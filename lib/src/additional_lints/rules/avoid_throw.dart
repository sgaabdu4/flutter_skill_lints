import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when a throw expression is used.
class AvoidThrow extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_throw',
    'Avoid throw expressions.',
    correctionMessage: 'Return a typed failure or use the project error boundary.',
  );

  AvoidThrow() : super(name: 'avoid_throw', description: 'Warns when a throw expression is used.');

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addThrowExpression(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidThrow rule;

  @override
  void visitThrowExpression(ThrowExpression node) {
    rule.reportAtNode(node);
  }
}
