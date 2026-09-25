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
      // The skill bans these class kinds by name: "NEVER create ServiceFactory,
      // ServiceLocator, or BackendProvider class", including prefixed variants.
      final banned = RegExp(r'(?:ServiceFactory|ServiceLocator|BackendProvider)$');
      for (final declaration in context.unit.declarations.whereType<ClassDeclaration>()) {
        if (!banned.hasMatch(declaration.namePart.typeName.lexeme)) continue;
        _reportAtOffset(reporter, context, declaration.classKeyword.offset);
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
      final reportedLines = <int>{};
      for (var i = 0; i < context.source.length; i++) {
        final match = _manualProviderDeclarationMatch(context, i);
        if (match == null) continue;
        reportedLines.add(i);
        reporter.report(context, i, match.column);
      }
      _reportResolvedManualProviders(reporter, context, reportedLines);
    },
  ),

  /// Keep WidgetRef inside widgets.
  ///
  /// Why: `Ref` and `WidgetRef` stay separate; `WidgetRef` is for widgets only.
  /// A service, repository or other non-widget class holding or accepting a
  /// `WidgetRef` ties its lifetime to a widget element. Move the logic into a
  /// generated provider/notifier that uses `Ref`.
  scannerRule(
    code: const LintCode(
      'riverpod_widget_ref_outside_widget',
      'WidgetRef is for widgets only.',
      correctionMessage: 'Move this logic into a generated provider or notifier and use its Ref instead of WidgetRef.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags WidgetRef types used inside classes that are not Widget or State subclasses.',
    scan: _reportWidgetRefOutsideWidgets,
  ),

  /// Do not alias generated providers.
  ///
  /// Why: Generated provider names are the single source of truth. A top-level
  /// or static `final cartAliasProvider = cartProvider;` creates a second name
  /// for the same provider. Rename the annotated function/class and regenerate.
  scannerRule(
    code: const LintCode(
      'riverpod_generated_provider_alias',
      'Do not alias generated providers.',
      correctionMessage:
          'Rename the annotated function/class, regenerate .g.dart, and update call sites instead.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags top-level or static declarations whose value is an existing provider variable.',
    scan: _reportProviderAliases,
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
    description:
        'Flags ConsumerState cache/source fields and fields assigned from ref.watch/ref.read '
        'results so provider-derived data has one Riverpod source of truth.',
    scan: (reporter, context) {
      final reportedLines = <int>{};
      for (final classSpan in context.classes) {
        if (!_isConsumerStateClass(context, classSpan)) continue;
        if (!_classContainsRefWatch(context, classSpan)) continue;

        for (final lineIndex in directClassMemberLines(context, classSpan)) {
          final line = context.source.masked[lineIndex];
          final fieldName = _derivedCacheField.firstMatch(line)?.group(1);
          if (fieldName == null) continue;
          reportedLines.add(lineIndex);
          reporter.report(context, lineIndex, line.indexOf(fieldName));
        }
      }
      _reportResolvedConsumerStateCaches(reporter, context, reportedLines);
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
      for (final declaration in context.unit.declarations) {
        final (name, offset) = switch (declaration) {
          // riverpod_generator names `FooEventNotifier` `fooEventProvider`.
          ClassDeclaration(:final metadata, :final namePart, :final classKeyword)
              when metadata.any(_isRiverpodAnnotation) =>
            (_classProviderName(namePart.typeName.lexeme), classKeyword.offset),
          FunctionDeclaration(:final metadata, :final name)
              when metadata.any(_isRiverpodAnnotation) =>
            (_functionProviderGeneratedName(name.lexeme), name.offset),
          _ => (null, 0),
        };
        if (name == null || !_eventSignalProviderName.hasMatch(name)) continue;
        final location = context.unit.lineInfo.getLocation(offset);
        reporter.report(context, location.lineNumber - 1, location.columnNumber - 1);
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
      final watches = _BroadBuildWatchVisitor();
      context.unit.accept(watches);
      for (final offset in watches.offsets) {
        final location = context.unit.lineInfo.getLocation(offset);
        reporter.report(context, location.lineNumber - 1, location.columnNumber - 1);
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
        _reportAtOffset(reporter, context, creation.offset);
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
        _reportAtOffset(reporter, context, read.offset);
      }
    },
  ),

  /// Match AsyncValue with a sealed switch, not when/map helpers.
  ///
  /// Why: The skill matches unions with a Dart `switch` and never `.when()` or
  /// `.map()`. Riverpod AsyncValue is sealed, so the skill switches over
  /// `AsyncData(:final value)`, `AsyncError(:final error)` and `AsyncLoading()`.
  scannerRule(
    code: const LintCode(
      'async_value_switch_over_when',
      'Match AsyncValue with a switch, not when/map.',
      correctionMessage: 'Use switch (value) { AsyncData(:final value) => ..., AsyncError(:final error) => ..., AsyncLoading() => ... }.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags Riverpod AsyncValue when/maybeWhen/whenOrNull/map/maybeMap/mapOrNull calls so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      final calls = _AsyncValueWhenMapCalls();
      context.unit.accept(calls);
      for (final call in calls.nodes) {
        _reportAtOffset(reporter, context, call.methodName.offset);
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
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags auto-dispose providers without parameters whose watched dependencies all resolve, through their generated `@ProviderFor` variables, to `@Riverpod(keepAlive: true)` sources in any file.',
    scan: (reporter, context) {
      for (final definition in _providerDefinitions(context)) {
        if (definition.keepAlive || definition.hasParameters) continue;
        if (!_watchesOnlyKeepAliveProviders(context, definition)) continue;
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
      severity: DiagnosticSeverity.ERROR,
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
    _reportAtOffset(reporter, context, creation.offset);
  }
}
