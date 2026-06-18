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
    description:
        'Flags string-based GoRouter navigation so the Flutter skill violation is shown during analysis.',
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
    description:
        'Flags synchronous context.pop followed by push navigation so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (RegExp(r'\bcontext\s*\.\s*pop\s*\(').hasMatch(line) && context.near(i, '.push', 4)) {
          reporter.report(context, i, line.indexOf('context'));
        }
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
      correctionMessage:
          'Check `mounted`, root `Navigator.maybeOf(...).canPop()`, and local `Navigator.maybeOf(...).canPop()` before fallback navigation.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags BuildContext pop fallback helpers that call canPop/pop without checking mounted plus root/local Navigator stacks first.',
    scan: (reporter, context) {
      if (context.isTestFile) return;
      for (var i = 0; i < context.source.length; i++) {
        final extensionEnd = _contextExtensionEndLine(context, i);
        if (extensionEnd == null) continue;
        for (var j = i + 1; j < extensionEnd && j < context.source.length; j++) {
          final declaration = _popFallbackHelperDeclaration.firstMatch(context.source.masked[j]);
          if (declaration == null) continue;
          final helperEnd = _blockEndLine(context.source.masked, j);
          if (helperEnd <= j || helperEnd > extensionEnd) continue;
          final body = context.source.masked.sublist(j, helperEnd + 1).join('\n');
          if (!_popFallbackBodyLooksLikeHelper(body)) continue;
          if (_popFallbackHasRequiredSafetyChecks(body)) continue;
          reporter.report(context, j, declaration.start);
        }
        i = extensionEnd;
      }
    },
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
    description:
        'Flags ref.watch calls inside router redirects so the Flutter skill violation is shown during analysis.',
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
    description:
        'Flags redirects to loading routes while auth/router state is loading so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        if (context.isRedirectLoadingBounce(i, context.source.code[i])) {
          reporter.report(context, i, 0);
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
    description:
        'Flags GoRouter.of(context) push/go/replace calls so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      final pattern = RegExp(
        r'\bGoRouter\s*\.\s*of\s*\([^)]*\)\s*\.\s*'
        r'(?:go|push|replace|pushReplacement|goNamed|pushNamed|replaceNamed)\s*'
        r'(?:<[^>]+>)?\s*\(',
      );
      for (var i = 0; i < context.source.length; i++) {
        final match = _windowMatchStartingOnLine(context, i, pattern, maxLines: 4);
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
    description:
        'Flags Navigator push with MaterialPageRoute/CupertinoPageRoute/PageRouteBuilder so the Flutter skill violation is shown during analysis.',
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
    description:
        'Flags route-specific BuildContext navigation extensions so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final extensionEnd = _contextExtensionEndLine(context, i);
        if (extensionEnd == null) continue;

        final safetyEnd = (i + 120).clamp(0, context.source.length);
        final end = extensionEnd < safetyEnd ? extensionEnd : safetyEnd;
        for (var j = i + 1; j < end; j++) {
          final line = context.source.masked[j];
          final fallbackHelperDeclaration = RegExp(
            r'^\s*(?:bool|void)\s+pop[A-Z]\w*\s*(?:<[^>]+>)?\s*\(',
          ).firstMatch(line);
          if (fallbackHelperDeclaration != null) continue;

          final helperThisCall = RegExp(
            r'\bpop[A-Z]\w*\s*(?:<[^>]+>)?\s*\(\s*this\b',
          ).firstMatch(line);
          if (helperThisCall != null) {
            reporter.report(context, j, helperThisCall.start);
            continue;
          }

          final variableRouteCall = RegExp(
            r'\b[A-Za-z_]\w*(?:Route|RouteData)\w*\s*\.\s*'
            r'(?:go|push|replace|pushReplacement|goRelative|pushRelative)\s*'
            r'(?:<[^>]+>)?\s*\(\s*this\b',
          ).firstMatch(line);
          if (variableRouteCall != null) {
            if (_isGenericContextFallbackRouteCall(context, j)) continue;
            reporter.report(context, j, variableRouteCall.start);
            continue;
          }

          final maxLines = end - j + 1 < 8 ? end - j + 1 : 8;
          final routeCall = RegExp(
            r'\b(?:const\s+)?[A-Z]\w*(?:Route|RouteData)\s*'
            r'(?:<[^>]+>)?\s*\([\s\S]*?\)\s*\.\s*'
            r'(?:go|push|replace|pushReplacement|goRelative|pushRelative)\s*'
            r'(?:<[^>]+>)?\s*\(',
          );
          final routeMatch = _windowMatchStartingOnLine(context, j, routeCall, maxLines: maxLines);
          if (routeMatch == null) continue;
          reporter.report(context, j, routeMatch.column);
        }

        i = end;
      }
    },
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
      for (var i = 0; i < context.source.length; i++) {
        final column = _directRouteNavigationColumn(context, i);
        if (column != null) {
          reporter.report(context, i, column);
        }
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
        final match = _windowMatchStartingOnLine(context, i, routeDefinition, maxLines: 4);
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
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        final navigatorContext = RegExp(
          r'\b(?:[A-Za-z_]\w*\s*\.\s*)?routerDelegate\s*\.\s*navigatorKey\s*\.\s*'
          r'currentContext\b|\bnavigatorKey\s*\.\s*currentContext\b',
        ).firstMatch(line);
        if (navigatorContext != null) {
          reporter.report(context, i, navigatorContext.start);
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
      correctionMessage:
          'Pass stable route IDs/path params, or configure and test an explicit GoRouter extraCodec.',
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
