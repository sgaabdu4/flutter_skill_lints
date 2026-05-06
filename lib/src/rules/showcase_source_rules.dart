import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/rules/source_scanner_rule.dart';

final List<ScannerRule> showcaseSourceRules = [
  scannerRule(
    code: const LintCode(
      'showcase_listen_manual_handle',
      'Store listenManual subscriptions.',
      correctionMessage: 'Keep and close the ProviderSubscription handle.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Reports listenManual calls whose subscription handle is not stored.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (line.contains('ref.listenManual') && !line.contains('=')) {
          reporter.report(context, i, line.indexOf('ref.listenManual'));
        }
      }
    },
  ),
  scannerRule(
    code: const LintCode(
      'showcase_prev_null_guard',
      'Avoid prev != null showcase replay guards.',
      correctionMessage: 'Compare previous and next values instead.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Reports prev != null showcase replay guards.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (line.contains('prev != null') && context.near(i, 'showcase', 12)) {
          reporter.report(context, i, line.indexOf('prev'));
        }
      }
    },
  ),
  scannerRule(
    code: const LintCode(
      'showcase_default_scope',
      'Avoid default ShowcaseView scope registration.',
      correctionMessage: 'Use a named ShowcaseView scope.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Reports default ShowcaseView scope registration.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (RegExp(r'\bShowcaseView\s*\.\s*register\s*\(\s*\)').hasMatch(line)) {
          reporter.report(context, i, line.indexOf('ShowcaseView'));
        }
      }
    },
  ),
  scannerRule(
    code: const LintCode(
      'showcase_dispose_on_tap',
      'disposeOnTap requires explicit target click handling.',
      correctionMessage: 'Add onTargetClick when disposeOnTap is true.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Reports disposeOnTap usage without nearby onTargetClick handling.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (line.contains('disposeOnTap: true') && !context.near(i, 'onTargetClick', 4)) {
          reporter.report(context, i, line.indexOf('disposeOnTap'));
        }
      }
    },
  ),
];
