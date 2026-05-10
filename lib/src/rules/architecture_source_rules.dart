import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/rules/source_scanner_rule.dart';

final List<ScannerRule> architectureSourceRules = [
  /// Domain code must stay pure Dart.
  ///
  /// Why: Flags Flutter or package imports from domain files. Move Flutter/package
  /// dependencies out of domain entities.
  scannerRule(
    code: const LintCode(
      'arch_domain_import',
      'Domain code must stay pure Dart.',
      correctionMessage: 'Move Flutter/package dependencies out of domain entities.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags Flutter or package imports from domain files so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final code = context.source.code[i];
        if (_isAllowedDomainImport(code)) continue;
        if (context.isDomainPath &&
            RegExp(
              r'''^\s*import\s+['"](?:package:flutter|dart:ui|package:[^'"]+)''',
            ).hasMatch(code)) {
          reporter.report(context, i, context.source.masked[i].indexOf('import'));
        }
      }
    },
  ),

  /// Domain code must not own JSON serialization.
  ///
  /// Why: Flags JSON serialization members in domain files. Move fromJson/toJson code to data
  /// models.
  scannerRule(
    code: const LintCode(
      'arch_domain_serialization',
      'Domain code must not own JSON serialization.',
      correctionMessage: 'Move fromJson/toJson code to data models.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags JSON serialization members in domain files so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        if (context.isDomainPath &&
            RegExp(
              r'\b(?:fromJson|toJson|_\$\w+FromJson)\s*\(',
            ).hasMatch(context.source.masked[i])) {
          reporter.report(context, i, 0);
        }
      }
    },
  ),

  /// Repositories and datasources need interface contracts.
  ///
  /// Why: Flags repository or datasource files without I* contracts. Add an abstract
  /// interface class for this layer.
  scannerRule(
    code: const LintCode(
      'arch_interface_contract',
      'Repositories and datasources need interface contracts.',
      correctionMessage: 'Add an abstract interface class for this layer.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags repository or datasource files without I* contracts so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      final text = context.source.masked.join('\n');
      if ((context.isDatasourcePath || context.isRepositoryPath) &&
          context.hasConcreteLayerClass() &&
          !RegExp(r'\babstract\s+interface\s+class\s+I\w+').hasMatch(text)) {
        reporter.report(context, 0, 0);
      }
    },
  ),

  /// Repositories should implement contracts, not generated bases.
  ///
  /// Why: Flags repository classes extending generated _$Repository bases. Keep
  /// generated Riverpod classes on notifiers; concrete repositories implement I* contracts.
  scannerRule(
    code: const LintCode(
      'arch_repository_generated_extends',
      'Repositories must implement interfaces instead of extending generated bases.',
      correctionMessage:
          'Use a concrete repository that implements I*Repository, not extends _\$*Repository.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags repositories extending generated classes so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      final generatedRepository = RegExp(r'\bclass\s+\w+Repository\s+extends\s+_\$\w+Repository\b');
      for (var i = 0; i < context.source.length; i++) {
        final match = generatedRepository.firstMatch(context.source.masked[i]);
        if (match != null && !context.hasNearbyAnnotation(i, const {'riverpod', 'Riverpod'})) {
          reporter.report(context, i, context.source.masked[i].indexOf('extends'));
        }
      }
    },
  ),

  /// Layer constructors should depend on interfaces.
  ///
  /// Why: Flags concrete repository or datasource constructor dependencies. Take
  /// I*Repository/I*Datasource interfaces instead of concrete classes.
  scannerRule(
    code: const LintCode(
      'arch_concrete_dependency',
      'Layer constructors should depend on interfaces.',
      correctionMessage: 'Take I*Repository/I*Datasource interfaces instead of concrete classes.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags concrete repository or datasource constructor dependencies so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      if (!context.isRepositoryPath && !context.isDatasourcePath) return;
      for (var i = 0; i < context.source.length; i++) {
        if (context.hasConcreteLayerDependencyLine(context.source.masked[i])) {
          reporter.report(context, i, 0);
        }
      }
    },
  ),

  /// Avoid try/catch in datasources.
  ///
  /// Why: Flags try/catch blocks inside datasource files. Let errors propagate and catch once
  /// at the notifier boundary.
  scannerRule(
    code: const LintCode(
      'arch_datasource_try_catch',
      'Avoid try/catch in datasources.',
      correctionMessage: 'Let errors propagate and catch once at the notifier boundary.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags try/catch blocks inside datasource files so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (context.isDatasourcePath && RegExp(r'\btry\s*\{').hasMatch(line)) {
          reporter.report(context, i, line.indexOf('try'));
        }
      }
    },
  ),

  /// Feature widgets belong under presentation/widgets.
  ///
  /// Why: Flags feature widgets outside presentation/widgets. Move feature widgets into the
  /// presentation layer.
  scannerRule(
    code: const LintCode(
      'arch_widget_path',
      'Feature widgets belong under presentation/widgets.',
      correctionMessage: 'Move feature widgets into the presentation layer.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags feature widgets outside presentation/widgets so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      if (!context.isFeatureWidgetWrongPath) return;
      for (var i = 0; i < context.source.length; i++) {
        reporter.report(context, i, 0);
      }
    },
  ),

  /// Atomic design widgets should not access providers directly.
  ///
  /// Why: Flags provider access from atomic design widgets. Move provider access to the
  /// presentation boundary.
  scannerRule(
    code: const LintCode(
      'atomic_provider_access',
      'Atomic design widgets should not access providers directly.',
      correctionMessage: 'Move provider access to the presentation boundary.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags provider access from atomic design widgets so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (context.isAtomicNoProviderPath &&
            RegExp(r'\bref\s*\.\s*(?:read|watch)\s*\(').hasMatch(line)) {
          reporter.report(context, i, line.indexOf('ref'));
        }
      }
    },
  ),

  /// Use typed IDs for entities with multiple String IDs.
  ///
  /// Why: Flags domain entities with multiple raw String ID fields. Use extension types or
  /// value objects for IDs.
  scannerRule(
    code: const LintCode(
      'typed_id_raw_id',
      'Use typed IDs for entities with multiple String IDs.',
      correctionMessage: 'Use extension types or value objects for IDs.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags domain entities with multiple raw String ID fields so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      if (!context.isDomainPath) return;
      final idFields = <int>[];
      for (var i = 0; i < context.source.length; i++) {
        if (RegExp(r'\bfinal\s+String\s+\w*Id\s*;').hasMatch(context.source.masked[i])) {
          idFields.add(i);
        }
      }
      if (idFields.length > 1) {
        reporter.report(context, idFields.first, 0);
      }
    },
  ),

  /// Avoid Map<String, dynamic> for non-data multi-value returns.
  ///
  /// Why: Flags non-data helpers returning Map<String, dynamic> tuples. Use records or typed
  /// objects.
  scannerRule(
    code: const LintCode(
      'records_map_return',
      'Avoid Map<String, dynamic> for non-data multi-value returns.',
      correctionMessage: 'Use records or typed objects.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags non-data helpers returning Map<String, dynamic> tuples so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (context.isMapDynamicReturn(line)) {
          reporter.report(context, i, line.indexOf('Map'));
        }
      }
    },
  ),

  /// Cast untyped map boundaries to Map<String, dynamic>.
  ///
  /// Why: Flags `as Map<String, Object?>` casts. JSON/runtime map casts need
  /// `dynamic` values so downstream JSON access stays explicit and consistent.
  scannerRule(
    code: const LintCode(
      'avoid_object_map_cast',
      'Cast untyped map boundaries to Map<String, dynamic>.',
      correctionMessage: 'Use `as Map<String, dynamic>` at runtime map boundaries.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags Map<String, Object?> casts so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      final objectMapCast = RegExp(r'\bas\s+Map\s*<\s*String\s*,\s*Object\?\s*>');
      for (var i = 0; i < context.source.length; i++) {
        final match = objectMapCast.firstMatch(context.source.masked[i]);
        if (match != null) {
          reporter.report(context, i, match.start);
        }
      }
    },
  ),
];

bool _isAllowedDomainImport(String line) {
  final packageImport = RegExp(r'''^\s*import\s+['"]package:([^'"]+)['"]''').firstMatch(line);
  if (packageImport == null) return false;

  final importedPath = packageImport.group(1) ?? '';
  return importedPath == 'freezed_annotation/freezed_annotation.dart' ||
      importedPath.contains('/domain/');
}
