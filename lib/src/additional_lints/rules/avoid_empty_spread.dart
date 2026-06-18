import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when a collection spread has no elements.
class AvoidEmptySpread extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_empty_spread',
    'Avoid spreading an empty collection.',
    correctionMessage: 'Remove the empty spread element.',
    severity: DiagnosticSeverity.ERROR,
  );

  AvoidEmptySpread()
    : super(
        name: 'avoid_empty_spread',
        description: 'Warns when an empty collection literal is spread into another collection.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addSpreadElement(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidEmptySpread rule;

  @override
  void visitSpreadElement(SpreadElement node) {
    if (_isEmptyCollectionLiteral(node.expression)) {
      rule.reportAtNode(node);
    }
  }
}

bool _isEmptyCollectionLiteral(Expression expression) {
  return switch (expression) {
    ListLiteral(:final elements) || SetOrMapLiteral(:final elements) => elements.isEmpty,
    _ => false,
  };
}
