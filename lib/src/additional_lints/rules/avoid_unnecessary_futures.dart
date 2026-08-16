import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/function_body_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Warns when an async function returns a Future without async work.
final class AvoidUnnecessaryFutures extends GeneratedFunctionAndMethodBodyCheckRule {
  static const LintCode code = LintCode(
    'avoid_unnecessary_futures',
    'Avoid unnecessary Future return types.',
    correctionMessage:
        'Return the value synchronously, or keep Future only when real async work exists.',
  );

  AvoidUnnecessaryFutures()
    : super(
        name: 'avoid_unnecessary_futures',
        description: 'Warns when async functions return immediate values through Future.',
        code: code,
      );

  @override
  void checkNonOverrideFunctionBody(TypeAnnotation? returnType, FunctionBody body) {
    _check(returnType, body);
  }

  void _check(TypeAnnotation? returnType, FunctionBody body) {
    if (!_isExplicitFutureValueReturn(returnType)) return;
    if (!body.isAsynchronous || body.isGenerator) return;
    if (containsAwait(body)) return;
    if (!_onlyReturnsSyncValues(body)) return;

    reportAtNode(returnType!);
  }

  bool _onlyReturnsSyncValues(FunctionBody body) {
    if (body is ExpressionFunctionBody) {
      return _isSyncValue(body.expression);
    }

    if (body is! BlockFunctionBody) return false;

    final statements = body.block.statements;
    if (statements.length != 1) return false;

    final statement = statements.single;
    return statement is ReturnStatement && _isSyncValue(statement.expression);
  }

  bool _isSyncValue(Expression? expression) {
    final type = expression?.staticType;
    if (type == null || type is VoidType) return false;
    return !_isFutureLike(type);
  }

  bool _isExplicitFutureValueReturn(TypeAnnotation? returnType) {
    if (returnType is! NamedType) return false;
    if (returnType.name.lexeme != 'Future') return false;
    if (returnType.element?.library?.isDartAsync != true) return false;

    final arguments = returnType.typeArguments?.arguments;
    if (arguments == null || arguments.length != 1) return false;

    final valueType = arguments.single;
    return valueType is! NamedType || valueType.name.lexeme != 'void';
  }
}

const _futureChecker = TypeChecker.fromUrl('dart:async#Future');

bool _isFutureLike(DartType type) {
  if (type is InterfaceType && _futureChecker.isAssignableFromType(type)) {
    return true;
  }
  return type.element?.name == 'FutureOr';
}
