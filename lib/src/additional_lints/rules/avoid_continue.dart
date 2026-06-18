import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when a continue statement is used.
class AvoidContinue extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_continue',
    'Avoid continue statements.',
    correctionMessage: 'Refactor the loop body so continue is no longer needed.',
    severity: DiagnosticSeverity.INFO,
  );

  AvoidContinue()
    : super(name: 'avoid_continue', description: 'Warns when continue statements are used.');

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addContinueStatement(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidContinue rule;

  @override
  void visitContinueStatement(ContinueStatement node) {
    rule.reportAtToken(node.continueKeyword);
  }
}
