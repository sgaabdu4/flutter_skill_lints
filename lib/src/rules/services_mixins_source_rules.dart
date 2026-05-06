import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/rules/source_scanner_rule.dart';

final List<ScannerRule> servicesMixinsSourceRules = [
  scannerRule(
    code: const LintCode(
      'service_singleton',
      'Avoid new singleton instance fields.',
      correctionMessage: 'Use Riverpod providers or injected services.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Reports singleton instance fields in services.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (RegExp(r'\bstatic\s+final\s+(?:\w+\s+)?instance\s*=').hasMatch(line)) {
          reporter.report(context, i, line.indexOf('static'));
        }
      }
    },
  ),
  scannerRule(
    code: const LintCode(
      'mixin_mixin_class',
      'Avoid mixin class for capability mixins.',
      correctionMessage: 'Use mixin for reusable behavior.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Reports mixin class declarations for capability mixins.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (RegExp(r'^\s*mixin\s+class\s+\w+').hasMatch(line)) {
          reporter.report(context, i, line.indexOf('mixin'));
        }
      }
    },
  ),
  scannerRule(
    code: const LintCode(
      'mixin_name_suffix',
      'Mixin names should end with Mixin.',
      correctionMessage: 'Suffix capability mixins with Mixin.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Reports capability mixins without the Mixin suffix.',
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
  scannerRule(
    code: const LintCode(
      'mixin_mutable_state',
      'Mixins should not carry mutable state.',
      correctionMessage: 'Keep mixins stateless.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Reports mutable fields inside mixins.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        if (context.isMutableMixinField(i)) {
          reporter.report(context, i, 0);
        }
      }
    },
  ),
];
