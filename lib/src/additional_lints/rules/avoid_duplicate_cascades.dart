import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';

/// Warns when a cascade expression contains duplicate cascade sections.
///
/// Duplicate cascades are usually the result of a copy-paste error and
/// indicate a bug. The last assignment wins, making earlier duplicates
/// dead code.
///
/// **Bad:**
/// ```dart
/// value
///   ..field = '2'
///   ..field = '1';
/// ```
///
/// **Good:**
/// ```dart
/// value
///   ..field1 = '2'
///   ..field2 = '1';
/// ```
class AvoidDuplicateCascades extends CascadeExpressionCheckRule {
  static const LintCode code = LintCode(
    'avoid_duplicate_cascades',
    'Duplicate cascade section found.',
    correctionMessage: 'Remove the duplicate cascade section.',
  );

  AvoidDuplicateCascades()
    : super(
        name: 'avoid_duplicate_cascades',
        description:
            'Warns when a cascade expression has duplicate cascade '
            'sections.',
        code: code,
      );

  @override
  void checkCascadeExpression(CascadeExpression node) {
    final sections = node.cascadeSections;
    if (sections.length < 2) return;

    final seen = <String>{};
    for (final section in sections) {
      final key = _sectionKey(section);
      if (key == null) continue;

      if (!seen.add(key)) {
        reportAtNode(section);
      }
    }
  }

  /// Returns a string key that uniquely identifies a cascade section's
  /// operation. Two sections with the same key are considered duplicates.
  ///
  /// Returns `null` for unrecognized section types.
  static String? _sectionKey(Expression section) {
    return switch (section) {
      // ..field = value or ..[index] = value
      AssignmentExpression(:final leftHandSide, :final rightHandSide) =>
        'assign:${leftHandSide.toSource()}=${rightHandSide.toSource()}',
      // ..method(args)
      MethodInvocation(:final methodName, :final argumentList) =>
        'call:${methodName.name}(${argumentList.arguments.map((a) => a.toSource()).join(',')})',
      // ..[index]
      IndexExpression(:final index) => 'index:${index.toSource()}',
      // ..property
      PropertyAccess(:final propertyName) => 'prop:${propertyName.name}',
      _ => null,
    };
  }
}
