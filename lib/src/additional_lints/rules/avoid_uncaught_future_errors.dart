import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';

/// Warns when a fire-and-forget Future has no local error handler.
final class AvoidUncaughtFutureErrors extends MethodInvocationRule {
  static const LintCode code = LintCode(
    'avoid_uncaught_future_errors',
    'Handle errors from fire-and-forget Futures.',
    correctionMessage: 'Add try/catch inside the inline async fire-and-forget body.',
  );

  AvoidUncaughtFutureErrors()
    : super(
        code: code,
        name: 'avoid_uncaught_future_errors',
        description: 'Warns when an inline async unawaited() body has no visible try/catch.',
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidUncaughtFutureErrors rule;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.target != null || node.methodName.name != 'unawaited') return;
    final arguments = node.argumentList.arguments;
    if (arguments.length != 1) return;

    final future = arguments.single;
    final inlineBody = _inlineAsyncBody(future.argumentExpression);
    if (inlineBody == null) return;
    if (_containsTryStatement(inlineBody)) return;

    rule.reportAtNode(future);
  }
}

FunctionBody? _inlineAsyncBody(Expression expression) {
  if (expression is! FunctionExpressionInvocation) return null;
  final function = expression.function;
  if (function is! FunctionExpression || !function.body.isAsynchronous) return null;
  return function.body;
}

bool _containsTryStatement(FunctionBody body) {
  final visitor = _TryStatementVisitor();
  body.accept(visitor);
  return visitor.found;
}

final class _TryStatementVisitor extends RecursiveAstVisitor<void> {
  bool found = false;

  @override
  void visitTryStatement(TryStatement node) {
    found = true;
  }
}
