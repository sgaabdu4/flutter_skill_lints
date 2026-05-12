import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when a `finally` block early-returns on a negated `mounted` check.
///
/// `return;` inside `finally` swallows any in-flight exception from the
/// `try` body — the caller never sees it. Dart's built-in
/// `control_flow_in_finally` lint catches the broad case; this rule
/// targets the common Riverpod / Flutter shape and offers an auto-fix
/// that rewrites the early-return into a guard around the trailing
/// statements.
///
/// **Bad:**
/// ```dart
/// } finally {
///   if (!ref.mounted) return;
///   state = state.copyWith(isResetting: false);
/// }
/// ```
///
/// **Good:**
/// ```dart
/// } finally {
///   if (ref.mounted) {
///     state = state.copyWith(isResetting: false);
///   }
/// }
/// ```
class AvoidMountedCheckInFinally extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_mounted_check_in_finally',
    "Don't early-return on '!mounted' inside a 'finally' block.",
    correctionMessage:
        "Wrap the trailing statements in 'if (mounted) { ... }' instead — "
        "'return' in 'finally' swallows in-flight exceptions.",
  );

  AvoidMountedCheckInFinally()
    : super(
        name: 'avoid_mounted_check_in_finally',
        description:
            "Warns when 'if (!ref.mounted) return;' (or context/bare mounted) "
            "appears inside a 'finally' block.",
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final visitor = _Visitor(this);
    registry.addTryStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidMountedCheckInFinally rule;

  _Visitor(this.rule);

  @override
  void visitTryStatement(TryStatement node) {
    final finallyBlock = node.finallyBlock;
    if (finallyBlock == null) return;
    final finder = _MountedReturnFinder(rule);
    finallyBlock.visitChildren(finder);
  }
}

class _MountedReturnFinder extends RecursiveAstVisitor<void> {
  final AvoidMountedCheckInFinally rule;

  _MountedReturnFinder(this.rule);

  @override
  void visitFunctionExpression(FunctionExpression node) {
    // Don't descend into nested closures — different `finally` scope.
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    // Same — different scope.
  }

  @override
  void visitTryStatement(TryStatement node) {
    // Nested try/finally is handled by the outer visitor on its own
    // dispatch — skip here to avoid double-reporting.
  }

  @override
  void visitIfStatement(IfStatement node) {
    if (node.elseStatement != null) {
      super.visitIfStatement(node);
      return;
    }
    if (!_isNegatedMountedCheck(node.expression)) {
      super.visitIfStatement(node);
      return;
    }
    if (!_isBareReturn(node.thenStatement)) {
      super.visitIfStatement(node);
      return;
    }
    rule.reportAtNode(node);
    super.visitIfStatement(node);
  }
}

bool _isNegatedMountedCheck(Expression expr) {
  if (expr is PrefixExpression && expr.operator.type == TokenType.BANG) {
    return _isMountedAccess(expr.operand);
  }
  return false;
}

bool _isMountedAccess(Expression expr) {
  if (expr is SimpleIdentifier) {
    return expr.name == 'mounted';
  }
  if (expr is PrefixedIdentifier) {
    return expr.identifier.name == 'mounted';
  }
  if (expr is PropertyAccess) {
    return expr.propertyName.name == 'mounted';
  }
  return false;
}

bool _isBareReturn(Statement stmt) {
  if (stmt is ReturnStatement) {
    return stmt.expression == null;
  }
  if (stmt is Block && stmt.statements.length == 1) {
    return _isBareReturn(stmt.statements.first);
  }
  return false;
}
