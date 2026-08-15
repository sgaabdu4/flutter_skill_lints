import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:flutter_skill_lints/src/additional_lints/ast_node_analysis.dart';

bool isEnumNameAccess(Expression expression, String parameterName) {
  if (expression case PrefixedIdentifier(
    prefix: SimpleIdentifier(name: final prefix),
    identifier: SimpleIdentifier(name: 'name'),
  ) when prefix == parameterName) {
    return true;
  }
  if (expression case PropertyAccess(
    target: SimpleIdentifier(name: final prefix),
    propertyName: SimpleIdentifier(name: 'name'),
  ) when prefix == parameterName) {
    return true;
  }
  return false;
}

({BinaryExpression body, String parameterName})? enumNameComparison(FunctionExpression callback) {
  final params = callback.parameters?.parameters;
  if (params == null || params.length != 1) return null;
  final parameterName = params.first.name?.lexeme;
  if (parameterName == null) return null;

  final body = maybeGetSingleReturnExpression(callback.body);
  if (body is! BinaryExpression || body.operator.type != TokenType.EQ_EQ) return null;
  return (body: body, parameterName: parameterName);
}

({Expression target, BinaryExpression body, String parameterName})? enumByNameCandidate(
  MethodInvocation node,
) {
  if (node.methodName.name != 'firstWhere') return null;
  final target = node.target;
  if (target == null) return null;
  final callback = node.argumentList.arguments.firstOrNull;
  if (callback is! FunctionExpression) return null;
  final comparison = enumNameComparison(callback);
  if (comparison == null) return null;
  return (target: target, body: comparison.body, parameterName: comparison.parameterName);
}
