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
      correctionMessage: 'Wrap the `ref.read(...notifier).save*(...)` call in `if (amount > 0 || count > 0)` (or equivalent) so empty submissions cannot persist.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags `ref.read(...notifier).save*(amount: .., count: ..)` (and similar numeric named-args such as `duration`, `distance`, `weight`, `size`, `total`) without a `> 0` / `isNotEmpty` guard in the same method body.',
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
      severity: DiagnosticSeverity.WARNING,
    ),
    description: 'Flags awaited work, HTTP calls and asynchronous or unresolved notifier calls in TextField/TextFormField callbacks without debounce. Resolved synchronous void updates are not assumed to start async work.',
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
      severity: DiagnosticSeverity.WARNING,
    ),
    description: 'Flags Slider/RangeSlider/CupertinoSlider callbacks with asynchronous or unresolved notifier calls, HTTP calls or awaited work without debounce.',
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
      severity: DiagnosticSeverity.WARNING,
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
      severity: DiagnosticSeverity.WARNING,
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

bool _onChangedHasWork(SourceScannerContext context, int lineIndex, int column) {
  final callback = _onChangedCallback(context, context.source.lineOffsets[lineIndex] + column);
  if (callback == null) return false;
  final startLine = context.unit.lineInfo.getLocation(callback.offset).lineNumber - 1;
  final endLine = context.unit.lineInfo.getLocation(callback.end).lineNumber - 1;
  final start = callback.offset - context.source.lineOffsets[startLine];
  final segment = context.source.masked
      .sublist(startLine, endLine + 1)
      .join('\n')
      .substring(start, start + callback.length);
  for (final work in _expensiveOnChangedWork.allMatches(segment)) {
    if (!work.group(0)!.contains('notifier') ||
        !_isSimpleSynchronousStateUpdate(context, callback.offset + work.end - 1)) {
      return true;
    }
  }
  return false;
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

bool _isSimpleSynchronousStateUpdate(SourceScannerContext context, int offset) {
  AstNode? node = context.unit.nodeCovering(offset: offset);
  while (node != null && node is! MethodInvocation) {
    node = node.parent;
  }
  if (node is! MethodInvocation) return false;
  if (!node.argumentList.arguments.every((argument) {
    final value = argument.argumentExpression;
    return value is SimpleIdentifier && value.element is FormalParameterElement ||
        _isPrimitiveLiteral(value);
  })) {
    return false;
  }
  final method = node.methodName.element;
  if (method is! ExecutableElement ||
      method.isAbstract ||
      method.isExternal ||
      !method.fragments.every((fragment) => fragment.isSynchronous) ||
      node.staticType is! VoidType) {
    return false;
  }
  final body = _declaredMethodBody(context, method);
  final declaration = body?.parent;
  if (declaration is! MethodDeclaration) return false;
  final parameters = {
    for (final parameter in declaration.parameters?.parameters ?? <FormalParameter>[])
      parameter.name?.lexeme,
  };
  return switch (body) {
    ExpressionFunctionBody(:final expression) => _isDirectStateAssignment(
      context,
      expression,
      parameters,
    ),
    BlockFunctionBody(:final block) => _isLocalStateUpdate(context, block, parameters),
    _ => false,
  };
}

bool _isLocalStateUpdate(SourceScannerContext context, Block block, Set<String?> parameters) {
  final locals = <String>{};
  for (final statement in block.statements) {
    if (statement is ExpressionStatement &&
        _isDirectStateAssignment(context, statement.expression, parameters)) {
      continue;
    }
    if (statement is VariableDeclarationStatement && statement.variables.isFinal) {
      if (!_recordValidatedLocals(statement.variables, parameters, locals)) return false;
      continue;
    }
    if (statement is IfStatement &&
        statement.elseStatement == null &&
        _isLocalValidation(statement.expression, parameters, locals) &&
        _onlyReturns(statement.thenStatement)) {
      continue;
    }
    return false;
  }
  return true;
}

bool _recordValidatedLocals(
  VariableDeclarationList declaration,
  Set<String?> parameters,
  Set<String> locals,
) {
  for (final variable in declaration.variables) {
    final initializer = variable.initializer;
    if (initializer == null || !_isLocalValidation(initializer, parameters, locals)) return false;
    locals.add(variable.name.lexeme);
  }
  return true;
}

bool _onlyReturns(Statement statement) =>
    statement is ReturnStatement && statement.expression == null ||
    statement is Block && statement.statements.every(_onlyReturns);

bool _isLocalValidation(Expression value, Set<String?> parameters, Set<String> locals) {
  if (value is SimpleIdentifier) {
    return parameters.contains(value.name) || locals.contains(value.name);
  }
  if (value is PrefixedIdentifier) {
    return (value.identifier.name == 'isEmpty' || value.identifier.name == 'isNotEmpty') &&
        value.prefix.staticType?.isDartCoreString == true &&
        _isLocalValidation(value.prefix, parameters, locals);
  }
  if (value is PropertyAccess) {
    return (value.propertyName.name == 'isEmpty' || value.propertyName.name == 'isNotEmpty') &&
        value.target != null &&
        value.target!.staticType?.isDartCoreString == true &&
        _isLocalValidation(value.target!, parameters, locals);
  }
  if (value is PrefixExpression && value.operator.lexeme == '!') {
    return _isLocalValidation(value.operand, parameters, locals);
  }
  return _isPrimitiveLiteral(value);
}

FunctionBody? _declaredMethodBody(SourceScannerContext context, ExecutableElement method) {
  final fragment = method.firstFragment;
  final offset = fragment.nameOffset;
  if (offset == null) return null;
  final source = fragment.libraryFragment.source;
  final unit = source == context.unit.declaredFragment?.source
      ? context.unit
      : parseString(content: source.contents.data, throwIfDiagnostics: false).unit;
  AstNode? declaration = unit.nodeCovering(offset: offset);
  while (declaration != null && declaration is! MethodDeclaration) {
    declaration = declaration.parent;
  }
  return declaration is MethodDeclaration ? declaration.body : null;
}

bool _isDirectStateAssignment(
  SourceScannerContext context,
  Expression expression,
  Set<String?> parameters,
) {
  if (expression is! AssignmentExpression || expression.operator.lexeme != '=') return false;
  final target = expression.leftHandSide;
  final writesState =
      target is SimpleIdentifier && target.name == 'state' ||
      target is PropertyAccess &&
          target.target is ThisExpression &&
          target.propertyName.name == 'state';
  if (!writesState) return false;
  final value = expression.rightHandSide;
  return value is SimpleIdentifier && parameters.contains(value.name) ||
      _isPrimitiveLiteral(value) ||
      _isStateCopyWith(context, value, parameters);
}

bool _isStateCopyWith(SourceScannerContext context, Expression value, Set<String?> parameters) {
  if (value is FunctionExpressionInvocation && value.function is PropertyAccess) {
    final access = value.function as PropertyAccess;
    final target = access.target;
    final getter = access.propertyName.element;
    final stateType = target?.staticType;
    if (target is! SimpleIdentifier ||
        target.name != 'state' ||
        access.propertyName.name != 'copyWith' ||
        getter is! GetterElement ||
        !getter.firstFragment.libraryFragment.source.fullName.endsWith('.freezed.dart') ||
        stateType is! InterfaceType ||
        value.staticType != stateType ||
        !isFreezedInterfaceType(stateType)) {
      return false;
    }
    return value.argumentList.arguments.every(
      (argument) => _isLocalValidation(argument.argumentExpression, parameters, const <String>{}),
    );
  }
  if (value is! MethodInvocation || value.methodName.name != 'copyWith') return false;
  final target = value.target;
  if (target is! SimpleIdentifier || target.name != 'state') return false;
  final method = value.methodName.element;
  if (method is! ExecutableElement ||
      method.isAbstract ||
      method.isExternal ||
      !method.fragments.every((fragment) => fragment.isSynchronous)) {
    return false;
  }
  if (!value.argumentList.arguments.every((argument) {
    final input = argument.argumentExpression;
    return input is SimpleIdentifier && parameters.contains(input.name) ||
        _isPrimitiveLiteral(input);
  })) {
    return false;
  }
  final body = _declaredMethodBody(context, method);
  return body is ExpressionFunctionBody && _isPureStateConstructor(body.expression, parameters);
}

bool _isPureStateConstructor(Expression value, Set<String?> parameters) {
  if (value is! InstanceCreationExpression) return false;
  if (value.constructorName.element?.isConst != true) return false;
  return value.argumentList.arguments.every(
    (argument) => _isPureStateConstructorArgument(argument.argumentExpression, parameters),
  );
}

bool _isPureStateConstructorArgument(Expression value, Set<String?> parameters) {
  if (value is SimpleIdentifier) return parameters.contains(value.name);
  if (value is PropertyAccess) {
    final getter = value.propertyName.element;
    return value.target is ThisExpression &&
        getter is GetterElement &&
        getter.isOriginVariable &&
        getter.variable is FieldElement &&
        !getter.variable.isLate;
  }
  if (value is BinaryExpression && value.operator.lexeme == '??') {
    return _isPureStateConstructorArgument(value.leftOperand, parameters) &&
        _isPureStateConstructorArgument(value.rightOperand, parameters);
  }
  return _isPrimitiveLiteral(value);
}

bool _isPrimitiveLiteral(Expression value) =>
    value is BooleanLiteral ||
    value is IntegerLiteral ||
    value is DoubleLiteral ||
    value is NullLiteral ||
    value is SimpleStringLiteral;

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
