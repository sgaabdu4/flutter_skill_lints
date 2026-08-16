import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';

/// Warns when an `else` wraps code after a branch that always exits.
class AvoidRedundantElse extends IfStatementRule {
  static const LintCode code = LintCode(
    'avoid_redundant_else',
    'Avoid else after a branch that exits.',
    correctionMessage: 'Remove the else and place its body after the exiting branch.',
    severity: DiagnosticSeverity.ERROR,
  );

  AvoidRedundantElse()
    : super(
        name: 'avoid_redundant_else',
        description: 'Warns when else follows a return, throw, break, or continue branch.',
        code: code,
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidRedundantElse rule;

  @override
  void visitIfStatement(IfStatement node) {
    final elseKeyword = node.elseKeyword;
    final elseStatement = node.elseStatement;
    if (elseKeyword == null || elseStatement == null) return;
    if (elseStatement is IfStatement) return;
    if (!_exitsControlFlow(node.thenStatement)) return;

    rule.reportAtToken(elseKeyword);
  }
}

bool _exitsControlFlow(Statement statement) {
  final unwrapped = _unwrapSingleStatementBlock(statement);
  return switch (unwrapped) {
    ReturnStatement() || BreakStatement() || ContinueStatement() => true,
    ExpressionStatement(:final expression) =>
      expression is ThrowExpression || expression is RethrowExpression,
    _ => false,
  };
}

Statement _unwrapSingleStatementBlock(Statement statement) {
  var current = statement;
  while (current is Block && current.statements.length == 1) {
    current = current.statements.single;
  }
  return current;
}
