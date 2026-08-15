import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';

import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Warns when Mocktail/Mockito `thenReturn` receives async values.
final class UseThenAnswer extends MethodInvocationRule {
  static const LintCode code = LintCode(
    'use_then_answer',
    'Use thenAnswer() for Futures and Streams.',
    correctionMessage: 'Return asynchronous values from thenAnswer() instead of thenReturn().',
  );

  UseThenAnswer()
    : super(
        code: code,
        name: 'use_then_answer',
        description: 'Warns when thenReturn() receives a Future or Stream value.',
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final UseThenAnswer rule;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (isAsyncThenReturn(node)) {
      rule.reportAtNode(node.methodName);
    }
  }
}
