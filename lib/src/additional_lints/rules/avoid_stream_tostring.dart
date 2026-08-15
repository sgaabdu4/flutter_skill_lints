import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';

import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';

/// Warns when `toString()` is called on a Stream.
class AvoidStreamToString extends MethodInvocationRule {
  static const LintCode code = LintCode(
    'avoid_stream_tostring',
    'Avoid calling toString() on a Stream.',
    correctionMessage:
        'Listen to the Stream or handle emitted values before converting to a string.',
  );

  AvoidStreamToString()
    : super(
        code: code,
        name: 'avoid_stream_tostring',
        description: 'Warns when Stream.toString() is used.',
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  static const _streamChecker = TypeChecker.fromUrl('dart:async#Stream');

  final AvoidStreamToString rule;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'toString') return;
    if (node.argumentList.arguments.isNotEmpty) return;

    final targetType = node.target?.staticType;
    if (targetType == null || !_streamChecker.isAssignableFromType(targetType)) return;

    rule.reportAtNode(node.methodName);
  }
}
