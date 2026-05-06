import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/rules/source_scanner_rule.dart';

final List<ScannerRule> freezedSourceRules = [
  scannerRule(
    code: const LintCode(
      'dart_static_namespace',
      'Prefer abstract final for static-only namespaces.',
      correctionMessage:
          'Replace private constructors on static-only classes with abstract final class.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description: 'Reports static-only classes that use private constructors.',
    scan: (reporter, context) {
      for (final classSpan in context.classes) {
        if (context.isPrivateNamespaceConstructor(classSpan)) {
          reporter.report(context, classSpan.start, 0);
        }
      }
    },
  ),
  scannerRule(
    code: const LintCode(
      'freezed_per_class_explicit_to_json',
      'Do not set explicitToJson per JsonSerializable class.',
      correctionMessage: 'Set explicit_to_json: true in build.yaml.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Reports per-class JsonSerializable explicitToJson settings.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (RegExp(r'@JsonSerializable\s*\([^)]*explicitToJson\s*:\s*true').hasMatch(line)) {
          reporter.report(context, i, line.indexOf('@JsonSerializable'));
        }
      }
    },
  ),
  scannerRule(
    code: const LintCode(
      'freezed_to_json_with_from_json',
      'Do not use @Freezed(toJson: true) when fromJson exists.',
      correctionMessage: 'Use plain @freezed with fromJson.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Reports @Freezed(toJson: true) classes that already define fromJson.',
    scan: (reporter, context) {
      final text = context.source.masked.join('\n');
      if (RegExp(r'@Freezed\s*\([^)]*toJson\s*:\s*true').hasMatch(text) &&
          RegExp(r'\bfactory\s+\w+(?:\.\w+)?\.fromJson\s*\(').hasMatch(text)) {
        reporter.report(context, context.firstLine('@Freezed'), 0);
      }
    },
  ),
  scannerRule(
    code: const LintCode(
      'freezed_legacy_when_map',
      'Avoid legacy Freezed when/map helpers.',
      correctionMessage: 'Use Dart pattern matching and switch expressions.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Reports legacy Freezed when/maybeWhen/maybeMap invocations.',
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
