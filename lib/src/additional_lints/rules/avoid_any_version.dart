import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';

/// Reports pubspec dependencies that use the unconstrained `any` version.
final class AvoidAnyVersion extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_any_version',
    'Avoid `any` pub dependency versions.',
    correctionMessage: 'Replace `any` with an explicit version constraint.',
    severity: DiagnosticSeverity.ERROR,
  );

  AvoidAnyVersion()
    : super(
        name: 'avoid_any_version',
        description: 'Reports pubspec dependencies that use `any` as the version constraint.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final root = context.package?.root;
    if (root == null || !_isAnchorUnit(root, context)) return;

    final text = _read(root.getChildAssumingFile('pubspec.yaml'));
    if (text == null || !_hasAnyVersion(text)) return;

    registry.addCompilationUnit(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidAnyVersion rule;

  @override
  void visitCompilationUnit(CompilationUnit node) {
    rule.reportAtToken(node.beginToken);
  }
}

bool _hasAnyVersion(String text) {
  const dependencySections = ['dependencies', 'dev_dependencies', 'dependency_overrides'];

  for (final section in dependencySections) {
    for (final value in _sectionScalarValues(text, section)) {
      if (_unquote(value) == 'any') return true;
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
    yield value;
  }
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
