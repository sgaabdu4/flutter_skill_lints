import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/function_body_rule.dart';

/// Avoids nullable Future, Stream, and collection return types.
///
/// Effective Dart recommends keeping async and collection containers
/// non-nullable. Put nullability on the produced value when that is the
/// semantic contract, or return an empty collection / explicit state.
class AvoidNullableAsyncOrCollectionReturnType
    extends GeneratedFunctionAndMethodReturnTypeCheckRule {
  static const LintCode code = LintCode(
    'avoid_nullable_async_or_collection_return_type',
    'Avoid nullable Future, Stream, and collection return types.',
    correctionMessage:
        'Return a non-null Future/Stream/collection. Put ? on the value type, return an empty collection, or model absence explicitly.',
    severity: DiagnosticSeverity.ERROR,
  );

  AvoidNullableAsyncOrCollectionReturnType()
    : super(
        name: 'avoid_nullable_async_or_collection_return_type',
        description: 'Avoids nullable Future, Stream, Iterable, List, Map, and Set returns.',
        code: code,
      );

  @override
  void checkReturnType(TypeAnnotation? returnType, {required bool isOverride}) {
    if (isOverride) return;
    final reported = _firstNullableAsyncOrCollection(returnType);
    if (reported == null) return;
    reportAtNode(reported);
  }

  NamedType? _firstNullableAsyncOrCollection(TypeAnnotation? type) {
    if (type is! NamedType) return null;

    if (_isTargetType(type) && type.question != null) {
      return type;
    }

    final typeArguments = type.typeArguments?.arguments;
    if (typeArguments == null) return null;
    for (final typeArgument in typeArguments) {
      final nested = _firstNullableAsyncOrCollection(typeArgument);
      if (nested != null) return nested;
    }

    return null;
  }

  bool _isTargetType(NamedType type) {
    final typeName = type.name.lexeme;
    final library = type.element?.library;
    return switch (typeName) {
      'Future' || 'Stream' => library?.isDartAsync == true,
      'Iterable' || 'List' || 'Map' || 'Set' => library?.isDartCore == true,
      _ => false,
    };
  }
}
