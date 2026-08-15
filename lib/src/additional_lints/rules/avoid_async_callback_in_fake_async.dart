import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';

/// Warns when a FakeAsync callback is marked `async`.
final class AvoidAsyncCallbackInFakeAsync extends MethodInvocationRule {
  static const LintCode code = LintCode(
    'avoid_async_callback_in_fake_async',
    'Avoid async callbacks in fakeAsync().',
    correctionMessage: 'Keep the callback synchronous and advance fake time explicitly.',
  );

  AvoidAsyncCallbackInFakeAsync()
    : super(
        code: code,
        name: 'avoid_async_callback_in_fake_async',
        description: 'Warns when fakeAsync() or FakeAsync.run() receives an async callback.',
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidAsyncCallbackInFakeAsync rule;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (!_isFakeAsyncInvocation(node)) return;

    final callback = node.argumentList.arguments
        .whereType<FunctionExpression>()
        .where((argument) => argument.parent is! NamedArgument)
        .firstOrNull;
    if (callback == null || callback.body.isAsynchronous == false) return;

    rule.reportAtNode(callback);
  }

  static bool _isFakeAsyncInvocation(MethodInvocation node) {
    final name = node.methodName.name;
    if (name == 'fakeAsync' && node.target == null) return true;
    return name == 'run' && node.target?.toSource() == 'FakeAsync';
  }
}
