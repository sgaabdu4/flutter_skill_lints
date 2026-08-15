import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Warns when a void expression is returned.
final class AvoidReturningVoid extends ReturnStatementCheckRule {
  static const LintCode code = LintCode(
    'avoid_returning_void',
    'Avoid returning void expressions.',
    correctionMessage: 'Call the void expression before returning, or use `return;`.',
  );

  AvoidReturningVoid()
    : super(
        name: 'avoid_returning_void',
        description: 'Warns when return statements return void expressions.',
        code: code,
      );

  @override
  bool shouldRegister(RuleContext context) => !isGeneratedRuleContext(context);

  @override
  void checkReturnStatement(ReturnStatement node) {
    final expression = node.expression;
    if (expression == null) return;
    if (expression.staticType is! VoidType) return;

    reportAtNode(expression);
  }
}
