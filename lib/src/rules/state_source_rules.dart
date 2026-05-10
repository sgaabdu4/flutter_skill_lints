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

  /// Do not surface raw exception strings in state.
  ///
  /// Why: Flags `error: e.toString()` state updates. Convert failures to
  /// structured app exceptions or user-safe messages before they enter UI state.
  scannerRule(
    code: const LintCode(
      'state_raw_error_to_string',
      'Do not surface raw exception strings in state.',
      correctionMessage: 'Use AppException or another structured, user-safe error message.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags raw error toString state updates so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      final rawErrorString = RegExp(r'\berror\s*:\s*[A-Za-z_]\w*\.toString\(\)');
      for (var i = 0; i < context.source.length; i++) {
        final match = rawErrorString.firstMatch(context.source.masked[i]);
        if (match != null) {
          reporter.report(context, i, match.start);
        }
      }
    },
  ),

  /// Freezed state should not carry nullable raw error strings.
  ///
  /// Why: Flags String? error fields in Freezed state classes. Model failures as
  /// AsyncError, failure unions, or structured app exceptions.
  scannerRule(
    code: const LintCode(
      'state_freezed_nullable_error',
      'Do not store nullable raw error strings in Freezed state.',
      correctionMessage: 'Use AsyncError, a failure union, or a structured app exception.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags String? error fields in Freezed state classes so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      final nullableError = RegExp(r'\bString\?\s+error\b');
      for (final classSpan in context.classes) {
        if (!context.hasFreezedAnnotation(classSpan)) continue;
        if (!classSpan.name.endsWith('State')) continue;
        for (var i = classSpan.start; i <= classSpan.end; i++) {
          final match = nullableError.firstMatch(context.source.masked[i]);
          if (match != null) {
            reporter.report(context, i, match.start);
          }
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
