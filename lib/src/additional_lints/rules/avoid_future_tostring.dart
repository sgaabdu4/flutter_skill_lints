import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';

/// Warns when `toString()` is called on a Future.
class AvoidFutureToString extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_future_tostring',
    'Avoid calling toString() on a Future.',
    correctionMessage: 'Await the Future or handle its result before converting it to a string.',
    severity: DiagnosticSeverity.ERROR,
  );

  AvoidFutureToString()
    : super(name: 'avoid_future_tostring', description: 'Warns when Future.toString() is used.');

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addMethodInvocation(this, _Visitor(this));
    registry.addInterpolationExpression(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidFutureToString rule;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'toString') return;
    if (node.argumentList.arguments.isNotEmpty) return;
    if (!isFutureLikeType(node.target?.staticType)) return;
    rule.reportAtNode(node.methodName);
  }

  @override
  void visitInterpolationExpression(InterpolationExpression node) {
    if (!isFutureLikeType(node.expression.staticType)) return;

    rule.reportAtNode(node.expression);
  }
}
