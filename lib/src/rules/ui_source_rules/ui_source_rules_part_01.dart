part of '../ui_source_rules.dart';

final List<ScannerRule> _uiSourceRulesPart1 = [
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

  /// Widgets must not receive concrete infrastructure dependencies.
  ///
  /// Why: Widget constructor args are render inputs, not composition roots. Keep
  /// cache managers, clients, storage, services, repositories, and datasources
  /// behind providers, repositories, datasources, or owned utility APIs.
  scannerRule(
    code: const LintCode(
      'widget_infra_dependency_boundary',
      'Widgets must not receive concrete infrastructure dependencies.',
      correctionMessage:
          'Move cache/client/storage/service/repository/datasource wiring behind the owning provider, datasource, repository, or service; widgets render values and dispatch only.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags infrastructure dependency props in widget/screen files so widgets stay UI + dispatch only.',
    scan: (reporter, context) {
      if (!context.isUiFile || context.isTestFile) return;

      for (var i = 0; i < context.source.length; i++) {
        final column = _widgetInfraDependencyColumn(context.source.masked[i]);
        if (column >= 0) reporter.report(context, i, column);
      }
    },
  ),

  /// Widget files must not declare top-level helper functions.
  ///
  /// Why: Widget-level helpers are feature/controller APIs. Keep UI behavior on
  /// widget classes, not as globals that any file can call without ownership.
  scannerRule(
    code: const LintCode(
      'widget_top_level_function_boundary',
      'Widget files must not declare top-level helper functions.',
      correctionMessage:
          'Move top-level widget helpers into a named class or notifier/computed provider; widget files must not expose global functions.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags top-level functions in widget/screen files so UI behavior has a class/provider owner.',
    scan: (reporter, context) {
      if (!context.isUiFile || context.isTestFile) return;

      var depth = 0;
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (depth == 0) {
          final column = _topLevelFunctionColumn(line);
          if (column >= 0) reporter.report(context, i, column);
        }
        depth += braceDelta(line);
        if (depth < 0) depth = 0;
      }
    },
  ),

  /// Widget files must not host provider-backed action namespaces.
  ///
  /// Why: `*Actions` classes that accept `WidgetRef` and call providers become
  /// hidden controllers in the widget layer. Keep orchestration in a coordinator,
  /// notifier, computed provider, or service with a clear owner.
  scannerRule(
    code: const LintCode(
      'widget_actions_namespace_boundary',
      'Widget files must not host provider-backed action namespaces.',
      correctionMessage:
          'Move provider-backed *Actions orchestration out of widgets into a coordinator, notifier, computed provider, or service.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags widget-file *Actions namespaces that accept WidgetRef and call providers.',
    scan: (reporter, context) {
      if (!context.isUiFile || context.isTestFile) return;

      for (final classSpan in context.classes) {
        if (!classSpan.name.endsWith('Actions')) continue;

        final text = context.source.masked.sublist(classSpan.start, classSpan.end + 1).join('\n');
        if (!text.contains('WidgetRef')) continue;
        if (!RegExp(r'\bref\s*\.\s*(?:read|watch|listen)\s*\(').hasMatch(text)) continue;

        reporter.report(
          context,
          classSpan.start,
          context.source.masked[classSpan.start].indexOf('class'),
        );
      }
    },
  ),

  /// Widget classes must not catch errors.
  ///
  /// Why: Widgets render and dispatch only. Notifiers catch, translate to typed
  /// state/snackbar effects, and report telemetry so error handling has one owner.
  scannerRule(
    code: const LintCode(
      'widget_try_catch_boundary',
      'Widget classes must not catch errors.',
      correctionMessage:
          'Move try/catch, error translation, snackbar dispatch, and telemetry into the notifier; keep widgets as UI + dispatch only.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags try blocks inside widget files so error handling stays in notifiers.',
    scan: (reporter, context) {
      if (!context.isUiFile || context.isTestFile) return;

      for (var i = 0; i < context.source.length; i++) {
        final match = RegExp(r'\btry\s*\{').firstMatch(context.source.masked[i]);
        if (match == null) continue;
        reporter.report(context, i, match.start);
      }
    },
  ),

  /// Widgets must not branch on awaited notifier results.
  ///
  /// Why: Assigning/branching on an awaited notifier result turns the widget into
  /// a controller. The notifier should own the mutation, update state, and expose
  /// a stable state transition for the widget to observe.
  scannerRule(
    code: const LintCode(
      'widget_awaits_notifier_result',
      'Widget branches on an awaited notifier result.',
      correctionMessage:
          'Move async orchestration and result branching into the notifier. Widgets may dispatch notifier actions and observe provider state.',
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
                _awaitedNotifierResultColumn(context, i, method.end) ??
                _notifierThenResultColumn(context, i, method.end);
            if (column < 0) continue;
            reporter.report(context, i, column);
          }
        }
      }
    },
  ),

  /// Widgets must not own provider mutation busy flags.
  ///
  /// Why: Local `_isSaving` / `_isSubmitting` fields beside notifier mutations
  /// split one mutation lifecycle between widget and provider state. The owning
  /// notifier should expose `isSaving` / `isSubmitting` and success serials.
  scannerRule(
    code: const LintCode(
      'widget_local_mutation_flag',
      'Widget owns provider mutation busy state.',
      correctionMessage:
          'Move local mutation flags into the owning notifier/provider state; widgets dispatch and watch/listen only.',
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
  ///
  /// Why: Private widget helpers that filter/map/sort collections hide feature
  /// state and rebuild work inside the UI layer. Put filtering, indexes, and
  /// derived lists in notifiers/computed providers.
  scannerRule(
    code: const LintCode(
      'widget_derived_collection_logic',
      'Widget helper derives collections.',
      correctionMessage:
          'Move filtering, mapping, sorting, and lookup/index construction to a notifier or computed provider; widgets render the selected value.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags widget helper methods/namespaces that return collections and perform filter/map/sort/lookup work.',
    scan: (reporter, context) {
      if (!context.isUiFile || context.isTestFile) return;
      _reportTopLevelDerivedCollections(reporter, context);
      _reportWidgetDerivedCollectionHelpers(reporter, context);
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

  /// Keep app shell widgets free of bootstrap side effects.
  ///
  /// Why: Flags root app widgets that both return an app shell (`MaterialApp`,
  /// `CupertinoApp`, or `WidgetsApp`) and register `ref.listen` side effects. Move
  /// startup orchestration to a dedicated bootstrap widget/provider.
  scannerRule(
    code: const LintCode(
      'app_shell_bootstrap_side_effects',
      'Keep app shell widgets free of bootstrap side effects.',
      correctionMessage:
          'Move ref.listen/startup orchestration into a dedicated bootstrap widget/provider; keep app shell widgets declarative.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags root app widgets that host bootstrap listeners so the Flutter skill app-shell boundary is shown during analysis.',
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
    scan: _scanDateTimeNowIntent,
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

void _scanDateTimeNowIntent(ScannerRuleReporter reporter, SourceScannerContext context) {
  if (context.isTestFile) return;
  final maskedSource = context.source.masked.join('\n');
  final codeSource = context.source.code.join('\n');
  final reportedOffsets = <int>{};
  final isExtensionFile = context.path.endsWith('/core/extensions/date_time_extensions.dart');

  if (!isExtensionFile) {
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
  }

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
    if (localNowMatch == null) continue;
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
  for (
    var lineIndex = method.start + 1;
    lineIndex <= method.end && lineIndex < context.source.length;
    lineIndex++
  ) {
    final match = _collectionWork.firstMatch(context.source.masked[lineIndex]);
    if (match == null) continue;
    reporter.report(context, lineIndex, match.start);
    return;
  }
}
