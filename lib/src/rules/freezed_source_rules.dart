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
];
