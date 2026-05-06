import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/rules/source_scanner_rule.dart';

final List<ScannerRule> uiSourceRules = [
  scannerRule(
    code: const LintCode(
      'style_raw_token',
      'Avoid raw spacing, radius, size, and color tokens.',
      correctionMessage: 'Use design tokens.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description: 'Reports raw visual constants instead of design tokens.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (RegExp(r'\b(?:EdgeInsets|BorderRadius|Radius|SizedBox)\s*\([^)]*\d').hasMatch(line) ||
            RegExp(r'\b(?:EdgeInsets|BorderRadius|Radius)\.\w+\s*\([^)]*\d').hasMatch(line) ||
            RegExp(r'\bColor\s*\(\s*0x[0-9A-Fa-f]+').hasMatch(line)) {
          reporter.report(context, i, 0);
        }
      }
    },
  ),
  scannerRule(
    code: const LintCode(
      'style_raw_text_style',
      'Avoid raw TextStyle construction.',
      correctionMessage: 'Use the app theme text styles.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description: 'Reports raw TextStyle construction.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (RegExp(r'\bTextStyle\s*\(').hasMatch(line)) {
          reporter.report(context, i, line.indexOf('TextStyle'));
        }
      }
    },
  ),
  scannerRule(
    code: const LintCode(
      'strings_hardcoded',
      'Avoid hardcoded UI strings.',
      correctionMessage: 'Move text into a *Strings constants class.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description: 'Reports hardcoded UI strings.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        if (context.hasHardcodedUiString(context.source.code[i])) {
          reporter.report(context, i, 0);
        }
      }
    },
  ),
  scannerRule(
    code: const LintCode(
      'ui_snackbar_boundary',
      'UI widgets should not directly show snackbars.',
      correctionMessage: 'Dispatch a notifier action and let the shell own snackbar presentation.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Reports direct snackbar dispatches from UI widgets.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (context.isUiFile && context.dispatchesSnackbarFromUi(line)) {
          reporter.report(context, i, 0);
        }
      }
    },
  ),
  scannerRule(
    code: const LintCode(
      'a11y_text_scale_clamp',
      'Do not globally clamp text scaling.',
      correctionMessage: 'Fix responsive layout instead of clamping accessibility text size.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Reports app-level text scaling clamps.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (context.isAppRootFile && context.clampsTextScaling(line)) {
          reporter.report(context, i, 0);
        }
      }
    },
  ),
  scannerRule(
    code: const LintCode(
      'perf_build_work',
      'Avoid expensive work in build().',
      correctionMessage: 'Move sorting, filtering, formatting, and regex creation out of build.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description: 'Reports expensive collection or formatting work inside build methods.',
    scan: (reporter, context) {
      for (final method in context.methods.where((method) => method.name == 'build')) {
        for (var i = method.start; i <= method.end; i++) {
          final line = context.source.masked[i];
          if (RegExp(r'\.(?:sort|where|map|toList)\s*\(').hasMatch(line) ||
              RegExp(r'\b(?:DateFormat|RegExp)\s*\(').hasMatch(line)) {
            reporter.report(context, i, 0);
          }
        }
      }
    },
  ),
  scannerRule(
    code: const LintCode(
      'perf_listview_children',
      'Prefer ListView.builder for dynamic lists.',
      correctionMessage: 'Use builder/sliver variants instead of ListView(children: ...).',
      severity: DiagnosticSeverity.WARNING,
    ),
    description: 'Reports ListView(children: ...) usage.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (RegExp(r'\bListView\s*\([^)]*\bchildren\s*:').hasMatch(line)) {
          reporter.report(context, i, line.indexOf('ListView'));
        }
      }
    },
  ),
];
