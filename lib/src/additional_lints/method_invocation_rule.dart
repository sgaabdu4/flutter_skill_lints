import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import 'package:flutter_skill_lints/src/ast_utils.dart';

abstract class NodeRegistrationRule extends AnalysisRule {
  NodeRegistrationRule({required super.name, required super.description, required LintCode code})
    : _code = code;

  final LintCode _code;

  @override
  LintCode get diagnosticCode => _code;

  AstVisitor<void> createVisitor() => throw UnimplementedError();
}

abstract class ClassDeclarationRule extends NodeRegistrationRule {
  ClassDeclarationRule({required super.name, required super.description, required super.code});

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addClassDeclaration(this, createVisitor());
  }
}

abstract class InstanceCreationExpressionRule extends NodeRegistrationRule {
  InstanceCreationExpressionRule({
    required super.name,
    required super.description,
    required super.code,
  });

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addInstanceCreationExpression(this, createVisitor());
  }
}

abstract class MethodDeclarationRule extends NodeRegistrationRule {
  MethodDeclarationRule({required super.name, required super.description, required super.code});

  bool shouldRegister(RuleContext context) => true;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (!shouldRegister(context)) return;

    registry.addMethodDeclaration(this, createVisitor());
  }
}

abstract class FunctionAndMethodDeclarationRule extends NodeRegistrationRule {
  FunctionAndMethodDeclarationRule({
    required super.name,
    required super.description,
    required super.code,
  });

  bool shouldRegister(RuleContext context) => true;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (!shouldRegister(context)) return;

    final visitor = createVisitor();
    registry.addFunctionDeclaration(this, visitor);
    registry.addMethodDeclaration(this, visitor);
  }
}

abstract class BinaryExpressionRule extends NodeRegistrationRule {
  BinaryExpressionRule({required super.name, required super.description, required super.code});

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addBinaryExpression(this, createVisitor());
  }
}

abstract class IfStatementRule extends NodeRegistrationRule {
  IfStatementRule({required super.name, required super.description, required super.code});

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addIfStatement(this, createVisitor());
  }
}

abstract class CompilationUnitRule extends NodeRegistrationRule {
  CompilationUnitRule({required super.name, required super.description, required super.code});

  bool shouldRegister(RuleContext context) => true;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (!shouldRegister(context)) return;
    registry.addCompilationUnit(this, createVisitor());
  }
}

abstract class RecordRule extends NodeRegistrationRule {
  RecordRule({required super.name, required super.description, required super.code});

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (isGeneratedRuleContext(context)) return;

    final visitor = createVisitor();
    registry
      ..addRecordLiteral(this, visitor)
      ..addRecordTypeAnnotation(this, visitor);
  }
}

abstract class MethodInvocationRule extends NodeRegistrationRule {
  MethodInvocationRule({required super.name, required super.description, required super.code});

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addMethodInvocation(this, createVisitor());
  }
}

abstract class MethodInvocationCheckRule extends NodeRegistrationRule {
  MethodInvocationCheckRule({required super.name, required super.description, required super.code});

  bool shouldRegister(RuleContext context) => true;

  void checkMethodInvocation(MethodInvocation node);

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (!shouldRegister(context)) return;
    registry.addMethodInvocation(this, _MethodInvocationCheckVisitor(this));
  }
}

abstract class GeneratedMethodInvocationCheckRule extends MethodInvocationCheckRule {
  GeneratedMethodInvocationCheckRule({
    required super.name,
    required super.description,
    required super.code,
  });

  @override
  bool shouldRegister(RuleContext context) => !isGeneratedRuleContext(context);
}

final class _MethodInvocationCheckVisitor extends SimpleAstVisitor<void> {
  const _MethodInvocationCheckVisitor(this.rule);

  final MethodInvocationCheckRule rule;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    rule.checkMethodInvocation(node);
  }
}

abstract class InstanceAndMethodInvocationRule extends MethodInvocationRule {
  InstanceAndMethodInvocationRule({
    required super.name,
    required super.description,
    required super.code,
  });

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final visitor = createVisitor();
    registry.addInstanceCreationExpression(this, visitor);
    registry.addMethodInvocation(this, visitor);
  }
}

abstract class InstanceAndMethodVisitor extends SimpleAstVisitor<void> {
  void checkInstanceOrMethod(DartType? staticType, ArgumentList argumentList, AstNode reportNode);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    checkInstanceOrMethod(node.staticType, node.argumentList, node.constructorName);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    checkInstanceOrMethod(node.staticType, node.argumentList, node.methodName);
  }
}

abstract class BinaryExpressionCheckRule extends NodeRegistrationRule {
  BinaryExpressionCheckRule({required super.name, required super.description, required super.code});

  void checkBinaryExpression(BinaryExpression node);

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addBinaryExpression(this, _BinaryExpressionCheckVisitor(this));
  }
}

final class _BinaryExpressionCheckVisitor extends SimpleAstVisitor<void> {
  const _BinaryExpressionCheckVisitor(this.rule);

  final BinaryExpressionCheckRule rule;

  @override
  void visitBinaryExpression(BinaryExpression node) {
    rule.checkBinaryExpression(node);
  }
}

abstract class MethodDeclarationCheckRule extends NodeRegistrationRule {
  MethodDeclarationCheckRule({
    required super.name,
    required super.description,
    required super.code,
  });

  bool shouldRegister(RuleContext context) => true;

  void checkMethodDeclaration(MethodDeclaration node);

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (!shouldRegister(context)) return;
    registry.addMethodDeclaration(this, _MethodDeclarationCheckVisitor(this));
  }
}

abstract class GeneratedMethodDeclarationCheckRule extends MethodDeclarationCheckRule {
  GeneratedMethodDeclarationCheckRule({
    required super.name,
    required super.description,
    required super.code,
  });

  @override
  bool shouldRegister(RuleContext context) => !isGeneratedRuleContext(context);
}

abstract class FunctionAndMethodDeclarationCheckRule extends NodeRegistrationRule {
  FunctionAndMethodDeclarationCheckRule({
    required super.name,
    required super.description,
    required super.code,
  });

  bool shouldRegister(RuleContext context) => true;

  void checkFunctionDeclaration(FunctionDeclaration node);

  void checkMethodDeclaration(MethodDeclaration node);

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (!shouldRegister(context)) return;
    final visitor = _FunctionAndMethodDeclarationCheckVisitor(this);
    registry
      ..addFunctionDeclaration(this, visitor)
      ..addMethodDeclaration(this, visitor);
  }
}

abstract class GeneratedFunctionAndMethodDeclarationCheckRule
    extends FunctionAndMethodDeclarationCheckRule {
  GeneratedFunctionAndMethodDeclarationCheckRule({
    required super.name,
    required super.description,
    required super.code,
  });

  @override
  bool shouldRegister(RuleContext context) => !isGeneratedRuleContext(context);
}

final class _FunctionAndMethodDeclarationCheckVisitor extends SimpleAstVisitor<void> {
  const _FunctionAndMethodDeclarationCheckVisitor(this.rule);

  final FunctionAndMethodDeclarationCheckRule rule;

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    rule.checkFunctionDeclaration(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    rule.checkMethodDeclaration(node);
  }
}

final class _MethodDeclarationCheckVisitor extends SimpleAstVisitor<void> {
  const _MethodDeclarationCheckVisitor(this.rule);

  final MethodDeclarationCheckRule rule;

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    rule.checkMethodDeclaration(node);
  }
}

abstract class TryStatementCheckRule extends NodeRegistrationRule {
  TryStatementCheckRule({required super.name, required super.description, required super.code});

  void checkTryStatement(TryStatement node);

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addTryStatement(this, _TryStatementCheckVisitor(this));
  }
}

abstract class BlockCheckRule extends NodeRegistrationRule {
  BlockCheckRule({required super.name, required super.description, required super.code});

  void checkBlock(Block node);

  bool shouldRegister(RuleContext context) => true;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (!shouldRegister(context)) return;
    registry.addBlock(this, _BlockCheckVisitor(this));
  }
}

abstract class ClassDeclarationCheckRule extends NodeRegistrationRule {
  ClassDeclarationCheckRule({required super.name, required super.description, required super.code});

  void checkClassDeclaration(ClassDeclaration node);

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addClassDeclaration(this, _ClassDeclarationCheckVisitor(this));
  }
}

abstract class CascadeExpressionCheckRule extends NodeRegistrationRule {
  CascadeExpressionCheckRule({
    required super.name,
    required super.description,
    required super.code,
  });

  void checkCascadeExpression(CascadeExpression node);

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addCascadeExpression(this, _CascadeExpressionCheckVisitor(this));
  }
}

abstract class ClassAndInstanceCreationCheckRule extends NodeRegistrationRule {
  ClassAndInstanceCreationCheckRule({
    required super.name,
    required super.description,
    required super.code,
  });

  void checkClassDeclaration(ClassDeclaration node);

  void checkInstanceCreationExpression(InstanceCreationExpression node);

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final visitor = _ClassAndInstanceCreationCheckVisitor(this);
    registry
      ..addClassDeclaration(this, visitor)
      ..addInstanceCreationExpression(this, visitor);
  }
}

abstract class ExtensionTypeDeclarationCheckRule extends NodeRegistrationRule {
  ExtensionTypeDeclarationCheckRule({
    required super.name,
    required super.description,
    required super.code,
  });

  bool shouldRegister(RuleContext context) => true;

  void checkExtensionTypeDeclaration(ExtensionTypeDeclaration node);

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (!shouldRegister(context)) return;
    registry.addExtensionTypeDeclaration(this, _ExtensionTypeDeclarationCheckVisitor(this));
  }
}

abstract class GeneratedExtensionTypeDeclarationCheckRule
    extends ExtensionTypeDeclarationCheckRule {
  GeneratedExtensionTypeDeclarationCheckRule({
    required super.name,
    required super.description,
    required super.code,
  });

  @override
  bool shouldRegister(RuleContext context) => !isGeneratedRuleContext(context);
}

final class _ExtensionTypeDeclarationCheckVisitor extends SimpleAstVisitor<void> {
  const _ExtensionTypeDeclarationCheckVisitor(this.rule);

  final ExtensionTypeDeclarationCheckRule rule;

  @override
  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    rule.checkExtensionTypeDeclaration(node);
  }
}

final class _ClassAndInstanceCreationCheckVisitor extends SimpleAstVisitor<void> {
  const _ClassAndInstanceCreationCheckVisitor(this.rule);

  final ClassAndInstanceCreationCheckRule rule;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    rule.checkClassDeclaration(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    rule.checkInstanceCreationExpression(node);
  }
}

final class _CascadeExpressionCheckVisitor extends SimpleAstVisitor<void> {
  const _CascadeExpressionCheckVisitor(this.rule);

  final CascadeExpressionCheckRule rule;

  @override
  void visitCascadeExpression(CascadeExpression node) {
    rule.checkCascadeExpression(node);
  }
}

final class _ClassDeclarationCheckVisitor extends SimpleAstVisitor<void> {
  const _ClassDeclarationCheckVisitor(this.rule);

  final ClassDeclarationCheckRule rule;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    rule.checkClassDeclaration(node);
  }
}

abstract class ExpressionStatementCheckRule extends NodeRegistrationRule {
  ExpressionStatementCheckRule({
    required super.name,
    required super.description,
    required super.code,
  });

  void checkExpressionStatement(ExpressionStatement node);

  bool shouldRegister(RuleContext context) => true;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addExpressionStatement(this, _ExpressionStatementCheckVisitor(this));
  }
}

abstract class GeneratedExpressionStatementCheckRule extends ExpressionStatementCheckRule {
  GeneratedExpressionStatementCheckRule({
    required super.name,
    required super.description,
    required super.code,
  });

  @override
  bool shouldRegister(RuleContext context) => !isGeneratedRuleContext(context);
}

abstract class AssignmentExpressionCheckRule extends NodeRegistrationRule {
  AssignmentExpressionCheckRule({
    required super.name,
    required super.description,
    required super.code,
  });

  void checkAssignmentExpression(AssignmentExpression node);

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addAssignmentExpression(this, _AssignmentExpressionCheckVisitor(this));
  }
}

final class _AssignmentExpressionCheckVisitor extends SimpleAstVisitor<void> {
  const _AssignmentExpressionCheckVisitor(this.rule);

  final AssignmentExpressionCheckRule rule;

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    rule.checkAssignmentExpression(node);
  }
}

abstract class ReturnStatementCheckRule extends NodeRegistrationRule {
  ReturnStatementCheckRule({required super.name, required super.description, required super.code});

  bool shouldRegister(RuleContext context) => true;

  void checkReturnStatement(ReturnStatement node);

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (!shouldRegister(context)) return;
    registry.addReturnStatement(this, _ReturnStatementCheckVisitor(this));
  }
}

final class _ReturnStatementCheckVisitor extends SimpleAstVisitor<void> {
  const _ReturnStatementCheckVisitor(this.rule);

  final ReturnStatementCheckRule rule;

  @override
  void visitReturnStatement(ReturnStatement node) {
    rule.checkReturnStatement(node);
  }
}

abstract class AsExpressionCheckRule extends NodeRegistrationRule {
  AsExpressionCheckRule({required super.name, required super.description, required super.code});

  bool shouldRegister(RuleContext context) => true;

  void checkAsExpression(AsExpression node);

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (!shouldRegister(context)) return;
    registry.addAsExpression(this, _AsExpressionCheckVisitor(this));
  }
}

final class _AsExpressionCheckVisitor extends SimpleAstVisitor<void> {
  const _AsExpressionCheckVisitor(this.rule);

  final AsExpressionCheckRule rule;

  @override
  void visitAsExpression(AsExpression node) {
    rule.checkAsExpression(node);
  }
}

abstract class GenericFunctionTypeCheckRule extends NodeRegistrationRule {
  GenericFunctionTypeCheckRule({
    required super.name,
    required super.description,
    required super.code,
  });

  void checkCallbackReturnType(GenericFunctionType node, NamedType returnType);

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addGenericFunctionType(this, _GenericFunctionTypeCheckVisitor(this));
  }
}

final class _GenericFunctionTypeCheckVisitor extends SimpleAstVisitor<void> {
  const _GenericFunctionTypeCheckVisitor(this.rule);

  final GenericFunctionTypeCheckRule rule;

  @override
  void visitGenericFunctionType(GenericFunctionType node) {
    if (node.parent is GenericTypeAlias) return;
    if (node.typeParameters != null || node.parameters.parameters.isNotEmpty) return;

    final returnType = node.returnType;
    if (returnType is NamedType) rule.checkCallbackReturnType(node, returnType);
  }
}

final class _TryStatementCheckVisitor extends SimpleAstVisitor<void> {
  const _TryStatementCheckVisitor(this.rule);

  final TryStatementCheckRule rule;

  @override
  void visitTryStatement(TryStatement node) {
    rule.checkTryStatement(node);
  }
}

final class _ExpressionStatementCheckVisitor extends SimpleAstVisitor<void> {
  const _ExpressionStatementCheckVisitor(this.rule);

  final ExpressionStatementCheckRule rule;

  @override
  void visitExpressionStatement(ExpressionStatement node) {
    rule.checkExpressionStatement(node);
  }
}

abstract class NamedTypeCheckRule extends NodeRegistrationRule {
  NamedTypeCheckRule({required super.name, required super.description, required super.code});

  bool shouldRegister(RuleContext context) => true;

  void checkNamedType(NamedType node);

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (!shouldRegister(context)) return;
    registry.addNamedType(this, _NamedTypeCheckVisitor(this));
  }
}

abstract class GeneratedNamedTypeCheckRule extends NamedTypeCheckRule {
  GeneratedNamedTypeCheckRule({
    required super.name,
    required super.description,
    required super.code,
  });

  @override
  bool shouldRegister(RuleContext context) => !isGeneratedRuleContext(context);
}

final class _NamedTypeCheckVisitor extends SimpleAstVisitor<void> {
  const _NamedTypeCheckVisitor(this.rule);

  final NamedTypeCheckRule rule;

  @override
  void visitNamedType(NamedType node) {
    rule.checkNamedType(node);
  }
}

abstract class CompilationUnitCheckRule extends NodeRegistrationRule {
  CompilationUnitCheckRule({required super.name, required super.description, required super.code});

  bool shouldRegister(RuleContext context) => true;

  void checkCompilationUnit(CompilationUnit node);

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (!shouldRegister(context)) return;
    registry.addCompilationUnit(this, _CompilationUnitCheckVisitor(this));
  }
}

abstract class GeneratedCompilationUnitCheckRule extends CompilationUnitCheckRule {
  GeneratedCompilationUnitCheckRule({
    required super.name,
    required super.description,
    required super.code,
  });

  @override
  bool shouldRegister(RuleContext context) => !isGeneratedRuleContext(context);
}

final class _CompilationUnitCheckVisitor extends SimpleAstVisitor<void> {
  const _CompilationUnitCheckVisitor(this.rule);

  final CompilationUnitCheckRule rule;

  @override
  void visitCompilationUnit(CompilationUnit node) {
    rule.checkCompilationUnit(node);
  }
}

final class _BlockCheckVisitor extends SimpleAstVisitor<void> {
  const _BlockCheckVisitor(this.rule);

  final BlockCheckRule rule;

  @override
  void visitBlock(Block node) {
    rule.checkBlock(node);
  }
}
