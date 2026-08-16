import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';

/// Avoid dynamic except at JSON map boundaries.
///
/// Why: `dynamic` disables static checking in normal app code and hides runtime errors. The only
/// built-in allowance is `Map<String, dynamic>` because JSON payloads commonly need that shape.
/// For untyped runtime APIs, keep the lint visible and add a targeted ignore with a local reason.
final class AvoidDynamicExceptJsonMaps extends GeneratedNamedTypeCheckRule {
  static const LintCode code = LintCode(
    'avoid_dynamic_except_json_maps',
    'Avoid dynamic except at JSON map boundaries.',
    correctionMessage:
        'Use Object?, a precise type, or Map<String, dynamic> for JSON. '
        'For untyped runtime boundaries, add a targeted ignore with a local reason.',
  );

  AvoidDynamicExceptJsonMaps()
    : super(
        name: 'avoid_dynamic_except_json_maps',
        description: 'Bans dynamic except in Map<String, dynamic> JSON types.',
        code: code,
      );

  @override
  void checkNamedType(NamedType node) {
    if (node.name.lexeme != 'dynamic') return;
    if (_isAllowedJsonMapDynamic(node)) return;
    if (_isAllowedJsonMapCastDynamic(node)) return;
    reportAtNode(node);
  }

  bool _isAllowedJsonMapDynamic(NamedType node) {
    final parent = node.parent;
    if (parent is! TypeArgumentList) return false;
    final mapType = parent.parent;
    if (mapType is! NamedType || mapType.name.lexeme != 'Map') return false;
    final arguments = parent.arguments;
    if (arguments.length != 2) return false;
    final keyType = arguments.first;
    return keyType is NamedType && keyType.name.lexeme == 'String' && arguments.last == node;
  }

  bool _isAllowedJsonMapCastDynamic(NamedType node) {
    final parent = node.parent;
    if (parent is! TypeArgumentList) return false;
    final invocation = parent.parent;
    if (invocation is! MethodInvocation || invocation.methodName.name != 'cast') return false;

    final arguments = parent.arguments;
    if (arguments.length != 2 || arguments.last != node) return false;
    final keyType = arguments.first;
    return keyType is NamedType && keyType.name.lexeme == 'String';
  }
}
