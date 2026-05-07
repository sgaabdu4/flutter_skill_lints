import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Use ref.invalidate when the result of ref.refresh is ignored.
///
/// Why: Bans ref.refresh when its return value is unused. Replace the ignored ref.refresh(...)
/// call with ref.invalidate(...).
final class UseRefInvalidate extends AnalysisRule {
  static const LintCode code = LintCode(
    'use_ref_invalidate',
    'Use ref.invalidate when the result of ref.refresh is ignored.',
    correctionMessage: 'Replace the ignored ref.refresh(...) call with ref.invalidate(...).',
  );

  UseRefInvalidate()
    : super(
        name: 'use_ref_invalidate',
        description: 'Bans ref.refresh when its return value is unused.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (isGeneratedRuleContext(context)) return;
    registry.addExpressionStatement(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final UseRefInvalidate rule;

  @override
  void visitExpressionStatement(ExpressionStatement node) {
    final expression = node.expression;
    if (expression is AwaitExpression) {
      final inner = expression.expression;
      if (inner is MethodInvocation && isTargetMethodInvocation(inner, 'ref', 'refresh')) {
        rule.reportAtNode(inner);
      }
      return;
    }
    if (expression is MethodInvocation && isTargetMethodInvocation(expression, 'ref', 'refresh')) {
      rule.reportAtNode(expression);
    }
  }
}
