import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';

import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';

/// Warns when multiple assignments are chained in one expression.
class AvoidMultiAssignment extends AssignmentExpressionCheckRule {
  static const LintCode code = LintCode(
    'avoid_multi_assignment',
    'Avoid chained assignments.',
    correctionMessage: 'Split the assignments into separate statements.',
  );

  AvoidMultiAssignment()
    : super(
        name: 'avoid_multi_assignment',
        description: 'Warns when assignment expressions are chained.',
        code: code,
      );

  @override
  void checkAssignmentExpression(AssignmentExpression node) {
    if (node.rightHandSide is AssignmentExpression) {
      reportAtNode(node);
    }
  }
}
