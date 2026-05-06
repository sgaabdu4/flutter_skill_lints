import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

final class AvoidWidgetBuildHelpers extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_widget_build_helpers',
    'Avoid private _buildXxx() widget helper methods.',
    correctionMessage: 'Extract a named widget class instead of a build helper method.',
  );

  AvoidWidgetBuildHelpers()
    : super(
        name: 'avoid_widget_build_helpers',
        description: 'Bans private _buildXxx helper methods.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (isGeneratedRuleContext(context)) return;
    registry.addMethodDeclaration(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AvoidWidgetBuildHelpers rule;

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (RegExp(r'^_build[A-Z][A-Za-z0-9_]*$').hasMatch(node.name.lexeme)) {
      rule.reportAtToken(node.name);
    }
  }
}
