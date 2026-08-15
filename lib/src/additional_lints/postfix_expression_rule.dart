import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

abstract class GeneratedPostfixExpressionCheckRule extends NodeRegistrationRule {
  GeneratedPostfixExpressionCheckRule({
    required super.name,
    required super.description,
    required super.code,
  });

  void checkPostfixExpression(PostfixExpression node);

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (isGeneratedRuleContext(context)) return;
    registry.addPostfixExpression(this, _PostfixExpressionCheckVisitor(this));
  }
}

final class _PostfixExpressionCheckVisitor extends SimpleAstVisitor<void> {
  const _PostfixExpressionCheckVisitor(this.rule);

  final GeneratedPostfixExpressionCheckRule rule;

  @override
  void visitPostfixExpression(PostfixExpression node) {
    rule.checkPostfixExpression(node);
  }
}
