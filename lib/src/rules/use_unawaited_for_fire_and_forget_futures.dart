import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';

/// Mark intentionally discarded callback Futures with unawaited.
///
/// Why: `discarded_futures` correctly flags `VoidCallback` bodies that create
/// a `Future` and drop it. Wrap intentional fire-and-forget work in
/// `unawaited(...)`. For reusable utilities, return `Future<void>` and await
/// `Future.wait(...)` so callers can choose whether to await or explicitly
/// launch the work in the background.
final class UseUnawaitedForFireAndForgetFutures extends GeneratedExpressionStatementCheckRule {
  static const LintCode code = LintCode(
    'use_unawaited_for_fire_and_forget_futures',
    'Future returned from a void callback is discarded.',
    correctionMessage:
        'In UI callbacks, wrap intentional background work in unawaited(...) '
        "and import 'dart:async'. For reusable utilities, return Future<void> "
        'and await Future.wait(...) so each caller can choose await or '
        'unawaited.',
  );

  UseUnawaitedForFireAndForgetFutures()
    : super(
        name: 'use_unawaited_for_fire_and_forget_futures',
        description:
            'Warns when a synchronous void callback drops a Future instead of '
            'marking it with unawaited.',
        code: code,
      );

  @override
  void checkExpressionStatement(ExpressionStatement node) {
    final expression = node.expression;
    if (expression is AwaitExpression) return;
    if (!_isFutureLike(expression.staticType)) return;

    final callback = node.thisOrAncestorOfType<FunctionExpression>();
    if (callback == null || callback.body.isAsynchronous) return;
    if (!_isVoidCallbackContext(callback)) return;

    reportAtNode(expression);
  }

  static bool _isVoidCallbackContext(FunctionExpression node) {
    final parameterType = node.correspondingParameter?.type;
    if (parameterType is FunctionType) {
      return parameterType.returnType is VoidType;
    }

    final contextType = _declaredContextType(node);
    if (contextType is FunctionType) {
      return contextType.returnType is VoidType;
    }

    return false;
  }

  static DartType? _declaredContextType(FunctionExpression node) {
    final parent = node.parent;
    if (parent is VariableDeclaration) {
      final declarationList = parent.parent;
      if (declarationList is VariableDeclarationList) {
        return declarationList.type?.type;
      }
    }
    if (parent is AssignmentExpression && parent.rightHandSide == node) {
      return parent.leftHandSide.staticType;
    }
    return null;
  }

  static bool _isFutureLike(DartType? type) {
    if (type is! InterfaceType) return false;
    final name = type.element.name;
    return name == 'Future' || name == 'FutureOr';
  }
}
