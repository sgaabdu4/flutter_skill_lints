import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';

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

const _renderObjectWidgetChecker = TypeChecker.fromName(
  'RenderObjectWidget',
  packageName: 'flutter',
);
const _scrollingParentChecker = TypeChecker.any([
  TypeChecker.fromName('ScrollView', packageName: 'flutter'),
  TypeChecker.fromName('SingleChildScrollView', packageName: 'flutter'),
]);
const _containerChecker = TypeChecker.fromName('Container', packageName: 'flutter');

/// The widget constructor whose argument receives [node] unchanged, or null
/// when a callback, method call or other expression may wrap it first.
InstanceCreationExpression? directWidgetParent(Expression node) {
  AstNode? current = node.parent;
  while (current != null) {
    switch (current) {
      case ListLiteral() ||
          IfElement() ||
          ForElement() ||
          SpreadElement() ||
          ParenthesizedExpression() ||
          ConditionalExpression() ||
          NamedArgument():
        current = current.parent;
      case ArgumentList(:final parent):
        return parent is InstanceCreationExpression ? parent : null;
      default:
        return null;
    }
  }
  return null;
}

/// Whether the parent-data widget [node] is proven to render under a parent
/// that is not [allowedParent].
///
/// Transparent `Container`s are walked. Any other composed widget ends the
/// proof, because its runtime child placement is not visible in the source.
bool hasProvenForeignRenderParent(
  InstanceCreationExpression node,
  TypeChecker allowedParent,
  TypeSystem typeSystem,
) {
  var parent = directWidgetParent(node);
  while (parent != null) {
    final element = parent.constructorName.type.element;
    if (element == null || allowedParent.isSuperOf(element)) return false;
    if (_renderObjectWidgetChecker.isSuperOf(element) ||
        _scrollingParentChecker.isSuperOf(element) ||
        _containerAddsRenderParent(parent, typeSystem)) {
      return true;
    }
    final type = parent.staticType;
    if (type == null || !_containerChecker.isExactlyType(type)) return false;
    parent = directWidgetParent(parent);
  }
  return false;
}

bool _containerAddsRenderParent(InstanceCreationExpression parent, TypeSystem typeSystem) {
  final type = parent.staticType;
  if (type == null || !_containerChecker.isExactlyType(type)) return false;
  const renderProperties = {
    'alignment',
    'padding',
    'color',
    'decoration',
    'foregroundDecoration',
    'width',
    'height',
    'constraints',
    'margin',
    'transform',
  };
  return parent.argumentList.arguments.whereType<NamedArgument>().any((argument) {
    final valueType = argument.argumentExpression.staticType;
    return renderProperties.contains(argument.name.lexeme) &&
        valueType != null &&
        typeSystem.isNonNullable(valueType);
  });
}
