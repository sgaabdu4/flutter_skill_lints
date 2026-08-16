import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Avoid shrinkWrap: true.
///
/// Why: Bans shrinkWrap: true because it forces expensive layout work. Use slivers or
/// constrained layouts instead of shrinkWrap.
final class AvoidShrinkWrap extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_shrink_wrap',
    'Avoid shrinkWrap: true.',
    correctionMessage: 'Use slivers or constrained layouts instead of shrinkWrap.',
  );

  AvoidShrinkWrap()
    : super(
        name: 'avoid_shrink_wrap',
        description: 'Bans shrinkWrap: true because it forces expensive layout work.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (isGeneratedRuleContext(context)) return;
    registry.addNamedArgument(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AvoidShrinkWrap rule;

  @override
  void visitNamedArgument(NamedArgument node) {
    if (node.name.lexeme != 'shrinkWrap') return;
    final expression = node.argumentExpression;
    if (expression is BooleanLiteral && expression.value) {
      rule.reportAtNode(node);
    }
  }
}
