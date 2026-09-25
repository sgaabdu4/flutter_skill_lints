import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/rules/source_scanner_rule.dart';

/// Rules enforcing Hive CE persistence-layer boundary integrity.
///
/// Why: `hive_ce` infers `HiveField(N)` indexes from Freezed constructor
/// parameter order, and the binary box format is locked once shipped.
/// Wrapping a primitive Model field in a Value Object regenerates the
/// adapter — old user box bytes become unreadable. Reordering params
/// silently shifts every subsequent slot. `dart analyze` cannot see disk;
/// these rules surface the risk at code-review time.
String _pascalCase(String snake) => snake
    .split('_')
    .where((p) => p.isNotEmpty)
    .map((p) => p[0].toUpperCase() + p.substring(1))
    .join();

final List<ScannerRule> hivePersistenceSourceRules = [
  /// Persisted maps must validate their runtime key shape before decoding.
  ///
  /// Why: Hive and other local stores restore maps with runtime key types. A
  /// direct generic cast can fail after an app restart even when the original
  /// write used string keys. Validate the raw map and copy it into a typed map
  /// before passing it to a model decoder.
  scannerRule(
    code: const LintCode(
      'avoid_unvalidated_persisted_map_cast',
      'Do not cast persisted values directly to Map<String, dynamic>.',
      correctionMessage: 'Check the value is a map, validate every key is a String, and create a typed map before decoding it.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags direct Map<String, dynamic> casts in libraries that use Hive, unless the cast value comes from JSON decoding.',
    scan: (reporter, context) {
      if (context.isTestFile || !context.path.startsWith('lib/')) return;
      final visitor = _PersistedMapCastVisitor();
      context.unit.accept(visitor);
      if (!visitor.usesHive) return;
      for (final cast in visitor.casts) {
        if (_comesFromJsonDecode(context.unit, cast.expression, 0)) continue;
        final location = context.unit.lineInfo.getLocation(cast.asOperator.offset);
        reporter.report(context, location.lineNumber - 1, location.columnNumber - 1);
      }
    },
  ),

  /// Flutter app source should import Hive through hive_ce_flutter.
  ///
  /// Why: `hive_ce_flutter` is the Flutter-facing package for Hive CE. It
  /// re-exports the core Hive API and adds Flutter helpers such as
  /// `Hive.initFlutter`, Color/TimeOfDay adapters, and platform setup. Keeping
  /// production Flutter code on that import surface prevents an app from
  /// depending on the core Dart package while bypassing the Flutter integration
  /// package declared in the stack. Tests can still use temp directories and
  /// manual `Hive.init(path)` setup.
  scannerRule(
    code: const LintCode(
      'use_hive_ce_flutter_import',
      'Flutter app source must import Hive CE through hive_ce_flutter.',
      correctionMessage:
          'Replace `package:hive_ce/hive_ce.dart` with '
          '`package:hive_ce_flutter/hive_ce_flutter.dart` in production Flutter source. '
          'Use manual `Hive.init(path)` only for explicit custom paths or test temp boxes.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags direct hive_ce imports in production Flutter lib/ files so apps use the Flutter package surface.',
    scan: (reporter, context) {
      if (context.isTestFile || !context.path.startsWith('lib/')) return;
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.code[i];
        final match = RegExp(r'''^\s*import\s+['"]package:hive_ce/hive_ce\.dart['"]''')
            .firstMatch(line);
        if (match != null) reporter.report(context, i, match.start);
      }
    },
  ),

  /// Hive Models must not carry Value Object types.
  ///
  /// Why: `/data/models/` classes are persistence-layer adapters; their
  /// constructor parameters become `HiveField(N)` slots on disk. Value
  /// Objects (`Distance`, `Money`, `Email`, …) belong in `/domain/` and
  /// require their own adapters to serialize. Keep primitive slots on the
  /// Model; expose VOs on the domain Entity via `Model.toEntity()`.
  scannerRule(
    code: const LintCode(
      'hive_field_no_vo_type',
      'Hive Models must not carry Value Object types.',
      correctionMessage:
          'Persistence Models in /data/models/ hold primitives. Move the VO field to the '
          'matching domain Entity and convert in the mapper '
          '(`Distance.fromMeters(distanceMeters)`). See building-flutter-apps '
          'references/hive-persistence.md (VO Interop).',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags VO-typed constructor parameters on Hive Model classes so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      if (!context.path.contains('/data/models/') && !context.path.contains('/data/model/')) {
        return;
      }
      final imported = _importedValueObjectNames(context);
      _reportValueObjectFields(reporter, context, imported);
    },
  ),
];

Set<String> _importedValueObjectNames(SourceScannerContext context) {
  const baseline = {
    'Distance',
    'Money',
    'Email',
    'Slug',
    'PhoneNumber',
    'HeartRate',
    'Weight',
    'Pace',
    'Username',
  };
  final imported = <String>{...baseline};
  final importPattern = RegExp(
    r'''^\s*import\s+['"][^'"]*?/domain/values/([a-z_][a-z0-9_]*)\.dart['"]([^;]*);''',
  );
  final showClausePattern = RegExp(r'\bshow\s+([A-Za-z_][\w,\s]*)');
  for (var i = 0; i < context.source.length; i++) {
    _addImportedValueObjects(
      imported,
      context.source.original[i],
      importPattern,
      showClausePattern,
    );
  }
  return imported;
}

void _addImportedValueObjects(
  Set<String> imported,
  String line,
  RegExp importPattern,
  RegExp showClausePattern,
) {
  final match = importPattern.firstMatch(line);
  if (match == null) return;
  imported.add(_pascalCase(match.group(1)!));
  final showMatch = showClausePattern.firstMatch(match.group(2) ?? '');
  if (showMatch == null) return;
  for (final name in showMatch.group(1)!.split(',')) {
    final trimmed = name.trim();
    if (trimmed.isNotEmpty) imported.add(trimmed);
  }
}

void _reportValueObjectFields(
  ScannerRuleReporter reporter,
  SourceScannerContext context,
  Set<String> imported,
) {
  final voUnion = imported.map(RegExp.escape).join('|');
  final voPattern = RegExp(r'\b(' + voUnion + r')\b');
  for (final classSpan in context.classes) {
    if (context.hasFreezedAnnotation(classSpan)) {
      _reportValueObjectClass(reporter, context, classSpan, voPattern);
    }
  }
}

void _reportValueObjectClass(
  ScannerRuleReporter reporter,
  SourceScannerContext context,
  ScannerClassSpan classSpan,
  RegExp voPattern,
) {
  var inFactory = false;
  for (var i = classSpan.start; i <= classSpan.end; i++) {
    final line = context.source.masked[i];
    if (line.contains('factory ${classSpan.name}') && line.contains('(')) {
      inFactory = true;
    }
    if (!inFactory) continue;
    if (line.trim().startsWith('///')) {
      if (line.contains(') = _') || line.contains(');')) inFactory = false;
      continue;
    }
    _reportValueObjectLine(reporter, context, i, line, voPattern);
    if (line.contains(') = _') || line.contains(');')) inFactory = false;
  }
}

void _reportValueObjectLine(
  ScannerRuleReporter reporter,
  SourceScannerContext context,
  int lineIndex,
  String line,
  RegExp voPattern,
) {
  final match = voPattern.firstMatch(line);
  if (match != null) reporter.report(context, lineIndex, match.start);
}

const _hivePackages = {'hive', 'hive_ce', 'hive_flutter', 'hive_ce_flutter'};

final class _PersistedMapCastVisitor extends RecursiveAstVisitor<void> {
  final List<AsExpression> casts = [];
  bool usesHive = false;

  @override
  void visitAsExpression(AsExpression node) {
    if (_isStringDynamicMap(node.type.type)) casts.add(node);
    super.visitAsExpression(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (!usesHive && _isFromPackages(node.element, _hivePackages)) usesHive = true;
    super.visitSimpleIdentifier(node);
  }

  @override
  void visitNamedType(NamedType node) {
    if (!usesHive && _isFromPackages(node.element, _hivePackages)) usesHive = true;
    super.visitNamedType(node);
  }
}

bool _isStringDynamicMap(DartType? type) {
  if (type is! InterfaceType || !type.isDartCoreMap || type.typeArguments.length != 2) {
    return false;
  }
  return type.typeArguments[0].isDartCoreString && type.typeArguments[1] is DynamicType;
}

bool _isFromPackages(Element? element, Set<String> packages) {
  final uri = element?.library?.uri;
  return uri != null &&
      uri.scheme == 'package' &&
      uri.pathSegments.isNotEmpty &&
      packages.contains(uri.pathSegments.first);
}

/// Whether [expression] is, or is read from, the result of `dart:convert` JSON decoding.
bool _comesFromJsonDecode(CompilationUnit unit, Expression expression, int depth) {
  if (depth > 8) return false;
  final value = expression.unParenthesized;
  switch (value) {
    case AwaitExpression(:final expression):
      return _comesFromJsonDecode(unit, expression, depth + 1);
    case IndexExpression(:final realTarget):
      return _comesFromJsonDecode(unit, realTarget, depth + 1);
    case MethodInvocation(:final methodName):
      return _isJsonDecodeElement(methodName.element);
    case SimpleIdentifier(:final element):
      final source = _localValueSource(unit, element);
      return source != null && _comesFromJsonDecode(unit, source, depth + 1);
    default:
      return false;
  }
}

bool _isJsonDecodeElement(Element? element) {
  if (element?.library?.uri.toString() != 'dart:convert') return false;
  final name = element?.name;
  if (element is TopLevelFunctionElement) return name == 'jsonDecode';
  if (element is MethodElement) {
    final owner = element.enclosingElement?.name;
    return (owner == 'JsonCodec' && name == 'decode') ||
        (owner == 'JsonDecoder' && name == 'convert');
  }
  return false;
}

/// The expression a local variable or pattern variable takes its value from.
Expression? _localValueSource(CompilationUnit unit, Element? element) {
  if (element is! LocalVariableElement && element is! PatternVariableElement) return null;
  final offset = element?.firstFragment.nameOffset;
  if (offset == null) return null;
  AstNode? node = unit.nodeCovering(offset: offset);
  while (node != null) {
    switch (node) {
      case VariableDeclaration(:final initializer?):
        return initializer;
      case ForEachPartsWithDeclaration(:final iterable):
        return iterable;
      case PatternVariableDeclaration(:final expression):
        return expression;
      case SwitchExpression(:final expression):
        return expression;
      case SwitchStatement(:final expression):
        return expression;
      case IfStatement(:final expression, caseClause: _?):
        return expression;
      case IfElement(:final expression, caseClause: _?):
        return expression;
      case FunctionBody():
        return null;
    }
    node = node.parent;
  }
  return null;
}
