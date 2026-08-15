import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/condition_rule.dart';

/// Warns when one condition combines too many logical operands.
final class AvoidComplexConditions extends ConditionRule {
  static const int maxOperands = 4;

  static const LintCode code = LintCode(
    'avoid_complex_conditions',
    'Avoid conditions with more than four logical operands.',
    correctionMessage: 'Extract the condition into named boolean values or a policy method.',
  );

  AvoidComplexConditions()
    : super(
        name: 'avoid_complex_conditions',
        description: 'Warns when a condition uses more than four && / || operands.',
        code: code,
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

final class _Visitor extends ConditionVisitor {
  const _Visitor(this.rule);

  final AvoidComplexConditions rule;

  @override
  void checkCondition(Expression condition) {
    final expression = _unwrapParentheses(condition);
    if (_logicalOperandCount(expression) <= AvoidComplexConditions.maxOperands) return;

    rule.reportAtNode(expression);
  }
}

Expression _unwrapParentheses(Expression expression) {
  while (expression is ParenthesizedExpression) {
    expression = expression.expression;
  }

  return expression;
}

int _logicalOperandCount(Expression expression) {
  expression = _unwrapParentheses(expression);
  if (expression is! BinaryExpression || !_isLogicalOperator(expression.operator)) {
    return 1;
  }

  return _logicalOperandCount(expression.leftOperand) +
      _logicalOperandCount(expression.rightOperand);
}

bool _isLogicalOperator(Token token) {
  return token.type == TokenType.AMPERSAND_AMPERSAND || token.type == TokenType.BAR_BAR;
}
