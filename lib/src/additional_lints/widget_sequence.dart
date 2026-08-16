import 'package:analyzer/dart/ast/ast.dart';

import 'package:flutter_skill_lints/src/additional_lints/flutter_widget_helpers.dart';

List<WidgetInfo> collectWidgetSequence(
  Expression node,
  WidgetInfo? Function(Expression) widgetInfoFor,
) {
  final sequence = <WidgetInfo>[];
  Expression? current = node;

  while (current != null) {
    final info = widgetInfoFor(current);
    if (info == null) break;
    sequence.add(info);
    current = getWidgetChildExpression(info.argumentList);
  }

  return sequence;
}

Expression? getWidgetChildExpression(ArgumentList argumentList) {
  for (final argument in argumentList.arguments) {
    if (argument is NamedArgument && argument.name.lexeme == 'child') {
      return argument.argumentExpression;
    }
  }
  return null;
}
