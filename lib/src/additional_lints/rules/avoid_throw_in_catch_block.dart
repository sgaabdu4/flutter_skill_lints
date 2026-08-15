import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';

/// Warns when a `throw` expression is used inside a catch block.
///
/// Calling `throw` inside a catch block loses the original stack trace
/// and exception context. Use `rethrow` to re-throw the original exception,
/// or `Error.throwWithStackTrace()` to throw a new exception while
/// preserving the stack trace.
///
/// **Bad:**
/// ```dart
/// try {
///   networkDataProvider();
/// } on Object {
///   throw RepositoryException();
/// }
/// ```
///
/// **Good:**
/// ```dart
/// try {
///   networkDataProvider();
/// } catch (_, stack) {
///   Error.throwWithStackTrace(RepositoryException(), stack);
/// }
/// ```
class AvoidThrowInCatchBlock extends TryStatementCheckRule {
  static const LintCode code = LintCode(
    'avoid_throw_in_catch_block',
    'Avoid using throw inside a catch block.',
    correctionMessage: 'Use Error.throwWithStackTrace() to preserve the stack trace.',
  );

  AvoidThrowInCatchBlock()
    : super(
        name: 'avoid_throw_in_catch_block',
        description: 'Warns when a throw expression is used inside a catch block.',
        code: code,
      );

  @override
  void checkTryStatement(TryStatement node) {
    for (final catchClause in node.catchClauses) {
      final throwFinder = _ThrowFinder(this);
      catchClause.body.visitChildren(throwFinder);
    }
  }
}

class _ThrowFinder extends RecursiveAstVisitor<void> {
  final AvoidThrowInCatchBlock rule;

  _ThrowFinder(this.rule);

  @override
  void visitThrowExpression(ThrowExpression node) {
    rule.reportAtNode(node);
    super.visitThrowExpression(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    // Don't traverse into nested functions/closures —
    // a throw inside a closure is not in the catch block's scope.
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    // Don't traverse into nested function declarations.
  }
}
