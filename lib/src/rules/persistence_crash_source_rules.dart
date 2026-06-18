import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/rules/source_scanner_rule.dart';

final List<ScannerRule> persistenceCrashSourceRules = [
  /// Hive generated adapters should reserve @HiveType ids.
  ///
  /// Why: Flags @GenerateAdapters without reservedTypeIds when @HiveType exists. Add
  /// reservedTypeIds when @HiveType classes share a file with adapters.
  scannerRule(
    code: const LintCode(
      'hive_reserved_type_ids_missing',
      'Hive generated adapters should reserve @HiveType ids.',
      correctionMessage: 'Add reservedTypeIds when @HiveType classes share a file with adapters.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags @GenerateAdapters without reservedTypeIds when @HiveType exists so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      if (_annotationSpans(context, 'HiveType').isEmpty) return;
      final adapterSpans = _annotationSpans(context, 'GenerateAdapters');
      for (final span in adapterSpans) {
        if (!RegExp(r'\breservedTypeIds\s*:').hasMatch(span.text)) {
          reporter.report(context, span.start, 0);
        }
      }
    },
  ),

  /// Hive tests should close boxes.
  ///
  /// Why: Flags test files that use Hive without Hive.close(). Call Hive.close() from
  /// tearDown or cleanup.
  scannerRule(
    code: const LintCode(
      'hive_test_close_missing',
      'Hive tests should close boxes.',
      correctionMessage: 'Call Hive.close() from tearDown or cleanup.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags test files that use Hive without Hive.close() so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      if (!context.isTestFile) return;
      final hiveUseLine = _firstLineMatching(context, RegExp(r'\bHive\s*\.'));
      if (hiveUseLine == null) return;
      if (_containsMatch(context, RegExp(r'\bHive\s*\.\s*close\s*\('))) return;
      reporter.report(context, hiveUseLine, context.source.masked[hiveUseLine].indexOf('Hive'));
    },
  ),

  /// Hive typeId values must be unique in a file.
  ///
  /// Why: Flags duplicate Hive typeId values in the same file. Assign a fresh permanent
  /// typeId and retire the old id.
  scannerRule(
    code: const LintCode(
      'hive_duplicate_type_id',
      'Hive typeId values must be unique in a file.',
      correctionMessage: 'Assign a fresh permanent typeId and retire the old id.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags duplicate Hive typeId values in the same file so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      _reportDuplicateAnnotationIds(
        reporter: reporter,
        context: context,
        annotationName: 'HiveType',
        idPattern: RegExp(r'\btypeId\s*:\s*(\d+)\b'),
      );
    },
  ),

  /// HiveField indices must be unique in a file.
  ///
  /// Why: Flags duplicate HiveField indices in the same file. Append with a new HiveField
  /// index; never reuse a retired index.
  scannerRule(
    code: const LintCode(
      'hive_duplicate_field_id',
      'HiveField indices must be unique in a file.',
      correctionMessage: 'Append with a new HiveField index; never reuse a retired index.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags duplicate HiveField indices in the same file so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      _reportDuplicateAnnotationIds(
        reporter: reporter,
        context: context,
        annotationName: 'HiveField',
        idPattern: RegExp(r'@HiveField\s*\(\s*(\d+)\b'),
      );
    },
  ),

  /// Avoid direct FirebaseCrashlytics calls outside crash_service.dart.
  ///
  /// Why: Flags FirebaseCrashlytics.instance usage outside the Crash facade. Route feature
  /// code through Crash.init/error/log.
  scannerRule(
    code: const LintCode(
      'crash_direct_firebase_call',
      'Avoid direct FirebaseCrashlytics calls outside crash_service.dart.',
      correctionMessage: 'Route feature code through Crash.init/error/log.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags FirebaseCrashlytics.instance usage outside crash_service.dart so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      if (_isCrashServiceContext(context)) return;
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        final column = line.indexOf('FirebaseCrashlytics.instance');
        if (column >= 0) {
          reporter.report(context, i, column);
        }
      }
    },
  ),

  /// Initialize Crash before runApp.
  ///
  /// Why: Flags main entrypoints that call runApp before Crash.init(). Call and await
  /// Crash.init() before runApp in the app entrypoint.
  scannerRule(
    code: const LintCode(
      'crash_init_before_run_app',
      'Initialize Crash before runApp.',
      correctionMessage: 'Call and await Crash.init() before runApp in the app entrypoint.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags main entrypoints that call runApp before Crash.init() so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      if (!_isMainEntrypoint(context)) return;
      final runAppLine = _firstRunAppInvocationLine(context);
      if (runAppLine == null) return;
      final initLine = _firstLineMatching(context, RegExp(r'\bCrash\s*\.\s*init\s*\('));
      if (initLine == null || initLine > runAppLine) {
        reporter.report(context, runAppLine, context.source.masked[runAppLine].indexOf('runApp'));
      }
    },
  ),

  /// Fire-and-forget futures need local error handling.
  ///
  /// Why: Flags feasible unawaited fire-and-forget calls without catch handling. Catch inside
  /// the fire-and-forget future or attach catchError.
  scannerRule(
    code: const LintCode(
      'fire_and_forget_missing_catch',
      'Fire-and-forget futures need local error handling.',
      correctionMessage: 'Catch inside the fire-and-forget future or attach catchError.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags feasible unawaited fire-and-forget calls without catch handling so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        final column = line.indexOf('unawaited(');
        if (column < 0) continue;
        final statement = _statementFrom(context, i);
        if (!_isFeasibleFireAndForgetRisk(statement)) continue;
        if (_hasCatchGuard(statement) || _usesKnownGuardedFireAndForgetHelper(statement)) continue;
        reporter.report(context, i, column);
      }
    },
  ),
];

void _reportDuplicateAnnotationIds({
  required ScannerRuleReporter reporter,
  required SourceScannerContext context,
  required String annotationName,
  required RegExp idPattern,
}) {
  final seen = <String, int>{};
  for (final span in _annotationSpans(context, annotationName)) {
    final match = idPattern.firstMatch(span.text);
    final id = match?.group(1);
    if (id == null) continue;
    if (seen.containsKey(id)) {
      reporter.report(context, span.start, span.column);
      continue;
    }
    seen[id] = span.start;
  }
}

List<_AnnotationSpan> _annotationSpans(SourceScannerContext context, String name) {
  final spans = <_AnnotationSpan>[];
  final startsAnnotation = RegExp('@$name\\b');
  for (var i = 0; i < context.source.length; i++) {
    final line = context.source.masked[i];
    final match = startsAnnotation.firstMatch(line);
    if (match == null) continue;

    final buffer = StringBuffer(line);
    var end = i;
    var depth = _parenDelta(line);
    final hasArguments = line.contains('(');
    while (hasArguments && depth > 0 && end + 1 < context.source.length) {
      end++;
      final nextLine = context.source.masked[end];
      buffer
        ..write('\n')
        ..write(nextLine);
      depth += _parenDelta(nextLine);
    }

    spans.add(_AnnotationSpan(i, match.start, buffer.toString()));
    i = end;
  }
  return spans;
}

int? _firstLineMatching(SourceScannerContext context, RegExp pattern) {
  for (var i = 0; i < context.source.length; i++) {
    if (pattern.hasMatch(context.source.masked[i])) return i;
  }
  return null;
}

bool _containsMatch(SourceScannerContext context, RegExp pattern) {
  for (final line in context.source.masked) {
    if (pattern.hasMatch(line)) return true;
  }
  return false;
}

bool _isCrashServiceContext(SourceScannerContext context) {
  final normalized = context.path.replaceAll('\\', '/').toLowerCase();
  return normalized.endsWith('/crash_service.dart') ||
      normalized.endsWith('/crash.dart') ||
      normalized.contains('/core/crash/');
}

bool _isMainEntrypoint(SourceScannerContext context) {
  final normalized = context.path.replaceAll('\\', '/').toLowerCase();
  return normalized == 'lib/main.dart' ||
      (normalized.startsWith('lib/main_') && normalized.endsWith('.dart'));
}

int? _firstRunAppInvocationLine(SourceScannerContext context) {
  for (var i = 0; i < context.source.length; i++) {
    final line = context.source.masked[i];
    if (!RegExp(r'\brunApp\s*\(').hasMatch(line)) continue;
    if (RegExp(
      r'^\s*(?:void|Future(?:<[^>]+>)?|[A-Za-z_][A-Za-z0-9_<>,? ]+)\s+runApp\s*\(',
    ).hasMatch(line)) {
      continue;
    }
    return i;
  }
  return null;
}

String _statementFrom(SourceScannerContext context, int startLine) {
  final buffer = StringBuffer();
  var depth = 0;
  for (var i = startLine; i < context.source.length; i++) {
    final line = context.source.masked[i];
    if (buffer.isNotEmpty) buffer.write('\n');
    buffer.write(line);
    depth += _parenDelta(line);
    if (line.contains(';') && depth <= 0) break;
  }
  return buffer.toString();
}

bool _isFeasibleFireAndForgetRisk(String statement) {
  if (statement.contains('() async')) return true;
  return RegExp(
    r'\b(?:Firebase|Crashlytics|analytics|remote|sync|logEvent|recordError|setUserIdentifier|setCustomKey)\b',
    caseSensitive: false,
  ).hasMatch(statement);
}

bool _hasCatchGuard(String statement) {
  if (statement.contains('.catchError(')) return true;
  if (!RegExp(r'\btry\s*\{').hasMatch(statement)) return false;
  return RegExp(r'\b(?:catch|on\s+[A-Za-z_][A-Za-z0-9_]*)\b').hasMatch(statement);
}

bool _usesKnownGuardedFireAndForgetHelper(String statement) {
  return RegExp(r'\bunawaited\s*\(\s*_(?:send|runCrashOperation)\s*\(').hasMatch(statement);
}

int _parenDelta(String line) => _count(line, '(') - _count(line, ')');

int _count(String text, String char) {
  var count = 0;
  for (var i = 0; i < text.length; i++) {
    if (text[i] == char) count++;
  }
  return count;
}

final class _AnnotationSpan {
  const _AnnotationSpan(this.start, this.column, this.text);

  final int start;
  final int column;
  final String text;
}
