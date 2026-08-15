import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Reports switch statements nested directly in another switch member body.
final class AvoidNestedSwitches extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_nested_switches',
    'Avoid nested switch statements.',
    correctionMessage: 'Extract the nested switch into a named helper.',
  );

  AvoidNestedSwitches()
    : super(
        name: 'avoid_nested_switches',
        description: 'Reports switch statements nested directly in a switch member body.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addSwitchStatement(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidNestedSwitches rule;

  @override
  void visitSwitchStatement(SwitchStatement node) {
    for (final member in node.members) {
      for (final statement in member.statements) {
        if (statement is SwitchStatement) {
          rule.reportAtNode(statement);
        }
      }
    }
  }
}
