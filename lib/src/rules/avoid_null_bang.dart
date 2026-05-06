import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

final class AvoidNullBang extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_null_bang',
    'Avoid null assertion operators.',
    correctionMessage: 'Use pattern matching, early returns, or explicit null handling instead.',
  );

  AvoidNullBang() : super(name: 'avoid_null_bang', description: 'Bans null assertion expressions.');

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (isGeneratedRuleContext(context)) return;
    registry.addPostfixExpression(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AvoidNullBang rule;

  @override
  void visitPostfixExpression(PostfixExpression node) {
    if (node.operator.lexeme == '!') {
      rule.reportAtToken(node.operator);
    }
  }
}
