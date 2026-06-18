import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when a conditional expression nests another conditional expression.
class AvoidNestedConditionalExpressions extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_nested_conditional_expressions',
    'Avoid nested conditional expressions.',
    correctionMessage: 'Extract the nested decision into a named helper or an if statement.',
  );

  AvoidNestedConditionalExpressions()
    : super(
        name: 'avoid_nested_conditional_expressions',
        description: 'Warns when a ternary expression contains another ternary expression.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addConditionalExpression(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidNestedConditionalExpressions rule;

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    _reportIfNested(node.thenExpression);
    _reportIfNested(node.elseExpression);
  }

  void _reportIfNested(Expression expression) {
    final unwrapped = _unwrapParentheses(expression);
    if (unwrapped is ConditionalExpression) {
      rule.reportAtNode(unwrapped);
    }
  }
}

Expression _unwrapParentheses(Expression expression) {
  while (expression is ParenthesizedExpression) {
    expression = expression.expression;
  }

  return expression;
}
