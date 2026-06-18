import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';

/// Reports pubspec publish targets that are not `none`.
final class PreferPublishToNone extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_publish_to_none',
    'Prefer `publish_to: none` for app and private package pubspecs.',
    correctionMessage: 'Set publish_to to none when this package should not be published.',
    severity: DiagnosticSeverity.INFO,
  );

  PreferPublishToNone()
    : super(
        name: 'prefer_publish_to_none',
        description: 'Reports pubspec publish_to values other than none.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final root = context.package?.root;
    if (root == null || !_isAnchorUnit(root, context)) return;

    final text = _read(root.getChildAssumingFile('pubspec.yaml'));
    if (text == null || !_hasNonNonePublishTarget(text)) return;

    registry.addCompilationUnit(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final PreferPublishToNone rule;

  @override
  void visitCompilationUnit(CompilationUnit node) {
    rule.reportAtToken(node.beginToken);
  }
}

bool _hasNonNonePublishTarget(String text) {
  final match = RegExp(
    r'''^\s*publish_to\s*:\s*['"]?([^'"#\s]+)['"]?\s*(?:#.*)?$''',
    multiLine: true,
  ).firstMatch(text);
  final target = match?.group(1);

  return target != null && target != 'none';
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
