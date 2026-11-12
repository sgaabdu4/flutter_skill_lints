part of '../ui_source_rules.dart';

final _dateFormatRegExp = RegExp(r'\b(?:DateFormat|RegExp)\s*\(');

final _sortWhereMapPattern = RegExp(r'\.(?:sort|where|map|toList)\s*\(');

final _refReadWatchScannerRulePattern = RegExp(r'\bref\s*\.\s*(?:read|watch|listen)\s*\(');

final _textStylePattern = RegExp(r'\bTextStyle\s*\(');

final List<ScannerRule> _uiSourceRulesPart1 = [
  /// Avoid raw spacing, radius, size, and color tokens.
  scannerRule(
    code: const LintCode(
      'style_raw_token',
      'Avoid raw spacing, radius, size, and color tokens.',
      correctionMessage: 'Use design tokens.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags raw visual constants instead of design tokens so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      if (context.isThemeDefFile || context.isTestFile) return;

      final rawLines = _rawStyleTokenLines(context);
      for (var i = 0; i < context.source.length; i++) {
        if (rawLines.contains(i)) {
          reporter.report(context, i, 0);
        }
      }
    },
  ),

  /// Avoid raw TextStyle construction.
  scannerRule(
    code: const LintCode(
      'style_raw_text_style',
      'Avoid raw TextStyle construction.',
      correctionMessage: 'Use the app theme text styles.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags raw TextStyle construction so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      if (context.isThemeDefFile || context.isTestFile) return;

      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (_textStylePattern.hasMatch(line)) {
          reporter.report(context, i, line.indexOf('TextStyle'));
        }
      }
    },
  ),

  /// Avoid hardcoded UI strings.
  scannerRule(
    code: const LintCode(
      'strings_hardcoded',
      'Avoid hardcoded UI strings.',
      correctionMessage: 'Move user-facing text into the gen-l10n ARB files and read it through AppLocalizations (context.l10n).',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags hardcoded UI strings so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        if (context.hasHardcodedUiString(context.source.code[i]) &&
            !context.isWidgetPreviewLine(i)) {
          reporter.report(context, i, 0);
        }
      }
    },
  ),

  /// Bind localizations once before reading localized strings.
  scannerRule(
    code: const LintCode(
      'l10n_context_direct_access',
      'Bind localizations before reading localized strings.',
      correctionMessage:
          'Use `final l10n = context.l10n;` and then read localized keys from `l10n`.',
      severity: DiagnosticSeverity.ERROR,
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

  /// Snackbars are shown only by UI helpers.
  scannerRule(
    code: const LintCode(
      'ui_snackbar_boundary',
      'Do not show snackbars from widgets, notifiers, repositories, or datasources.',
      correctionMessage: 'Keep a durable status field in the notifier; the widget listens and calls a UI helper that wraps SnackBarUtils.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags direct snackbar dispatches from UI widgets and SnackBarUtils.show calls from notifiers, repositories, and datasources.',
    scan: (reporter, context) {
      if (!context.isUiFile) {
        if (!context.isTestFile) {
          context.unit.accept(_SnackBarUtilsDispatchVisitor(reporter, context));
        }
        return;
      }
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (context.dispatchesSnackbarFromUi(line)) {
          reporter.report(context, i, 0);
        }
      }
    },
  ),

  /// Widgets must not receive concrete infrastructure dependencies.
  scannerRule(
    code: const LintCode(
      'widget_infra_dependency_boundary',
      'Widgets must not receive concrete infrastructure dependencies.',
      correctionMessage: 'Move cache/client/storage/service/repository/datasource wiring behind the owning provider, datasource, repository, or service; widgets render values and dispatch only.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags infrastructure dependency props in widget/screen files so widgets stay UI + dispatch only.',
    scan: (reporter, context) {
      if (!context.isUiFile || context.isTestFile) return;

      for (var i = 0; i < context.source.length; i++) {
        final column = _widgetInfraDependencyColumn(context.source.masked[i]);
        if (column >= 0) reporter.report(context, i, column);
      }
    },
  ),

  /// Widget files must not declare top-level helper functions.
  scannerRule(
    code: const LintCode(
      'widget_top_level_function_boundary',
      'Widget files must not declare top-level helper functions.',
      correctionMessage: 'Move top-level widget helpers into a named class or notifier/computed provider; widget files must not expose global functions.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags top-level functions in widget/screen files so UI behavior has a class/provider owner.',
    scan: (reporter, context) {
      if (!context.isUiFile || context.isTestFile) return;

      var depth = 0;
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (depth == 0) {
          final column = _topLevelFunctionColumn(line);
          if (column >= 0 && !context.isWidgetPreviewLine(i)) reporter.report(context, i, column);
        }
        depth += braceDelta(line);
        if (depth < 0) depth = 0;
      }
    },
  ),

  /// Widget files must not host provider-backed action namespaces.
  scannerRule(
    code: const LintCode(
      'widget_actions_namespace_boundary',
      'Widget files must not host provider-backed action namespaces.',
      correctionMessage: 'Move provider-backed *Actions orchestration out of widgets into a coordinator, notifier, computed provider, or service.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags widget-file *Actions namespaces that accept WidgetRef and call providers.',
    scan: (reporter, context) {
      if (!context.isUiFile || context.isTestFile) return;

      for (final classSpan in context.classes) {
        if (!classSpan.name.endsWith('Actions')) continue;

        final text = context.source.masked.sublist(classSpan.start, classSpan.end + 1).join('\n');
        if (!text.contains('WidgetRef')) continue;
        if (!_refReadWatchScannerRulePattern.hasMatch(text)) continue;

        reporter.report(
          context,
          classSpan.start,
          context.source.masked[classSpan.start].indexOf('class'),
        );
      }
    },
  ),

  /// Widget classes must not catch errors.
  scannerRule(
    code: const LintCode(
      'widget_try_catch_boundary',
      'Widget classes must not catch errors.',
      correctionMessage: 'Move try/catch, error translation, snackbar dispatch, and telemetry into the notifier; keep widgets as UI + dispatch only.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags catch clauses inside widget files so error handling stays in notifiers.',
    scan: (reporter, context) {
      if (!context.isUiFile || context.isTestFile) return;

      context.unit.accept(_WidgetCatchVisitor(reporter, context));
    },
  ),

  /// Widgets must not branch on awaited notifier results.
  scannerRule(
    code: const LintCode(
      'widget_awaits_notifier_result',
      'Widget branches on an awaited notifier result.',
      correctionMessage: 'Move async orchestration and result branching into the notifier. Widgets may dispatch notifier actions and observe provider state.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags widget code that assigns/branches on awaited ref.read(...notifier) results.',
    scan: (reporter, context) {
      if (context.isTestFile) return;

      for (final classSpan in context.classes) {
        if (!_isWidgetSurfaceClass(context, classSpan)) continue;

        for (final method in context.methods.where((method) => classSpan.contains(method.start))) {
          for (var i = method.start; i <= method.end && i < context.source.length; i++) {
            final column =
                _awaitedNotifierResultColumn(context, i) ??
                _notifierThenResultColumn(context, i, method.end);
            if (column < 0) continue;
            reporter.report(context, i, column);
          }
        }
      }
    },
  ),

  /// Widgets must not own provider mutation busy flags.
  scannerRule(
    code: const LintCode(
      'widget_local_mutation_flag',
      'Widget owns provider mutation busy state.',
      correctionMessage: 'Move local mutation flags into the owning notifier/provider state; widgets dispatch and watch/listen only.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags widget-local mutation flags when the widget also dispatches notifier mutations.',
    scan: (reporter, context) {
      if (!context.isUiFile || context.isTestFile) return;

      for (final classSpan in context.classes) {
        if (!_isWidgetSurfaceClass(context, classSpan)) continue;
        if (!_classDispatchesNotifierMutation(context, classSpan)) continue;

        reportDirectClassMemberMatches(reporter, context, classSpan, _widgetLocalMutationFlagField);
      }
    },
  ),

  /// Move derived collection logic out of widgets.
  scannerRule(
    code: const LintCode(
      'widget_derived_collection_logic',
      'Widget helper derives collections.',
      correctionMessage: 'Move filtering, mapping, sorting, and lookup/index construction to a notifier or computed provider; widgets render the selected value.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags widget helper methods/namespaces that return collections and perform filter/map/sort/lookup work.',
    scan: (reporter, context) {
      if (!context.isUiFile || context.isTestFile) return;
      _reportTopLevelDerivedCollections(reporter, context);
      _reportWidgetDerivedCollectionHelpers(reporter, context);
    },
  ),

  /// Do not globally clamp text scaling.
  scannerRule(
    code: const LintCode(
      'a11y_text_scale_clamp',
      'Do not globally clamp text scaling.',
      correctionMessage: 'Fix responsive layout instead of clamping accessibility text size.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags app-level text scaling clamps so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (context.isAppRootFile && context.clampsTextScaling(line)) {
          reporter.report(context, i, 0);
        }
      }
    },
  ),

  /// Keep app shell widgets free of bootstrap side effects.
  scannerRule(
    code: const LintCode(
      'app_shell_bootstrap_side_effects',
      'Keep app shell widgets free of bootstrap side effects.',
      correctionMessage: 'Move ref.listen/startup orchestration into a dedicated bootstrap widget/provider; keep app shell widgets declarative.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags root app widgets that host bootstrap listeners so the Flutter skill app-shell boundary is shown during analysis.',
    scan: (reporter, context) {
      if (!context.isAppRootFile || context.isTestFile) return;

      for (final classSpan in context.classes) {
        for (final method in context.methods.where(
          (method) =>
              method.name == 'build' &&
              method.start >= classSpan.start &&
              method.end <= classSpan.end,
        )) {
          if (!_buildContainsAppShell(context, method)) continue;

          for (var i = method.start; i <= method.end; i++) {
            final column = _refListenColumn(context.source.masked[i]);
            if (column >= 0) {
              reporter.report(context, i, column);
            }
          }
        }
      }
    },
  ),

  /// Make `DateTime.now()` timezone intent explicit.
  scannerRule(
    code: const LintCode(
      'datetime_now_requires_timezone_intent',
      'Make current DateTime timezone intent explicit.',
      correctionMessage: 'Use DateTimeX.nowUtc()/nowLocal(), and move repeated current-date windows into a DateTimeX helper.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags raw current DateTime calls and inline current-date math so timestamp persistence and local calendar bucketing stay behind DateTimeX helpers.',
    scan: _scanDateTimeNowIntent,
  ),

  /// Keep intl formatting in primitive extensions.
  scannerRule(
    code: const LintCode(
      'ad_hoc_intl_format',
      'Do not build DateFormat or NumberFormat at call sites.',
      correctionMessage:
          'Move the formatting into a DateTimeX or NumX extension method and call it here.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags intl DateFormat/NumberFormat construction outside the DateTime and num extensions that own primitive formatting.',
    scan: (reporter, context) {
      if (context.isTestFile) return;
      context.unit.accept(_AdHocIntlFormatVisitor(reporter, context));
    },
  ),

  /// Keep numeric clamping in the num extension.
  scannerRule(
    code: const LintCode(
      'inline_num_clamp',
      'Do not call num.clamp inline at call sites.',
      correctionMessage: 'Call a NumX extension helper such as clamped(min, max).',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags dart:core num.clamp calls outside an extension on num so clamping stays behind NumX helpers.',
    scan: (reporter, context) {
      if (context.isTestFile) return;
      context.unit.accept(_InlineNumClampVisitor(reporter, context));
    },
  ),

  /// Avoid expensive work in build().
  scannerRule(
    code: const LintCode(
      'perf_build_work',
      'Avoid expensive work in build().',
      correctionMessage: 'Move sorting, filtering, formatting, and regex creation out of build.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags expensive collection or formatting work inside Widget/State build methods (not Riverpod Notifier build) so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (final method in context.methods.where((method) => method.name == 'build')) {
        if (!_isWidgetBuild(context, method)) continue;
        for (var i = method.start; i <= method.end; i++) {
          final line = context.source.masked[i];
          if (_sortWhereMapPattern.hasMatch(line) || _dateFormatRegExp.hasMatch(line)) {
            reporter.report(context, i, 0);
          }
        }
      }
    },
  ),

  /// Prefer ListView.builder for dynamic lists.
  scannerRule(
    code: const LintCode(
      'perf_listview_children',
      'Prefer ListView.builder for dynamic lists.',
      correctionMessage: 'Use builder/sliver variants instead of ListView(children: ...).',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags ListView(children: ...) whose children are built from dynamic data (mapped/generated collections, collection-for, or non-constant spreads).',
    scan: (reporter, context) {
      context.unit.accept(_DynamicListViewChildrenVisitor(reporter, context));
    },
  ),
];

/// A Widget/State `build`: its class extends a widget or State, its signature is `Widget build(` or takes a `BuildContext`, or it sits in a UI file.
bool _isWidgetBuild(SourceScannerContext context, ScannerMethodSpan method) {
  final classSpan = context.classes.where((span) => span.contains(method.start)).lastOrNull;
  if (classSpan == null) return false;
  final annotation = classSpan.start > 0 ? context.source.masked[classSpan.start - 1] : '';
  if (classSpan.isNotifier || _riverpodAnnotation.hasMatch(annotation)) return false;
  if (_isWidgetSurfaceClass(context, classSpan)) return true;
  final signature = sourceLineWindow(context, method.start, method.end, 2);
  return _widgetBuildSignature.hasMatch(signature) || context.isUiFile;
}

final _riverpodAnnotation = RegExp(r'@[Rr]iverpod\b');

final _widgetBuildSignature = RegExp(r'\bWidget\s+build\s*\(|\bbuild\s*\(\s*BuildContext\b');

void _scanDateTimeNowIntent(ScannerRuleReporter reporter, SourceScannerContext context) {
  if (context.isTestFile) return;
  final maskedSource = context.source.masked.join('\n');
  final codeSource = context.source.code.join('\n');
  final reportedOffsets = <int>{};

  _reportDateTimeMatches(
    reporter,
    context,
    _currentTimeHelperDateMath.allMatches(maskedSource),
    reportedOffsets,
  );
  _reportDateTimeMatches(
    reporter,
    context,
    _currentTimeBoundary.allMatches(maskedSource),
    reportedOffsets,
  );
  _reportPersistedLocalNowMatches(reporter, context, maskedSource, reportedOffsets);

  _reportCurrentDateTimeMatches(reporter, context, maskedSource, reportedOffsets);
  _reportInterpolatedCurrentDateTimeMatches(reporter, context, codeSource, reportedOffsets);
}

void _reportDateTimeMatches(
  ScannerRuleReporter reporter,
  SourceScannerContext context,
  Iterable<RegExpMatch> matches,
  Set<int> reportedOffsets,
) {
  for (final match in matches) {
    if (_isInsideDateTimeExtension(context, match.start)) continue;
    _reportDateTimeOffset(reporter, context, match.start, reportedOffsets);
  }
}

void _reportPersistedLocalNowMatches(
  ScannerRuleReporter reporter,
  SourceScannerContext context,
  String source,
  Set<int> reportedOffsets,
) {
  for (final match in _persistedLocalNowExpression.allMatches(source)) {
    final localNowMatch = _localNowExpression.firstMatch(match.group(0)!);
    if (localNowMatch == null || _isInsideDateTimeExtension(context, match.start)) continue;
    _reportDateTimeOffset(reporter, context, match.start + localNowMatch.start, reportedOffsets);
  }
}

void _reportCurrentDateTimeMatches(
  ScannerRuleReporter reporter,
  SourceScannerContext context,
  String source,
  Set<int> reportedOffsets,
) {
  for (final match in _currentDateTimeCall.allMatches(source)) {
    if (_isAllowedDateTimeExtensionCurrentBoundary(context, match.start)) {
      continue;
    }
    _reportDateTimeOffset(reporter, context, match.start, reportedOffsets);
  }
}

void _reportInterpolatedCurrentDateTimeMatches(
  ScannerRuleReporter reporter,
  SourceScannerContext context,
  String source,
  Set<int> reportedOffsets,
) {
  for (final match in _interpolatedCurrentDateTimeCall.allMatches(source)) {
    final callText = match.group(0);
    if (callText == null) continue;
    final callIndex = callText.indexOf('DateTime');
    if (callIndex < 0) continue;
    final callOffset = match.start + callIndex;
    if (_isRawStringLiteralText(context, match.start)) continue;
    if (_isAllowedDateTimeExtensionCurrentBoundary(context, callOffset)) {
      continue;
    }
    _reportDateTimeOffset(reporter, context, callOffset, reportedOffsets);
  }
}

void _reportDateTimeOffset(
  ScannerRuleReporter reporter,
  SourceScannerContext context,
  int offset,
  Set<int> reportedOffsets,
) {
  if (!reportedOffsets.add(offset)) return;
  final location = _lineColumnForOffset(context.source, offset);
  reporter.report(context, location.lineIndex, location.column);
}

void _reportTopLevelDerivedCollections(ScannerRuleReporter reporter, SourceScannerContext context) {
  var depth = 0;
  for (var lineIndex = 0; lineIndex < context.source.length; lineIndex++) {
    final line = context.source.masked[lineIndex];
    if (depth == 0 && _isTopLevelDerivedCollection(context, lineIndex)) {
      reporter.report(context, lineIndex, _firstNonWhitespaceColumn(line));
    }
    depth = _nonNegativeBraceDepth(depth + braceDelta(line));
  }
}

int _nonNegativeBraceDepth(int depth) => depth < 0 ? 0 : depth;

void _reportWidgetDerivedCollectionHelpers(
  ScannerRuleReporter reporter,
  SourceScannerContext context,
) {
  for (final classSpan in context.classes) {
    final isWidgetClass = _isWidgetSurfaceClass(context, classSpan);
    final isDataClass = _isWidgetDataHelperClass(classSpan);
    if (!isWidgetClass && !isDataClass) continue;
    for (final method in context.methods.where((method) => classSpan.contains(method.start))) {
      if (_isCollectionHelper(context, method, requirePrivate: isWidgetClass)) {
        _reportCollectionWork(reporter, context, method);
      }
    }
  }
}

void _reportCollectionWork(
  ScannerRuleReporter reporter,
  SourceScannerContext context,
  ScannerMethodSpan method,
) {
  final expressionBody = _expressionBodyOf(context, method);
  final bodyStart = expressionBody?.offset;
  final firstLine = bodyStart == null
      ? method.start + 1
      : context.unit.lineInfo.getLocation(bodyStart).lineNumber - 1;
  final lastLine = expressionBody == null
      ? method.end
      : context.unit.lineInfo.getLocation(expressionBody.end).lineNumber - 1;
  for (
    var lineIndex = firstLine;
    lineIndex <= lastLine && lineIndex < context.source.length;
    lineIndex++
  ) {
    final line = context.source.masked[lineIndex];
    final from = lineIndex == firstLine && bodyStart != null
        ? bodyStart - context.source.lineOffsets[lineIndex]
        : 0;
    final match = _collectionWork.firstMatch(line.substring(from));
    if (match == null) continue;
    reporter.report(context, lineIndex, from + match.start);
    return;
  }
}

ExpressionFunctionBody? _expressionBodyOf(SourceScannerContext context, ScannerMethodSpan method) {
  final line = context.source.masked[method.start];
  final column = line.indexOf(method.name);
  if (column < 0) return null;
  final node = context.unit.nodeCovering(offset: context.source.lineOffsets[method.start] + column);
  final declaration = node?.thisOrAncestorOfType<MethodDeclaration>();
  final body = declaration?.body;
  return body is ExpressionFunctionBody ? body : null;
}
