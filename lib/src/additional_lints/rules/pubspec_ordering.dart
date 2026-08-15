import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/pubspec_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/pubspec_rule_utils.dart';

/// Warns when common pubspec sections or package entries are out of order.
final class PubspecOrdering extends PubspecAnalysisRule {
  static const LintCode code = LintCode(
    'pubspec_ordering',
    'Keep pubspec.yaml sections and dependencies ordered.',
    correctionMessage: 'Move pubspec entries into the conventional order.',
  );

  PubspecOrdering()
    : super(
        name: 'pubspec_ordering',
        description: 'Warns when common pubspec.yaml entries are not ordered.',
        code: code,
      );

  @override
  bool shouldRegisterPubspec(String text) => _hasOrderingIssue(text);

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
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
  for (final (:line, :indent) in yamlSectionLines(text, section)) {
    if (indent != 2) continue;

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
