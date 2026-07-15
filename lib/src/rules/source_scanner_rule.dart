import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';
part 'source_scanner_rule/source_scanner_source.dart';

typedef ScannerRuleCallback =
    void Function(ScannerRuleReporter reporter, SourceScannerContext context);

/// ScannerRule enforces a Flutter skill lint contract.
///
/// Why: The analyzer rule keeps the corresponding Flutter skill guidance visible during
/// development. Follow the diagnostic correction for the reported Flutter skill requirement.
final class ScannerRule extends AnalysisRule {
  ScannerRule({
    required super.name,
    required super.description,
    required LintCode code,
    required ScannerRuleCallback scan,
  }) : _code = code,
       _scan = scan;

  @override
  LintCode get diagnosticCode => _code;

  final LintCode _code;
  final ScannerRuleCallback _scan;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (isGeneratedRuleContext(context)) return;
    registry.addCompilationUnit(this, _SourceScannerVisitor(this, context));
  }

  void scanContext(RuleContext context) {
    _scan(ScannerRuleReporter._(this), SourceScannerContext.fromRuleContext(context));
  }
}

ScannerRule scannerRule({
  required LintCode code,
  required String description,
  required ScannerRuleCallback scan,
}) => ScannerRule(name: code.lowerCaseName, description: description, code: code, scan: scan);

final class ScannerRuleReporter {
  const ScannerRuleReporter._(this._rule);

  final ScannerRule _rule;

  void report(SourceScannerContext context, int lineIndex, int column) {
    final source = context.source;
    final safeLine = lineIndex.clamp(0, source.length - 1);
    final safeColumn = column < 0 ? 0 : column;
    final lineLength = source.original[safeLine].length;
    final offset = source.lineOffsets[safeLine] + safeColumn.clamp(0, lineLength);
    final length = lineLength == 0 ? 1 : (lineLength - safeColumn).clamp(1, lineLength);
    _rule.reportAtOffset(offset, length);
  }
}

final class _SourceScannerVisitor extends SimpleAstVisitor<void> {
  _SourceScannerVisitor(this.rule, this.ruleContext);

  final ScannerRule rule;
  final RuleContext ruleContext;

  @override
  void visitCompilationUnit(CompilationUnit node) {
    rule.scanContext(ruleContext);
  }
}

final class SourceScannerContext {
  SourceScannerContext._({
    required this.path,
    required this.source,
    required this.classes,
    required this.methods,
  });

  factory SourceScannerContext.fromRuleContext(RuleContext context) {
    final unit = context.currentUnit ?? context.definingUnit;
    final cached = _contextCache[unit];
    if (cached != null) return cached;

    final scannerContext = SourceScannerContext._fromUnit(unit);
    _contextCache[unit] = scannerContext;
    return scannerContext;
  }

  factory SourceScannerContext._fromUnit(RuleContextUnit unit) {
    final source = SourceScannerSource(unit.content);
    final classes = _classes(source);
    final methods = <ScannerMethodSpan>[];
    for (final classSpan in classes) {
      methods.addAll(_methods(source, classSpan));
    }

    return SourceScannerContext._(
      path: _relativePath(unit.file.path),
      source: source,
      classes: classes,
      methods: methods,
    );
  }

  static final Expando<SourceScannerContext> _contextCache = Expando<SourceScannerContext>(
    'flutter_skill_lints_source_scanner_context',
  );

  final String path;
  final SourceScannerSource source;
  final List<ScannerClassSpan> classes;
  final List<ScannerMethodSpan> methods;

  bool isRedirectWatch(int lineIndex) =>
      source.masked[lineIndex].contains('ref.watch(') && near(lineIndex, 'redirect:', 12);

  bool isRedirectLoadingBounce(int lineIndex, String code) {
    if (!near(lineIndex, 'redirect:', 12)) return false;
    if (!RegExp(r'''return\s+['"][^'"]*(?:splash|loading|home|/)''').hasMatch(code)) {
      return false;
    }
    return near(lineIndex, 'isLoading', 8) || near(lineIndex, 'loading', 8);
  }

  bool isInitStateRead(int lineIndex) =>
      source.masked[lineIndex].contains('ref.read(') && near(lineIndex, 'initState', 8);

  bool hasStringNavigation(String code, String masked) {
    return stringNavigationColumn(code, masked) != null;
  }

  int? stringNavigationColumn(String code, String masked) {
    final patterns = [
      RegExp(
        r'''\bcontext\s*\.\s*(?:go|push|replace|pushReplacement)\s*(?:<[^>]+>)?\s*\(\s*r?['"]''',
      ),
      RegExp(r'''\bcontext\s*\.\s*(?:goNamed|pushNamed|replaceNamed)\s*(?:<[^>]+>)?\s*\('''),
      RegExp(
        r'''\bGoRouter\s*\.\s*of\s*\([^)]*\)\s*\.\s*(?:go|push|replace|pushReplacement)\s*(?:<[^>]+>)?\s*\(\s*r?['"]''',
      ),
      RegExp(
        r'''\bGoRouter\s*\.\s*of\s*\([^)]*\)\s*\.\s*(?:goNamed|pushNamed|replaceNamed)\s*(?:<[^>]+>)?\s*\(''',
      ),
      RegExp(
        r'''\b(?:_?router|[A-Za-z_]\w*Router\w*)\s*\.\s*(?:go|push|replace|pushReplacement)\s*(?:<[^>]+>)?\s*\(\s*r?['"]''',
      ),
      RegExp(
        r'''\b(?:_?router|[A-Za-z_]\w*Router\w*)\s*\.\s*(?:goNamed|pushNamed|replaceNamed)\s*(?:<[^>]+>)?\s*\(''',
      ),
      RegExp(r'''\binitialLocation\s*:\s*r?['"]'''),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(code);
      if (match == null) continue;
      if (match.start >= masked.length) return null;
      if (masked.substring(match.start, match.end).trim().isNotEmpty) {
        return match.start;
      }
    }
    return null;
  }

  bool hasHardcodedUiString(String code) {
    if (path.endsWith('_strings.dart') || path.contains('/l10n/')) return false;
    if (isTestFile) return false;
    return RegExp(r'''\b(?:Text|Tooltip|Semantics)\s*\(\s*['"][^'"]+['"]''').hasMatch(code) ||
        RegExp(
          r'''\b(?:title|label|tooltip|hintText|helperText|errorText)\s*:\s*['"][^'"]+['"]''',
        ).hasMatch(code);
  }

  int? directContextL10nColumn(int lineIndex) {
    if (path.contains('/l10n/') || isTestFile) return null;

    final line = source.masked[lineIndex];
    final sameLine = RegExp(r'\bcontext\s*\.\s*l10n\s*\.').firstMatch(line);
    if (sameLine != null) return sameLine.start;

    final l10nEndLine = RegExp(r'\bcontext\s*\.\s*l10n\s*$').firstMatch(line);
    if (l10nEndLine != null && _nextCodeLineStartsWith(lineIndex, RegExp(r'^\s*\.\s*\w'))) {
      return l10nEndLine.start;
    }

    if (!RegExp(r'\bcontext\s*$').hasMatch(line)) return null;

    final nextIndex = _nextCodeLineIndex(lineIndex);
    if (nextIndex == null) return null;

    final nextLine = source.masked[nextIndex];
    if (RegExp(r'^\s*\.\s*l10n\s*\.').hasMatch(nextLine)) return line.indexOf('context');
    if (RegExp(r'^\s*\.\s*l10n\s*$').hasMatch(nextLine) &&
        _nextCodeLineStartsWith(nextIndex, RegExp(r'^\s*\.\s*\w'))) {
      return line.indexOf('context');
    }

    return null;
  }

  bool isMutableMixinField(int lineIndex) {
    final line = source.masked[lineIndex];
    final fieldMatch = RegExp(
      r'^\s*(?!final\b)(?!const\b)(?:late\s+)?(?:var|int|double|num|bool|String|Object|List|Map|Set|[A-Z]\w*(?:<[^;=]+>)?\??)\s+([A-Za-z_]\w*)\b[^;=]*=',
    ).firstMatch(line);
    if (fieldMatch == null) {
      return false;
    }
    if (!near(lineIndex, 'mixin ', 16)) {
      return false;
    }
    final mixin = _enclosingMixin(lineIndex);
    if (mixin == null || !_isDirectMixinMember(mixin, lineIndex)) {
      return false;
    }

    final fieldName = fieldMatch.group(1) ?? '';
    if (fieldName.startsWith('_') && _isStateLifecycleMixin(mixin.signature)) {
      return false;
    }

    return true;
  }

  bool isMapDynamicReturn(String line) {
    if (isDataPath) return false;
    if (RegExp(r'\b(?:toJson|fromJson|toMap)\s*\(').hasMatch(line) ||
        line.contains('RequestBody')) {
      return false;
    }
    return RegExp(r'\bMap\s*<\s*String\s*,\s*dynamic\s*>\s+\w+\s*\(').hasMatch(line);
  }

  bool dispatchesSnackbarFromUi(String line) =>
      line.contains('ScaffoldMessenger.of(') ||
      line.contains('ScaffoldMessenger.maybeOf(') ||
      line.contains('SnackBarUtils.show');

  bool clampsTextScaling(String line) =>
      line.contains('withClampedTextScaling') ||
      line.contains('maxScaleFactor') ||
      line.contains('textScaleFactor:') ||
      line.contains('TextScaler.linear(1');

  bool hasConcreteLayerClass() {
    for (final line in source.masked) {
      if (RegExp(r'\bclass\s+\w+(?:Repository|Datasource)\b').hasMatch(line)) {
        return true;
      }
    }
    return false;
  }

  bool hasConcreteLayerDependencyLine(String line) {
    if (RegExp(r'^\s*(?:abstract\s+interface\s+)?class\b').hasMatch(line)) {
      return false;
    }
    if (RegExp(
      r'\b(?:final\s+)?(?!I)[A-Z]\w*(?:Repository|Datasource)\s+_\w+\s*;',
    ).hasMatch(line)) {
      return true;
    }
    if (RegExp(r'[(,]\s*(?!I)[A-Z]\w*(?:Repository|Datasource)\s+\w+').hasMatch(line)) {
      return true;
    }
    return false;
  }

  bool isPrivateNamespaceConstructor(ScannerClassSpan classSpan) {
    final text = source.masked.sublist(classSpan.start, classSpan.end + 1).join('\n');
    final annotationStart = classSpan.start - 3 < 0 ? 0 : classSpan.start - 3;
    final leadingText = source.masked.sublist(annotationStart, classSpan.start + 1).join('\n');
    if (leadingText.contains('@freezed') || leadingText.contains('@Freezed')) return false;
    if (!RegExp('${classSpan.name}._\\s*\\(\\s*\\)\\s*;').hasMatch(text)) return false;
    return !RegExp(r'\babstract\s+final\s+class\b').hasMatch(source.masked[classSpan.start]);
  }

  bool requiresFreezedValueClass(ScannerClassSpan classSpan) {
    if (isTestFile) return false;
    if (classSpan.name.startsWith('_') || classSpan.isNotifier) return false;
    if (_isAbstractInterfaceClass(classSpan)) return false;
    if (_isGeneratedOrPartOfFile) return false;
    if (isDomainPath) return true;
    return isDataModelPath || (isDataPath && classSpan.name.endsWith('Model'));
  }

  bool hasFreezedAnnotation(ScannerClassSpan classSpan) {
    final start = classSpan.start - 8 < 0 ? 0 : classSpan.start - 8;
    for (var i = classSpan.start - 1; i >= start; i--) {
      final line = source.masked[i].trim();
      if (line.isEmpty) continue;
      if (line.startsWith('@freezed') || line.startsWith('@Freezed')) return true;
      if (!line.startsWith('@')) break;
    }
    return false;
  }

  bool hasNearbyAnnotation(int lineIndex, Set<String> names) {
    final start = lineIndex - 8 < 0 ? 0 : lineIndex - 8;
    for (var i = lineIndex - 1; i >= start; i--) {
      final line = source.masked[i].trim();
      if (line.isEmpty) continue;
      if (!line.startsWith('@')) break;
      for (final name in names) {
        if (RegExp('^@${RegExp.escape(name)}\\b').hasMatch(line)) return true;
      }
    }
    return false;
  }

  bool hasImmediateGuard(int awaitLine, int methodEnd, String target) {
    for (var i = awaitLine + 1; i <= methodEnd && i < source.length; i++) {
      final line = source.masked[i].trim();
      if (line.isEmpty) continue;
      return line.contains('if (!$target.mounted)') && line.contains('return');
    }
    return false;
  }

  int firstLine(String needle) {
    for (var i = 0; i < source.length; i++) {
      if (source.masked[i].contains(needle)) return i;
    }
    return 0;
  }

  bool near(int lineIndex, String needle, int distance) {
    final start = lineIndex - distance < 0 ? 0 : lineIndex - distance;
    final end = lineIndex + distance >= source.length ? source.length - 1 : lineIndex + distance;
    for (var i = start; i <= end; i++) {
      if (source.masked[i].contains(needle)) return true;
    }
    return false;
  }

  bool nearOriginal(int lineIndex, RegExp pattern, int distance) {
    final start = lineIndex - distance < 0 ? 0 : lineIndex - distance;
    final end = lineIndex + distance >= source.length ? source.length - 1 : lineIndex + distance;
    for (var i = start; i <= end; i++) {
      if (pattern.hasMatch(source.original[i])) return true;
    }
    return false;
  }

  bool isMutationMethod(String name) =>
      RegExp(r'^(?:create|update|delete|set|reorder|save|add|remove)[A-Z_]?').hasMatch(name);

  int? _nextCodeLineIndex(int lineIndex) {
    for (var i = lineIndex + 1; i < source.length; i++) {
      if (source.masked[i].trim().isNotEmpty) return i;
    }
    return null;
  }

  bool _nextCodeLineStartsWith(int lineIndex, RegExp pattern) {
    final nextIndex = _nextCodeLineIndex(lineIndex);
    return nextIndex != null && pattern.hasMatch(source.masked[nextIndex]);
  }

  bool get isDataPath => path.contains('/data/') || path.contains('/repositories/');
  bool get isDatasourcePath => path.contains('/data/datasources/');
  bool get isDataModelPath => path.contains('/data/models/') || path.contains('/data/model/');
  bool get isRepositoryPath => path.contains('/repositories/');
  bool get isDomainPath => path.contains('/domain/');

  bool get isFeatureWidgetWrongPath =>
      !isTestFile &&
      path.contains('/features/') &&
      path.contains('/widgets/') &&
      !path.contains('/presentation/widgets/');

  bool get isAtomicNoProviderPath =>
      path.contains('/core/widgets/atoms/') ||
      path.contains('/core/widgets/molecules/') ||
      path.contains('/core/widgets/templates/');

  bool get isPresentationWidgetFile {
    final normalized = path.replaceAll('\\', '/');
    return normalized.startsWith('lib/') && normalized.contains('/presentation/widgets/');
  }

  bool get isUiFile {
    final normalized = path.replaceAll('\\', '/');
    return normalized.startsWith('lib/core/widgets/') ||
        normalized.startsWith('lib/core/dialogs/') ||
        normalized.startsWith('lib/core/sheets/') ||
        normalized.contains('/presentation/widgets/') ||
        normalized.contains('/presentation/screens/') ||
        normalized.contains('/presentation/dialogs/') ||
        normalized.contains('/presentation/sheets/');
  }

  bool get isAppRootFile {
    final normalized = path.replaceAll('\\', '/');
    return normalized == 'lib/main.dart' ||
        normalized == 'lib/app.dart' ||
        normalized.endsWith('/app.dart') ||
        normalized.endsWith('/app_root.dart');
  }

  bool get isTestFile => path.startsWith('test/') || path.endsWith('_test.dart');

  bool get isThemeDefFile =>
      path.contains('/core/theme/') ||
      path.endsWith('_tokens.dart') ||
      path.endsWith('_theme.dart');

  bool get isKeyRegistryFile {
    final normalized = path.replaceAll('\\', '/').toLowerCase();
    return normalized.endsWith('/app_widget_keys.dart') ||
        normalized.endsWith('/widget_keys.dart') ||
        normalized.endsWith('/e2e_keys.dart') ||
        normalized.endsWith('/app_keys.dart') ||
        normalized.endsWith('/test_keys.dart') ||
        normalized.endsWith('_keys.dart') ||
        normalized.endsWith('/keys.dart');
  }

  bool get _isGeneratedOrPartOfFile {
    final normalized = path.replaceAll('\\', '/');
    if (normalized.endsWith('.g.dart') || normalized.endsWith('.freezed.dart')) return true;
    return source.masked.any((line) => RegExp(r'^\s*part\s+of\b').hasMatch(line));
  }

  bool _isAbstractInterfaceClass(ScannerClassSpan classSpan) {
    final line = source.masked[classSpan.start];
    return RegExp(r'\babstract\s+interface\s+class\b').hasMatch(line);
  }

  _ScannerMixinSpan? _enclosingMixin(int lineIndex) {
    for (var start = lineIndex; start >= 0; start--) {
      final line = source.masked[start];
      if (!RegExp(r'^\s*mixin(?:\s+class)?\s+\w+\b').hasMatch(line)) continue;

      final signature = StringBuffer(line);
      var openBraceLine = start;
      var foundOpenBrace = line.contains('{');
      while (!foundOpenBrace && openBraceLine + 1 < source.length) {
        openBraceLine++;
        signature.write(' ${source.masked[openBraceLine]}');
        foundOpenBrace = source.masked[openBraceLine].contains('{');
      }
      if (!foundOpenBrace || lineIndex < openBraceLine) return null;

      var depth = 0;
      var end = openBraceLine;
      for (var i = start; i < source.length; i++) {
        depth += _braceDelta(source.masked[i]);
        if (i >= openBraceLine && depth <= 0) {
          end = i;
          break;
        }
      }
      if (lineIndex <= end) {
        return _ScannerMixinSpan(start: start, end: end, signature: signature.toString());
      }
    }
    return null;
  }

  bool _isDirectMixinMember(_ScannerMixinSpan mixin, int lineIndex) {
    var depth = 0;
    for (var i = mixin.start; i < lineIndex; i++) {
      depth += _braceDelta(source.masked[i]);
    }
    return depth == 1;
  }

  bool _isStateLifecycleMixin(String signature) =>
      RegExp(r'\bon\s+(?:\w+\.)?(?:State|ConsumerState|HookConsumerState)\b').hasMatch(signature);

  static List<ScannerClassSpan> _classes(SourceScannerSource source) {
    final classes = <ScannerClassSpan>[];
    for (var i = 0; i < source.length; i++) {
      final line = source.masked[i];
      final match = RegExp(r'\bclass\s+([A-Za-z_][A-Za-z0-9_]*)\b').firstMatch(line);
      if (match == null) continue;

      final name = match.group(1) ?? '';
      final signature = StringBuffer(line);
      var start = i;
      var braceDepth = _braceDelta(line);
      var foundOpenBrace = line.contains('{');

      while (!foundOpenBrace && start + 1 < source.length) {
        start++;
        signature.write(' ${source.masked[start]}');
        foundOpenBrace = source.masked[start].contains('{');
        braceDepth += _braceDelta(source.masked[start]);
      }

      var end = start;
      while (foundOpenBrace && braceDepth > 0 && end + 1 < source.length) {
        end++;
        braceDepth += _braceDelta(source.masked[end]);
      }

      final sig = signature.toString();
      classes.add(
        ScannerClassSpan(
          name: name,
          start: i,
          end: end,
          isNotifier:
              name.endsWith('Notifier') ||
              sig.contains(r'extends _$') ||
              sig.contains('extends Notifier') ||
              sig.contains('extends AsyncNotifier'),
        ),
      );
      i = end;
    }
    return classes;
  }

  static List<ScannerMethodSpan> _methods(SourceScannerSource source, ScannerClassSpan classSpan) {
    final methods = <ScannerMethodSpan>[];
    final methodRegex = RegExp(
      r'^\s*(?:@override\s+)?(?:static\s+)?(?:Future(?:<[^>]+>)?|Stream(?:<[^>]+>)?|void|[A-Za-z_][A-Za-z0-9_<>,? ]*)\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(',
    );

    for (var i = classSpan.start + 1; i < classSpan.end; i++) {
      final line = source.masked[i];
      if (line.contains('factory ')) continue;
      final match = methodRegex.firstMatch(line);
      if (match == null) continue;
      final name = match.group(1) ?? '';
      if (_isControlKeyword(name)) continue;

      if (line.contains('=>')) {
        methods.add(ScannerMethodSpan(name: name, start: i, end: i));
        continue;
      }

      var start = i;
      var foundOpenBrace = line.contains('{');
      var braceDepth = _braceDelta(line);
      while (!foundOpenBrace && start + 1 < classSpan.end) {
        start++;
        foundOpenBrace = source.masked[start].contains('{');
        braceDepth += _braceDelta(source.masked[start]);
      }
      if (!foundOpenBrace) continue;

      var end = start;
      while (braceDepth > 0 && end + 1 <= classSpan.end) {
        end++;
        braceDepth += _braceDelta(source.masked[end]);
      }

      methods.add(ScannerMethodSpan(name: name, start: i, end: end));
      i = end;
    }
    return methods;
  }

  static bool _isControlKeyword(String name) =>
      name == 'if' || name == 'for' || name == 'while' || name == 'switch' || name == 'catch';

  static int _braceDelta(String line) => _count(line, '{') - _count(line, '}');

  static int _count(String text, String char) {
    var count = 0;
    for (var i = 0; i < text.length; i++) {
      if (text[i] == char) count++;
    }
    return count;
  }

  static String _relativePath(String path) {
    final normalized = path.replaceAll('\\', '/');
    for (final marker in ['/lib/', '/test/']) {
      final index = normalized.lastIndexOf(marker);
      if (index >= 0) return normalized.substring(index + 1);
    }
    return normalized;
  }
}
