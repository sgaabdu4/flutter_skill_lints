import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Warns when a Dart file spans too many source lines.
final class AvoidLongFiles extends AnalysisRule {
  static const int maxLines = 600;

  static const LintCode code = LintCode(
    'avoid_long_files',
    'Avoid files longer than 600 lines.',
    correctionMessage: 'Split this file by role, feature, or ownership boundary.',
  );

  AvoidLongFiles()
    : super(name: 'avoid_long_files', description: 'Warns when a Dart file exceeds 600 lines.');

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (isGeneratedRuleContext(context)) return;
    registry.addCompilationUnit(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidLongFiles rule;

  @override
  void visitCompilationUnit(CompilationUnit node) {
    if (_lineCount(node) <= AvoidLongFiles.maxLines) return;

    rule.reportAtToken(node.beginToken);
  }
}

int _lineCount(CompilationUnit node) {
  final contentEnd = node.end == 0 ? 0 : node.end - 1;
  return node.lineInfo.getLocation(contentEnd).lineNumber;
}
