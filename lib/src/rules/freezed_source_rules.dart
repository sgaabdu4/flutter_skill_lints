import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';
import 'package:flutter_skill_lints/src/rules/source_scanner_rule.dart';

final List<ScannerRule> freezedSourceRules = [
  /// Prefer abstract final for static-only namespaces.
  ///
  /// Why: Flags static-only classes that use private constructors. Replace private
  /// constructors on static-only classes with abstract final class.
  scannerRule(
    code: const LintCode(
      'dart_static_namespace',
      'Prefer abstract final for static-only namespaces.',
      correctionMessage:
          'Replace private constructors on static-only classes with abstract final class.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description: 'Flags static-only classes that use private constructors so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (final classSpan in context.classes) {
        if (context.isPrivateNamespaceConstructor(classSpan)) {
          reporter.report(context, classSpan.start, 0);
        }
      }
    },
  ),

  /// Do not set explicitToJson per JsonSerializable class.
  ///
  /// Why: Flags per-class JsonSerializable explicitToJson settings. Set explicit_to_json:
  /// true in build.yaml.
  scannerRule(
    code: const LintCode(
      'freezed_per_class_explicit_to_json',
      'Do not set explicitToJson per JsonSerializable class.',
      correctionMessage: 'Set explicit_to_json: true in build.yaml.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags per-class JsonSerializable explicitToJson settings so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (RegExp(r'@JsonSerializable\s*\([^)]*explicitToJson\s*:\s*true').hasMatch(line)) {
          reporter.report(context, i, line.indexOf('@JsonSerializable'));
        }
      }
    },
  ),

  /// Do not use @Freezed(toJson: true) when fromJson exists.
  ///
  /// Why: Flags @Freezed(toJson: true) classes that already define fromJson. Use plain
  /// @freezed with fromJson.
  scannerRule(
    code: const LintCode(
      'freezed_to_json_with_from_json',
      'Do not use @Freezed(toJson: true) when fromJson exists.',
      correctionMessage: 'Use plain @freezed with fromJson.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags @Freezed(toJson: true) classes that already define fromJson so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      final text = context.source.masked.join('\n');
      if (RegExp(r'@Freezed\s*\([^)]*toJson\s*:\s*true').hasMatch(text) &&
          RegExp(r'\bfactory\s+\w+(?:\.\w+)?\.fromJson\s*\(').hasMatch(text)) {
        reporter.report(context, context.firstLine('@Freezed'), 0);
      }
    },
  ),

  /// Avoid legacy Freezed when/map helpers.
  ///
  /// Why: Flags the generated Freezed pattern helpers (`when`, `map`, `maybeWhen`,
  /// `maybeMap`, `whenOrNull`, `mapOrNull`), including implicit-`this` calls inside
  /// the Freezed class. Use Dart pattern matching and switch expressions.
  scannerRule(
    code: const LintCode(
      'freezed_legacy_when_map',
      'Avoid legacy Freezed when/map helpers.',
      correctionMessage: 'Use Dart pattern matching and switch expressions.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags generated Freezed when/map/maybeWhen/maybeMap/whenOrNull/mapOrNull invocations so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      context.unit.accept(_LegacyFreezedInvocationVisitor(reporter, context));
    },
  ),

  /// Use Freezed for domain entities and data models.
  ///
  /// Why: Flags domain entity and data model classes that are manual or Equatable-based.
  /// Freezed is the project-wide value-class convention, chosen to remove the mental tax
  /// of picking between equality/copy/serialization patterns.
  scannerRule(
    code: const LintCode(
      'freezed_required_value_class',
      'Use Freezed for domain entities and data models.',
      correctionMessage: 'Use @freezed sealed classes only. This project chooses one value-class pattern to remove mental tax; do not use Equatable or manual equality here.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags non-Freezed domain entities and data models so value classes use one consistent immutable pattern with no Equatable/manual-equality choice.',
    scan: (reporter, context) {
      for (final classSpan in context.classes) {
        if (!context.requiresFreezedValueClass(classSpan)) continue;
        if (context.hasFreezedAnnotation(classSpan)) continue;
        reporter.report(
          context,
          classSpan.start,
          context.source.masked[classSpan.start].indexOf('class'),
        );
      }
    },
  ),

  /// Use Freezed instead of manual @immutable value classes.
  ///
  /// Why: @immutable only checks field mutability, and Freezed's `@unfreezed` generates
  /// mutable value/state classes. Freezed owns equality, copyWith, exhaustiveness, and
  /// serialization conventions, so value/state classes do not drift into one-off hand-written
  /// or mutable models.
  scannerRule(
    code: const LintCode(
      'use_freezed_instead_of_immutable',
      'Use @freezed sealed classes instead of @immutable or @unfreezed.',
      correctionMessage: 'Remove @immutable/@unfreezed and rewrite the value/state class as a @freezed sealed class in its own file.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags manual @immutable and resolved Freezed @unfreezed annotations so value/state classes use the project-wide immutable Freezed pattern.',
    scan: (reporter, context) {
      if (context.isTestFile) return;
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        final index = line.indexOf('@immutable');
        if (index < 0) continue;
        reporter.report(context, i, index);
      }
      _reportUnfreezedAnnotations(reporter, context);
    },
  ),

  /// Keep one Freezed declaration per file.
  ///
  /// Why: Freezed generates a part file and a private implementation per declaration. Keeping
  /// each declaration in its own source file keeps generated output, imports, serialization,
  /// and ownership boundaries obvious.
  scannerRule(
    code: const LintCode(
      'freezed_one_class_per_file',
      'Keep one Freezed declaration per file.',
      correctionMessage: 'Move each @freezed/@Freezed class into its own Dart file.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags files containing multiple Freezed declarations so each generated value class has one source owner.',
    scan: (reporter, context) {
      if (context.isTestFile) return;
      final freezedClasses = [
        for (final classSpan in context.classes)
          if (context.hasFreezedAnnotation(classSpan)) classSpan,
      ];
      if (freezedClasses.length <= 1) return;

      for (final classSpan in freezedClasses.skip(1)) {
        reporter.report(
          context,
          classSpan.start,
          context.source.masked[classSpan.start].indexOf('class'),
        );
      }
    },
  ),
];

void _reportUnfreezedAnnotations(ScannerRuleReporter reporter, SourceScannerContext context) {
  for (final declaration in context.unit.declarations.whereType<ClassDeclaration>()) {
    for (final annotation in declaration.metadata) {
      final element = annotation.element;
      if (element?.name != 'unfreezed' ||
          element?.library?.uri.toString() !=
              'package:freezed_annotation/freezed_annotation.dart') {
        continue;
      }
      final location = context.unit.lineInfo.getLocation(annotation.offset);
      reporter.report(context, location.lineNumber - 1, location.columnNumber - 1);
    }
  }
}

final class _LegacyFreezedInvocationVisitor extends RecursiveAstVisitor<void> {
  _LegacyFreezedInvocationVisitor(this.reporter, this.context);

  final ScannerRuleReporter reporter;
  final SourceScannerContext context;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_legacyFreezedHelpers.contains(node.methodName.name) && _isGeneratedFreezedMethod(node)) {
      final location = context.unit.lineInfo.getLocation(node.methodName.offset);
      reporter.report(context, location.lineNumber - 1, location.columnNumber - 1);
    }
    super.visitMethodInvocation(node);
  }
}

const _legacyFreezedHelpers = {'when', 'map', 'maybeWhen', 'maybeMap', 'whenOrNull', 'mapOrNull'};

bool _isGeneratedFreezedMethod(MethodInvocation node) {
  final method = node.methodName.element;
  final targetType = node.target == null ? _enclosingThisType(node) : node.target!.staticType;
  if (method is! ExecutableElement ||
      targetType is! InterfaceType ||
      !method.firstFragment.libraryFragment.source.fullName.endsWith('.freezed.dart')) {
    return false;
  }
  return isFreezedInterfaceType(targetType);
}

DartType? _enclosingThisType(AstNode node) =>
    node.thisOrAncestorOfType<ClassDeclaration>()?.declaredFragment?.element.thisType;
