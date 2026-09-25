import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';
import 'package:flutter_skill_lints/src/mounted_guard_utils.dart';

/// Don't use ref or state after an await in Notifier methods without checking ref.mounted.
///
/// Why: Requires ref.mounted guards after async gaps in Riverpod Notifier methods. Add 'if
/// (!ref.mounted) return;' immediately after the await.
final class UseRefMountedAfterAwait extends GeneratedMethodDeclarationCheckRule {
  static const LintCode code = LintCode(
    'use_ref_mounted_after_await',
    "Don't use ref or state after an await in Notifier methods without checking ref.mounted.",
    correctionMessage: "Add 'if (!ref.mounted) return;' immediately after the await.",
    severity: DiagnosticSeverity.ERROR,
  );

  UseRefMountedAfterAwait()
    : super(
        name: 'use_ref_mounted_after_await',
        description: 'Requires ref.mounted guards after async gaps in Riverpod Notifier methods.',
        code: code,
      );

  @override
  void checkMethodDeclaration(MethodDeclaration node) {
    final classNode = enclosingClass(node);
    if (classNode == null || !isNotifierClass(classNode)) return;

    final scanner = AsyncStatementScanner(
      guardTarget: 'ref',
      accessTargets: const {'ref', 'state'},
      onViolation: reportAtNode,
      additionalMountedCondition: (condition) => _resolvedMountedHelperGuard(condition, classNode),
      mountedWhenTrue: (condition) => _mountedWhenTrue(condition, classNode),
    );
    _scanAsyncBody(scanner, node.body);
    // Async closures resume after their own awaits, even inside sync methods.
    node.body.accept(_AsyncClosureVisitor((body) => _scanAsyncBody(scanner, body)));
  }
}

void _scanAsyncBody(AsyncStatementScanner scanner, FunctionBody body) {
  if (!body.isAsynchronous) return;
  switch (body) {
    case BlockFunctionBody(:final block):
      scanner.scanBlock(block);
    case ExpressionFunctionBody(:final expression):
      scanner.scanExpression(expression);
    default:
      return;
  }
}

final class _AsyncClosureVisitor extends RecursiveAstVisitor<void> {
  _AsyncClosureVisitor(this.onBody);

  final void Function(FunctionBody body) onBody;

  @override
  void visitFunctionExpression(FunctionExpression node) {
    onBody(node.body);
    super.visitFunctionExpression(node);
  }
}

/// A condition that can only be true while the notifier is still mounted.
bool _mountedWhenTrue(Expression condition, ClassDeclaration owner) {
  final value = condition.unParenthesized;
  if (isTargetProperty(value, 'ref', 'mounted')) return isRiverpodRefAccess(value);
  if (value is BinaryExpression && value.operator.lexeme == '&&') {
    return _mountedWhenTrue(value.leftOperand, owner) &&
        isPureMountedGuardSuffix(value.rightOperand);
  }
  return _isResolvedMountedHelperCall(value, owner);
}

bool _resolvedMountedHelperGuard(Expression condition, ClassDeclaration owner) {
  final guard = condition.unParenthesized;
  if (guard is! PrefixExpression || guard.operator.lexeme != '!') return false;
  return _isResolvedMountedHelperCall(guard.operand.unParenthesized, owner);
}

bool _isResolvedMountedHelperCall(Expression call, ClassDeclaration owner) {
  if (call is! MethodInvocation || call.target != null && call.target is! ThisExpression) {
    return false;
  }
  final invoked = call.methodName.element;
  if (invoked is! MethodElement || !invoked.isPrivate) return false;
  final ownerElement = owner.declaredFragment?.element;
  if (ownerElement == null) return false;
  final helper = classBodyOf(owner)?.members
      .whereType<MethodDeclaration>()
      .where((method) => method.declaredFragment?.element == invoked)
      .firstOrNull;
  if (helper == null) return false;
  // A library-local subclass can override a private method, including via a mixin.
  if (ownerElement.library.classes.any(
    (candidate) =>
        candidate != ownerElement &&
        candidate.allSupertypes.any((type) => type.element == ownerElement),
  )) {
    return false;
  }
  final body = helper.body;
  final returned = switch (body) {
    ExpressionFunctionBody(:final expression) => expression,
    BlockFunctionBody(:final block)
        when block.statements.length == 1 && block.statements.single is ReturnStatement =>
      (block.statements.single as ReturnStatement).expression,
    _ => null,
  };
  return returned != null && _trueRequiresMounted(returned);
}

bool _trueRequiresMounted(Expression expression) {
  final value = expression.unParenthesized;
  if (isTargetProperty(value, 'ref', 'mounted')) return isRiverpodRefAccess(value);
  if (value is BinaryExpression && value.operator.lexeme == '&&') {
    return _trueRequiresMounted(value.rightOperand) ||
        _trueRequiresMounted(value.leftOperand) && isPureMountedGuardSuffix(value.rightOperand);
  }
  if (value is BinaryExpression && value.operator.lexeme == '||') {
    return _trueRequiresMounted(value.leftOperand) && _trueRequiresMounted(value.rightOperand);
  }
  return false;
}
