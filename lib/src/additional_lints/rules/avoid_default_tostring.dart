import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Warns when `toString()` uses the default Object implementation.
class AvoidDefaultToString extends MethodInvocationRule {
  static const LintCode code = LintCode(
    'avoid_default_tostring',
    "Avoid calling default Object.toString() on '{0}'.",
    correctionMessage: 'Declare a meaningful toString() or avoid converting this object directly.',
  );

  AvoidDefaultToString()
    : super(
        code: code,
        name: 'avoid_default_tostring',
        description: 'Warns when local classes use the default Object.toString().',
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidDefaultToString rule;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'toString') return;
    if (node.argumentList.arguments.isNotEmpty) return;

    final type = node.target?.staticType;
    if (type is! InterfaceType) return;

    final className = type.element.name;
    if (className == null) return;

    final declaration = localClassDeclaration(node, className);
    if (declaration == null) return;
    if (!_hasOnlyDefaultToString(declaration, node.root)) return;

    rule.reportAtNode(node.methodName, arguments: [className]);
  }
}

bool _hasOnlyDefaultToString(ClassDeclaration declaration, AstNode root) {
  if (declaresToString(declaration)) return false;

  final superName = declaration.extendsClause?.superclass.name.lexeme;
  if (superName == null || superName == 'Object') return true;

  final superDeclaration = localClassDeclaration(root, superName);
  if (superDeclaration == null) return false;

  return _hasOnlyDefaultToString(superDeclaration, root);
}
