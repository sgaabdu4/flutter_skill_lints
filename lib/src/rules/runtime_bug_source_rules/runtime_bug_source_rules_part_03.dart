part of '../runtime_bug_source_rules.dart';

const _iterableChecker = TypeChecker.fromUrl('dart:core#Iterable');
const _mapChecker = TypeChecker.fromUrl('dart:core#Map');
const _widgetChecker = TypeChecker.fromName('Widget', packageName: 'flutter');

/// Map methods whose callback runs once per call rather than once per entry.
const _singleCallMapMethods = {'putIfAbsent', 'update'};

void _reportRepeatedIdLookups(ScannerRuleReporter reporter, SourceScannerContext context) {
  final visitor = _RepeatedIdLookupVisitor();
  context.unit.accept(visitor);
  _reportOffsets(reporter, context, visitor.offsets);
}

void _reportNestedIdLookups(ScannerRuleReporter reporter, SourceScannerContext context) {
  final visitor = _NestedIdLookupVisitor();
  context.unit.accept(visitor);
  _reportOffsets(reporter, context, visitor.offsets);
}

void _reportOffsets(ScannerRuleReporter reporter, SourceScannerContext context, List<int> offsets) {
  for (final offset in offsets) {
    final lineIndex = context.unit.lineInfo.getLocation(offset).lineNumber - 1;
    reporter.report(context, lineIndex, offset - context.source.lineOffsets[lineIndex]);
  }
}

/// Collects id lookups that run repeatedly: inside a loop, a collection-for,
/// an iteration callback over a collection, or a widget build path.
final class _RepeatedIdLookupVisitor extends RecursiveAstVisitor<void> {
  final offsets = <int>[];

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_isLinearIdLookup(node) && _runsRepeatedly(node)) offsets.add(node.operator!.offset);
    super.visitMethodInvocation(node);
  }

  @override
  void visitForStatement(ForStatement node) {
    if (_isManualIdLookupLoop(node.forLoopParts, node.body) && _runsRepeatedly(node)) {
      offsets.add(node.forKeyword.offset);
    }
    super.visitForStatement(node);
  }
}

/// Collects id lookups keyed by the variable of an enclosing for-in loop, e.g.
/// `for (final change in changes) items.indexWhere((i) => i.id == change.itemId)`.
final class _NestedIdLookupVisitor extends RecursiveAstVisitor<void> {
  final offsets = <int>[];

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_isLinearIdLookup(node) && _isKeyedByEnclosingLoop(node)) {
      offsets.add(node.operator!.offset);
    }
    super.visitMethodInvocation(node);
  }
}

bool _isKeyedByEnclosingLoop(MethodInvocation lookup) {
  final predicate = lookup.argumentList.arguments.first;
  for (var node = lookup.parent; node != null; node = node.parent) {
    final parts = switch (node) {
      ForStatement(:final forLoopParts) || ForElement(:final forLoopParts) => forLoopParts,
      _ => null,
    };
    final loopVariable = parts is ForEachPartsWithDeclaration
        ? parts.loopVariable.declaredFragment?.element
        : null;
    if (loopVariable != null && _references(predicate, loopVariable)) return true;
    if (node is ClassMember || node is CompilationUnitMember) return false;
  }
  return false;
}

bool _references(AstNode node, Element variable) {
  final finder = _ReferenceFinder(variable);
  node.accept(finder);
  return finder.found;
}

final class _ReferenceFinder extends RecursiveAstVisitor<void> {
  _ReferenceFinder(this.variable);

  final Element variable;
  bool found = false;

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.element == variable) found = true;
  }
}

/// `items.firstWhere((item) => item.id == ...)` or `indexWhere` on an Iterable
/// whose predicate compares the element's `id`.
bool _isLinearIdLookup(MethodInvocation node) {
  final name = node.methodName.name;
  if (name != 'firstWhere' && name != 'indexWhere') return false;
  final targetType = node.realTarget?.staticType;
  if (targetType == null || !_iterableChecker.isAssignableFromType(targetType)) return false;
  final arguments = node.argumentList.arguments;
  final predicate = arguments.isEmpty ? null : arguments.first;
  if (predicate is! FunctionExpression) return false;
  final parameters = predicate.parameters?.parameters;
  final parameter = parameters?.length == 1 ? parameters?.single.declaredFragment?.element : null;
  if (parameter == null) return false;
  return _comparesIdOf(predicate.body, parameter);
}

/// A `for` loop whose body compares the loop item's `id`, e.g.
/// `for (final item in items) { if (item.id == id) return item; }`.
bool _isManualIdLookupLoop(ForLoopParts parts, Statement body) {
  final loopVariable = switch (parts) {
    ForEachPartsWithDeclaration(:final loopVariable) => loopVariable.declaredFragment?.element,
    ForPartsWithDeclarations(:final variables) when variables.variables.length == 1 =>
      variables.variables.single.declaredFragment?.element,
    _ => null,
  };
  return loopVariable != null && _comparesIdOf(body, loopVariable);
}

bool _comparesIdOf(AstNode node, Element variable) {
  final finder = _IdComparisonFinder(variable);
  node.accept(finder);
  return finder.found;
}

final class _IdComparisonFinder extends RecursiveAstVisitor<void> {
  _IdComparisonFinder(this.loopVariable);

  final Element loopVariable;
  bool found = false;

  @override
  void visitBinaryExpression(BinaryExpression node) {
    if (node.operator.type == TokenType.EQ_EQ &&
        (_isIdOf(node.leftOperand, loopVariable) || _isIdOf(node.rightOperand, loopVariable))) {
      found = true;
      return;
    }
    super.visitBinaryExpression(node);
  }
}

/// Whether [expression] reads `.id` of [variable] or of `list[variable]`.
bool _isIdOf(Expression expression, Element? variable) {
  if (variable == null) return false;
  final Expression? target = switch (expression) {
    PrefixedIdentifier(:final identifier, :final prefix) when identifier.name == 'id' => prefix,
    PropertyAccess(:final propertyName, :final realTarget) when propertyName.name == 'id' =>
      realTarget,
    _ => null,
  };
  return switch (target) {
    SimpleIdentifier(:final element) => element == variable,
    IndexExpression(:final index) => index is SimpleIdentifier && index.element == variable,
    _ => false,
  };
}

/// Walks from [node] to its enclosing declaration and reports whether it runs
/// once per element of another collection or on every widget build.
bool _runsRepeatedly(AstNode node) {
  AstNode child = node;
  for (var parent = node.parent; parent != null; child = parent, parent = parent.parent) {
    switch (parent) {
      case ForStatement(:final body) when identical(child, body):
        return true;
      case ForElement(:final body) when identical(child, body):
        return true;
      case ForParts(:final condition, :final updaters)
          when identical(child, condition) || updaters.contains(child):
        return true;
      case WhileStatement() || DoStatement():
        return true;
      case FunctionExpression():
        return _returnsWidget(parent.staticType) || _isIterationCallback(parent);
      case MethodDeclaration():
        return _returnsWidgetElement(parent.declaredFragment?.element);
      case ConstructorDeclaration() || FieldDeclaration() || TopLevelVariableDeclaration():
        return false;
    }
  }
  return false;
}

/// A positional callback passed to a collection method that invokes it once
/// per element, such as `map`, `where`, `forEach`, `any` or `fold`.
bool _isIterationCallback(FunctionExpression function) {
  final arguments = function.parent;
  final invocation = arguments?.parent;
  if (arguments is! ArgumentList || invocation is! MethodInvocation) return false;
  final targetType = invocation.realTarget?.staticType;
  if (targetType == null) return false;
  if (_iterableChecker.isAssignableFromType(targetType)) return true;
  return _mapChecker.isAssignableFromType(targetType) &&
      !_singleCallMapMethods.contains(invocation.methodName.name);
}

bool _returnsWidget(DartType? type) =>
    type is FunctionType && _widgetChecker.isAssignableFromType(type.returnType);

bool _returnsWidgetElement(ExecutableElement? element) =>
    element != null && _widgetChecker.isAssignableFromType(element.returnType);

void _reportStorageClearSentinels(ScannerRuleReporter reporter, SourceScannerContext context) {
  for (final classSpan in context.classes) {
    if (!_isStorageBoundaryClass(context, classSpan)) continue;
    for (final method in context.methods.where((method) => classSpan.contains(method.start))) {
      if (_methodLooksLikeResetAll(method.name)) {
        _reportStorageClearMethod(reporter, context, method);
      }
    }
  }
}

void _reportStorageClearMethod(
  ScannerRuleReporter reporter,
  SourceScannerContext context,
  ScannerMethodSpan method,
) {
  for (
    var lineIndex = method.start;
    lineIndex <= method.end && lineIndex < context.source.length;
    lineIndex++
  ) {
    final match = _storageClearCall.firstMatch(context.source.masked[lineIndex]);
    if (match != null && _clearPreservesSentinel(context, method, lineIndex)) {
      reporter.report(context, lineIndex, match.start);
    }
  }
}

void _reportUngatedHeavyWidgets(ScannerRuleReporter reporter, SourceScannerContext context) {
  for (final classSpan in context.classes) {
    for (final method in context.methods.where((method) => method.name == 'build')) {
      if (classSpan.contains(method.start)) {
        _reportHeavyWidgetsInBuild(reporter, context, classSpan, method);
      }
    }
  }
}

void _reportHeavyWidgetsInBuild(
  ScannerRuleReporter reporter,
  SourceScannerContext context,
  ScannerClassSpan classSpan,
  ScannerMethodSpan method,
) {
  for (
    var lineIndex = method.start;
    lineIndex <= method.end && lineIndex < context.source.length;
    lineIndex++
  ) {
    final match = _heavyWidgetInit.firstMatch(context.source.masked[lineIndex]);
    if (match == null || _isHeavyWidgetGated(context, classSpan, method, lineIndex)) continue;
    reporter.report(context, lineIndex, match.start);
  }
}
