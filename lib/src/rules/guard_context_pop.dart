import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Guard context.pop() with context.canPop().
///
/// Why: Page back actions must account for direct deep links. Check
/// context.canPop() before context.pop(), then route to a generated typed
/// fallback when there is nothing to pop.
final class GuardContextPop extends AnalysisRule {
  static const LintCode code = LintCode(
    'guard_context_pop',
    'Guard context.pop() with context.canPop().',
    correctionMessage:
        'Check context.canPop() before context.pop(), then navigate to a typed fallback when false.',
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
    final bodySource = body.toSource();
    final relativeOffset = node.offset - body.offset;
    final prefix = bodySource.substring(0, relativeOffset.clamp(0, bodySource.length));
    if (!RegExp(r'\bcontext\s*\.\s*canPop\s*\(').hasMatch(prefix)) {
      rule.reportAtNode(node);
    }
  }
}
