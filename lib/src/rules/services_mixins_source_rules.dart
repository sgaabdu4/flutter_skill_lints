import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/rules/source_scanner_rule.dart';

final List<ScannerRule> servicesMixinsSourceRules = [
  /// Avoid new singleton instance fields.
  ///
  /// Why: Flags singleton instance fields in services. Use Riverpod providers or injected
  /// services.
  scannerRule(
    code: const LintCode(
      'service_singleton',
      'Avoid new singleton instance fields.',
      correctionMessage: 'Use Riverpod providers or injected services.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags singleton instance fields in services so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (RegExp(r'\bstatic\s+final\s+(?:\w+\s+)?instance\s*=').hasMatch(line)) {
          reporter.report(context, i, line.indexOf('static'));
        }
      }
    },
  ),

  /// Avoid mixin class for capability mixins.
  ///
  /// Why: Flags mixin class declarations for capability mixins. Use mixin for reusable
  /// behavior.
  scannerRule(
    code: const LintCode(
      'mixin_mixin_class',
      'Avoid mixin class for capability mixins.',
      correctionMessage: 'Use mixin for reusable behavior.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags mixin class declarations for capability mixins so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (RegExp(r'^\s*mixin\s+class\s+\w+').hasMatch(line)) {
          reporter.report(context, i, line.indexOf('mixin'));
        }
      }
    },
  ),

  /// Mixin names should end with Mixin.
  ///
  /// Why: Flags capability mixins without the Mixin suffix. Suffix capability mixins with
  /// Mixin.
  scannerRule(
    code: const LintCode(
      'mixin_name_suffix',
      'Mixin names should end with Mixin.',
      correctionMessage: 'Suffix capability mixins with Mixin.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags capability mixins without the Mixin suffix so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        final mixinMatch = RegExp(r'^\s*mixin(?:\s+class)?\s+(\w+)').firstMatch(line);
        if (mixinMatch != null && !(mixinMatch.group(1) ?? '').endsWith('Mixin')) {
          reporter.report(context, i, mixinMatch.start);
        }
      }
    },
  ),

  /// Mixins should not carry mutable state.
  ///
  /// Why: Flags mutable fields inside mixins. Keep mixins stateless.
  scannerRule(
    code: const LintCode(
      'mixin_mutable_state',
      'Mixins should not carry mutable state.',
      correctionMessage: 'Keep mixins stateless.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags mutable fields inside mixins so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        if (context.isMutableMixinField(i)) {
          reporter.report(context, i, 0);
        }
      }
    },
  ),
];
