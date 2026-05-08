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
  /// Why: Flags typed route push calls in shell navigation widgets. Use
  /// StatefulNavigationShell.goBranch() for tab changes.
  scannerRule(
    code: const LintCode(
      'router_shell_tab_push',
      'Do not push shell tab routes.',
      correctionMessage: 'Use StatefulNavigationShell.goBranch() for tab changes.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags typed route push calls in shell navigation widgets so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      final shellTabPush = RegExp(
        r'\bconst\s+[A-Z]\w*Route\s*'
        r'\([^)]*\)\s*\.\s*push\s*(?:<[^>]+>)?\s*\(',
      );

      for (final method in context.methods) {
        final body = context.source.masked.sublist(method.start, method.end + 1).join('\n');
        if (!body.contains('StatefulNavigationShell') && !body.contains('goBranch')) continue;

        for (var i = method.start; i <= method.end; i++) {
          final line = context.source.masked[i];
          if (shellTabPush.hasMatch(line)) {
            reporter.report(context, i, 0);
          }
        }
      }
    },
  ),
];
