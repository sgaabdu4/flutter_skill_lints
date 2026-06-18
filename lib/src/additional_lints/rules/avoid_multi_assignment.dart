import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when multiple assignments are chained in one expression.
class AvoidMultiAssignment extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_multi_assignment',
    'Avoid chained assignments.',
    correctionMessage: 'Split the assignments into separate statements.',
  );

  AvoidMultiAssignment()
    : super(
        name: 'avoid_multi_assignment',
        description: 'Warns when assignment expressions are chained.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addAssignmentExpression(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidMultiAssignment rule;

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    if (node.rightHandSide is AssignmentExpression) {
      rule.reportAtNode(node);
    }
  }
}
