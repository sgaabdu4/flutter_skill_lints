import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when an `if` statement uses an `else` block.
///
/// Prefer guard clauses, early returns, switch expressions, or separate
/// statements over nested `else` branches.
class AvoidUnnecessaryElseAfterControlFlow extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_unnecessary_else_after_control_flow',
    'Avoid else blocks.',
    correctionMessage: 'Refactor this branch so the else block is not needed.',
    severity: DiagnosticSeverity.ERROR,
  );

  AvoidUnnecessaryElseAfterControlFlow()
    : super(
        name: 'avoid_unnecessary_else_after_control_flow',
        description: 'Avoid else blocks in if statements.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final visitor = _Visitor(this);
    registry
      ..addIfStatement(this, visitor)
      ..addIfElement(this, visitor);
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidUnnecessaryElseAfterControlFlow rule;

  @override
  void visitIfStatement(IfStatement node) {
    final elseStatement = node.elseStatement;
    final elseKeyword = node.elseKeyword;
    if (elseStatement == null || elseKeyword == null) return;
    rule.reportAtToken(elseKeyword);
  }

  @override
  void visitIfElement(IfElement node) {
    final elseElement = node.elseElement;
    final elseKeyword = node.elseKeyword;
    if (elseElement == null || elseKeyword == null) return;
    rule.reportAtToken(elseKeyword);
  }
}
