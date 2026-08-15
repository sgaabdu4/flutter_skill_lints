import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';

/// Warns when a catch clause contains only a `rethrow` statement.
///
/// Such catch clauses are redundant because they don't handle exceptions —
/// they simply re-throw them. Either add meaningful exception handling or
/// remove the catch clause entirely.
///
/// **Bad:**
/// ```dart
/// try {
///   doSomething();
/// } catch (e) {
///   rethrow;
/// }
/// ```
///
/// **Good:**
/// ```dart
/// // Option 1: Add exception handling
/// try {
///   doSomething();
/// } catch (e) {
///   logger.error(e);
///   rethrow;
/// }
///
/// // Option 2: Remove redundant catch clause
/// doSomething();
/// ```
class AvoidOnlyRethrow extends TryStatementCheckRule {
  static const LintCode code = LintCode(
    'avoid_only_rethrow',
    'Catch clause contains only a rethrow statement.',
    correctionMessage: 'Remove the redundant try-catch block.',
  );

  AvoidOnlyRethrow()
    : super(
        name: 'avoid_only_rethrow',
        description: 'Warns when a catch clause contains only a rethrow statement.',
        code: code,
      );

  @override
  @override
  void checkTryStatement(TryStatement node) {
    for (final catchClause in node.catchClauses) {
      final statements = catchClause.body.statements;
      if (statements.length != 1) continue;

      final statement = statements.first;
      if (statement is! ExpressionStatement) continue;

      if (statement.expression is RethrowExpression) {
        reportAtNode(catchClause);
      }
    }
  }
}
