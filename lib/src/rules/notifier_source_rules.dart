import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/rules/notifier_dependency_capture.dart';
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
      correctionMessage: 'Resolve stable dependencies from their provider via a stateless helper/mixin instead of a notifier-local field.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags notifier-local repository/service fields so Riverpod provider caching remains the dependency source of truth.',
    scan: (reporter, context) {
      if (context.isTestFile) return;
      final notifierNames = {
        for (final span in context.classes)
          if (span.isNotifier) span.name,
      };
      for (final declaration in context.unit.declarations.whereType<ClassDeclaration>()) {
        if (!notifierNames.contains(declaration.namePart.typeName.lexeme)) continue;
        for (final field in notifierDependencyCacheFields(declaration)) {
          final location = context.unit.lineInfo.getLocation(field.name.offset);
          reporter.report(context, location.lineNumber - 1, location.columnNumber - 1);
        }
      }
    },
  ),

  /// Mutation methods must resolve dependencies before writes or awaits.
  ///
  /// Why: Flags Notifier mutation methods that use repositories or provider reads without
  /// capturing their operation in a final local before the first state write or await.
  scannerRule(
    code: const LintCode(
      'notifier_ensure_deps',
      'Mutation methods must initialize dependencies before writes.',
      correctionMessage: 'Capture the operation from ref.read(...) in a final local before the first state write or await.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags Notifier mutation methods that access dependencies without resolving their operation before state writes or awaits.',
    scan: (reporter, context) {
      for (final classSpan in context.classes.where((span) => span.isNotifier)) {
        final classMethods = context.methods.where((method) => classSpan.contains(method.start));
        for (final method in classMethods) {
          if (method.name != 'build' && notifierNeedsDependencyEnsure(context, classSpan, method)) {
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
    description: 'Flags ref.watch calls inside Notifier methods so the Flutter skill violation is shown during analysis.',
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
