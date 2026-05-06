import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/rules/source_scanner_rule.dart';

final List<ScannerRule> riverpodSourceRules = [
  scannerRule(
    code: const LintCode(
      'riverpod_read_init_state',
      'Avoid ref.read in initState.',
      correctionMessage: 'Defer reads with a post-frame callback.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Reports ref.read calls made from initState.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (context.isInitStateRead(i)) {
          reporter.report(context, i, line.indexOf('ref.read'));
        }
      }
    },
  ),
  scannerRule(
    code: const LintCode(
      'riverpod_service_locator',
      'Avoid service locator classes in Riverpod apps.',
      correctionMessage: 'Model dependencies with providers.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Reports service locator classes in Riverpod apps.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (RegExp(
          r'\bclass\s+(?:ServiceFactory|ServiceLocator|BackendProvider)\b',
        ).hasMatch(line)) {
          reporter.report(context, i, line.indexOf('class'));
        }
      }
    },
  ),
  scannerRule(
    code: const LintCode(
      'riverpod_watch_no_select',
      'Prefer select when watching state in leaf widgets.',
      correctionMessage: 'Use ref.watch(provider.select((value) => value.field)).',
      severity: DiagnosticSeverity.WARNING,
    ),
    description: 'Reports broad ref.watch calls that do not use select.',
    scan: (reporter, context) {
      // Only fire inside widget build() methods. Computed providers and
      // service factories legitimately call ref.watch without .select.
      // Exempt .notifier) — caller wants the whole notifier, no field to select.
      for (final method in context.methods.where((m) => m.name == 'build')) {
        for (var i = method.start; i <= method.end; i++) {
          final line = context.source.masked[i];
          if (RegExp(r'\bref\s*\.\s*watch\s*\(').hasMatch(line) &&
              !line.contains('.select(') &&
              !line.contains('.notifier)')) {
            reporter.report(context, i, line.indexOf('ref'));
          }
        }
      }
    },
  ),
  scannerRule(
    code: const LintCode(
      'riverpod_keepalive_family',
      'Avoid keepAlive family providers.',
      correctionMessage: 'Use auto-dispose families unless the cache is bounded.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description: 'Reports keepAlive Riverpod families with required parameters.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (RegExp(r'@Riverpod\s*\([^)]*keepAlive\s*:\s*true').hasMatch(line) &&
            context.near(i, 'required ', 5)) {
          reporter.report(context, i, line.indexOf('@Riverpod'));
        }
      }
    },
  ),
];
