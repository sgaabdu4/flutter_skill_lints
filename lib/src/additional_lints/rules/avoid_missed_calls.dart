import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';

/// Warns when a Future-producing expression statement is neither awaited nor
/// otherwise handled.
final class AvoidMissedCalls extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_missed_calls',
    'Handle the returned Future.',
    correctionMessage: 'Await it, return it, assign it, or pass it to unawaited().',
  );

  AvoidMissedCalls()
    : super(
        name: 'avoid_missed_calls',
        description: 'Warns when Future-returning calls are used as bare statements.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addExpressionStatement(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidMissedCalls rule;

  @override
  void visitExpressionStatement(ExpressionStatement node) {
    final expression = node.expression;
    if (expression is AwaitExpression) return;
    if (expression is AssignmentExpression) return;
    if (!_isAsyncLike(expression.staticType)) return;

    rule.reportAtNode(expression);
  }
}

const _futureChecker = TypeChecker.fromUrl('dart:async#Future');

bool _isAsyncLike(DartType? type) {
  if (type == null) return false;
  if (type is InterfaceType && _futureChecker.isAssignableFromType(type)) {
    return true;
  }
  return type.element?.name == 'FutureOr';
}
