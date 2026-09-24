import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
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

  /// Do not store a Ref field in notifiers.
  ///
  /// Why: Generated notifiers already expose `ref` from their base class. A
  /// stored `Ref` field duplicates it and can outlive the provider element that
  /// owns it. Use the inherited `ref` directly.
  scannerRule(
    code: const LintCode(
      'notifier_stored_ref_field',
      'Do not store a Ref field in notifiers.',
      correctionMessage: 'Use the generated ref inherited from the notifier base class.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags Ref-typed fields declared in Riverpod notifier classes.',
    scan: (reporter, context) {
      final notifiers = context.unit.declarations.whereType<ClassDeclaration>().where(
        _isRiverpodNotifierClass,
      );
      for (final variable in notifiers.expand(_storedRefFields)) {
        final location = context.unit.lineInfo.getLocation(variable.name.offset);
        reporter.report(context, location.lineNumber - 1, location.columnNumber - 1);
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

final _notifierLocalDependencyField = RegExp(
  r'^\s+(?:(?:late|final)\s+)*(?:I?[A-Z][A-Za-z0-9_]*(?:Repository|Service|Datasource|DataSource))\??\s+(_[A-Za-z0-9_]*(?:repo|repository|service|datasource|dataSource)[A-Za-z0-9_]*)\s*(?:[=;])',
);

bool _isInsideMethod(List<ScannerMethodSpan> methods, int lineIndex) =>
    methods.any((method) => lineIndex >= method.start && lineIndex <= method.end);

bool _isRiverpodNotifierClass(ClassDeclaration declaration) {
  final element = declaration.declaredFragment?.element;
  if (element == null) return false;
  return _riverpodNotifier.isSuperOf(element) || hasRiverpodCodegenAnnotation(declaration);
}

Iterable<VariableDeclaration> _storedRefFields(ClassDeclaration declaration) sync* {
  final body = declaration.body;
  if (body is! BlockClassBody) return;
  for (final field in body.members.whereType<FieldDeclaration>()) {
    for (final variable in field.fields.variables) {
      final type = variable.declaredFragment?.element.type;
      if (type is InterfaceType && _riverpodRef.isAssignableFromType(type)) yield variable;
    }
  }
}

const _riverpodRef = TypeChecker.fromName('Ref', packageName: 'riverpod');
const _riverpodNotifier = TypeChecker.any([
  TypeChecker.fromName('AnyNotifier', packageName: 'riverpod'),
  TypeChecker.fromName('Notifier', packageName: 'riverpod'),
]);
