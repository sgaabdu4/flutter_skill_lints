import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when a block contains no statements.
class NoEmptyBlock extends AnalysisRule {
  static const LintCode code = LintCode(
    'no_empty_block',
    'Avoid empty blocks.',
    correctionMessage: 'Remove the block or add the missing statement.',
  );

  NoEmptyBlock()
    : super(
        name: 'no_empty_block',
        description: 'Warns when an executable block has no statements.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addBlock(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final NoEmptyBlock rule;

  @override
  void visitBlock(Block node) {
    if (node.statements.isNotEmpty) return;
    if (node.parent is BlockFunctionBody) return;

    rule.reportAtNode(node);
  }
}
