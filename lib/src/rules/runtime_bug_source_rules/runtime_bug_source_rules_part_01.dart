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
      correctionMessage:
          'Check the changed-row list and return early when empty before `saveAll(...)`. Otherwise every sync cycle rewrites the whole collection.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags `.saveAll(... .map(Model.fromEntity).toList())` inside a method body that has no earlier `isEmpty` early-return guard.',
    scan: (reporter, context) {
      if (context.isTestFile) return;
      for (final method in context.methods) {
        for (var i = method.start; i <= method.end && i < context.source.length; i++) {
          final line = context.source.masked[i];
          final match = _saveAllCallStart.firstMatch(line);
          if (match == null) continue;
          final callWindow = _collectWindow(context, i, method.end, 10);
          if (!_saveAllFromEntity.hasMatch(callWindow)) continue;
          if (_hasEarlyEmptyGuard(context, method.start, i)) continue;
          if (_hasOuterDirtyGuard(context, i)) continue;
          reporter.report(context, i, match.start);
        }
      }
    },
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
      correctionMessage:
          'Collect changed rows and call mergeAll/saveMany, or add an ignore comment when a full rewrite is intentional.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags `saveAll(fullCollection.map(Model.fromEntity).toList())` after mutating indexed rows of that same collection.',
    scan: (reporter, context) {
      if (context.isTestFile) return;
      for (final method in context.methods) {
        for (var i = method.start; i <= method.end && i < context.source.length; i++) {
          final line = context.source.masked[i];
          final match = _saveAllCallStart.firstMatch(line);
          if (match == null) continue;
          final callWindow = _collectWindow(context, i, method.end, 10);
          if (!_saveAllFromEntity.hasMatch(callWindow)) continue;
          final collection = _saveAllMappedCollection(callWindow);
          if (collection == null) continue;
          if (!_methodMutatesCollectionSubset(context, method, i, collection)) continue;
          reporter.report(context, i, match.start);
        }
      }
    },
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
      correctionMessage:
          'Use a generated computed provider/service/repository cache; for non-const classes, an instance `late final` derived field is also valid.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags Map/List/Set getters that build collection values in the getter body without an obvious cache.',
    scan: (reporter, context) {
      if (context.isTestFile) return;
      for (final classSpan in context.classes) {
        for (var i = classSpan.start; i <= classSpan.end && i < context.source.length; i++) {
          final line = context.source.masked[i];
          final blockMatch = _collectionGetterBlockStart.firstMatch(line);
          if (blockMatch != null) {
            final end = _findBlockEnd(context, i, classSpan.end);
            if (end == null) continue;
            final body = _collectLines(context, i, end);
            if (!_collectionGetterAllocates(body)) continue;
            reporter.report(context, i, blockMatch.start);
            i = end;
            continue;
          }

          final expressionMatch = _collectionGetterExpression.firstMatch(line);
          if (expressionMatch == null) continue;
          final expression = expressionMatch.group(2) ?? '';
          if (!_collectionGetterAllocates(expression)) continue;
          reporter.report(context, i, expressionMatch.start);
        }
      }
    },
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
      correctionMessage:
          'Use a computed provider or explicit service/repository cache; for non-const classes, an instance `late final` derived field is also valid.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags production Expando usage so derived caches do not live in hidden top-level side tables.',
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
  /// Why: `items.indexBy((item) => item.id)[id]` spreads lookup mechanics
  /// across call sites and allocates a map for a one-off read. Keep the
  /// primitive in the shared Iterable extension; reserve `indexBy` for
  /// providers/services that intentionally return or reuse the full index.
  scannerRule(
    code: const LintCode(
      'ad_hoc_id_index_lookup',
      'Ad-hoc id lookup belongs in an extension.',
      correctionMessage:
          'Use `lookupByKey` / `indexOfByKey`, or expose a computed provider/service-owned index when the full map is reused.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags `items.indexBy((item) => item.id)[id]` one-off lookups outside the shared Iterable extension.',
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

  /// Id lookups on hot paths must use an index instead of linear search.
  ///
  /// Why: `firstWhere`, `indexWhere`, or hand-written `for` helpers named
  /// `*ById` scan the full collection on every call. In widgets, notifiers,
  /// repositories, and providers those calls often sit behind taps, timers, or
  /// rebuilds. Pre-index by id with a Map and reuse that lookup.
  scannerRule(
    code: const LintCode(
      'linear_id_lookup_in_hot_path',
      'Linear id lookup in a hot path.',
      correctionMessage:
          'Build/reuse a `Map<Id, Item>` index for id lookups instead of firstWhere/indexWhere/manual loops.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags firstWhere/indexWhere/manual *ById loops over `.id == ...` in likely-hot widget, notifier, repository, or provider code.',
    scan: (reporter, context) {
      if (context.isTestFile) return;
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        final match = _byIdFunctionStart.firstMatch(line);
        if (match == null) continue;
        final end = _findBlockEnd(context, i, context.source.length - 1);
        if (end == null) continue;
        final body = _collectLines(context, i, end);
        if (!_manualIdLoop.hasMatch(body)) continue;
        reporter.report(context, i, match.start);
      }

      for (final classSpan in context.classes) {
        if (!_isHotLookupClass(context, classSpan)) continue;
        for (final method in context.methods) {
          if (!classSpan.contains(method.start)) continue;
          for (var i = method.start; i <= method.end && i < context.source.length; i++) {
            final line = context.source.masked[i];
            final match = _linearIdLookupCall.firstMatch(line);
            if (match == null) continue;
            final lookupWindow = _collectWindow(context, i, method.end, 6);
            if (!_linearIdLookup.hasMatch(lookupWindow)) continue;
            if (_isIndexLookupInsideForBlock(context, method.start, i)) continue;
            reporter.report(context, i, match.start);
          }
        }
      }
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
      correctionMessage:
          'Build a lookup map before the loop and read by id inside the loop instead of calling indexWhere/firstWhere repeatedly.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags `for (final item in items) { otherItems.indexWhere((x) => x.id == item.otherId) }` patterns.',
    scan: (reporter, context) {
      if (context.isTestFile) return;
      for (final method in context.methods) {
        for (var i = method.start; i <= method.end && i < context.source.length; i++) {
          final loop = _forEachLoop.firstMatch(context.source.masked[i]);
          final loopVar = loop?.group(1);
          if (loopVar == null) continue;
          final bodyEnd = _findBlockEnd(context, i, method.end) ?? method.end;
          final lookup = _nestedIdLookup(loopVar);
          for (var j = i + 1; j <= bodyEnd && j < context.source.length; j++) {
            final line = context.source.masked[j];
            final match = _linearIdLookupCall.firstMatch(line);
            if (match == null) continue;
            final lookupWindow = _collectWindow(context, j, bodyEnd, 6);
            if (!lookup.hasMatch(lookupWindow)) continue;
            reporter.report(context, j, match.start);
            break;
          }
        }
      }
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
  /// observer.
  scannerRule(
    code: const LintCode(
      'appwrite_blocking_function_execution_in_client',
      'Long-running Appwrite Function execution waits synchronously on the client.',
      correctionMessage:
          'Pass `xasync: true`, treat the response as an async-start acknowledgement, then reconcile the source of truth with bounded polling/realtime.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags Appwrite `createExecution(...)` calls in likely long-running/destructive client methods unless the call explicitly passes `xasync: true`.',
    scan: (reporter, context) {
      if (context.isTestFile) return;
      for (final method in context.methods) {
        for (var i = method.start; i <= method.end && i < context.source.length; i++) {
          final line = context.source.masked[i];
          final match = _appwriteExecutionCall.firstMatch(line);
          if (match == null) continue;
          final callWindow = _collectWindow(context, i, method.end, 18);
          final directAppwriteCall = _appwriteCreateExecution.hasMatch(line);
          if (!directAppwriteCall && !_functionIdArgument.hasMatch(callWindow)) continue;
          if (_isExecutionForwardingWrapper(context, method, callWindow)) continue;
          if (!_methodLooksLongRunningFunction(method.name) &&
              !_appwriteExecutionLooksLongRunning(callWindow)) {
            continue;
          }
          if (_xasyncTrue.hasMatch(callWindow)) continue;
          reporter.report(context, i, match.start);
        }
      }
    },
  ),

  /// Destructive failures must reconcile before reporting telemetry.
  ///
  /// Why: delete/remove/deactivate flows can time out or lose the client
  /// connection after the backend has already completed. Reporting the caught
  /// exception before checking whether the entity/account is gone creates false
  /// Crashlytics/Sentry noise and may show a user-facing error for a successful
  /// operation. Reconcile first; report only when the source of truth still
  /// shows failure.
  scannerRule(
    code: const LintCode(
      'destructive_failure_logged_before_reconcile',
      'Destructive mutation reports failure before source-of-truth reconciliation.',
      correctionMessage:
          'Call a reconcile/verify/waitFor source-of-truth check first, then log/report the exception only when reconciliation fails.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags Crash/Sentry/Firebase error reporting before a later reconcile/verify call inside delete/remove/deactivate methods.',
    scan: (reporter, context) {
      if (context.isTestFile) return;
      for (final method in context.methods) {
        if (!_methodLooksDestructive(method.name)) continue;
        for (var i = method.start; i <= method.end && i < context.source.length; i++) {
          final line = context.source.masked[i];
          final match = _failureTelemetryCall.firstMatch(line);
          if (match == null) continue;
          if (!_hasLaterReconcileCall(context, i + 1, method.end)) continue;
          reporter.report(context, i, match.start);
        }
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
      correctionMessage:
          'Remove migration/version/install marker preservation. Let reset/clear hard-clear app-owned local storage.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags datasource/repository reset/clear methods that read and restore migration/version/install markers around storage clear.',
    scan: (reporter, context) {
      if (context.isTestFile) return;
      for (final classSpan in context.classes) {
        if (!_isStorageBoundaryClass(context, classSpan)) continue;
        for (final method in context.methods) {
          if (!classSpan.contains(method.start)) continue;
          if (!_methodLooksLikeResetAll(method.name)) continue;
          for (var i = method.start; i <= method.end && i < context.source.length; i++) {
            final line = context.source.masked[i];
            final match = _storageClearCall.firstMatch(line);
            if (match == null) continue;
            if (_clearPreservesSentinel(context, method, i)) {
              reporter.report(context, i, match.start);
            }
          }
        }
      }
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
      correctionMessage:
          'Wrap the persist call in a `Timer` (cancel-and-restart on next call) or a `Debouncer` so rapid mutations coalesce into one write.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags `_schedule*Persist` / `_persistDraft` helper methods that lack any Timer/Future.delayed/Debouncer reference inside their class.',
    scan: (reporter, context) {
      if (context.isTestFile) return;
      for (final classSpan in context.classes) {
        if (!classSpan.isNotifier) continue;
        if (!_hasPersistHelper(context, classSpan)) continue;
        if (_hasDebounceMechanism(context, classSpan)) continue;
        final helperLine = _persistHelperLine(context, classSpan);
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
      correctionMessage:
          'Capture a generation/request token before the await and return if it is stale before assigning `state`.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags private notifier init/restore/load methods that await and then assign state without an obvious generation/request/stale guard.',
    scan: (reporter, context) {
      if (context.isTestFile) return;
      for (final classSpan in context.classes) {
        if (!classSpan.isNotifier) continue;
        for (final method in context.methods) {
          if (!classSpan.contains(method.start)) continue;
          if (!_asyncNotifierInitializerMethod.hasMatch(method.name)) continue;
          final stateWriteLine = _unguardedAsyncStateWriteLine(context, method);
          if (stateWriteLine == null) continue;
          final line = context.source.masked[stateWriteLine];
          final col = _notifierStateWrite.firstMatch(line)?.start ?? 0;
          reporter.report(context, stateWriteLine, col);
        }
      }
    },
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
      correctionMessage:
          'Add a `bool _userRequested = false` (or `_userTapped...` / `_userOpened...`) field, set it in an `onTap` callback, and construct the heavy widget only when the flag is true.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags `InAppWebView`, `IOSInAppWebViewWidget`, `WebViewWidget`, `YoutubePlayer`, or `VideoPlayer` constructors inside `build()` of classes that declare no `_user*` / `*Tapped` / `*Requested` boolean gate field.',
    scan: (reporter, context) {
      if (context.isTestFile) return;
      for (final classSpan in context.classes) {
        for (final method in context.methods) {
          if (method.name != 'build') continue;
          if (!classSpan.contains(method.start)) continue;
          for (var i = method.start; i <= method.end && i < context.source.length; i++) {
            final line = context.source.masked[i];
            final match = _heavyWidgetInit.firstMatch(line);
            if (match == null) continue;
            if (_isHeavyWidgetGated(context, classSpan, method, i)) continue;
            reporter.report(context, i, match.start);
          }
        }
      }
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
      correctionMessage:
          'Add a `Map<String, T> _cache` field; check it before `_storage.read(...)`. Write through on `markSeen` / equivalent.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags `_storage.read` / `box.get` calls inside *Service classes that declare no `Map<String,*>` cache field.',
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
      correctionMessage:
          'Return a bounded projection (e.g. `s.lastNDays` / `s.count`) instead of deriving and retaining a new collection from the full source list.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags `@Riverpod(keepAlive: true)` notifiers whose build() derives retained state from `s.<unboundedCollectionName>`.',
    scan: (reporter, context) {
      if (context.isTestFile) return;
      for (final classSpan in context.classes) {
        if (!_isKeepAliveNotifier(context, classSpan)) continue;
        for (var i = classSpan.start; i <= classSpan.end && i < context.source.length; i++) {
          final column = _unboundedCollectionWatchColumn(context, i, classSpan.end);
          if (column == null) continue;
          reporter.report(context, i, column);
          break;
        }
      }
      for (var i = 0; i < context.source.length; i++) {
        if (!_keepAliveAnnotation.hasMatch(context.source.masked[i])) continue;
        final fnLine = _findFunctionDeclarationAfter(context, i);
        if (fnLine == null) continue;
        final body = _findFunctionBodyEnd(context, fnLine);
        if (body == null) continue;
        for (var j = fnLine; j <= body && j < context.source.length; j++) {
          final column = _unboundedCollectionWatchColumn(context, j, body);
          if (column == null) continue;
          reporter.report(context, j, column);
          break;
        }
      }
    },
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
      correctionMessage:
          'Expose a `Future<SettingsSnapshot> loadAll()` aggregator so callers can fetch everything in one read.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags abstract `*LocalDatasource` / `*RemoteDatasource` interfaces with 5+ single-value async getters and no loadAll/getAll/readAll method.',
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
