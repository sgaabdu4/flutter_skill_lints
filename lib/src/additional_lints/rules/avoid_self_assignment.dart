import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/error.dart';

import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_equal_expressions.dart';

/// Warns when a variable, field, or index expression is assigned to itself.
class AvoidSelfAssignment extends AssignmentExpressionCheckRule {
  static const LintCode code = LintCode(
    'avoid_self_assignment',
    'This assignment assigns the target to itself.',
    correctionMessage: 'Remove the assignment or assign a different value.',
  );

  AvoidSelfAssignment()
    : super(
        name: 'avoid_self_assignment',
        description: 'Warns when an assignment writes an expression to itself.',
        code: code,
      );

  @override
  void checkAssignmentExpression(AssignmentExpression node) {
    if (node.operator.type != TokenType.EQ) return;
    if (sameLintExpressionSource(node.leftHandSide, node.rightHandSide)) {
      reportAtNode(node);
    }
  }
}
