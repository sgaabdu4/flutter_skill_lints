import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/rules/source_scanner_rule.dart';

final List<ScannerRule> architectureExtendedSourceRules = [
  /// Data models should expose a toEntity() mapper.
  ///
  /// Why: Flags data model files whose model classes do not expose toEntity(). Add a
  /// toEntity() method on data models and map in repositories.
  scannerRule(
    code: const LintCode(
      'arch_model_missing_to_entity',
      'Data models should expose a toEntity() mapper.',
      correctionMessage: 'Add a toEntity() method on data models and map in repositories.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags data model files whose model classes do not expose toEntity() so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      if (!context.path.contains('/data/models/')) return;
      if (!RegExp(r'\bclass\s+\w+Model\b').hasMatch(context.source.masked.join('\n'))) {
        return;
      }
      if (context.source.masked.any((line) => RegExp(r'\btoEntity\s*\(').hasMatch(line))) {
        return;
      }
      reporter.report(context, 0, 0);
    },
  ),

  /// Data models must be separate from domain entities.
  ///
  /// Why: Flags data models that inherit from likely domain entities. Keep model and entity
  /// classes separate; map with toEntity().
  scannerRule(
    code: const LintCode(
      'arch_model_extends_entity',
      'Data models must be separate from domain entities.',
      correctionMessage: 'Keep model and entity classes separate; map with toEntity().',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags data models that inherit from likely domain entities so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      if (!context.path.contains('/data/models/')) return;
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (RegExp(r'\bclass\s+\w+Model\s+extends\s+(?!\w+Model\b)\w+').hasMatch(line)) {
          reporter.report(context, i, line.indexOf('extends'));
        }
      }
    },
  ),

  /// Domain entities must not use JSON annotations.
  ///
  /// Why: Flags JSON annotations in domain files. Move JSON keys and serialization
  /// annotations to data models.
  scannerRule(
    code: const LintCode(
      'arch_domain_json_annotation',
      'Domain entities must not use JSON annotations.',
      correctionMessage: 'Move JSON keys and serialization annotations to data models.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags JSON annotations in domain files so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      if (!context.isDomainPath) return;
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (RegExp(r'\b(?:JsonKey|JsonSerializable|FreezedUnionValue)\b').hasMatch(line)) {
          reporter.report(context, i, 0);
        }
      }
    },
  ),
];
