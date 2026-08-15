import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/rules/source_scanner_rule.dart';

/// Rules enforcing Hive CE persistence-layer boundary integrity.
///
/// Why: `hive_ce` infers `HiveField(N)` indexes from Freezed constructor
/// parameter order, and the binary box format is locked once shipped.
/// Wrapping a primitive Model field in a Value Object regenerates the
/// adapter — old user box bytes become unreadable. Reordering params
/// silently shifts every subsequent slot. `dart analyze` cannot see disk;
/// these rules surface the risk at code-review time.
String _pascalCase(String snake) => snake
    .split('_')
    .where((p) => p.isNotEmpty)
    .map((p) => p[0].toUpperCase() + p.substring(1))
    .join();

final List<ScannerRule> hivePersistenceSourceRules = [
  /// Persisted maps must validate their runtime key shape before decoding.
  ///
  /// Why: Hive and other local stores restore maps with runtime key types. A
  /// direct generic cast can fail after an app restart even when the original
  /// write used string keys. Validate the raw map and copy it into a typed map
  /// before passing it to a model decoder.
  scannerRule(
    code: const LintCode(
      'avoid_unvalidated_persisted_map_cast',
      'Do not cast persisted values directly to Map<String, dynamic>.',
      correctionMessage:
          'Check the value is a map, validate every key is a String, and create a typed map before decoding it.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags direct Map<String, dynamic> casts at local persistence boundaries so malformed stored values are rejected safely.',
    scan: (reporter, context) {
      if (context.isTestFile || !context.path.startsWith('lib/')) return;
      final path = context.path.toLowerCase();
      final remotePath =
          path.contains('/remote/') ||
          path.contains('/network/') ||
          path.contains('/api/') ||
          path.contains('remote_') ||
          path.contains('_remote');
      final persistencePath =
          !remotePath &&
          (path.contains('hive') ||
              path.contains('storage') ||
              path.contains('persistence') ||
              path.contains('cache') ||
              path.contains('local') ||
              path.contains('datasource'));
      if (!persistencePath) return;

      final cast = RegExp(r'\bas\s+Map\s*<\s*String\s*,\s*dynamic\s*>');
      for (var i = 0; i < context.source.length; i++) {
        final match = cast.firstMatch(context.source.masked[i]);
        if (match != null) reporter.report(context, i, match.start);
      }
    },
  ),

  /// Flutter app source should import Hive through hive_ce_flutter.
  ///
  /// Why: `hive_ce_flutter` is the Flutter-facing package for Hive CE. It
  /// re-exports the core Hive API and adds Flutter helpers such as
  /// `Hive.initFlutter`, Color/TimeOfDay adapters, and platform setup. Keeping
  /// production Flutter code on that import surface prevents an app from
  /// depending on the core Dart package while bypassing the Flutter integration
  /// package declared in the stack. Tests can still use temp directories and
  /// manual `Hive.init(path)` setup.
  scannerRule(
    code: const LintCode(
      'use_hive_ce_flutter_import',
      'Flutter app source must import Hive CE through hive_ce_flutter.',
      correctionMessage:
          'Replace `package:hive_ce/hive_ce.dart` with '
          '`package:hive_ce_flutter/hive_ce_flutter.dart` in production Flutter source. '
          'Use manual `Hive.init(path)` only for explicit custom paths or test temp boxes.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags direct hive_ce imports in production Flutter lib/ files so apps use the Flutter package surface.',
    scan: (reporter, context) {
      if (context.isTestFile || !context.path.startsWith('lib/')) return;
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.code[i];
        final match = RegExp(
          r'''^\s*import\s+['"]package:hive_ce/hive_ce\.dart['"]''',
        ).firstMatch(line);
        if (match != null) reporter.report(context, i, match.start);
      }
    },
  ),

  /// Hive Models must not carry Value Object types.
  ///
  /// Why: `/data/models/` classes are persistence-layer adapters; their
  /// constructor parameters become `HiveField(N)` slots on disk. Value
  /// Objects (`Distance`, `Money`, `Email`, …) belong in `/domain/` and
  /// require their own adapters to serialize. Keep primitive slots on the
  /// Model; expose VOs on the domain Entity via `Model.toEntity()`.
  scannerRule(
    code: const LintCode(
      'hive_field_no_vo_type',
      'Hive Models must not carry Value Object types.',
      correctionMessage:
          'Persistence Models in /data/models/ hold primitives. Move the VO field to the '
          'matching domain Entity and convert in the mapper '
          '(`Distance.fromMeters(distanceMeters)`). See building-flutter-apps '
          'references/hive-persistence.md (VO Interop).',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags VO-typed constructor parameters on Hive Model classes so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      if (!context.path.contains('/data/models/') && !context.path.contains('/data/model/')) {
        return;
      }
      final imported = _importedValueObjectNames(context);
      _reportValueObjectFields(reporter, context, imported);
    },
  ),
];

Set<String> _importedValueObjectNames(SourceScannerContext context) {
  const baseline = {
    'Distance',
    'Money',
    'Email',
    'Slug',
    'PhoneNumber',
    'HeartRate',
    'Weight',
    'Pace',
    'Username',
  };
  final imported = <String>{...baseline};
  final importPattern = RegExp(
    r'''^\s*import\s+['"][^'"]*?/domain/values/([a-z_][a-z0-9_]*)\.dart['"]([^;]*);''',
  );
  final showClausePattern = RegExp(r'\bshow\s+([A-Za-z_][\w,\s]*)');
  for (var i = 0; i < context.source.length; i++) {
    _addImportedValueObjects(
      imported,
      context.source.original[i],
      importPattern,
      showClausePattern,
    );
  }
  return imported;
}

void _addImportedValueObjects(
  Set<String> imported,
  String line,
  RegExp importPattern,
  RegExp showClausePattern,
) {
  final match = importPattern.firstMatch(line);
  if (match == null) return;
  imported.add(_pascalCase(match.group(1)!));
  final showMatch = showClausePattern.firstMatch(match.group(2) ?? '');
  if (showMatch == null) return;
  for (final name in showMatch.group(1)!.split(',')) {
    final trimmed = name.trim();
    if (trimmed.isNotEmpty) imported.add(trimmed);
  }
}

void _reportValueObjectFields(
  ScannerRuleReporter reporter,
  SourceScannerContext context,
  Set<String> imported,
) {
  final voUnion = imported.map(RegExp.escape).join('|');
  final voPattern = RegExp(r'\b(' + voUnion + r')\b');
  for (final classSpan in context.classes) {
    if (context.hasFreezedAnnotation(classSpan)) {
      _reportValueObjectClass(reporter, context, classSpan, voPattern);
    }
  }
}

void _reportValueObjectClass(
  ScannerRuleReporter reporter,
  SourceScannerContext context,
  ScannerClassSpan classSpan,
  RegExp voPattern,
) {
  var inFactory = false;
  for (var i = classSpan.start; i <= classSpan.end; i++) {
    final line = context.source.masked[i];
    if (line.contains('factory ${classSpan.name}') && line.contains('(')) {
      inFactory = true;
    }
    if (!inFactory) continue;
    if (line.trim().startsWith('///')) {
      if (line.contains(') = _') || line.contains(');')) inFactory = false;
      continue;
    }
    _reportValueObjectLine(reporter, context, i, line, voPattern);
    if (line.contains(') = _') || line.contains(');')) inFactory = false;
  }
}

void _reportValueObjectLine(
  ScannerRuleReporter reporter,
  SourceScannerContext context,
  int lineIndex,
  String line,
  RegExp voPattern,
) {
  final match = voPattern.firstMatch(line);
  if (match != null) reporter.report(context, lineIndex, match.start);
}
