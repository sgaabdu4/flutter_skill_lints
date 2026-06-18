import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';

/// Warns when common pubspec sections or package entries are out of order.
final class PubspecOrdering extends AnalysisRule {
  static const LintCode code = LintCode(
    'pubspec_ordering',
    'Keep pubspec.yaml sections and dependencies ordered.',
    correctionMessage: 'Move pubspec entries into the conventional order.',
  );

  PubspecOrdering()
    : super(
        name: 'pubspec_ordering',
        description: 'Warns when common pubspec.yaml entries are not ordered.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final root = context.package?.root;
    if (root == null || !_isAnchorUnit(root, context)) return;

    final text = _read(root.getChildAssumingFile('pubspec.yaml'));
    if (text == null || !_hasOrderingIssue(text)) return;

    registry.addCompilationUnit(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final PubspecOrdering rule;

  @override
  void visitCompilationUnit(CompilationUnit node) {
    rule.reportAtToken(node.beginToken);
  }
}

bool _hasOrderingIssue(String text) {
  final topLevelKeys = _topLevelKeys(text).where(_topLevelOrder.containsKey).toList();
  if (!_isSortedBy(topLevelKeys, (key) => _topLevelOrder[key]!)) return true;

  const packageSections = ['dependencies', 'dev_dependencies', 'dependency_overrides'];
  for (final section in packageSections) {
    final names = _sectionPackageNames(text, section).toList();
    if (!_isSortedBy(names, (name) => name.toLowerCase())) return true;
  }

  return false;
}

const _topLevelOrder = {
  'name': 0,
  'description': 1,
  'version': 2,
  'publish_to': 3,
  'homepage': 4,
  'repository': 5,
  'issue_tracker': 6,
  'documentation': 7,
  'topics': 8,
  'screenshots': 9,
  'funding': 10,
  'environment': 11,
  'dependencies': 12,
  'dev_dependencies': 13,
  'dependency_overrides': 14,
  'flutter': 15,
};

Iterable<String> _topLevelKeys(String text) sync* {
  for (final line in text.split('\n')) {
    if (line.trim().isEmpty || line.trimLeft().startsWith('#')) continue;
    if (line.startsWith(' ') || line.startsWith('\t')) continue;

    final match = RegExp(r'''^['"]?([A-Za-z_][\w-]*)['"]?\s*:''').firstMatch(line);
    final key = match?.group(1);
    if (key != null) yield key;
  }
}

Iterable<String> _sectionPackageNames(String text, String section) sync* {
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

    final match = RegExp(r'''^\s*['"]?([A-Za-z_][\w-]*)['"]?\s*:''').firstMatch(line);
    final name = match?.group(1);
    if (name != null) yield name;
  }
}

bool _isSortedBy<T extends Object>(List<T> values, Comparable<Object> Function(T) key) {
  for (var i = 1; i < values.length; i++) {
    if (key(values[i - 1]).compareTo(key(values[i])) > 0) return false;
  }
  return true;
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
