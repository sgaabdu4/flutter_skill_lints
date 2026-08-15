part of '../runtime_bug_source_rules.dart';

final List<ScannerRule> _runtimeBugSourceRulesPart2 = [
  /// Save callbacks for numeric forms must guard zero/empty input.
  ///
  /// Why: A "save" button that persists `amount: 0` and `count: 0` creates
  /// empty rows the user did not intend. Guard with
  /// `if (amount > 0 || count > 0)` (or `isNotEmpty` for strings/lists)
  /// before the notifier call.
  scannerRule(
    code: const LintCode(
      'notifier_zero_value_save_no_guard',
      'Save call passes numeric fields without a positive-value guard.',
      correctionMessage:
          'Wrap the `ref.read(...notifier).save*(...)` call in `if (amount > 0 || count > 0)` (or equivalent) so empty submissions cannot persist.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags `ref.read(...notifier).save*(amount: .., count: ..)` (and similar numeric named-args such as `duration`, `distance`, `weight`, `size`, `total`) without a `> 0` / `isNotEmpty` guard in the same method body.',
    scan: (reporter, context) {
      if (context.isTestFile) return;
      for (final method in context.methods) {
        if (_methodHasNotifierAccess(context, method)) {
          _reportZeroValueSave(reporter, context, method);
        }
      }
    },
  ),

  /// TextField `onChanged` that fires expensive work must debounce.
  ///
  /// Why: `onChanged` fires on every keystroke. A handler that hits a notifier
  /// mutation, network call, or any `await` runs once per char. Without a
  /// Timer-based debounce, typing "hello" sends 5 requests. Debounce in the
  /// notifier (cancel-and-restart Timer) or wrap with a `Debouncer`.
  scannerRule(
    code: const LintCode(
      'text_field_on_changed_no_debounce',
      'TextField onChanged triggers expensive work without debounce.',
      correctionMessage:
          'Wrap the notifier call in a `Timer` (cancel-and-restart) or `Debouncer`. For search-as-you-type, 300–500ms is typical.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags TextField/TextFormField onChanged callbacks that call a notifier method or await async work, when the file has no Timer/Debouncer/Future.delayed indirection.',
    scan: (reporter, context) {
      if (context.isTestFile) return;
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        final m = _textInputConstructor.firstMatch(line);
        if (m == null) continue;
        final block = _collectCallbackBody(context, i, 18);
        if (block == null) continue;
        if (!_blockHasOnChangedWithWork(block)) continue;
        if (_fileHasDebounce(context)) continue;
        final col = line.indexOf(m.group(1) ?? 'TextField', m.start);
        reporter.report(context, i, col);
      }
    },
  ),

  /// `Slider` `onChanged` must defer expensive work to `onChangeEnd` or debounce.
  ///
  /// Why: Slider `onChanged` fires continuously during drag (~60Hz). A
  /// notifier mutation or async work inside fires dozens of times for a
  /// single user gesture. Use `onChangeEnd` for terminal effects, or
  /// debounce.
  scannerRule(
    code: const LintCode(
      'slider_on_changed_no_debounce',
      'Slider onChanged triggers expensive work without debounce or onChangeEnd.',
      correctionMessage:
          'Move the notifier call to `onChangeEnd`, or debounce with a Timer. `onChanged` should only update local UI state.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags Slider/RangeSlider/CupertinoSlider onChanged callbacks that call notifiers or await async work without debounce.',
    scan: (reporter, context) {
      if (context.isTestFile) return;
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (!_sliderConstructor.hasMatch(line)) continue;
        final block = _collectConstructorArgs(context, i, 18);
        if (block == null) continue;
        if (!_blockHasOnChangedWithWork(block)) continue;
        if (_fileHasDebounce(context)) continue;
        final m = _sliderConstructor.firstMatch(line);
        final col = m == null ? 0 : line.indexOf(m.group(1) ?? 'Slider', m.start);
        reporter.report(context, i, col);
      }
    },
  ),

  /// `ScrollController.addListener` callback must throttle expensive work.
  ///
  /// Why: Scroll callbacks fire per pixel. A load-more, analytics event, or
  /// notifier call inside fires hundreds of times during a flick. Throttle
  /// with a Timer or guard with a `notFiredInLast(...)` mechanism.
  scannerRule(
    code: const LintCode(
      'scroll_listener_no_throttle',
      'ScrollController.addListener fires expensive work without throttle.',
      correctionMessage:
          'Throttle the callback with a Timer or guard with a last-fired-at timestamp; scroll callbacks run per pixel.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags `<ScrollController>.addListener(...)` callbacks that call a notifier method or await async work without Timer/throttle in the same file.',
    scan: (reporter, context) {
      if (context.isTestFile) return;
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        final match = _scrollListenerCall.firstMatch(line);
        if (match == null) continue;
        final body = _collectCallbackBody(context, i, 14);
        if (body == null) continue;
        if (!_expensiveOnChangedWork.hasMatch(body)) continue;
        if (_fileHasDebounce(context)) continue;
        reporter.report(context, i, match.start);
      }
    },
  ),

  /// User-visible waits must stay below snappy budgets.
  ///
  /// Why: debounces and hard sleeps in UI/notifier flows are felt as tap or
  /// typing latency. Keep search/realtime debounces <=150ms, visual animation
  /// durations <=120ms, and persistence/hard waits <=50ms. Retry/backoff,
  /// rest timers, reminders, and other background/domain timers are excluded.
  scannerRule(
    code: const LintCode(
      'user_visible_duration_too_long',
      'User-visible debounce, animation, or hard wait exceeds the snappy budget.',
      correctionMessage:
          'Reduce foreground debounce/wait durations: search/realtime <=150ms, animations <=120ms, persistence or Future.delayed hard waits <=50ms. Move sync/retry/domain waits to background owners.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags long Duration literals in UI/notifier/app-flow debounce, Timer, Future.delayed, animation, and transition contexts while ignoring tests, repositories, datasources, services, retry/backoff, rest timers, reminders, and sync/backfill settle timers.',
    scan: (reporter, context) {
      if (!_isUserVisibleLatencyPath(context)) return;
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        final durationMs = _durationLiteralMs(line);
        if (durationMs == null) continue;
        final window = _durationWindow(context, i);
        if (!_userVisibleDelaySignal.hasMatch(window)) continue;
        if (_backgroundDurationExemption.hasMatch(window)) continue;
        final budgetMs = _userVisibleDurationBudgetMs(window);
        if (durationMs <= budgetMs) continue;
        final column = line.indexOf('Duration(');
        reporter.report(context, i, column < 0 ? 0 : column);
      }
    },
  ),

  /// Unit-bearing numeric local vars passed to notifiers must be Value Objects.
  ///
  /// Why: `double amountCents = ...` followed by `ref.read(...).save(amount: amountCents)`
  /// crosses the widget→notifier boundary as a raw primitive. The notifier
  /// has no way to enforce sign, finiteness, or unit; mixups across unit
  /// systems (cents/dollars, meters/feet, seconds/ms) flow through silently.
  /// Wrap at the boundary in a Value Object.
  scannerRule(
    code: const LintCode(
      'notifier_param_requires_value_object',
      'Unit-bearing primitive local passed to notifier save call.',
      correctionMessage:
          'Wrap the local in a domain Value Object (e.g. `Distance.fromMeters(distance)`) at the boundary; the notifier should accept the VO, not the primitive.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags `double|int <name>(Meters|Seconds|Kilometers|Miles|Cents|Percent)` local declarations followed by a `ref.read(...notifier).save*(...)` call in the same method.',
    scan: (reporter, context) {
      if (context.isTestFile) return;
      for (final method in context.methods) {
        if (_methodHasNotifierAccess(context, method)) {
          _reportUnitPrimitiveNotifierUse(reporter, context, method);
        }
      }
    },
  ),

  /// Full-collection loads must not run once per loop iteration.
  ///
  /// Why: awaiting a `getAll`/`fetchAll`/`loadAll`-style loader inside a loop
  /// re-reads (and often re-deserializes/sorts) the entire collection on every
  /// iteration — an O(items × rows) N+1. Load the collection once before the
  /// loop, or expose a batched method that resolves all keys in a single pass.
  scannerRule(
    code: const LintCode(
      'full_collection_load_in_loop',
      'Full-collection load runs once per loop iteration.',
      correctionMessage:
          'Load the collection once before the loop, or add a batched lookup that resolves all keys in one pass. Awaiting a load-all call per iteration is O(items × rows).',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags an awaited getAll/fetchAll/loadAll-style full-collection load inside a for/while loop body.',
    scan: (reporter, context) {
      if (context.isTestFile) return;
      for (final method in context.methods) {
        _reportFullCollectionLoads(reporter, context, method);
      }
    },
  ),

  /// Fire-and-forget native/webview/media commands must handle their errors.
  ///
  /// Why: controller commands such as `runJavaScript`, `playVideo`, or `seekTo`
  /// return futures that reject during platform races (a webview still loading
  /// or being disposed). Passing one straight to `unawaited(...)` discards the
  /// rejection, which then escapes to `PlatformDispatcher.onError` and is
  /// commonly misreported as a fatal crash. Route the command through an
  /// error-handling helper (a try/catch wrapper or `.catchError`) instead.
  scannerRule(
    code: const LintCode(
      'unguarded_fire_and_forget_platform_command',
      'Fire-and-forget platform command future has no error handling.',
      correctionMessage:
          'Route the native/webview/media command through an error-handling helper (a try/catch wrapper or .catchError) instead of unawaited(...). Unhandled rejections escape to the global error handler and are often misreported as fatal crashes.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags a webview/media controller command (runJavaScript, playVideo, seekTo, ...) passed directly to unawaited(...) without error handling.',
    scan: (reporter, context) {
      if (context.isTestFile) return;
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        final match = _unawaitedPlatformCommand.firstMatch(line);
        if (match == null) continue;
        if (_errorHandlingWrapper.hasMatch(line)) continue;
        reporter.report(context, i, match.start);
      }
    },
  ),
];

void _reportZeroValueSave(
  ScannerRuleReporter reporter,
  SourceScannerContext context,
  ScannerMethodSpan method,
) {
  _visitMethodLines(context, method, (lineIndex, line) {
    final match = _saveMethodCall.firstMatch(line);
    if (match == null || !_lineHasNumericNamedArg(context, lineIndex, method.end)) return false;
    if (_hasPositiveGuard(context, method.start, lineIndex)) return false;
    reporter.report(context, lineIndex, match.start);
    return false;
  });
}

void _reportUnitPrimitiveNotifierUse(
  ScannerRuleReporter reporter,
  SourceScannerContext context,
  ScannerMethodSpan method,
) {
  final unitVars = _unitPrimitiveLocalNames(context, method);
  if (unitVars.isEmpty) return;
  for (var i = method.start; i <= method.end && i < context.source.length; i++) {
    final save = _saveMethodCall.firstMatch(context.source.masked[i]);
    if (save != null && _lineUsesUnitPrimitive(context, method, i, unitVars)) {
      reporter.report(context, i, save.start);
    }
  }
}

Set<String> _unitPrimitiveLocalNames(SourceScannerContext context, ScannerMethodSpan method) {
  final names = <String>{};
  for (var i = method.start; i <= method.end && i < context.source.length; i++) {
    for (final match in _unitPrimitiveLocal.allMatches(context.source.masked[i])) {
      final name = match.group(1);
      if (name != null) names.add(name);
    }
  }
  return names;
}

bool _lineUsesUnitPrimitive(
  SourceScannerContext context,
  ScannerMethodSpan method,
  int lineIndex,
  Set<String> names,
) {
  final end = (lineIndex + 8).clamp(lineIndex, method.end);
  final window = [
    for (var i = lineIndex; i <= end && i < context.source.length; i++) context.source.masked[i],
  ].join('\n');
  return names.any((name) => RegExp('\\b$name\\b').hasMatch(window));
}

void _reportFullCollectionLoads(
  ScannerRuleReporter reporter,
  SourceScannerContext context,
  ScannerMethodSpan method,
) {
  for (var i = method.start; i <= method.end && i < context.source.length; i++) {
    final loopLine = context.source.masked[i];
    if (!_hasBracedLoopBody(context, i, method.end, loopLine)) continue;
    final bodyEnd = _findBlockEnd(context, i, method.end);
    if (bodyEnd != null) _reportCollectionLoadInBody(reporter, context, i, bodyEnd);
  }
}

bool _hasBracedLoopBody(SourceScannerContext context, int lineIndex, int methodEnd, String line) {
  if (!_loopOpener.hasMatch(line)) return false;
  return line.contains('{') ||
      (lineIndex + 1 < context.source.length &&
          lineIndex + 1 <= methodEnd &&
          context.source.masked[lineIndex + 1].contains('{'));
}

void _reportCollectionLoadInBody(
  ScannerRuleReporter reporter,
  SourceScannerContext context,
  int loopStart,
  int bodyEnd,
) {
  for (
    var lineIndex = loopStart + 1;
    lineIndex <= bodyEnd && lineIndex < context.source.length;
    lineIndex++
  ) {
    final line = context.source.masked[lineIndex];
    final match = _fullCollectionLoaderCall.firstMatch(line);
    if (match == null || !_isAwaitedCollectionLoad(context, loopStart, lineIndex, line)) continue;
    reporter.report(context, lineIndex, match.start);
    return;
  }
}

bool _isAwaitedCollectionLoad(
  SourceScannerContext context,
  int loopStart,
  int lineIndex,
  String line,
) {
  return _awaitKeyword.hasMatch(line) ||
      (lineIndex - 1 >= loopStart && _awaitKeyword.hasMatch(context.source.masked[lineIndex - 1]));
}

bool _blockHasOnChangedWithWork(String block) {
  final onChangedMatch = _onChangedNamedArg.firstMatch(block);
  if (onChangedMatch == null) return false;
  final after = block.substring(onChangedMatch.end);
  final terminator = after.indexOf('onChangeEnd');
  final segment = terminator >= 0 ? after.substring(0, terminator) : after;
  return _expensiveOnChangedWork.hasMatch(segment);
}

bool _fileHasDebounce(SourceScannerContext context) {
  for (var i = 0; i < context.source.length; i++) {
    if (_debounceMechanism.hasMatch(context.source.masked[i])) return true;
  }
  return false;
}

String? _collectCallbackBody(SourceScannerContext context, int startLine, int maxLines) {
  final end = startLine + maxLines > context.source.length
      ? context.source.length
      : startLine + maxLines;
  final buffer = StringBuffer();
  for (var i = startLine; i < end; i++) {
    buffer.write(context.source.masked[i]);
    buffer.write('\n');
  }
  return buffer.toString();
}

String? _collectConstructorArgs(SourceScannerContext context, int startLine, int maxLines) {
  return _collectCallbackBody(context, startLine, maxLines);
}
