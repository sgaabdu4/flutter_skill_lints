import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/riverpod_consumer_checkers.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Warns when `ref` is accessed inside a Riverpod `ConsumerState.dispose()`.
class AvoidRefInsideStateDispose extends MethodDeclarationRule with SkipGeneratedSources {
  static const LintCode code = LintCode(
    'avoid_ref_inside_state_dispose',
    "Avoid using 'ref' inside ConsumerState.dispose().",
    correctionMessage:
        'Move provider cleanup into ref.onDispose(), a subscription close call, or an earlier lifecycle method.',
  );

  AvoidRefInsideStateDispose()
    : super(
        name: 'avoid_ref_inside_state_dispose',
        description: 'Warns when ConsumerState.dispose() accesses Riverpod ref.',
        code: code,
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AvoidRefInsideStateDispose rule;

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.name.lexeme != 'dispose') return;

    final classDecl = enclosingClass(node);
    if (classDecl == null || !isClassAssignableTo(classDecl, consumerStateChecker)) return;

    final finder = _RefAccessFinder(rule);
    node.body.visitChildren(finder);
  }
}

class _RefAccessFinder extends RecursiveAstVisitor<void> {
  _RefAccessFinder(this.rule);

  final AvoidRefInsideStateDispose rule;

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.name != 'ref') {
      super.visitSimpleIdentifier(node);
      return;
    }

    if (isExpressionTargetIdentifier(node)) return;

    rule.reportAtNode(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.target case SimpleIdentifier(name: 'ref')) {
      rule.reportAtNode(node);
      return;
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.prefix.name == 'ref') {
      rule.reportAtNode(node);
      return;
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.target case SimpleIdentifier(name: 'ref')) {
      rule.reportAtNode(node);
      return;
    }
    super.visitPropertyAccess(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}

  @override
  void visitFunctionExpression(FunctionExpression node) {}
}
