import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/function_body_rule.dart';

/// Avoids `FutureOr<T>` as a function or method return type.
///
/// Effective Dart recommends returning a stable sync or async shape. Accepting
/// `FutureOr<T>` in parameters or callback return types can be useful, but
/// returning it makes callers branch or always `await`.
class AvoidFutureOrReturnType extends GeneratedFunctionAndMethodReturnTypeCheckRule {
  static const LintCode code = LintCode(
    'avoid_futureor_return_type',
    'Avoid FutureOr as a return type.',
    correctionMessage:
        'Return Future<T> for async APIs, T for sync APIs, or Future<void> for async APIs without a value.',
    severity: DiagnosticSeverity.ERROR,
  );

  AvoidFutureOrReturnType()
    : super(
        name: 'avoid_futureor_return_type',
        description: 'Avoids FutureOr<T> as a public API return type.',
        code: code,
      );

  @override
  void checkReturnType(TypeAnnotation? returnType, {required bool isOverride}) {
    if (returnType is! NamedType) return;
    if (returnType.name.lexeme != 'FutureOr') return;
    if (returnType.element?.library?.isDartAsync != true) return;

    reportAtNode(returnType);
  }
}
