import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Warns when an obvious local throwable class does not declare `toString`.
class AvoidThrowObjectsWithoutToString extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_throw_objects_without_tostring',
    "Thrown local class '{0}' does not declare toString().",
    correctionMessage: 'Declare toString() on thrown local error objects.',
  );

  AvoidThrowObjectsWithoutToString()
    : super(
        name: 'avoid_throw_objects_without_tostring',
        description: 'Warns when an obvious local throwable class does not declare toString().',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addThrowExpression(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidThrowObjectsWithoutToString rule;

  @override
  void visitThrowExpression(ThrowExpression node) {
    final type = node.expression.staticType;
    if (type is! InterfaceType) return;
    final className = type.element.name;
    if (className == null) return;

    final declaration = localClassDeclaration(node, className);
    if (declaration == null || declaresToString(declaration)) return;

    rule.reportAtNode(node.expression, arguments: [declaration.namePart.typeName.lexeme]);
  }
}
