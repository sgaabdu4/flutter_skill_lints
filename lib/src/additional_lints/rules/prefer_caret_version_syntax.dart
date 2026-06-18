import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';

/// Warns when a pubspec dependency can use equivalent caret syntax.
final class PreferCaretVersionSyntax extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_caret_version_syntax',
    'Prefer caret syntax for compatible pub dependency ranges.',
    correctionMessage: 'Replace this range with the equivalent ^version constraint.',
  );

  PreferCaretVersionSyntax()
    : super(
        name: 'prefer_caret_version_syntax',
        description: 'Warns when pubspec dependency ranges can use caret syntax.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final root = context.package?.root;
    if (root == null || !_isAnchorUnit(root, context)) return;

    final text = _read(root.getChildAssumingFile('pubspec.yaml'));
    if (text == null || !_hasCaretConvertibleRange(text)) return;

    registry.addCompilationUnit(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final PreferCaretVersionSyntax rule;

  @override
  void visitCompilationUnit(CompilationUnit node) {
    rule.reportAtToken(node.beginToken);
  }
}

bool _hasCaretConvertibleRange(String text) {
  const packageSections = ['dependencies', 'dev_dependencies', 'dependency_overrides'];
  for (final section in packageSections) {
    for (final value in _sectionScalarValues(text, section)) {
      if (_isCaretEquivalent(value)) return true;
    }
  }

  return false;
}

Iterable<String> _sectionScalarValues(String text, String section) sync* {
  final lines = text.split('\n');
  var inSection = false;
  var sectionIndent = 0;

  for (final line in lines) {
    if (line.trim().isEmpty || line.trimLeft().startsWith('#')) continue;
    final indent = line.length - line.trimLeft().length;
    final sectionMatch = RegExp('^\\s*${RegExp.escape(section)}\\s*:(.*)\$').firstMatch(line);
    if (sectionMatch != null) {
      sectionIndent = indent;
      inSection = (sectionMatch.group(1) ?? '').trim().isEmpty;
      continue;
    }
    if (!inSection) continue;
    if (indent <= sectionIndent) {
      inSection = false;
      continue;
    }
    if (indent != sectionIndent + 2) continue;

    final match = RegExp(
      r'''^\s*['"]?[A-Za-z_][\w-]*['"]?\s*:\s*(.+?)\s*(?:#.*)?$''',
    ).firstMatch(line);
    final value = match?.group(1)?.trim();
    if (value == null || value.isEmpty || value == '{}') continue;
    if (value.startsWith('{')) continue;
    yield _unquote(value);
  }
}

bool _isCaretEquivalent(String value) {
  final match = RegExp(r'^>=\s*(\d+)\.(\d+)\.(\d+)\s+<\s*(\d+)\.(\d+)\.(\d+)$').firstMatch(value);
  if (match == null) return false;

  final lower = _Version(
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
    int.parse(match.group(3)!),
  );
  final upper = _Version(
    int.parse(match.group(4)!),
    int.parse(match.group(5)!),
    int.parse(match.group(6)!),
  );

  return upper == lower.caretUpperBound;
}

final class _Version {
  const _Version(this.major, this.minor, this.patch);

  final int major;
  final int minor;
  final int patch;

  _Version get caretUpperBound {
    if (major > 0) return _Version(major + 1, 0, 0);
    if (minor > 0) return _Version(0, minor + 1, 0);
    return _Version(0, 0, patch + 1);
  }

  @override
  bool operator ==(Object other) =>
      other is _Version && major == other.major && minor == other.minor && patch == other.patch;

  @override
  int get hashCode => Object.hash(major, minor, patch);
}

String _unquote(String value) {
  if (value.length < 2) return value;
  final first = value[0];
  final last = value[value.length - 1];
  if ((first == '"' && last == '"') || (first == "'" && last == "'")) {
    return value.substring(1, value.length - 1);
  }
  return value;
}

bool _isAnchorUnit(Folder root, RuleContext context) {
  final currentPath = context.definingUnit.file.path;
  final pubspecText = _read(root.getChildAssumingFile('pubspec.yaml')) ?? '';
  final packageName = RegExp(
    r'^name:\s*([A-Za-z0-9_]+)\s*$',
    multiLine: true,
  ).firstMatch(pubspecText)?.group(1);

  if (packageName != null) {
    return currentPath == root.getChildAssumingFile('lib/$packageName.dart').path;
  }

  return currentPath == root.getChildAssumingFile('lib/main.dart').path;
}

String? _read(File file) {
  if (!file.exists) return null;
  try {
    return file.readAsStringSync();
  } on FileSystemException {
    return null;
  }
}
