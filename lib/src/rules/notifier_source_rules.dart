import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/riverpod_type_checkers.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';
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

  /// Dispose notifier Timer fields with ref.onDispose.
  ///
  /// Why: performance.md requires timers owned by a notifier to be disposed via
  /// `ref.onDispose()`. A `Timer` field in a notifier with no `ref.onDispose`
  /// keeps firing after the provider is disposed.
  scannerRule(
    code: const LintCode(
      'notifier_timer_without_on_dispose',
      'Cancel notifier Timer fields in ref.onDispose.',
      correctionMessage: 'Register ref.onDispose(() => _timer?.cancel()) in build().',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags dart:async Timer fields in Riverpod notifiers that never register ref.onDispose so the Flutter skill violation is shown during analysis.',
    scan: _scanUndisposedNotifierTimers,
  ),
];

const _timerChecker = TypeChecker.fromUrl('dart:async#Timer');
const _refChecker = TypeChecker.fromName('Ref', packageName: 'riverpod');

void _scanUndisposedNotifierTimers(ScannerRuleReporter reporter, SourceScannerContext context) {
  for (final declaration in context.unit.declarations.whereType<ClassDeclaration>()) {
    final element = declaration.declaredFragment?.element;
    if (element == null || !anyNotifierChecker.isSuperOf(element)) continue;
    if (collectNodes<MethodInvocation>(declaration).any(_isRefOnDispose)) continue;
    for (final field in declaration.body.members.whereType<FieldDeclaration>()) {
      if (field.isStatic) continue;
      for (final variable in field.fields.variables) {
        final type = variable.declaredFragment?.element.type;
        if (type != null && _timerChecker.isExactlyType(type)) {
          reporter.reportNode(context, variable);
        }
      }
    }
  }
}

bool _isRefOnDispose(MethodInvocation call) {
  final refType = call.realTarget?.staticType;
  return call.methodName.name == 'onDispose' &&
      refType != null &&
      _refChecker.isAssignableFromType(refType);
}

final _notifierLocalDependencyField = RegExp(
  r'^\s+(?:(?:late|final)\s+)*(?:I?[A-Z][A-Za-z0-9_]*(?:Repository|Service|Datasource|DataSource))\??\s+(_[A-Za-z0-9_]*(?:repo|repository|service|datasource|dataSource)[A-Za-z0-9_]*)\s*(?:[=;])',
);

bool _isInsideMethod(List<ScannerMethodSpan> methods, int lineIndex) =>
    methods.any((method) => lineIndex >= method.start && lineIndex <= method.end);
