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
    description: 'Flags ref.read calls made from initState so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final column = context.initStateReadColumn(i);
        if (column != null) {
          reporter.report(context, i, column);
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
    description: 'Flags service locator classes in Riverpod apps so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (RegExp(r'\bclass\s+(?:ServiceFactory|ServiceLocator|BackendProvider)\b')
            .hasMatch(line)) {
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
    description: 'Flags manual Riverpod provider declarations so the Flutter skill violation is shown during analysis.',
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
      correctionMessage: 'Move the cache to one @riverpod source of truth or compute it locally without mutable cache fields.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags ConsumerState cache/source fields used with ref.watch so provider-derived data has one Riverpod source of truth.',
    scan: (reporter, context) {
      for (final classSpan in context.classes) {
        if (!_isConsumerStateClass(context, classSpan)) continue;
        if (!_classContainsRefWatch(context, classSpan)) continue;

        reportDirectClassMemberMatches(reporter, context, classSpan, _derivedCacheField);
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
      correctionMessage: 'Pass immutable IDs/primitives to generated providers, or derive args inside the provider/notifier.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags config/args/params wrapper objects passed from widgets into provider families.',
    scan: (reporter, context) {
      _reportProviderArgWrapperMembers(reporter, context);
      _reportProviderArgWrapperBuildLocals(reporter, context);
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
      correctionMessage: 'Use ref.listen in build for widget side effects, or move synchronization to the provider/notifier source of truth.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags ProviderSubscription fields in ConsumerState so Riverpod remains the lifecycle source of truth.',
    scan: (reporter, context) {
      for (final classSpan in context.classes) {
        if (!_isConsumerStateClass(context, classSpan)) continue;

        reportDirectClassMemberMatches(reporter, context, classSpan, _providerSubscriptionField);
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
      correctionMessage: 'Use ref.listen in build for widget side effects, or move durable subscriptions to a provider/notifier/service lifecycle.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags ref.listenManual calls so Riverpod owns subscription lifecycle from one source of truth.',
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
      correctionMessage: 'Fold the event serial/payload into the owning notifier state, or rename durable status state to a concrete Status/Lifecycle notifier.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags standalone Riverpod signal/event providers so mutation state stays in one notifier source of truth.',
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
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags broad ref.watch calls that do not use select so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      // Scalar values already form an atomic rebuild boundary.
      final scalarWatches = _ScalarWatchVisitor();
      context.unit.accept(scalarWatches);
      // Generated providers legitimately watch dependencies in build().
      for (final method in context.methods.where((m) => m.name == 'build')) {
        if (context.classes.any(
          (span) =>
              span.start <= method.start &&
              span.end >= method.end &&
              _hasRiverpodAnnotation(context, span),
        )) {
          continue;
        }
        for (var i = method.start; i <= method.end; i++) {
          final column = _broadRefWatchColumn(context, i, method.end, scalarWatches.offsets);
          if (column != null) reporter.report(context, i, column);
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
    description: 'Flags select() callbacks without arrow syntax so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) => _scanSelectViolations(reporter, context, _hasBlockSelectCallback),
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
      correctionMessage: 'Select concrete fields/records, or watch a generated computed projection provider directly.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags ref.watch(provider.select((value) => value)) so select remains a real rebuild boundary.',
    scan: (reporter, context) =>
        _scanSelectViolations(reporter, context, _hasIdentitySelectCallback),
  ),

  /// Riverpod Mutation<T>() declarations must carry an experimental note.
  ///
  /// Why: Riverpod Mutation is still experimental. The skill's file-scope
  /// mutation carries the note on its own declaration so reviewers see the API
  /// stability boundary.
  scannerRule(
    code: const LintCode(
      'riverpod_mutation_experimental_warning',
      'Mutation<T> declarations must carry an experimental note.',
      correctionMessage:
          'Add a comment on the Mutation declaration that says the API is experimental.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags Riverpod Mutation<T>() creations whose declaration has no experimental comment so the Flutter skill violation is shown during analysis.',
    scan: _scanMutationExperimentalWarning,
  ),

  /// Riverpod mutations are file-scope finals.
  ///
  /// Why: The skill declares one mutation as one file-scope `final` so the same
  /// instance is shared across rebuilds and consumers. A Mutation created in
  /// build(), a method, or a class field is a new or class-owned instance.
  scannerRule(
    code: const LintCode(
      'riverpod_mutation_top_level',
      'Declare Mutation<T> as a file-scope final.',
      correctionMessage:
          'Move the Mutation to a top-level final so rebuilds and consumers share one instance.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags Riverpod Mutation<T>() creations that are not the initializer of a top-level final so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      final creations = _RiverpodMutationCreations();
      context.unit.accept(creations);
      for (final creation in creations.nodes) {
        final variable = creation.parent;
        final list = variable?.parent;
        if (variable is VariableDeclaration &&
            variable.initializer == creation &&
            list is VariableDeclarationList &&
            list.isFinal &&
            list.parent is TopLevelVariableDeclaration) {
          continue;
        }
        _reportAtNode(reporter, context, creation);
      }
    },
  ),

  /// Use tsx.get instead of ref.read inside Mutation.run.
  ///
  /// Why: The skill reads providers through the mutation transaction because
  /// tsx.get keeps them alive until the mutation completes; ref.read does not.
  scannerRule(
    code: const LintCode(
      'riverpod_mutation_ref_read',
      'Use tsx.get instead of ref.read inside Mutation.run.',
      correctionMessage: 'Read providers through the mutation transaction (tsx.get) so they stay alive until the mutation completes.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags Riverpod read calls inside a Riverpod Mutation.run callback so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      final reads = _RiverpodReadsInMutationRun();
      context.unit.accept(reads);
      for (final read in reads.nodes) {
        _reportAtNode(reporter, context, read);
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
      correctionMessage: 'Change @riverpod to @Riverpod(keepAlive: true), or add an autoDispose rationale comment.',
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
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags keepAlive Riverpod families with required parameters so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (_isKeepAliveRiverpodAnnotation(context, i) &&
            !_hasKeepAliveTickerModeWorkaround(context, i) &&
            _hasFamilySignatureAfterKeepAlive(context, i)) {
          reporter.report(context, i, line.indexOf('@Riverpod'));
        }
      }
    },
  ),
];

void _reportProviderArgWrapperMembers(ScannerRuleReporter reporter, SourceScannerContext context) {
  for (final classSpan in context.classes) {
    if (!_isConsumerStateClass(context, classSpan)) continue;
    for (final lineIndex in directClassMemberLines(context, classSpan)) {
      _reportProviderArgWrapperMember(reporter, context, classSpan, lineIndex);
    }
  }
}

void _reportProviderArgWrapperMember(
  ScannerRuleReporter reporter,
  SourceScannerContext context,
  ScannerClassSpan classSpan,
  int lineIndex,
) {
  final line = context.source.masked[lineIndex];
  final match = _providerArgWrapperMember.firstMatch(line);
  final name = match?.group(1);
  if (match == null || name == null || !_classPassesProviderArgName(context, classSpan, name)) {
    return;
  }
  reporter.report(context, lineIndex, line.indexOf(name));
}

void _reportProviderArgWrapperBuildLocals(
  ScannerRuleReporter reporter,
  SourceScannerContext context,
) {
  for (final method in context.methods.where((method) => method.name == 'build')) {
    for (var lineIndex = method.start; lineIndex <= method.end; lineIndex++) {
      _reportProviderArgWrapperLocal(reporter, context, method, lineIndex);
    }
  }
}

void _reportProviderArgWrapperLocal(
  ScannerRuleReporter reporter,
  SourceScannerContext context,
  ScannerMethodSpan method,
  int lineIndex,
) {
  final line = context.source.masked[lineIndex];
  final localMatch = _providerArgWrapperLocal.firstMatch(line);
  final name = localMatch?.group(1);
  if (localMatch != null && name != null && _methodPassesProviderArgName(context, method, name)) {
    reporter.report(context, lineIndex, line.indexOf(name));
  }
  final inlineMatch = _inlineProviderArgWrapper.firstMatch(line);
  if (inlineMatch != null) reporter.report(context, lineIndex, inlineMatch.start);
}

void _scanMutationExperimentalWarning(ScannerRuleReporter reporter, SourceScannerContext context) {
  final experimental = RegExp(r'\bexperimental\b', caseSensitive: false);
  final creations = _RiverpodMutationCreations();
  context.unit.accept(creations);
  for (final creation in creations.nodes) {
    final owner = creation.thisOrAncestorMatching(
      (node) => node is Statement || node is CompilationUnitMember || node is ClassMember,
    );
    if (owner == null) continue;
    final first = owner is AnnotatedNode
        ? (owner.metadata.isEmpty
              ? owner.firstTokenAfterCommentAndMetadata
              : owner.metadata.first.beginToken)
        : owner.beginToken;
    final comments = _ownedComments(context, first, owner.endToken, trailing: true);
    if (comments.any(experimental.hasMatch)) continue;
    _reportAtNode(reporter, context, creation);
  }
}
