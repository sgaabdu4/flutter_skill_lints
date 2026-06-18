import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when nested `if` statements can be combined.
class AvoidCollapsibleIf extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_collapsible_if',
    'Avoid nested if statements that can be collapsed.',
    correctionMessage: 'Combine the conditions into a single if statement.',
    severity: DiagnosticSeverity.ERROR,
  );

  AvoidCollapsibleIf()
    : super(
        name: 'avoid_collapsible_if',
        description: 'Warns when an if statement only contains another if statement.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addIfStatement(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidCollapsibleIf rule;

  @override
  void visitIfStatement(IfStatement node) {
    if (node.elseStatement != null) return;

    final nestedIf = _singleNestedIf(node.thenStatement);
    if (nestedIf == null || nestedIf.elseStatement != null) return;

    rule.reportAtToken(nestedIf.ifKeyword);
  }
}

IfStatement? _singleNestedIf(Statement statement) {
  if (statement is! Block || statement.statements.length != 1) return null;

  final nested = statement.statements.single;
  return nested is IfStatement ? nested : null;
}
