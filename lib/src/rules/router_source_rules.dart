import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/rules/source_scanner_rule.dart';

final List<ScannerRule> routerSourceRules = [
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
            r'^\s*(?:bool\s+popIfCan|void\s+popOrGo)\s*(?:<[^>]+>)?\s*\(',
          ).firstMatch(line);
          if (fallbackHelperDeclaration != null) continue;

          final helperThisCall = RegExp(
            r'\b(?:popIfCan|popOrGo)\s*(?:<[^>]+>)?\s*\(\s*this\b',
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
          r'(?:_?AppNavigationCoordinator|AppNavigation|[A-Z]\w*NavigationCoordinator)\b',
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
        if (!window.contains('appNavigationCoordinatorProvider')) continue;
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

({RegExpMatch match, int column})? _windowMatchStartingOnLine(
  SourceScannerContext context,
  int lineIndex,
  RegExp pattern, {
  int maxLines = 6,
}) {
  final end = lineIndex + maxLines > context.source.length
      ? context.source.length
      : lineIndex + maxLines;
  final window = context.source.masked.sublist(lineIndex, end).join('\n');
  final match = pattern.firstMatch(window);
  if (match == null) return null;
  final beforeMatch = window.substring(0, match.start);
  if (beforeMatch.contains('\n')) return null;
  return (match: match, column: beforeMatch.length);
}

int? _contextExtensionEndLine(SourceScannerContext context, int startLine) {
  final firstLine = context.source.masked[startLine];
  if (!RegExp(r'^\s*extension\b').hasMatch(firstLine)) return null;

  final signature = StringBuffer(firstLine);
  var lineIndex = startLine;
  var foundOpenBrace = firstLine.contains('{');
  while (!foundOpenBrace && lineIndex + 1 < context.source.length && lineIndex - startLine < 8) {
    lineIndex++;
    final line = context.source.masked[lineIndex];
    signature.write(' $line');
    foundOpenBrace = line.contains('{');
  }
  if (!foundOpenBrace) return null;

  final isContextExtension = RegExp(
    r'\bon\s+(?:[A-Za-z_]\w*\.)?BuildContext\??\b',
  ).hasMatch(signature.toString());
  if (!isContextExtension) return null;

  return _blockEndLine(context.source.masked, startLine);
}

bool _isGenericContextFallbackRouteCall(SourceScannerContext context, int lineIndex) {
  final line = context.source.masked[lineIndex];
  final fallbackRouteCall = RegExp(
    r'\bfallbackRoute\s*\.\s*go\s*(?:<[^>]+>)?\s*\(\s*this\b',
  ).firstMatch(line);
  if (fallbackRouteCall == null) return false;

  for (var i = lineIndex; i >= 0 && lineIndex - i <= 24; i--) {
    final candidate = context.source.masked[i];
    if (RegExp(r'^\s*void\s+popOrGo\s*(?:<[^>]+>)?\s*\(').hasMatch(candidate)) {
      return true;
    }
    if (RegExp(r'^\s*extension\b').hasMatch(candidate)) return false;
    if (RegExp(
      r'^\s*(?:Future(?:<[^>]+>)?|void|bool|[A-Za-z_]\w*)\s+'
      r'[A-Za-z_]\w*\s*(?:<[^>]+>)?\s*\(',
    ).hasMatch(candidate)) {
      return false;
    }
  }

  return false;
}

int _blockEndLine(List<String> lines, int startLine) {
  var depth = 0;
  var sawOpenBrace = false;

  for (var i = startLine; i < lines.length; i++) {
    final line = lines[i];
    for (var j = 0; j < line.length; j++) {
      final char = line.codeUnitAt(j);
      if (char == 123) {
        depth++;
        sawOpenBrace = true;
      } else if (char == 125 && sawOpenBrace) {
        depth--;
        if (depth <= 0) return i;
      }
    }
  }

  return lines.length;
}

int? _directRouteNavigationColumn(SourceScannerContext context, int lineIndex) {
  final publicCoordinatorStaticCallPattern = RegExp(
    r'\bAppNavigationCoordinator\s*\.\s*\w+\s*(?:<[^>]+>)?\s*\(',
  );
  final publicCoordinatorStaticCall = _windowMatchStartingOnLine(
    context,
    lineIndex,
    publicCoordinatorStaticCallPattern,
    maxLines: 4,
  );
  if (publicCoordinatorStaticCall != null) return publicCoordinatorStaticCall.column;

  final contextNavigation = RegExp(
    r'\bcontext\s*\.\s*(?:go|push|replace|pushReplacement|goNamed|pushNamed|replaceNamed)\s*'
    r'(?:<[^>]+>)?\s*\(',
  );
  final contextNavigationCall = _windowMatchStartingOnLine(
    context,
    lineIndex,
    contextNavigation,
    maxLines: 4,
  );
  if (contextNavigationCall != null) return contextNavigationCall.column;

  final contextConvenienceNavigation = RegExp(
    r'\bcontext\s*\.\s*(?:go|push|replace|pushReplacement)[A-Z]\w*\s*'
    r'(?:<[^>]+>)?\s*\(',
  );
  final contextConvenienceNavigationCall = _windowMatchStartingOnLine(
    context,
    lineIndex,
    contextConvenienceNavigation,
    maxLines: 4,
  );
  if (contextConvenienceNavigationCall != null) {
    return contextConvenienceNavigationCall.column;
  }

  final routerVariableNavigation = RegExp(
    r'\b(?:_?router|[A-Za-z_]\w*Router\w*)\s*\.\s*'
    r'(?:go|push|replace|pushReplacement|goNamed|pushNamed|replaceNamed)\s*'
    r'(?:<[^>]+>)?\s*\(',
  );
  final routerVariableNavigationCall = _windowMatchStartingOnLine(
    context,
    lineIndex,
    routerVariableNavigation,
    maxLines: 4,
  );
  if (routerVariableNavigationCall != null) return routerVariableNavigationCall.column;

  final routerConvenienceNavigation = RegExp(
    r'\b(?:_?router|[A-Za-z_]\w*Router\w*)\s*\.\s*'
    r'(?:go|push|replace|pushReplacement)[A-Z]\w*\s*'
    r'(?:<[^>]+>)?\s*\(',
  );
  final routerConvenienceNavigationCall = _windowMatchStartingOnLine(
    context,
    lineIndex,
    routerConvenienceNavigation,
    maxLines: 4,
  );
  if (routerConvenienceNavigationCall != null) {
    return routerConvenienceNavigationCall.column;
  }

  final navigatorNavigation = RegExp(
    r'\bNavigator\s*(?:\.\s*of\s*\([^)]*\)\s*)?\.\s*'
    r'(?:push|pushReplacement|pushAndRemoveUntil|pushNamed|pushReplacementNamed|'
    r'restorablePush|restorablePushNamed)\s*'
    r'(?:<[^>]+>)?\s*\(',
  );
  final navigatorNavigationCall = _windowMatchStartingOnLine(
    context,
    lineIndex,
    navigatorNavigation,
    maxLines: 4,
  );
  if (navigatorNavigationCall != null) return navigatorNavigationCall.column;

  return null;
}

bool _isRouterBoundaryPath(String path) =>
    path.startsWith('lib/core/router/') ||
    path.startsWith('lib/presentation/router/') ||
    path.startsWith('lib/presentation/navigation/') ||
    path == 'test/helpers/router_test_utils.dart';

int? _modalCoordinatorAbstractionColumn(SourceScannerContext context, int lineIndex) {
  final line = context.source.masked[lineIndex];
  final staleSymbol = RegExp(
    r'\b(?:AppModalRoute|AppModalController|AppModalPresentation|'
    r'appNavigationCoordinatorProvider)\b',
  ).firstMatch(line);
  if (staleSymbol != null) return staleSymbol.start;

  final appNavigationInterface = RegExp(
    r'\b(?:abstract\s+interface\s+class|abstract\s+class|class)\s+AppNavigation\b',
  ).firstMatch(line);
  if (appNavigationInterface != null) return appNavigationInterface.start;

  final coordinatorModalCall = RegExp(
    r'\.\s*(?:present|showAppBottomSheet|showScrollableBottomSheet|'
    r'showDialogBottomSheet|showBlurredDialog)\s*(?:<[^>]+>)?\s*\(',
  ).firstMatch(line);
  if (coordinatorModalCall == null) return null;

  final start = lineIndex - 8 < 0 ? 0 : lineIndex - 8;
  final end = (lineIndex + 2).clamp(0, context.source.length);
  final window = context.source.masked.sublist(start, end).join('\n');
  if (window.contains('appNavigationCoordinatorProvider') ||
      RegExp(r'\bAppNavigation\b').hasMatch(window)) {
    return coordinatorModalCall.start;
  }
  return null;
}

int? _routerExtraColumn(SourceScannerContext context, int lineIndex) {
  final line = context.source.masked[lineIndex];

  final typedRouteExtraColumn = line.indexOf(r'$extra');
  if (typedRouteExtraColumn >= 0) {
    return typedRouteExtraColumn;
  }

  final stateExtra = RegExp(
    r'\b(?:state|GoRouterState\s*\.\s*of\s*\([^)]*\))\s*\.\s*extra\b',
  ).firstMatch(line);
  if (stateExtra != null) {
    return stateExtra.start;
  }

  final extraArgument = RegExp(r'\bextra\s*:').firstMatch(line);
  if (extraArgument != null && _nearGoRouterNavigationCall(context, lineIndex)) {
    return extraArgument.start;
  }

  return null;
}

bool _nearGoRouterNavigationCall(SourceScannerContext context, int lineIndex) {
  final start = lineIndex - 8 < 0 ? 0 : lineIndex - 8;
  final window = context.source.masked.sublist(start, lineIndex + 1).join('\n');
  final contextNavigation = RegExp(
    r'\b(?:context|router)\s*\.\s*(?:go|push|replace|pushReplacement|goNamed|pushNamed|replaceNamed)\s*(?:<[^>]+>)?\s*\(',
  );
  final goRouterNavigation = RegExp(
    r'\bGoRouter\s*\.\s*of\s*\([^)]*\)\s*\.\s*(?:go|push|replace|pushReplacement|goNamed|pushNamed|replaceNamed)\s*(?:<[^>]+>)?\s*\(',
  );
  return contextNavigation.hasMatch(window) || goRouterNavigation.hasMatch(window);
}
