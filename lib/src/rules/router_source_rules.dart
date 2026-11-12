import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';
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

final _returnFalsePattern = RegExp(r'\breturn\s+false\b');

final _pushReplacePushReplacementPattern = RegExp(
  r'\b(?:go|push|replace|pushReplacement)\s*(?:<[^>]+>)?\s*\(',
);

final _popMaybePopPattern = RegExp(r'\b(?:pop|maybePop)\s*(?:<[^>]+>)?\s*\(');

final _canPopPattern = RegExp(r'\bcanPop\s*\(');

bool _popFallbackBodyLooksLikeHelper(String body) {
  if (!_canPopPattern.hasMatch(body)) return false;
  if (!_popMaybePopPattern.hasMatch(body)) return false;
  return _pushReplacePushReplacementPattern.hasMatch(body) || _returnFalsePattern.hasMatch(body);
}

bool _popFallbackHasRequiredSafetyChecks(String body) {
  return _contextMountedReturnFalseGuard.hasMatch(body) &&
      _hasNavigatorStackCheck(body, rootNavigator: true) &&
      _hasNavigatorStackCheck(body, rootNavigator: false);
}

final _canPopHasNavigatorStackCheckPattern = RegExp(r'\.canPop\s*\(');

bool _hasNavigatorStackCheck(String body, {required bool rootNavigator}) {
  final lines = body.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (!_isNavigatorLookup(line, rootNavigator: rootNavigator)) continue;
    final end = i + 5 > lines.length ? lines.length : i + 5;
    final window = lines.sublist(i, end).join('\n');
    if (_canPopHasNavigatorStackCheckPattern.hasMatch(window)) return true;
  }
  return false;
}

final _rootNavigatorTruePattern = RegExp(r'\brootNavigator\s*:\s*true\b');

final _navigatorMaybeOfPattern = RegExp(r'\bNavigator\s*\.\s*(?:maybeOf|of)\s*\(');

bool _isNavigatorLookup(String line, {required bool rootNavigator}) {
  if (!_navigatorMaybeOfPattern.hasMatch(line)) return false;
  final isRoot = _rootNavigatorTruePattern.hasMatch(line);
  return rootNavigator ? isRoot : !isRoot;
}

final _buildContextPattern = RegExp(r'\bon\s+(?:[A-Za-z_]\w*\.)?BuildContext\??\b');

final _extensionPattern = RegExp(r'^\s*extension\b');

int? _contextExtensionEndLine(SourceScannerContext context, int startLine) {
  final firstLine = context.source.masked[startLine];
  if (!_extensionPattern.hasMatch(firstLine)) return null;

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

  final isContextExtension = _buildContextPattern.hasMatch(signature.toString());
  if (!isContextExtension) return null;

  return _blockEndLine(context.source.masked, startLine);
}

final _popIfCanPattern = RegExp(r'\bpopIfCan\s*(?:<[^>]+>)?\s*\(');

final _futureVoidBoolPattern = RegExp(
  r'^\s*(?:Future(?:<[^>]+>)?|void|bool|[A-Za-z_]\w*)\s+'
  r'[A-Za-z_]\w*\s*(?:<[^>]+>)?\s*\(',
);

final _voidPopPattern = RegExp(r'^\s*void\s+pop[A-Z]\w*\s*(?:<[^>]+>)?\s*\(');

final _fallbackRouteThisPattern = RegExp(r'\bfallbackRoute\s*\.\s*go\s*(?:<[^>]+>)?\s*\(\s*this\b');

bool _isGenericContextFallbackRouteCall(SourceScannerContext context, int lineIndex) {
  final line = context.source.masked[lineIndex];
  final fallbackRouteCall = _fallbackRouteThisPattern.firstMatch(line);
  if (fallbackRouteCall == null) return false;

  int? declarationLine;
  for (var i = lineIndex; i >= 0 && lineIndex - i <= 24; i--) {
    final candidate = context.source.masked[i];
    if (_voidPopPattern.hasMatch(candidate)) {
      declarationLine = i;
      break;
    }
    if (_extensionPattern.hasMatch(candidate)) return false;
    if (_futureVoidBoolPattern.hasMatch(candidate)) {
      return false;
    }
  }

  if (declarationLine == null) return false;
  final helperEnd = _blockEndLine(context.source.masked, declarationLine);
  if (helperEnd <= declarationLine || lineIndex > helperEnd) return false;
  final body = context.source.masked.sublist(declarationLine, helperEnd + 1).join('\n');
  return _popIfCanPattern.hasMatch(body);
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

final _redirectGorouterCurrentPattern = RegExp(
  r'\bredirect\b|\bgorouter\b|\bcurrent(?:path|location)\b|location\b',
);

int? _splashInitialSyncGateColumn(SourceScannerContext context, int lineIndex) {
  if (context.isTestFile) return null;
  if (!_isRouterRedirectContext(context)) return null;

  final line = context.source.masked[lineIndex];
  final match = _initialSyncStatusSyncing.firstMatch(line);
  if (match == null) return null;

  final window = _routerWindow(context, lineIndex, before: 8, after: 8).toLowerCase();
  if (!window.contains('splash')) return null;
  if (!_redirectGorouterCurrentPattern.hasMatch(window)) {
    return null;
  }

  return match.start;
}

final _goRouterResolveRedirectPattern = RegExp(r'\bGoRouter\b|\bresolve[A-Za-z0-9_]*Redirect\b');

bool _isRouterRedirectContext(SourceScannerContext context) {
  if (_isRouterBoundaryPath(context.path)) return true;
  final source = context.source.masked.join('\n');
  return _goRouterResolveRedirectPattern.hasMatch(source);
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

final _navigatorPattern = RegExp(
  r'\bNavigator\s*(?:\.\s*of\s*\([^)]*\)\s*)?\.\s*'
  r'(?:push|pushReplacement|pushAndRemoveUntil|pushNamed|pushReplacementNamed|'
  r'restorablePush|restorablePushNamed)\s*'
  r'(?:<[^>]+>)?\s*\(',
);

final _routerConvenienceCallPattern = RegExp(
  r'\b(?:_?router|[A-Za-z_]\w*Router\w*)\s*\.\s*'
  r'(?:go|push|replace|pushReplacement)[A-Z]\w*\s*'
  r'(?:<[^>]+>)?\s*\(',
);

final _routerRouterPattern = RegExp(
  r'\b(?:_?router|[A-Za-z_]\w*Router\w*)\s*\.\s*'
  r'(?:go|push|replace|pushReplacement|goNamed|pushNamed|replaceNamed)\s*'
  r'(?:<[^>]+>)?\s*\(',
);

final _contextConvenienceCallPattern = RegExp(
  r'\bcontext\s*\.\s*(?:go|push|replace|pushReplacement)[A-Z]\w*\s*'
  r'(?:<[^>]+>)?\s*\(',
);

final _contextPushReplacePattern = RegExp(
  r'\bcontext\s*\.\s*(?:go|push|replace|pushReplacement|goNamed|pushNamed|replaceNamed)\s*'
  r'(?:<[^>]+>)?\s*\(',
);

final _navigationCoordinatorPattern = RegExp(
  r'\b[A-Z]\w*NavigationCoordinator\s*\.\s*\w+\s*(?:<[^>]+>)?\s*\(',
);

int? _directRouteNavigationColumn(SourceScannerContext context, int lineIndex) {
  final publicCoordinatorStaticCallPattern = _navigationCoordinatorPattern;
  final publicCoordinatorStaticCall = sourceWindowMatch(
    context,
    lineIndex,
    publicCoordinatorStaticCallPattern,
    maxLines: 4,
  );
  if (publicCoordinatorStaticCall != null) return publicCoordinatorStaticCall.column;

  final contextNavigation = _contextPushReplacePattern;
  final contextNavigationCall = sourceWindowMatch(
    context,
    lineIndex,
    contextNavigation,
    maxLines: 4,
  );
  if (contextNavigationCall != null) return contextNavigationCall.column;

  final contextConvenienceNavigation = _contextConvenienceCallPattern;
  final contextConvenienceNavigationCall = sourceWindowMatch(
    context,
    lineIndex,
    contextConvenienceNavigation,
    maxLines: 4,
  );
  if (contextConvenienceNavigationCall != null) {
    return contextConvenienceNavigationCall.column;
  }

  final routerVariableNavigation = _routerRouterPattern;
  final routerVariableNavigationCall = sourceWindowMatch(
    context,
    lineIndex,
    routerVariableNavigation,
    maxLines: 4,
  );
  if (routerVariableNavigationCall != null) return routerVariableNavigationCall.column;

  final routerConvenienceNavigation = _routerConvenienceCallPattern;
  final routerConvenienceNavigationCall = sourceWindowMatch(
    context,
    lineIndex,
    routerConvenienceNavigation,
    maxLines: 4,
  );
  if (routerConvenienceNavigationCall != null) {
    return routerConvenienceNavigationCall.column;
  }

  final navigatorNavigation = _navigatorPattern;
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

final _navigationPattern = RegExp(r'\b[A-Z]\w*Navigation\b');

final _navigationCoordinatorProviderPattern = RegExp(
  r'\b[A-Za-z_]\w*NavigationCoordinatorProvider\b',
);

final _presentShowBottomSheetPattern = RegExp(
  r'\.\s*(?:present|show[A-Z]\w*(?:BottomSheet|Sheet|Dialog))\s*(?:<[^>]+>)?\s*\(',
);

final _abstractInterfaceClassPattern = RegExp(
  r'\b(?:abstract\s+interface\s+class|abstract\s+class|class)\s+[A-Z]\w*Navigation\b',
);

final _modalRouteModalControllerPattern = RegExp(
  r'\b(?:[A-Z]\w*ModalRoute|[A-Z]\w*ModalController|'
  r'[A-Z]\w*ModalPresentation|[A-Za-z_]\w*NavigationCoordinatorProvider)\b',
);

int? _modalCoordinatorAbstractionColumn(SourceScannerContext context, int lineIndex) {
  final line = context.source.masked[lineIndex];
  final staleSymbol = _modalRouteModalControllerPattern.firstMatch(line);
  if (staleSymbol != null) return staleSymbol.start;

  final navigationInterface = _abstractInterfaceClassPattern.firstMatch(line);
  if (navigationInterface != null) return navigationInterface.start;

  final coordinatorModalCall = _presentShowBottomSheetPattern.firstMatch(line);
  if (coordinatorModalCall == null) return null;

  final start = lineIndex - 8 < 0 ? 0 : lineIndex - 8;
  final end = (lineIndex + 2).clamp(0, context.source.length);
  final window = context.source.masked.sublist(start, end).join('\n');
  if (_navigationCoordinatorProviderPattern.hasMatch(window) ||
      _navigationPattern.hasMatch(window)) {
    return coordinatorModalCall.start;
  }
  return null;
}

final _extraPattern = RegExp(r'\bextra\s*:');

final _stateGoRouterStateExtraPattern = RegExp(
  r'\b(?:state|GoRouterState\s*\.\s*of\s*\([^)]*\))\s*\.\s*extra\b',
);

int? _routerExtraColumn(SourceScannerContext context, int lineIndex) {
  final line = context.source.masked[lineIndex];

  final typedRouteExtraColumn = line.indexOf(r'$extra');
  if (typedRouteExtraColumn >= 0) {
    return typedRouteExtraColumn;
  }

  final stateExtra = _stateGoRouterStateExtraPattern.firstMatch(line);
  if (stateExtra != null) {
    return stateExtra.start;
  }

  final extraArgument = _extraPattern.firstMatch(line);
  if (extraArgument != null && _nearGoRouterNavigationCall(context, lineIndex)) {
    return extraArgument.start;
  }

  return null;
}

final _goRouterPushReplacePattern = RegExp(
  r'\bGoRouter\s*\.\s*of\s*\([^)]*\)\s*\.\s*(?:go|push|replace|pushReplacement|goNamed|pushNamed|replaceNamed)\s*(?:<[^>]+>)?\s*\(',
);

final _contextRouterPushPattern = RegExp(
  r'\b(?:context|router)\s*\.\s*(?:go|push|replace|pushReplacement|goNamed|pushNamed|replaceNamed)\s*(?:<[^>]+>)?\s*\(',
);

bool _nearGoRouterNavigationCall(SourceScannerContext context, int lineIndex) {
  final start = lineIndex - 8 < 0 ? 0 : lineIndex - 8;
  final window = context.source.masked.sublist(start, lineIndex + 1).join('\n');
  final contextNavigation = _contextRouterPushPattern;
  final goRouterNavigation = _goRouterPushReplacePattern;
  return contextNavigation.hasMatch(window) || goRouterNavigation.hasMatch(window);
}
