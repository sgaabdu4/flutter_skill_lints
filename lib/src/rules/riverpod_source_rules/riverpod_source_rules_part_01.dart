part of '../riverpod_source_rules.dart';

final List<ScannerRule> _riverpodSourceRulesPart1 = [
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

  /// Use Riverpod code generation for providers.
  ///
  /// Why: Flags manual Riverpod provider constructors. The Flutter skill keeps
  /// providers generated through `@riverpod` / `@Riverpod` so provider names,
  /// lifetimes, and generated APIs stay as the single source of truth.
  scannerRule(
    code: const LintCode(
      'riverpod_manual_provider',
      'Use Riverpod code generation for providers.',
      correctionMessage: 'Replace manual Provider(...) declarations with @riverpod codegen.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags manual Riverpod provider declarations so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final match = _manualProviderDeclarationMatch(context, i);
        if (match == null) continue;
        reporter.report(context, i, match.column);
      }
    },
  ),

  /// Do not override generated notifier providers with state values.
  ///
  /// Why: `overrideWithValue(State(...))` replaces the generated notifier
  /// provider with a plain value override. Any runtime path that later reads
  /// `provider.notifier` can crash because the provider element no longer has
  /// notifier behavior. Use a test/E2E notifier override so `.notifier` remains valid.
  scannerRule(
    code: const LintCode(
      'riverpod_notifier_override_with_value',
      'Do not override generated notifier providers with state values.',
      correctionMessage:
          'Use provider.overrideWith(TestNotifier.new) so provider.notifier remains available.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags runtime overrideWithValue(State(...)) calls on likely generated notifier providers.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final match = _notifierStateOverrideWithValueMatch(context, i);
        if (match == null) continue;
        reporter.report(context, i, match.column);
      }
    },
  ),

  /// Keep provider-derived data in providers, not ConsumerState caches.
  ///
  /// Why: Flags manual cache/source fields in ConsumerState classes that also
  /// watch providers. Derived provider data belongs in one generated @riverpod
  /// source of truth or in pure build-local derivation, not repeated mutable widget state.
  scannerRule(
    code: const LintCode(
      'riverpod_consumer_state_derived_cache',
      'Do not cache provider-derived data in ConsumerState.',
      correctionMessage:
          'Move the cache to one @riverpod source of truth or compute it locally without mutable cache fields.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags ConsumerState cache/source fields used with ref.watch so provider-derived data has one Riverpod source of truth.',
    scan: (reporter, context) {
      for (final classSpan in context.classes) {
        if (!_isConsumerStateClass(context, classSpan)) continue;
        if (!_classContainsRefWatch(context, classSpan)) continue;

        for (final lineIndex in _directClassMemberLines(context, classSpan)) {
          final line = context.source.masked[lineIndex];
          final match = _derivedCacheField.firstMatch(line);
          if (match == null) continue;
          final fieldName = match.group(1);
          final column = fieldName == null ? match.start : line.indexOf(fieldName, match.start);
          reporter.report(context, lineIndex, column);
        }
      }
    },
  ),

  /// Do not store/pass provider-family arg wrapper objects in widgets.
  ///
  /// Why: Provider-family args are part of the provider boundary. Widgets
  /// should pass immutable IDs/primitives directly, or the provider/notifier
  /// should own derivation. `config` / `args` / `params` wrappers in widget
  /// state or build locals recreate controller logic in the widget layer.
  scannerRule(
    code: const LintCode(
      'riverpod_widget_provider_arg_wrapper',
      'Do not use provider arg wrapper objects in widgets.',
      correctionMessage:
          'Pass immutable IDs/primitives to generated providers, or derive args inside the provider/notifier.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags config/args/params wrapper objects passed from widgets into provider families.',
    scan: (reporter, context) {
      for (final classSpan in context.classes) {
        if (!_isConsumerStateClass(context, classSpan)) continue;

        for (final lineIndex in _directClassMemberLines(context, classSpan)) {
          final line = context.source.masked[lineIndex];
          final match = _providerArgWrapperMember.firstMatch(line);
          if (match == null) continue;
          final name = match.group(1);
          if (name == null || !_classPassesProviderArgName(context, classSpan, name)) continue;
          reporter.report(context, lineIndex, line.indexOf(name));
        }
      }

      for (final method in context.methods.where((method) => method.name == 'build')) {
        for (var i = method.start; i <= method.end; i++) {
          final line = context.source.masked[i];
          final localMatch = _providerArgWrapperLocal.firstMatch(line);
          if (localMatch != null) {
            final name = localMatch.group(1);
            if (name != null && _methodPassesProviderArgName(context, method, name)) {
              reporter.report(context, i, line.indexOf(name));
            }
          }

          final inlineMatch = _inlineProviderArgWrapper.firstMatch(line);
          if (inlineMatch == null) continue;
          reporter.report(context, i, inlineMatch.start);
        }
      }
    },
  ),

  /// Do not store ProviderSubscription handles in ConsumerState.
  ///
  /// Why: Widget-owned ProviderSubscription fields duplicate Riverpod lifecycle
  /// state. Widgets use `ref.listen` in build for UI side effects; durable
  /// synchronization belongs in one provider/notifier source of truth.
  scannerRule(
    code: const LintCode(
      'riverpod_consumer_state_provider_subscription',
      'Do not store ProviderSubscription fields in ConsumerState.',
      correctionMessage:
          'Use ref.listen in build for widget side effects, or move synchronization to the provider/notifier source of truth.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags ProviderSubscription fields in ConsumerState so Riverpod remains the lifecycle source of truth.',
    scan: (reporter, context) {
      for (final classSpan in context.classes) {
        if (!_isConsumerStateClass(context, classSpan)) continue;

        for (final lineIndex in _directClassMemberLines(context, classSpan)) {
          final line = context.source.masked[lineIndex];
          final match = _providerSubscriptionField.firstMatch(line);
          if (match == null) continue;
          final fieldName = match.group(1);
          final column = fieldName == null ? match.start : line.indexOf(fieldName, match.start);
          reporter.report(context, lineIndex, column);
        }
      }
    },
  ),

  /// Do not use ref.listenManual.
  ///
  /// Why: Manual Riverpod subscriptions create a second lifecycle source of
  /// truth in widgets. Use `ref.listen` in build for UI side effects; durable
  /// subscriptions belong in provider, notifier, repository, or service lifecycles.
  scannerRule(
    code: const LintCode(
      'riverpod_listen_manual_forbidden',
      'Do not use ref.listenManual.',
      correctionMessage:
          'Use ref.listen in build for widget side effects, or move durable subscriptions to a provider/notifier/service lifecycle.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags ref.listenManual calls so Riverpod owns subscription lifecycle from one source of truth.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        final match = _refListenManual.firstMatch(line);
        if (match == null) continue;
        reporter.report(context, i, match.start);
      }
    },
  ),

  /// Do not model one-shot UI events as standalone signal providers.
  ///
  /// Why: Standalone `*Signal` / `*Event` providers split one notifier's
  /// mutation result across two providers. Fold the event serial/payload into
  /// the owning notifier state and listen to a concrete field with `select`.
  scannerRule(
    code: const LintCode(
      'riverpod_event_counter_signal_forbidden',
      'Do not create standalone Riverpod signal/event providers.',
      correctionMessage:
          'Fold the event serial/payload into the owning notifier state, or rename durable status state to a concrete Status/Lifecycle notifier.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags standalone Riverpod signal/event providers so mutation state stays in one notifier source of truth.',
    scan: (reporter, context) {
      if (context.isTestFile) return;
      for (final classSpan in context.classes) {
        if (!_eventSignalProviderName.hasMatch(classSpan.name)) continue;
        if (!_hasRiverpodAnnotation(context, classSpan)) continue;
        reporter.report(
          context,
          classSpan.start,
          context.source.masked[classSpan.start].indexOf('class'),
        );
      }

      for (var i = 0; i < context.source.length; i++) {
        if (!context.hasNearbyAnnotation(i, const {'riverpod', 'Riverpod'})) continue;
        final line = context.source.masked[i];
        final match = _eventSignalFunctionProvider.firstMatch(line);
        if (match == null) continue;
        final name = match.group(1);
        if (name == null || !_eventSignalProviderName.hasMatch(name)) continue;
        reporter.report(context, i, line.indexOf(name));
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

  /// select() callbacks should use expression-body syntax.
  ///
  /// Why: Keeps Riverpod select examples concise and avoids block callbacks in leaf
  /// widget watches. Use ref.watch(provider.select((value) => value.field)).
  scannerRule(
    code: const LintCode(
      'riverpod_select_arrow_syntax',
      'Use arrow syntax for select() callbacks.',
      correctionMessage: 'Change select((value) { ... }) to select((value) => value.field).',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags select() callbacks without arrow syntax so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (final method in context.methods.where((method) => method.name == 'build')) {
        for (var i = method.start; i <= method.end; i++) {
          for (final invocation in _refWatchInvocations(context, i, method.end)) {
            if (!_hasBlockSelectCallback(invocation)) continue;
            final selectLine = _firstSelectLine(context, i, method.end);
            reporter.report(
              context,
              selectLine,
              context.source.masked[selectLine].indexOf('.select'),
            );
          }
        }
      }
    },
  ),

  /// select() must narrow to a field or record, not return the source object.
  ///
  /// Why: `select((value) => value)` silences broad-watch lint without reducing
  /// rebuild scope. Use a concrete field/record select, or watch a computed
  /// projection provider directly.
  scannerRule(
    code: const LintCode(
      'riverpod_select_identity_forbidden',
      'Do not use identity select callbacks.',
      correctionMessage:
          'Select concrete fields/records, or watch a generated computed projection provider directly.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags ref.watch(provider.select((value) => value)) so select remains a real rebuild boundary.',
    scan: (reporter, context) {
      for (final method in context.methods.where((method) => method.name == 'build')) {
        for (var i = method.start; i <= method.end; i++) {
          for (final invocation in _refWatchInvocations(context, i, method.end)) {
            if (!_hasIdentitySelectCallback(invocation)) continue;
            final selectLine = _firstSelectLine(context, i, method.end);
            reporter.report(
              context,
              selectLine,
              context.source.masked[selectLine].indexOf('.select'),
            );
          }
        }
      }
    },
  ),

  /// Mutation<T> usage should carry an experimental warning.
  ///
  /// Why: Riverpod Mutation is still experimental. Keep a nearby note so code reviewers
  /// see the API stability boundary at the call site.
  scannerRule(
    code: const LintCode(
      'riverpod_mutation_experimental_warning',
      'Mutation<T> usage must have nearby experimental context.',
      correctionMessage: 'Add a nearby comment that says Mutation is experimental.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags Mutation<T> usage without nearby experimental context so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      if (!context.path.contains('/notifiers/') && !context.path.endsWith('_notifier.dart')) {
        return;
      }
      final mutationUsage = RegExp(r'\bMutation\s*<');
      final experimental = RegExp(r'\bexperimental\b', caseSensitive: false);
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (RegExp(r'^\s*class\s+Mutation\s*<').hasMatch(line)) continue;
        if (RegExp(r'^\s*typedef\s+Mutation\s*<').hasMatch(line)) continue;
        if (RegExp(r'^\s*Mutation\s*<[^>]+>\s+\w+(?:<[^>]+>)?\s*\(').hasMatch(line)) {
          continue;
        }
        if (RegExp(
          r'^\s*(?:[A-Za-z_]\w*(?:<[^>]+>)?\??|void)\s+Mutation(?:<[^>]+>)?\s*\(',
        ).hasMatch(line)) {
          continue;
        }
        final match = mutationUsage.firstMatch(line);
        if (match != null && match.start > 0 && line[match.start - 1] == '.') continue;
        if (match == null || context.nearOriginal(i, experimental, 5)) continue;
        reporter.report(context, i, match.start);
      }
    },
  ),

  /// Keep derived providers alive when all watched dependencies are keepAlive.
  ///
  /// Why: Follows the building-flutter-apps provider decision tree for computed or
  /// one-time providers. If every watched dependency is keepAlive, make the derived
  /// non-family provider keepAlive too.
  scannerRule(
    code: const LintCode(
      'riverpod_auto_dispose_keepalive_dependencies',
      'Use keepAlive when all watched dependencies are keepAlive.',
      correctionMessage:
          'Change @riverpod to @Riverpod(keepAlive: true), unless this provider has parameters.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags auto-dispose providers whose same-file watched dependencies are all keepAlive.',
    scan: (reporter, context) {
      final definitions = _providerDefinitions(context);
      final definitionsByName = {
        for (final definition in definitions) definition.providerName: definition,
      };

      for (final definition in definitions) {
        if (definition.keepAlive || definition.hasParameters) continue;
        final watchedProviders = _watchedProviderNames(context, definition);
        if (watchedProviders.isEmpty) continue;
        if (!watchedProviders.every((name) => definitionsByName[name]?.keepAlive ?? false)) {
          continue;
        }
        reporter.report(context, definition.annotationLine, 0);
      }
    },
  ),

  /// Feature notifiers should be keepAlive by default.
  ///
  /// Why: Class-based feature notifiers own mutable screen/feature state. In
  /// presentation notifier files, accidental auto-dispose resets that state when
  /// a subtree temporarily unmounts. Family notifiers stay auto-dispose by
  /// default because keepAlive would cache every argument variant.
  scannerRule(
    code: const LintCode(
      'riverpod_feature_notifier_keepalive',
      'Feature notifiers should use keepAlive.',
      correctionMessage:
          'Change @riverpod to @Riverpod(keepAlive: true), or add an autoDispose rationale comment.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags non-family feature presentation notifiers that auto-dispose without rationale.',
    scan: (reporter, context) {
      if (!_isFeaturePresentationNotifierPath(context)) return;

      for (final definition in _providerDefinitions(context)) {
        if (!definition.isClassBased) continue;
        if (!definition.className.endsWith('Notifier')) continue;
        if (definition.keepAlive || definition.hasParameters) continue;
        if (_registersDisposeCleanup(context, definition)) continue;
        if (_hasAutoDisposeRationale(context, definition.annotationLine)) continue;
        reporter.report(context, definition.annotationLine, 0);
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
        if (_isKeepAliveRiverpodAnnotation(context, i) &&
            !_hasKeepAliveTickerModeWorkaround(context, i) &&
            (context.near(i, 'required ', 5) || _hasFamilySignatureAfterKeepAlive(context, i))) {
          reporter.report(context, i, line.indexOf('@Riverpod'));
        }
      }
    },
  ),
];
