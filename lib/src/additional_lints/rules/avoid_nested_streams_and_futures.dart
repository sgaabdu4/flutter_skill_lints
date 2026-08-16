import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';

import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';

/// Avoids async container types nested across `Future` and `Stream`.
class AvoidNestedStreamsAndFutures extends NamedTypeCheckRule {
  static const LintCode code = LintCode(
    'avoid_nested_streams_and_futures',
    'Avoid nested Stream and Future types.',
    correctionMessage: 'Expose one async boundary and flatten the produced value.',
    severity: DiagnosticSeverity.ERROR,
  );

  AvoidNestedStreamsAndFutures()
    : super(
        name: 'avoid_nested_streams_and_futures',
        description: 'Avoids Future<Stream<T>>, Stream<Future<T>>, and Stream<Stream<T>>.',
        code: code,
      );

  @override
  void checkNamedType(NamedType node) {
    if (!_isDartAsyncType(node, 'Future') && !_isDartAsyncType(node, 'Stream')) {
      return;
    }

    final typeArguments = node.typeArguments?.arguments;
    if (typeArguments == null) return;

    for (final typeArgument in typeArguments) {
      if (typeArgument is! NamedType) continue;
      if (_isDartAsyncType(node, 'Future') && _isDartAsyncType(typeArgument, 'Future')) {
        continue;
      }
      if (_isDartAsyncType(typeArgument, 'Future') || _isDartAsyncType(typeArgument, 'Stream')) {
        reportAtNode(node);
        return;
      }
    }
  }
}

bool _isDartAsyncType(NamedType type, String name) {
  return type.name.lexeme == name && type.element?.library?.isDartAsync == true;
}
