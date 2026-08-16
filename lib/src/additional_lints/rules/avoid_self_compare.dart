import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_equal_expressions.dart';

/// Warns when an expression is compared with itself.
class AvoidSelfCompare extends BinaryExpressionRule {
  static const LintCode code = LintCode(
    'avoid_self_compare',
    'This comparison compares an expression with itself.',
    correctionMessage: 'Remove the comparison or compare with a different value.',
  );

  AvoidSelfCompare()
    : super(
        name: 'avoid_self_compare',
        description: 'Warns when both sides of a comparison are the same expression.',
        code: code,
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidSelfCompare rule;

  @override
  void visitBinaryExpression(BinaryExpression node) {
    if (!_comparisonOperators.contains(node.operator.type)) return;
    if (sameLintExpressionSource(node.leftOperand, node.rightOperand)) {
      rule.reportAtNode(node);
    }
  }
}

const _comparisonOperators = <TokenType>{
  TokenType.EQ_EQ,
  TokenType.BANG_EQ,
  TokenType.LT,
  TokenType.LT_EQ,
  TokenType.GT,
  TokenType.GT_EQ,
};
