import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/rules/source_scanner_rule.dart';

final List<ScannerRule> showcaseSourceRules = [
  /// Store listenManual subscriptions.
  ///
  /// Why: Flags listenManual calls whose subscription handle is not stored. Keep and close
  /// the ProviderSubscription handle.
  scannerRule(
    code: const LintCode(
      'showcase_listen_manual_handle',
      'Store listenManual subscriptions.',
      correctionMessage: 'Keep and close the ProviderSubscription handle.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags listenManual calls whose subscription handle is not stored so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (line.contains('ref.listenManual') && !line.contains('=')) {
          reporter.report(context, i, line.indexOf('ref.listenManual'));
        }
      }
    },
  ),

  /// Avoid prev != null showcase replay guards.
  ///
  /// Why: Flags prev != null showcase replay guards. Compare previous and next values
  /// instead.
  scannerRule(
    code: const LintCode(
      'showcase_prev_null_guard',
      'Avoid prev != null showcase replay guards.',
      correctionMessage: 'Compare previous and next values instead.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags prev != null showcase replay guards so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (line.contains('prev != null') && context.near(i, 'showcase', 12)) {
          reporter.report(context, i, line.indexOf('prev'));
        }
      }
    },
  ),

  /// Avoid default ShowcaseView scope registration.
  ///
  /// Why: Flags default ShowcaseView scope registration. Use a named ShowcaseView scope.
  scannerRule(
    code: const LintCode(
      'showcase_default_scope',
      'Avoid default ShowcaseView scope registration.',
      correctionMessage: 'Use a named ShowcaseView scope.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags default ShowcaseView scope registration so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (RegExp(r'\bShowcaseView\s*\.\s*register\s*\(\s*\)').hasMatch(line)) {
          reporter.report(context, i, line.indexOf('ShowcaseView'));
        }
      }
    },
  ),

  /// disposeOnTap requires explicit target click handling.
  ///
  /// Why: Flags disposeOnTap usage without nearby onTargetClick handling. Add onTargetClick
  /// when disposeOnTap is true.
  scannerRule(
    code: const LintCode(
      'showcase_dispose_on_tap',
      'disposeOnTap requires explicit target click handling.',
      correctionMessage: 'Add onTargetClick when disposeOnTap is true.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags disposeOnTap usage without nearby onTargetClick handling so the Flutter skill violation is shown during analysis.',
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
