import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when string literals are placed next to each other.
class AvoidAdjacentStrings extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_adjacent_strings',
    'Avoid adjacent string literals.',
    correctionMessage: 'Use one string literal or explicit interpolation.',
  );

  AvoidAdjacentStrings()
    : super(
        name: 'avoid_adjacent_strings',
        description: 'Warns when adjacent string literals are used.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addAdjacentStrings(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidAdjacentStrings rule;

  @override
  void visitAdjacentStrings(AdjacentStrings node) {
    rule.reportAtNode(node);
  }
}
