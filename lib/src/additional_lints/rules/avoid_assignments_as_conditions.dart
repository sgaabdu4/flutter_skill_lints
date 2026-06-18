import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when an assignment expression is used in a condition.
class AvoidAssignmentsAsConditions extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_assignments_as_conditions',
    'Avoid assignments as conditions.',
    correctionMessage: 'Move the assignment before the condition.',
  );

  AvoidAssignmentsAsConditions()
    : super(
        name: 'avoid_assignments_as_conditions',
        description: 'Warns when assignment expressions are used as conditions.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final visitor = _Visitor(this);
    registry.addAssertStatement(this, visitor);
    registry.addConditionalExpression(this, visitor);
    registry.addDoStatement(this, visitor);
    registry.addForStatement(this, visitor);
    registry.addIfElement(this, visitor);
    registry.addIfStatement(this, visitor);
    registry.addWhenClause(this, visitor);
    registry.addWhileStatement(this, visitor);
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidAssignmentsAsConditions rule;

  @override
  void visitAssertStatement(AssertStatement node) {
    _check(node.condition);
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    _check(node.condition);
  }

  @override
  void visitDoStatement(DoStatement node) {
    _check(node.condition);
  }

  @override
  void visitForStatement(ForStatement node) {
    if (node.forLoopParts case ForPartsWithExpression(:final condition?)) {
      _check(condition);
    }
  }

  @override
  void visitIfElement(IfElement node) {
    _check(node.expression);
  }

  @override
  void visitIfStatement(IfStatement node) {
    _check(node.expression);
  }

  @override
  void visitWhenClause(WhenClause node) {
    _check(node.expression);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    _check(node.condition);
  }

  void _check(Expression condition) {
    condition.accept(_AssignmentVisitor(rule));
  }
}

final class _AssignmentVisitor extends RecursiveAstVisitor<void> {
  const _AssignmentVisitor(this.rule);

  final AvoidAssignmentsAsConditions rule;

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    rule.reportAtNode(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}
}
