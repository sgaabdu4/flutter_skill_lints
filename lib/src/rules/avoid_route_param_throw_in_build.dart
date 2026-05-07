import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Don't throw from route-param lookups in build().
///
/// Why: Bans firstWhere(... orElse: () => throw...) inside build methods. Use a nullable by-id
/// provider and render fallback UI instead.
final class AvoidRouteParamThrowInBuild extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_route_param_throw_in_build',
    "Don't throw from route-param lookups in build().",
    correctionMessage: 'Use a nullable by-id provider and render fallback UI instead.',
  );

  AvoidRouteParamThrowInBuild()
    : super(
        name: 'avoid_route_param_throw_in_build',
        description: 'Bans firstWhere(... orElse: () => throw ...) inside build methods.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (isGeneratedRuleContext(context)) return;
    registry.addMethodInvocation(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AvoidRouteParamThrowInBuild rule;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'firstWhere') return;
    final method = enclosingMethod(node);
    if (method == null || method.name.lexeme != 'build') return;
    if (containsThrowExpression(node.argumentList)) {
      rule.reportAtNode(node.methodName);
    }
  }
}
