import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';

import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';

/// Avoids `Future<Future<T>>`.
class AvoidNestedFutures extends NamedTypeCheckRule {
  static const LintCode code = LintCode(
    'avoid_nested_futures',
    'Avoid nested Future types.',
    correctionMessage: 'Flatten the async contract to a single Future.',
    severity: DiagnosticSeverity.ERROR,
  );

  AvoidNestedFutures()
    : super(
        name: 'avoid_nested_futures',
        description: 'Avoids Future<Future<T>> type annotations.',
        code: code,
      );

  @override
  void checkNamedType(NamedType node) {
    if (!_isDartAsyncType(node, 'Future')) return;

    final typeArguments = node.typeArguments?.arguments;
    if (typeArguments == null) return;

    if (typeArguments.any(_containsFutureType)) {
      reportAtNode(node);
    }
  }
}

bool _containsFutureType(TypeAnnotation type) {
  if (type is! NamedType) return false;
  if (_isDartAsyncType(type, 'Future')) return true;

  return type.typeArguments?.arguments.any(_containsFutureType) ?? false;
}

bool _isDartAsyncType(NamedType type, String name) {
  return type.name.lexeme == name && type.element?.library?.isDartAsync == true;
}
