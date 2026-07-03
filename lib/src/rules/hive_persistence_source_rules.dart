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
        final m = importPattern.firstMatch(context.source.original[i]);
        if (m == null) continue;
        imported.add(_pascalCase(m.group(1)!));
        final tail = m.group(2) ?? '';
        final showMatch = showClausePattern.firstMatch(tail);
        if (showMatch != null) {
          for (final name in showMatch.group(1)!.split(',')) {
            final trimmed = name.trim();
            if (trimmed.isNotEmpty) imported.add(trimmed);
          }
        }
      }
      final voUnion = imported.map(RegExp.escape).join('|');
      final voPattern = RegExp(r'\b(' + voUnion + r')\b');
      for (final classSpan in context.classes) {
        if (!context.hasFreezedAnnotation(classSpan)) continue;
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
          final match = voPattern.firstMatch(line);
          if (match != null) reporter.report(context, i, match.start);
          if (line.contains(') = _') || line.contains(');')) inFactory = false;
        }
      }
    },
  ),
];
