import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';

/// Warns when the last catch clause contains only a `rethrow` statement.
class AvoidOnlyRethrow extends TryStatementCheckRule {
  static const LintCode code = LintCode(
    'avoid_only_rethrow',
    'Catch clause contains only a rethrow statement.',
    correctionMessage: 'Remove the redundant try-catch block.',
    severity: DiagnosticSeverity.ERROR,
  );

  AvoidOnlyRethrow()
    : super(
        name: 'avoid_only_rethrow',
        description: 'Warns when a catch clause contains only a rethrow statement.',
        code: code,
      );

  @override
  void checkTryStatement(TryStatement node) {
    final catchClause = node.catchClauses.lastOrNull;
    final statement = catchClause?.body.statements.singleOrNull;
    if (statement is ExpressionStatement && statement.expression is RethrowExpression) {
      reportAtNode(catchClause);
    }
  }
}
