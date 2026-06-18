import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'avoid_equal_expressions.dart';

/// Warns when a variable, field, or index expression is assigned to itself.
class AvoidSelfAssignment extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_self_assignment',
    'This assignment assigns the target to itself.',
    correctionMessage: 'Remove the assignment or assign a different value.',
  );

  AvoidSelfAssignment()
    : super(
        name: 'avoid_self_assignment',
        description: 'Warns when an assignment writes an expression to itself.',
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

  final AvoidSelfAssignment rule;

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    if (node.operator.type != TokenType.EQ) return;
    if (sameLintExpressionSource(node.leftHandSide, node.rightHandSide)) {
      rule.reportAtNode(node);
    }
  }
}
