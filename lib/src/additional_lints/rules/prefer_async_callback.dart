import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';

import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';

/// Warns when `Future<void> Function()` is used instead of `AsyncCallback`.
///
/// The `AsyncCallback` typedef from `package:flutter/foundation.dart` is a
/// cleaner and more readable alternative to the verbose
/// `Future<void> Function()` type annotation.
///
/// ## Example
///
/// ❌ Bad:
/// ```dart
/// void fn(Future<void> Function() callback) {}
/// ```
///
/// ✅ Good:
/// ```dart
/// void fn(AsyncCallback callback) {}
/// ```
class PreferAsyncCallback extends GenericFunctionTypeCheckRule {
  static const LintCode code = LintCode(
    'prefer_async_callback',
    "Use 'AsyncCallback' instead of 'Future<void> Function()'.",
    correctionMessage:
        "Replace with 'AsyncCallback' from "
        "'package:flutter/foundation.dart'.",
  );

  PreferAsyncCallback()
    : super(
        name: 'prefer_async_callback',
        description: 'Warns when Future<void> Function() is used instead of AsyncCallback.',
        code: code,
      );

  @override
  void checkCallbackReturnType(GenericFunctionType node, NamedType returnType) {
    if (returnType.name.lexeme != 'Future') return;

    // Must have exactly one type argument: <void>
    final typeArgs = returnType.typeArguments;
    if (typeArgs == null) return;
    if (typeArgs.arguments.length != 1) return;

    final typeArg = typeArgs.arguments.first;
    if (typeArg is! NamedType) return;
    if (typeArg.name.lexeme != 'void') return;

    reportAtNode(node);
  }
}
