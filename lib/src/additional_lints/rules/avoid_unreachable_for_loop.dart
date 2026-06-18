import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Reports a `for` loop whose condition is the literal `false`.
class AvoidUnreachableForLoop extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_unreachable_for_loop',
    'Avoid unreachable for loops.',
    correctionMessage: 'Remove the loop or change the false condition.',
    severity: DiagnosticSeverity.ERROR,
  );

  AvoidUnreachableForLoop()
    : super(
        name: 'avoid_unreachable_for_loop',
        description: 'Reports for loops with a literal false condition.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addForStatement(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidUnreachableForLoop rule;

  @override
  void visitForStatement(ForStatement node) {
    final condition = switch (node.forLoopParts) {
      ForPartsWithDeclarations(:final condition) => condition,
      ForPartsWithExpression(:final condition) => condition,
      ForPartsWithPattern(:final condition) => condition,
      _ => null,
    };

    if (condition is BooleanLiteral && !condition.value) {
      rule.reportAtNode(condition);
    }
  }
}
