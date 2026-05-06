import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/rules/source_scanner_rule.dart';

final List<ScannerRule> stateSourceRules = [
  scannerRule(
    code: const LintCode(
      'state_raw_response',
      'Do not store raw API responses in state.',
      correctionMessage: 'Extract the fields needed by the UI.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description: 'Reports raw JSON or response values stored in UI state.',
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
  scannerRule(
    code: const LintCode(
      'state_broad_invalidation',
      'Avoid broad invalidation before navigation-critical route changes.',
      correctionMessage: 'Persist, targeted-sync state, then navigate.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description: 'Reports broad invalidation before navigation-critical route changes.',
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
  scannerRule(
    code: const LintCode(
      'async_context_mounted_style',
      'Use context.mounted after async gaps in widgets.',
      correctionMessage: 'Replace mounted checks with context.mounted for BuildContext safety.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Reports widget mounted checks after async gaps instead of context.mounted.',
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
