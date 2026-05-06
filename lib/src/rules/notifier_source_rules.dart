import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/rules/source_scanner_rule.dart';

final List<ScannerRule> notifierSourceRules = [
  scannerRule(
    code: const LintCode(
      'notifier_ensure_deps',
      'Mutation methods must initialize dependencies before writes.',
      correctionMessage:
          'Call an _ensure... helper before using repositories or ref.read dependencies.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Reports Notifier mutation methods that write before dependency initialization.',
    scan: (reporter, context) {
      for (final classSpan in context.classes.where((span) => span.isNotifier)) {
        final classMethods = context.methods.where((method) => classSpan.contains(method.start));
        for (final method in classMethods) {
          if (method.name == 'build') continue;

          var hasEnsure = false;
          var hasMutationDependency = false;
          var hasNullRepoReturn = false;
          for (var i = method.start; i <= method.end; i++) {
            final line = context.source.masked[i];
            if (line.contains('_ensure')) hasEnsure = true;
            if (line.contains('_repository') ||
                line.contains('_repo') ||
                line.contains('Repository') ||
                line.contains('ref.read(')) {
              hasMutationDependency = true;
            }
            if (RegExp(
              r'if\s*\(\s*_\w*(?:repo|repository)\w*\s*==\s*null\s*\)\s*return',
            ).hasMatch(line)) {
              hasNullRepoReturn = true;
            }
          }
          if (context.isMutationMethod(method.name) &&
              !hasEnsure &&
              (hasMutationDependency || hasNullRepoReturn)) {
            reporter.report(context, method.start, 0);
          }
        }
      }
    },
  ),
  scannerRule(
    code: const LintCode(
      'notifier_watch_method',
      'Avoid ref.watch inside notifier methods.',
      correctionMessage: 'Use ref.read in notifier methods.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Reports ref.watch calls inside Notifier methods.',
    scan: (reporter, context) {
      for (final classSpan in context.classes.where((span) => span.isNotifier)) {
        final classMethods = context.methods.where((method) => classSpan.contains(method.start));
        for (final method in classMethods) {
          if (method.name == 'build') continue;

          for (var i = method.start; i <= method.end; i++) {
            if (context.source.masked[i].contains('ref.watch(')) {
              reporter.report(context, method.start, 0);
              break;
            }
          }
        }
      }
    },
  ),
];
