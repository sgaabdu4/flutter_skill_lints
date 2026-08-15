import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';

import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Warns when Mockito-style `thenReturn` receives a Future or Stream.
final class AvoidThenReturnWithFuture extends MethodInvocationRule {
  static const LintCode code = LintCode(
    'avoid_then_return_with_future',
    'Avoid returning Futures or Streams from thenReturn().',
    correctionMessage: 'Use thenAnswer() for asynchronous values.',
  );

  AvoidThenReturnWithFuture()
    : super(
        code: code,
        name: 'avoid_then_return_with_future',
        description: 'Warns when thenReturn() receives a Future or Stream expression.',
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidThenReturnWithFuture rule;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (isAsyncThenReturn(node)) {
      rule.reportAtNode(node.methodName);
    }
  }
}
