import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/rules/source_scanner_rule.dart';
part 'runtime_bug_source_rules/runtime_bug_source_rules_part_01.dart';
part 'runtime_bug_source_rules/runtime_bug_source_rules_part_02.dart';

final List<ScannerRule> runtimeBugSourceRules = [
  ..._runtimeBugSourceRulesPart1,
  ..._runtimeBugSourceRulesPart2,
];

// ---------------------------------------------------------------------------
// Regexes
// ---------------------------------------------------------------------------

final _saveAllCallStart = RegExp(r'\.\s*saveAll\s*\(');

final _saveAllFromEntity = RegExp(
  r'\.\s*saveAll\s*\([\s\S]*?\.\s*map\s*\([^)]*\.\s*fromEntity\s*\)'
  r'[\s\S]*?\.\s*toList\s*\(\s*\)',
);

final _earlyEmptyReturn = RegExp(
  r'\bif\s*\([^)]*(?:'
  r'\.\s*isEmpty\b|'
  r'!\s*\w+\.\s*isNotEmpty\b|'
  r'\.\s*length\s*(?:==\s*0|<\s*1)\b'
  r')[^)]*\)\s*(?:\{)?\s*return\b',
);

final _dirtyGuardOutsideMethod = RegExp(
  r'\bif\s*\([^)]*(?:'
  r'\bis(?:Dirty|Changed|Modified|Stale)\b|'
  r'\bhas(?:Changes|Updates|Diff|Dirty)\b|'
  r'\.\s*isNotEmpty\b|'
  r'\.\s*length\s*[>!]=?\s*\d+'
  r')',
);

final _persistHelperPattern = RegExp(
  r'\b(?:void|Future\s*<\s*void\s*>)\s+_(?:schedule|persist|enqueue|flush)[A-Z]\w*\s*\(',
);

final _asyncNotifierInitializerMethod = RegExp(
  r'^_(?:init|initialize|restore|load|refresh|sync|hydrate|bootstrap)[A-Z_]?\w*$',
);

final _notifierStateWrite = RegExp(r'\bstate\s*=');

final _staleGuardToken = RegExp(
  r'(?:generation|serial|version|epoch|requestId|requestToken|token|stale|current|isCurrent|activeRequest|currentRequest)',
  caseSensitive: false,
);

final _appwriteExecutionCall = RegExp(r'\b(?:createExecution|[A-Za-z_]\w*Execution)\s*\(');

final _appwriteCreateExecution = RegExp(r'\bcreateExecution\s*\(');

final _functionIdArgument = RegExp(r'\bfunctionId\s*:');

final _xasyncTrue = RegExp(r'\bxasync\s*:\s*true\b');

final _longRunningOperationName = RegExp(
  r'(?:delete|remove|destroy|purge|wipe|cleanup|sync|import|export|migrat|generate|process|archive|restore|backfill|recalculate)',
  caseSensitive: false,
);

final _failureTelemetryCall = RegExp(
  r'\b(?:Crash\s*\.\s*error|Crashlytics\s*\.\s*recordError|FirebaseCrashlytics\s*\.\s*instance\s*\.\s*recordError|Sentry\s*\.\s*captureException|recordError\s*\(|captureException\s*\(|reportError\s*\(|logError\s*\()',
);

final _reconcileCall = RegExp(
  r'\b_?(?:reconcile|verify|confirm|waitFor|poll|exists|getCurrent|getById|reload|refresh)[A-Za-z_]\w*\s*\(',
  caseSensitive: false,
);

final _storageClearCall = RegExp(r'\.\s*clear\s*\(');

final _sentinelStorageToken = RegExp(
  r'(?:migration|schema|version|lastOpened|last_opened|installed|install|firstRun|first_run|device|sentinel)',
  caseSensitive: false,
);

final _storageReadOrGet = RegExp(r'\.\s*(?:read|get)\s*[<(]');

final _storageWriteOrSave = RegExp(r'\.\s*(?:save|put|set|write)\s*[<(]');

void _visitMethodLines(
  SourceScannerContext context,
  ScannerMethodSpan method,
  bool Function(int lineIndex, String line) visitor,
) {
  for (
    var lineIndex = method.start;
    lineIndex <= method.end && lineIndex < context.source.length;
    lineIndex++
  ) {
    if (visitor(lineIndex, context.source.masked[lineIndex])) return;
  }
}

void _visitSaveAllCalls(
  SourceScannerContext context,
  ScannerMethodSpan method,
  void Function(int lineIndex, RegExpMatch match, String window) visitor,
) {
  _visitMethodLines(context, method, (lineIndex, line) {
    final match = _saveAllCallStart.firstMatch(line);
    if (match == null) return false;
    visitor(lineIndex, match, sourceLineWindow(context, lineIndex, method.end, 10));
    return false;
  });
}

final _debounceMechanism = RegExp(
  r'\b(?:Timer\s*\(|Timer\.periodic\s*\(|Future\.delayed\s*\(|Debouncer\b)',
);

final _durationMillisecondsLiteral = RegExp(r'Duration\s*\(\s*milliseconds\s*:\s*(\d+)');

final _durationSecondsLiteral = RegExp(r'Duration\s*\(\s*seconds\s*:\s*(\d+)');

final _userVisibleDelaySignal = RegExp(
  r'debounc|Future\s*(?:<[^>]+>)?\s*\.\s*delayed|Timer\s*\(|transitionDuration|AnimationStyle|duration\s*:',
  caseSensitive: false,
);

final _backgroundDurationExemption = RegExp(
  r'retry|backoff|timeout|poll|ceiling|sync|backfill|rest|reminder|notification|alarm|snooze|cleanup|temp|expiry|expiration|ttl|ticker|periodic|interval|dismiss|snack|toast|overlay|banner',
  caseSensitive: false,
);

final _collectionGetterBlockStart = RegExp(
  r'^\s*(?:Map|List|Set)\s*<[^;]+>\s+get\s+([A-Za-z_]\w*)\s*\{',
);

final _collectionGetterExpression = RegExp(
  r'^\s*(?:Map|List|Set)\s*<[^;]+>\s+get\s+([A-Za-z_]\w*)\s*=>\s*(.+);',
);

final _collectionGetterCache = RegExp(
  r'\b(?:Expando\b|cached\s*!=\s*null|Cache\s*\[|_cache\s*\[|\?\?=)',
);

final _collectionLiteralAllocation = RegExp(r'=\s*(?:<[^;=]+>\s*)?[\{\[]\s*(?:\}|\])');

final _collectionExpressionAllocation = RegExp(
  r'\bfor\s*\(|\.\s*(?:map|where|toList|toSet)\s*\(|[\{\[]\s*for\s*\(',
);

final _byIdFunctionStart = RegExp(
  r'^\s*(?:[A-Za-z_]\w*(?:\s*<[^;]+>)?\??)\s+_?[A-Za-z_]\w*ById\s*\([^)]*\)\s*\{',
);

final _manualIdLoop = RegExp(r'\bfor\s*\([\s\S]*?\.\s*id\s*==');

final _adHocIdIndexLookup = RegExp(
  r'\.\s*indexBy\s*\(\s*'
  r'(?:\([A-Za-z_]\w*\)|[A-Za-z_]\w*)\s*=>\s*[A-Za-z_]\w*\s*\.\s*id\s*'
  r'\)\s*\[',
);

final _linearIdLookupCall = RegExp(r'\.\s*(?:firstWhere|indexWhere)\s*\(');

final _linearIdLookup = RegExp(
  r'\.\s*(?:firstWhere|indexWhere)\s*\(\s*'
  r'(?:\([A-Za-z_]\w*\)|[A-Za-z_]\w*)\s*=>\s*[A-Za-z_]\w*\s*\.\s*id\s*==',
);

final _forEachLoop = RegExp(
  r'\bfor\s*\(\s*(?:final\s+)?(?:[A-Za-z_]\w*\s+)?([A-Za-z_]\w*)\s+in\s+[A-Za-z_]\w*',
);

final _heavyWidgetInit = RegExp(
  r'\b(?:InAppWebView|IOSInAppWebViewWidget|WebViewWidget|YoutubePlayer|VideoPlayer)\s*\(',
);

final _userGateField = RegExp(
  r'\bbool\s+(_\w*(?:User|Tap|Pressed|Activated|Requested|Consented|Opened)\w*)\s*=',
);

final _storageReadCall = RegExp(r'\b(?:_storage\s*\.\s*read|_box\s*\.\s*get)\s*[<(]');

final _memoField = RegExp(
  r'^\s*(?:late\s+)?(?:final\s+)?Map\s*<\s*String\s*,[^;]*?\s+_?\w+\s*[=;]',
);

final _keepAliveAnnotation = RegExp(r'@Riverpod\s*\(\s*keepAlive\s*:\s*true\s*\)');

final _watchUnboundedCollection = RegExp(
  r'\bref\s*\.\s*watch\s*\([\s\S]*?\.\s*select\s*\(\s*\(\w+\)\s*=>\s*\w+\s*\.\s*'
  r'(?:logs|items|entries|history|records|events|messages|notifications|posts|comments|rows|results|all)\b',
);

final _directCollectionProjection = RegExp(
  r'\breturn\s+ref\s*\.\s*watch\s*\([\s\S]*?\.select\s*\([\s\S]*?=>\s*\w+\s*\.\s*'
  r'(?:logs|items|entries|history|records|events|messages|notifications|posts|comments|rows|results|all)'
  r'\s*\)\s*\)\s*;',
);

final _expressionCollectionProjection = RegExp(
  r'=>\s*ref\s*\.\s*watch\s*\([\s\S]*?\.select\s*\([\s\S]*?=>\s*\w+\s*\.\s*'
  r'(?:logs|items|entries|history|records|events|messages|notifications|posts|comments|rows|results|all)'
  r'\s*\)\s*\)\s*;',
);

final _localCollectionProjection = RegExp(
  r'\bfinal\s+(\w+)\s*=\s*ref\s*\.\s*watch\s*\([\s\S]*?\.select\s*\([\s\S]*?=>\s*\w+\s*\.\s*'
  r'(?:logs|items|entries|history|records|events|messages|notifications|posts|comments|rows|results|all)'
  r'\s*\)\s*\)\s*;\s*return\s+\1\s*;',
);

final _datasourceInterfaceSignature = RegExp(
  r'\babstract\s+(?:interface\s+)?class\s+I?\w*(?:Local|Remote)Datasource\b',
);

final _batchLoaderMethod = RegExp(r'\b(?:loadAll|getAll|readAll|loadSettings|getSnapshot)\s*\(');

final _singleValueGetter = RegExp(
  r'\bFuture\s*<\s*(?!List\b|Map\b|Iterable\b|Set\b|Stream\b)[^>]+>\s+'
  r'(?:get|is|has|fetch)[A-Z]\w*\s*\(',
);

final _saveMethodCall = RegExp(r'\.\s*save(?:[A-Z]\w*)?\s*\(');

final _notifierAccess = RegExp(r'\.\s*notifier\s*\)');

final _positiveGuard = RegExp(r'\bif\s*\([^)]*(?:>\s*0\b|>=\s*1\b|!=\s*0\b)');

final _unitPrimitiveLocal = RegExp(
  r'\b(?:double|int|num)\s+([A-Za-z_]\w*(?:Meters|Seconds|Minutes|Hours|Kilometers|Miles|Cents|Percent|Kilograms|Grams|Pounds|Bytes|Pixels))\b\s*=',
);

final _loopOpener = RegExp(r'\b(?:for|while)\s*\(');

final _fullCollectionLoaderCall = RegExp(
  r'\.\s*(?:getAll|fetchAll|fetchAllRows|fetchAllRowsFrom|loadAll|readAll|getAllIds|fetchAllIds)\s*\(',
);

const _platformCommandNames =
    'runJavaScript|runJavaScriptReturningResult|evaluateJavascript|playVideo|pauseVideo'
    '|seekTo|setVolume|setPlaybackRate|mute|unMute|enterFullScreen|exitFullScreen|loadRequest';

// A fire-and-forget native/webview/media command passed directly to `unawaited`,
// e.g. `unawaited(controller.playVideo())`. The receiver is a plain identifier
// chain, so error-handling wrappers (which interpose another call after
// `unawaited(`) and command tear-offs (no call parens) are not matched.
final _unawaitedPlatformCommand = RegExp(
  r'\bunawaited\s*\(\s*[A-Za-z_][\w.!?]*\s*\.\s*(?:' + _platformCommandNames + r')\s*\(',
);

final _errorHandlingWrapper = RegExp(
  r'(?:IgnoringErrors|catchError|runGuarded|guardedFuture|onError|Safely)',
);

final _awaitKeyword = RegExp(r'\bawait\b');

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

bool _methodLooksLongRunningFunction(String methodName) =>
    _longRunningOperationName.hasMatch(methodName);

bool _appwriteExecutionLooksLongRunning(String callWindow) {
  final functionId = RegExp(r'\bfunctionId\s*:\s*([^,\n)]+)').firstMatch(callWindow)?.group(1);
  if (functionId != null && _longRunningOperationName.hasMatch(functionId)) return true;
  final data = RegExp(r'\bdata\s*:\s*([^,\n)]+)').firstMatch(callWindow)?.group(1);
  return data != null && _longRunningOperationName.hasMatch(data);
}

bool _isExecutionForwardingWrapper(
  SourceScannerContext context,
  ScannerMethodSpan method,
  String callWindow,
) {
  final signature = sourceLineWindow(context, method.start, method.end, 6);
  return RegExp(r'\bbool\??\s+xasync\b').hasMatch(signature) &&
      RegExp(r'\bxasync\s*:\s*xasync\b').hasMatch(callWindow);
}

bool _methodLooksDestructive(String methodName) => RegExp(
  r'^(?:delete|remove|destroy|deactivate|close|cancel|purge|wipe)',
  caseSensitive: false,
).hasMatch(methodName);

bool _hasLaterReconcileCall(SourceScannerContext context, int startLine, int endLine) {
  for (var i = startLine; i <= endLine && i < context.source.length; i++) {
    if (_reconcileCall.hasMatch(context.source.masked[i])) return true;
  }
  return false;
}

bool _isStorageBoundaryClass(SourceScannerContext context, ScannerClassSpan classSpan) {
  if (context.isDatasourcePath || context.isRepositoryPath) return true;
  return RegExp(
    r'(?:Datasource|Repository|Storage|Preferences|Settings|Local)$',
  ).hasMatch(classSpan.name);
}

bool _methodLooksLikeResetAll(String methodName) => RegExp(
  r'^(?:reset|clear|wipe|purge)(?:All|Local|Storage|Data|Settings)?$',
  caseSensitive: false,
).hasMatch(methodName);

bool _clearPreservesSentinel(
  SourceScannerContext context,
  ScannerMethodSpan method,
  int clearLine,
) {
  var sawReadBeforeClear = false;
  for (var i = method.start; i < clearLine && i < context.source.length; i++) {
    final line = context.source.masked[i];
    if (_sentinelStorageToken.hasMatch(line) && _storageReadOrGet.hasMatch(line)) {
      sawReadBeforeClear = true;
      break;
    }
  }
  if (!sawReadBeforeClear) return false;

  for (var i = clearLine + 1; i <= method.end && i < context.source.length; i++) {
    final line = context.source.masked[i];
    if (_sentinelStorageToken.hasMatch(line) && _storageWriteOrSave.hasMatch(line)) {
      return true;
    }
  }
  return false;
}

bool _hasEarlyEmptyGuard(SourceScannerContext context, int methodStart, int saveAllLine) {
  for (var i = methodStart; i < saveAllLine; i++) {
    if (_earlyEmptyReturn.hasMatch(context.source.masked[i])) return true;
  }
  return false;
}

bool _hasOuterDirtyGuard(SourceScannerContext context, int saveAllLine) {
  final start = saveAllLine - 12 < 0 ? 0 : saveAllLine - 12;
  for (var i = start; i < saveAllLine; i++) {
    if (_dirtyGuardOutsideMethod.hasMatch(context.source.masked[i])) return true;
  }
  return false;
}

String? _saveAllMappedCollection(String callWindow) {
  final match = RegExp(
    r'\b([A-Za-z_]\w*)\s*\.\s*map\s*\([^)]*\.\s*fromEntity\s*\)',
  ).firstMatch(callWindow);
  return match?.group(1);
}

bool _methodMutatesCollectionSubset(
  SourceScannerContext context,
  ScannerMethodSpan method,
  int saveAllLine,
  String collection,
) {
  final start = saveAllLine - 80 < method.start ? method.start : saveAllLine - 80;
  final indexedAssignment = RegExp(r'\b' + RegExp.escape(collection) + r'\s*\[[^\]]+\]\s*=');
  final linearLookup = RegExp(
    r'\b' + RegExp.escape(collection) + r'\s*\.\s*(?:indexWhere|firstWhere)\s*\(',
  );
  for (var i = start; i < saveAllLine && i < context.source.length; i++) {
    final line = context.source.masked[i];
    if (indexedAssignment.hasMatch(line) || linearLookup.hasMatch(line)) return true;
  }
  return false;
}

bool _collectionGetterAllocates(String body) {
  if (_collectionGetterCache.hasMatch(body)) return false;
  if (_collectionLiteralAllocation.hasMatch(body) && RegExp(r'\bfor\s*\(').hasMatch(body)) {
    return true;
  }
  return _collectionExpressionAllocation.hasMatch(body);
}

bool _isHotLookupClass(SourceScannerContext context, ScannerClassSpan classSpan) =>
    classSpan.isNotifier ||
    context.isUiFile ||
    context.isRepositoryPath ||
    classSpan.name.endsWith('Repository') ||
    classSpan.name.endsWith('Service');

bool _isIndexLookupInsideForBlock(SourceScannerContext context, int methodStart, int lookupLine) {
  final line = context.source.masked[lookupLine];
  if (!line.contains('.indexWhere')) return false;
  final start = lookupLine - 6 < methodStart ? methodStart : lookupLine - 6;
  for (var i = start; i < lookupLine; i++) {
    if (context.source.masked[i].contains('for (')) return true;
  }
  return false;
}

RegExp _nestedIdLookup(String loopVar) => RegExp(
  r'\.\s*(?:indexWhere|firstWhere)\s*\(\s*'
  r'(?:\([A-Za-z_]\w*\)|[A-Za-z_]\w*)\s*=>\s*[A-Za-z_]\w*\s*\.\s*id\s*==\s*'
  '${RegExp.escape(loopVar)}'
  r'\s*\.',
);

int? _findBlockEnd(SourceScannerContext context, int startLine, int maxLine) {
  final state = _BraceScanState();
  for (var i = startLine; i <= maxLine && i < context.source.length; i++) {
    if (_scanBraceLine(state, context.source.masked[i])) return i;
  }
  return null;
}

final class _BraceScanState {
  int depth = 0;
  bool sawOpen = false;
}

bool _scanBraceLine(_BraceScanState state, String line) {
  for (var column = 0; column < line.length; column++) {
    final char = line[column];
    if (char == '{') {
      state.depth++;
      state.sawOpen = true;
    } else if (char == '}' && state.sawOpen) {
      state.depth--;
      if (state.depth == 0) return true;
    }
  }
  return false;
}

String _collectLines(SourceScannerContext context, int startLine, int endLine) {
  final buffer = StringBuffer();
  for (var i = startLine; i <= endLine && i < context.source.length; i++) {
    if (i > startLine) buffer.write('\n');
    buffer.write(context.source.masked[i]);
  }
  return buffer.toString();
}

bool _hasPersistHelper(SourceScannerContext context, ScannerClassSpan classSpan) {
  for (var i = classSpan.start; i <= classSpan.end && i < context.source.length; i++) {
    if (_persistHelperPattern.hasMatch(context.source.masked[i])) return true;
  }
  return false;
}

bool _hasDebounceMechanism(SourceScannerContext context, ScannerClassSpan classSpan) {
  for (var i = classSpan.start; i <= classSpan.end && i < context.source.length; i++) {
    if (_debounceMechanism.hasMatch(context.source.masked[i])) return true;
  }
  return false;
}

bool _isUserVisibleLatencyPath(SourceScannerContext context) {
  if (context.isTestFile) return false;
  final normalized = context.path.replaceAll('\\', '/');
  if (normalized.contains('/data/') ||
      normalized.contains('/repositories/') ||
      normalized.contains('/core/services/') ||
      normalized.contains('/domain/')) {
    return false;
  }
  return normalized.startsWith('lib/core/notifiers/') ||
      normalized.startsWith('lib/core/widgets/') ||
      normalized.contains('/presentation/notifiers/') ||
      normalized.contains('/presentation/screens/') ||
      normalized.contains('/presentation/widgets/') ||
      normalized.contains('/presentation/sheets/') ||
      normalized.contains('/presentation/dialogs/') ||
      normalized.contains('/routes/') ||
      normalized.endsWith('_router.dart');
}

String _durationWindow(SourceScannerContext context, int lineIndex) {
  final start = lineIndex - 3 < 0 ? 0 : lineIndex - 3;
  final end = lineIndex + 3 >= context.source.length ? context.source.length - 1 : lineIndex + 3;
  final buffer = StringBuffer();
  for (var i = start; i <= end; i++) {
    buffer.write(context.source.masked[i]);
    buffer.write('\n');
  }
  return buffer.toString();
}

int _userVisibleDurationBudgetMs(String window) {
  if (RegExp(r'persist|storage|draft|preference', caseSensitive: false).hasMatch(window)) {
    return 50;
  }
  if (RegExp(r'Future\s*(?:<[^>]+>)?\s*\.\s*delayed', caseSensitive: false).hasMatch(window)) {
    return 50;
  }
  if (RegExp(
    r'Animated|AnimationStyle|transitionDuration|duration\s*:',
    caseSensitive: false,
  ).hasMatch(window)) {
    return 120;
  }
  return 150;
}

int? _durationLiteralMs(String line) {
  final msMatch = _durationMillisecondsLiteral.firstMatch(line);
  if (msMatch != null) return int.tryParse(msMatch.group(1) ?? '');

  final secondsMatch = _durationSecondsLiteral.firstMatch(line);
  final seconds = secondsMatch == null ? null : int.tryParse(secondsMatch.group(1) ?? '');
  return seconds == null ? null : seconds * 1000;
}

int? _persistHelperLine(SourceScannerContext context, ScannerClassSpan classSpan) {
  for (var i = classSpan.start; i <= classSpan.end && i < context.source.length; i++) {
    if (_persistHelperPattern.hasMatch(context.source.masked[i])) return i;
  }
  return null;
}

int? _unguardedAsyncStateWriteLine(SourceScannerContext context, ScannerMethodSpan method) {
  int? awaitLine;
  for (var i = method.start; i <= method.end && i < context.source.length; i++) {
    final line = context.source.masked[i];
    if (line.contains('await ')) {
      awaitLine ??= i;
      continue;
    }
    if (awaitLine == null) continue;
    if (!_notifierStateWrite.hasMatch(line)) continue;
    if (_hasStaleGuardBetween(context, awaitLine + 1, i - 1)) return null;
    return i;
  }
  return null;
}

bool _hasStaleGuardBetween(SourceScannerContext context, int startLine, int endLine) {
  if (endLine < startLine) return false;
  for (var i = startLine; i <= endLine && i < context.source.length; i++) {
    final line = context.source.masked[i];
    if (!line.contains('if') || !_staleGuardToken.hasMatch(line)) continue;
    final returnEnd = i + 4 < endLine ? i + 4 : endLine;
    for (var j = i; j <= returnEnd && j < context.source.length; j++) {
      if (context.source.masked[j].contains('return')) return true;
    }
  }
  return false;
}

Set<String> _userGateNames(SourceScannerContext context, ScannerClassSpan classSpan) {
  final names = <String>{};
  for (var i = classSpan.start; i <= classSpan.end && i < context.source.length; i++) {
    final match = _userGateField.firstMatch(context.source.masked[i]);
    final name = match?.group(1);
    if (name != null) names.add(name);
  }
  return names;
}

bool _isHeavyWidgetGated(
  SourceScannerContext context,
  ScannerClassSpan classSpan,
  ScannerMethodSpan method,
  int widgetLine,
) {
  final gateNames = _userGateNames(context, classSpan);
  if (gateNames.isEmpty) return false;
  final start = widgetLine - 8 < method.start ? method.start : widgetLine - 8;
  for (var i = start; i <= widgetLine && i < context.source.length; i++) {
    final line = context.source.masked[i];
    for (final gateName in gateNames) {
      final gate = RegExp(
        r'\b(?:if|else\s+if)\s*\([^)]*\b' +
            RegExp.escape(gateName) +
            r'\b[^)]*\)|\b' +
            RegExp.escape(gateName) +
            r'\s*\?',
      );
      if (gate.hasMatch(line)) return true;
    }
  }
  return false;
}

bool _hasMemoField(SourceScannerContext context, ScannerClassSpan classSpan) {
  for (var i = classSpan.start; i <= classSpan.end && i < context.source.length; i++) {
    if (_memoField.hasMatch(context.source.masked[i])) return true;
  }
  return false;
}

bool _isKeepAliveNotifier(SourceScannerContext context, ScannerClassSpan classSpan) {
  final lookbackStart = classSpan.start - 8 < 0 ? 0 : classSpan.start - 8;
  for (var i = lookbackStart; i < classSpan.start; i++) {
    if (_keepAliveAnnotation.hasMatch(context.source.masked[i])) return true;
  }
  return false;
}

final _topLevelFunctionDecl = RegExp(
  r'^\s*(?:Future\s*<[^>]+>|Stream\s*<[^>]+>|[A-Z]\w*(?:<[^>]+>)?|FutureOr\s*<[^>]+>|void)\s+\w+\s*\([^)]*Ref\s+\w+',
);

int? _findFunctionDeclarationAfter(SourceScannerContext context, int annotationLine) {
  final end = annotationLine + 6 > context.source.length
      ? context.source.length
      : annotationLine + 6;
  for (var i = annotationLine + 1; i < end; i++) {
    if (_topLevelFunctionDecl.hasMatch(context.source.masked[i])) return i;
  }
  return null;
}

int? _findFunctionBodyEnd(SourceScannerContext context, int fnLine) {
  final state = _BraceScanState();
  for (var i = fnLine; i < context.source.length && i < fnLine + 200; i++) {
    if (_scanBraceLine(state, context.source.masked[i])) return i;
  }
  return null;
}

bool _isDatasourceInterface(SourceScannerContext context, ScannerClassSpan classSpan) {
  for (var i = classSpan.start; i <= classSpan.start + 2 && i < context.source.length; i++) {
    if (_datasourceInterfaceSignature.hasMatch(context.source.masked[i])) return true;
  }
  return false;
}

bool _hasBatchLoader(SourceScannerContext context, ScannerClassSpan classSpan) {
  for (var i = classSpan.start; i <= classSpan.end && i < context.source.length; i++) {
    if (_batchLoaderMethod.hasMatch(context.source.masked[i])) return true;
  }
  return false;
}

int _countSingleValueGetters(SourceScannerContext context, ScannerClassSpan classSpan) {
  var count = 0;
  for (var i = classSpan.start; i <= classSpan.end && i < context.source.length; i++) {
    if (_singleValueGetter.hasMatch(context.source.masked[i])) count++;
  }
  return count;
}

bool _hasPositiveGuard(SourceScannerContext context, int methodStart, int saveLine) {
  for (var i = methodStart; i < saveLine; i++) {
    if (_positiveGuard.hasMatch(context.source.masked[i])) return true;
  }
  return false;
}

bool _methodHasNotifierAccess(SourceScannerContext context, ScannerMethodSpan method) {
  for (var i = method.start; i <= method.end && i < context.source.length; i++) {
    if (_notifierAccess.hasMatch(context.source.masked[i])) return true;
  }
  return false;
}

int? _unboundedCollectionWatchColumn(SourceScannerContext context, int startLine, int endLine) {
  final line = context.source.masked[startLine];
  final watchStart = line.indexOf('ref.watch');
  if (watchStart < 0) return null;
  final window = sourceLineWindow(context, startLine, endLine, 8);
  if (!_watchUnboundedCollection.hasMatch(window)) return null;
  if (_isPureCollectionProjection(window)) return null;
  return watchStart;
}

bool _isPureCollectionProjection(String window) {
  return _directCollectionProjection.hasMatch(window) ||
      _expressionCollectionProjection.hasMatch(window) ||
      _localCollectionProjection.hasMatch(window);
}

bool _lineHasNumericNamedArg(SourceScannerContext context, int saveLine, int methodEnd) {
  final end = saveLine + 8 > methodEnd ? methodEnd : saveLine + 8;
  for (var i = saveLine; i <= end && i < context.source.length; i++) {
    if (_numericNamedArg.hasMatch(context.source.masked[i])) return true;
  }
  return false;
}

final _textInputConstructor = RegExp(
  r'(?:^|\breturn\s+|=>\s*|=\s*|,\s*|\(\s*|\[\s*|child:\s*|children:\s*\[\s*)'
  r'(TextField|TextFormField|CupertinoTextField|CupertinoTextFormFieldRow|SearchBar|SearchAnchor)\s*\(',
);

final _sliderConstructor = RegExp(
  r'(?:^|\breturn\s+|=>\s*|=\s*|,\s*|\(\s*|\[\s*|child:\s*|children:\s*\[\s*)'
  r'(Slider|RangeSlider|CupertinoSlider)\s*\(',
);

final _scrollListenerCall = RegExp(
  r'\b(?:_?\w*[Ss]crollController|widget\s*\.\s*\w*[Ss]crollController)\s*\.\s*addListener\s*\(',
);

final _expensiveOnChangedWork = RegExp(
  r'\bawait\b|'
  r'\.\s*notifier\s*\)\s*\.\s*\w+\s*\(|'
  r'\b(?:http|dio|Dio)\s*\.\s*(?:get|post|put|patch|delete)\s*\(',
);

final _onChangedNamedArg = RegExp(r'\bonChanged\s*:\s*\(');

final _numericNamedArg = RegExp(
  r'\b(?:duration|distance|amount|count|weight|seconds|meters|kilometers|miles|minutes|hours|cents|percent|kilograms|pounds|grams|bytes|pixels|total|max|min|limit|offset|threshold|delay|timeout|ratio|score|level|size|index|page)\w*\s*:',
  caseSensitive: false,
);
