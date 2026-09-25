import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';
import 'package:flutter_skill_lints/src/mounted_guard_utils.dart';

/// Don't use BuildContext after an await without checking context.mounted.
///
/// Why: Requires context.mounted guards before BuildContext use after async gaps. Add 'if
/// (!context.mounted) return;' before using context after an await.
final class UseContextMountedAfterAwait extends AnalysisRule {
  static const LintCode code = LintCode(
    'use_context_mounted_after_await',
    "Don't use BuildContext after an await without checking context.mounted.",
    correctionMessage:
        "Capture State.context before the await, then check 'if (!context.mounted) return;'.",
    severity: DiagnosticSeverity.ERROR,
  );

  UseContextMountedAfterAwait()
    : super(
        name: 'use_context_mounted_after_await',
        description: 'Requires context.mounted guards before BuildContext use after async gaps.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (isGeneratedRuleContext(context)) return;
    final visitor = _Visitor(this);
    registry.addMethodDeclaration(this, visitor);
    registry.addFunctionDeclaration(this, visitor);
    registry.addFunctionExpression(this, visitor);
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final UseContextMountedAfterAwait rule;

  @override
  void visitMethodDeclaration(MethodDeclaration node) => _checkBody(node.body);

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) =>
      _checkBody(node.functionExpression.body);

  /// Async callbacks such as `onPressed: () async { ... }` resume after their awaits too.
  @override
  void visitFunctionExpression(FunctionExpression node) {
    if (node.parent is FunctionDeclaration) return;
    _checkBody(node.body);
  }

  /// Each `context` resolves on its own: a captured parameter or local can be
  /// guarded with `context.mounted`, the State.context getter cannot.
  void _checkBody(FunctionBody body) {
    if (!body.isAsynchronous) return;
    final scanner = AsyncStatementScanner(
      guardTarget: 'context',
      accessTargets: const {'context'},
      onViolation: rule.reportAtNode,
      mountedWhenTrue: _mountedWhenTrue,
    );
    switch (body) {
      case BlockFunctionBody(:final block):
        scanner.scanBlock(block);
      case ExpressionFunctionBody(:final expression):
        scanner.scanExpression(expression);
      default:
        return;
    }
  }
}

/// A condition that can only be true while the captured context is mounted.
bool _mountedWhenTrue(Expression condition) {
  final value = condition.unParenthesized;
  if (isTargetProperty(value, 'context', 'mounted')) return isCapturedContextAccess(value);
  if (value is BinaryExpression && value.operator.lexeme == '&&') {
    return _mountedWhenTrue(value.rightOperand) ||
        _mountedWhenTrue(value.leftOperand) && isPureMountedGuardSuffix(value.rightOperand);
  }
  return false;
}
