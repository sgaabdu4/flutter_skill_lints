import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when an underscore-only variable is read after being declared.
class AvoidReferencingDiscardedVariables extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_referencing_discarded_variables',
    'Avoid referencing discarded variables.',
    correctionMessage: 'Rename the variable to show that the value is intentionally used.',
  );

  AvoidReferencingDiscardedVariables()
    : super(
        name: 'avoid_referencing_discarded_variables',
        description: 'Warns when underscore-only variables are read.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addSimpleIdentifier(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidReferencingDiscardedVariables rule;

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (!_isDiscardedName(node.name)) return;
    if (node.inDeclarationContext() || !node.inGetterContext()) return;

    final parent = node.parent;
    if (parent is DeclaredIdentifier && parent.name == node) return;
    if (parent is VariableDeclaration && parent.name == node) return;
    if (parent is FormalParameter && parent.name == node) return;
    if (parent is FieldFormalParameter && parent.name == node) return;
    if (parent is SuperFormalParameter && parent.name == node) return;

    rule.reportAtNode(node);
  }

  bool _isDiscardedName(String name) {
    if (name.isEmpty) return false;
    return name.codeUnits.every((unit) => unit == 0x5F);
  }
}
