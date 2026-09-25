part of '../ast_utils.dart';

/// The literal text of a string literal, ignoring interpolated expressions.
String? stringLiteralText(Expression expression) {
  if (expression is SimpleStringLiteral) return expression.value;

  if (expression is AdjacentStrings) {
    final buffer = StringBuffer();
    for (final string in expression.strings) {
      final part = stringLiteralText(string);
      if (part != null) buffer.write(part);
    }
    return buffer.toString();
  }

  if (expression is StringInterpolation) {
    final buffer = StringBuffer();
    for (final element in expression.elements) {
      if (element is InterpolationString) buffer.write(element.value);
    }
    return buffer.toString();
  }

  return null;
}

/// Whether [value] contains a Latin letter.
bool hasLetter(String value) => _letter.hasMatch(value);

final RegExp _letter = RegExp('[A-Za-z]');

/// Whether a named argument [name] carries user-facing copy.
bool isUserFacingLabel(String name) => _userFacingLabels.contains(name.toLowerCase());

const _userFacingLabels = {
  'text',
  'data',
  'label',
  'labeltext',
  'hint',
  'hinttext',
  'helpertext',
  'errortext',
  'title',
  'subtitle',
  'tooltip',
  'semanticslabel',
  'semanticlabel',
  'message',
  'placeholder',
  'prefixtext',
  'suffixtext',
  'toptext',
  'bottomtext',
  'description',
  'heading',
};

const _flutterNavigatorChecker = TypeChecker.any([
  TypeChecker.fromName('Navigator', packageName: 'flutter'),
  TypeChecker.fromName('NavigatorState', packageName: 'flutter'),
]);

/// go_router's `GoRouter` class.
const goRouterChecker = TypeChecker.fromName('GoRouter', packageName: 'go_router');

/// go_router's typed route base class.
const goRouteDataChecker = TypeChecker.fromName('GoRouteData', packageName: 'go_router');

/// Whether [node] resolves to a Flutter Navigator or go_router `pop` / `maybePop`.
bool isResolvedNavigationPop(MethodInvocation node) {
  final name = node.methodName.name;
  if (name != 'pop' && name != 'maybePop') return false;
  final owner = node.methodName.element?.enclosingElement;
  return (owner is InterfaceElement &&
          (_flutterNavigatorChecker.isExactly(owner) || goRouterChecker.isExactly(owner))) ||
      isGoRouterHelperMember(node.methodName.element);
}

/// Whether [node] resolves to forward page navigation: `go` / `push*` /
/// `replace*` on Flutter's Navigator, `GoRouter`, go_router's `BuildContext`
/// helpers, or a typed `GoRouteData`.
bool isResolvedForwardNavigation(MethodInvocation node) {
  final name = node.methodName.name;
  final isForward =
      name == 'go' ||
      name == 'goNamed' ||
      name.startsWith('push') ||
      name.startsWith('replace') ||
      name.startsWith('restorablePush');
  if (!isForward) return false;
  final targetType = node.realTarget?.staticType;
  if (targetType != null && goRouteDataChecker.isAssignableFromType(targetType)) return true;
  final owner = node.methodName.element?.enclosingElement;
  return (owner is InterfaceElement &&
          (_flutterNavigatorChecker.isExactly(owner) || goRouterChecker.isExactly(owner))) ||
      isGoRouterHelperMember(node.methodName.element);
}

/// Whether [element] is declared by go_router's `GoRouterHelper` extension on
/// `BuildContext`.
bool isGoRouterHelperMember(Element? element) {
  final owner = element?.enclosingElement;
  return owner is ExtensionElement &&
      owner.name == 'GoRouterHelper' &&
      owner.library.identifier.startsWith('package:go_router/');
}

/// The statements after [node]'s enclosing statement in the same block.
Iterable<Statement> followingBlockStatements(AstNode node) sync* {
  AstNode? current = node;
  while (current != null && current is! FunctionBody) {
    final parent = current.parent;
    if (current is Statement && parent is Block) {
      final statements = parent.statements;
      yield* statements.skip(statements.indexOf(current) + 1);
      return;
    }
    current = parent;
  }
}

/// Every node of type [T] under [root], in source order.
List<T> collectNodes<T extends AstNode>(AstNode root) {
  final collector = _NodeCollector<T>();
  root.accept(collector);
  return collector.nodes;
}

final class _NodeCollector<T extends AstNode> extends GeneralizingAstVisitor<void> {
  final nodes = <T>[];

  @override
  void visitNode(AstNode node) {
    if (node is T) nodes.add(node);
    super.visitNode(node);
  }
}
