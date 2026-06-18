import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when an equality comparison negates one side.
class AvoidNegationsInEqualityChecks extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_negations_in_equality_checks',
    'Avoid negating one side of an equality check.',
    correctionMessage: 'Move the negation into the equality operator.',
  );

  AvoidNegationsInEqualityChecks()
    : super(
        name: 'avoid_negations_in_equality_checks',
        description: 'Warns when == or != compares a negated boolean expression.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addBinaryExpression(this, _Visitor(this));
  }
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
