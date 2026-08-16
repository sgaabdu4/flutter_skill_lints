import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';

/// Warns when code uses banned type annotations.
class AvoidBannedTypes extends GeneratedNamedTypeCheckRule {
  static const LintCode code = LintCode(
    'avoid_banned_types',
    "Avoid banned type '{0}'.",
    correctionMessage: 'Use a specific type or Object? at the boundary.',
  );

  AvoidBannedTypes()
    : super(
        name: 'avoid_banned_types',
        description: 'Warns when code uses banned type annotations.',
        code: code,
      );

  @override
  void checkNamedType(NamedType node) {
    final name = node.name.lexeme;
    if (name != 'dynamic') return;
    if (_isJsonMapValueType(node)) return;

    reportAtNode(node, arguments: [name]);
  }
}

bool _isJsonMapValueType(NamedType node) {
  final typeArguments = node.parent;
  if (typeArguments is! TypeArgumentList) return false;

  final arguments = typeArguments.arguments;
  if (arguments.length != 2 || arguments.last != node) return false;

  final mapType = typeArguments.parent;
  if (mapType is! NamedType || mapType.name.lexeme != 'Map') return false;

  final keyType = arguments.first;
  return keyType is NamedType && keyType.name.lexeme == 'String';
}
