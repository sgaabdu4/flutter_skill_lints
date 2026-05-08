import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/rules/source_scanner_rule.dart';

final List<ScannerRule> showcaseExtendedSourceRules = [
  /// Use showcaseview v5 APIs only.
  ///
  /// Why: Flags showcaseview v4 API usage. Replace ShowCaseWidget.of(context) with
  /// ShowcaseView named scopes.
  scannerRule(
    code: const LintCode(
      'showcase_v4_api',
      'Use showcaseview v5 APIs only.',
      correctionMessage: 'Replace ShowCaseWidget.of(context) with ShowcaseView named scopes.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags showcaseview v4 API usage so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (RegExp(r'\bShowCaseWidget\s*\.\s*of\s*\(').hasMatch(line)) {
          reporter.report(context, i, line.indexOf('ShowCaseWidget'));
        }
      }
    },
  ),

  /// Guard ShowcaseView.getNamed(scope).
  ///
  /// Why: Flags ShowcaseView.getNamed calls with no nearby try/catch guard. Wrap getNamed
  /// calls in try/catch or a safe helper until the scope is registered.
  scannerRule(
    code: const LintCode(
      'showcase_get_named_unhandled',
      'Guard ShowcaseView.getNamed(scope).',
      correctionMessage:
          'Wrap getNamed calls in try/catch or a safe helper until the scope is registered.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags ShowcaseView.getNamed calls with no nearby try/catch guard so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (!RegExp(r'\bShowcaseView\s*\.\s*getNamed\s*\(').hasMatch(line)) continue;
        if (context.near(i, 'try', 3) || context.near(i, 'catch', 8)) continue;
        reporter.report(context, i, line.indexOf('ShowcaseView'));
      }
    },
  ),

  /// Showcase scopes should use centralized constants.
  ///
  /// Why: Flags inline string showcase scopes. Use ShowcaseConstants.* instead of inline
  /// scope strings.
  scannerRule(
    code: const LintCode(
      'showcase_scope_string_literal',
      'Showcase scopes should use centralized constants.',
      correctionMessage: 'Use ShowcaseConstants.* instead of inline scope strings.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags inline string showcase scopes so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      if (context.isTestFile) return;

      for (var i = 0; i < context.source.length; i++) {
        final code = context.source.code[i];
        final line = context.source.masked[i];
        if (RegExp(r'''\bscope\s*:\s*['"][^'"]+['"]''').hasMatch(code) &&
            context.near(i, 'Showcase', 6)) {
          reporter.report(context, i, line.indexOf('scope'));
        }
      }
    },
  ),
];
