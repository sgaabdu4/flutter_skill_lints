import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/condition_rule.dart';

/// Warns when an assignment expression is used in a condition.
class AvoidAssignmentsAsConditions extends ConditionRule {
  static const LintCode code = LintCode(
    'avoid_assignments_as_conditions',
    'Avoid assignments as conditions.',
    correctionMessage: 'Move the assignment before the condition.',
  );

  AvoidAssignmentsAsConditions()
    : super(
        name: 'avoid_assignments_as_conditions',
        description: 'Warns when assignment expressions are used as conditions.',
        code: code,
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

final class _Visitor extends ConditionVisitor {
  const _Visitor(this.rule);

  final AvoidAssignmentsAsConditions rule;

  @override
  void checkCondition(Expression condition) {
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
