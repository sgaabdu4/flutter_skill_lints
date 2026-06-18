import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../type_checker.dart';

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

  static const _futureChecker = TypeChecker.fromUrl('dart:async#Future');

  final AvoidFutureToString rule;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'toString') return;
    if (node.argumentList.arguments.isNotEmpty) return;
    final targetType = node.target?.staticType;
    if (targetType == null || !_futureChecker.isAssignableFromType(targetType)) return;
    rule.reportAtNode(node.methodName);
  }

  @override
  void visitInterpolationExpression(InterpolationExpression node) {
    final expressionType = node.expression.staticType;
    if (expressionType == null || !_futureChecker.isAssignableFromType(expressionType)) return;

    rule.reportAtNode(node.expression);
  }
}
