import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';

/// Warns when a block contains no statements.
class NoEmptyBlock extends BlockCheckRule {
  static const LintCode code = LintCode(
    'no_empty_block',
    'Avoid empty blocks.',
    correctionMessage: 'Remove the block or add the missing statement.',
  );

  NoEmptyBlock()
    : super(
        name: 'no_empty_block',
        description: 'Warns when an executable block has no statements.',
        code: code,
      );

  @override
  void checkBlock(Block node) {
    if (node.statements.isNotEmpty) return;
    if (node.parent is BlockFunctionBody) return;

    reportAtNode(node);
  }
}
