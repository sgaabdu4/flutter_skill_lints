import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when a FakeAsync callback is marked `async`.
final class AvoidAsyncCallbackInFakeAsync extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_async_callback_in_fake_async',
    'Avoid async callbacks in fakeAsync().',
    correctionMessage: 'Keep the callback synchronous and advance fake time explicitly.',
  );

  AvoidAsyncCallbackInFakeAsync()
    : super(
        name: 'avoid_async_callback_in_fake_async',
        description: 'Warns when fakeAsync() or FakeAsync.run() receives an async callback.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addMethodInvocation(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidAsyncCallbackInFakeAsync rule;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (!_isFakeAsyncInvocation(node)) return;

    final callback = node.argumentList.arguments
        .whereType<FunctionExpression>()
        .where((argument) => argument.parent is! NamedExpression)
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
