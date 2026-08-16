import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';

abstract class ConditionRule extends NodeRegistrationRule {
  ConditionRule({
    required super.name,
    required super.description,
    required super.code,
    this.includeAssert = true,
  });

  final bool includeAssert;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final visitor = createVisitor();
    if (includeAssert) registry.addAssertStatement(this, visitor);
    registry
      ..addConditionalExpression(this, visitor)
      ..addDoStatement(this, visitor)
      ..addForStatement(this, visitor)
      ..addIfElement(this, visitor)
      ..addIfStatement(this, visitor)
      ..addWhenClause(this, visitor)
      ..addWhileStatement(this, visitor);
    registerAdditionalConditionNodes(registry, visitor);
  }

  void registerAdditionalConditionNodes(RuleVisitorRegistry registry, AstVisitor<void> visitor) {}
}

abstract class ConditionVisitor extends SimpleAstVisitor<void> {
  const ConditionVisitor();

  void checkCondition(Expression condition);

  @override
  void visitAssertStatement(AssertStatement node) {
    checkCondition(node.condition);
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    checkCondition(node.condition);
  }

  @override
  void visitDoStatement(DoStatement node) {
    checkCondition(node.condition);
  }

  @override
  void visitForStatement(ForStatement node) {
    if (node.forLoopParts case ForPartsWithExpression(:final condition?)) {
      checkCondition(condition);
    }
  }

  @override
  void visitIfElement(IfElement node) {
    checkCondition(node.expression);
  }

  @override
  void visitIfStatement(IfStatement node) {
    checkCondition(node.expression);
  }

  @override
  void visitWhenClause(WhenClause node) {
    checkCondition(node.expression);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    checkCondition(node.condition);
  }
}
