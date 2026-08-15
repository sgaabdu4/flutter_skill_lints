import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';

/// Warns when a try statement is nested in another try statement.
class AvoidNestedTryStatements extends TryStatementCheckRule {
  static const LintCode code = LintCode(
    'avoid_nested_try_statements',
    'Avoid nested try statements.',
    correctionMessage: 'Extract the inner operation or handle errors in one place.',
  );

  AvoidNestedTryStatements()
    : super(
        name: 'avoid_nested_try_statements',
        description: 'Warns when a try statement is nested in another try statement.',
        code: code,
      );

  @override
  void checkTryStatement(TryStatement node) {
    if (_hasEnclosingTryStatement(node)) {
      reportAtNode(node);
    }
  }
}

bool _hasEnclosingTryStatement(TryStatement node) {
  AstNode? parent = node.parent;

  while (parent != null) {
    if (parent is TryStatement) return true;
    if (parent is FunctionBody) return false;
    parent = parent.parent;
  }

  return false;
}
