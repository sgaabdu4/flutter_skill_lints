import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when a labeled statement is used.
class AvoidLabels extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_labels',
    'Avoid labeled statements.',
    correctionMessage: 'Refactor the control flow so the label is no longer needed.',
    severity: DiagnosticSeverity.ERROR,
  );

  AvoidLabels()
    : super(name: 'avoid_labels', description: 'Warns when labeled statements are used.');

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final visitor = _Visitor(this);
    registry.addLabeledStatement(this, visitor);
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidLabels rule;

  @override
  void visitLabeledStatement(LabeledStatement node) {
    rule.reportAtNode(node.labels.first);
  }
}
