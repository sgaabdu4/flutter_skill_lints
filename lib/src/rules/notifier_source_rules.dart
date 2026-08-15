import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/rules/source_scanner_rule.dart';

final List<ScannerRule> notifierSourceRules = [
  /// Do not cache stable repositories/services in generated notifiers.
  ///
  /// Why: Riverpod provider caching is the dependency SSOT. A notifier-local
  /// `_repository` / `_service` field creates a second lifecycle and commonly
  /// leads to null short-circuits or stale dependencies. Resolve deps lazily
  /// with `ref.read` through a stateless helper/mixin instead.
  scannerRule(
    code: const LintCode(
      'notifier_local_dependency_cache',
      'Do not cache repositories or services in notifiers.',
      correctionMessage:
          'Resolve stable dependencies from their provider via a stateless helper/mixin instead of a notifier-local field.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags notifier-local repository/service fields so Riverpod provider caching remains the dependency source of truth.',
    scan: (reporter, context) {
      if (context.isTestFile) return;

      for (final classSpan in context.classes.where((span) => span.isNotifier)) {
        final classMethods = context.methods
            .where((method) => classSpan.contains(method.start))
            .toList();
        for (var i = classSpan.start + 1; i < classSpan.end; i++) {
          if (_isInsideMethod(classMethods, i)) continue;
          final line = context.source.masked[i];
          final match = _notifierLocalDependencyField.firstMatch(line);
          if (match == null) continue;
          final fieldName = match.group(1);
          final column = fieldName == null ? match.start : line.indexOf(fieldName, match.start);
          reporter.report(context, i, column);
        }
      }
    },
  ),

  /// Mutation methods must initialize dependencies before writes.
  ///
  /// Why: Flags Notifier mutation methods that write before dependency initialization. Call
  /// an _ensure... helper before using repositories or ref.read dependencies.
  scannerRule(
    code: const LintCode(
      'notifier_ensure_deps',
      'Mutation methods must initialize dependencies before writes.',
      correctionMessage:
          'Call an _ensure... helper before using repositories or ref.read dependencies.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags Notifier mutation methods that write before dependency initialization so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (final classSpan in context.classes.where((span) => span.isNotifier)) {
        final classMethods = context.methods.where((method) => classSpan.contains(method.start));
        for (final method in classMethods) {
          if (method.name != 'build' && _notifierNeedsEnsure(context, method)) {
            reporter.report(context, method.start, 0);
          }
        }
      }
    },
  ),

  /// Avoid ref.watch inside notifier methods.
  ///
  /// Why: Flags ref.watch calls inside Notifier methods. Use ref.read in notifier methods.
  scannerRule(
    code: const LintCode(
      'notifier_watch_method',
      'Avoid ref.watch inside notifier methods.',
      correctionMessage: 'Use ref.read in notifier methods.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags ref.watch calls inside Notifier methods so the Flutter skill violation is shown during analysis.',
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

bool _notifierNeedsEnsure(SourceScannerContext context, ScannerMethodSpan method) {
  var hasEnsure = false;
  var hasDependency = false;
  var hasNullRepositoryReturn = false;
  for (var i = method.start; i <= method.end; i++) {
    final line = context.source.masked[i];
    hasEnsure = hasEnsure || _hasEnsureCall(line);
    hasDependency = hasDependency || _hasMutationDependency(line);
    hasNullRepositoryReturn = hasNullRepositoryReturn || _hasNullRepositoryReturn(line);
  }
  return context.isMutationMethod(method.name) &&
      !hasEnsure &&
      (hasDependency || hasNullRepositoryReturn);
}

bool _hasEnsureCall(String line) =>
    line.contains('_ensure') || RegExp(r'\bensure[A-Z]\w*\s*\(').hasMatch(line);

bool _hasMutationDependency(String line) =>
    line.contains('_repository') ||
    line.contains('_repo') ||
    line.contains('Repository') ||
    line.contains('ref.read(');

bool _hasNullRepositoryReturn(String line) =>
    RegExp(r'if\s*\(\s*_\w*(?:repo|repository)\w*\s*==\s*null\s*\)\s*return').hasMatch(line);

final _notifierLocalDependencyField = RegExp(
  r'^\s+(?:(?:late|final)\s+)*(?:I?[A-Z][A-Za-z0-9_]*(?:Repository|Service|Datasource|DataSource))\??\s+(_[A-Za-z0-9_]*(?:repo|repository|service|datasource|dataSource)[A-Za-z0-9_]*)\s*(?:[=;])',
);

bool _isInsideMethod(List<ScannerMethodSpan> methods, int lineIndex) =>
    methods.any((method) => lineIndex >= method.start && lineIndex <= method.end);
