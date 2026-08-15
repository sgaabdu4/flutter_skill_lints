import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';

import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';

/// Warns when `setState` is called with an empty callback.
class AvoidEmptySetstate extends MethodInvocationCheckRule {
  static const LintCode code = LintCode(
    'avoid_empty_setstate',
    'Avoid empty setState callbacks.',
    correctionMessage: 'Remove the setState call or add the missing state mutation.',
  );

  AvoidEmptySetstate()
    : super(
        name: 'avoid_empty_setstate',
        description: 'Warns when setState is called with an empty callback.',
        code: code,
      );

  @override
  void checkMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'setState') return;
    if (!_isInsideState(node)) return;

    final callback = node.argumentList.arguments.firstOrNull;
    if (callback is! FunctionExpression) return;

    final body = callback.body;
    if (body is! BlockFunctionBody || body.block.statements.isNotEmpty) {
      return;
    }

    reportAtNode(node);
  }

  static bool _isInsideState(AstNode node) {
    AstNode? current = node.parent;
    while (current != null) {
      if (current is ClassDeclaration) {
        final element = current.declaredFragment?.element;
        return element != null && flutterStateChecker.isSuperOf(element);
      }
      current = current.parent;
    }
    return false;
  }
}
