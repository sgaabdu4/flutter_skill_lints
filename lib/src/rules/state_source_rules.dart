import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/rules/source_scanner_rule.dart';

final List<ScannerRule> stateSourceRules = [
  /// Do not store raw API responses in state.
  ///
  /// Why: Flags raw JSON or response values stored in UI state. Extract the fields needed by
  /// the UI.
  scannerRule(
    code: const LintCode(
      'state_raw_response',
      'Do not store raw API responses in state.',
      correctionMessage: 'Extract the fields needed by the UI.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags raw JSON or response values stored in UI state so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (RegExp(
          r'\bstate\s*=\s*state\.copyWith\s*\([^)]*(?:rawJson|response|json)',
        ).hasMatch(line)) {
          reporter.report(context, i, line.indexOf('state'));
        }
      }
    },
  ),

  /// Avoid broad invalidation before navigation-critical route changes.
  ///
  /// Why: Flags broad invalidation before navigation-critical route changes. Persist,
  /// targeted-sync state, then navigate.
  scannerRule(
    code: const LintCode(
      'state_broad_invalidation',
      'Avoid broad invalidation before navigation-critical route changes.',
      correctionMessage: 'Persist, targeted-sync state, then navigate.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags broad invalidation before navigation-critical route changes so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (final method in context.methods) {
        for (var i = method.start; i <= method.end; i++) {
          final line = context.source.masked[i];
          if (line.contains('ref.invalidate(') &&
              context.isMutationMethod(method.name) &&
              context.near(i, 'go(', 8)) {
            reporter.report(context, i, line.indexOf('ref'));
          }
        }
      }
    },
  ),

  /// Use context.mounted after async gaps in widgets.
  ///
  /// Why: Flags widget mounted checks after async gaps instead of context.mounted. Replace
  /// mounted checks with context.mounted for BuildContext safety.
  scannerRule(
    code: const LintCode(
      'async_context_mounted_style',
      'Use context.mounted after async gaps in widgets.',
      correctionMessage: 'Replace mounted checks with context.mounted for BuildContext safety.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags widget mounted checks after async gaps instead of context.mounted so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (final method in context.methods) {
        for (var i = method.start; i <= method.end; i++) {
          final line = context.source.masked[i];
          if (line.contains('if (!mounted)') && context.near(i, 'await ', 8)) {
            reporter.report(context, i, line.indexOf('mounted'));
          }
        }
      }
    },
  ),
];
