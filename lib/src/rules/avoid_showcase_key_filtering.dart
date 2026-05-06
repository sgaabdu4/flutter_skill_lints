import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

final class AvoidShowcaseKeyFiltering extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_showcase_key_filtering',
    "Don't filter Showcase keys by currentContext before startShowCase().",
    correctionMessage: 'Pass the full ordered key list to startShowCase().',
  );

  AvoidShowcaseKeyFiltering()
    : super(
        name: 'avoid_showcase_key_filtering',
        description: 'Bans startShowCase calls that filter keys by currentContext.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (isGeneratedRuleContext(context)) return;
    registry.addMethodInvocation(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AvoidShowcaseKeyFiltering rule;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'startShowCase') return;
    final source = node.argumentList.toSource();
    if (source.contains('currentContext') &&
        (source.contains('.where(') || source.contains('.toList('))) {
      rule.reportAtNode(node.methodName);
    }
  }
}
