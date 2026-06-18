import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when a fire-and-forget Future has no local error handler.
final class AvoidUncaughtFutureErrors extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_uncaught_future_errors',
    'Handle errors from fire-and-forget Futures.',
    correctionMessage: 'Add try/catch inside the inline async fire-and-forget body.',
  );

  AvoidUncaughtFutureErrors()
    : super(
        name: 'avoid_uncaught_future_errors',
        description: 'Warns when an inline async unawaited() body has no visible try/catch.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addMethodInvocation(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidUncaughtFutureErrors rule;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.target != null || node.methodName.name != 'unawaited') return;
    final arguments = node.argumentList.arguments;
    if (arguments.length != 1) return;

    final future = arguments.single;
    if (future is! Expression) return;
    final inlineBody = _inlineAsyncBody(future);
    if (inlineBody == null) return;
    if (_containsTryStatement(inlineBody)) return;

    rule.reportAtNode(future);
  }
}

FunctionBody? _inlineAsyncBody(Expression expression) {
  if (expression is! FunctionExpressionInvocation) return null;
  final function = expression.function;
  if (function is! FunctionExpression || !function.body.isAsynchronous) return null;
  return function.body;
}

bool _containsTryStatement(FunctionBody body) {
  final visitor = _TryStatementVisitor();
  body.accept(visitor);
  return visitor.found;
}

final class _TryStatementVisitor extends RecursiveAstVisitor<void> {
  bool found = false;

  @override
  void visitTryStatement(TryStatement node) {
    found = true;
  }
}
