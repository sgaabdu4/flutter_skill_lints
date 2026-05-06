import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

final class GuardContextPop extends AnalysisRule {
  static const LintCode code = LintCode(
    'guard_context_pop',
    'Guard context.pop() with context.canPop().',
    correctionMessage: 'Check context.canPop() and navigate to a typed fallback when it is false.',
  );

  GuardContextPop()
    : super(
        name: 'guard_context_pop',
        description: 'Requires context.canPop() guards before context.pop().',
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

  final GuardContextPop rule;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (!isTargetMethodInvocation(node, 'context', 'pop')) return;
    final body = node.thisOrAncestorOfType<FunctionBody>();
    if (body == null) {
      rule.reportAtNode(node);
      return;
    }
    final prefix = body.toSource().substring(0, node.offset - body.offset);
    if (!prefix.contains('context.canPop')) {
      rule.reportAtNode(node);
    }
  }
}
