import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';

import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';

/// Warns when `void Function()` is used instead of `VoidCallback`.
class PreferVoidCallback extends GenericFunctionTypeCheckRule {
  static const LintCode code = LintCode(
    'prefer_void_callback',
    "Use 'VoidCallback' instead of 'void Function()'.",
    correctionMessage: "Replace with 'VoidCallback' from 'dart:ui'.",
  );

  PreferVoidCallback()
    : super(
        name: 'prefer_void_callback',
        description: 'Warns when void Function() is used instead of VoidCallback.',
        code: code,
      );

  @override
  void checkCallbackReturnType(GenericFunctionType node, NamedType returnType) {
    if (returnType.name.lexeme != 'void') return;

    reportAtNode(node);
  }
}
