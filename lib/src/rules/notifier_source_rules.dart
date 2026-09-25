import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
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
      for (final declaration in _notifierDeclarations(context)) {
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

  /// Keep ref.watch and ref.listen in a notifier's build().
  ///
  /// Why: Notifier methods read dependencies with ref.read. ref.watch belongs in
  /// build() when the notifier rebuilds from another provider, and ref.listen
  /// belongs in build() for side effects tied to provider changes.
  scannerRule(
    code: const LintCode(
      'notifier_watch_method',
      'Avoid ref.watch or ref.listen inside notifier methods other than build().',
      correctionMessage:
          'Use ref.read in notifier methods; watch or listen to providers in build().',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags resolved ref.watch and ref.listen calls in Notifier methods other than build().',
    scan: (reporter, context) {
      for (final declaration in _notifierDeclarations(context)) {
        final members = classBodyOf(declaration)?.members ?? const <ClassMember>[];
        for (final method in members.whereType<MethodDeclaration>()) {
          if (method.isStatic || method.name.lexeme == 'build') continue;
          final finder = _RefSubscriptionFinder();
          method.body.accept(finder);
          if (!finder.found) continue;
          final start = method.firstTokenAfterCommentAndMetadata.offset;
          reporter.report(context, context.unit.lineInfo.getLocation(start).lineNumber - 1, 0);
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
    if (!_isNotifierWithoutOnDispose(declaration)) continue;
    for (final variable in _instanceTimerFields(declaration)) {
      reporter.reportNode(context, variable);
    }
  }
}

bool _isNotifierWithoutOnDispose(ClassDeclaration declaration) {
  final element = declaration.declaredFragment?.element;
  return element != null &&
      anyNotifierChecker.isSuperOf(element) &&
      !collectNodes<MethodInvocation>(declaration).any(_isRefOnDispose);
}

Iterable<VariableDeclaration> _instanceTimerFields(ClassDeclaration declaration) => declaration
    .body
    .members
    .whereType<FieldDeclaration>()
    .where((field) => !field.isStatic)
    .expand((field) => field.fields.variables)
    .where((variable) {
      final type = variable.declaredFragment?.element.type;
      return type != null && _timerChecker.isExactlyType(type);
    });

bool _isRefOnDispose(MethodInvocation call) {
  final refType = call.realTarget?.staticType;
  return call.methodName.name == 'onDispose' &&
      refType != null &&
      _refChecker.isAssignableFromType(refType);
}

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

Iterable<ClassDeclaration> _notifierDeclarations(SourceScannerContext context) {
  final notifierNames = {
    for (final span in context.classes)
      if (span.isNotifier) span.name,
  };
  return context.unit.declarations.whereType<ClassDeclaration>().where(
    (declaration) => notifierNames.contains(declaration.namePart.typeName.lexeme),
  );
}

/// A `ref.watch(...)` or `ref.listen(...)` call on a resolved Riverpod `Ref`.
final class _RefSubscriptionFinder extends RecursiveAstVisitor<void> {
  bool found = false;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final target = node.target;
    final type = target?.staticType;
    if (const {'watch', 'listen'}.contains(node.methodName.name) &&
        target is SimpleIdentifier &&
        type is InterfaceType &&
        [type, ...type.allSupertypes].any((candidate) => candidate.element.name == 'Ref')) {
      found = true;
      return;
    }
    super.visitMethodInvocation(node);
  }
}
