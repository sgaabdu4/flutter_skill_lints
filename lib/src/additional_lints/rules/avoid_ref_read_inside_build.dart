import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/riverpod_consumer_checkers.dart';

/// Warns when `ref.read()` is called inside a `build()` method of a
/// Riverpod consumer widget or consumer state class.
///
/// `ref.read` reads the provider value once and does not listen for changes.
/// Using it inside `build()` means the widget won't rebuild when the
/// provider's value changes. Use `ref.watch()` instead, or move
/// `ref.read()` into callbacks/user interactions that intentionally read once.
class AvoidRefReadInsideBuild extends MethodDeclarationRule {
  static const LintCode code = LintCode(
    'avoid_ref_read_inside_build',
    "Avoid using 'ref.read' inside the build method.",
    correctionMessage:
        "Use 'ref.watch' instead so the widget rebuilds when the "
        "provider's value changes. If you only need a one-time read for "
        "actions, keep 'ref.read' inside callbacks instead.",
  );

  AvoidRefReadInsideBuild()
    : super(
        name: 'avoid_ref_read_inside_build',
        description:
            'Warns when ref.read() is used inside the build method of a '
            'Riverpod consumer widget or state.',
        code: code,
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidRefReadInsideBuild rule;

  _Visitor(this.rule);

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (!isConsumerBuildMethod(node)) return;

    // Search for ref.read() calls inside the build body (excluding closures)
    final finder = _RefReadFinder(rule);
    node.body.visitChildren(finder);
  }
}

/// Recursively searches for `ref.read(...)` calls inside a build body.
///
/// Stops at function boundaries (closures/lambdas) because `ref.read()`
/// inside event handlers like `onPressed: () => ref.read(...)` is intentional.
class _RefReadFinder extends RecursiveAstVisitor<void> {
  final AvoidRefReadInsideBuild rule;

  _RefReadFinder(this.rule);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'read') {
      if (node.target case SimpleIdentifier(name: 'ref')) {
        rule.reportAtNode(node);
        return; // Don't recurse — already reported
      }
    }
    super.visitMethodInvocation(node);
  }

  // Stop at function boundaries — closures are intentional (e.g., onPressed)
  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}
}
