import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';

/// Warns when declarations use placeholder names.
class AvoidBannedNames extends CompilationUnitRule {
  static const LintCode code = LintCode(
    'avoid_banned_names',
    "Avoid banned name '{0}'.",
    correctionMessage: 'Rename the declaration to describe its role.',
  );

  static const bannedNames = {'foo', 'bar', 'baz'};

  AvoidBannedNames()
    : super(
        name: 'avoid_banned_names',
        description: 'Warns when declarations use banned names.',
        code: code,
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

final class _Visitor extends RecursiveAstVisitor<void> {
  _Visitor(this.rule);

  final AvoidBannedNames rule;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    _check(node.namePart.typeName);
    super.visitClassDeclaration(node);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    final name = node.name;
    if (name != null) _check(name);
    super.visitConstructorDeclaration(node);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    _check(node.namePart.typeName);
    super.visitEnumDeclaration(node);
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    final name = node.name;
    if (name != null) _check(name);
    super.visitExtensionDeclaration(node);
  }

  @override
  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    _check(node.namePart.typeName);
    super.visitExtensionTypeDeclaration(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _check(node.name);
    super.visitFunctionDeclaration(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (!_hasOverrideAnnotation(node.metadata)) _check(node.name);
    super.visitMethodDeclaration(node);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    _check(node.name);
    super.visitMixinDeclaration(node);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    if (!_isOverrideMember(node)) _check(node.name);
    super.visitVariableDeclaration(node);
  }

  @override
  void visitRegularFormalParameter(RegularFormalParameter node) {
    final name = node.name;
    if (name != null && !_isOverrideParameter(node)) _check(name);
    super.visitRegularFormalParameter(node);
  }

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    final name = node.name;
    if (!_isOverrideParameter(node)) _check(name);
    super.visitFieldFormalParameter(node);
  }

  @override
  void visitSuperFormalParameter(SuperFormalParameter node) {
    final name = node.name;
    if (!_isOverrideParameter(node)) _check(name);
    super.visitSuperFormalParameter(node);
  }

  void _check(Token token) {
    final name = token.lexeme;
    if (!AvoidBannedNames.bannedNames.contains(name)) return;
    rule.reportAtToken(token, arguments: [name]);
  }
}

bool _isOverrideMember(VariableDeclaration node) {
  final field = node.thisOrAncestorOfType<FieldDeclaration>();
  return field != null && _hasOverrideAnnotation(field.metadata);
}

bool _isOverrideParameter(FormalParameter node) {
  final method = node.thisOrAncestorOfType<MethodDeclaration>();
  return method != null && _hasOverrideAnnotation(method.metadata);
}

bool _hasOverrideAnnotation(NodeList<Annotation> metadata) {
  return metadata.any((annotation) => annotation.name.name == 'override');
}
