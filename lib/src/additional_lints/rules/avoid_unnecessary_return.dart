import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Warns when a void function ends with `return;`.
final class AvoidUnnecessaryReturn extends ReturnStatementCheckRule {
  static const LintCode code = LintCode(
    'avoid_unnecessary_return',
    'Avoid unnecessary return statements.',
    correctionMessage: 'Remove the trailing `return;`.',
  );

  AvoidUnnecessaryReturn()
    : super(
        name: 'avoid_unnecessary_return',
        description: 'Warns when a void function ends with a bare return statement.',
        code: code,
      );

  @override
  bool shouldRegister(RuleContext context) => !isGeneratedRuleContext(context);

  @override
  void checkReturnStatement(ReturnStatement node) {
    if (node.expression != null) return;

    final block = node.parent;
    if (block is! Block || block.statements.last != node) return;

    final body = block.parent;
    if (body is! BlockFunctionBody || body.block != block) return;
    if (!_hasVoidReturnType(body)) return;

    reportAtNode(node);
  }
}

bool _hasVoidReturnType(FunctionBody body) {
  final parent = body.parent;

  return switch (parent) {
    MethodDeclaration(:final returnType) => _isVoidType(returnType),
    FunctionExpression(:final parent) when parent is FunctionDeclaration => _isVoidType(
      parent.returnType,
    ),
    _ => false,
  };
}

bool _isVoidType(TypeAnnotation? type) {
  return type is NamedType && type.name.lexeme == 'void';
}
