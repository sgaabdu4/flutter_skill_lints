import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/rules/source_scanner_rule.dart';

final List<ScannerRule> uiSourceRules = [
  /// Avoid raw spacing, radius, size, and color tokens.
  ///
  /// Why: Flags raw visual constants instead of design tokens. Use design tokens.
  scannerRule(
    code: const LintCode(
      'style_raw_token',
      'Avoid raw spacing, radius, size, and color tokens.',
      correctionMessage: 'Use design tokens.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags raw visual constants instead of design tokens so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      if (context.isThemeDefFile || context.isTestFile) return;

      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (_hasRawStyleToken(line)) {
          reporter.report(context, i, 0);
        }
      }
    },
  ),

  /// Avoid raw TextStyle construction.
  ///
  /// Why: Flags raw TextStyle construction. Use the app theme text styles.
  scannerRule(
    code: const LintCode(
      'style_raw_text_style',
      'Avoid raw TextStyle construction.',
      correctionMessage: 'Use the app theme text styles.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags raw TextStyle construction so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      if (context.isThemeDefFile || context.isTestFile) return;

      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (RegExp(r'\bTextStyle\s*\(').hasMatch(line)) {
          reporter.report(context, i, line.indexOf('TextStyle'));
        }
      }
    },
  ),

  /// Avoid hardcoded UI strings.
  ///
  /// Why: Flags hardcoded UI strings. Move text into a *Strings constants class.
  scannerRule(
    code: const LintCode(
      'strings_hardcoded',
      'Avoid hardcoded UI strings.',
      correctionMessage: 'Move text into a *Strings constants class.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags hardcoded UI strings so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        if (context.hasHardcodedUiString(context.source.code[i])) {
          reporter.report(context, i, 0);
        }
      }
    },
  ),

  /// Bind localizations once before reading localized strings.
  ///
  /// Why: Keeps widget localization access consistent. Bind `final l10n = context.l10n;`
  /// at the top of `build`, then read keys from `l10n`.
  scannerRule(
    code: const LintCode(
      'l10n_context_direct_access',
      'Bind localizations before reading localized strings.',
      correctionMessage:
          'Use `final l10n = context.l10n;` and then read localized keys from `l10n`.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags direct context.l10n key access so widgets bind localizations once before use.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final column = context.directContextL10nColumn(i);
        if (column != null) {
          reporter.report(context, i, column);
        }
      }
    },
  ),

  /// UI widgets should not directly show snackbars.
  ///
  /// Why: Flags direct snackbar dispatches from UI widgets. Dispatch a notifier action and
  /// let the shell own snackbar presentation.
  scannerRule(
    code: const LintCode(
      'ui_snackbar_boundary',
      'UI widgets should not directly show snackbars.',
      correctionMessage: 'Dispatch a notifier action and let the shell own snackbar presentation.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags direct snackbar dispatches from UI widgets so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (context.isUiFile && context.dispatchesSnackbarFromUi(line)) {
          reporter.report(context, i, 0);
        }
      }
    },
  ),

  /// Do not globally clamp text scaling.
  ///
  /// Why: Flags app-level text scaling clamps. Fix responsive layout instead of clamping
  /// accessibility text size.
  scannerRule(
    code: const LintCode(
      'a11y_text_scale_clamp',
      'Do not globally clamp text scaling.',
      correctionMessage: 'Fix responsive layout instead of clamping accessibility text size.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags app-level text scaling clamps so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (context.isAppRootFile && context.clampsTextScaling(line)) {
          reporter.report(context, i, 0);
        }
      }
    },
  ),

  /// Make `DateTime.now()` timezone intent explicit.
  ///
  /// Why: Raw current-time calls spread timezone and calendar-window policy through
  /// app code. Keep current-time helpers and semantic date windows in
  /// `core/extensions/date_time_extensions.dart`.
  scannerRule(
    code: const LintCode(
      'datetime_now_requires_timezone_intent',
      'Make current DateTime timezone intent explicit.',
      correctionMessage:
          'Use DateTimeX.nowUtc()/nowLocal(), and move repeated current-date windows into a DateTimeX helper.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags raw current DateTime calls and inline current-date math so timestamp persistence and local calendar bucketing stay behind DateTimeX helpers.',
    scan: (reporter, context) {
      if (context.isTestFile) return;
      final isDateTimeExtensionsFile = context.path.endsWith(
        '/core/extensions/date_time_extensions.dart',
      );

      final maskedSource = context.source.masked.join('\n');
      final codeSource = context.source.code.join('\n');
      final reportedOffsets = <int>{};

      void reportOffset(int offset) {
        if (!reportedOffsets.add(offset)) return;
        final location = _lineColumnForOffset(context.source, offset);
        reporter.report(context, location.lineIndex, location.column);
      }

      if (!isDateTimeExtensionsFile) {
        for (final match in _currentTimeHelperDateMath.allMatches(maskedSource)) {
          reportOffset(match.start);
        }

        for (final match in _currentTimeBoundary.allMatches(maskedSource)) {
          reportOffset(match.start);
        }

        for (final match in _persistedLocalNowExpression.allMatches(maskedSource)) {
          final localNowMatch = _localNowExpression.firstMatch(match.group(0)!);
          if (localNowMatch == null) continue;
          reportOffset(match.start + localNowMatch.start);
        }
      }

      for (final match in _currentDateTimeCall.allMatches(maskedSource)) {
        if (_isAllowedDateTimeExtensionCurrentBoundary(context, match.start)) {
          continue;
        }
        reportOffset(match.start);
      }

      for (final match in _interpolatedCurrentDateTimeCall.allMatches(codeSource)) {
        final callText = match.group(0);
        if (callText == null) continue;
        final callIndex = callText.indexOf('DateTime');
        if (callIndex < 0) continue;
        final callOffset = match.start + callIndex;
        if (_isRawStringLiteralText(context, match.start)) continue;
        if (_isAllowedDateTimeExtensionCurrentBoundary(context, callOffset)) {
          continue;
        }
        reportOffset(callOffset);
      }
    },
  ),

  /// Avoid expensive work in build().
  ///
  /// Why: Flags expensive collection or formatting work inside build methods. Move sorting,
  /// filtering, formatting, and regex creation out of build.
  scannerRule(
    code: const LintCode(
      'perf_build_work',
      'Avoid expensive work in build().',
      correctionMessage: 'Move sorting, filtering, formatting, and regex creation out of build.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags expensive collection or formatting work inside build methods so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (final method in context.methods.where((method) => method.name == 'build')) {
        for (var i = method.start; i <= method.end; i++) {
          final line = context.source.masked[i];
          if (RegExp(r'\.(?:sort|where|map|toList)\s*\(').hasMatch(line) ||
              RegExp(r'\b(?:DateFormat|RegExp)\s*\(').hasMatch(line)) {
            reporter.report(context, i, 0);
          }
        }
      }
    },
  ),

  /// Prefer ListView.builder for dynamic lists.
  ///
  /// Why: Flags ListView(children:...) usage. Use builder/sliver variants instead of
  /// ListView(children:...).
  scannerRule(
    code: const LintCode(
      'perf_listview_children',
      'Prefer ListView.builder for dynamic lists.',
      correctionMessage: 'Use builder/sliver variants instead of ListView(children: ...).',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags ListView(children: ...) usage so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (RegExp(r'\bListView\s*\([^)]*\bchildren\s*:').hasMatch(line)) {
          reporter.report(context, i, line.indexOf('ListView'));
        }
      }
    },
  ),
];

final _currentDateTimeCall = RegExp(r'\bDateTime\s*\.\s*(?:now|timestamp)\s*\(\s*\)');
final _interpolatedCurrentDateTimeCall = RegExp(
  r'\$\{\s*DateTime\s*\.\s*(?:now|timestamp)\s*\(\s*\)',
);
final _localNowExpression = RegExp(
  r'\bDateTime\s*\.\s*now\s*\(\s*\)\s*\.\s*toLocal\s*\('
  r'|\b(?:[A-Za-z_]\w*\s*\.\s*)?nowLocal\s*\(',
);
final _persistedLocalNowExpression = RegExp(
  r'\b(?:createdAt|updatedAt|deletedAt|savedAt|syncedAt|lastSyncedAt|timestamp|checkedInAt)\b\s*(?::|=)\s*\(?\s*(?:'
  r'\bDateTime\s*\.\s*now\s*\(\s*\)\s*\.\s*toLocal\s*\('
  r'|\b(?:[A-Za-z_]\w*\s*\.\s*)?nowLocal\s*\()',
);
final _currentTimeHelperDateMath = RegExp(
  r'\b(?:DateTimeX\s*\.\s*)?nowLocal\s*\(\s*\)(?:\s*\.\s*startOfDay)?\s*\.\s*(?:calendarDaysBefore|calendarDaysAfter|daysBefore|daysAfter|add|subtract)\s*\(',
);
final _currentTimeBoundary = RegExp(
  r'\b(?:DateTimeX\s*\.\s*)?now(?:Local|Utc)\s*\(\s*\)\s*\.\s*(?:startOfDay|endOfDay)\b',
);

bool _hasRawStyleToken(String line) {
  if (RegExp(r'\bColor\s*\(\s*0x[0-9A-Fa-f]+').hasMatch(line)) {
    return true;
  }

  final visualConstructor = RegExp(
    r'\b(?:EdgeInsets|BorderRadius|Radius|SizedBox)(?:\.\w+)?\s*\([^)]*',
  );
  for (final match in visualConstructor.allMatches(line)) {
    if (_hasMeaningfulNumericLiteral(line.substring(match.start))) {
      return true;
    }
  }
  return false;
}

bool _hasMeaningfulNumericLiteral(String line) {
  final numericLiteral = RegExp(r'(?<![A-Za-z_])(?:\d+(?:\.\d+)?|\.\d+)');
  for (final match in numericLiteral.allMatches(line)) {
    final literal = match.group(0);
    if (literal == null) continue;

    final value = double.tryParse(literal);
    if (value == null || value == 0) continue;

    final previous = _previousNonWhitespace(line, match.start);
    if (previous != null && '+-*/'.contains(previous)) continue;

    return true;
  }
  return false;
}

({int lineIndex, int column}) _lineColumnForOffset(SourceScannerSource source, int offset) {
  var lineIndex = 0;
  while (lineIndex + 1 < source.lineOffsets.length && source.lineOffsets[lineIndex + 1] <= offset) {
    lineIndex++;
  }

  return (lineIndex: lineIndex, column: offset - source.lineOffsets[lineIndex]);
}

bool _isAllowedDateTimeExtensionCurrentBoundary(SourceScannerContext context, int offset) {
  if (!context.path.endsWith('/core/extensions/date_time_extensions.dart')) {
    return false;
  }

  final (:lineIndex, :column) = _lineColumnForOffset(context.source, offset);
  final line = context.source.masked[lineIndex];
  final call = _currentDateTimeCall.matchAsPrefix(line, column);
  if (call == null || !call.group(0)!.contains('timestamp')) return false;

  final start = lineIndex < 3 ? 0 : lineIndex - 3;
  final window = context.source.masked.sublist(start, lineIndex + 1).join('\n');
  return RegExp(
    r'\bstatic\s+DateTime\s+nowUtc\s*\(\s*\)\s*=>\s*DateTime\s*\.\s*timestamp\s*\(',
  ).hasMatch(window);
}

bool _isRawStringLiteralText(SourceScannerContext context, int offset) {
  final (:lineIndex, :column) = _lineColumnForOffset(context.source, offset);
  final line = context.source.code[lineIndex];
  for (var i = column - 1; i >= 0; i--) {
    final char = line[i];
    if (char != '\'' && char != '"') continue;

    var quoteStart = i;
    while (quoteStart > 0 && line[quoteStart - 1] == char) {
      quoteStart--;
    }

    final prefixIndex = quoteStart - 1;
    return prefixIndex >= 0 && (line[prefixIndex] == 'r' || line[prefixIndex] == 'R');
  }
  return false;
}

String? _previousNonWhitespace(String text, int beforeIndex) {
  for (var i = beforeIndex - 1; i >= 0; i--) {
    final char = text[i];
    if (char.trim().isNotEmpty) return char;
  }
  return null;
}
