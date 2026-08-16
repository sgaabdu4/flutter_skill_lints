import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';

/// Warns when a class containing only static members is not marked as
/// `abstract final`, which would prevent instantiation and inheritance.
class PreferAbstractFinalStaticClass extends ClassDeclarationRule {
  static const LintCode code = LintCode(
    'prefer_abstract_final_static_class',
    'Classes with only static members should be declared as abstract final.',
    correctionMessage:
        "Add 'abstract final' modifiers to prevent "
        'instantiation and inheritance.',
  );

  PreferAbstractFinalStaticClass()
    : super(
        name: 'prefer_abstract_final_static_class',
        description: 'Warns when a class with only static members is not abstract final.',
        code: code,
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferAbstractFinalStaticClass rule;

  _Visitor(this.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final body = node.body;
    if (_isEligibleDeclaration(node) && body is BlockClassBody && _hasOnlyStaticMembers(body)) {
      rule.reportAtNode(node);
    }
  }

  static bool _isEligibleDeclaration(ClassDeclaration node) {
    if (node.abstractKeyword != null && node.finalKeyword != null) return false;
    return node.sealedKeyword == null &&
        node.baseKeyword == null &&
        node.interfaceKeyword == null &&
        node.mixinKeyword == null;
  }

  static bool _hasOnlyStaticMembers(BlockClassBody body) {
    if (body.members.isEmpty) return false;
    for (final member in body.members) {
      final isStatic = switch (member) {
        MethodDeclaration(:final isStatic) => isStatic,
        FieldDeclaration(:final isStatic) => isStatic,
        _ => false,
      };
      if (!isStatic) return false;
    }
    return true;
  }
}
