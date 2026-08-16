import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';

/// Warns when an equality comparison negates one side.
class AvoidNegationsInEqualityChecks extends BinaryExpressionRule {
  static const LintCode code = LintCode(
    'avoid_negations_in_equality_checks',
    'Avoid negating one side of an equality check.',
    correctionMessage: 'Move the negation into the equality operator.',
  );

  AvoidNegationsInEqualityChecks()
    : super(
        name: 'avoid_negations_in_equality_checks',
        description: 'Warns when == or != compares a negated boolean expression.',
        code: code,
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidNegationsInEqualityChecks rule;

  @override
  void visitBinaryExpression(BinaryExpression node) {
    final operator = node.operator.type;
    if (operator != TokenType.EQ_EQ && operator != TokenType.BANG_EQ) return;

    final leftNegated = _isBooleanNegation(node.leftOperand);
    final rightNegated = _isBooleanNegation(node.rightOperand);
    if (leftNegated == rightNegated) return;

    rule.reportAtNode(node);
  }
}

bool _isBooleanNegation(Expression expression) {
  final unwrapped = _unwrap(expression);
  return unwrapped is PrefixExpression && unwrapped.operator.type == TokenType.BANG;
}

Expression _unwrap(Expression expression) {
  var current = expression;
  while (current is ParenthesizedExpression) {
    current = current.expression;
  }
  return current;
}
