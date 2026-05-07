import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/rules/source_scanner_rule.dart';

final List<ScannerRule> servicesExtendedSourceRules = [
  /// Static-only helpers must not own side effects.
  ///
  /// Why: Flags static-only utility classes that touch IO, SDKs, time, or randomness. Use a
  /// Riverpod provider or a facade with a swappable backend.
  scannerRule(
    code: const LintCode(
      'service_static_side_effect',
      'Static-only helpers must not own side effects.',
      correctionMessage: 'Use a Riverpod provider or a facade with a swappable backend.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags static-only utility classes that touch IO, SDKs, time, or randomness so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (final classSpan in context.classes) {
        if (classSpan.name == 'Crash') continue;
        final body = context.source.masked.sublist(classSpan.start, classSpan.end + 1).join('\n');
        if (!RegExp(r'^\s*abstract\s+final\s+class\b', multiLine: true).hasMatch(body)) {
          continue;
        }
        if (!RegExp(
          r'\b(?:Firebase|Hive|SharedPreferences|HttpClient|DateTime\.now|Random\s*\()',
        ).hasMatch(body)) {
          continue;
        }
        reporter.report(context, classSpan.start, 0);
      }
    },
  ),

  /// Do not allocate Random per call.
  ///
  /// Why: Flags Random construction inside methods. Hoist Random to a module-level final and
  /// reuse it.
  scannerRule(
    code: const LintCode(
      'service_random_per_call',
      'Do not allocate Random per call.',
      correctionMessage: 'Hoist Random to a module-level final and reuse it.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags Random construction inside methods so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (final method in context.methods) {
        for (var i = method.start; i <= method.end; i++) {
          final line = context.source.masked[i];
          if (RegExp(r'\b(?:math\.)?Random\s*\(').hasMatch(line)) {
            reporter.report(context, i, line.indexOf('Random'));
          }
        }
      }
    },
  ),

  /// Avoid fire-and-forget calls in tests.
  ///
  /// Why: Flags unawaited calls from test files. Await the Future directly in tests and
  /// assert on the fake service.
  scannerRule(
    code: const LintCode(
      'fire_forget_in_tests',
      'Avoid fire-and-forget calls in tests.',
      correctionMessage: 'Await the Future directly in tests and assert on the fake service.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags unawaited calls from test files so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      if (!context.isTestFile) return;
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (RegExp(r'\bunawaited\s*\(').hasMatch(line)) {
          reporter.report(context, i, line.indexOf('unawaited'));
        }
      }
    },
  ),
];
