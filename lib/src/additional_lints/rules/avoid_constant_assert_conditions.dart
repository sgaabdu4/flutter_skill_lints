import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'package:flutter_skill_lints/src/additional_lints/constant_expression.dart';

/// Warns when an assert condition is a compile-time constant.
final class AvoidConstantAssertConditions extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_constant_assert_conditions',
    'Avoid constant assert conditions.',
    correctionMessage: 'Assert a runtime condition or remove the assert.',
  );

  AvoidConstantAssertConditions()
    : super(
        name: 'avoid_constant_assert_conditions',
        description: 'Warns when assert conditions are compile-time constants.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addAssertStatement(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidConstantAssertConditions rule;

  @override
  void visitAssertStatement(AssertStatement node) {
    if (!_isConstantCondition(node.condition)) return;

    rule.reportAtNode(node.condition);
  }
}

bool _isConstantCondition(Expression expression) {
  expression = unparenthesizedExpression(expression);

  if (isConstantExpression(expression)) return true;

  if (expression is BinaryExpression) {
    final operator = expression.operator.type;
    if (comparisonOperators.contains(operator) || isLogicalOperator(operator)) {
      return _isConstantCondition(expression.leftOperand) &&
          _isConstantCondition(expression.rightOperand);
    }
  }

  return false;
}
