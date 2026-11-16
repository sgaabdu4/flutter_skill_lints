import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

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
  void visitMethodInvocation(MethodInvocation node) {
    if (_isHopCall(node.methodName.element) ||
        (_completionMethods.contains(node.methodName.name) && _isCompleted(node.realTarget)) ||
        (followHelpers && _wrapsHop(node.methodName.element))) {
      report(node);
    }
    super.visitMethodInvocation(node);
  }

  bool _isCompleted(Expression? target) => switch (target) {
    ParenthesizedExpression() => _isCompleted(target.expression),
    SimpleIdentifier() => _isCompletedVariable(target.element),
    _ => _isCompletedCreation(target),
  };

  bool _isCompletedVariable(Element? element) {
    if (element is! LocalVariableElement) return false;
    final finder = _InitializerFinder(element);
    _body.accept(finder);
    return _isCompletedCreation(finder.initializer);
  }

  bool _wrapsHop(Element? element) {
    final unit = _body.thisOrAncestorOfType<CompilationUnit>();
    for (final declaration in unit?.declarations ?? const <CompilationUnitMember>[]) {
      if (declaration is FunctionDeclaration && declaration.declaredFragment?.element == element) {
        var found = false;
        final body = declaration.functionExpression.body;
        body.accept(ProviderTurnHopVisitor((_) => found = true, body, followHelpers: false));
        return found;
      }
    }
    return false;
  }
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

const _completionMethods = {'then', 'catchError', 'whenComplete'};
const _completedFutureConstructors = {'value', 'sync'};

bool _isIn(Element element, String className, String library) =>
    element.enclosingElement?.name == className && element.library?.uri.toString() == library;

bool _isHopConstructor(ConstructorElement? element, ArgumentList arguments) {
  if (element == null) return false;
  if (_isIn(element, 'Future', 'dart:async')) {
    return element.name == 'new' ||
        element.name == 'microtask' ||
        (element.name == 'delayed' && _isShortDelay(arguments));
  }
  return _isIn(element, 'Timer', 'dart:async') && element.name == 'new' && _isShortDelay(arguments);
}

bool _isCompletedCreation(Expression? expression) {
  final element = switch (expression) {
    InstanceCreationExpression() => expression.constructorName.element,
    DotShorthandConstructorInvocation() => expression.element,
    _ => null,
  };
  return element != null &&
      _isIn(element, 'Future', 'dart:async') &&
      _completedFutureConstructors.contains(element.name);
}

bool _isHopCall(Element? element) =>
    (element is TopLevelFunctionElement &&
        element.name == 'scheduleMicrotask' &&
        element.library.uri.toString() == 'dart:async') ||
    (element is MethodElement && element.name == 'run' && _isIn(element, 'Timer', 'dart:async'));

bool _isShortDelay(ArgumentList arguments) =>
    arguments.arguments.take(1).any((first) => _isShortDuration(first.argumentExpression));

bool _isShortDuration(Expression expression) => switch (expression) {
  PrefixedIdentifier() => _isZeroDuration(expression.identifier),
  DotShorthandPropertyAccess() => _isZeroDuration(expression.propertyName),
  InstanceCreationExpression() => _isUnderOneMillisecond(expression.argumentList),
  _ => false,
};

bool _isZeroDuration(SimpleIdentifier name) => name.name == 'zero';

bool _isUnderOneMillisecond(ArgumentList arguments) {
  var microseconds = 0;
  for (final argument in arguments.arguments) {
    final value = argument.argumentExpression;
    final amount = value is IntegerLiteral ? value.value : null;
    if (amount == null) return false;
    if (argument is NamedArgument && argument.name.lexeme == 'microseconds') {
      microseconds = amount;
    } else if (amount != 0) {
      return false;
    }
  }
  return microseconds < 1000;
}
