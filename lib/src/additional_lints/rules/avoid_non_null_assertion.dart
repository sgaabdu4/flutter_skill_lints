import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Warns when a postfix null assertion operator is used.
class AvoidNonNullAssertion extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_non_null_assertion',
    'Avoid using null assertion operators.',
    correctionMessage: 'Handle the null case explicitly before using the value.',
    severity: DiagnosticSeverity.ERROR,
  );

  AvoidNonNullAssertion()
    : super(
        name: 'avoid_non_null_assertion',
        description: 'Warns when a postfix null assertion operator is used.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (isGeneratedRuleContext(context)) return;
    registry.addPostfixExpression(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidNonNullAssertion rule;

  @override
  void visitPostfixExpression(PostfixExpression node) {
    if (node.operator.lexeme != '!') return;
    rule.reportAtToken(node.operator);
  }
}
