import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Warns when an explicit nullable return type is not needed.
class AvoidUnnecessaryNullableReturnType extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_unnecessary_nullable_return_type',
    'Avoid unnecessary nullable return types.',
    correctionMessage: 'Remove the nullable marker or return null from this function.',
  );

  AvoidUnnecessaryNullableReturnType()
    : super(
        name: 'avoid_unnecessary_nullable_return_type',
        description: 'Warns when a nullable return type has no nullable return path.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (isGeneratedRuleContext(context)) return;

    final visitor = _Visitor(this);
    registry.addFunctionDeclaration(this, visitor);
    registry.addMethodDeclaration(this, visitor);
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidUnnecessaryNullableReturnType rule;

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _check(node.returnType, node.functionExpression.body);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (_hasOverrideAnnotation(node.metadata)) return;
    _check(node.returnType, node.body);
  }

  void _check(TypeAnnotation? returnType, FunctionBody body) {
    if (returnType is! NamedType || returnType.question == null) return;
    if (!_provesNonNullReturn(body)) return;

    rule.reportAtNode(returnType);
  }

  bool _provesNonNullReturn(FunctionBody body) {
    if (body is ExpressionFunctionBody) {
      return _isNonNullableExpression(body.expression);
    }
    if (body is! BlockFunctionBody) return false;

    final returns = _LocalReturnCollector(body).returns;
    if (returns.isEmpty) return false;
    if (returns.any((statement) => !_isNonNullableExpression(statement.expression))) {
      return false;
    }

    return _blockAlwaysExits(body.block);
  }

  bool _isNonNullableExpression(Expression? expression) {
    if (expression == null || expression is NullLiteral) return false;

    final type = expression.staticType;
    if (type == null) return false;

    return type.nullabilitySuffix != NullabilitySuffix.question;
  }

  bool _blockAlwaysExits(Block block) {
    final statements = block.statements;
    if (statements.isEmpty) return false;

    final last = statements.last;
    return switch (last) {
      ReturnStatement() => true,
      ExpressionStatement(expression: ThrowExpression()) => true,
      IfStatement(:final elseStatement?) =>
        _statementAlwaysExits(last.thenStatement) && _statementAlwaysExits(elseStatement),
      _ => false,
    };
  }

  bool _statementAlwaysExits(Statement statement) {
    return switch (statement) {
      ReturnStatement() => true,
      ExpressionStatement(expression: ThrowExpression()) => true,
      Block() => _blockAlwaysExits(statement),
      IfStatement(:final elseStatement?) =>
        _statementAlwaysExits(statement.thenStatement) && _statementAlwaysExits(elseStatement),
      _ => false,
    };
  }

  bool _hasOverrideAnnotation(NodeList<Annotation> metadata) {
    return metadata.any((annotation) => annotation.name.name == 'override');
  }
}

final class _LocalReturnCollector extends RecursiveAstVisitor<void> {
  _LocalReturnCollector(FunctionBody body) {
    body.accept(this);
  }

  final List<ReturnStatement> returns = <ReturnStatement>[];

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitReturnStatement(ReturnStatement node) {
    returns.add(node);
  }
}
