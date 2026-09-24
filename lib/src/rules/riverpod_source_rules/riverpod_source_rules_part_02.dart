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
  if (parent is NamedArgument || parent is ArgumentList) {
    final arguments = parent is NamedArgument ? parent.parent : parent;
    final creation = arguments?.parent;
    if (arguments is ArgumentList && creation is InstanceCreationExpression) {
      return !_isWholeStateIntoAppWidget(value, creation);
    }
  }
  if (parent is SwitchExpression && parent.expression == value) {
    final scrutinee = value.staticType?.element;
    return parent.cases.every((branch) {
      final pattern = branch.guardedPattern.pattern;
      return pattern is WildcardPattern ||
          pattern is ObjectPattern &&
              (pattern.fields.isEmpty || _isSealedVariantPattern(pattern, scrutinee));
    });
  }
  if (parent is ReturnStatement && value.staticType?.isDartCoreList == true) return true;
  return false;
}

/// performance.md:26-27: reusable widgets receive minimal immutable view data,
/// and binding boundaries select specific fields. A watched class with more
/// than one field passed whole into an app widget hands it the whole state.
/// Records, collections and SDK values stay whole-value inputs (primitives and
/// enums are exempt earlier). Framework widgets take framework config such as
/// a RouterConfig, not reusable-widget view data.
bool _isWholeStateIntoAppWidget(Expression value, InstanceCreationExpression creation) {
  final type = value.staticType;
  final widget = creation.constructorName.type.element;
  return type is InterfaceType &&
      widget is InterfaceElement &&
      _isAppWidget(widget) &&
      !type.allSupertypes.any(
        (supertype) => supertype.isDartCoreIterable || supertype.isDartCoreMap,
      ) &&
      _publicFieldCount(type) > 1;
}

bool _isAppWidget(InterfaceElement element) =>
    !_isFlutterLibrary(element.library) &&
    element.allSupertypes.any(
      (type) => type.element.name == 'Widget' && _isFlutterLibrary(type.element.library),
    );

bool _isFlutterLibrary(LibraryElement library) =>
    library.uri.toString().startsWith('package:flutter/');

/// Counts public instance fields plus public abstract getters, because Freezed
/// declares a class's fields as abstract getters on its generated mixin. SDK
/// types (DateTime, Duration, Uri) count as single values.
int _publicFieldCount(InterfaceType type) {
  final names = <String?>{};
  for (final element in [
    type.element,
    for (final supertype in type.allSupertypes) supertype.element,
  ]) {
    if (element.library.uri.isScheme('dart')) continue;
    names
      ..addAll([
        for (final field in element.fields)
          if (!field.isStatic && !field.isOriginGetterSetter && field.isPublic) field.name,
      ])
      ..addAll([
        for (final getter in element.getters)
          if (!getter.isStatic && getter.isAbstract && getter.isPublic) getter.name,
      ]);
  }
  return names.length;
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

void _reportAtOffset(ScannerRuleReporter reporter, SourceScannerContext context, int offset) {
  final location = context.unit.lineInfo.getLocation(offset);
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

/// Collects Riverpod AsyncValue when/map dispatch calls; `whenData` is a
/// transform, not a union match, so it is not collected.
final class _AsyncValueWhenMapCalls extends RecursiveAstVisitor<void> {
  final nodes = <MethodInvocation>[];

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_asyncValueWhenMapNames.contains(node.methodName.name) &&
        _isRiverpodLibrary(node.methodName.element?.library) &&
        _isRiverpodAsyncValue(node.realTarget?.staticType)) {
      nodes.add(node);
    }
    super.visitMethodInvocation(node);
  }
}

const _asyncValueWhenMapNames = {'when', 'maybeWhen', 'whenOrNull', 'map', 'maybeMap', 'mapOrNull'};

bool _isRiverpodAsyncValue(DartType? type) =>
    type is InterfaceType &&
    [type, ...type.allSupertypes].any(
      (candidate) =>
          candidate.element.name == 'AsyncValue' && _isRiverpodLibrary(candidate.element.library),
    );

bool _isRiverpodLibrary(LibraryElement? library) {
  final uri = library?.uri.toString() ?? '';
  return uri.startsWith('package:riverpod/') || uri.startsWith('package:flutter_riverpod/');
}

/// A sealed-union variant pattern such as `Authenticated(:final user)` or
/// `AsyncData(:final value)` dispatches on the whole watched value; select
/// cannot express that exhaustive switch.
bool _isSealedVariantPattern(ObjectPattern pattern, Element? scrutinee) =>
    scrutinee is ClassElement && scrutinee.isSealed && pattern.type.element != scrutinee;
