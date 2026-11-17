import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// A rule that visits instance creations in app files, not in generated or test files.
abstract class InstanceCreationRule extends AnalysisRule {
  InstanceCreationRule({required super.name, required super.description});

  AstVisitor<void> createVisitor();

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (isGeneratedRuleContext(context) || isTestSourceContext(context)) return;
    registry.addInstanceCreationExpression(this, createVisitor());
  }
}
