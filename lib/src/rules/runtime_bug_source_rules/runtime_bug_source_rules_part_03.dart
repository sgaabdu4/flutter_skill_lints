part of '../runtime_bug_source_rules.dart';

final _manualIdLoop = RegExp(r'\bfor\s*\([\s\S]*?\.\s*id\s*==');

void _reportManualIdLookupFunctions(ScannerRuleReporter reporter, SourceScannerContext context) {
  for (var lineIndex = 0; lineIndex < context.source.length; lineIndex++) {
    final match = _byIdFunctionStart.firstMatch(context.source.masked[lineIndex]);
    if (match == null || !_manualIdLookupFunctionHasLoop(context, lineIndex)) continue;
    reporter.report(context, lineIndex, match.start);
  }
}

bool _manualIdLookupFunctionHasLoop(SourceScannerContext context, int lineIndex) {
  final end = _findBlockEnd(context, lineIndex, context.source.length - 1);
  return end != null && _manualIdLoop.hasMatch(_collectLines(context, lineIndex, end));
}

void _reportHotClassIdLookups(ScannerRuleReporter reporter, SourceScannerContext context) {
  for (final classSpan in context.classes) {
    if (!_isHotLookupClass(context, classSpan)) continue;
    for (final method in context.methods.where((method) => classSpan.contains(method.start))) {
      _reportHotMethodIdLookups(reporter, context, method);
    }
  }
}

void _reportHotMethodIdLookups(
  ScannerRuleReporter reporter,
  SourceScannerContext context,
  ScannerMethodSpan method,
) {
  _visitMethodLines(context, method, (lineIndex, line) {
    final match = _linearIdLookupCall.firstMatch(line);
    if (match == null || !_isHotLinearIdLookup(context, method, lineIndex)) return false;
    reporter.report(context, lineIndex, match.start);
    return false;
  });
}

bool _isHotLinearIdLookup(SourceScannerContext context, ScannerMethodSpan method, int lineIndex) {
  final lookupWindow = sourceLineWindow(context, lineIndex, method.end, 6);
  return _linearIdLookup.hasMatch(lookupWindow) &&
      !_isIndexLookupInsideForBlock(context, method.start, lineIndex);
}

void _reportNestedIdLookups(
  ScannerRuleReporter reporter,
  SourceScannerContext context,
  ScannerMethodSpan method,
) {
  for (
    var lineIndex = method.start;
    lineIndex <= method.end && lineIndex < context.source.length;
    lineIndex++
  ) {
    _reportNestedIdLookupAtLine(reporter, context, method, lineIndex);
  }
}

void _reportNestedIdLookupAtLine(
  ScannerRuleReporter reporter,
  SourceScannerContext context,
  ScannerMethodSpan method,
  int lineIndex,
) {
  final loop = _forEachLoop.firstMatch(context.source.masked[lineIndex]);
  final loopVar = loop?.group(1);
  if (loopVar == null) return;
  final bodyEnd = _findBlockEnd(context, lineIndex, method.end) ?? method.end;
  final lookup = _nestedIdLookup(loopVar);
  for (
    var bodyLine = lineIndex + 1;
    bodyLine <= bodyEnd && bodyLine < context.source.length;
    bodyLine++
  ) {
    final match = _linearIdLookupCall.firstMatch(context.source.masked[bodyLine]);
    if (match == null) continue;
    if (_nestedLookupMatches(context, bodyLine, bodyEnd, lookup)) {
      reporter.report(context, bodyLine, match.start);
      return;
    }
  }
}

bool _nestedLookupMatches(
  SourceScannerContext context,
  int lineIndex,
  int bodyEnd,
  RegExp lookup,
) => lookup.hasMatch(sourceLineWindow(context, lineIndex, bodyEnd, 6));

void _reportStorageClearSentinels(ScannerRuleReporter reporter, SourceScannerContext context) {
  for (final classSpan in context.classes) {
    if (!_isStorageBoundaryClass(context, classSpan)) continue;
    for (final method in context.methods.where((method) => classSpan.contains(method.start))) {
      if (_methodLooksLikeResetAll(method.name)) {
        _reportStorageClearMethod(reporter, context, method);
      }
    }
  }
}

void _reportStorageClearMethod(
  ScannerRuleReporter reporter,
  SourceScannerContext context,
  ScannerMethodSpan method,
) {
  for (
    var lineIndex = method.start;
    lineIndex <= method.end && lineIndex < context.source.length;
    lineIndex++
  ) {
    final match = _storageClearCall.firstMatch(context.source.masked[lineIndex]);
    if (match != null && _clearPreservesSentinel(context, method, lineIndex)) {
      reporter.report(context, lineIndex, match.start);
    }
  }
}

void _reportUngatedHeavyWidgets(ScannerRuleReporter reporter, SourceScannerContext context) {
  for (final classSpan in context.classes) {
    for (final method in context.methods.where((method) => method.name == 'build')) {
      if (classSpan.contains(method.start)) {
        _reportHeavyWidgetsInBuild(reporter, context, classSpan, method);
      }
    }
  }
}

void _reportHeavyWidgetsInBuild(
  ScannerRuleReporter reporter,
  SourceScannerContext context,
  ScannerClassSpan classSpan,
  ScannerMethodSpan method,
) {
  for (
    var lineIndex = method.start;
    lineIndex <= method.end && lineIndex < context.source.length;
    lineIndex++
  ) {
    final match = _heavyWidgetInit.firstMatch(context.source.masked[lineIndex]);
    if (match == null || _isHeavyWidgetGated(context, classSpan, method, lineIndex)) continue;
    reporter.report(context, lineIndex, match.start);
  }
}
