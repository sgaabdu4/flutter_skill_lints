import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/rules/source_scanner_rule.dart';

final List<ScannerRule> riverpodSourceRules = [
  /// Avoid ref.read in initState.
  ///
  /// Why: Flags ref.read calls made from initState. Defer reads with a post-frame callback.
  scannerRule(
    code: const LintCode(
      'riverpod_read_init_state',
      'Avoid ref.read in initState.',
      correctionMessage: 'Defer reads with a post-frame callback.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags ref.read calls made from initState so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (context.isInitStateRead(i)) {
          reporter.report(context, i, line.indexOf('ref.read'));
        }
      }
    },
  ),

  /// Avoid service locator classes in Riverpod apps.
  ///
  /// Why: Flags service locator classes in Riverpod apps. Model dependencies with providers.
  scannerRule(
    code: const LintCode(
      'riverpod_service_locator',
      'Avoid service locator classes in Riverpod apps.',
      correctionMessage: 'Model dependencies with providers.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags service locator classes in Riverpod apps so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (RegExp(
          r'\bclass\s+(?:ServiceFactory|ServiceLocator|BackendProvider)\b',
        ).hasMatch(line)) {
          reporter.report(context, i, line.indexOf('class'));
        }
      }
    },
  ),

  /// Prefer select when watching state in leaf widgets.
  ///
  /// Why: Flags broad ref.watch calls that do not use select. Use
  /// ref.watch(provider.select((value) => value.field)).
  scannerRule(
    code: const LintCode(
      'riverpod_watch_no_select',
      'Prefer select when watching state in leaf widgets.',
      correctionMessage: 'Use ref.watch(provider.select((value) => value.field)).',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags broad ref.watch calls that do not use select so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      // Only fire inside widget build() methods. Computed providers and
      // service factories legitimately call ref.watch without .select.
      // Exempt .notifier) — caller wants the whole notifier, no field to select.
      for (final method in context.methods.where((m) => m.name == 'build')) {
        for (var i = method.start; i <= method.end; i++) {
          final line = context.source.masked[i];
          if (_hasBroadRefWatch(context, i, method.end)) {
            reporter.report(context, i, line.indexOf('ref'));
          }
        }
      }
    },
  ),

  /// Avoid keepAlive family providers.
  ///
  /// Why: Flags keepAlive Riverpod families with required parameters. Use auto-dispose
  /// families unless the cache is bounded.
  scannerRule(
    code: const LintCode(
      'riverpod_keepalive_family',
      'Avoid keepAlive family providers.',
      correctionMessage: 'Use auto-dispose families unless the cache is bounded.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags keepAlive Riverpod families with required parameters so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (RegExp(r'@Riverpod\s*\([^)]*keepAlive\s*:\s*true').hasMatch(line) &&
            context.near(i, 'required ', 5)) {
          reporter.report(context, i, line.indexOf('@Riverpod'));
        }
      }
    },
  ),
];

bool _hasBroadRefWatch(SourceScannerContext context, int lineIndex, int methodEnd) {
  for (final invocation in _refWatchInvocations(context, lineIndex, methodEnd)) {
    if (!RegExp(r'\.\s*select\s*\(').hasMatch(invocation) &&
        !RegExp(r'\.\s*notifier\b').hasMatch(invocation)) {
      return true;
    }
  }
  return false;
}

List<String> _refWatchInvocations(SourceScannerContext context, int lineIndex, int methodEnd) {
  final firstLine = context.source.masked[lineIndex];
  final matches = RegExp(r'\bref\s*\.\s*watch\s*\(').allMatches(firstLine).toList();
  if (matches.isEmpty) return const [];

  return [
    for (final match in matches) _refWatchInvocation(context, lineIndex, methodEnd, match.start),
  ];
}

String _refWatchInvocation(
  SourceScannerContext context,
  int startLine,
  int methodEnd,
  int startColumn,
) {
  final buffer = StringBuffer();
  var depth = 0;
  var sawOpenParen = false;

  for (
    var lineIndex = startLine;
    lineIndex <= methodEnd && lineIndex < context.source.length;
    lineIndex++
  ) {
    final line = context.source.masked[lineIndex];
    final scanStart = lineIndex == startLine ? startColumn : 0;

    for (var column = scanStart; column < line.length; column++) {
      final char = line[column];
      buffer.write(char);

      if (char == '(') {
        sawOpenParen = true;
        depth++;
        continue;
      }

      if (char == ')' && sawOpenParen) {
        depth--;
        if (depth == 0) {
          return buffer.toString();
        }
      }
    }

    buffer.write('\n');
  }

  return buffer.toString();
}
