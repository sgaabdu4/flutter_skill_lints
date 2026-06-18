import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../constant_expression.dart';

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
  expression = _unwrapParentheses(expression);

  if (isConstantExpression(expression)) return true;

  if (expression is BinaryExpression) {
    final operator = expression.operator.type;
    if (comparisonOperators.contains(operator) || _isLogicalOperator(operator)) {
      return _isConstantCondition(expression.leftOperand) &&
          _isConstantCondition(expression.rightOperand);
    }
  }

  return false;
}

Expression _unwrapParentheses(Expression expression) {
  while (expression is ParenthesizedExpression) {
    expression = expression.expression;
  }

  return expression;
}

bool _isLogicalOperator(TokenType type) {
  return type == TokenType.AMPERSAND_AMPERSAND || type == TokenType.BAR_BAR;
}
