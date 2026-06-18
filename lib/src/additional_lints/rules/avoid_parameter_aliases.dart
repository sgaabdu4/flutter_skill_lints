import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

/// Warns when a local variable directly aliases an existing local value.
final class AvoidParameterAliases extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_parameter_aliases',
    'Avoid copying values into pass-through local variables.',
    correctionMessage:
        'Use the existing value directly or create a derived value instead of a pass-through alias.',
  );

  AvoidParameterAliases()
    : super(
        name: 'avoid_parameter_aliases',
        description: 'Warns when local variables directly copy existing local or parameter values.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addVariableDeclaration(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidParameterAliases rule;

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    if (!_isLocalVariableStatement(node)) return;

    final initializer = node.initializer?.unParenthesized;
    if (initializer is! SimpleIdentifier) return;
    if (!_isAliasSource(initializer.element)) return;

    rule.reportAtToken(node.name);
  }
}

bool _isAliasSource(Element? element) {
  return element is FormalParameterElement || element is LocalVariableElement;
}

bool _isLocalVariableStatement(VariableDeclaration node) {
  final parent = node.parent;
  return parent is VariableDeclarationList && parent.parent is VariableDeclarationStatement;
}
