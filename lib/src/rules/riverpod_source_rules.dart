import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/rules/source_scanner_rule.dart';
part 'riverpod_source_rules/riverpod_source_rules_part_01.dart';

final List<ScannerRule> riverpodSourceRules = [..._riverpodSourceRulesPart1];

final _manualProviderDeclaration = RegExp(
  r'\b(?:final|var|const)\s+[A-Za-z_]\w*\s*=\s*'
  r'(?:AutoDispose)?(?:Provider|FutureProvider|StreamProvider|StateProvider|'
  r'NotifierProvider|AsyncNotifierProvider|StateNotifierProvider|ChangeNotifierProvider)'
  r'(?:\s*[<(]|\s*\.)',
);

final _derivedCacheField = RegExp(
  r'^\s*(?:late\s+)?(?:final\s+)?'
  r'(?:[A-Za-z_]\w*(?:<[^;=]+>)?\??)\s+'
  r'(_[A-Za-z_]\w*(?:Cache|Source|Snapshot|Memo|DayStart|TodayStart|Filtered|Sorted|Grouped|Lookup|ById))\b',
);
final _providerSubscriptionField = RegExp(
  r'^\s*(?:late\s+)?(?:final\s+)?'
  r'(?:[A-Za-z_]\w*\.)?ProviderSubscription\s*<[^;=]+>\??\s+(_[A-Za-z_]\w*)\b',
);
final _providerArgWrapperMember = RegExp(
  r'^\s*(?:late\s+)?(?:final\s+)?'
  r'(?:[A-Za-z_]\w*(?:<[^;=]+>)?\??)\s+'
  r'(?:get\s+)?(_(?:config|args?|params?|providerArgs?|providerParams?))\b',
);
final _providerArgWrapperLocal = RegExp(
  r'^\s*final\s+(?:[A-Za-z_]\w*(?:<[^;=]+>)?\??\s+)?'
  r'(config|args?|params?|providerArgs?|providerParams?)\s*=\s*'
  r'[A-Z]\w*(?:Config|Args|Params)\s*\(',
);
final _inlineProviderArgWrapper = RegExp(
  r'\b[A-Za-z_]\w*Provider\s*\(\s*[A-Z]\w*(?:Config|Args|Params)\s*\(',
);
final _refListenManual = RegExp(r'\bref\s*\.\s*listenManual\s*[<(]');
final _refWatchCall = RegExp(r'\bref\s*\.\s*watch\s*\(');
final _overrideWithValueStart = RegExp(r'\b([a-z]\w*Provider)\s*\.\s*overrideWithValue\s*\(');
final _stateValueConstructor = RegExp(r'\b(?:const\s+)?([A-Z]\w*State)\s*\(');

({RegExpMatch match, int column})? _manualProviderDeclarationMatch(
  SourceScannerContext context,
  int lineIndex,
) {
  final end = lineIndex + 4 > context.source.masked.length
      ? context.source.masked.length
      : lineIndex + 4;
  final window = context.source.masked.sublist(lineIndex, end).join('\n');
  final match = _manualProviderDeclaration.firstMatch(window);
  if (match == null) return null;

  final beforeMatch = window.substring(0, match.start);
  if (beforeMatch.contains('\n')) return null;
  return (match: match, column: beforeMatch.length);
}

({int column, String providerName})? _notifierStateOverrideWithValueMatch(
  SourceScannerContext context,
  int lineIndex,
) {
  if (context.isTestFile) return null;

  final end = lineIndex + 6 > context.source.masked.length
      ? context.source.masked.length
      : lineIndex + 6;
  final window = context.source.masked.sublist(lineIndex, end).join('\n');
  final overrideMatch = _overrideWithValueStart.firstMatch(window);
  if (overrideMatch == null) return null;

  final beforeMatch = window.substring(0, overrideMatch.start);
  if (beforeMatch.contains('\n')) return null;

  final providerName = overrideMatch.group(1) ?? '';
  final stateMatch = _stateValueConstructor.firstMatch(window.substring(overrideMatch.end));
  final stateType = stateMatch?.group(1);
  if (stateType == null) return null;
  if (!_isGeneratedNotifierStateOverride(providerName, stateType)) return null;

  return (column: beforeMatch.length, providerName: providerName);
}

bool _isGeneratedNotifierStateOverride(String providerName, String stateType) {
  if (!providerName.endsWith('Provider') || !stateType.endsWith('State')) return false;
  final providerBase = providerName.substring(0, providerName.length - 'Provider'.length);
  final stateBase = stateType.substring(0, stateType.length - 'State'.length);
  return providerBase == _lowerFirst(stateBase);
}

bool _isConsumerStateClass(SourceScannerContext context, ScannerClassSpan classSpan) {
  final signature = _classSignature(context, classSpan);
  return RegExp(r'\bextends\s+(?:[A-Za-z_]\w*\.)?ConsumerState\s*<').hasMatch(signature);
}

String _classSignature(SourceScannerContext context, ScannerClassSpan classSpan) {
  final buffer = StringBuffer();
  for (var i = classSpan.start; i <= classSpan.end && i < context.source.length; i++) {
    final line = context.source.masked[i];
    buffer.write(' ');
    buffer.write(line);
    if (line.contains('{')) break;
  }
  return buffer.toString();
}

bool _classContainsRefWatch(SourceScannerContext context, ScannerClassSpan classSpan) {
  for (var i = classSpan.start; i <= classSpan.end && i < context.source.length; i++) {
    if (_refWatchCall.hasMatch(context.source.masked[i])) return true;
  }
  return false;
}

bool _classPassesProviderArgName(
  SourceScannerContext context,
  ScannerClassSpan classSpan,
  String name,
) {
  final body = context.source.masked.sublist(classSpan.start, classSpan.end + 1).join('\n');
  return _providerCallWithArgName(name).hasMatch(body);
}

bool _methodPassesProviderArgName(
  SourceScannerContext context,
  ScannerMethodSpan method,
  String name,
) {
  final body = context.source.masked.sublist(method.start, method.end + 1).join('\n');
  return _providerCallWithArgName(name).hasMatch(body);
}

RegExp _providerCallWithArgName(String name) {
  return RegExp(r'\b[A-Za-z_]\w*Provider\s*\(\s*' + RegExp.escape(name) + r'\b');
}

Iterable<int> _directClassMemberLines(
  SourceScannerContext context,
  ScannerClassSpan classSpan,
) sync* {
  var depth = 0;
  var sawClassOpenBrace = false;

  for (var i = classSpan.start; i <= classSpan.end && i < context.source.length; i++) {
    final line = context.source.masked[i];
    if (i > classSpan.start && sawClassOpenBrace && depth == 1) {
      yield i;
    }

    for (var j = 0; j < line.length; j++) {
      final char = line[j];
      if (char == '{') {
        depth++;
        sawClassOpenBrace = true;
      } else if (char == '}') {
        depth--;
      }
    }
  }
}

final class _ProviderAnnotation {
  const _ProviderAnnotation({
    required this.line,
    required this.endLine,
    required this.text,
    required this.keepAlive,
  });

  final int line;
  final int endLine;
  final String text;
  final bool keepAlive;
}

final class _RiverpodProviderDefinition {
  const _RiverpodProviderDefinition({
    required this.providerName,
    required this.annotationLine,
    required this.bodyStart,
    required this.bodyEnd,
    required this.keepAlive,
    required this.hasParameters,
    required this.isClassBased,
    required this.className,
  });

  final String providerName;
  final int annotationLine;
  final int bodyStart;
  final int bodyEnd;
  final bool keepAlive;
  final bool hasParameters;
  final bool isClassBased;
  final String className;
}

List<_RiverpodProviderDefinition> _providerDefinitions(SourceScannerContext context) {
  final definitions = <_RiverpodProviderDefinition>[];

  for (var i = 0; i < context.source.length; i++) {
    final annotation = _riverpodAnnotationAt(context, i);
    if (annotation == null) continue;

    final declarationLine = _nextNonEmptyLine(context, annotation.endLine + 1);
    if (declarationLine == null) continue;
    final declaration = context.source.masked[declarationLine];

    final classMatch = RegExp(r'\bclass\s+([A-Za-z_]\w*)\b').firstMatch(declaration);
    if (classMatch != null) {
      final className = classMatch.group(1) ?? '';
      final classSpan = context.classes
          .where((classSpan) => classSpan.start == declarationLine)
          .cast<ScannerClassSpan?>()
          .firstOrNull;
      final bodyEnd = classSpan?.end ?? declarationLine;
      definitions.add(
        _RiverpodProviderDefinition(
          providerName: _classProviderName(className),
          annotationLine: annotation.line,
          bodyStart: declarationLine,
          bodyEnd: bodyEnd,
          keepAlive: annotation.keepAlive,
          hasParameters: _classBuildHasParameters(context, declarationLine, bodyEnd),
          isClassBased: true,
          className: className,
        ),
      );
      i = declarationLine;
      continue;
    }

    final functionName = _functionProviderName(context, declarationLine);
    if (functionName == null) continue;
    definitions.add(
      _RiverpodProviderDefinition(
        providerName: _functionProviderGeneratedName(functionName),
        annotationLine: annotation.line,
        bodyStart: declarationLine,
        bodyEnd: _functionProviderEnd(context, declarationLine),
        keepAlive: annotation.keepAlive,
        hasParameters: _functionHasProviderParameters(context, declarationLine),
        isClassBased: false,
        className: '',
      ),
    );
    i = declarationLine;
  }

  return definitions;
}

_ProviderAnnotation? _riverpodAnnotationAt(SourceScannerContext context, int lineIndex) {
  final line = context.source.masked[lineIndex];
  if (!RegExp(r'^\s*@(?:r|R)iverpod\b').hasMatch(line)) return null;

  final text = StringBuffer();
  var endLine = lineIndex;
  final needsClosingParen = line.contains('@Riverpod') && line.contains('(') && !line.contains(')');
  for (var i = lineIndex; i < context.source.length; i++) {
    text.write(' ${context.source.masked[i]}');
    endLine = i;
    if (!needsClosingParen || context.source.masked[i].contains(')')) break;
  }

  final annotationText = text.toString();
  return _ProviderAnnotation(
    line: lineIndex,
    endLine: endLine,
    text: annotationText,
    keepAlive: RegExp(r'@Riverpod\s*\([^)]*keepAlive\s*:\s*true').hasMatch(annotationText),
  );
}

int? _nextNonEmptyLine(SourceScannerContext context, int startLine) {
  for (var i = startLine; i < context.source.length; i++) {
    if (context.source.masked[i].trim().isNotEmpty) return i;
  }
  return null;
}

String _classProviderName(String className) {
  final base = className.endsWith('Notifier')
      ? className.substring(0, className.length - 'Notifier'.length)
      : className;
  return '${_lowerFirst(base)}Provider';
}

String _functionProviderGeneratedName(String functionName) =>
    '${_lowerFirst(functionName)}Provider';

String _lowerFirst(String value) {
  if (value.isEmpty) return value;
  return value[0].toLowerCase() + value.substring(1);
}

bool _classBuildHasParameters(SourceScannerContext context, int classStart, int classEnd) {
  for (var i = classStart; i <= classEnd && i < context.source.length; i++) {
    final line = context.source.masked[i];
    if (!RegExp(r'\bbuild\s*\(').hasMatch(line)) continue;
    return _parameterListHasProviderArgs(_declarationText(context, i));
  }
  return false;
}

String? _functionProviderName(SourceScannerContext context, int declarationLine) {
  final declaration = _declarationWindow(context, declarationLine);
  final matches = RegExp(r'\b([A-Za-z_]\w*)\s*\(').allMatches(declaration).toList();
  if (matches.isEmpty) return null;
  return matches.last.group(1);
}

bool _functionHasProviderParameters(SourceScannerContext context, int declarationLine) =>
    _parameterTextHasProviderArgs(_functionParameterText(context, declarationLine));

String _declarationText(SourceScannerContext context, int startLine) {
  final buffer = StringBuffer();
  var depth = 0;
  var sawParen = false;
  for (var i = startLine; i < context.source.length && i < startLine + 8; i++) {
    final line = context.source.masked[i];
    buffer.write(' $line');
    for (var column = 0; column < line.length; column++) {
      final char = line[column];
      if (char == '(') {
        sawParen = true;
        depth++;
      } else if (char == ')' && sawParen) {
        depth--;
        if (depth == 0) return buffer.toString();
      }
    }
  }
  return buffer.toString();
}

bool _parameterListHasProviderArgs(String declaration) {
  final start = declaration.indexOf('(');
  final end = declaration.indexOf(')', start + 1);
  if (start < 0 || end < 0) return false;
  final parameters = declaration.substring(start + 1, end).trim();
  return _parameterTextHasProviderArgs(parameters);
}

bool _parameterTextHasProviderArgs(String parameters) {
  if (parameters.isEmpty) return false;
  final withoutRef = parameters
      .replaceFirst(RegExp(r'^(?:[A-Za-z_]\w*)?Ref\s+ref\s*,?\s*'), '')
      .replaceFirst(RegExp(r'^WidgetRef\s+ref\s*,?\s*'), '')
      .trim();
  return withoutRef.isNotEmpty;
}

String _functionParameterText(SourceScannerContext context, int declarationLine) {
  final declaration = _declarationWindow(context, declarationLine);
  final matches = RegExp(r'\b[A-Za-z_]\w*\s*\(([^)]*)\)').allMatches(declaration).toList();
  if (matches.isEmpty) return '';
  return matches.last.group(1)?.trim() ?? '';
}

String _declarationWindow(SourceScannerContext context, int startLine) {
  final buffer = StringBuffer();
  for (var i = startLine; i < context.source.length && i < startLine + 8; i++) {
    final line = context.source.masked[i];
    final bodyStart = _declarationBodyStart(line);
    buffer.write(' ');
    if (bodyStart == null) {
      buffer.write(line);
      continue;
    }
    buffer.write(line.substring(0, bodyStart));
    break;
  }
  return buffer.toString();
}

int? _declarationBodyStart(String line) {
  final blockMatch = RegExp(r'\)\s*(?:async\s*\*?|sync\s*\*)?\s*\{').firstMatch(line);
  final blockIndex = blockMatch == null ? -1 : line.indexOf('{', blockMatch.start);
  final arrowIndex = line.indexOf('=>');
  if (blockIndex < 0) return arrowIndex < 0 ? null : arrowIndex;
  if (arrowIndex < 0) return blockIndex;
  return blockIndex < arrowIndex ? blockIndex : arrowIndex;
}

int _functionProviderEnd(SourceScannerContext context, int declarationLine) {
  final declaration = context.source.masked[declarationLine];
  if (declaration.contains('=>')) return declarationLine;

  var depth = 0;
  var sawOpenBrace = false;
  for (var i = declarationLine; i < context.source.length; i++) {
    final line = context.source.masked[i];
    depth += _count(line, '{');
    if (line.contains('{')) sawOpenBrace = true;
    depth -= _count(line, '}');
    if (sawOpenBrace && depth <= 0) return i;
  }
  return declarationLine;
}

Set<String> _watchedProviderNames(
  SourceScannerContext context,
  _RiverpodProviderDefinition definition,
) {
  final body = context.source.masked
      .sublist(definition.bodyStart, definition.bodyEnd + 1)
      .join('\n');
  return RegExp(
    r'\bref\s*\.\s*watch\s*\(\s*([A-Za-z_]\w*Provider)\b',
  ).allMatches(body).map((match) => match.group(1) ?? '').where((name) => name.isNotEmpty).toSet();
}

int _count(String text, String char) {
  var count = 0;
  for (var i = 0; i < text.length; i++) {
    if (text[i] == char) count++;
  }
  return count;
}

bool _hasBlockSelectCallback(String invocation) =>
    RegExp(r'\.\s*select\s*\(\s*\([^)]*\)\s*\{').hasMatch(invocation);

bool _hasIdentitySelectCallback(String invocation) {
  final match = RegExp(
    r'\.\s*select\s*\(\s*\(\s*(?:(?:final|var|[A-Za-z_]\w*(?:<[^>]+>)?\??)\s+)?([A-Za-z_]\w*)\s*\)\s*=>\s*\1\s*(?:,|\))',
  ).firstMatch(invocation);
  return match != null;
}

int _firstSelectLine(SourceScannerContext context, int startLine, int methodEnd) {
  for (var i = startLine; i <= methodEnd && i < context.source.length; i++) {
    if (context.source.masked[i].contains('.select')) return i;
  }
  return startLine;
}

bool _isKeepAliveRiverpodAnnotation(SourceScannerContext context, int lineIndex) {
  final line = context.source.masked[lineIndex];
  if (!line.contains('@Riverpod')) return false;

  final annotation = StringBuffer();
  final end = (lineIndex + 6).clamp(0, context.source.length - 1);
  for (var i = lineIndex; i <= end; i++) {
    annotation.write(' ${context.source.masked[i]}');
    if (context.source.masked[i].contains(')')) break;
  }
  return RegExp(r'@Riverpod\s*\([^)]*keepAlive\s*:\s*true').hasMatch(annotation.toString());
}

bool _hasKeepAliveTickerModeWorkaround(SourceScannerContext context, int annotationLine) {
  return context.nearOriginal(
    annotationLine,
    RegExp(
      r'(?:#4709|riverpod#4709|TickerMode|pausedActiveSubscriptionCount)',
      caseSensitive: false,
    ),
    6,
  );
}

bool _hasFamilySignatureAfterKeepAlive(SourceScannerContext context, int annotationLine) {
  final annotation = _riverpodAnnotationAt(context, annotationLine);
  if (annotation == null) return false;
  final declarationLine = _nextNonEmptyLine(context, annotation.endLine + 1);
  if (declarationLine == null) return false;

  final declaration = _declarationText(context, declarationLine);
  if (RegExp(r'\bclass\s+[A-Za-z_]\w*\b').hasMatch(declaration)) {
    final classSpan = context.classes
        .where((classSpan) => classSpan.start == declarationLine)
        .cast<ScannerClassSpan?>()
        .firstOrNull;
    return _classBuildHasParameters(context, declarationLine, classSpan?.end ?? declarationLine);
  }

  return _functionHasProviderParameters(context, declarationLine);
}

bool _isFeaturePresentationNotifierPath(SourceScannerContext context) {
  final normalized = context.path.replaceAll('\\', '/').toLowerCase();
  return normalized.startsWith('lib/features/') &&
      normalized.contains('/presentation/notifiers/') &&
      normalized.endsWith('_notifier.dart');
}

bool _hasAutoDisposeRationale(SourceScannerContext context, int annotationLine) {
  return context.nearOriginal(
    annotationLine,
    RegExp(
      r'\b(?:auto[- ]?dispose|ephemeral|transient|route[- ]?local|screen[- ]?local|reset when|dispose when unused)\b',
      caseSensitive: false,
    ),
    6,
  );
}

bool _registersDisposeCleanup(
  SourceScannerContext context,
  _RiverpodProviderDefinition definition,
) {
  final body = context.source.masked
      .sublist(definition.bodyStart, definition.bodyEnd + 1)
      .join('\n');
  return RegExp(r'\bref\s*\.\s*onDispose\s*\(').hasMatch(body);
}

bool _hasBroadRefWatch(SourceScannerContext context, int lineIndex, int methodEnd) {
  for (final invocation in _refWatchInvocations(context, lineIndex, methodEnd)) {
    if (!RegExp(r'\.\s*select\s*\(').hasMatch(invocation) &&
        !RegExp(r'\.\s*notifier\b').hasMatch(invocation) &&
        !_isProjectionProviderWatch(invocation)) {
      return true;
    }
  }
  return false;
}

final _eventSignalProviderName = RegExp(
  r'(?:Signal|Signals|Event|Events|Pulse|Pulses|Serial|Serials)$',
);
final _eventSignalFunctionProvider = RegExp(
  r'^\s*(?:Future\s*<[^>]+>|Stream\s*<[^>]+>|[A-Za-z_]\w*(?:<[^>]+>)?\??)\s+'
  r'([A-Za-z_]\w*)\s*\(\s*Ref\s+ref\b',
);

bool _hasRiverpodAnnotation(SourceScannerContext context, ScannerClassSpan classSpan) {
  for (var i = classSpan.start - 1; i >= 0 && i >= classSpan.start - 6; i--) {
    final line = context.source.masked[i].trim();
    if (line.isEmpty) continue;
    if (line.startsWith('@riverpod') || line.startsWith('@Riverpod')) return true;
    if (!line.startsWith('//')) return false;
  }
  return false;
}

bool _isProjectionProviderWatch(String invocation) {
  final providerName = _watchedProviderName(invocation);
  if (providerName == null) return false;
  return _isProjectionProviderName(providerName);
}

String? _watchedProviderName(String invocation) {
  final match = RegExp(
    r'\bref\s*\.\s*watch\s*\(\s*([A-Za-z_]\w*Provider)\b',
  ).firstMatch(invocation);
  return match?.group(1);
}

bool _isProjectionProviderName(String providerName) {
  final base = providerName.endsWith('Provider')
      ? providerName.substring(0, providerName.length - 'Provider'.length)
      : providerName;
  final normalized = base.toLowerCase();

  if (normalized.endsWith('byid') ||
      normalized.endsWith('category') ||
      normalized.endsWith('categories') ||
      normalized.endsWith('count') ||
      normalized.endsWith('data') ||
      normalized.endsWith('date') ||
      normalized.endsWith('dates') ||
      normalized.endsWith('days') ||
      normalized.endsWith('direction') ||
      normalized.endsWith('enabled') ||
      normalized.endsWith('entries') ||
      normalized.endsWith('entry') ||
      normalized.endsWith('ids') ||
      normalized.endsWith('indices') ||
      normalized.endsWith('map') ||
      normalized.endsWith('mode') ||
      normalized.endsWith('name') ||
      normalized.endsWith('reminder') ||
      normalized.endsWith('router') ||
      normalized.endsWith('session') ||
      normalized.endsWith('sessions') ||
      normalized.endsWith('share') ||
      normalized.endsWith('sound') ||
      normalized.endsWith('summary') ||
      normalized.endsWith('timer') ||
      normalized.endsWith('unit') ||
      normalized.endsWith('value') ||
      normalized.endsWith('vibration') ||
      normalized.endsWith('version')) {
    return true;
  }

  if (RegExp(
    r'(?:count|data|dates|days|entries|entry|ids|indices|list|map|sets|summary|value)for[a-z0-9]+$',
  ).hasMatch(normalized)) {
    return true;
  }

  return false;
}

List<String> _refWatchInvocations(SourceScannerContext context, int lineIndex, int methodEnd) {
  final firstLine = context.source.masked[lineIndex];
  final matches = RegExp(r'\bref\s*\.\s*watch\s*\(').allMatches(firstLine).toList();
  if (matches.isEmpty) return const [];

  return [
    for (final match in matches) _refWatchInvocation(context, lineIndex, methodEnd, match.start),
  ];
}

String _refWatchInvocation(
  SourceScannerContext context,
  int startLine,
  int methodEnd,
  int startColumn,
) {
  final buffer = StringBuffer();
  var depth = 0;
  var sawOpenParen = false;

  for (
    var lineIndex = startLine;
    lineIndex <= methodEnd && lineIndex < context.source.length;
    lineIndex++
  ) {
    final line = context.source.masked[lineIndex];
    final scanStart = lineIndex == startLine ? startColumn : 0;

    for (var column = scanStart; column < line.length; column++) {
      final char = line[column];
      buffer.write(char);

      if (char == '(') {
        sawOpenParen = true;
        depth++;
        continue;
      }

      if (char == ')' && sawOpenParen) {
        depth--;
        if (depth == 0) {
          return buffer.toString();
        }
      }
    }

    buffer.write('\n');
  }

  return buffer.toString();
}
