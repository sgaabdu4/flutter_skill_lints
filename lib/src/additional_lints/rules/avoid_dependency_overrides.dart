import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:flutter_skill_lints/src/additional_lints/pubspec_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/pubspec_rule_utils.dart';

/// Reports dependency overrides in every package in the workspace.
final class AvoidDependencyOverrides extends PubspecAnalysisRule {
  static const LintCode code = LintCode(
    'avoid_dependency_overrides',
    'Remove pub dependency overrides.',
    correctionMessage: 'Remove dependency_overrides from the package or workspace member.',
    severity: DiagnosticSeverity.ERROR,
  );

  AvoidDependencyOverrides()
    : super(
        name: 'avoid_dependency_overrides',
        description: 'Reports dependency overrides in package and workspace pubspec files.',
        code: code,
      );

  @override
  bool shouldRegister(Folder root, RuleContext context, String? pubspecText) {
    return hasDependencyOverrideInWorkspace(root);
  }

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidDependencyOverrides rule;

  @override
  void visitCompilationUnit(CompilationUnit node) {
    rule.reportAtToken(node.beginToken);
  }
}

bool hasDependencyOverrideInWorkspace(Folder root) {
  final seen = <String>{};
  for (final packageRoot in _workspacePackageRoots(root, seen)) {
    final overrides = <String, String>{};
    for (final fileName in ['pubspec.yaml', 'pubspec_overrides.yaml']) {
      final text = readFileText(packageRoot.getFile(fileName));
      if (text != null) overrides.addAll(_dependencyOverrideEntries(text));
    }
    if (overrides.isNotEmpty) return true;
  }
  return false;
}

Map<String, String> _dependencyOverrideEntries(String text) {
  final lines = text.split('\n');
  final section = _findYamlSection(lines, 'dependency_overrides');
  if (section == null) return {};

  if (section.inline.isNotEmpty && section.inline != '{}') {
    return {'<inline>': section.inline};
  }
  if (section.inline.isNotEmpty) return {};

  return _parseYamlEntries(lines, section.index, section.indent);
}

Map<String, String> _parseYamlEntries(List<String> lines, int sectionIndex, int sectionIndent) {
  final entries = <String, String>{};
  for (var index = sectionIndex + 1; index < lines.length; index++) {
    final line = lines[index];
    if (_isBlankOrComment(line)) continue;
    final indent = _indentOf(line);
    if (indent <= sectionIndent) break;
    if (indent != sectionIndent + 2) continue;

    final entry = _yamlEntryPattern.firstMatch(line);
    if (entry == null) continue;
    entries[entry.group(1)!] = _stripQuotes(entry.group(2)!);
  }
  return entries;
}

({int indent, int index, String inline})? _findYamlSection(List<String> lines, String name) {
  final sectionPattern = RegExp('^\\s*$name\\s*:(.*)\$');
  for (var index = 0; index < lines.length; index++) {
    final line = lines[index];
    if (_isBlankOrComment(line)) continue;
    final match = sectionPattern.firstMatch(line);
    if (match == null) continue;
    return (indent: _indentOf(line), index: index, inline: (match.group(1) ?? '').trim());
  }
  return null;
}

bool _isBlankOrComment(String line) => line.trim().isEmpty || line.trimLeft().startsWith('#');

int _indentOf(String line) => line.length - line.trimLeft().length;

String _stripQuotes(String value) => value.replaceAll(RegExp(r'''^['"]|['"]$'''), '');

final _yamlEntryPattern = RegExp(r'''^\s*['"]?([A-Za-z_][\w-]*)['"]?\s*:\s*([^#]+?)\s*$''');

final _workspaceItemPattern = RegExp(r'''^\s*-\s*["']?([^"'#\s]+)["']?\s*$''');

Iterable<String> _inlineWorkspacePaths(String inline) sync* {
  final body = inline.substring(1, inline.length - 1);
  for (final item in body.split(',')) {
    final path = _stripQuotes(item.trim());
    if (path.isNotEmpty) yield path;
  }
}

Iterable<Folder> _workspacePackageRoots(Folder root, Set<String> seen) sync* {
  if (!seen.add(root.path)) return;
  yield root;

  final text = readFileText(root.getFile('pubspec.yaml'));
  if (text == null) return;
  for (final memberPath in _workspaceMemberPaths(text)) {
    for (final member in _workspaceMembers(root, memberPath)) {
      if (!member.exists || !member.getFile('pubspec.yaml').exists) continue;
      yield* _workspacePackageRoots(member, seen);
    }
  }
}

Iterable<Folder> _workspaceMembers(Folder root, String memberPath) sync* {
  final parts = memberPath
      .replaceAll('\\', '/')
      .split('/')
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return;
  yield* _matchWorkspacePath(root, parts, 0);
}

Iterable<Folder> _matchWorkspacePath(Folder current, List<String> parts, int index) sync* {
  if (index == parts.length) {
    yield current;
    return;
  }

  final part = parts[index];
  if (part == '**') {
    yield* _matchWorkspacePath(current, parts, index + 1);
    for (final child in _childFolders(current)) {
      yield* _matchWorkspacePath(child, parts, index);
    }
    return;
  }

  if (part == '*') {
    for (final child in _childFolders(current)) {
      yield* _matchWorkspacePath(child, parts, index + 1);
    }
    return;
  }

  final child = current.getFolder(part);
  if (child.exists) yield* _matchWorkspacePath(child, parts, index + 1);
}

Iterable<Folder> _childFolders(Folder folder) sync* {
  List<Resource> children;
  try {
    children = folder.getChildren();
  } on FileSystemException {
    return;
  }
  for (final child in children) {
    if (child is Folder) yield child;
  }
}

Iterable<String> _workspaceMemberPaths(String text) sync* {
  final lines = text.split('\n');
  final section = _findYamlSection(lines, 'workspace');
  if (section == null) return;
  if (section.inline.startsWith('[') && section.inline.endsWith(']')) {
    yield* _inlineWorkspacePaths(section.inline);
    return;
  }

  for (var index = section.index + 1; index < lines.length; index++) {
    final line = lines[index];
    if (_isBlankOrComment(line)) continue;
    if (_indentOf(line) <= section.indent) break;
    final item = _workspaceItemPattern.firstMatch(line);
    if (item != null) yield item.group(1)!;
  }
}
