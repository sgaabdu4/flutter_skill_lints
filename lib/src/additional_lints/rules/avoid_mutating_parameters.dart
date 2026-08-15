import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Warns when a function or method mutates one of its parameters.
final class AvoidMutatingParameters extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_mutating_parameters',
    'Avoid mutating parameters.',
    correctionMessage: 'Copy the value into a local variable or return a new value.',
  );

  AvoidMutatingParameters()
    : super(
        name: 'avoid_mutating_parameters',
        description: 'Warns when parameters are reassigned or mutated through direct writes.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final visitor = _Visitor(this);
    registry
      ..addFunctionDeclaration(this, visitor)
      ..addFunctionExpression(this, visitor)
      ..addMethodDeclaration(this, visitor);
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidMutatingParameters rule;

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _check(node.functionExpression.parameters, node.functionExpression.body);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    if (node.parent is FunctionDeclaration) return;
    _check(node.parameters, node.body);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _check(node.parameters, node.body);
  }

  void _check(FormalParameterList? parameters, FunctionBody body) {
    final names = formalParameterNames(parameters);
    if (names.isEmpty) return;
    body.accept(_MutationVisitor(rule, names));
  }
}

final class _MutationVisitor extends RecursiveAstVisitor<void> {
  const _MutationVisitor(this.rule, this.parameters);

  final AvoidMutatingParameters rule;
  final Set<String> parameters;

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    final target = _parameterWriteTarget(node.leftHandSide, parameters);
    if (target != null) {
      rule.reportAtNode(target);
    }
    super.visitAssignmentExpression(node);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    if (!node.operator.type.isIncrementOperator) return;
    final target = _parameterWriteTarget(node.operand, parameters);
    if (target != null) {
      rule.reportAtNode(target);
    }
    super.visitPostfixExpression(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    if (!node.operator.type.isIncrementOperator) return;
    final target = _parameterWriteTarget(node.operand, parameters);
    if (target != null) {
      rule.reportAtNode(target);
    }
    super.visitPrefixExpression(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}
}

AstNode? _parameterWriteTarget(Expression expression, Set<String> parameters) {
  return switch (expression) {
    SimpleIdentifier(:final name) when parameters.contains(name) => expression,
    PrefixedIdentifier(:final prefix, :final identifier) when parameters.contains(prefix.name) =>
      identifier,
    PropertyAccess(target: SimpleIdentifier(:final name), :final propertyName)
        when parameters.contains(name) =>
      propertyName,
    IndexExpression(target: SimpleIdentifier(:final name)) when parameters.contains(name) =>
      expression,
    _ => null,
  };
}
