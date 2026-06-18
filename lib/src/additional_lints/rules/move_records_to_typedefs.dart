import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Warns when record shapes are not named at their declaration boundary.
class MoveRecordsToTypedefs extends AnalysisRule {
  static const LintCode code = LintCode(
    'move_records_to_typedefs',
    'Move record types to typedefs.',
    correctionMessage:
        'Create a named typedef for this record shape and use that name at the declaration.',
  );

  MoveRecordsToTypedefs()
    : super(
        name: 'move_records_to_typedefs',
        description: 'Warns when record shapes are not named at their declaration boundary.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (isGeneratedRuleContext(context)) return;
    final visitor = _Visitor(this);
    registry
      ..addRecordTypeAnnotation(this, visitor)
      ..addRecordLiteral(this, visitor);
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final MoveRecordsToTypedefs rule;

  @override
  void visitRecordTypeAnnotation(RecordTypeAnnotation node) {
    if (_isInsideTypeAlias(node)) return;

    rule.reportAtNode(node);
  }

  @override
  void visitRecordLiteral(RecordLiteral node) {
    if (!_needsExplicitRecordOwner(node)) return;

    rule.reportAtNode(node);
  }

  bool _needsExplicitRecordOwner(RecordLiteral node) {
    final parent = node.parent;
    if (parent is VariableDeclaration && parent.initializer == node) {
      final declarationList = parent.parent;
      return declarationList is VariableDeclarationList && declarationList.type == null;
    }

    if (parent is ReturnStatement) {
      return _enclosingReturnType(parent) == null;
    }

    if (parent is ExpressionFunctionBody) {
      return _enclosingReturnType(parent) == null;
    }

    return false;
  }

  TypeAnnotation? _enclosingReturnType(AstNode node) {
    AstNode? current = node.parent;
    while (current != null) {
      if (current is FunctionDeclaration) return current.returnType;
      if (current is MethodDeclaration) return current.returnType;
      if (current is FunctionExpression) {
        final parent = current.parent;
        if (parent is FunctionDeclaration) return parent.returnType;
        if (parent is MethodDeclaration) return parent.returnType;
      }
      current = current.parent;
    }
    return null;
  }

  bool _isInsideTypeAlias(AstNode node) {
    AstNode? current = node.parent;
    while (current != null) {
      if (current is GenericTypeAlias) return true;
      current = current.parent;
    }
    return false;
  }
}
