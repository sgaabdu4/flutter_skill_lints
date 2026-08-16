import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';

/// Warns when a synchronous function contains a bare Future-producing call.
final class AvoidAsyncCallInSyncFunction extends ExpressionStatementCheckRule {
  static const LintCode code = LintCode(
    'avoid_async_call_in_sync_function',
    'Avoid bare async calls in synchronous functions.',
    correctionMessage: 'Make the function async and await the call, or explicitly use unawaited().',
  );

  AvoidAsyncCallInSyncFunction()
    : super(
        name: 'avoid_async_call_in_sync_function',
        description: 'Warns when sync functions contain unhandled Future-returning calls.',
        code: code,
      );

  @override
  void checkExpressionStatement(ExpressionStatement node) {
    final body = _enclosingFunctionBody(node);
    if (body == null || body.isAsynchronous || body.isGenerator) return;

    final expression = node.expression;
    if (expression is AssignmentExpression) return;
    if (!isFutureLikeType(expression.staticType)) return;

    reportAtNode(expression);
  }
}

FunctionBody? _enclosingFunctionBody(AstNode node) {
  AstNode? current = node.parent;
  while (current != null) {
    if (current is FunctionBody) return current;
    current = current.parent;
  }
  return null;
}
