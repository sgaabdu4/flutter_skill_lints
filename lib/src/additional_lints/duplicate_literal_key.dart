import 'package:analyzer/dart/ast/ast.dart';

String? duplicateLiteralKey(Expression expression) {
  final unwrapped = unwrapParenthesized(expression);

  return switch (unwrapped) {
    BooleanLiteral(:final value) => 'bool:$value',
    DoubleLiteral(:final value) => 'double:$value',
    IntegerLiteral(:final value?) => 'int:$value',
    NullLiteral() => 'null',
    SimpleStringLiteral(:final value) => 'string:$value',
    _ => null,
  };
}

Expression unwrapParenthesized(Expression expression) {
  var current = expression;
  while (current is ParenthesizedExpression) {
    current = current.expression;
  }
  return current;
}
