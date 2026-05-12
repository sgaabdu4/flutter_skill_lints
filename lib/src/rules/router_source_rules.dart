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
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (context.hasStringNavigation(context.source.code[i], line)) {
          reporter.report(context, i, line.indexOf('context'));
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
  /// pushNamed,replaceNamed}` calls. Typed routes (`go_router_builder`) are the
  /// SSOT — `const FooRoute(...).push<T>(context)` / `.go(context)` keeps
  /// navigation refactor-safe and survives route renames.
  scannerRule(
    code: const LintCode(
      'router_gorouter_of',
      'Avoid GoRouter.of(context) navigation.',
      correctionMessage: 'Use a typed route: const FooRoute(...).push<T>(context) or .go(context).',
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
        final line = context.source.masked[i];
        final match = pattern.firstMatch(line);
        if (match != null) {
          reporter.report(context, i, match.start);
        }
      }
    },
  ),

  /// Avoid Navigator push with untyped page routes.
  ///
  /// Why: Flags `Navigator.{push,pushReplacement,pushAndRemoveUntil}` with
  /// `MaterialPageRoute` / `CupertinoPageRoute` / `PageRouteBuilder`. Use a
  /// typed GoRouter route — `const FooRoute(...).push<T>(context)` —
  /// for refactor-safe, declarative navigation.
  scannerRule(
    code: const LintCode(
      'router_untyped_navigator_push',
      'Avoid Navigator push with untyped page routes.',
      correctionMessage: 'Define a @TypedGoRoute, then call const FooRoute(...).push<T>(context).',
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
