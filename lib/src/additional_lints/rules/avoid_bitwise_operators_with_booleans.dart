import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';

/// Warns when boolean values are combined with bitwise operators.
final class AvoidBitwiseOperatorsWithBooleans extends BinaryExpressionRule {
  static const LintCode code = LintCode(
    'avoid_bitwise_operators_with_booleans',
    'Avoid bitwise operators with boolean operands.',
    correctionMessage: 'Use && or ||, or make the eager evaluation explicit.',
  );

  AvoidBitwiseOperatorsWithBooleans()
    : super(
        name: 'avoid_bitwise_operators_with_booleans',
        description: 'Warns when non-nullable bool values are combined with &, |, or ^.',
        code: code,
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidBitwiseOperatorsWithBooleans rule;

  @override
  void visitBinaryExpression(BinaryExpression node) {
    if (!_isBitwiseOperator(node.operator.type)) return;
    if (!_isNonNullableBool(node.leftOperand) || !_isNonNullableBool(node.rightOperand)) {
      return;
    }

    rule.reportAtNode(node);
  }
}

bool _isBitwiseOperator(TokenType type) {
  return type == TokenType.AMPERSAND || type == TokenType.BAR || type == TokenType.CARET;
}

bool _isNonNullableBool(Expression expression) {
  final type = expression.staticType;
  return type != null &&
      type.isDartCoreBool &&
      type.nullabilitySuffix != NullabilitySuffix.question;
}
