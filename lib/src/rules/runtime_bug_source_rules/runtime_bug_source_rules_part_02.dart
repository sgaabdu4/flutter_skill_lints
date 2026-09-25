part of '../runtime_bug_source_rules.dart';

final List<ScannerRule> _runtimeBugSourceRulesPart2 = [
  /// Save callbacks for numeric forms must guard zero/empty input.
  ///
  /// Why: A "save" button that persists `amount: 0` and `count: 0` creates
  /// empty rows the user did not intend. Guard with
  /// `if (amount > 0 || count > 0)` around the call, or return early with
  /// `if (amount <= 0 && count <= 0) return;` (or `isNotEmpty` / `isEmpty` for
  /// strings/lists). Only arguments whose resolved type is `int`, `double` or `num`
  /// need the guard; a Value Object such as `Distance` owns its own invariants.
  scannerRule(
    code: const LintCode(
      'notifier_zero_value_save_no_guard',
      'Save call passes numeric fields without a positive-value guard.',
      correctionMessage: 'Wrap the `ref.read(...notifier).save*(...)` call in `if (amount > 0 || count > 0)` (or equivalent) so empty submissions cannot persist.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags `ref.read(...notifier).save*(amount: .., count: ..)` (and similar named args such as `duration`, `distance`, `weight`, `size`, `total`) whose resolved type is numeric, unless an enclosing `> 0` / `isNotEmpty` guard or an earlier `<= 0` / `isEmpty` early return protects the call.',
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
  /// Why: `onChanged` fires on every keystroke. A handler that starts an async notifier
  /// operation, network call, or any `await` runs once per char. Without a
  /// Timer-based debounce, typing "hello" sends 5 requests. Debounce in the
  /// notifier (cancel-and-restart Timer) or wrap with a `Debouncer`.
  scannerRule(
    code: const LintCode(
      'text_field_on_changed_no_debounce',
      'TextField onChanged triggers expensive work without debounce.',
      correctionMessage: 'Debounce asynchronous work in the notifier or event handler using the project latency budget.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags TextField/TextFormField onChanged callbacks (lambdas or tear-offs) that reach asynchronous or remote work (await, Future/Stream-typed calls, async callees, unresolved calls) without debounce in the file or in the project callee\'s file. Synchronous state-only updates are allowed.',
    scan: (reporter, context) {
      if (context.isTestFile) return;
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        final m = _textInputConstructor.firstMatch(line);
        if (m == null) continue;
        final col = line.indexOf(m.group(1) ?? 'TextField', m.start);
        if (!_onChangedHasWork(context, i, col)) continue;
        if (_fileHasDebounce(context)) continue;
        reporter.report(context, i, col);
      }
    },
  ),

  /// `Slider` `onChanged` must defer expensive work to `onChangeEnd` or debounce.
  ///
  /// Why: Slider `onChanged` fires continuously during drag (~60Hz). An
  /// async notifier operation or awaited work inside fires dozens of times for a
  /// single user gesture. Use `onChangeEnd` for terminal effects, or
  /// debounce.
  scannerRule(
    code: const LintCode(
      'slider_on_changed_no_debounce',
      'Slider onChanged triggers expensive work without debounce or onChangeEnd.',
      correctionMessage: 'Move the notifier call to `onChangeEnd`, or debounce with a Timer. `onChanged` should only update local UI state.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags Slider/RangeSlider/CupertinoSlider onChanged callbacks (lambdas or tear-offs) that reach asynchronous or remote work (await, Future/Stream-typed calls, async callees, unresolved calls) without debounce.',
    scan: (reporter, context) {
      if (context.isTestFile) return;
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        final m = _sliderConstructor.firstMatch(line);
        if (m == null) continue;
        final col = line.indexOf(m.group(1) ?? 'Slider', m.start);
        if (!_onChangedHasWork(context, i, col)) continue;
        if (_fileHasDebounce(context)) continue;
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
      correctionMessage: 'Throttle the callback with a Timer or guard with a last-fired-at timestamp; scroll callbacks run per pixel.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags `<ScrollController>.addListener(...)` callbacks that call a notifier method or await async work without Timer/throttle in the same file.',
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
      correctionMessage: 'Reduce foreground debounce/wait durations: search/realtime <=150ms, animations <=120ms, persistence or Future.delayed hard waits <=50ms. Move sync/retry/domain waits to background owners.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags long Duration literals in UI/notifier/app-flow debounce, Timer, Future.delayed, animation, and transition contexts while ignoring tests, repositories, datasources, services, retry/backoff, rest timers, reminders, and sync/backfill settle timers.',
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
      correctionMessage: 'Wrap the local in a domain Value Object (e.g. `Distance.fromMeters(distance)`) at the boundary; the notifier should accept the VO, not the primitive.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags `double|int <name>(Meters|Seconds|Kilometers|Miles|Cents|Percent)` local declarations followed by a `ref.read(...notifier).save*(...)` call in the same method.',
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
      correctionMessage: 'Load the collection once before the loop, or add a batched lookup that resolves all keys in one pass. Awaiting a load-all call per iteration is O(items × rows).',
      severity: DiagnosticSeverity.WARNING,
    ),
    description: 'Flags an awaited getAll/fetchAll/loadAll-style full-collection load inside a for/while loop body.',
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
      correctionMessage: 'Route the native/webview/media command through an error-handling helper (a try/catch wrapper or .catchError) instead of unawaited(...). Unhandled rejections escape to the global error handler and are often misreported as fatal crashes.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description: 'Flags a webview/media controller command (runJavaScript, playVideo, seekTo, ...) passed directly to unawaited(...) without error handling.',
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
    if (match == null) return false;
    final call = _saveInvocationAt(context, lineIndex, match.start);
    if (call == null || !_passesNumericNamedArgument(call) || _hasZeroValueGuard(call)) {
      return false;
    }
    reporter.report(context, lineIndex, match.start);
    return false;
  });
}

MethodInvocation? _saveInvocationAt(SourceScannerContext context, int lineIndex, int column) {
  final offset = context.source.lineOffsets[lineIndex] + column;
  for (
    AstNode? node = context.unit.nodeCovering(offset: offset);
    node != null;
    node = node.parent
  ) {
    if (node is MethodInvocation && node.operator?.offset == offset) return node;
  }
  return null;
}

bool _passesNumericNamedArgument(MethodInvocation call) =>
    call.argumentList.arguments.whereType<NamedArgument>().any((argument) {
      if (!_numericNamedArg.hasMatch('${argument.name.lexeme}:')) return false;
      final type = argument.argumentExpression.staticType;
      return type != null && (type.isDartCoreInt || type.isDartCoreDouble || type.isDartCoreNum);
    });

/// Whether an enclosing `if (x > 0)` wraps [call] or an earlier
/// `if (x <= 0) return;` in an enclosing block exits before it.
bool _hasZeroValueGuard(MethodInvocation call) {
  AstNode child = call;
  for (var parent = call.parent; parent != null; child = parent, parent = parent.parent) {
    if (parent is FunctionBody) return false;
    if (parent is IfStatement &&
        parent.thenStatement == child &&
        _conditionMatches(parent.expression, _isPositiveCheck)) {
      return true;
    }
    if (parent is Block && _exitsBeforeChild(parent, child)) return true;
  }
  return false;
}

/// Whether a statement of [block] before [child] is an `if (x <= 0) return;` guard.
bool _exitsBeforeChild(Block block, AstNode child) => block.statements
    .takeWhile((statement) => statement != child)
    .any((statement) => statement is IfStatement && _isEarlyReturnZeroGuard(statement));

bool _isEarlyReturnZeroGuard(IfStatement statement) {
  if (statement.elseStatement != null) return false;
  final then = statement.thenStatement;
  final exits =
      then is ReturnStatement ||
      (then is Block && then.statements.length == 1 && then.statements.single is ReturnStatement);
  return exits && _conditionMatches(statement.expression, _isNonPositiveCheck);
}

bool _conditionMatches(Expression condition, bool Function(Expression) check) {
  final expression = condition.unParenthesized;
  if (check(expression)) return true;
  if (expression is BinaryExpression && const {'&&', '||'}.contains(expression.operator.lexeme)) {
    return _conditionMatches(expression.leftOperand, check) ||
        _conditionMatches(expression.rightOperand, check);
  }
  return false;
}

bool _isPositiveCheck(Expression expression) =>
    _isZeroComparison(expression, const {'>': 0, '>=': 1, '!=': 0}) ||
    _isEmptinessCheck(expression, 'isNotEmpty');

bool _isNonPositiveCheck(Expression expression) =>
    _isZeroComparison(expression, const {'<=': 0, '<': 1, '==': 0}) ||
    _isEmptinessCheck(expression, 'isEmpty');

bool _isZeroComparison(Expression expression, Map<String, int> bounds) {
  if (expression is! BinaryExpression) return false;
  final bound = bounds[expression.operator.lexeme];
  final right = expression.rightOperand.unParenthesized;
  return bound != null && right is IntegerLiteral && right.value == bound;
}

bool _isEmptinessCheck(Expression expression, String property) => switch (expression) {
  PrefixedIdentifier(:final identifier) => identifier.name == property,
  PropertyAccess(:final propertyName) => propertyName.name == property,
  _ => false,
};

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

/// Whether the `onChanged` callback of the input at [column] reaches
/// asynchronous or remote work (#37): an `await`, a Future/Stream-typed call,
/// an async callee, or a call that does not resolve. A lambda body is walked;
/// a tear-off is judged by its resolved callee. Callees declared in this
/// project are followed (other files through [_ParsedWorkFinder]), so
/// synchronous state-only updates (`copyWith`, local validation) stay clean;
/// SDK and package callees are judged by their resolved signature.
bool _onChangedHasWork(SourceScannerContext context, int lineIndex, int column) {
  final callback = _onChangedCallback(context, context.source.lineOffsets[lineIndex] + column);
  if (callback == null) return false;
  final finder = _AsyncWorkFinder(context);
  switch (callback.unParenthesized) {
    case FunctionExpression(:final body):
      body.accept(finder);
    case final SimpleIdentifier tearOff:
      finder.checkTearOff(tearOff, tearOff.element);
    case final PrefixedIdentifier tearOff:
      finder.checkTearOff(tearOff, tearOff.identifier.element);
    case final PropertyAccess tearOff:
      finder.checkTearOff(tearOff, tearOff.propertyName.element);
    case final other:
      other.accept(finder);
  }
  return finder.found;
}

Expression? _onChangedCallback(SourceScannerContext context, int offset) {
  AstNode? node = context.unit.nodeCovering(offset: offset);
  while (node != null && node is! InstanceCreationExpression && node is! MethodInvocation) {
    node = node.parent;
  }
  final arguments = switch (node) {
    InstanceCreationExpression(:final argumentList) => argumentList.arguments,
    MethodInvocation(:final argumentList) => argumentList.arguments,
    _ => const <Argument>[],
  };
  for (final argument in arguments.whereType<NamedArgument>()) {
    if (argument.name.lexeme == 'onChanged') return argument.argumentExpression;
  }
  return null;
}

final class _AsyncWorkFinder extends RecursiveAstVisitor<void> {
  _AsyncWorkFinder(this.context);

  final SourceScannerContext context;
  final _followed = <Element>{};
  final _parsed = <String, CompilationUnit?>{};
  var _depth = 0;
  bool found = false;

  void checkTearOff(Expression tearOff, Element? element) {
    final type = tearOff.staticType;
    if (type is! FunctionType || _isAsyncType(type.returnType)) {
      found = true;
      return;
    }
    if (element is MethodElement ||
        element is TopLevelFunctionElement ||
        element is LocalFunctionElement) {
      _follow(element as ExecutableElement);
    }
  }

  @override
  void visitAwaitExpression(AwaitExpression node) => found = true;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _checkInvocation(node, node.methodName.element);
    if (!found) super.visitMethodInvocation(node);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    _checkInvocation(node, node.element);
    if (!found) super.visitFunctionExpressionInvocation(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final constructor = node.constructorName.element;
    if (constructor == null || _isAsyncType(node.staticType)) {
      found = true;
      return;
    }
    _follow(constructor);
    if (!found) super.visitInstanceCreationExpression(node);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    final setter = node.writeElement;
    if (setter is SetterElement && !setter.isOriginVariable) _follow(setter);
    if (!found) super.visitAssignmentExpression(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    final getter = node.element;
    if (getter is GetterElement && !getter.isOriginVariable) _follow(getter);
  }

  void _checkInvocation(InvocationExpression node, Element? element) {
    if (node.staticInvokeType is! FunctionType || _isAsyncType(node.staticType)) {
      found = true;
      return;
    }
    if (element is ExecutableElement) _follow(element);
  }

  void _follow(ExecutableElement element) {
    if (found) return;
    if (!element.fragments.every((fragment) => fragment.isSynchronous) ||
        _isAsyncType(element.returnType)) {
      found = true;
      return;
    }
    if (_depth >= 4 || !_followed.add(element.baseElement)) return;
    final fragment = element.firstFragment;
    final source = fragment.libraryFragment.source;
    _depth++;
    if (source == context.unit.declaredFragment?.source) {
      _enclosingExecutable(context.unit.nodeCovering(offset: fragment.offset))?.accept(this);
    } else if (_parsedProjectUnit(source.uri, source.fullName, () => source.contents.data)
        case final unit?) {
      _enclosingExecutable(unit.nodeCovering(offset: fragment.offset))
          ?.accept(_ParsedWorkFinder(this, element));
    }
    _depth--;
  }

  /// The parsed unit of a callee file in this project. SDK and package
  /// callees are judged by their resolved signature. A file that owns a
  /// debounce mechanism is trusted, as [_fileHasDebounce] trusts the widget
  /// file: debouncing in the notifier is the documented fix.
  CompilationUnit? _parsedProjectUnit(Uri uri, String path, String Function() content) {
    final current = context.unit.declaredFragment?.source.uri;
    final isProject = switch ((uri.scheme, current?.scheme)) {
      ('package', 'package') => uri.pathSegments.first == current?.pathSegments.first,
      ('file', 'file') => true,
      _ => false,
    };
    if (!isProject) return null;
    return _parsed.putIfAbsent(path, () {
      final text = content();
      if (_sourceHasDebounce(SourceScannerSource(text))) return null;
      return parseString(content: text, throwIfDiagnostics: false).unit;
    });
  }
}

/// Walks a callee declaration parsed from another project file (#37). The
/// parse is unresolved, so names are typed through the callee's element
/// model: locals and parameters, members of the enclosing type, extensions
/// and the library scope. A call that cannot be typed is unresolved and
/// counts as work.
final class _ParsedWorkFinder extends RecursiveAstVisitor<void> {
  _ParsedWorkFinder(this.finder, ExecutableElement callee)
    : fragment = callee.firstFragment.libraryFragment,
      enclosing = callee.enclosingElement,
      thisType = switch (callee.enclosingElement) {
        InterfaceElement(:final thisType) => thisType,
        ExtensionElement(:final extendedType) => extendedType,
        _ => null,
      } {
    for (final parameter in callee.formalParameters) {
      if (parameter.name case final name?) locals[name] = parameter.type;
    }
  }

  final _AsyncWorkFinder finder;
  final LibraryFragment fragment;
  final Element? enclosing;
  final DartType? thisType;
  final locals = <String, DartType?>{};
  final localFunctions = <String>{};

  LibraryElement get library => fragment.element;

  @override
  void visitAwaitExpression(AwaitExpression node) => finder.found = true;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (finder.found) return;
    final target = node.realTarget;
    final name = node.methodName.name;
    if (target != null || !localFunctions.contains(name)) {
      _check(_resolveCallee(target, name));
    }
    node.target?.accept(this);
    node.argumentList.accept(this);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    _check(_typeOf(node.function));
    super.visitFunctionExpressionInvocation(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final constructorName = node.constructorName;
    final named = constructorName.type;
    final name = constructorName.name?.name;
    final constructor = switch ((_typeOfAnnotation(named), named.importPrefix)) {
      (InterfaceType(:final element), _) =>
        name == null ? element.unnamedConstructor : element.getNamedConstructor(name),
      (_, final prefix?) when name == null => switch (_lookup(prefix.name.lexeme)) {
        final InterfaceElement type => type.getNamedConstructor(named.name.lexeme),
        _ => null,
      },
      _ => null,
    };
    _check(constructor);
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    final setter = switch (node.leftHandSide) {
      SimpleIdentifier(:final name) when !locals.containsKey(name) =>
        _setter(thisType, name) ?? fragment.scope.lookup(name).setter,
      PrefixedIdentifier(:final prefix, :final identifier) => _setter(
        _typeOf(prefix),
        identifier.name,
      ),
      PropertyAccess(:final realTarget, :final propertyName) => _setter(
        _typeOf(realTarget),
        propertyName.name,
      ),
      _ => null,
    };
    if (setter is SetterElement && !setter.isOriginVariable) finder._follow(setter);
    super.visitAssignmentExpression(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) => _followGetter(_resolveName(node.name));

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    node.prefix.accept(this);
    _followGetter(_resolveMember(node.prefix, node.identifier.name));
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    node.target?.accept(this);
    _followGetter(_resolveMember(node.realTarget, node.propertyName.name));
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    super.visitVariableDeclaration(node);
    final declared = switch (node.parent) {
      VariableDeclarationList(:final type?) => type,
      _ => null,
    };
    locals[node.name.lexeme] = declared == null
        ? _typeOf(node.initializer)
        : _typeOfAnnotation(declared);
  }

  @override
  void visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) {
    super.visitForEachPartsWithDeclaration(node);
    final variable = node.loopVariable;
    final iterable = _typeOf(node.iterable);
    locals[variable.name.lexeme] = switch (variable.type) {
      final type? => _typeOfAnnotation(type),
      null when iterable is InterfaceType =>
        iterable.asInstanceOf(library.typeProvider.iterableElement)?.typeArguments.first,
      null => null,
    };
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    for (final parameter in node.parameters?.parameters ?? const <FormalParameter>[]) {
      if (parameter.name case final name?) {
        locals[name.lexeme] = switch (parameter.type) {
          final type? => _typeOfAnnotation(type),
          null => null,
        };
      }
    }
    super.visitFunctionExpression(node);
  }

  @override
  void visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    localFunctions.add(node.functionDeclaration.name.lexeme);
    super.visitFunctionDeclarationStatement(node);
  }

  @override
  void visitCatchClause(CatchClause node) {
    final exceptionType = node.exceptionType;
    if (node.exceptionParameter?.name case final name?) {
      locals[name.lexeme] = exceptionType == null
          ? library.typeProvider.objectType
          : _typeOfAnnotation(exceptionType);
    }
    if (node.stackTraceParameter?.name case final name?) {
      locals[name.lexeme] = library.typeProvider.objectType;
    }
    super.visitCatchClause(node);
  }

  @override
  void visitDeclaredVariablePattern(DeclaredVariablePattern node) {
    locals[node.name.lexeme] = switch (node.type) {
      final type? => _typeOfAnnotation(type),
      null => null,
    };
    super.visitDeclaredVariablePattern(node);
  }

  /// Follows a resolved callee, checks a callable value, or reports an
  /// unresolved call.
  void _check(Object? callee) {
    switch (callee) {
      case InterfaceElement(:final unnamedConstructor?):
        finder._follow(unnamedConstructor);
      case final GetterElement getter:
        _followGetter(getter);
        _checkCallable(getter.returnType);
      case final ExecutableElement executable:
        finder._follow(executable);
      case final DartType type:
        _checkCallable(type);
      case _:
        finder.found = true;
    }
  }

  void _checkCallable(DartType type) {
    if (type is FunctionType) {
      if (_isAsyncType(type.returnType)) finder.found = true;
      return;
    }
    final call = type is InterfaceType ? type.lookUpMethod('call', library) : null;
    if (call == null) {
      finder.found = true;
    } else {
      finder._follow(call);
    }
  }

  void _followGetter(Object? element) {
    if (element is GetterElement && !element.isOriginVariable) finder._follow(element);
  }

  Element? _lookup(String name) => fragment.scope.lookup(name).getter;

  /// An unqualified name: a local, a member of the enclosing type, or a
  /// library-scope declaration. A local of unknown type is `null`.
  Object? _resolveName(String name) {
    if (locals.containsKey(name)) return locals[name];
    return _member(thisType, name) ??
        switch (enclosing) {
          final InstanceElement own => own.getMethod(name) ?? own.getGetter(name),
          _ => null,
        } ??
        _lookup(name);
  }

  /// `target.name`: a static member, an import-prefixed declaration, or an
  /// instance member of the target's type.
  Object? _resolveMember(Expression target, String name) {
    if (target is SuperExpression) return _member(thisType, name, inherited: true);
    switch (_staticTarget(target)) {
      case PrefixElement(:final scope):
        return scope.lookup(name).getter;
      case final InterfaceElement type:
        return type.getNamedConstructor(name) ?? type.getMethod(name) ?? type.getGetter(name);
      case final InstanceElement type:
        return type.getMethod(name) ?? type.getGetter(name);
    }
    final type = _typeOf(target);
    if (type is FunctionType && name == 'call') return type;
    return _member(type, name);
  }

  Element? _staticTarget(Expression target) {
    switch (target) {
      case SimpleIdentifier(:final name)
          when !locals.containsKey(name) && _member(thisType, name) == null:
        final element = _lookup(name);
        return element is PrefixElement || element is InstanceElement ? element : null;
      case PrefixedIdentifier(:final prefix, :final identifier):
        if (_staticTarget(prefix) case PrefixElement(:final scope)) {
          final element = scope.lookup(identifier.name).getter;
          return element is InstanceElement ? element : null;
        }
    }
    return null;
  }

  Object? _member(DartType? type, String name, {bool inherited = false}) {
    if (type is InterfaceType) {
      final member =
          type.lookUpMethod(name, library, inherited: inherited) ??
          type.lookUpGetter(name, library, inherited: inherited);
      if (member != null) return member;
    }
    if (type == null) return null;
    for (final extension in fragment.accessibleExtensions) {
      final member = extension.getMethod(name) ?? extension.getGetter(name);
      if (member != null && _isOn(type, extension.extendedType)) return member;
    }
    return null;
  }

  bool _isOn(DartType type, DartType extended) => switch (extended) {
    TypeParameterType() => true,
    InterfaceType(:final element) =>
      type is InterfaceType &&
          (type.element == element || type.allSupertypes.any((s) => s.element == element)),
    _ => false,
  };

  SetterElement? _setter(DartType? type, String name) =>
      type is InterfaceType ? type.lookUpSetter(name, library) : null;

  DartType? _typeOf(Expression? expression) {
    final type = switch (expression) {
      SimpleIdentifier(:final name) => _valueType(_resolveName(name)),
      PrefixedIdentifier(:final prefix, :final identifier) => _valueType(
        _resolveMember(prefix, identifier.name),
      ),
      PropertyAccess(:final realTarget, :final propertyName) => _valueType(
        _resolveMember(realTarget, propertyName.name),
      ),
      MethodInvocation(:final realTarget, :final methodName) => _returnType(
        _resolveCallee(realTarget, methodName.name),
      ),
      InstanceCreationExpression(:final constructorName) => _typeOfAnnotation(constructorName.type),
      AsExpression(:final type) => _typeOfAnnotation(type),
      ThisExpression() => thisType,
      final Expression other => _wrappedOrLiteralType(other),
      null => null,
    };
    return type is TypeParameterType ? null : type;
  }

  DartType? _wrappedOrLiteralType(Expression expression) {
    final types = library.typeProvider;
    return switch (expression) {
      ParenthesizedExpression(:final expression) => _typeOf(expression),
      PostfixExpression(:final operand) => _typeOf(operand),
      CascadeExpression(:final target) => _typeOf(target),
      StringLiteral() => types.stringType,
      IntegerLiteral() => types.intType,
      DoubleLiteral() => types.doubleType,
      BooleanLiteral() => types.boolType,
      _ => null,
    };
  }

  Object? _resolveCallee(Expression? target, String name) =>
      target == null ? _resolveName(name) : _resolveMember(target, name);

  DartType? _valueType(Object? element) => switch (element) {
    final DartType type => type,
    GetterElement(:final returnType) => returnType,
    ExecutableElement(:final type) => type,
    _ => null,
  };

  DartType? _returnType(Object? callee) => switch (callee) {
    InterfaceElement(:final thisType) => thisType,
    GetterElement(:final returnType) => _callReturnType(returnType),
    ExecutableElement(:final returnType) => returnType,
    final DartType type => _callReturnType(type),
    _ => null,
  };

  DartType? _callReturnType(DartType type) => switch (type) {
    FunctionType(:final returnType) => returnType,
    InterfaceType() => type.lookUpMethod('call', library)?.returnType,
    _ => null,
  };

  DartType? _typeOfAnnotation(TypeAnnotation annotation) {
    if (annotation is! NamedType) return null;
    final prefix = annotation.importPrefix?.name.lexeme;
    final scope = prefix == null
        ? fragment.scope
        : switch (_lookup(prefix)) {
            PrefixElement(:final scope) => scope,
            _ => null,
          };
    final element = scope?.lookup(annotation.name.lexeme).getter;
    if (element is! InterfaceElement) return null;
    final dynamicType = library.typeProvider.dynamicType;
    final arguments = [
      for (final argument in annotation.typeArguments?.arguments ?? const <TypeAnnotation>[])
        _typeOfAnnotation(argument) ?? dynamicType,
    ];
    return element.instantiate(
      typeArguments: arguments.length == element.typeParameters.length
          ? arguments
          : [for (final _ in element.typeParameters) dynamicType],
      nullabilitySuffix: annotation.question == null
          ? NullabilitySuffix.none
          : NullabilitySuffix.question,
    );
  }
}

bool _isAsyncType(DartType? type) =>
    type != null && (type.isDartAsyncFuture || type.isDartAsyncFutureOr || type.isDartAsyncStream);

AstNode? _enclosingExecutable(AstNode? node) {
  while (node != null &&
      node is! MethodDeclaration &&
      node is! ConstructorDeclaration &&
      node is! FunctionDeclaration) {
    node = node.parent;
  }
  return node;
}

bool _fileHasDebounce(SourceScannerContext context) => _sourceHasDebounce(context.source);

bool _sourceHasDebounce(SourceScannerSource source) {
  for (var i = 0; i < source.length; i++) {
    if (_debounceMechanism.hasMatch(source.masked[i])) return true;
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
