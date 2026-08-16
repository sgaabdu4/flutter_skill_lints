import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/condition_rule.dart';

/// Warns when a set literal is used where its value is ignored or non-boolean.
final class AvoidMisusedSetLiterals extends ConditionRule {
  static const LintCode code = LintCode(
    'avoid_misused_set_literals',
    'Avoid misused set literals.',
    correctionMessage:
        'Use the set literal as a value, or replace the condition with a boolean expression.',
    severity: DiagnosticSeverity.ERROR,
  );

  AvoidMisusedSetLiterals()
    : super(
        name: 'avoid_misused_set_literals',
        description: 'Warns when a set literal is used as a statement or condition.',
        code: code,
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);

  @override
  void registerAdditionalConditionNodes(RuleVisitorRegistry registry, AstVisitor<void> visitor) {
    registry.addExpressionStatement(this, visitor);
  }
}

final class _Visitor extends ConditionVisitor {
  const _Visitor(this.rule);

  final AvoidMisusedSetLiterals rule;

  @override
  void visitExpressionStatement(ExpressionStatement node) {
    checkCondition(node.expression);
  }

  @override
  void checkCondition(Expression expression) {
    final unwrapped = _unwrap(expression);
    if (unwrapped is SetOrMapLiteral && unwrapped.isSet) {
      rule.reportAtNode(unwrapped);
    }
  }
}

Expression _unwrap(Expression expression) {
  var current = expression;
  while (current is ParenthesizedExpression) {
    current = current.expression;
  }
  if (current is AsExpression) {
    return _unwrap(current.expression);
  }
  return current;
}
