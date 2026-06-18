import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Warns when a block only wraps another block.
final class AvoidUnnecessaryBlock extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_unnecessary_block',
    'Avoid unnecessary nested blocks.',
    correctionMessage: 'Inline the nested block statements into the outer block.',
    severity: DiagnosticSeverity.INFO,
  );

  AvoidUnnecessaryBlock()
    : super(
        name: 'avoid_unnecessary_block',
        description: 'Warns when a block statement contains only another block.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (isGeneratedRuleContext(context)) return;

    registry.addBlock(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidUnnecessaryBlock rule;

  @override
  void visitBlock(Block node) {
    final statements = node.statements;
    if (statements.length != 1) return;

    final statement = statements.single;
    if (statement is! Block) return;

    rule.reportAtNode(statement);
  }
}
