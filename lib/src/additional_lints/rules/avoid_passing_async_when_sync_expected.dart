import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

/// Warns when an async function literal is passed to a sync-only callback.
final class AvoidPassingAsyncWhenSyncExpected extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_passing_async_when_sync_expected',
    'Avoid passing an async callback where a sync callback is expected.',
    correctionMessage:
        'Use a synchronous callback, or change the parameter type to accept a Future.',
  );

  AvoidPassingAsyncWhenSyncExpected()
    : super(
        name: 'avoid_passing_async_when_sync_expected',
        description: 'Warns when async function literals are passed to void callback parameters.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addFunctionExpression(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidPassingAsyncWhenSyncExpected rule;

  @override
  void visitFunctionExpression(FunctionExpression node) {
    if (!node.body.isAsynchronous) return;

    final argument = _callbackArgument(node);
    if (argument == null) return;

    final parameterType = _parameterType(argument);
    if (parameterType is! FunctionType) return;
    if (parameterType.returnType is VoidType) {
      rule.reportAtNode(node);
    }
  }
}

AstNode? _callbackArgument(FunctionExpression node) {
  final parent = node.parent;
  if (parent is NamedExpression && parent.expression == node) return parent;
  if (parent is ArgumentList) return node;
  return null;
}

DartType? _parameterType(AstNode argument) {
  if (argument case NamedExpression(:final correspondingParameter)) {
    return correspondingParameter?.type;
  }

  if (argument case FunctionExpression(:final correspondingParameter)) {
    return correspondingParameter?.type;
  }

  return null;
}
