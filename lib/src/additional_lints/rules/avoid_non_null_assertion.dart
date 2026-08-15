import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/postfix_expression_rule.dart';

/// Warns when a postfix null assertion operator is used.
class AvoidNonNullAssertion extends GeneratedPostfixExpressionCheckRule {
  static const LintCode code = LintCode(
    'avoid_non_null_assertion',
    'Avoid using null assertion operators.',
    correctionMessage: 'Handle the null case explicitly before using the value.',
    severity: DiagnosticSeverity.ERROR,
  );

  AvoidNonNullAssertion()
    : super(
        name: 'avoid_non_null_assertion',
        description: 'Warns when a postfix null assertion operator is used.',
        code: code,
      );

  @override
  void checkPostfixExpression(PostfixExpression node) {
    if (node.operator.lexeme != '!') return;
    reportAtToken(node.operator);
  }
}
