import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Warns when `async` only returns an existing Future.
final class AvoidRedundantAsync extends GeneratedFunctionAndMethodDeclarationCheckRule {
  static const LintCode code = LintCode(
    'avoid_redundant_async',
    'Avoid redundant async.',
    correctionMessage:
        'Return the Future directly or await it when async error handling is needed.',
  );

  AvoidRedundantAsync()
    : super(
        name: 'avoid_redundant_async',
        description: 'Warns when async functions only return an existing Future.',
        code: code,
      );

  @override
  void checkFunctionDeclaration(FunctionDeclaration node) {
    _check(node.functionExpression.body, node.name);
  }

  @override
  void checkMethodDeclaration(MethodDeclaration node) {
    if (_hasOverrideAnnotation(node.metadata)) return;
    _check(node.body, node.name);
  }

  void _check(FunctionBody body, Token reportToken) {
    if (!body.isAsynchronous || body.isGenerator) return;
    if (containsAwait(body)) return;
    if (!_onlyReturnsExistingFuture(body)) return;

    reportAtToken(reportToken);
  }

  bool _onlyReturnsExistingFuture(FunctionBody body) {
    if (body is ExpressionFunctionBody) {
      return _isFutureLike(body.expression.staticType);
    }

    if (body is! BlockFunctionBody) return false;

    final statements = body.block.statements;
    if (statements.length != 1) return false;

    final statement = statements.single;
    return statement is ReturnStatement && _isFutureLike(statement.expression?.staticType);
  }

  bool _hasOverrideAnnotation(NodeList<Annotation> metadata) {
    return metadata.any((annotation) => annotation.name.name == 'override');
  }
}

const _futureChecker = TypeChecker.fromUrl('dart:async#Future');

bool _isFutureLike(DartType? type) {
  if (type == null) return false;
  if (type is InterfaceType && _futureChecker.isAssignableFromType(type)) {
    return true;
  }
  return type.element?.name == 'FutureOr';
}
