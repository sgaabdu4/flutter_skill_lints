import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';

/// Warns when both sides of a logical expression are the same expression.
class AvoidEqualExpressions extends BinaryExpressionRule {
  static const LintCode code = LintCode(
    'avoid_equal_expressions',
    'Both sides of this expression are the same.',
    correctionMessage: 'Remove the duplicate expression or use a different operand.',
  );

  AvoidEqualExpressions()
    : super(
        name: 'avoid_equal_expressions',
        description: 'Warns when both sides of a logical expression are equal.',
        code: code,
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidEqualExpressions rule;

  @override
  void visitBinaryExpression(BinaryExpression node) {
    if (!_logicalOperators.contains(node.operator.type)) return;
    if (sameLintExpressionSource(node.leftOperand, node.rightOperand)) {
      rule.reportAtNode(node);
    }
  }
}

const _logicalOperators = <TokenType>{
  TokenType.AMPERSAND_AMPERSAND,
  TokenType.BAR_BAR,
  TokenType.QUESTION_QUESTION,
};

bool sameLintExpressionSource(Expression left, Expression right) {
  if (!_isSafeToCompare(left) || !_isSafeToCompare(right)) return false;

  return _canonicalExpressionSource(left) == _canonicalExpressionSource(right);
}

String _canonicalExpressionSource(Expression expression) {
  var current = expression;
  while (current is ParenthesizedExpression) {
    current = current.expression;
  }

  return current.toSource().replaceAll(RegExp(r'\s+'), ' ').trim();
}

bool _isSafeToCompare(Expression expression) {
  var current = expression;
  while (current is ParenthesizedExpression) {
    current = current.expression;
  }

  if (current is AssignmentExpression ||
      current is AwaitExpression ||
      current is CascadeExpression ||
      current is FunctionExpressionInvocation ||
      current is InstanceCreationExpression ||
      current is MethodInvocation ||
      current is PostfixExpression) {
    return false;
  }

  if (current is PrefixExpression) {
    if (current.operator.type == TokenType.PLUS_PLUS ||
        current.operator.type == TokenType.MINUS_MINUS) {
      return false;
    }

    return _isSafeToCompare(current.operand);
  }

  for (final child in current.childEntities) {
    if (child is Expression && !_isSafeToCompare(child)) return false;
  }

  return true;
}
