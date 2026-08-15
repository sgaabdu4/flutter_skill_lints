import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/condition_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/constant_expression.dart';

/// Warns when a control-flow condition directly contains boolean literals.
final class AvoidConditionsWithBooleanLiterals extends ConditionRule {
  static const LintCode code = LintCode(
    'avoid_conditions_with_boolean_literals',
    'Avoid boolean literals in conditions.',
    correctionMessage: 'Remove the literal branch or replace it with a named boolean.',
  );

  AvoidConditionsWithBooleanLiterals()
    : super(
        name: 'avoid_conditions_with_boolean_literals',
        description: 'Warns when conditions directly contain true or false literals.',
        code: code,
        includeAssert: false,
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

final class _Visitor extends ConditionVisitor {
  const _Visitor(this.rule);

  final AvoidConditionsWithBooleanLiterals rule;

  @override
  void checkCondition(Expression condition) {
    final literal = _directBooleanLiteralInCondition(condition);
    if (literal == null) return;

    rule.reportAtNode(literal);
  }
}

BooleanLiteral? _directBooleanLiteralInCondition(Expression expression) {
  expression = unparenthesizedExpression(expression);

  if (expression is BooleanLiteral) return expression;

  if (expression is PrefixExpression && expression.operator.type == TokenType.BANG) {
    return _directBooleanLiteralInCondition(expression.operand);
  }

  if (expression is BinaryExpression && isLogicalOperator(expression.operator.type)) {
    return _directBooleanLiteralInCondition(expression.leftOperand) ??
        _directBooleanLiteralInCondition(expression.rightOperand);
  }

  return null;
}
