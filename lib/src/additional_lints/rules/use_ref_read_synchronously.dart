import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'package:flutter_skill_lints/src/additional_lints/async_guard_utils.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/riverpod_consumer_checkers.dart';

/// Warns when `ref.read()` is called after an `await` point inside an async
/// callback within a ConsumerWidget or ConsumerState build method without
/// checking if the widget is still mounted.
///
/// After an `await`, the widget may have been unmounted, making `ref.read()`
/// return stale or unintended state.
class UseRefReadSynchronously extends MethodDeclarationRule {
  static const LintCode code = LintCode(
    'use_ref_read_synchronously',
    "Avoid calling 'ref.read' after an await point without checking "
        'if the widget is mounted.',
    correctionMessage:
        "Add a 'if (!mounted) return;' or 'if (!context.mounted) return;' "
        "guard before calling 'ref.read' after an await.",
  );

  UseRefReadSynchronously()
    : super(
        name: 'use_ref_read_synchronously',
        description:
            'Warns when ref.read() is called after an await point in a '
            'ConsumerWidget or ConsumerState without a mounted guard.',
        code: code,
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

class _Visitor extends SimpleAstVisitor<void> {
  final UseRefReadSynchronously rule;

  _Visitor(this.rule);

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (!isConsumerBuildMethod(node)) return;

    // Find async callbacks inside the build method and check for ref.read
    // after await points
    final finder = _AsyncCallbackFinder(rule);
    node.body.visitChildren(finder);
  }
}

/// Finds async function expressions (callbacks) inside the build method
/// and checks each for `ref.read()` usage after `await` points.
class _AsyncCallbackFinder extends RecursiveAstVisitor<void> {
  final UseRefReadSynchronously rule;

  _AsyncCallbackFinder(this.rule);

  @override
  void visitFunctionExpression(FunctionExpression node) {
    if (node.body.isAsynchronous) {
      final body = node.body;
      if (body is BlockFunctionBody) {
        _checkStatements(body.block.statements);
      }
      // Don't recurse into this async body — it's been handled
      return;
    }
    // Continue recursing into non-async lambdas
    super.visitFunctionExpression(node);
  }

  /// Checks a list of statements for ref.read() usage after an await point.
  void _checkStatements(NodeList<Statement> statements) {
    scanStatementsAfterAwait(statements, (statement) => statement.accept(_RefReadFinder(rule)));
  }
}

/// Finds `ref.read(...)` calls in AST nodes.
class _RefReadFinder extends RecursiveAstVisitor<void> {
  final UseRefReadSynchronously rule;

  _RefReadFinder(this.rule);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'read') {
      if (_isRefTarget(node.target)) {
        rule.reportAtNode(node);
        return; // Don't recurse — already reported
      }
    }
    super.visitMethodInvocation(node);
  }

  /// Checks if the target is `ref` or `ref!`.
  static bool _isRefTarget(Expression? target) {
    if (target case SimpleIdentifier(name: 'ref')) {
      return true;
    }
    // Handle ref! (PostfixExpression with ! operator)
    if (target case PostfixExpression(operand: SimpleIdentifier(name: 'ref'))) {
      return true;
    }
    return false;
  }

  // Stop at function boundaries — nested closures may be stored for later
  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}
}
