part of '../runtime_bug_source_rules.dart';

final List<ScannerRule> _runtimeBugSourceRulesPart1 = [
  /// Sync writes must check a dirty list before pushing.
  ///
  /// Why: `saveAll` replaces the entire collection. Calling it inside a sync
  /// loop without first checking the changed-row list rewrites every row on
  /// every cycle and floods disk I/O. Guard with `if (changed.isEmpty) return`
  /// (or equivalent) above the `saveAll` call.
  scannerRule(
    code: const LintCode(
      'sync_save_all_no_dirty_guard',
      'saveAll called inside sync push without a dirty-list guard.',
      correctionMessage: 'Check the changed-row list and return early when empty before `saveAll(...)`. Otherwise every sync cycle rewrites the whole collection.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags `.saveAll(... .map(Model.fromEntity).toList())` inside a method body that has no earlier `isEmpty` early-return guard.',
    scan: _scanSyncSaveAllGuards,
  ),

  /// `saveAll` must not rewrite a full collection after mutating a subset.
  ///
  /// Why: A dirty flag only proves *something* changed. If the method mutates
  /// one or more indexed rows and then calls `saveAll(fullCollection.map(...))`,
  /// it still rewrites every row. Keep a changed-row list and write only that
  /// subset with `mergeAll` / `saveMany`, or document the full rewrite with an
  /// ignore comment.
  scannerRule(
    code: const LintCode(
      'save_all_full_collection_after_subset_mutation',
      'saveAll rewrites a full collection after subset mutation.',
      correctionMessage: 'Collect changed rows and call mergeAll/saveMany, or add an ignore comment when a full rewrite is intentional.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags `saveAll(fullCollection.map(Model.fromEntity).toList())` after mutating indexed rows of that same collection.',
    scan: _scanSubsetSaveAllWrites,
  ),

  /// Collection getters must not allocate a fresh Map/List/Set on every access.
  ///
  /// Why: Getters are easy to call from `select`, build methods, and notifier
  /// hot paths. Building a collection in the getter turns every access into an
  /// O(n) allocation and breaks equality for records that contain the getter
  /// result. Memoize immutable-state indexes or expose a computed provider.
  scannerRule(
    code: const LintCode(
      'collection_getter_allocates_each_access',
      'Collection getter allocates a fresh Map/List/Set on every access.',
      correctionMessage: 'Use a generated computed provider/service/repository cache; for non-const classes, an instance `late final` derived field is also valid.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags Map/List/Set getters that build collection values in the getter body without an obvious cache.',
    scan: _scanCollectionGetterAllocations,
  ),

  /// Do not use Expando side tables as derived state caches.
  ///
  /// Why: Hot derived indexes should live in a computed provider or an
  /// explicit service/repository cache. Non-const classes may own an instance
  /// `late final` cache, but const Freezed state/entities cannot. A top-level
  /// `Expando` side table creates a second invisible cache owner and hides
  /// identity/lifetime semantics.
  scannerRule(
    code: const LintCode(
      'expando_derived_cache_forbidden',
      'Do not use Expando for derived caches in production app code.',
      correctionMessage: 'Use a computed provider or explicit service/repository cache; for non-const classes, an instance `late final` derived field is also valid.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags production Expando usage so derived caches do not live in hidden top-level side tables.',
    scan: (reporter, context) {
      if (context.isTestFile) return;
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        final column = line.indexOf('Expando');
        if (column < 0) continue;
        reporter.report(context, i, column);
      }
    },
  ),

  /// Single id lookups must use the shared Iterable lookup extension.
  ///
  /// Why: `items.indexBy((item) => item.id)[id]` or the skill's
  /// `items.indexOfByKey((item) => item.id)[id]` spreads lookup mechanics
  /// across call sites and allocates a map for a one-off read. Use
  /// `lookupByKey` for one read; keep `indexOfByKey` for a cached index that is
  /// reused (`final productsById = products.indexOfByKey(...)`,
  /// collections-helpers.md).
  scannerRule(
    code: const LintCode(
      'ad_hoc_id_index_lookup',
      'Ad-hoc id lookup belongs in an extension.',
      correctionMessage: 'Use `lookupByKey` for a one-off read, or cache the `indexOfByKey` map (or a computed provider/service-owned index) when it is reused.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags `items.indexBy((item) => item.id)[id]` and `items.indexOfByKey((item) => item.id)[id]` one-off lookups outside the shared Iterable extension.',
    scan: (reporter, context) {
      if (context.isTestFile) return;
      if (context.path.endsWith('iterable_extensions.dart')) return;
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        final match = _adHocIdIndexLookup.firstMatch(line);
        if (match == null) continue;
        reporter.report(context, i, match.start);
      }
    },
  ),

  /// Repeated id lookups on hot paths must use an index instead of linear search.
  ///
  /// Why: `firstWhere`, `indexWhere`, or a hand-written `for` scan by `.id`
  /// inside a loop, a collection-for, an iteration callback such as `map` or
  /// `forEach`, a widget build path, or a getter repeats a full scan per
  /// element, per frame, or per access. Pre-index by id with a Map and reuse
  /// that lookup. A single lookup in a one-off method is not repeated and is not
  /// reported.
  scannerRule(
    code: const LintCode(
      'linear_id_lookup_in_hot_path',
      'Linear id lookup in a hot path.',
      correctionMessage: 'Build/reuse a `Map<Id, Item>` index for id lookups instead of firstWhere/indexWhere/manual loops.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags firstWhere/indexWhere/manual `.id ==` loops that repeat inside a loop, collection-for, iteration callback, widget build path, or getter.',
    scan: (reporter, context) {
      if (context.isTestFile) return;
      _reportRepeatedIdLookups(reporter, context);
    },
  ),

  /// Nested loops must not perform inner id lookups.
  ///
  /// Why: A loop over collection A that calls `indexWhere`/`firstWhere` on
  /// collection B by id is O(a*b). Build `final byId = {for (final item in b)
  /// item.id: item}` once, then read `byId[id]` inside the loop.
  scannerRule(
    code: const LintCode(
      'nested_linear_lookup_by_id',
      'Nested loop performs an inner linear id lookup.',
      correctionMessage: 'Build a lookup map before the loop and read by id inside the loop instead of calling indexWhere/firstWhere repeatedly.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags `for (final item in items) { otherItems.indexWhere((x) => x.id == item.otherId) }` patterns, including loops over id lists such as `x.id == id`.',
    scan: (reporter, context) {
      if (context.isTestFile) return;
      _reportNestedIdLookups(reporter, context);
    },
  ),

  /// Appwrite client Function executions that may outlive the request must be async.
  ///
  /// Why: destructive, sync, import/export, migration, and generation Functions
  /// can keep running after the client request times out. Calling
  /// `createExecution(..., xasync: false)` (or omitting `xasync: true`) makes
  /// the app wait on the function response and often surfaces a timeout even
  /// when the backend operation succeeds. Async-start the Function, then
  /// reconcile against the source of truth with bounded polling or a realtime
  /// observer. A destructive/batch remote call passed `waitForCompletion: true`
  /// blocks the client the same way.
  scannerRule(
    code: const LintCode(
      'appwrite_blocking_function_execution_in_client',
      'Long-running Appwrite Function execution waits synchronously on the client.',
      correctionMessage: 'Pass `xasync: true`, treat the response as an async-start acknowledgement, then reconcile the source of truth with bounded polling/realtime.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags Appwrite `createExecution(...)` calls in likely long-running/destructive client methods unless the call explicitly passes `xasync: true`, and long-running remote calls that pass a resolved `waitForCompletion: true`.',
    scan: _scanBlockingFunctionExecutions,
  ),

  /// Destructive failures must reconcile before reporting telemetry.
  ///
  /// Why: delete/remove/deactivate flows can time out or lose the client
  /// connection after the backend has already completed. Reporting the caught
  /// exception before checking whether the entity/account is gone creates false
  /// Crashlytics/Sentry noise and may show a user-facing error for a successful
  /// operation. Reconcile first; report only when the source of truth still
  /// shows failure. A catch around async-started long-running work
  /// (networking.md "Long-Running Remote Work") that reports and never
  /// reconciles is flagged too.
  scannerRule(
    code: const LintCode(
      'destructive_failure_logged_before_reconcile',
      'Destructive mutation reports failure before source-of-truth reconciliation.',
      correctionMessage: 'Call a reconcile/verify/waitFor source-of-truth check first, then log/report the exception only when reconciliation fails.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags Crash/Sentry/Firebase error reporting before a later reconcile/verify call inside delete/remove/deactivate methods, or in the catch of async-started long-running work that never reconciles.',
    scan: (reporter, context) {
      if (context.isTestFile) return;
      final tries = collectNodes<TryStatement>(context.unit);
      for (final method in context.methods) {
        if (!_methodLooksDestructive(method.name)) continue;
        _reportTelemetryBeforeReconcile(reporter, context, method);
        if (_hasLaterReconcileCall(context, method.start, method.end)) continue;
        _reportUnreconciledLongRunningCatches(reporter, context, method, tries);
      }
    },
  ),

  /// Reset/clear methods must not preserve migration and sentinel storage keys.
  ///
  /// Why: reset flows are hard wipes of app-owned local state. Preserving
  /// version/install/migration markers around `.clear()` keeps compatibility
  /// state alive and can hide data-shape mismatches that should be rejected.
  scannerRule(
    code: const LintCode(
      'storage_clear_preserves_migration_state',
      'Reset/clear method preserves migration state around local storage clear.',
      correctionMessage: 'Remove migration/version/install marker preservation. Let reset/clear hard-clear app-owned local storage.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags datasource/repository reset/clear methods that read and restore migration/version/install markers around storage clear.',
    scan: (reporter, context) {
      if (context.isTestFile) return;
      _reportStorageClearSentinels(reporter, context);
    },
  ),

  /// Notifier persistence must be debounced, not synchronous-per-mutation.
  ///
  /// Why: A draft persistence method that fires on every checkbox tap, expand,
  /// or mode switch serializes the entire state on each call. 5 rapid user
  /// actions = 5 full writes back-to-back. Wrap the persist in a `Timer` /
  /// `Future.delayed` / `Debouncer` so bursts coalesce into one write.
  scannerRule(
    code: const LintCode(
      'notifier_persistence_no_debounce',
      'Persistence helper has no debounce / Timer / delayed indirection.',
      correctionMessage: 'Wrap the persist call in a `Timer` (cancel-and-restart on next call) or a `Debouncer` so rapid mutations coalesce into one write.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags `_schedule*Persist` / `_persistDraft` helper methods reached from synchronous or state-writing mutation paths when their class lacks any Timer/Future.delayed/Debouncer reference. Awaited one-shot lifecycle writes are allowed.',
    scan: (reporter, context) {
      if (context.isTestFile) return;
      for (final classSpan in context.classes) {
        if (!classSpan.isNotifier) continue;
        if (!_hasPersistHelper(context, classSpan)) continue;
        if (_hasDebounceMechanism(context, classSpan)) continue;
        final helperLine = _mutationPathPersistHelperLine(context, classSpan);
        if (helperLine == null) continue;
        final line = context.source.masked[helperLine];
        final col = _persistHelperPattern.firstMatch(line)?.start ?? 0;
        reporter.report(context, helperLine, col);
      }
    },
  ),

  /// Async notifier init/restore/load methods must guard stale writes.
  ///
  /// Why: A provider may start an async restore/load in the background while the
  /// user triggers a mutation. If the old async operation writes `state` after
  /// the mutation, it can overwrite the user-visible state and make navigation
  /// or buttons appear slow/stuck. Capture a generation/request token before
  /// the await and return when it is stale before writing `state`.
  scannerRule(
    code: const LintCode(
      'notifier_async_init_stale_state_write',
      'Async notifier init/restore/load writes state after await without a stale guard.',
      correctionMessage: 'Capture a generation/request token before the await and return if it is stale before assigning `state`, or return when `!ref.mounted`.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags private notifier init/restore/load methods that await and then assign state without an obvious generation/request/stale guard.',
    scan: _scanAsyncNotifierStaleStateWrites,
  ),

  /// Heavy widgets must not initialize in `build` without a user-action gate.
  ///
  /// Why: `InAppWebView`, `WebViewWidget`, video and audio players, and other
  /// heavy natives perform network handshakes and platform-channel work on
  /// mount. If the widget mounts every time a sheet opens, you pay that cost
  /// even when the user never interacts. Gate construction behind a `bool`
  /// triggered by an explicit user action.
  scannerRule(
    code: const LintCode(
      'webview_init_in_build_no_gate',
      'Heavy widget (WebView / native player) constructed in build without a user-action gate.',
      correctionMessage: 'Add a `bool _userRequested = false` (or `_userTapped...` / `_userOpened...`) field, set it in an `onTap` callback, and construct the heavy widget only when the flag is true.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags `InAppWebView`, `IOSInAppWebViewWidget`, `WebViewWidget`, `YoutubePlayer`, or `VideoPlayer` constructors inside `build()` of classes that declare no `_user*` / `*Tapped` / `*Requested` boolean gate field.',
    scan: (reporter, context) {
      if (context.isTestFile) return;
      _reportUngatedHeavyWidgets(reporter, context);
    },
  ),

  /// `*Service` storage reads must be memoized.
  ///
  /// Why: A service whose async getter hits disk on every call multiplies I/O
  /// across every screen entry. Cache results in a `Map<String, T>` field and
  /// only read from storage on a miss.
  scannerRule(
    code: const LintCode(
      'service_storage_read_no_memo',
      'Service reads from storage without an in-memory memo.',
      correctionMessage: 'Add a `Map<String, T> _cache` field; check it before `_storage.read(...)`. Write through on `markSeen` / equivalent.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags `_storage.read` / `box.get` calls inside *Service classes that declare no `Map<String,*>` cache field.',
    scan: (reporter, context) {
      if (context.isTestFile) return;
      for (final classSpan in context.classes) {
        if (!classSpan.name.endsWith('Service')) continue;
        if (_hasMemoField(context, classSpan)) continue;
        for (var i = classSpan.start; i <= classSpan.end && i < context.source.length; i++) {
          final line = context.source.masked[i];
          final match = _storageReadCall.firstMatch(line);
          if (match == null) continue;
          reporter.report(context, i, match.start);
        }
      }
    },
  ),

  /// `@Riverpod(keepAlive: true)` notifiers must not watch unbounded collections.
  ///
  /// Why: A `keepAlive` notifier lives for the session. If it derives state by
  /// watching an unbounded collection getter (`logs`, `items`, `history`, …),
  /// every entry in that collection is retained for the session, defeating the
  /// auto-dispose memory benefit. Prefer auto-dispose or derive from a bounded
  /// projection.
  scannerRule(
    code: const LintCode(
      'keepalive_watches_unbounded_collection',
      'keepAlive notifier watches an unbounded collection getter.',
      correctionMessage: 'Return a bounded projection (e.g. `s.count`) instead of returning or deriving from the full source collection.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags `@Riverpod(keepAlive: true)` providers whose build() returns or derives from `s.<unboundedCollectionName>` of a provider that is not resolved as `@Riverpod(keepAlive: true)`.',
    scan: _scanKeepAliveUnboundedCollections,
  ),

  /// Datasource interfaces with many single-field getters need a batch loader.
  ///
  /// Why: An interface with 5+ async `getX()` / `isX()` methods forces every
  /// screen that needs settings to fire N storage reads in series. Add a
  /// `loadAll()` / `loadSettings()` aggregator that returns a single object.
  scannerRule(
    code: const LintCode(
      'datasource_missing_batch_loader',
      'Datasource interface has many single-field getters but no batch loader.',
      correctionMessage: 'Expose a `Future<SettingsSnapshot> loadAll()` aggregator so callers can fetch everything in one read.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags abstract `*LocalDatasource` / `*RemoteDatasource` interfaces with 5+ single-value async getters and no loadAll/getAll/readAll method.',
    scan: (reporter, context) {
      if (context.isTestFile) return;
      for (final classSpan in context.classes) {
        if (!_isDatasourceInterface(context, classSpan)) continue;
        if (_hasBatchLoader(context, classSpan)) continue;
        final getterCount = _countSingleValueGetters(context, classSpan);
        if (getterCount < 5) continue;
        final line = context.source.masked[classSpan.start];
        final col = line.indexOf('class');
        reporter.report(context, classSpan.start, col < 0 ? 0 : col);
      }
    },
  ),
];

void _scanSyncSaveAllGuards(ScannerRuleReporter reporter, SourceScannerContext context) {
  if (context.isTestFile) return;
  for (final method in context.methods) {
    _reportSyncSaveAllGuard(reporter, context, method);
  }
}

void _reportSyncSaveAllGuard(
  ScannerRuleReporter reporter,
  SourceScannerContext context,
  ScannerMethodSpan method,
) {
  _visitSaveAllCalls(context, method, (lineIndex, match, window) {
    if (!_saveAllFromEntity.hasMatch(window) ||
        _hasEarlyEmptyGuard(context, method.start, lineIndex) ||
        _hasOuterDirtyGuard(context, lineIndex)) {
      return;
    }
    reporter.report(context, lineIndex, match.start);
  });
}

void _scanSubsetSaveAllWrites(ScannerRuleReporter reporter, SourceScannerContext context) {
  if (context.isTestFile) return;
  for (final method in context.methods) {
    _reportSubsetSaveAllWrite(reporter, context, method);
  }
}

void _reportSubsetSaveAllWrite(
  ScannerRuleReporter reporter,
  SourceScannerContext context,
  ScannerMethodSpan method,
) {
  _visitSaveAllCalls(context, method, (lineIndex, match, window) {
    final collection = _saveAllFromEntity.hasMatch(window)
        ? _saveAllMappedCollection(window)
        : null;
    if (collection == null ||
        !_methodMutatesCollectionSubset(context, method, lineIndex, collection)) {
      return;
    }
    reporter.report(context, lineIndex, match.start);
  });
}

void _scanAsyncNotifierStaleStateWrites(
  ScannerRuleReporter reporter,
  SourceScannerContext context,
) {
  if (context.isTestFile) return;
  for (final classSpan in context.classes) {
    if (!classSpan.isNotifier) continue;
    _reportAsyncNotifierClassWrites(reporter, context, classSpan);
  }
}

void _reportAsyncNotifierClassWrites(
  ScannerRuleReporter reporter,
  SourceScannerContext context,
  ScannerClassSpan classSpan,
) {
  for (final method in context.methods) {
    if (!classSpan.contains(method.start) ||
        !_asyncNotifierInitializerMethod.hasMatch(method.name)) {
      continue;
    }
    final stateWriteLine = _unguardedAsyncStateWriteLine(context, method);
    if (stateWriteLine == null) continue;
    final line = context.source.masked[stateWriteLine];
    final column = _notifierStateWrite.firstMatch(line)?.start ?? 0;
    reporter.report(context, stateWriteLine, column);
  }
}

void _scanCollectionGetterAllocations(ScannerRuleReporter reporter, SourceScannerContext context) {
  if (context.isTestFile) return;
  for (final classSpan in context.classes) {
    _reportCollectionGetterAllocationsInClass(reporter, context, classSpan);
  }
}

void _reportCollectionGetterAllocationsInClass(
  ScannerRuleReporter reporter,
  SourceScannerContext context,
  ScannerClassSpan classSpan,
) {
  for (
    var lineIndex = classSpan.start;
    lineIndex <= classSpan.end && lineIndex < context.source.length;
    lineIndex++
  ) {
    final line = context.source.masked[lineIndex];
    final blockMatch = _collectionGetterBlockStart.firstMatch(line);
    if (blockMatch != null) {
      final end = _findBlockEnd(context, lineIndex, classSpan.end);
      if (end == null) continue;
      if (_collectionGetterAllocates(_collectLines(context, lineIndex, end))) {
        reporter.report(context, lineIndex, blockMatch.start);
      }
      lineIndex = end;
      continue;
    }
    _reportCollectionGetterExpression(reporter, context, lineIndex, line);
  }
}

void _reportCollectionGetterExpression(
  ScannerRuleReporter reporter,
  SourceScannerContext context,
  int lineIndex,
  String line,
) {
  final match = _collectionGetterExpression.firstMatch(line);
  if (match == null) return;
  final expression = match.group(2) ?? '';
  if (_collectionGetterAllocates(expression)) {
    reporter.report(context, lineIndex, match.start);
  }
}

void _scanBlockingFunctionExecutions(ScannerRuleReporter reporter, SourceScannerContext context) {
  if (context.isTestFile) return;
  for (final method in context.methods) {
    _reportBlockingFunctionExecutionsInMethod(reporter, context, method);
  }
  final completionWaits = _CompletionWaitVisitor();
  context.unit.accept(completionWaits);
  for (final call in completionWaits.calls) {
    reporter.reportOffset(context, call.methodName.offset);
  }
}

/// Long-running remote calls that make the client wait for backend completion
/// (networking.md "Long-Running Remote Work"): a resolved `bool waitForCompletion`
/// parameter passed `true` on a destructive/batch call or inside such a method.
final class _CompletionWaitVisitor extends RecursiveAstVisitor<void> {
  final calls = <MethodInvocation>[];

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_waitsForBackendCompletion(node) && _isLongRunningCall(node)) calls.add(node);
    super.visitMethodInvocation(node);
  }
}

bool _waitsForBackendCompletion(MethodInvocation node) {
  return node.argumentList.arguments.any((argument) {
    final parameter = argument.correspondingParameter;
    final value = argument.argumentExpression;
    return argument is NamedArgument &&
        parameter != null &&
        parameter.name == 'waitForCompletion' &&
        parameter.type.isDartCoreBool &&
        value is BooleanLiteral &&
        value.value;
  });
}

bool _isLongRunningCall(MethodInvocation node) {
  if (_longRunningOperationName.hasMatch(node.methodName.name)) return true;
  final enclosing = node.thisOrAncestorOfType<MethodDeclaration>()?.name.lexeme;
  return enclosing != null && _longRunningOperationName.hasMatch(enclosing);
}

void _reportBlockingFunctionExecutionsInMethod(
  ScannerRuleReporter reporter,
  SourceScannerContext context,
  ScannerMethodSpan method,
) {
  _visitMethodLines(context, method, (lineIndex, line) {
    final match = _appwriteExecutionCall.firstMatch(line);
    if (match == null) return false;
    final callWindow = sourceLineWindow(context, lineIndex, method.end, 18);
    if (!_blockingExecutionMatches(context, method, line, callWindow)) return false;
    reporter.report(context, lineIndex, match.start);
    return false;
  });
}

bool _blockingExecutionMatches(
  SourceScannerContext context,
  ScannerMethodSpan method,
  String line,
  String callWindow,
) {
  final directCall = _appwriteCreateExecution.hasMatch(line);
  if (!directCall && !_functionIdArgument.hasMatch(callWindow)) return false;
  if (_isExecutionForwardingWrapper(context, method, callWindow)) return false;
  final longRunning =
      _methodLooksLongRunningFunction(method.name) ||
      _appwriteExecutionLooksLongRunning(callWindow);
  return longRunning && !_xasyncTrue.hasMatch(callWindow);
}

void _scanKeepAliveUnboundedCollections(
  ScannerRuleReporter reporter,
  SourceScannerContext context,
) {
  if (context.isTestFile) return;
  for (final classSpan in context.classes) {
    _reportKeepAliveClassCollection(reporter, context, classSpan);
  }
  _reportKeepAliveAnnotatedFunctions(reporter, context);
}

void _reportKeepAliveClassCollection(
  ScannerRuleReporter reporter,
  SourceScannerContext context,
  ScannerClassSpan classSpan,
) {
  if (!_isKeepAliveNotifier(context, classSpan)) return;
  for (
    var lineIndex = classSpan.start;
    lineIndex <= classSpan.end && lineIndex < context.source.length;
    lineIndex++
  ) {
    final column = _unboundedCollectionWatchColumn(context, lineIndex, classSpan.end);
    if (column == null) continue;
    reporter.report(context, lineIndex, column);
    return;
  }
}

void _reportKeepAliveAnnotatedFunctions(
  ScannerRuleReporter reporter,
  SourceScannerContext context,
) {
  for (var lineIndex = 0; lineIndex < context.source.length; lineIndex++) {
    if (!_keepAliveAnnotation.hasMatch(context.source.masked[lineIndex])) continue;
    final functionLine = _findFunctionDeclarationAfter(context, lineIndex);
    if (functionLine == null) continue;
    _reportKeepAliveFunctionCollection(reporter, context, functionLine);
  }
}

void _reportKeepAliveFunctionCollection(
  ScannerRuleReporter reporter,
  SourceScannerContext context,
  int functionLine,
) {
  final bodyEnd = _findFunctionBodyEnd(context, functionLine);
  if (bodyEnd == null) return;
  for (
    var lineIndex = functionLine;
    lineIndex <= bodyEnd && lineIndex < context.source.length;
    lineIndex++
  ) {
    final column = _unboundedCollectionWatchColumn(context, lineIndex, bodyEnd);
    if (column == null) continue;
    reporter.report(context, lineIndex, column);
    return;
  }
}
