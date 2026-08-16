import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/rules/source_scanner_rule.dart';
part 'router_source_rules/router_source_rules_part_01.dart';

final List<ScannerRule> routerSourceRules = [..._routerSourceRulesPart1];

final _popFallbackHelperDeclaration = RegExp(
  r'^\s*(?:bool|void|Future\s*<\s*void\s*>)\s+pop[A-Z]\w*\s*(?:<[^>]+>)?\s*\(',
);

final _contextMountedReturnFalseGuard = RegExp(
  r'\bif\s*\(\s*!\s*(?:(?:this\.)?mounted|[A-Za-z_]\w*\.mounted)\s*\)\s*return\s+false\s*;',
);
final _initialSyncStatusSyncing = RegExp(r'\b[A-Za-z_]\w*SyncStatus\s*\.\s*syncing\b');

bool _popFallbackBodyLooksLikeHelper(String body) {
  if (!RegExp(r'\bcanPop\s*\(').hasMatch(body)) return false;
  if (!RegExp(r'\b(?:pop|maybePop)\s*(?:<[^>]+>)?\s*\(').hasMatch(body)) return false;
  return RegExp(r'\b(?:go|push|replace|pushReplacement)\s*(?:<[^>]+>)?\s*\(').hasMatch(body) ||
      RegExp(r'\breturn\s+false\b').hasMatch(body);
}

bool _popFallbackHasRequiredSafetyChecks(String body) {
  return _contextMountedReturnFalseGuard.hasMatch(body) &&
      _hasNavigatorStackCheck(body, rootNavigator: true) &&
      _hasNavigatorStackCheck(body, rootNavigator: false);
}

bool _hasNavigatorStackCheck(String body, {required bool rootNavigator}) {
  final lines = body.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (!_isNavigatorLookup(line, rootNavigator: rootNavigator)) continue;
    final end = i + 5 > lines.length ? lines.length : i + 5;
    final window = lines.sublist(i, end).join('\n');
    if (RegExp(r'\.canPop\s*\(').hasMatch(window)) return true;
  }
  return false;
}

bool _isNavigatorLookup(String line, {required bool rootNavigator}) {
  if (!RegExp(r'\bNavigator\s*\.\s*(?:maybeOf|of)\s*\(').hasMatch(line)) return false;
  final isRoot = RegExp(r'\brootNavigator\s*:\s*true\b').hasMatch(line);
  return rootNavigator ? isRoot : !isRoot;
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

  int? declarationLine;
  for (var i = lineIndex; i >= 0 && lineIndex - i <= 24; i--) {
    final candidate = context.source.masked[i];
    if (RegExp(r'^\s*void\s+pop[A-Z]\w*\s*(?:<[^>]+>)?\s*\(').hasMatch(candidate)) {
      declarationLine = i;
      break;
    }
    if (RegExp(r'^\s*extension\b').hasMatch(candidate)) return false;
    if (RegExp(
      r'^\s*(?:Future(?:<[^>]+>)?|void|bool|[A-Za-z_]\w*)\s+'
      r'[A-Za-z_]\w*\s*(?:<[^>]+>)?\s*\(',
    ).hasMatch(candidate)) {
      return false;
    }
  }

  if (declarationLine == null) return false;
  final helperEnd = _blockEndLine(context.source.masked, declarationLine);
  if (helperEnd <= declarationLine || lineIndex > helperEnd) return false;
  final body = context.source.masked.sublist(declarationLine, helperEnd + 1).join('\n');
  return RegExp(r'\bpopIfCan\s*(?:<[^>]+>)?\s*\(').hasMatch(body);
}

int _blockEndLine(List<String> lines, int startLine) {
  final state = _BlockBraceState();
  for (var i = startLine; i < lines.length; i++) {
    if (_scanBlockBraces(state, lines[i])) return i;
  }
  return lines.length;
}

final class _BlockBraceState {
  int depth = 0;
  bool sawOpenBrace = false;
}

bool _scanBlockBraces(_BlockBraceState state, String line) {
  for (var column = 0; column < line.length; column++) {
    final char = line.codeUnitAt(column);
    if (char == 123) {
      state.depth++;
      state.sawOpenBrace = true;
    } else if (char == 125 && state.sawOpenBrace) {
      state.depth--;
      if (state.depth <= 0) return true;
    }
  }
  return false;
}

int? _splashInitialSyncGateColumn(SourceScannerContext context, int lineIndex) {
  if (context.isTestFile) return null;
  if (!_isRouterRedirectContext(context)) return null;

  final line = context.source.masked[lineIndex];
  final match = _initialSyncStatusSyncing.firstMatch(line);
  if (match == null) return null;

  final window = _routerWindow(context, lineIndex, before: 8, after: 8).toLowerCase();
  if (!window.contains('splash')) return null;
  if (!RegExp(
    r'\bredirect\b|\bgorouter\b|\bcurrent(?:path|location)\b|location\b',
  ).hasMatch(window)) {
    return null;
  }

  return match.start;
}

bool _isRouterRedirectContext(SourceScannerContext context) {
  if (_isRouterBoundaryPath(context.path)) return true;
  final source = context.source.masked.join('\n');
  return RegExp(r'\bGoRouter\b|\bresolve[A-Za-z0-9_]*Redirect\b').hasMatch(source);
}

String _routerWindow(
  SourceScannerContext context,
  int lineIndex, {
  required int before,
  required int after,
}) {
  final start = lineIndex - before < 0 ? 0 : lineIndex - before;
  final end = lineIndex + after >= context.source.length
      ? context.source.length - 1
      : lineIndex + after;
  return context.source.masked.sublist(start, end + 1).join('\n');
}

int? _directRouteNavigationColumn(SourceScannerContext context, int lineIndex) {
  final publicCoordinatorStaticCallPattern = RegExp(
    r'\b[A-Z]\w*NavigationCoordinator\s*\.\s*\w+\s*(?:<[^>]+>)?\s*\(',
  );
  final publicCoordinatorStaticCall = sourceWindowMatch(
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
  final contextNavigationCall = sourceWindowMatch(
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
  final contextConvenienceNavigationCall = sourceWindowMatch(
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
  final routerVariableNavigationCall = sourceWindowMatch(
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
  final routerConvenienceNavigationCall = sourceWindowMatch(
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
  final navigatorNavigationCall = sourceWindowMatch(
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
    r'\b(?:[A-Z]\w*ModalRoute|[A-Z]\w*ModalController|'
    r'[A-Z]\w*ModalPresentation|[A-Za-z_]\w*NavigationCoordinatorProvider)\b',
  ).firstMatch(line);
  if (staleSymbol != null) return staleSymbol.start;

  final navigationInterface = RegExp(
    r'\b(?:abstract\s+interface\s+class|abstract\s+class|class)\s+[A-Z]\w*Navigation\b',
  ).firstMatch(line);
  if (navigationInterface != null) return navigationInterface.start;

  final coordinatorModalCall = RegExp(
    r'\.\s*(?:present|show[A-Z]\w*(?:BottomSheet|Sheet|Dialog))\s*(?:<[^>]+>)?\s*\(',
  ).firstMatch(line);
  if (coordinatorModalCall == null) return null;

  final start = lineIndex - 8 < 0 ? 0 : lineIndex - 8;
  final end = (lineIndex + 2).clamp(0, context.source.length);
  final window = context.source.masked.sublist(start, end).join('\n');
  if (RegExp(r'\b[A-Za-z_]\w*NavigationCoordinatorProvider\b').hasMatch(window) ||
      RegExp(r'\b[A-Z]\w*Navigation\b').hasMatch(window)) {
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
