import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/rules/source_scanner_rule.dart';

final List<ScannerRule> routerExtendedSourceRules = [
  /// Keep GoRouter redirect decisions in a pure resolver.
  ///
  /// Why: Flags inline branching inside GoRouter redirect closures. Move redirect branching
  /// into a resolve...Redirect function and matrix-test it.
  scannerRule(
    code: const LintCode(
      'router_impure_redirect',
      'Keep GoRouter redirect decisions in a pure resolver.',
      correctionMessage:
          'Move redirect branching into a resolve...Redirect function and matrix-test it.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags inline branching inside GoRouter redirect closures so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (!line.contains('redirect:')) continue;
        final windowEnd = (i + 16).clamp(0, context.source.length - 1);
        final window = context.source.masked.sublist(i, windowEnd + 1).join('\n');
        if (RegExp(r'\bresolve\w*Redirect\s*\(').hasMatch(window)) continue;
        if (RegExp(r'\b(?:if|switch)\s*\(').hasMatch(window)) {
          reporter.report(context, i, line.indexOf('redirect'));
        }
      }
    },
  ),

  /// Do not push shell tab routes.
  ///
  /// Why: Flags typed route push/go calls in shell navigation widgets. Use
  /// StatefulNavigationShell.goBranch() for tab changes.
  scannerRule(
    code: const LintCode(
      'router_shell_tab_push',
      'Do not push shell tab routes.',
      correctionMessage: 'Use StatefulNavigationShell.goBranch() for tab changes.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags typed route push/go calls in shell navigation widgets so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      final text = context.source.masked.join('\n');
      if (!text.contains('StatefulNavigationShell') && !text.contains('goBranch')) return;
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (RegExp(
          r'\b[A-Z]\w*Route\s*\([^)]*\)\s*\.\s*(?:push|go)\s*(?:<[^>]+>)?\s*\(',
        ).hasMatch(line)) {
          reporter.report(context, i, 0);
        }
      }
    },
  ),
];
