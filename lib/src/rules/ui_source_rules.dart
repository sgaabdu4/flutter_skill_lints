import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';
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

/// Whether [offset] sits in a static member of an extension on dart:core
/// `DateTime`, the skill's `DateTimeX.nowUtc()`/`nowLocal()` owner
/// (primitive-formatting.md).
bool _isAllowedDateTimeExtensionCurrentBoundary(SourceScannerContext context, int offset) {
  return _dateTimeExtensions(context)
      .expand((extension) => extension.body.members)
      .whereType<MethodDeclaration>()
      .any((member) => member.isStatic && offset >= member.offset && offset < member.end);
}

/// Whether [offset] sits in an extension on dart:core `DateTime`, where the
/// skill keeps current-date windows.
bool _isInsideDateTimeExtension(SourceScannerContext context, int offset) {
  return _dateTimeExtensions(context)
      .any((extension) => offset >= extension.offset && offset < extension.end);
}

Iterable<ExtensionDeclaration> _dateTimeExtensions(SourceScannerContext context) {
  return context.unit.declarations.whereType<ExtensionDeclaration>().where(
    (extension) => _extendsCoreType(extension, const {'DateTime'}),
  );
}

/// Whether [extension] is on one of the dart:core [typeNames], the skill's
/// primitive owners in `core/extensions/` (primitive-formatting.md).
bool _extendsCoreType(ExtensionDeclaration? extension, Set<String> typeNames) {
  final type = extension?.declaredFragment?.element.extendedType;
  return type is InterfaceType &&
      type.element.library.isDartCore &&
      typeNames.contains(type.element.name);
}

const _coreNumTypes = {'num', 'int', 'double'};

/// intl formatters and the dart:core types whose extensions own them:
/// `DateTimeX.formatShortDate` and `NumX.asCurrency` (primitive-formatting.md).
const _intlFormatterOwners = {
  'DateFormat': {'DateTime'},
  'NumberFormat': _coreNumTypes,
};

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
  if (RegExp(r'^\s*(?:class|mixin|enum|extension|typedef|sealed\s+class|abstract\s+class)\b')
      .hasMatch(line)) {
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
  final signature = sourceClassSignature(context, classSpan);
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
      r'\b' + RegExp.escape(getterName) + r'\s*\.\s*(?:save|create|update|delete|set|add|remove|import|export|submit|select|continue|start)[A-Za-z0-9_]*\s*\(',
    );
    if (getterMutation.hasMatch(body)) return true;
  }

  return false;
}

int? _awaitedNotifierResultColumn(SourceScannerContext context, int lineIndex) {
  final line = context.source.masked[lineIndex];
  final start = _awaitedNotifierResultStart.firstMatch(line);
  if (start == null) return null;
  final awaitColumn = line.indexOf('await');
  if (awaitColumn < 0) return null;
  final offset = context.source.lineOffsets[lineIndex] + awaitColumn;
  AstNode? awaited = context.unit.nodeCovering(offset: offset);
  while (awaited != null && awaited is! AwaitExpression) {
    awaited = awaited.parent;
  }
  if (awaited is! AwaitExpression || awaited.expression is! MethodInvocation) return null;
  final invocation = awaited.expression as MethodInvocation;
  if (invocation.target == null || !_notifierReadInWindow.hasMatch(invocation.toSource())) {
    return null;
  }
  return awaitColumn;
}

int _notifierThenResultColumn(SourceScannerContext context, int lineIndex, int methodEnd) {
  final line = context.source.masked[lineIndex];
  if (!line.contains('ref.read') && !line.contains('ref')) return -1;

  final window = sourceLineWindow(context, lineIndex, methodEnd, 12);
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
  final window = sourceLineWindow(context, method.start, method.end, 4).replaceAll('\n', ' ');
  final pattern = requirePrivate ? _collectionReturnHelper : _anyCollectionReturnHelper;
  return pattern.hasMatch(window);
}

bool _isTopLevelDerivedCollection(SourceScannerContext context, int lineIndex) {
  final line = context.source.masked[lineIndex];
  if (!_topLevelCollectionVariable.hasMatch(line)) return false;
  final window = sourceLineWindow(context, lineIndex, context.source.length - 1, 6);
  return _collectionWork.hasMatch(window);
}

int _firstNonWhitespaceColumn(String line) {
  for (var i = 0; i < line.length; i++) {
    if (line[i].trim().isNotEmpty) return i;
  }
  return 0;
}

bool _buildContainsAppShell(SourceScannerContext context, ScannerMethodSpan method) {
  for (var i = method.start; i <= method.end; i++) {
    if (RegExp(r'\b(?:MaterialApp|CupertinoApp|WidgetsApp)(?:\.router)?\s*\(')
        .hasMatch(context.source.masked[i])) {
      return true;
    }
  }
  return false;
}

int _refListenColumn(String line) =>
    RegExp(r'\bref\s*\.\s*listen\s*(?:<[^>]+>)?\s*\(').firstMatch(line)?.start ?? -1;

final class _WidgetCatchVisitor extends RecursiveAstVisitor<void> {
  _WidgetCatchVisitor(this.reporter, this.context);

  final ScannerRuleReporter reporter;
  final SourceScannerContext context;

  @override
  void visitTryStatement(TryStatement node) {
    if (node.catchClauses.isNotEmpty) {
      _reportAtOffset(reporter, context, node.tryKeyword.offset);
    }
    super.visitTryStatement(node);
  }
}

/// Riverpod and state_notifier notifier bases. Riverpod 3 codegen notifiers
/// (`extends _$X`) reach AnyNotifier through `$Notifier`/`$AsyncNotifier`.
const _notifierChecker = TypeChecker.any([
  TypeChecker.fromName('AnyNotifier', packageName: 'riverpod'),
  TypeChecker.fromName('Notifier', packageName: 'riverpod'),
  TypeChecker.fromName('AsyncNotifier', packageName: 'riverpod'),
  TypeChecker.fromName('StreamNotifier', packageName: 'riverpod'),
  TypeChecker.fromName('StateNotifier', packageName: 'state_notifier'),
]);

/// Reports `SnackBarUtils.show...` calls from notifiers, repositories, and
/// datasources (context-ui.md: only the UI helper may wrap SnackBarUtils).
final class _SnackBarUtilsDispatchVisitor extends RecursiveAstVisitor<void> {
  _SnackBarUtilsDispatchVisitor(this.reporter, this.context);

  final ScannerRuleReporter reporter;
  final SourceScannerContext context;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final target = node.target;
    if (target is Identifier &&
        target.element is ClassElement &&
        target.name == 'SnackBarUtils' &&
        node.methodName.name.startsWith('show') &&
        (context.isDataPath || isEnclosedClassAssignableTo(node, _notifierChecker))) {
      _reportAtOffset(reporter, context, node.offset);
    }
    super.visitMethodInvocation(node);
  }
}

void _reportAtOffset(ScannerRuleReporter reporter, SourceScannerContext context, int offset) {
  final location = context.unit.lineInfo.getLocation(offset);
  reporter.report(context, location.lineNumber - 1, location.columnNumber - 1);
}

/// Reports intl `DateFormat`/`NumberFormat` construction outside the
/// dart:core primitive extension that owns it.
final class _AdHocIntlFormatVisitor extends RecursiveAstVisitor<void> {
  _AdHocIntlFormatVisitor(this.reporter, this.context);

  final ScannerRuleReporter reporter;
  final SourceScannerContext context;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final formatter = node.constructorName.element?.enclosingElement;
    final owners = _intlFormatterOwners[formatter?.name];
    if (formatter != null &&
        owners != null &&
        formatter.library.uri.toString().startsWith('package:intl/') &&
        !_extendsCoreType(node.thisOrAncestorOfType<ExtensionDeclaration>(), owners)) {
      _reportAtOffset(reporter, context, node.offset);
    }
    super.visitInstanceCreationExpression(node);
  }
}

/// Reports dart:core `num.clamp` calls outside an extension on num.
final class _InlineNumClampVisitor extends RecursiveAstVisitor<void> {
  _InlineNumClampVisitor(this.reporter, this.context);

  final ScannerRuleReporter reporter;
  final SourceScannerContext context;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final owner = node.methodName.element?.enclosingElement;
    if (node.methodName.name == 'clamp' &&
        owner is InterfaceElement &&
        owner.library.isDartCore &&
        _coreNumTypes.contains(owner.name) &&
        !_extendsCoreType(node.thisOrAncestorOfType<ExtensionDeclaration>(), _coreNumTypes)) {
      _reportAtOffset(reporter, context, node.methodName.offset);
    }
    super.visitMethodInvocation(node);
  }
}
