import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Warns when a throw expression is used.
class AvoidThrow extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_throw',
    'Avoid throw expressions.',
    correctionMessage: 'Return a typed failure or use the project error boundary.',
  );

  AvoidThrow() : super(name: 'avoid_throw', description: 'Warns when a throw expression is used.');

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (isGeneratedRuleContext(context)) return;
    registry.addThrowExpression(this, _Visitor(this, context.definingUnit.file.path));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule, this.path);

  final AvoidThrow rule;
  final String path;

  @override
  void visitThrowExpression(ThrowExpression node) {
    if (_isValueObjectArgumentGuard(node, path)) return;
    rule.reportAtNode(node);
  }
}

bool _isValueObjectArgumentGuard(ThrowExpression node, String path) {
  if (!path.replaceAll('\\', '/').contains('/domain/values/')) return false;
  final error = node.expression;
  if (error is! InstanceCreationExpression || error.constructorName.element?.name != 'value') {
    return false;
  }
  final type = error.staticType;
  if (type is! InterfaceType ||
      type.element.name != 'ArgumentError' ||
      type.element.library.identifier != 'dart:core') {
    return false;
  }
  final arguments = error.argumentList.arguments;
  if (arguments.isEmpty) return false;
  final value = arguments.first.argumentExpression;
  if (value is! SimpleIdentifier || value.element is! FormalParameterElement) return false;
  IfStatement? guard;
  ConstructorDeclaration? factory;
  for (AstNode? parent = node.parent; parent != null; parent = parent.parent) {
    if (parent is IfStatement &&
        parent.thenStatement.offset <= node.offset &&
        parent.thenStatement.end >= node.end) {
      guard ??= parent;
    }
    if (parent is ConstructorDeclaration) {
      factory = parent;
      break;
    }
  }
  return factory?.factoryKeyword != null &&
      guard != null &&
      RegExp('\\b${RegExp.escape(value.name)}\\b').hasMatch(guard.expression.toSource());
}
