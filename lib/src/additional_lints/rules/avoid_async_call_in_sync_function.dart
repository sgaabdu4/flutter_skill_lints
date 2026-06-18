import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';

/// Warns when a synchronous function contains a bare Future-producing call.
final class AvoidAsyncCallInSyncFunction extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_async_call_in_sync_function',
    'Avoid bare async calls in synchronous functions.',
    correctionMessage: 'Make the function async and await the call, or explicitly use unawaited().',
  );

  AvoidAsyncCallInSyncFunction()
    : super(
        name: 'avoid_async_call_in_sync_function',
        description: 'Warns when sync functions contain unhandled Future-returning calls.',
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

  final AvoidAsyncCallInSyncFunction rule;

  @override
  void visitExpressionStatement(ExpressionStatement node) {
    final body = _enclosingFunctionBody(node);
    if (body == null || body.isAsynchronous || body.isGenerator) return;

    final expression = node.expression;
    if (expression is AssignmentExpression) return;
    if (!_isAsyncLike(expression.staticType)) return;

    rule.reportAtNode(expression);
  }
}

const _futureChecker = TypeChecker.fromUrl('dart:async#Future');

FunctionBody? _enclosingFunctionBody(AstNode node) {
  AstNode? current = node.parent;
  while (current != null) {
    if (current is FunctionBody) return current;
    current = current.parent;
  }
  return null;
}

bool _isAsyncLike(DartType? type) {
  if (type == null) return false;
  if (type is InterfaceType && _futureChecker.isAssignableFromType(type)) {
    return true;
  }
  return type.element?.name == 'FutureOr';
}
