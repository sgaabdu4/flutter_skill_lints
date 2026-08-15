import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Warns when a block only wraps another block.
final class AvoidUnnecessaryBlock extends BlockCheckRule {
  static const LintCode code = LintCode(
    'avoid_unnecessary_block',
    'Avoid unnecessary nested blocks.',
    correctionMessage: 'Inline the nested block statements into the outer block.',
  );

  AvoidUnnecessaryBlock()
    : super(
        name: 'avoid_unnecessary_block',
        description: 'Warns when a block statement contains only another block.',
        code: code,
      );

  @override
  bool shouldRegister(RuleContext context) => !isGeneratedRuleContext(context);

  @override
  void checkBlock(Block node) {
    final statements = node.statements;
    if (statements.length != 1) return;

    final statement = statements.single;
    if (statement is! Block) return;

    reportAtNode(statement);
  }
}
