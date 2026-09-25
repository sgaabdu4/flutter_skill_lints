part of '../riverpod_source_rules.dart';

/// Broad `watch` calls on Riverpod's `Ref` or `WidgetRef` inside a `build`
/// method.
final class _BroadBuildWatchVisitor extends RecursiveAstVisitor<void> {
  final offsets = <int>[];
  var _inBuild = false;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    // Generated providers legitimately watch dependencies in build().
    if (node.metadata.any(_isRiverpodAnnotation)) return;
    super.visitClassDeclaration(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    final wasInBuild = _inBuild;
    _inBuild = node.name.lexeme == 'build';
    super.visitMethodDeclaration(node);
    _inBuild = wasInBuild;
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_inBuild && _isRiverpodRefWatch(node) && !_isNarrowWatch(node)) {
      offsets.add(node.offset);
    }
    super.visitMethodInvocation(node);
  }
}

const _riverpodRefType = TypeChecker.fromName('Ref', packageName: 'riverpod');

bool _isRiverpodRefWatch(MethodInvocation node) {
  final type = node.realTarget?.staticType;
  return node.methodName.name == 'watch' &&
      type is InterfaceType &&
      (_riverpodRefType.isAssignableFromType(type) || _widgetRef.isAssignableFromType(type));
}

/// Watches that already rebuild on a narrow value: `select`, `.notifier`,
/// computed projection providers, scalar results, values consumed whole, and
/// MutationState flags.
bool _isNarrowWatch(MethodInvocation watch) {
  final argument = watch.argumentList.arguments.firstOrNull;
  if (argument is! Expression) return false;
  if (argument is MethodInvocation && argument.methodName.name == 'select') return true;
  if (argument is PrefixedIdentifier && argument.identifier.name == 'notifier' ||
      argument is PropertyAccess && argument.propertyName.name == 'notifier') {
    return true;
  }
  if (_isProjectionProviderWatch(argument)) return true;
  final type = watch.staticType;
  // Scalar values already form an atomic rebuild boundary.
  if (type != null &&
      (type.isDartCoreBool ||
          type.isDartCoreString ||
          type.isDartCoreInt ||
          type.isDartCoreDouble ||
          type.isDartCoreNum ||
          type.element is EnumElement)) {
    return true;
  }
  if (_consumesWholeWatch(watch)) return true;
  // The skill allows MutationState flags (isPending, hasError, ...) for simple checks.
  return _isRiverpodMutationElement(type?.element, 'MutationState');
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

const _providerOrFamily = TypeChecker.fromName('ProviderOrFamily', packageName: 'riverpod');

bool _isRiverpodPackageLibrary(LibraryElement? library) {
  final uri = library?.uri.toString() ?? '';
  return uri.startsWith('package:riverpod/') ||
      uri.startsWith('package:flutter_riverpod/') ||
      uri.startsWith('package:hooks_riverpod/');
}

/// A provider class declared by Riverpod itself, as opposed to a generated provider class.
bool _isRiverpodProviderClass(Element? element) =>
    element is InterfaceElement &&
    _isRiverpodPackageLibrary(element.library) &&
    _providerOrFamily.isSuperOf(element);

Element? _leftmostElement(Expression? expression) => switch (expression) {
  SimpleIdentifier(:final element) => element,
  PrefixedIdentifier(:final prefix, :final identifier) =>
    prefix.element is PrefixElement ? identifier.element : prefix.element,
  PropertyAccess(:final target) => _leftmostElement(target),
  _ => null,
};

/// Constructor calls and static builder calls (`Provider.family(...)`) on Riverpod provider classes.
final class _ManualProviderCreationFinder extends RecursiveAstVisitor<void> {
  final nodes = <Expression>[];

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (_isRiverpodProviderClass(node.constructorName.type.element)) nodes.add(node);
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_isRiverpodProviderClass(_leftmostElement(node.target))) nodes.add(node);
    super.visitMethodInvocation(node);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    if (_isRiverpodProviderClass(_leftmostElement(node.function))) nodes.add(node);
    super.visitFunctionExpressionInvocation(node);
  }
}

int _unitLineIndex(SourceScannerContext context, int offset) =>
    context.unit.lineInfo.getLocation(offset).lineNumber - 1;

void _reportResolvedManualProviders(
  ScannerRuleReporter reporter,
  SourceScannerContext context,
  Set<int> reportedLines,
) {
  final finder = _ManualProviderCreationFinder();
  context.unit.accept(finder);
  for (final node in finder.nodes) {
    final owner = node.thisOrAncestorMatching(
      (candidate) =>
          candidate is TopLevelVariableDeclaration ||
          candidate is FieldDeclaration ||
          candidate is VariableDeclarationStatement ||
          candidate is FunctionDeclaration ||
          candidate is MethodDeclaration,
    );
    final ownerLine = owner is AnnotatedNode
        ? _unitLineIndex(context, owner.firstTokenAfterCommentAndMetadata.offset)
        : owner == null
        ? null
        : _unitLineIndex(context, owner.offset);
    final location = context.unit.lineInfo.getLocation(node.offset);
    final line = location.lineNumber - 1;
    if (reportedLines.contains(ownerLine) || !reportedLines.add(line)) continue;
    reporter.report(context, line, location.columnNumber - 1);
  }
}

/// Top-level or static declarations whose value is an existing provider.
void _reportProviderAliases(ScannerRuleReporter reporter, SourceScannerContext context) {
  void check(Token name, Expression? value) {
    final expression = value?.unParenthesized;
    if (expression == null || !_isProviderAliasValue(expression)) return;
    final location = context.unit.lineInfo.getLocation(name.offset);
    reporter.report(context, location.lineNumber - 1, location.columnNumber - 1);
  }

  for (final declaration in context.unit.declarations) {
    switch (declaration) {
      case TopLevelVariableDeclaration(:final variables):
        for (final variable in variables.variables) {
          check(variable.name, variable.initializer);
        }
      case FunctionDeclaration(isGetter: true, :final name, :final functionExpression):
        check(name, _expressionBodyValue(functionExpression.body));
      case ClassDeclaration(:final body) || MixinDeclaration(:final body):
        _checkStaticMembers(body, check);
      default:
        break;
    }
  }
}

void _checkStaticMembers(ClassBody body, void Function(Token, Expression?) check) {
  if (body is! BlockClassBody) return;
  for (final member in body.members) {
    if (member is FieldDeclaration && member.isStatic) {
      for (final variable in member.fields.variables) {
        check(variable.name, variable.initializer);
      }
    } else if (member is MethodDeclaration && member.isStatic && member.isGetter) {
      check(member.name, _expressionBodyValue(member.body));
    }
  }
}

Expression? _expressionBodyValue(FunctionBody body) {
  if (body is ExpressionFunctionBody) return body.expression;
  if (body is! BlockFunctionBody || body.block.statements.length != 1) return null;
  final statement = body.block.statements.single;
  return statement is ReturnStatement ? statement.expression : null;
}

/// A reference to (or family call on) an existing provider variable, not a new provider.
bool _isProviderAliasValue(Expression expression) {
  final type = expression.staticType;
  if (type is! InterfaceType || !_providerOrFamily.isAssignableFromType(type)) return false;
  final source = switch (expression) {
    FunctionExpressionInvocation(:final function) => function,
    MethodInvocation(:final target?, methodName: SimpleIdentifier(name: 'call')) => target,
    MethodInvocation(target: null, :final methodName) => methodName,
    _ => expression,
  };
  final element = switch (source) {
    SimpleIdentifier(:final element) => element,
    PrefixedIdentifier(:final element) => element,
    _ => null,
  };
  return element is PropertyAccessorElement && element.variable is TopLevelVariableElement;
}

const _consumerState = TypeChecker.fromName('ConsumerState', packageName: 'flutter_riverpod');
const _widgetRef = TypeChecker.fromName('WidgetRef', packageName: 'flutter_riverpod');

/// ConsumerState fields that store a `ref.watch`/`ref.read` result or a value derived from it.
void _reportResolvedConsumerStateCaches(
  ScannerRuleReporter reporter,
  SourceScannerContext context,
  Set<int> reportedLines,
) {
  for (final declaration in context.unit.declarations.whereType<ClassDeclaration>()) {
    final element = declaration.declaredFragment?.element;
    final body = declaration.body;
    if (element == null || body is! BlockClassBody || !_consumerState.isSuperOf(element)) {
      continue;
    }
    final finder = _ProviderDerivedFieldFinder(element);
    declaration.accept(finder);
    final derivedFields = body.members
        .whereType<FieldDeclaration>()
        .expand((member) => member.fields.variables)
        .where((variable) => finder.fields.contains(variable.declaredFragment?.element));
    for (final variable in derivedFields) {
      final location = context.unit.lineInfo.getLocation(variable.name.offset);
      final line = location.lineNumber - 1;
      if (reportedLines.add(line)) reporter.report(context, line, location.columnNumber - 1);
    }
  }
}

final class _ProviderDerivedFieldFinder extends RecursiveAstVisitor<void> {
  _ProviderDerivedFieldFinder(this.owner);

  final InterfaceElement owner;
  final fields = <Element>{};
  final _derivedLocals = <Element>{};

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    final initializer = node.initializer;
    final element = node.declaredFragment?.element;
    if (initializer != null && element != null && _isProviderDerived(initializer)) {
      if (element is FieldElement) {
        if (element.enclosingElement == owner && !element.isStatic) fields.add(element);
      } else {
        _derivedLocals.add(element);
      }
    }
    super.visitVariableDeclaration(node);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    final target = node.writeElement;
    final field = target is PropertyAccessorElement ? target.variable : target;
    if (field is FieldElement &&
        field.enclosingElement == owner &&
        !field.isStatic &&
        _isProviderDerived(node.rightHandSide)) {
      fields.add(field);
    }
    super.visitAssignmentExpression(node);
  }

  bool _isProviderDerived(Expression expression) {
    final value = expression.unParenthesized;
    return switch (value) {
      MethodInvocation(:final target?, :final methodName) =>
        _isWidgetRefRead(target, methodName.name) || _isProviderDerived(target),
      PropertyAccess(:final target?) => _isProviderDerived(target),
      PrefixedIdentifier(:final prefix) => _isProviderDerived(prefix),
      IndexExpression(:final target?) => _isProviderDerived(target),
      AwaitExpression(:final expression) => _isProviderDerived(expression),
      PostfixExpression(:final operand, operator: Token(lexeme: '!')) => _isProviderDerived(
        operand,
      ),
      BinaryExpression(:final leftOperand, :final rightOperand, operator: Token(lexeme: '??')) =>
        _isProviderDerived(leftOperand) || _isProviderDerived(rightOperand),
      ConditionalExpression(:final thenExpression, :final elseExpression) =>
        _isProviderDerived(thenExpression) || _isProviderDerived(elseExpression),
      SimpleIdentifier(:final element) => _derivedLocals.contains(element),
      _ => false,
    };
  }

  bool _isWidgetRefRead(Expression target, String method) {
    if (method != 'watch' && method != 'read') return false;
    final type = target.staticType;
    return type is InterfaceType && _widgetRef.isAssignableFromType(type);
  }
}

const _flutterWidgetOrState = TypeChecker.any([
  TypeChecker.fromName('Widget', packageName: 'flutter'),
  TypeChecker.fromName('State', packageName: 'flutter'),
]);

void _reportWidgetRefOutsideWidgets(ScannerRuleReporter reporter, SourceScannerContext context) {
  final finder = _WidgetRefTypeFinder();
  context.unit.accept(finder);
  for (final node in finder.nodes) {
    reporter.reportNode(context, node);
  }
}

final class _WidgetRefTypeFinder extends RecursiveAstVisitor<void> {
  final nodes = <NamedType>[];

  @override
  void visitNamedType(NamedType node) {
    final element = node.element;
    if (element is InterfaceElement && _widgetRef.isExactly(element) && _isOutsideWidget(node)) {
      nodes.add(node);
    }
    super.visitNamedType(node);
  }

  bool _isOutsideWidget(AstNode node) {
    final owner = node.thisOrAncestorMatching(
      (candidate) =>
          candidate is ClassDeclaration ||
          candidate is MixinDeclaration ||
          candidate is EnumDeclaration,
    );
    final element = switch (owner) {
      ClassDeclaration(:final declaredFragment?) => declaredFragment.element,
      MixinDeclaration(:final declaredFragment?) => declaredFragment.element,
      EnumDeclaration(:final declaredFragment?) => declaredFragment.element,
      _ => null,
    };
    return element != null && !_flutterWidgetOrState.isSuperOf(element);
  }
}
