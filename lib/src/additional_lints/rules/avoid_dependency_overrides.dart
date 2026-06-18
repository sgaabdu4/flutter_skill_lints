import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';

/// Reports pubspec dependency overrides.
final class AvoidDependencyOverrides extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_dependency_overrides',
    'Avoid pub dependency overrides.',
    correctionMessage: 'Remove dependency_overrides and fix the declared dependency constraints.',
    severity: DiagnosticSeverity.ERROR,
  );

  AvoidDependencyOverrides()
    : super(
        name: 'avoid_dependency_overrides',
        description: 'Reports pubspec dependency_overrides entries.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final root = context.package?.root;
    if (root == null || !_isAnchorUnit(root, context)) return;

    final text = _read(root.getChildAssumingFile('pubspec.yaml'));
    if (text == null || !_hasDependencyOverrideEntry(text)) return;

    registry.addCompilationUnit(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidDependencyOverrides rule;

  @override
  void visitCompilationUnit(CompilationUnit node) {
    rule.reportAtToken(node.beginToken);
  }
}

bool _hasDependencyOverrideEntry(String text) {
  final lines = text.split('\n');
  var inSection = false;
  var sectionIndent = 0;

  for (final line in lines) {
    if (line.trim().isEmpty || line.trimLeft().startsWith('#')) continue;
    final indent = line.length - line.trimLeft().length;
    final sectionMatch = RegExp(r'^\s*dependency_overrides\s*:(.*)$').firstMatch(line);
    if (sectionMatch != null) {
      sectionIndent = indent;
      final inlineValue = (sectionMatch.group(1) ?? '').trim();
      if (inlineValue.isNotEmpty && inlineValue != '{}') return true;
      inSection = inlineValue.isEmpty;
      continue;
    }
    if (!inSection) continue;
    if (indent <= sectionIndent) {
      inSection = false;
      continue;
    }
    if (indent != sectionIndent + 2) continue;
    if (RegExp(r'''^\s*['"]?[A-Za-z_][\w-]*['"]?\s*:''').hasMatch(line)) return true;
  }

  return false;
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
