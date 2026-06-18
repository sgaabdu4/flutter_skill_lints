import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when enum values are accessed by numeric index.
class AvoidEnumValuesByIndex extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_enum_values_by_index',
    'Avoid accessing enum values by index.',
    correctionMessage: 'Use the enum constant directly or resolve it by name.',
  );

  AvoidEnumValuesByIndex()
    : super(
        name: 'avoid_enum_values_by_index',
        description: 'Warns when Enum.values is indexed directly.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addIndexExpression(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidEnumValuesByIndex rule;

  @override
  void visitIndexExpression(IndexExpression node) {
    if (_isValuesAccess(node.target)) {
      rule.reportAtNode(node);
    }
  }
}

bool _isValuesAccess(Expression? target) {
  return switch (target) {
    PrefixedIdentifier(identifier: SimpleIdentifier(name: 'values')) => true,
    PropertyAccess(propertyName: SimpleIdentifier(name: 'values')) => true,
    _ => false,
  };
}
