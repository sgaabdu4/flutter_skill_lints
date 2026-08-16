import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';

/// Warns when a non-nullable boolean is compared to a boolean literal.
class NoBooleanLiteralCompare extends BinaryExpressionRule {
  static const LintCode code = LintCode(
    'no_boolean_literal_compare',
    'Avoid comparing a boolean value to a boolean literal.',
    correctionMessage: 'Use the boolean expression directly.',
  );

  NoBooleanLiteralCompare()
    : super(
        name: 'no_boolean_literal_compare',
        description: 'Warns when a non-nullable bool is compared to true or false.',
        code: code,
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final NoBooleanLiteralCompare rule;

  @override
  void visitBinaryExpression(BinaryExpression node) {
    final operator = node.operator.type;
    if (operator != TokenType.EQ_EQ && operator != TokenType.BANG_EQ) return;

    final leftIsLiteral = node.leftOperand is BooleanLiteral;
    final rightIsLiteral = node.rightOperand is BooleanLiteral;
    if (leftIsLiteral == rightIsLiteral) return;

    final comparedExpression = leftIsLiteral ? node.rightOperand : node.leftOperand;
    if (!_isNonNullableBool(comparedExpression)) return;

    rule.reportAtNode(node);
  }
}

bool _isNonNullableBool(Expression expression) {
  final type = expression.staticType;
  return type != null &&
      type.isDartCoreBool &&
      type.nullabilitySuffix != NullabilitySuffix.question;
}
