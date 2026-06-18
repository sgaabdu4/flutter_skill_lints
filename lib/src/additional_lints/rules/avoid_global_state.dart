import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when mutable state is declared at library or class-static scope.
final class AvoidGlobalState extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_global_state',
    'Avoid mutable global state.',
    correctionMessage: 'Make the value final/const or move the state behind an instance boundary.',
  );

  AvoidGlobalState()
    : super(
        name: 'avoid_global_state',
        description: 'Warns when mutable state is declared at library or static class scope.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final visitor = _Visitor(this);
    registry
      ..addTopLevelVariableDeclaration(this, visitor)
      ..addFieldDeclaration(this, visitor);
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidGlobalState rule;

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    if (_isImmutable(node.variables)) return;
    _reportVariables(node.variables);
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    if (!node.isStatic || _isImmutable(node.fields)) return;
    _reportVariables(node.fields);
  }

  void _reportVariables(VariableDeclarationList variables) {
    for (final variable in variables.variables) {
      rule.reportAtOffset(variable.name.offset, variable.name.length);
    }
  }

  bool _isImmutable(VariableDeclarationList variables) {
    return variables.isFinal || variables.isConst;
  }
}
