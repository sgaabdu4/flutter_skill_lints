import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/rules/source_scanner_rule.dart';

final List<ScannerRule> freezedExtendedSourceRules = [
  /// Freezed classes with custom members need a private constructor.
  ///
  /// Why: Flags Freezed classes with custom getters/methods but no private constructor. Add
  /// const ClassName._(); before custom getters or methods.
  scannerRule(
    code: const LintCode(
      'freezed_missing_private_constructor',
      'Freezed classes with custom members need a private constructor.',
      correctionMessage: 'Add const ClassName._(); before custom getters or methods.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags Freezed classes with custom getters/methods but no private constructor so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (final classSpan in context.classes) {
        final annotationStart = classSpan.start - 4 < 0 ? 0 : classSpan.start - 4;
        final leading = context.source.masked
            .sublist(annotationStart, classSpan.start + 1)
            .join('\n');
        if (!leading.contains('@freezed') && !leading.contains('@Freezed')) continue;

        final body = context.source.masked.sublist(classSpan.start, classSpan.end + 1).join('\n');
        if (RegExp('${classSpan.name}._\\s*\\(').hasMatch(body)) continue;

        final hasCustomGetter = RegExp(
          r'^\s*(?:[A-Za-z_][\w<>,? ]+\s+)?get\s+\w+\s*=>',
          multiLine: true,
        ).hasMatch(body);
        final hasCustomMethod =
            RegExp(
              r'^\s*(?!factory\b)(?!const\s+factory\b)(?!@override\b)(?:[A-Za-z_][\w<>,? ]+\s+)+\w+\s*\(',
              multiLine: true,
            ).allMatches(body).any((match) {
              final text = match.group(0) ?? '';
              return !text.contains('fromJson(') && !text.contains('${classSpan.name}(');
            });

        if (hasCustomGetter || hasCustomMethod) {
          reporter.report(context, classSpan.start, 0);
        }
      }
    },
  ),
];
