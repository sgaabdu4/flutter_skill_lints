import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/test_callback_utils.dart';

/// Warns when a test repeats the same `expect(actual, expected)` assertion.
final class AvoidDuplicateTestAssertions extends MethodInvocationRule {
  static const LintCode code = LintCode(
    'avoid_duplicate_test_assertions',
    'Avoid duplicate test assertions.',
    correctionMessage: 'Remove the repeated assertion or assert a distinct condition.',
  );

  AvoidDuplicateTestAssertions()
    : super(
        code: code,
        name: 'avoid_duplicate_test_assertions',
        description:
            'Warns when the same expect(actual, expected) assertion is repeated in a test.',
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidDuplicateTestAssertions rule;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'test') return;

    final callback = testCallbackArgument(node);
    if (callback == null) return;

    final visitor = _DuplicateExpectVisitor(rule);
    callback.body.accept(visitor);
  }
}

final class _DuplicateExpectVisitor extends RecursiveAstVisitor<void> {
  _DuplicateExpectVisitor(this.rule);

  final AvoidDuplicateTestAssertions rule;
  final Set<String> _seenAssertions = {};

  @override
  void visitFunctionExpression(FunctionExpression node) {
    return;
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'expect') {
      super.visitMethodInvocation(node);
      return;
    }

    final args = node.argumentList.arguments
        .where((argument) => argument is! NamedArgument)
        .toList();
    if (args.length < 2) return;

    final key = '${args[0].toSource()}\u0000${args[1].toSource()}';
    if (!_seenAssertions.add(key)) {
      rule.reportAtNode(node.methodName);
    }
  }
}
