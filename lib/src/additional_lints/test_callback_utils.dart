import 'package:analyzer/dart/ast/ast.dart';

FunctionExpression? testCallbackArgument(MethodInvocation node) {
  final positionalArgs = node.argumentList.arguments.where(
    (argument) => argument is! NamedArgument,
  );
  if (positionalArgs.length < 2) return null;

  final callback = positionalArgs.elementAt(1);
  return callback is FunctionExpression ? callback : null;
}
