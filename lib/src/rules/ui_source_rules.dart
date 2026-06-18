import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/rules/source_scanner_rule.dart';
part 'ui_source_rules/ui_source_rules_part_01.dart';

final List<ScannerRule> uiSourceRules = [..._uiSourceRulesPart1];

final _currentDateTimeCall = RegExp(r'\bDateTime\s*\.\s*(?:now|timestamp)\s*\(\s*\)');
final _interpolatedCurrentDateTimeCall = RegExp(
  r'\$\{\s*DateTime\s*\.\s*(?:now|timestamp)\s*\(\s*\)',
);
final _localNowExpression = RegExp(
  r'\bDateTime\s*\.\s*now\s*\(\s*\)\s*\.\s*toLocal\s*\('
  r'|\b(?:[A-Za-z_]\w*\s*\.\s*)?nowLocal\s*\(',
);
final _persistedLocalNowExpression = RegExp(
  r'\b(?:createdAt|updatedAt|deletedAt|savedAt|syncedAt|lastSyncedAt|timestamp|checkedInAt)\b\s*(?::|=)\s*\(?\s*(?:'
  r'\bDateTime\s*\.\s*now\s*\(\s*\)\s*\.\s*toLocal\s*\('
  r'|\b(?:[A-Za-z_]\w*\s*\.\s*)?nowLocal\s*\()',
);
final _currentTimeHelperDateMath = RegExp(
  r'\b(?:DateTimeX\s*\.\s*)?nowLocal\s*\(\s*\)(?:\s*\.\s*startOfDay)?\s*\.\s*(?:calendarDaysBefore|calendarDaysAfter|daysBefore|daysAfter|add|subtract)\s*\(',
);
final _currentTimeBoundary = RegExp(
  r'\b(?:DateTimeX\s*\.\s*)?now(?:Local|Utc)\s*\(\s*\)\s*\.\s*(?:startOfDay|endOfDay)\b',
);

bool _hasRawStyleToken(String line) {
  if (RegExp(r'\bColor\s*\(\s*0x[0-9A-Fa-f]+').hasMatch(line)) {
    return true;
  }

  final visualConstructor = RegExp(
    r'\b(?:EdgeInsets|BorderRadius|Radius|SizedBox)(?:\.\w+)?\s*\([^)]*',
  );
  for (final match in visualConstructor.allMatches(line)) {
    if (_hasMeaningfulNumericLiteral(line.substring(match.start))) {
      return true;
    }
  }
  return false;
}

bool _hasMeaningfulNumericLiteral(String line) {
  final numericLiteral = RegExp(r'(?<![A-Za-z_])(?:\d+(?:\.\d+)?|\.\d+)');
  for (final match in numericLiteral.allMatches(line)) {
    final literal = match.group(0);
    if (literal == null) continue;

    final value = double.tryParse(literal);
    if (value == null || value == 0) continue;

    final previous = _previousNonWhitespace(line, match.start);
    if (previous != null && '+-*/'.contains(previous)) continue;

    return true;
  }
  return false;
}

({int lineIndex, int column}) _lineColumnForOffset(SourceScannerSource source, int offset) {
  var lineIndex = 0;
  while (lineIndex + 1 < source.lineOffsets.length && source.lineOffsets[lineIndex + 1] <= offset) {
    lineIndex++;
  }

  return (lineIndex: lineIndex, column: offset - source.lineOffsets[lineIndex]);
}

bool _isAllowedDateTimeExtensionCurrentBoundary(SourceScannerContext context, int offset) {
  if (!context.path.endsWith('/core/extensions/date_time_extensions.dart')) {
    return false;
  }

  final (:lineIndex, :column) = _lineColumnForOffset(context.source, offset);
  final line = context.source.masked[lineIndex];
  final call = _currentDateTimeCall.matchAsPrefix(line, column);
  if (call == null || !call.group(0)!.contains('timestamp')) return false;

  final start = lineIndex < 3 ? 0 : lineIndex - 3;
  final window = context.source.masked.sublist(start, lineIndex + 1).join('\n');
  return RegExp(
    r'\bstatic\s+DateTime\s+nowUtc\s*\(\s*\)\s*=>\s*DateTime\s*\.\s*timestamp\s*\(',
  ).hasMatch(window);
}

bool _isRawStringLiteralText(SourceScannerContext context, int offset) {
  final (:lineIndex, :column) = _lineColumnForOffset(context.source, offset);
  final line = context.source.code[lineIndex];
  for (var i = column - 1; i >= 0; i--) {
    final char = line[i];
    if (char != '\'' && char != '"') continue;

    var quoteStart = i;
    while (quoteStart > 0 && line[quoteStart - 1] == char) {
      quoteStart--;
    }

    final prefixIndex = quoteStart - 1;
    return prefixIndex >= 0 && (line[prefixIndex] == 'r' || line[prefixIndex] == 'R');
  }
  return false;
}

String? _previousNonWhitespace(String text, int beforeIndex) {
  for (var i = beforeIndex - 1; i >= 0; i--) {
    final char = text[i];
    if (char.trim().isNotEmpty) return char;
  }
  return null;
}

final _widgetSurface = RegExp(
  r'\bextends\s+(?:ConsumerWidget|ConsumerStatefulWidget|HookConsumerWidget|StatelessWidget|StatefulWidget|HookWidget|ConsumerState\b|HookConsumerState\b|State\s*<)',
);

final _topLevelFunction = RegExp(
  r'^\s*(?:Future(?:<[^;{=]+>)?|Stream(?:<[^;{=]+>)?|void|bool|int|double|num|String|Widget|[A-Z]\w*(?:<[^;{=]+>)?)\s+'
  r'(_?[A-Za-z_]\w*)\s*(?:<[^;{=]+>)?\s*\(',
);

final _awaitedNotifierResultStart = RegExp(
  r'\b(?:final|var|bool|int|double|num|String|[A-Za-z_]\w*(?:<[^;=]+>)?)\s+'
  r'\w+\s*=\s*await\b|\b(?:if|switch)\s*\(\s*await\b|\breturn\s+await\b',
);

final _notifierReadInWindow = RegExp(
  r'\bref\s*\.\s*read\s*\([\s\S]*?\.\s*notifier\s*\)\s*\.\s*[A-Za-z_]\w*\s*\(',
);

final _notifierThenInWindow = RegExp(
  r'\bref\s*\.\s*read\s*\([\s\S]*?\.\s*notifier\s*\)[\s\S]*?\.then\s*\(',
);

final _widgetLocalMutationFlagField = RegExp(
  r'^\s*bool\s+(_is(?:Saving|Submitting|Creating|Deleting|Importing|Exporting|Selecting|Continuing|Processing|Syncing))\b\s*=',
);

final _directNotifierMutationDispatch = RegExp(
  r'\bref\s*\.\s*read\s*\([\s\S]*?\.notifier\s*\)[\s\S]{0,180}?\.\s*'
  r'(?:save|create|update|delete|set|add|remove|import|export|submit|select|continue|start)[A-Za-z0-9_]*\s*\(',
);

final _notifierGetterDeclaration = RegExp(
  r'\b[A-Za-z_]\w*Notifier\s+get\s+(_[A-Za-z_]\w*)\s*=>\s*ref\s*\.\s*read\s*\([\s\S]*?\.notifier\s*\)',
);

final _collectionReturnHelper = RegExp(
  r'\b(?:List|Iterable|Map|Set)(?:\s*<[^;{]+>)?\s+_[A-Za-z_]\w*\s*\(',
);

final _anyCollectionReturnHelper = RegExp(
  r'\b(?:List|Iterable|Map|Set)(?:\s*<[^;{]+>)?\s+[A-Za-z_]\w*\s*\(',
);

final _collectionWork = RegExp(
  r'\.(?:where|map|sort|toList|firstWhere|indexWhere|fold|add|addAll)\s*\(',
);

final _topLevelCollectionVariable = RegExp(
  r'^\s*(?:final|var)\s+_?[A-Za-z_]\w*(?:\s*=\s*|(?:\s*<[^;=]+>)?\s*=)',
);

final _infraTypeName = RegExp(
  r'\b(?:BaseCacheManager|[A-Z]\w*(?:CacheManager|Client|Plugin|Storage|Repository|Datasource|DataSource|Service|Queue|Manager))\b',
);

final _widgetInfraNamedConstructorArg = RegExp(
  r'\b[A-Za-z_]\w*\s*:\s*(?:const\s+)?[A-Z]\w*(?:CacheManager|Client|Plugin|Storage|Repository|Datasource|DataSource|Service|Queue|Manager)\s*\(',
);

final _widgetInfraLocalConstructor = RegExp(
  r'\b(?:final|var)\s+[A-Za-z_]\w*\s*=\s*(?:const\s+)?[A-Z]\w*(?:CacheManager|Client|Plugin|Storage|Repository|Datasource|DataSource|Service|Queue|Manager)\s*\(',
);

int _topLevelFunctionColumn(String line) {
  if (RegExp(
    r'^\s*(?:class|mixin|enum|extension|typedef|sealed\s+class|abstract\s+class)\b',
  ).hasMatch(line)) {
    return -1;
  }
  final match = _topLevelFunction.firstMatch(line);
  if (match == null) return -1;
  final name = match.group(1) ?? '';
  if (name == 'build' || name == 'main') return -1;
  return match.start;
}

int _widgetInfraDependencyColumn(String line) {
  final namedArg = _widgetInfraNamedConstructorArg.firstMatch(line);
  if (namedArg != null) return namedArg.start;

  final localConstructor = _widgetInfraLocalConstructor.firstMatch(line);
  if (localConstructor != null) return localConstructor.start;

  final typeMatch = _infraTypeName.firstMatch(line);
  if (typeMatch == null) return -1;
  final before = line.substring(0, typeMatch.start);
  final after = line.substring(typeMatch.end);

  if (RegExp(r'^\s*(?:late\s+)?final\s+$').hasMatch(before) &&
      RegExp(r'(?:<[^;=]+>)?\??\s+[A-Za-z_]\w*\s*;').hasMatch(after)) {
    return typeMatch.start;
  }

  if (RegExp(r'[({,]\s*(?:required\s+)?(?:final\s+)?$').hasMatch(before) &&
      RegExp(r'(?:<[^;=]+>)?\??\s+[A-Za-z_]\w*[,)}]').hasMatch(after)) {
    return typeMatch.start;
  }

  return -1;
}

bool _isWidgetSurfaceClass(SourceScannerContext context, ScannerClassSpan classSpan) {
  final signature = _classSignature(context, classSpan);
  return _widgetSurface.hasMatch(signature);
}

bool _isWidgetDataHelperClass(ScannerClassSpan classSpan) => classSpan.name.endsWith('Data');

bool _classDispatchesNotifierMutation(SourceScannerContext context, ScannerClassSpan classSpan) {
  final body = context.source.masked.sublist(classSpan.start, classSpan.end + 1).join('\n');
  if (_directNotifierMutationDispatch.hasMatch(body)) return true;

  for (final match in _notifierGetterDeclaration.allMatches(body)) {
    final getterName = match.group(1);
    if (getterName == null) continue;
    final getterMutation = RegExp(
      r'\b' +
          RegExp.escape(getterName) +
          r'\s*\.\s*(?:save|create|update|delete|set|add|remove|import|export|submit|select|continue|start)[A-Za-z0-9_]*\s*\(',
    );
    if (getterMutation.hasMatch(body)) return true;
  }

  return false;
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

int? _awaitedNotifierResultColumn(SourceScannerContext context, int lineIndex, int methodEnd) {
  final line = context.source.masked[lineIndex];
  final start = _awaitedNotifierResultStart.firstMatch(line);
  if (start == null) return null;

  final window = _lineWindow(context, lineIndex, methodEnd, 8);
  if (!_notifierReadInWindow.hasMatch(window)) return null;
  final awaitColumn = line.indexOf('await');
  return awaitColumn >= 0 ? awaitColumn : start.start;
}

int _notifierThenResultColumn(SourceScannerContext context, int lineIndex, int methodEnd) {
  final line = context.source.masked[lineIndex];
  if (!line.contains('ref.read') && !line.contains('ref')) return -1;

  final window = _lineWindow(context, lineIndex, methodEnd, 12);
  if (!_notifierThenInWindow.hasMatch(window)) return -1;
  final refColumn = line.indexOf('ref.read');
  if (refColumn >= 0) return refColumn;
  return line.indexOf('ref');
}

bool _isCollectionHelper(
  SourceScannerContext context,
  ScannerMethodSpan method, {
  required bool requirePrivate,
}) {
  if (requirePrivate && !method.name.startsWith('_')) return false;
  final window = _lineWindow(context, method.start, method.end, 4).replaceAll('\n', ' ');
  final pattern = requirePrivate ? _collectionReturnHelper : _anyCollectionReturnHelper;
  return pattern.hasMatch(window);
}

bool _isTopLevelDerivedCollection(SourceScannerContext context, int lineIndex) {
  final line = context.source.masked[lineIndex];
  if (!_topLevelCollectionVariable.hasMatch(line)) return false;
  final window = _lineWindow(context, lineIndex, context.source.length - 1, 6);
  return _collectionWork.hasMatch(window);
}

int _firstNonWhitespaceColumn(String line) {
  for (var i = 0; i < line.length; i++) {
    if (line[i].trim().isNotEmpty) return i;
  }
  return 0;
}

String _lineWindow(SourceScannerContext context, int startLine, int endLine, int maxLines) {
  final end = startLine + maxLines > endLine ? endLine : startLine + maxLines;
  final buffer = StringBuffer();
  for (var i = startLine; i <= end && i < context.source.length; i++) {
    if (i > startLine) buffer.write('\n');
    buffer.write(context.source.masked[i]);
  }
  return buffer.toString();
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

    depth += _braceDelta(line);
    if (line.contains('{')) sawClassOpenBrace = true;
  }
}

int _braceDelta(String line) {
  var delta = 0;
  for (var i = 0; i < line.length; i++) {
    final char = line[i];
    if (char == '{') {
      delta++;
    } else if (char == '}') {
      delta--;
    }
  }
  return delta;
}

bool _buildContainsAppShell(SourceScannerContext context, ScannerMethodSpan method) {
  for (var i = method.start; i <= method.end; i++) {
    if (RegExp(
      r'\b(?:MaterialApp|CupertinoApp|WidgetsApp)(?:\.router)?\s*\(',
    ).hasMatch(context.source.masked[i])) {
      return true;
    }
  }
  return false;
}

int _refListenColumn(String line) =>
    RegExp(r'\bref\s*\.\s*listen\s*(?:<[^>]+>)?\s*\(').firstMatch(line)?.start ?? -1;
