import 'package:analyzer/dart/ast/ast.dart';

/// Represents the main axis direction of a flex/multi-child widget.
enum FlexAxis { vertical, horizontal }

/// Lightweight info about a widget node in the AST.
typedef WidgetInfo = ({String name, ArgumentList argumentList, Expression node});

String? allowedWidgetName(Expression expression, Set<String> allowedNames) {
  final name = switch (expression) {
    InstanceCreationExpression(:final constructorName) => constructorName.type.name.lexeme,
    MethodInvocation(:final methodName) => methodName.name,
    _ => null,
  };
  return name != null && allowedNames.contains(name) ? name : null;
}
