import 'package:analyzer/error/error.dart';
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
    description:
        'Flags static-only classes that use private constructors so the Flutter skill violation is shown during analysis.',
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
    description:
        'Flags per-class JsonSerializable explicitToJson settings so the Flutter skill violation is shown during analysis.',
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
    description:
        'Flags @Freezed(toJson: true) classes that already define fromJson so the Flutter skill violation is shown during analysis.',
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
  /// Why: Flags legacy Freezed when/maybeWhen/maybeMap invocations. Use Dart pattern matching
  /// and switch expressions.
  scannerRule(
    code: const LintCode(
      'freezed_legacy_when_map',
      'Avoid legacy Freezed when/map helpers.',
      correctionMessage: 'Use Dart pattern matching and switch expressions.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags legacy Freezed when/maybeWhen/maybeMap invocations so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (RegExp(r'\.(?:when|maybeWhen|maybeMap)\s*\(').hasMatch(line)) {
          reporter.report(context, i, line.indexOf(RegExp(r'(when|maybeWhen|maybeMap)')));
        }
      }
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
      correctionMessage:
          'Use @freezed sealed classes only. This project chooses one value-class pattern to remove mental tax; do not use Equatable or manual equality here.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags non-Freezed domain entities and data models so value classes use one consistent immutable pattern with no Equatable/manual-equality choice.',
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
  /// Why: @immutable only checks field mutability. Freezed owns equality, copyWith,
  /// exhaustiveness, and serialization conventions, so value/state classes do not drift into
  /// one-off hand-written models.
  scannerRule(
    code: const LintCode(
      'use_freezed_instead_of_immutable',
      'Use Freezed instead of @immutable.',
      correctionMessage:
          'Remove @immutable and rewrite the value/state class as a @freezed sealed class in its own file.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags manual @immutable annotations so immutable value/state classes use the project-wide Freezed pattern.',
    scan: (reporter, context) {
      if (context.isTestFile) return;
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        final index = line.indexOf('@immutable');
        if (index < 0) continue;
        reporter.report(context, i, index);
      }
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
    description:
        'Flags files containing multiple Freezed declarations so each generated value class has one source owner.',
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
