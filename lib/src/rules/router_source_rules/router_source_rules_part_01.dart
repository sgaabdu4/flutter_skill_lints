part of '../router_source_rules.dart';

final List<ScannerRule> _routerSourceRulesPart1 = [
  /// Avoid string route navigation.
  ///
  /// Why: Flags string-based GoRouter navigation. Use typed GoRouter routes.
  scannerRule(
    code: const LintCode(
      'router_string_nav',
      'Avoid string route navigation.',
      correctionMessage: 'Use typed GoRouter routes.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags string-based GoRouter navigation so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      if (context.isTestFile) return;

      for (var i = 0; i < context.source.length; i++) {
        final column = context.stringNavigationColumn(
          context.source.code[i],
          context.source.masked[i],
        );
        if (column != null) {
          reporter.report(context, i, column);
        }
      }
    },
  ),

  /// Do not pop and push in the same synchronous flow.
  ///
  /// Why: Flags synchronous context.pop followed by push navigation. Wait for modal dismissal
  /// before pushing the next route.
  scannerRule(
    code: const LintCode(
      'router_pop_then_push',
      'Do not pop and push in the same synchronous flow.',
      correctionMessage: 'Wait for modal dismissal before pushing the next route.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags synchronous context.pop followed by push navigation so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      final reportedLines = <int>{};
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (RegExp(r'\bcontext\s*\.\s*pop\s*\(').hasMatch(line) && context.near(i, '.push', 4)) {
          reporter.report(context, i, line.indexOf('context'));
          reportedLines.add(i);
        }
      }
      for (final pop in collectNodes<MethodInvocation>(context.unit)) {
        if (!isResolvedNavigationPop(pop)) continue;
        final pushesAfterPop = followingBlockStatements(pop).any(
          (statement) => collectNodes<MethodInvocation>(statement).any(
            (call) => call.methodName.name.startsWith('push') && isResolvedForwardNavigation(call),
          ),
        );
        if (!pushesAfterPop) continue;
        final line = context.unit.lineInfo.getLocation(pop.offset).lineNumber - 1;
        if (reportedLines.add(line)) reporter.reportNode(context, pop);
      }
    },
  ),

  /// BuildContext pop fallback helpers must check Navigator stacks.
  ///
  /// Why: GoRouter `context.canPop()` can disagree with the active root/local
  /// Navigator stack when dialogs, sheets, shell routes, or nested navigators
  /// are involved. A generic `popIfCan` / `popOr...` helper that checks only
  /// GoRouter may fall through to its route fallback while a Navigator route is
  /// still poppable. Check `mounted`, the root Navigator, and the local
  /// Navigator before falling back to typed route navigation.
  scannerRule(
    code: const LintCode(
      'pop_fallback_helper_must_check_navigator_stack',
      'BuildContext pop fallback helper does not check Navigator stacks.',
      correctionMessage: 'Check `mounted`, root `Navigator.maybeOf(...).canPop()`, and local `Navigator.maybeOf(...).canPop()` before fallback navigation.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags BuildContext pop fallback helpers that call canPop/pop without checking mounted plus root/local Navigator stacks first.',
    scan: _scanPopFallbackHelpers,
  ),

  /// Avoid ref.watch in router redirects.
  ///
  /// Why: Flags ref.watch calls inside router redirects. Use a read/listenable bridge for
  /// redirect state.
  scannerRule(
    code: const LintCode(
      'router_redirect_watch',
      'Avoid ref.watch in router redirects.',
      correctionMessage: 'Use a read/listenable bridge for redirect state.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags ref.watch calls inside router redirects so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (context.isRedirectWatch(i)) {
          reporter.report(context, i, line.indexOf('ref'));
        }
      }
    },
  ),

  /// Do not redirect to loading routes while auth/router state is loading.
  ///
  /// Why: Flags redirects to loading routes while auth/router state is loading. Return null
  /// while loading to stay on the current route.
  scannerRule(
    code: const LintCode(
      'router_redirect_loading_bounce',
      'Do not redirect to loading routes while auth/router state is loading.',
      correctionMessage: 'Return null while loading to stay on the current route.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags redirects to loading routes while auth/router state is loading so the Flutter skill violation is shown during analysis.',
    scan: _reportRedirectLoadingBounces,
  ),

  /// Do not hold splash while initial sync runs.
  ///
  /// Why: Initial data sync is a background/domain concern. Once auth and setup
  /// state are known, route to the authenticated shell and let local data hydrate
  /// instead of keeping the user on the cover screen.
  scannerRule(
    code: const LintCode(
      'router_splash_waits_for_initial_sync',
      'Do not hold splash while initial sync runs.',
      correctionMessage: 'Route to the authenticated shell once auth/setup are resolved; keep initial sync in the background.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags splash redirect gates that wait for InitialSyncStatus.syncing so startup stays responsive.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final column = _splashInitialSyncGateColumn(context, i);
        if (column != null) {
          reporter.report(context, i, column);
        }
      }
    },
  ),

  /// Avoid GoRouter.of(context).* navigation.
  ///
  /// Why: Flags `GoRouter.of(context).{go,push,replace,pushReplacement,goNamed,
  /// pushNamed,replaceNamed}` calls. App code should call the generated typed
  /// route helpers (`SomeRoute(...).go(context)` / `.push(context)`) so the
  /// route class stays the navigation SSOT.
  scannerRule(
    code: const LintCode(
      'router_gorouter_of',
      'Avoid GoRouter.of(context) navigation.',
      correctionMessage: 'Call the generated typed route helper instead of GoRouter.of(context).',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags GoRouter.of(context) push/go/replace calls so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      final pattern = RegExp(
        r'\bGoRouter\s*\.\s*of\s*\([^)]*\)\s*\.\s*'
        r'(?:go|push|replace|pushReplacement|goNamed|pushNamed|replaceNamed)\s*'
        r'(?:<[^>]+>)?\s*\(',
      );
      for (var i = 0; i < context.source.length; i++) {
        final match = sourceWindowMatch(context, i, pattern, maxLines: 4);
        if (match != null) {
          reporter.report(context, i, match.column);
        }
      }
    },
  ),

  /// Avoid Navigator push with untyped page routes.
  ///
  /// Why: Flags `Navigator.{push,pushReplacement,pushAndRemoveUntil}` with
  /// `MaterialPageRoute` / `CupertinoPageRoute` / `PageRouteBuilder`. Define a
  /// typed GoRouter route and navigate through the generated route helper.
  scannerRule(
    code: const LintCode(
      'router_untyped_navigator_push',
      'Avoid Navigator push with untyped page routes.',
      correctionMessage: 'Define a @TypedGoRoute and call the generated route .go/.push helper.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags Navigator push with MaterialPageRoute/CupertinoPageRoute/PageRouteBuilder so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      final navigatorCall = RegExp(
        r'\bNavigator\s*\.\s*(?:of\s*\([^)]*\)\s*\.\s*)?'
        r'(?:push|pushReplacement|pushAndRemoveUntil)\s*'
        r'(?:<[^>]+>)?\s*\(',
      );
      final pageRouteCtor = RegExp(
        r'\b(?:MaterialPageRoute|CupertinoPageRoute|PageRouteBuilder)\s*'
        r'(?:<[^>]+>)?\s*\(',
      );
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        final navMatch = navigatorCall.firstMatch(line);
        if (navMatch != null && pageRouteCtor.hasMatch(line)) {
          reporter.report(context, i, navMatch.start);
          continue;
        }
        if (navMatch != null) {
          final start = i + 1;
          final end = (i + 5).clamp(0, context.source.length);
          for (var j = start; j < end; j++) {
            if (pageRouteCtor.hasMatch(context.source.masked[j])) {
              reporter.report(context, i, navMatch.start);
              break;
            }
          }
        }
      }
    },
  ),

  /// Do not add route-specific BuildContext navigation extensions.
  ///
  /// Why: Flags `extension ... on BuildContext` methods that wrap generated
  /// typed routes. Route-specific helpers hide the typed route call site and
  /// create a second route API.
  scannerRule(
    code: const LintCode(
      'router_context_navigation_extension',
      'Do not add route-specific BuildContext navigation extensions.',
      correctionMessage: 'Call the generated typed route helper at the call site.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags route-specific BuildContext navigation extensions so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) => _reportContextNavigationExtensions(reporter, context),
  ),

  /// Use typed route helpers as the navigation API.
  ///
  /// Why: Flags wrapper classes/functions around navigation. Generated typed route
  /// classes are the navigation SSOT.
  scannerRule(
    code: const LintCode(
      'router_navigation_wrapper_api',
      'Use typed route helpers as the navigation API.',
      correctionMessage: 'Use generated typed GoRouter route helpers as the navigation SSOT.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags navigation wrapper APIs so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        final classMatch = RegExp(
          r'\b(?:abstract\s+interface\s+class|abstract\s+class|final\s+class|class)\s+'
          r'_?[A-Z]\w*(?:NavigationCoordinator|Navigation)\b',
        ).firstMatch(line);
        if (classMatch != null) {
          reporter.report(context, i, classMatch.start);
          continue;
        }

        final functionMatch = RegExp(
          r'\b(?:navigateTo|goTo|pushTo|replaceWith)[A-Z]\w*'
          r'(?:Route|Screen|Page)\w*\s*(?:<[^>]+>)?\s*\(',
        ).firstMatch(line);
        if (functionMatch != null) {
          reporter.report(context, i, functionMatch.start);
        }
      }
    },
  ),

  /// Use generated typed routes for page navigation.
  ///
  /// Why: Flags raw context/router/Navigator page navigation. Page navigation
  /// should call generated typed route helpers directly so route params stay
  /// compile-time checked.
  scannerRule(
    code: const LintCode(
      'router_direct_route_call',
      'Use generated typed routes for page navigation.',
      correctionMessage: 'Call SomeRoute(...).go(context) or SomeRoute(...).push(context) instead.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags raw page navigation so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      final reportedLines = <int>{};
      for (var i = 0; i < context.source.length; i++) {
        final column = _directRouteNavigationColumn(context, i);
        if (column != null) {
          reporter.report(context, i, column);
          reportedLines.add(i);
        }
      }
      for (final call in collectNodes<MethodInvocation>(context.unit)) {
        final targetType = call.realTarget?.staticType;
        if (targetType == null || !goRouterChecker.isAssignableFromType(targetType)) continue;
        if (!isResolvedForwardNavigation(call)) continue;
        if (!reportedLines.add(context.unit.lineInfo.getLocation(call.offset).lineNumber - 1)) {
          continue;
        }
        reporter.reportNode(context, call);
      }
    },
  ),

  /// Keep route definitions in the router boundary.
  ///
  /// Why: Flags raw `GoRoute`/shell route definitions outside the router
  /// boundary. App routes should be defined once with typed GoRouter route
  /// classes, and tests should use a shared router fixture helper.
  scannerRule(
    code: const LintCode(
      'router_raw_route_definition',
      'Keep route definitions in the router boundary.',
      correctionMessage: 'Define app routes in lib/core/router with typed GoRouter route classes.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags raw GoRouter route definitions outside the router boundary.',
    scan: (reporter, context) {
      if (_isRouterBoundaryPath(context.path)) return;

      final routeDefinition = RegExp(
        r'\b(?:GoRouter|GoRoute|ShellRoute|StatefulShellRoute)'
        r'(?:\s*(?:<[^>]+>)?|\s*\.\s*\w+)\s*\(',
      );
      for (var i = 0; i < context.source.length; i++) {
        final match = sourceWindowMatch(context, i, routeDefinition, maxLines: 4);
        if (match != null) {
          reporter.report(context, i, match.column);
        }
      }
    },
  ),

  /// Use local modal helpers for dialogs and sheets.
  ///
  /// Why: Flags wrapper APIs around modal presentation. Local dialog and sheet
  /// helpers keep presentation close to the modal and typed page routes keep
  /// page navigation as the SSOT.
  scannerRule(
    code: const LintCode(
      'router_modal_local_helpers',
      'Use local modal helpers for dialogs and sheets.',
      correctionMessage:
          'Use local dialog/sheet helpers for modals and generated typed route helpers for pages.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags modal wrapper APIs so modal helpers stay local and typed page routes stay the SSOT.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final column = _modalCoordinatorAbstractionColumn(context, i);
        if (column != null) {
          reporter.report(context, i, column);
        }
      }
    },
  ),

  /// Keep navigation out of context escape hatches.
  ///
  /// Why: Navigation should stay at the UI event boundary through generated
  /// route helpers or local modal helpers.
  scannerRule(
    code: const LintCode(
      'router_container_navigation_escape',
      'Keep navigation out of context escape hatches.',
      correctionMessage:
          'Call generated typed route helpers or local modal helpers at the UI event boundary.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags container and navigatorKey context navigation escape hatches.',
    scan: (reporter, context) {
      final reportedLines = <int>{};
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        final navigatorContext = RegExp(
          r'\b(?:[A-Za-z_]\w*\s*\.\s*)?routerDelegate\s*\.\s*navigatorKey\s*\.\s*'
          r'currentContext\b|\bnavigatorKey\s*\.\s*currentContext\b',
        ).firstMatch(line);
        if (navigatorContext != null) {
          reporter.report(context, i, navigatorContext.start);
          reportedLines.add(i);
          continue;
        }

        final match = RegExp(r'\bProviderScope\s*\.\s*containerOf\s*\(').firstMatch(line);
        if (match == null) continue;

        final end = (i + 8).clamp(0, context.source.length);
        final window = context.source.masked.sublist(i, end).join('\n');
        if (!RegExp(r'\b[A-Za-z_]\w*NavigationCoordinatorProvider\b').hasMatch(window)) {
          continue;
        }
        reporter.report(context, i, match.start);
      }
      for (final identifier in collectNodes<SimpleIdentifier>(context.unit)) {
        if (identifier.name != 'currentContext') continue;
        final target = _propertyTarget(identifier);
        if (target == null || !_isNavigatorGlobalKey(target.staticType)) continue;
        if (!reportedLines.add(context.unit.lineInfo.getLocation(target.offset).lineNumber - 1)) {
          continue;
        }
        reporter.reportNode(context, target);
      }
    },
  ),

  /// Avoid GoRouter extra for route state.
  ///
  /// Why: Flags typed route `$extra`, GoRouterState.extra reads, and direct navigation
  /// `extra:` payloads. Route state must survive serialization, redirects, reloads, and
  /// modal pops; pass stable IDs or configure an explicit codec instead.
  scannerRule(
    code: const LintCode(
      'router_complex_extra',
      'Avoid GoRouter extra for route state.',
      correctionMessage: 'Pass stable route IDs/path params, or configure and test an explicit GoRouter extraCodec.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags GoRouter extra route state so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      if (context.isTestFile) return;

      for (var i = 0; i < context.source.length; i++) {
        final column = _routerExtraColumn(context, i);
        if (column != null) {
          reporter.report(context, i, column);
        }
      }
    },
  ),
];

/// Reports a route location returned from a branch taken while an enum
/// status is `loading` (or an `isLoading` flag is true).
void _reportRedirectLoadingBounces(ScannerRuleReporter reporter, SourceScannerContext context) {
  for (final node in collectNodes<AstNode>(context.unit)) {
    switch (node) {
      case IfStatement(:final expression, :final thenStatement, caseClause: null)
          when _isLoadingCondition(expression):
        _reportLocationReturns(reporter, context, thenStatement);
      case SwitchStatement(:final members):
        for (final (index, member) in members.indexed) {
          final matchesLoading = switch (member) {
            SwitchPatternCase(:final guardedPattern) => _matchesLoadingConstant(
              guardedPattern.pattern,
            ),
            SwitchCase(:final expression) => _isLoadingEnumReference(expression),
            _ => false,
          };
          if (!matchesLoading) continue;
          final body = members
              .skip(index)
              .map((m) => m.statements)
              .where((s) => s.isNotEmpty)
              .firstOrNull;
          for (final statement in body ?? const <Statement>[]) {
            _reportLocationReturns(reporter, context, statement);
          }
        }
      case SwitchExpressionCase(:final guardedPattern, :final expression)
          when _matchesLoadingConstant(guardedPattern.pattern) && _isRouteLocation(expression):
        reporter.reportNode(context, expression);
      default:
    }
  }
}

void _reportLocationReturns(
  ScannerRuleReporter reporter,
  SourceScannerContext context,
  Statement branch,
) {
  final body = branch.thisOrAncestorOfType<FunctionBody>();
  for (final statement in collectNodes<ReturnStatement>(branch)) {
    if (statement.thisOrAncestorOfType<FunctionBody>() == body &&
        _isRouteLocation(statement.expression)) {
      reporter.reportNode(context, statement);
    }
  }
}

bool _isLoadingCondition(Expression condition) => switch (condition.unParenthesized) {
  BinaryExpression(:final operator, :final leftOperand, :final rightOperand)
      when operator.lexeme == '&&' || operator.lexeme == '||' =>
    _isLoadingCondition(leftOperand) || _isLoadingCondition(rightOperand),
  BinaryExpression(:final operator, :final leftOperand, :final rightOperand)
      when operator.lexeme == '==' =>
    _isLoadingEnumReference(leftOperand) || _isLoadingEnumReference(rightOperand),
  final Expression flag => _isLoadingFlag(flag),
};

bool _matchesLoadingConstant(DartPattern pattern) =>
    collectNodes<ConstantPattern>(pattern)
        .any((constant) => _isLoadingEnumReference(constant.expression));

bool _isLoadingEnumReference(Expression expression) => switch (expression.unParenthesized) {
  PrefixedIdentifier(:final identifier) => _isLoadingEnumConstant(identifier),
  PropertyAccess(:final propertyName) => _isLoadingEnumConstant(propertyName),
  DotShorthandPropertyAccess(:final propertyName) => _isLoadingEnumConstant(propertyName),
  _ => false,
};

bool _isLoadingEnumConstant(SimpleIdentifier identifier) {
  if (identifier.name != 'loading') return false;
  final element = identifier.element;
  final variable = element is PropertyAccessorElement ? element.variable : element;
  return variable is FieldElement && variable.isEnumConstant;
}

bool _isLoadingFlag(Expression expression) {
  final name = switch (expression) {
    SimpleIdentifier(:final name) => name,
    PrefixedIdentifier(:final identifier) => identifier.name,
    PropertyAccess(:final propertyName) => propertyName.name,
    _ => null,
  };
  return name == 'isLoading' && (expression.staticType?.isDartCoreBool ?? false);
}

bool _isRouteLocation(Expression? expression) {
  final value = expression?.unParenthesized;
  if (value is SimpleStringLiteral) return value.value.startsWith('/');
  if (value is ConditionalExpression) {
    return _isRouteLocation(value.thenExpression) || _isRouteLocation(value.elseExpression);
  }
  final (target, name) = switch (value) {
    PropertyAccess(:final realTarget, :final propertyName) => (realTarget, propertyName.name),
    PrefixedIdentifier(:final prefix, :final identifier) => (prefix, identifier.name),
    _ => (null, null),
  };
  final type = target?.staticType;
  return name == 'location' && type != null && goRouteDataChecker.isAssignableFromType(type);
}

void _reportContextNavigationExtensions(
  ScannerRuleReporter reporter,
  SourceScannerContext context,
) {
  for (var lineIndex = 0; lineIndex < context.source.length; lineIndex++) {
    final extensionEnd = _contextExtensionEndLine(context, lineIndex);
    if (extensionEnd == null) continue;
    final end = _navigationExtensionEnd(lineIndex, extensionEnd, context.source.length);
    _reportNavigationExtensionLines(reporter, context, lineIndex + 1, end);
    lineIndex = end;
  }
  for (final extension in context.unit.declarations.whereType<ExtensionDeclaration>()) {
    final extendedType = extension.onClause?.extendedType.type;
    if (extendedType == null || !_buildContextChecker.isExactlyType(extendedType)) continue;
    for (final call in collectNodes<MethodInvocation>(extension)) {
      if (_isStringRouteNavigation(call)) reporter.reportNode(context, call);
    }
  }
}

const _buildContextChecker = TypeChecker.fromName('BuildContext', packageName: 'flutter');

/// Forward navigation that takes a raw location: go_router's `BuildContext`
/// helpers or a `GoRouter` instance, as opposed to a typed `GoRouteData`.
bool _isStringRouteNavigation(MethodInvocation node) {
  if (!isResolvedForwardNavigation(node)) return false;
  final targetType = node.realTarget?.staticType;
  return isGoRouterHelperMember(node.methodName.element) ||
      (targetType != null && goRouterChecker.isExactlyType(targetType));
}

int _navigationExtensionEnd(int start, int extensionEnd, int sourceLength) {
  final safetyEnd = start + 120;
  final safeEnd = safetyEnd < sourceLength ? safetyEnd : sourceLength;
  return extensionEnd < safeEnd ? extensionEnd : safeEnd;
}

void _reportNavigationExtensionLines(
  ScannerRuleReporter reporter,
  SourceScannerContext context,
  int start,
  int end,
) {
  for (var lineIndex = start; lineIndex < end; lineIndex++) {
    final column = _routeSpecificNavigationColumn(context, lineIndex, end);
    if (column != null) reporter.report(context, lineIndex, column);
  }
}

int? _routeSpecificNavigationColumn(SourceScannerContext context, int lineIndex, int end) {
  final line = context.source.masked[lineIndex];
  if (_routeFallbackDeclaration.hasMatch(line)) return null;
  final helperCall = _routeHelperThisCall.firstMatch(line);
  if (helperCall != null) return helperCall.start;
  final variableRouteCall = _variableRouteCall.firstMatch(line);
  if (variableRouteCall != null) {
    return _isGenericContextFallbackRouteCall(context, lineIndex) ? null : variableRouteCall.start;
  }
  final maxLines = end - lineIndex + 1 < 8 ? end - lineIndex + 1 : 8;
  final routeMatch = sourceWindowMatch(context, lineIndex, _typedRouteCall, maxLines: maxLines);
  return routeMatch?.column;
}

final _routeFallbackDeclaration = RegExp(r'^\s*(?:bool|void)\s+pop[A-Z]\w*\s*(?:<[^>]+>)?\s*\(');

final _routeHelperThisCall = RegExp(r'\bpop[A-Z]\w*\s*(?:<[^>]+>)?\s*\(\s*this\b');

final _variableRouteCall = RegExp(
  r'\b[A-Za-z_]\w*(?:Route|RouteData)\w*\s*\.\s*'
  r'(?:go|push|replace|pushReplacement|goRelative|pushRelative)\s*'
  r'(?:<[^>]+>)?\s*\(\s*this\b',
);

final _typedRouteCall = RegExp(
  r'\b(?:const\s+)?[A-Z]\w*(?:Route|RouteData)\s*'
  r'(?:<[^>]+>)?\s*\([\s\S]*?\)\s*\.\s*'
  r'(?:go|push|replace|pushReplacement|goRelative|pushRelative)\s*'
  r'(?:<[^>]+>)?\s*\(',
);

void _scanPopFallbackHelpers(ScannerRuleReporter reporter, SourceScannerContext context) {
  if (context.isTestFile) return;
  for (var lineIndex = 0; lineIndex < context.source.length; lineIndex++) {
    final extensionEnd = _contextExtensionEndLine(context, lineIndex);
    if (extensionEnd == null) continue;
    _reportPopFallbackHelpersInExtension(reporter, context, lineIndex, extensionEnd);
    lineIndex = extensionEnd;
  }
}

void _reportPopFallbackHelpersInExtension(
  ScannerRuleReporter reporter,
  SourceScannerContext context,
  int extensionStart,
  int extensionEnd,
) {
  for (
    var lineIndex = extensionStart + 1;
    lineIndex < extensionEnd && lineIndex < context.source.length;
    lineIndex++
  ) {
    final declaration = _popFallbackHelperDeclaration.firstMatch(context.source.masked[lineIndex]);
    if (declaration == null) continue;
    _reportPopFallbackHelper(reporter, context, lineIndex, extensionEnd, declaration.start);
  }
}

void _reportPopFallbackHelper(
  ScannerRuleReporter reporter,
  SourceScannerContext context,
  int lineIndex,
  int extensionEnd,
  int column,
) {
  final helperEnd = _blockEndLine(context.source.masked, lineIndex);
  if (helperEnd <= lineIndex || helperEnd > extensionEnd) return;
  final body = context.source.masked.sublist(lineIndex, helperEnd + 1).join('\n');
  if (!_popFallbackBodyLooksLikeHelper(body)) return;
  if (_popFallbackHasRequiredSafetyChecks(body)) return;
  reporter.report(context, lineIndex, column);
}

Expression? _propertyTarget(SimpleIdentifier identifier) => switch (identifier.parent) {
  final PropertyAccess access when access.propertyName == identifier => access.realTarget,
  final PrefixedIdentifier prefixed when prefixed.identifier == identifier => prefixed.prefix,
  _ => null,
};

const _globalKeyChecker = TypeChecker.fromName('GlobalKey', packageName: 'flutter');
const _navigatorStateChecker = TypeChecker.fromName('NavigatorState', packageName: 'flutter');

bool _isNavigatorGlobalKey(DartType? type) {
  if (type is! InterfaceType) return false;
  final key = [
    type,
    ...type.element.allSupertypes,
  ].whereType<InterfaceType>().where((candidate) => _globalKeyChecker.isExactlyType(candidate));
  return key.any(
    (candidate) =>
        candidate.typeArguments.length == 1 &&
        _navigatorStateChecker.isAssignableFromType(candidate.typeArguments.single),
  );
}
