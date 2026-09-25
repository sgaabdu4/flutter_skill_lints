part of '../ast_utils.dart';

int? _firstAwaitEnd(AstNode node) {
  final visitor = _AwaitEndFinder();
  node.accept(visitor);
  return visitor.end;
}

final class _AwaitEndFinder extends RecursiveAstVisitor<void> {
  int? end;

  @override
  void visitAwaitExpression(AwaitExpression node) {
    final current = end;
    if (current == null || node.end < current) end = node.end;
    super.visitAwaitExpression(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}
}

/// An assignment to a tracked target whose value waits on an `await` first.
final class _AwaitedWriteFinder extends RecursiveAstVisitor<void> {
  _AwaitedWriteFinder(this.targetNames);

  final Set<String> targetNames;
  AstNode? node;

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    final target = node.leftHandSide;
    if (this.node == null &&
        target is SimpleIdentifier &&
        targetNames.contains(target.name) &&
        containsAwait(node.rightHandSide)) {
      this.node = target;
      return;
    }
    super.visitAssignmentExpression(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}
}

final class _ReturnFinder extends RecursiveAstVisitor<void> {
  bool found = false;

  @override
  void visitReturnStatement(ReturnStatement node) {
    found = true;
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}
}

final class _AwaitFinder extends RecursiveAstVisitor<void> {
  bool found = false;

  @override
  void visitAwaitExpression(AwaitExpression node) {
    found = true;
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}
}

final class _ThrowFinder extends RecursiveAstVisitor<void> {
  bool found = false;

  @override
  void visitThrowExpression(ThrowExpression node) {
    found = true;
  }
}

final class _TargetAccessFinder extends RecursiveAstVisitor<void> {
  _TargetAccessFinder(this.targetNames, {this.includeBlocks = false, this.where});

  final Set<String> targetNames;
  final bool includeBlocks;
  final bool Function(AstNode access)? where;
  AstNode? node;

  bool _accepts(AstNode access) => where?.call(access) ?? true;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (this.node != null) return;
    final target = node.target;
    if (target is SimpleIdentifier && targetNames.contains(target.name)) {
      if (target.name == 'ref' && node.methodName.name == 'mounted') return;
      if (_accepts(node)) {
        this.node = node;
        return;
      }
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (this.node != null) return;
    if (targetNames.contains(node.prefix.name)) {
      if (node.prefix.name == 'ref' && node.identifier.name == 'mounted') {
        return;
      }
      if (node.prefix.name == 'context' &&
          node.identifier.name == 'mounted' &&
          isCapturedContextAccess(node)) {
        return;
      }
      if (_accepts(node)) {
        this.node = node;
        return;
      }
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (this.node != null) return;
    final target = node.target;
    // `this.context.mounted` reads the State getter as a whole.
    if (target is PropertyAccess &&
        target.target is ThisExpression &&
        targetNames.contains(target.propertyName.name) &&
        node.propertyName.name == 'mounted' &&
        _accepts(node)) {
      this.node = node;
      return;
    }
    if (target is ThisExpression &&
        targetNames.contains(node.propertyName.name) &&
        _accepts(node)) {
      this.node = node;
      return;
    }
    if (target is SimpleIdentifier && targetNames.contains(target.name)) {
      if (target.name == 'ref' && node.propertyName.name == 'mounted') {
        return;
      }
      if (target.name == 'context' &&
          node.propertyName.name == 'mounted' &&
          isCapturedContextAccess(node)) {
        return;
      }
      if (_accepts(node)) {
        this.node = node;
        return;
      }
    }
    super.visitPropertyAccess(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (this.node != null) return;
    if (!targetNames.contains(node.name)) {
      super.visitSimpleIdentifier(node);
      return;
    }
    if (isExpressionTargetIdentifier(node)) return;
    if (classMemberNameIsDeclaration(node)) return;
    if (_accepts(node)) this.node = node;
  }

  @override
  void visitBlock(Block node) {
    if (includeBlocks) super.visitBlock(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}
}

final class _EnsureCallFinder extends RecursiveAstVisitor<void> {
  bool found = false;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final name = node.methodName.name;
    if (name.startsWith('_ensure') || RegExp(r'^ensure[A-Z]\w*').hasMatch(name)) {
      found = true;
      return;
    }
    super.visitMethodInvocation(node);
  }
}

/// Whether a closure executes immediately instead of being stored or scheduled.
bool isImmediatelyInvoked(FunctionExpression function) {
  AstNode expression = function;
  var wrapper = expression.parent;
  while (wrapper is ParenthesizedExpression) {
    expression = wrapper;
    wrapper = expression.parent;
  }
  final parent = expression.parent;
  return parent is FunctionExpressionInvocation && identical(parent.function, expression) ||
      parent is MethodInvocation &&
          parent.methodName.name == 'call' &&
          identical(parent.target, expression);
}

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
