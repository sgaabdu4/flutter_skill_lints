import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

/// Reports each zero-delay turn hop in a provider body, closures included.
final class ProviderTurnHopVisitor extends RecursiveAstVisitor<void> {
  ProviderTurnHopVisitor(this.report, this._body, {this.followHelpers = true});

  final void Function(AstNode node) report;
  final FunctionBody _body;
  final bool followHelpers;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (_isHopConstructor(node.constructorName.element, node.argumentList)) report(node);
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitDotShorthandConstructorInvocation(DotShorthandConstructorInvocation node) {
    if (_isHopConstructor(node.element, node.argumentList)) report(node);
    super.visitDotShorthandConstructorInvocation(node);
  }

  @override
  void visitAwaitExpression(AwaitExpression node) {
    final operand = node.expression;
    if (operand is NullLiteral || _isCompleted(operand)) report(node);
    super.visitAwaitExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_isHopCall(node.methodName.element) ||
        (_completionMethods.contains(node.methodName.name) && _isCompleted(node.realTarget)) ||
        (followHelpers && _wrapsHop(node.methodName.element))) {
      report(node);
    }
    super.visitMethodInvocation(node);
  }

  bool _isCompleted(Expression? target) {
    if (target is ParenthesizedExpression) return _isCompleted(target.expression);
    if (target is SimpleIdentifier) return _isCompletedVariable(target.element);
    if (target is PrefixedIdentifier && target.identifier.name == 'future') {
      return _isCompletedCompleter(target.prefix, target.offset);
    }
    return _isCompletedCreation(target);
  }

  bool _isCompletedVariable(Element? element) {
    if (element is! LocalVariableElement) return false;
    final finder = _InitializerFinder(element);
    _body.accept(finder);
    return _isCompletedCreation(finder.initializer);
  }

  bool _isCompletedCompleter(Expression holder, int usedAt) {
    final element = holder is SimpleIdentifier ? holder.element : null;
    if (element is! LocalVariableElement) return false;
    final finder = _InitializerFinder(element);
    _body.accept(finder);
    final initializer = finder.initializer;
    final creation = initializer is CascadeExpression ? initializer.target : initializer;
    if (!_isCompleterCreation(creation)) return false;
    if (initializer is CascadeExpression && initializer.cascadeSections.any(_isCompleteCall)) {
      return true;
    }
    final calls = _CompleteCallFinder(element, usedAt);
    _body.accept(calls);
    return calls.found;
  }

  bool _wrapsHop(Element? element) {
    final declaration = topLevelFunctionOf(_body, element);
    if (declaration == null) return false;
    var found = false;
    final body = declaration.functionExpression.body;
    body.accept(ProviderTurnHopVisitor((_) => found = true, body, followHelpers: false));
    return found;
  }
}

FunctionDeclaration? topLevelFunctionOf(AstNode from, Element? element) {
  final unit = from.thisOrAncestorOfType<CompilationUnit>();
  for (final declaration in unit?.declarations ?? const <CompilationUnitMember>[]) {
    if (declaration is FunctionDeclaration && declaration.declaredFragment?.element == element) {
      return declaration;
    }
  }
  return null;
}

final class _CompleteCallFinder extends RecursiveAstVisitor<void> {
  _CompleteCallFinder(this._element, this._before);

  final LocalVariableElement _element;
  final int _before;
  bool found = false;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final target = node.realTarget;
    if (node.offset < _before &&
        target is SimpleIdentifier &&
        target.element == _element &&
        _isCompleteCall(node)) {
      found = true;
    }
    super.visitMethodInvocation(node);
  }
}

bool _isCompleteCall(Expression node) {
  if (node is! MethodInvocation) return false;
  final name = node.methodName.name;
  if (name == 'completeError') return true;
  if (name != 'complete') return false;
  final arguments = node.argumentList.arguments;
  return arguments.isEmpty || !_mayBeFuture(arguments.first.argumentExpression.staticType);
}

bool _isCompleterCreation(Expression? expression) {
  final element = switch (expression) {
    InstanceCreationExpression() => expression.constructorName.element,
    DotShorthandConstructorInvocation() => expression.element,
    _ => null,
  };
  return element != null && _isIn(element, 'Completer', 'dart:async');
}

bool _mayBeFuture(DartType? type) {
  if (type == null || type is DynamicType || type is InvalidType) return true;
  if (type is TypeParameterType || type.isDartAsyncFuture || type.isDartAsyncFutureOr) return true;
  if (type.isDartCoreObject) return true;
  return type is InterfaceType &&
      type.allSupertypes.any((supertype) => supertype.isDartAsyncFuture);
}

final class _InitializerFinder extends RecursiveAstVisitor<void> {
  _InitializerFinder(this._element);

  final LocalVariableElement _element;
  Expression? initializer;

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    if (node.declaredFragment?.element == _element) initializer = node.initializer;
    super.visitVariableDeclaration(node);
  }
}

const _completionMethods = {'then', 'catchError', 'whenComplete', 'listen'};
const _completedStreamConstructors = {'value', 'error', 'fromIterable'};
const _microsecondsPerUnit = {
  'microseconds': 1,
  'milliseconds': 1000,
  'seconds': 1000000,
  'minutes': 60000000,
  'hours': 3600000000,
  'days': 86400000000,
};

bool _isIn(Element element, String className, String library) =>
    element.enclosingElement?.name == className && element.library?.uri.toString() == library;

bool _isHopConstructor(ConstructorElement? element, ArgumentList arguments) {
  if (element == null) return false;
  if (_isIn(element, 'Future', 'dart:async')) {
    return element.name == 'new' ||
        element.name == 'microtask' ||
        (element.name == 'delayed' && _isShortDelay(arguments));
  }
  return _isIn(element, 'Timer', 'dart:async') &&
      (element.name == 'new' || element.name == 'periodic') &&
      _isShortDelay(arguments);
}

bool _isCompletedCreation(Expression? expression) {
  final (element, arguments) = switch (expression) {
    InstanceCreationExpression() => (expression.constructorName.element, expression.argumentList),
    DotShorthandConstructorInvocation() => (expression.element, expression.argumentList),
    _ => (null, null),
  };
  if (element == null || arguments == null) return false;
  if (_isIn(element, 'Stream', 'dart:async')) {
    return _completedStreamConstructors.contains(element.name);
  }
  if (!_isIn(element, 'Future', 'dart:async')) return false;
  final first = arguments.arguments.firstOrNull?.argumentExpression;
  return switch (element.name) {
    'error' => true,
    'value' => first == null || !_mayBeFuture(first.staticType),
    'sync' => first != null && _returnsNoFuture(first.staticType),
    _ => false,
  };
}

bool _returnsNoFuture(DartType? callback) =>
    callback is FunctionType && !_mayBeFuture(callback.returnType);

bool _isHopCall(Element? element) =>
    (element is TopLevelFunctionElement &&
        element.name == 'scheduleMicrotask' &&
        element.library.uri.toString() == 'dart:async') ||
    (element is MethodElement &&
        (element.name == 'run' && _isIn(element, 'Timer', 'dart:async') ||
            element.name == 'scheduleMicrotask' && _isIn(element, 'Zone', 'dart:async')));

bool _isShortDelay(ArgumentList arguments) {
  final first = arguments.arguments.firstOrNull?.argumentExpression;
  final microseconds = first == null ? null : _microseconds(first, 0);
  return microseconds != null && microseconds < 1000;
}

int? _microseconds(Expression expression, int depth) {
  if (depth > 8) return null;
  final constant = expression.computeConstantValue()?.value;
  final stored = (constant?.getField('inMicroseconds') ?? constant?.getField('_duration'))
      ?.toIntValue();
  if (stored != null) return stored;
  return switch (expression) {
    ParenthesizedExpression() => _microseconds(expression.expression, depth + 1),
    InstanceCreationExpression() => _creationMicroseconds(
      expression.constructorName.element,
      expression.argumentList,
    ),
    DotShorthandConstructorInvocation() => _creationMicroseconds(
      expression.element,
      expression.argumentList,
    ),
    SimpleIdentifier() => _variableMicroseconds(expression.element, depth),
    PrefixedIdentifier() => _variableMicroseconds(expression.identifier.element, depth),
    PropertyAccess() => _variableMicroseconds(expression.propertyName.element, depth),
    DotShorthandPropertyAccess() => _variableMicroseconds(expression.propertyName.element, depth),
    _ => null,
  };
}

int? _variableMicroseconds(Element? element, int depth) {
  final variable = element is PropertyAccessorElement ? element.variable : element;
  if (variable is! VariableElement) return null;
  if (variable.name == 'zero' && _isIn(variable, 'Duration', 'dart:core')) return 0;
  final initializer = variable is LocalVariableElement ? variable.constantInitializer : null;
  return initializer == null ? null : _microseconds(initializer, depth + 1);
}

int? _creationMicroseconds(ConstructorElement? element, ArgumentList arguments) {
  if (element == null || !_isIn(element, 'Duration', 'dart:core')) return null;
  var total = 0;
  for (final argument in arguments.arguments) {
    final unit = argument is NamedArgument ? _microsecondsPerUnit[argument.name.lexeme] : null;
    final amount = argument.argumentExpression.computeConstantValue()?.value?.toIntValue();
    if (unit == null || amount == null) return null;
    total += unit * amount;
  }
  return total;
}
