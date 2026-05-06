import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/rules/source_scanner_rule.dart';

final List<ScannerRule> architectureSourceRules = [
  scannerRule(
    code: const LintCode(
      'arch_domain_import',
      'Domain code must stay pure Dart.',
      correctionMessage: 'Move Flutter/package dependencies out of domain entities.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Reports Flutter or package imports from domain files.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final code = context.source.code[i];
        if (context.isDomainPath &&
            RegExp(
              r'''^\s*import\s+['"](?:package:flutter|dart:ui|package:[^'"]+)''',
            ).hasMatch(code)) {
          reporter.report(context, i, context.source.masked[i].indexOf('import'));
        }
      }
    },
  ),
  scannerRule(
    code: const LintCode(
      'arch_domain_serialization',
      'Domain code must not own JSON serialization.',
      correctionMessage: 'Move fromJson/toJson code to data models.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Reports JSON serialization members in domain files.',
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
  scannerRule(
    code: const LintCode(
      'arch_interface_contract',
      'Repositories and datasources need interface contracts.',
      correctionMessage: 'Add an abstract interface class for this layer.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Reports repository or datasource files without I* contracts.',
    scan: (reporter, context) {
      final text = context.source.masked.join('\n');
      if ((context.isDatasourcePath || context.isRepositoryPath) &&
          context.hasConcreteLayerClass() &&
          !RegExp(r'\babstract\s+interface\s+class\s+I\w+').hasMatch(text)) {
        reporter.report(context, 0, 0);
      }
    },
  ),
  scannerRule(
    code: const LintCode(
      'arch_concrete_dependency',
      'Layer constructors should depend on interfaces.',
      correctionMessage: 'Take I*Repository/I*Datasource interfaces instead of concrete classes.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Reports concrete repository or datasource constructor dependencies.',
    scan: (reporter, context) {
      if (!context.isRepositoryPath && !context.isDatasourcePath) return;
      for (var i = 0; i < context.source.length; i++) {
        if (context.hasConcreteLayerDependencyLine(context.source.masked[i])) {
          reporter.report(context, i, 0);
        }
      }
    },
  ),
  scannerRule(
    code: const LintCode(
      'arch_datasource_try_catch',
      'Avoid try/catch in datasources.',
      correctionMessage: 'Let errors propagate and catch once at the notifier boundary.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Reports try/catch blocks inside datasource files.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (context.isDatasourcePath && RegExp(r'\btry\s*\{').hasMatch(line)) {
          reporter.report(context, i, line.indexOf('try'));
        }
      }
    },
  ),
  scannerRule(
    code: const LintCode(
      'arch_widget_path',
      'Feature widgets belong under presentation/widgets.',
      correctionMessage: 'Move feature widgets into the presentation layer.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Reports feature widgets outside presentation/widgets.',
    scan: (reporter, context) {
      if (!context.isFeatureWidgetWrongPath) return;
      for (var i = 0; i < context.source.length; i++) {
        reporter.report(context, i, 0);
      }
    },
  ),
  scannerRule(
    code: const LintCode(
      'atomic_provider_access',
      'Atomic design widgets should not access providers directly.',
      correctionMessage: 'Move provider access to the presentation boundary.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Reports provider access from atomic design widgets.',
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
  scannerRule(
    code: const LintCode(
      'typed_id_raw_id',
      'Use typed IDs for entities with multiple String IDs.',
      correctionMessage: 'Use extension types or value objects for IDs.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Reports domain entities with multiple raw String ID fields.',
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
  scannerRule(
    code: const LintCode(
      'records_map_return',
      'Avoid Map<String, dynamic> for non-data multi-value returns.',
      correctionMessage: 'Use records or typed objects.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Reports non-data helpers returning Map<String, dynamic> tuples.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (context.isMapDynamicReturn(line)) {
          reporter.report(context, i, line.indexOf('Map'));
        }
      }
    },
  ),
];
