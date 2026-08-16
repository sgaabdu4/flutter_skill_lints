import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/condition_rule.dart';

/// Warns when a condition wraps an invertible boolean check in `!`.
class AvoidInvertedBooleanChecks extends ConditionRule {
  static const LintCode code = LintCode(
    'avoid_inverted_boolean_checks',
    'Avoid wrapping an invertible boolean check in !.',
    correctionMessage: 'Use the inverse operator directly.',
  );

  AvoidInvertedBooleanChecks()
    : super(
        name: 'avoid_inverted_boolean_checks',
        description: 'Warns when conditions use ! around an invertible boolean check.',
        code: code,
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

final class _Visitor extends ConditionVisitor {
  const _Visitor(this.rule);

  final AvoidInvertedBooleanChecks rule;

  @override
  void checkCondition(Expression condition) {
    final expression = _unwrap(condition);
    if (expression is! PrefixExpression || expression.operator.type != TokenType.BANG) {
      return;
    }

    if (_hasDirectInverse(_unwrap(expression.operand))) {
      rule.reportAtNode(expression);
    }
  }
}

bool _hasDirectInverse(Expression expression) {
  return switch (expression) {
    BinaryExpression(:final operator) when _invertibleOperators.contains(operator.type) => true,
    IsExpression() => true,
    _ => false,
  };
}

const _invertibleOperators = {
  TokenType.EQ_EQ,
  TokenType.BANG_EQ,
  TokenType.LT,
  TokenType.GT,
  TokenType.LT_EQ,
  TokenType.GT_EQ,
};

Expression _unwrap(Expression expression) {
  var current = expression;
  while (current is ParenthesizedExpression) {
    current = current.expression;
  }
  return current;
}
