import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/constant_expression.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';

/// Warns when a binary comparison has constant operands on both sides.
///
/// A condition like `10 == 11` or `SomeClass.value == '1'` always evaluates
/// to the same result, which usually indicates a typo or a bug.
class AvoidConstantConditions extends BinaryExpressionCheckRule {
  static const LintCode code = LintCode(
    'avoid_constant_conditions',
    'Both sides of this comparison are constants, so the result is always the '
        'same.',
    correctionMessage: 'Replace one operand with a variable or remove the dead condition.',
  );

  AvoidConstantConditions()
    : super(
        name: 'avoid_constant_conditions',
        description:
            'Warns when a binary comparison has constant operands on both '
            'sides.',
        code: code,
      );

  @override
  @override
  void checkBinaryExpression(BinaryExpression node) {
    if (!comparisonOperators.contains(node.operator.type)) return;

    if (!isConstantExpression(node.leftOperand) || !isConstantExpression(node.rightOperand)) {
      return;
    }

    reportAtNode(node);
  }
}
