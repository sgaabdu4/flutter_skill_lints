import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/test_callback_utils.dart';

/// Warns when a test `group` callback contains no test calls.
final class AvoidEmptyTestGroups extends MethodInvocationRule {
  static const LintCode code = LintCode(
    'avoid_empty_test_groups',
    'Avoid test groups without test cases.',
    correctionMessage: 'Add a test case or remove the empty group.',
  );

  AvoidEmptyTestGroups()
    : super(
        code: code,
        name: 'avoid_empty_test_groups',
        description: 'Warns when a test group contains no test calls.',
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidEmptyTestGroups rule;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'group') return;

    final callback = testCallbackArgument(node);
    if (callback == null) return;

    final finder = _TestCallFinder();
    callback.body.accept(finder);
    if (!finder.hasTestCall) {
      rule.reportAtNode(node.methodName);
    }
  }
}

final class _TestCallFinder extends RecursiveAstVisitor<void> {
  static const Set<String> _testMethodNames = {'test', 'testWidgets'};

  bool hasTestCall = false;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_testMethodNames.contains(node.methodName.name)) {
      hasTestCall = true;
      return;
    }
    super.visitMethodInvocation(node);
  }
}
