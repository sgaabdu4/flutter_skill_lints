import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/postfix_expression_rule.dart';

/// Avoid null assertion operators.
///
/// Why: Bans null assertion expressions. Use pattern matching, early returns, or explicit null
/// handling instead.
final class AvoidNullBang extends GeneratedPostfixExpressionCheckRule {
  static const LintCode code = LintCode(
    'avoid_null_bang',
    'Avoid null assertion operators.',
    correctionMessage: 'Use pattern matching, early returns, or explicit null handling instead.',
  );

  AvoidNullBang()
    : super(name: 'avoid_null_bang', description: 'Bans null assertion expressions.', code: code);

  @override
  void checkPostfixExpression(PostfixExpression node) {
    if (node.operator.lexeme == '!') {
      reportAtToken(node.operator);
    }
  }
}
