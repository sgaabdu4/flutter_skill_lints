import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

import 'package:flutter_skill_lints/src/additional_lints/text_distance.dart';

/// Fix that appends a suffix to a class name.
class AddSuffixFix extends ResolvedCorrectionProducer {
  final String suffix;
  final FixKind _fixKind;

  AddSuffixFix._({required super.context, required this.suffix, required this._fixKind});

  /// Factory for adding "Notifier" suffix.
  static AddSuffixFix notifierFix({required CorrectionProducerContext context}) {
    return AddSuffixFix._(
      context: context,
      suffix: 'Notifier',
      fixKind: const FixKind(
        'flutter_skill_lints.fix.addNotifierSuffix',
        DartFixKindPriority.standard,
        'Add Notifier suffix',
      ),
    );
  }

  @override
  CorrectionApplicability get applicability => CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final nameToken = node.thisOrAncestorOfType<ClassDeclaration>()?.namePart.typeName;
    if (nameToken == null) return;

    final baseName = _stripMisspelledSuffix(nameToken.lexeme, suffix);

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.token(nameToken), '$baseName$suffix');
    });
  }

  /// Strips the tail of [name] that is the closest typo of [suffix], at most two edits away.
  static String _stripMisspelledSuffix(String name, String suffix) {
    final suffixLower = suffix.toLowerCase();
    var bestDistance = 3;
    var bestLength = 0;

    for (var len = suffix.length + 2; len >= suffix.length - 2; len--) {
      if (len <= 0 || len >= name.length) continue;

      final tail = name.substring(name.length - len);
      final distance = computeEditDistance(tail.toLowerCase(), suffixLower);
      if (distance > 0 && distance < bestDistance) {
        bestDistance = distance;
        bestLength = len;
      }
    }

    return bestLength == 0 ? name : name.substring(0, name.length - bestLength);
  }
}
