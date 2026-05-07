import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/rules/source_scanner_rule.dart';

final List<ScannerRule> dataCrashSourceRules = [
  /// Avoid log-and-rethrow in data layers.
  ///
  /// Why: Flags log-and-rethrow patterns in data layers. Let callers log once at the
  /// boundary.
  scannerRule(
    code: const LintCode(
      'data_log_rethrow',
      'Avoid log-and-rethrow in data layers.',
      correctionMessage: 'Let callers log once at the boundary.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags log-and-rethrow patterns in data layers so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (context.isDataPath &&
            RegExp(r'\b(?:print|debugPrint|log)\s*\(').hasMatch(line) &&
            context.near(i, 'rethrow', 6)) {
          reporter.report(context, i, 0);
        }
      }
    },
  ),

  /// Crash reporting may include PII.
  ///
  /// Why: Flags possible PII values sent to crash reporting. Do not send email, name, phone,
  /// token, password, address, or user IDs.
  scannerRule(
    code: const LintCode(
      'crash_possible_pii',
      'Crash reporting may include PII.',
      correctionMessage: 'Do not send email, name, phone, token, password, address, or user IDs.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags possible PII values sent to crash reporting so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (RegExp(r'\b(?:Crash\.|FirebaseCrashlytics)').hasMatch(line) &&
            RegExp(
              r'\b(?:email|name|phone|token|password|ssn|address|userId)\b',
              caseSensitive: false,
            ).hasMatch(line)) {
          reporter.report(context, i, 0);
        }
      }
    },
  ),
];
