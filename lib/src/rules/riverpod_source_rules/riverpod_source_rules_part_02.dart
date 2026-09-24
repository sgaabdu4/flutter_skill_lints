part of '../riverpod_source_rules.dart';

final class _ScalarWatchVisitor extends RecursiveAstVisitor<void> {
  final offsets = <int>{};

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'watch' && node.target?.toSource() == 'ref') {
      final type = node.staticType;
      if (type != null &&
          (type.isDartCoreBool ||
              type.isDartCoreString ||
              type.isDartCoreInt ||
              type.isDartCoreDouble ||
              type.isDartCoreNum ||
              type.element is EnumElement)) {
        offsets.add(node.offset);
      }
      if (_consumesWholeWatch(node)) offsets.add(node.offset);
      // The skill allows MutationState flags (isPending, hasError, ...) for simple checks.
      if (_isRiverpodMutationElement(type?.element, 'MutationState')) offsets.add(node.offset);
    }
    super.visitMethodInvocation(node);
  }
}

bool _consumesWholeWatch(MethodInvocation watch) {
  AstNode value = watch;
  while (_wholeValueWrapper(value.parent, value)) {
    value = value.parent!;
  }
  final parent = value.parent;
  if (parent is VariableDeclaration && _isOnlyUsedWhole(parent)) return true;
  return _isWholeValueUse(watch);
}

bool _wholeValueWrapper(AstNode? parent, AstNode value) =>
    parent is ParenthesizedExpression && parent.expression == value ||
    parent is ConditionalExpression &&
        (parent.thenExpression == value || parent.elseExpression == value);

bool _isOnlyUsedWhole(VariableDeclaration declaration) {
  final element = declaration.declaredFragment?.element;
  if (element == null) return false;
  AstNode? scope = declaration.parent;
  while (scope != null && scope is! MethodDeclaration) {
    scope = scope.parent;
  }
  if (scope == null) return false;
  final uses = _VariableUses(element);
  scope.accept(uses);
  return uses.found && uses.allWhole;
}

final class _VariableUses extends RecursiveAstVisitor<void> {
  _VariableUses(this.element);

  final Element element;
  bool found = false;
  bool allWhole = true;

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.element != element) return;
    found = true;
    if (!_isWholeValueUse(node)) allWhole = false;
  }
}

bool _isWholeValueUse(Expression value) {
  final parent = value.parent;
  if (parent is ForEachParts && parent.iterable == value) return true;
  if (parent is MethodInvocation &&
      parent.target == value &&
      parent.methodName.name == 'when' &&
      _hasCompleteAsyncValueDispatch(parent)) {
    return true;
  }
  if (parent is NamedArgument || parent is ArgumentList) {
    final arguments = parent is NamedArgument ? parent.parent : parent;
    if (arguments is ArgumentList && arguments.parent is InstanceCreationExpression) {
      return true;
    }
  }
  if (parent is SwitchExpression && parent.expression == value) {
    return parent.cases.every((branch) {
      final pattern = branch.guardedPattern.pattern;
      return pattern is WildcardPattern || pattern is ObjectPattern && pattern.fields.isEmpty;
    });
  }
  if (parent is ReturnStatement && value.staticType?.isDartCoreList == true) return true;
  return false;
}

bool _hasCompleteAsyncValueDispatch(MethodInvocation invocation) {
  final method = invocation.methodName.element;
  final owner = method?.enclosingElement;
  final ownerLibrary = owner?.library?.uri.toString() ?? '';
  if (method?.name != 'when' ||
      (owner?.name != 'AsyncValue' && owner?.name != 'AsyncValueExtensions') ||
      !(ownerLibrary.startsWith('package:riverpod/') ||
          ownerLibrary.startsWith('package:flutter_riverpod/'))) {
    return false;
  }
  final branches = invocation.argumentList.arguments
      .whereType<NamedArgument>()
      .map((argument) => argument.name.lexeme)
      .toSet();
  return branches.containsAll(const {'data', 'loading', 'error'});
}

bool _isRiverpodMutationElement(Element? element, String name) =>
    element?.name == name &&
    (element?.library?.uri.toString().startsWith('package:riverpod/') ?? false);

/// Collects `Mutation<T>()` creations that resolve to Riverpod's Mutation.
final class _RiverpodMutationCreations extends RecursiveAstVisitor<void> {
  final nodes = <InstanceCreationExpression>[];

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (_isRiverpodMutationElement(node.constructorName.type.element, 'Mutation')) {
      nodes.add(node);
    }
    super.visitInstanceCreationExpression(node);
  }
}

void _reportAtNode(ScannerRuleReporter reporter, SourceScannerContext context, AstNode node) {
  final location = context.unit.lineInfo.getLocation(node.offset);
  reporter.report(context, location.lineNumber - 1, location.columnNumber - 1);
}

/// Collects Riverpod `read` calls made inside a Riverpod `Mutation.run` callback.
final class _RiverpodReadsInMutationRun extends RecursiveAstVisitor<void> {
  final nodes = <MethodInvocation>[];

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'read' &&
        _isRiverpodLibrary(node.methodName.element?.library) &&
        node.thisOrAncestorMatching(_isMutationRunCallback) != null) {
      nodes.add(node);
    }
    super.visitMethodInvocation(node);
  }
}

bool _isMutationRunCallback(AstNode node) {
  if (node is! FunctionExpression) return false;
  final arguments = node.parent;
  final invocation = arguments?.parent;
  return arguments is ArgumentList &&
      invocation is MethodInvocation &&
      invocation.methodName.name == 'run' &&
      _isRiverpodMutationElement(invocation.methodName.element?.enclosingElement, 'Mutation');
}

bool _isRiverpodLibrary(LibraryElement? library) {
  final uri = library?.uri.toString() ?? '';
  return uri.startsWith('package:riverpod/') || uri.startsWith('package:flutter_riverpod/');
}
