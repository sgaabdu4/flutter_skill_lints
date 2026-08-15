import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

abstract class FunctionAndMethodBodyCheckRule extends NodeRegistrationRule {
  FunctionAndMethodBodyCheckRule({
    required super.name,
    required super.description,
    required super.code,
  });

  bool shouldRegister(RuleContext context) => true;

  void checkNonOverrideFunctionBody(TypeAnnotation? returnType, FunctionBody body);

  void checkFunctionBody(
    TypeAnnotation? returnType,
    FunctionBody body, {
    required bool isOverride,
  }) {
    if (isOverride) return;
    checkNonOverrideFunctionBody(returnType, body);
  }

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (!shouldRegister(context)) return;
    final visitor = _FunctionAndMethodBodyCheckVisitor(this);
    registry
      ..addFunctionDeclaration(this, visitor)
      ..addMethodDeclaration(this, visitor);
  }
}

abstract class GeneratedFunctionAndMethodBodyCheckRule extends FunctionAndMethodBodyCheckRule {
  GeneratedFunctionAndMethodBodyCheckRule({
    required super.name,
    required super.description,
    required super.code,
  });

  @override
  bool shouldRegister(RuleContext context) => !isGeneratedRuleContext(context);
}

abstract class FunctionAndMethodReturnTypeCheckRule extends NodeRegistrationRule {
  FunctionAndMethodReturnTypeCheckRule({
    required super.name,
    required super.description,
    required super.code,
  });

  bool shouldRegister(RuleContext context) => true;

  void checkReturnType(TypeAnnotation? returnType, {required bool isOverride});

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (!shouldRegister(context)) return;
    final visitor = _FunctionAndMethodReturnTypeCheckVisitor(this);
    registry
      ..addFunctionDeclaration(this, visitor)
      ..addMethodDeclaration(this, visitor);
  }
}

abstract class GeneratedFunctionAndMethodReturnTypeCheckRule
    extends FunctionAndMethodReturnTypeCheckRule {
  GeneratedFunctionAndMethodReturnTypeCheckRule({
    required super.name,
    required super.description,
    required super.code,
  });

  @override
  bool shouldRegister(RuleContext context) => !isGeneratedRuleContext(context);
}

final class _FunctionAndMethodBodyCheckVisitor extends SimpleAstVisitor<void> {
  const _FunctionAndMethodBodyCheckVisitor(this.rule);

  final FunctionAndMethodBodyCheckRule rule;

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    rule.checkFunctionBody(node.returnType, node.functionExpression.body, isOverride: false);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    final isOverride = node.metadata.any((annotation) => annotation.name.name == 'override');
    rule.checkFunctionBody(node.returnType, node.body, isOverride: isOverride);
  }
}

final class _FunctionAndMethodReturnTypeCheckVisitor extends SimpleAstVisitor<void> {
  const _FunctionAndMethodReturnTypeCheckVisitor(this.rule);

  final FunctionAndMethodReturnTypeCheckRule rule;

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    rule.checkReturnType(node.returnType, isOverride: false);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    final isOverride = node.metadata.any((annotation) => annotation.name.name == 'override');
    rule.checkReturnType(node.returnType, isOverride: isOverride);
  }
}
