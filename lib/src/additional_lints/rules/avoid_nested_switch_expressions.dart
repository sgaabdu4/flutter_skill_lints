import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Reports switch expressions nested directly in another switch expression arm.
final class AvoidNestedSwitchExpressions extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_nested_switch_expressions',
    'Avoid nested switch expressions.',
    correctionMessage: 'Extract the nested switch expression into a named helper.',
    severity: DiagnosticSeverity.INFO,
  );

  AvoidNestedSwitchExpressions()
    : super(
        name: 'avoid_nested_switch_expressions',
        description: 'Reports switch expressions nested directly in a switch expression arm.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addSwitchExpression(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidNestedSwitchExpressions rule;

  @override
  void visitSwitchExpression(SwitchExpression node) {
    for (final caseNode in node.cases) {
      final expression = _unwrap(caseNode.expression);
      if (expression is SwitchExpression) {
        rule.reportAtNode(expression);
      }
    }
  }
}

Expression _unwrap(Expression expression) {
  var current = expression;
  while (current is ParenthesizedExpression) {
    current = current.expression;
  }
  return current;
}
