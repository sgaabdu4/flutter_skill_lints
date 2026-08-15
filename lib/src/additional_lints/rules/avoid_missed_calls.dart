import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';

/// Warns when a Future-producing expression statement is neither awaited nor
/// otherwise handled.
final class AvoidMissedCalls extends ExpressionStatementCheckRule {
  static const LintCode code = LintCode(
    'avoid_missed_calls',
    'Handle the returned Future.',
    correctionMessage: 'Await it, return it, assign it, or pass it to unawaited().',
  );

  AvoidMissedCalls()
    : super(
        name: 'avoid_missed_calls',
        description: 'Warns when Future-returning calls are used as bare statements.',
        code: code,
      );

  @override
  void checkExpressionStatement(ExpressionStatement node) {
    final expression = node.expression;
    if (expression is AwaitExpression) return;
    if (expression is AssignmentExpression) return;
    if (!isFutureLikeType(expression.staticType)) return;

    reportAtNode(expression);
  }
}
