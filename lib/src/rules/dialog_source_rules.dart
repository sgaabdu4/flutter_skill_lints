import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';
import 'package:flutter_skill_lints/src/rules/source_scanner_rule.dart';

final List<ScannerRule> dialogSourceRules = [
  /// Dialogs and sheets must not subscribe to the provider their own action mutates.
  ///
  /// Why: A modal route stays mounted for the entire dismiss animation. If the
  /// dialog widget watches state that its button callback mutates, the dialog
  /// rebuilds mid-dismiss against now-stale state and visibly flips its variant.
  /// Pass an immutable snapshot value object through the constructor instead.
  scannerRule(
    code: const LintCode(
      'dialog_widget_subscribes_to_mutable_provider',
      'Dialog/sheet widget watches a provider its own action also mutates.',
      correctionMessage: 'Pass an immutable snapshot value object via the constructor. The dialog must not subscribe to state its own action mutates.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags dialog/sheet widgets that ref.watch and ref.read(...notifier).<method>() on the same provider so the Flutter skill modal snapshot pattern is shown during analysis.',
    scan: (reporter, context) {
      if (context.isTestFile) return;
      _reportMutableProviderSubscriptions(reporter, context);
    },
  ),

  /// Modal parent widgets must not watch high-frequency provider fields.
  ///
  /// Why: A sheet/dialog parent often owns text fields, scroll views, and other
  /// large subtrees. Watching timer/ticker/progress fields there rebuilds the
  /// whole modal every tick. Extract the ticking controls to a leaf
  /// ConsumerWidget and watch the high-frequency field in that leaf only.
  scannerRule(
    code: const LintCode(
      'modal_high_frequency_watch_not_leaf',
      'Modal parent watches a high-frequency provider field.',
      correctionMessage: 'Extract the ticking/progress controls to a leaf ConsumerWidget and watch seconds/progress/isRunning there instead of in the sheet/dialog parent.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags dialog/sheet classes that watch timer, ticker, progress, or running-state provider fields in build().',
    scan: (reporter, context) {
      if (context.isTestFile) return;
      _reportHighFrequencyModalWatches(reporter, context);
    },
  ),

  /// Dialog button callbacks must pop with a result, not chain side effects.
  ///
  /// Why: Code after Navigator.pop runs against a dying widget tree — the
  /// dismiss animation has started, context.mounted will flip to false mid-flight,
  /// and any provider mutation triggers a rebuild on the disappearing dialog.
  /// Let the caller orchestrate side effects after `await showDialog<T>(...)`.
  scannerRule(
    code: const LintCode(
      'dialog_button_pop_then_state_mutation',
      'Dialog button mutates state or navigates after Navigator.pop.',
      correctionMessage: 'Dialogs must Navigator.pop(result) and exit. Move provider mutations or further navigation to the caller after `await showDialog<T>(...)`.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags code that runs after Navigator.pop inside a dialog/sheet widget so the modal snapshot pattern is shown during analysis.',
    scan: (reporter, context) {
      if (context.isTestFile) return;
      final dialogSpans = [
        for (final classSpan in context.classes)
          if (_isDialogHostClass(context, classSpan)) classSpan,
      ];
      for (final classSpan in dialogSpans) {
        _reportDialogPostPopMutation(reporter, context, classSpan);
      }
      _reportDialogPostPopNavigation(reporter, context, dialogSpans);
    },
  ),

  /// `select` records that read Map/Set/List getters notify on every parent change.
  ///
  /// Why: Records compare by field identity. A getter that builds a fresh Map,
  /// Set, or List per access produces a new identity on every read, so the
  /// record `==` is always false and the watcher rebuilds even when no relevant
  /// field changed. Watch primitive fields or memoize the derived value in a
  /// provider.
  scannerRule(
    code: const LintCode(
      'select_returns_unstable_record_identity',
      'Record select includes a getter that returns a fresh Map/Set/List each call.',
      correctionMessage: 'Records compare by field identity; getters that build a fresh Map/Set/List each call cause a rebuild on every notify. Watch primitive fields or memoize the derived value in a provider.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags ref.watch(...select((s) => (...record literal...))) where a field reads an explicit getter returning a Map/Set/Iterable (or, unresolved, a getter whose name implies one).',
    scan: (reporter, context) {
      if (context.isTestFile) return;
      final visitor = _UnstableRecordSelectVisitor();
      context.unit.accept(visitor);
      for (final select in visitor.selects) {
        reporter.reportOffset(context, select.operator!.offset);
      }
    },
  ),

  /// `build` must be pure. Do not assign to fields from inside build.
  ///
  /// Why: `build` may run any number of times for any reason. Caching a derived
  /// value in `_field ??= compute()` makes the widget retain stale data across
  /// the next provider invalidation and turns rebuilds into ordering-dependent
  /// state mutations. Compute the value in an event callback or expose it via
  /// a provider.
  scannerRule(
    code: const LintCode(
      'build_method_assigns_to_field',
      'build() must not assign to a field.',
      correctionMessage:
          'build must be pure. Move the assignment to initState, an event callback, or a provider.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags field assignments inside build methods so widget builds stay pure and idempotent.',
    scan: (reporter, context) {
      if (context.isTestFile) return;
      for (final method in context.methods.where((m) => m.name == 'build')) {
        for (var i = method.start + 1; i <= method.end && i < context.source.length; i++) {
          final line = context.source.masked[i];
          final match = _buildFieldAssignment.firstMatch(line);
          if (match == null) continue;
          if (_isInsideFunctionLiteral(context, i, match.start)) {
            continue;
          }
          reporter.report(context, i, line.length - line.trimLeft().length);
        }
      }
    },
  ),

  /// `build` must not call helpers that mutate instance state.
  ///
  /// Why: Moving field/controller writes into `_sync...()` or `_load...()` keeps
  /// the assignment out of sight but still makes build impure. `build` can run
  /// any time; a helper that writes fields, controller text/value, or calls
  /// `setState` turns rebuilds into state mutations.
  scannerRule(
    code: const LintCode(
      'build_calls_mutating_instance_method',
      'build() calls a helper that mutates instance state.',
      correctionMessage: 'Keep build pure. Move field/controller sync to initState, didUpdateWidget, an event callback, or a provider.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags build() calls to private methods that assign instance fields/controller properties or call setState.',
    scan: (reporter, context) {
      if (context.isTestFile) return;
      _reportMutatingBuildCalls(reporter, context);
    },
  ),

  /// State teardown belongs in the notifier, not in a widget callback after await.
  ///
  /// Why: When a widget awaits a notifier mutation and then calls reset/clear,
  /// the same mutation may have triggered a parent rebuild that unmounted the
  /// widget. context.mounted goes false, the teardown is skipped, and the
  /// screen never sees the cleared state. Make the notifier method own its
  /// own teardown on the success path. Screens self-navigate from the cleared
  /// state (`onMissing*` hooks), so a widget-side `.go(context)` chained off
  /// the awaited mutation is reported too.
  scannerRule(
    code: const LintCode(
      'widget_calls_notifier_teardown_after_await',
      'Widget calls notifier.reset/clear/dispose or navigates with .go(context) after awaiting a notifier mutation.',
      correctionMessage: 'Move the teardown into the notifier method on its success path and let the screen self-navigate from observed state (onMissing* hooks). Widgets dispatch and observe state; they do not orchestrate notifier lifecycle.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags reset/clear/dispose calls and .go(context)/context.go(...) navigation that follow an awaited notifier mutation in widget classes so the notifier owns its own teardown.',
    scan: (reporter, context) {
      if (context.isTestFile) return;
      _reportNotifierTeardownCalls(reporter, context);
    },
  ),

  /// After awaiting a modal, use a typed route .go(context), not pop navigation.
  ///
  /// Why: A screen that protects accidental exit with `PopScope(canPop: false)`
  /// intercepts every programmatic pop, including pop-fallback helpers, and
  /// flashes its own confirm-exit dialog. Use a typed `<Route>().go(context)`
  /// (or `context.go(...)`) which bypasses the local pop interceptor.
  scannerRule(
    code: const LintCode(
      'popscope_bypass_uses_go_not_pop',
      'Pop navigation after an awaited modal triggers PopScope interception.',
      correctionMessage: 'Use a typed `<Route>().go(context)` (or `context.go(...)`) for intentional navigation after an awaited modal; pop navigation triggers PopScope.onPopInvoked.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags context.pop* calls that follow an awaited modal helper inside the same method.',
    scan: (reporter, context) {
      if (context.isTestFile) return;
      for (final classSpan in context.classes) {
        final modalDepths = <int>{};
        var depth = 0;
        for (var i = classSpan.start; i <= classSpan.end && i < context.source.length; i++) {
          final line = context.source.masked[i];
          if (_awaitModalCall.hasMatch(line)) modalDepths.add(depth);
          if (modalDepths.isNotEmpty) {
            final match = _popNavigationCall.firstMatch(line);
            if (match != null) {
              reporter.report(context, i, match.start);
            }
          }
          depth += braceDelta(line);
          modalDepths.removeWhere((d) => depth < d);
        }
      }
    },
  ),

  /// `showDialog` / `showModalBottomSheet` must carry `routeSettings`.
  ///
  /// Why: Without a route name, the dialog/sheet route does not appear in
  /// observer logs, analytics, or `GoRouter` debug output as anything other
  /// than `?`. Pass `routeSettings: const RouteSettings(name: '<feature>-<intent>')`
  /// wherever a Flutter modal launcher is called; app helpers such as
  /// `showAppSheet` pass it once inside the helper.
  scannerRule(
    code: const LintCode(
      'modal_helper_requires_route_settings',
      'show modal helper missing routeSettings.',
      correctionMessage: 'Pass `routeSettings: const RouteSettings(name: "...")` so the dialog/sheet shows up in observer logs and analytics.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags Flutter modal launchers (showDialog, showModalBottomSheet, ...) called without a routeSettings argument.',
    scan: (reporter, context) {
      if (context.isTestFile) return;
      for (final call in collectNodes<MethodInvocation>(context.unit)) {
        if (_isFlutterModalLauncherWithoutRouteSettings(call)) {
          reporter.reportNode(context, call.methodName);
        }
      }
    },
  ),
];

void _reportMutableProviderSubscriptions(
  ScannerRuleReporter reporter,
  SourceScannerContext context,
) {
  for (final classSpan in context.classes) {
    if (_isDialogHostClass(context, classSpan) && _extendsConsumerSurface(context, classSpan)) {
      _reportMutableProviderClass(reporter, context, classSpan);
    }
  }
}

void _reportMutableProviderClass(
  ScannerRuleReporter reporter,
  SourceScannerContext context,
  ScannerClassSpan classSpan,
) {
  for (final declaration in context.unit.declarations.whereType<ClassDeclaration>()) {
    if (declaration.namePart.typeName.lexeme != classSpan.name) continue;
    final accesses = _ProviderAccessVisitor();
    declaration.accept(accesses);
    for (final (:watch, :provider) in accesses.watches) {
      if (!accesses.mutated.contains(provider)) continue;
      final ref = watch.target!;
      final lineIndex = context.unit.lineInfo.getLocation(ref.offset).lineNumber - 1;
      if (_lineIgnoresRule(context, lineIndex, 'dialog_widget_subscribes_to_mutable_provider')) {
        continue;
      }
      reporter.reportOffset(context, ref.offset);
    }
  }
}

/// Collects `ref.watch(<provider>)` calls and the providers mutated through
/// `ref.read(<provider>.notifier)`, keyed by their [_providerKey].
final class _ProviderAccessVisitor extends RecursiveAstVisitor<void> {
  final watches = <({MethodInvocation watch, Object provider})>[];
  final mutated = <Object>{};

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final argument = _refCallArgument(node);
    if (argument != null) {
      final provider = _providerKey(argument);
      if (provider != null && node.methodName.name == 'watch') {
        watches.add((watch: node, provider: provider));
      } else if (provider != null && _readsNotifier(argument)) {
        mutated.add(provider);
      }
    }
    super.visitMethodInvocation(node);
  }
}

/// The single argument of `ref.watch(...)` / `ref.read(...)` on a Riverpod `WidgetRef`/`Ref`.
Expression? _refCallArgument(MethodInvocation node) {
  if (!const {'watch', 'read'}.contains(node.methodName.name)) return null;
  if (!_isRiverpodRef(node.realTarget)) return null;
  final arguments = node.argumentList.arguments;
  return arguments.length == 1 ? arguments.single.argumentExpression : null;
}

bool _isRiverpodRef(Expression? target) {
  if (target == null) return false;
  final type = target.staticType;
  if (type is InterfaceType) return const {'WidgetRef', 'Ref'}.contains(type.element.name);
  return target is SimpleIdentifier && target.name == 'ref';
}

bool _readsNotifier(Expression argument) => switch (argument.unParenthesized) {
  PrefixedIdentifier(:final identifier) => identifier.name == 'notifier',
  PropertyAccess(:final propertyName) => propertyName.name == 'notifier',
  _ => false,
};

/// The provider a `watch`/`read` argument listens to, with `.select(...)`, `.notifier`,
/// `.future`, family calls and casts stripped: its element when resolved, otherwise its name.
Object? _providerKey(Expression argument) {
  final root = _providerRoot(argument);
  return root == null ? null : root.element ?? root.name;
}

SimpleIdentifier? _providerRoot(Expression expression) => switch (expression.unParenthesized) {
  SimpleIdentifier() && final identifier => identifier,
  AsExpression(:final expression) => _providerRoot(expression),
  PrefixedIdentifier(:final prefix, :final identifier)
      when _providerAccessors.contains(identifier.name) =>
    prefix,
  PropertyAccess(:final target?, :final propertyName)
      when _providerAccessors.contains(propertyName.name) =>
    _providerRoot(target),
  MethodInvocation(:final target?, :final methodName)
      when const {'select', 'selectAsync'}.contains(methodName.name) =>
    _providerRoot(target),
  MethodInvocation(target: null, :final methodName) => methodName,
  FunctionExpressionInvocation(:final function) => _providerRoot(function),
  _ => null,
};

const _providerAccessors = {'notifier', 'future', 'stream'};

/// Finds `ref.watch(<provider>.select((s) => (...record...)))` selects whose record reads a
/// getter that builds a fresh collection per call.
final class _UnstableRecordSelectVisitor extends RecursiveAstVisitor<void> {
  final selects = <MethodInvocation>[];

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'select' && _isWatchedSelect(node)) {
      final record = _selectedRecord(node);
      if (record != null && record.fields.any(_readsUnstableGetter)) selects.add(node);
    }
    super.visitMethodInvocation(node);
  }
}

bool _isWatchedSelect(MethodInvocation select) {
  final arguments = select.parent;
  final watch = arguments?.parent;
  return arguments is ArgumentList &&
      watch is MethodInvocation &&
      watch.methodName.name == 'watch' &&
      _isRiverpodRef(watch.realTarget);
}

RecordLiteral? _selectedRecord(MethodInvocation select) {
  final arguments = select.argumentList.arguments;
  if (arguments.length != 1) return null;
  final selector = arguments.single.argumentExpression.unParenthesized;
  if (selector is! FunctionExpression) return null;
  final body = selector.body;
  final returned = body is ExpressionFunctionBody ? body.expression.unParenthesized : null;
  return returned is RecordLiteral ? returned : null;
}

/// A record field reading an explicit (non-synthetic) getter that returns a Map, Set or
/// Iterable. Stored fields keep their identity between notifications. Unresolved reads
/// fall back to getter names such as `tagsMap` or `itemsByCategoryId`.
bool _readsUnstableGetter(RecordLiteralField field) {
  final property = switch (field.fieldExpression.unParenthesized) {
    PrefixedIdentifier(:final identifier) => identifier,
    PropertyAccess(:final propertyName) => propertyName,
    _ => null,
  };
  if (property == null) return false;
  final element = property.element;
  if (element is GetterElement) {
    return element.isOriginDeclaration &&
        _collectionChecker.isAssignableFromType(element.returnType);
  }
  return element == null && _unstableGetterName.hasMatch(property.name);
}

const _collectionChecker = TypeChecker.any([
  TypeChecker.fromUrl('dart:core#Map'),
  TypeChecker.fromUrl('dart:core#Iterable'),
]);

void _reportHighFrequencyModalWatches(ScannerRuleReporter reporter, SourceScannerContext context) {
  for (final classSpan in context.classes) {
    if (!_isDialogHostClass(context, classSpan) || !_extendsConsumerSurface(context, classSpan)) {
      continue;
    }
    for (final method in context.methods.where((method) => method.name == 'build')) {
      if (classSpan.contains(method.start)) {
        _reportHighFrequencyBuildMethod(reporter, context, method);
      }
    }
  }
}

void _reportHighFrequencyBuildMethod(
  ScannerRuleReporter reporter,
  SourceScannerContext context,
  ScannerMethodSpan method,
) {
  for (var i = method.start; i <= method.end && i < context.source.length; i++) {
    final line = context.source.masked[i];
    final watchStart = line.indexOf('ref.watch');
    if (watchStart < 0) continue;
    final watchWindow = sourceLineWindow(context, i, method.end, 8);
    if (!_highFrequencyWatch.hasMatch(watchWindow) ||
        _lineIgnoresRule(context, i, 'modal_high_frequency_watch_not_leaf')) {
      continue;
    }
    reporter.report(context, i, watchStart);
  }
}

void _reportMutatingBuildCalls(ScannerRuleReporter reporter, SourceScannerContext context) {
  for (final classSpan in context.classes) {
    final mutatingMethods = _mutatingPrivateMethods(context, classSpan);
    if (mutatingMethods.isEmpty) continue;
    for (final method in context.methods.where((method) => method.name == 'build')) {
      if (classSpan.contains(method.start)) {
        _reportMutatingBuildMethod(reporter, context, method, mutatingMethods);
      }
    }
  }
}

void _reportMutatingBuildMethod(
  ScannerRuleReporter reporter,
  SourceScannerContext context,
  ScannerMethodSpan method,
  Set<String> mutatingMethods,
) {
  for (var i = method.start + 1; i <= method.end && i < context.source.length; i++) {
    _reportMutatingBuildLine(reporter, context, i, mutatingMethods);
  }
}

void _reportMutatingBuildLine(
  ScannerRuleReporter reporter,
  SourceScannerContext context,
  int lineIndex,
  Set<String> mutatingMethods,
) {
  final line = context.source.masked[lineIndex];
  for (final methodName in mutatingMethods) {
    final matches = RegExp(r'\b' + RegExp.escape(methodName) + r'\s*\(').allMatches(line);
    for (final match in matches) {
      if (_isInsideFunctionLiteral(context, lineIndex, match.start)) continue;
      reporter.report(context, lineIndex, match.start);
      return;
    }
  }
}

void _reportNotifierTeardownCalls(ScannerRuleReporter reporter, SourceScannerContext context) {
  for (final classSpan in context.classes) {
    if (!classSpan.isNotifier && _extendsWidgetSurface(context, classSpan)) {
      _reportNotifierTeardownClass(reporter, context, classSpan);
    }
  }
}

void _reportNotifierTeardownClass(
  ScannerRuleReporter reporter,
  SourceScannerContext context,
  ScannerClassSpan classSpan,
) {
  final awaitedProviders = <String, int>{};
  var depth = 0;
  for (var i = classSpan.start; i <= classSpan.end && i < context.source.length; i++) {
    final line = context.source.masked[i];
    _rememberAwaitedNotifier(awaitedProviders, line, depth);
    _reportTeardownMatches(reporter, context, i, line, awaitedProviders);
    depth += braceDelta(line);
    awaitedProviders.removeWhere((_, recordedDepth) => depth < recordedDepth);
  }
}

void _rememberAwaitedNotifier(Map<String, int> providers, String line, int depth) {
  final match = _awaitedNotifierMethod.firstMatch(line);
  final provider = match?.group(1) ?? '';
  if (provider.isNotEmpty) providers[provider] = depth;
}

void _reportTeardownMatches(
  ScannerRuleReporter reporter,
  SourceScannerContext context,
  int lineIndex,
  String line,
  Map<String, int> awaitedProviders,
) {
  if (awaitedProviders.isEmpty) return;
  for (final match in _notifierTeardown.allMatches(line)) {
    if (awaitedProviders.containsKey(match.group(1) ?? '')) {
      reporter.report(context, lineIndex, match.start);
    }
  }
  for (final match in _goNavigationCall.allMatches(line)) {
    reporter.report(context, lineIndex, match.start);
  }
}

bool _isFlutterModalLauncherWithoutRouteSettings(MethodInvocation call) {
  final element = call.methodName.element;
  if (element is! TopLevelFunctionElement) return false;
  if (!element.library.identifier.startsWith('package:flutter/')) return false;
  if (!element.formalParameters.any((parameter) => parameter.name == 'routeSettings')) {
    return false;
  }
  return namedArgumentExpression(call.argumentList, 'routeSettings') == null;
}

void _reportDialogPostPopMutation(
  ScannerRuleReporter reporter,
  SourceScannerContext context,
  ScannerClassSpan classSpan,
) {
  final state = _DialogPopState();
  for (var i = classSpan.start; i <= classSpan.end && i < context.source.length; i++) {
    final line = context.source.masked[i];
    _reportPostPopOffender(reporter, context, state, i, line);
    _rememberPopInvocation(state, i, line);
    state.depth += braceDelta(line);
    if (state.hasPop && state.depth < state.popDepth) state.clearPop();
  }
}

/// Reports resolved navigation (another pop, or a typed-route / go_router /
/// Navigator push) that runs after a resolved pop in the same block. Offenders
/// the line scanner already reports are skipped.
void _reportDialogPostPopNavigation(
  ScannerRuleReporter reporter,
  SourceScannerContext context,
  List<ScannerClassSpan> dialogSpans,
) {
  int lineOf(AstNode node) => context.unit.lineInfo.getLocation(node.offset).lineNumber - 1;
  for (final pop in collectNodes<MethodInvocation>(context.unit)) {
    if (!isResolvedNavigationPop(pop)) continue;
    final popLine = lineOf(pop);
    if (!dialogSpans.any((span) => span.contains(popLine))) continue;
    final offender = followingBlockStatements(pop)
        .expand(collectNodes<MethodInvocation>)
        .where((call) => isResolvedNavigationPop(call) || isResolvedForwardNavigation(call))
        .firstOrNull;
    if (offender == null) continue;
    if (_postPopOffender.hasMatch(context.source.masked[lineOf(offender)])) continue;
    reporter.reportNode(context, offender);
  }
}

void _reportPostPopOffender(
  ScannerRuleReporter reporter,
  SourceScannerContext context,
  _DialogPopState state,
  int lineIndex,
  String line,
) {
  if (!state.hasPop || lineIndex <= state.popLine) return;
  final offender = _postPopOffender.firstMatch(line);
  if (offender == null) return;
  reporter.report(context, lineIndex, offender.start);
  state.clearPop();
}

void _rememberPopInvocation(_DialogPopState state, int lineIndex, String line) {
  if (_popInvocation.hasMatch(line)) state.recordPop(lineIndex);
}

final class _DialogPopState {
  int depth = 0;
  int popLine = -1;
  int popDepth = -1;

  bool get hasPop => popLine >= 0;

  void recordPop(int lineIndex) {
    popLine = lineIndex;
    popDepth = depth;
  }

  void clearPop() {
    popLine = -1;
    popDepth = -1;
  }
}

// ---------------------------------------------------------------------------
// Shared regex patterns and helpers
// ---------------------------------------------------------------------------

final _highFrequencyWatch = RegExp(
  r'\bref\s*\.\s*watch\s*\([\s\S]*?\.\s*select\s*\(\s*'
  r'(?:\([A-Za-z_]\w*\)|[A-Za-z_]\w*)\s*=>\s*[A-Za-z_]\w*\s*\.\s*'
  r'(?:seconds|elapsed|elapsedSeconds|tick|ticks|progress|percent|isRunning|isAnimating|isPlaying)\b',
);

final _popInvocation = RegExp(
  r'\b(?:Navigator\s*\.\s*(?:of\s*\([^)]*\)\s*\.\s*)?(?:pop|maybePop)|context\s*\.\s*pop[A-Za-z_]*)\s*\(',
);

final _postPopOffender = RegExp(
  r'\b(?:ref\s*\.\s*(?:read|watch|invalidate|refresh)\s*\(|'
  r'context\s*\.\s*(?:go|push|replace|goNamed|pushNamed|replaceNamed)\b|'
  r'Navigator\s*\.\s*(?:of\s*\([^)]*\)\s*\.\s*)?(?:push|pushNamed|pushReplacement|pushReplacementNamed)\s*\(|'
  r'\b[A-Z]\w*Route\s*\([^)]*\)\s*\.\s*go\s*\()',
);

final _unstableGetterName = RegExp(
  r'^[A-Za-z_]\w*(?:Map|Set|Sets|Ids|Items|Entries|sBy[A-Z]\w*|By[A-Z]\w*)$',
);
final _buildFieldAssignment = RegExp(
  r'^\s*(?:this\s*\.\s*[A-Za-z_]\w*|_[A-Za-z]\w*)\s*(?:\?\?=|=(?![=>]))',
);

final _instanceStateMutation = RegExp(
  r'^\s*(?:this\s*\.\s*)?_[A-Za-z]\w*(?:\s*(?:\?\?=|=(?![=>]))|\s*\.\s*[A-Za-z_]\w*\s*=(?![=>]))|\bsetState\s*\(',
);

final _awaitedNotifierMethod = RegExp(
  r'\bawait\s+ref\s*\.\s*read\s*\(\s*([A-Za-z_]\w*)\b[^)]*\.\s*notifier\s*\)\s*\.\s*[A-Za-z_]\w*\s*\(',
);

final _notifierTeardown = RegExp(
  r'\bref\s*\.\s*read\s*\(\s*([A-Za-z_]\w*)\b[^)]*\.\s*notifier\s*\)\s*\.\s*(?:reset|clear|dispose)\s*\(',
);

final _goNavigationCall = RegExp(r'\.\s*go\s*\(');

final _awaitModalCall = RegExp(
  r'\bawait\s+(?:\w+\s*\.\s*)?'
  r'(?:show(?:Dialog|ModalBottomSheet)|show[A-Z]\w*(?:Dialog|Sheet|BottomSheet))\b',
);

final _popNavigationCall = RegExp(r'\bcontext\s*\.\s*pop[A-Za-z_]*\s*\(');

bool _isDialogHostClass(SourceScannerContext context, ScannerClassSpan classSpan) {
  if (_classNameLooksLikeDialog(classSpan.name)) return true;
  final path = context.path.toLowerCase();
  return path.endsWith('_dialog.dart') ||
      path.endsWith('_sheet.dart') ||
      path.endsWith('_bottom_sheet.dart') ||
      path.endsWith('_dialog_content.dart') ||
      path.endsWith('_sheet_content.dart');
}

bool _classNameLooksLikeDialog(String name) {
  return name.endsWith('Dialog') ||
      name.endsWith('DialogContent') ||
      name.endsWith('Sheet') ||
      name.endsWith('SheetContent') ||
      name.endsWith('BottomSheet');
}

bool _extendsConsumerSurface(SourceScannerContext context, ScannerClassSpan classSpan) {
  final signature = sourceClassSignature(context, classSpan);
  return _consumerSurface.hasMatch(signature);
}

bool _extendsWidgetSurface(SourceScannerContext context, ScannerClassSpan classSpan) {
  final signature = sourceClassSignature(context, classSpan);
  return _widgetSurface.hasMatch(signature);
}

final _consumerSurface = RegExp(
  r'\bextends\s+(?:ConsumerWidget|ConsumerStatefulWidget|HookConsumerWidget|ConsumerState\b|HookConsumerState\b)',
);

final _widgetSurface = RegExp(
  r'\bextends\s+(?:ConsumerWidget|ConsumerStatefulWidget|HookConsumerWidget|StatelessWidget|StatefulWidget|HookWidget|ConsumerState\b|HookConsumerState\b|State\s*<)',
);

Set<String> _mutatingPrivateMethods(SourceScannerContext context, ScannerClassSpan classSpan) {
  final names = <String>{};
  for (final method in context.methods) {
    if (!classSpan.contains(method.start)) continue;
    if (!method.name.startsWith('_')) continue;
    if (method.name == '_debugFillProperties') continue;
    for (var i = method.start + 1; i <= method.end && i < context.source.length; i++) {
      if (!_instanceStateMutation.hasMatch(context.source.masked[i])) continue;
      names.add(method.name);
      break;
    }
  }
  return names;
}

bool _lineIgnoresRule(SourceScannerContext context, int lineIndex, String ruleName) {
  final pattern = RegExp(r'//\s*ignore(?:_for_file)?\s*:\s*([^\n]+)');
  return _hasIgnoredCode(context, [lineIndex, lineIndex - 1], pattern, ruleName) ||
      _hasIgnoredCode(context, _leadingLines(context), pattern, ruleName);
}

Iterable<int> _leadingLines(SourceScannerContext context) sync* {
  for (var i = 0; i < context.source.length && i < 20; i++) {
    yield i;
  }
}

bool _hasIgnoredCode(
  SourceScannerContext context,
  Iterable<int> lines,
  RegExp pattern,
  String ruleName,
) {
  for (final lineIndex in lines) {
    if (lineIndex < 0 || lineIndex >= context.source.length) continue;
    final match = pattern.firstMatch(context.source.original[lineIndex]);
    final codes = match?.group(1)?.split(',').map((code) => code.trim()).toSet();
    if (codes?.contains(ruleName) ?? false) return true;
  }
  return false;
}

bool _isInsideFunctionLiteral(SourceScannerContext context, int lineIndex, int column) {
  final offset = context.source.lineOffsets[lineIndex] + column;
  AstNode? node = context.unit.nodeCovering(offset: offset);
  while (node != null && node is! MethodDeclaration) {
    if (node is FunctionExpression && !isImmediatelyInvoked(node)) return true;
    node = node.parent;
  }
  return false;
}
