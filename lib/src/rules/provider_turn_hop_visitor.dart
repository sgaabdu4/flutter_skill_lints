import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
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
  void visitForStatement(ForStatement node) {
    _reportAwaitFor(node.awaitKeyword, node.forLoopParts);
    super.visitForStatement(node);
  }

  @override
  void visitForElement(ForElement node) {
    _reportAwaitFor(node.awaitKeyword, node.forLoopParts);
    super.visitForElement(node);
  }

  void _reportAwaitFor(Token? awaitKeyword, ForLoopParts parts) {
    if (awaitKeyword != null && parts is ForEachParts && _isCompleted(parts.iterable)) {
      report(parts.iterable);
    }
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_isHopCall(node.methodName.element) ||
        (_completionMethods.contains(node.methodName.name) && _isCompleted(node.realTarget)) ||
        (followHelpers && _wrapsHop(node))) {
      report(node);
    }
    super.visitMethodInvocation(node);
  }

  bool _isCompleted(Expression? target) {
    if (target is ParenthesizedExpression) return _isCompleted(target.expression);
    if (target is SimpleIdentifier) return _isCompletedVariable(target);
    if (target is PrefixedIdentifier && target.identifier.name == 'future') {
      return _isCompletedCompleter(target.prefix, target);
    }
    if (target is PropertyAccess && target.propertyName.name == 'future') {
      return _isCompletedCompleter(target.realTarget, target);
    }
    return _isCompletedCreation(target);
  }

  bool _isCompletedVariable(SimpleIdentifier usage) {
    final element = usage.element;
    if (element is! LocalVariableElement) return false;
    final finder = _ValueFinder(element);
    _body.accept(finder);
    Expression? held = finder.initializer;
    var known = true;
    for (final assignment in finder.assignments) {
      if (assignment.offset > usage.offset) {
        if (_sharesLoop(usage, assignment)) return false;
        continue;
      }
      if (!_runsBefore(assignment, usage)) return false;
      final operator = assignment.operator.type;
      if (operator == TokenType.EQ) {
        held = assignment.rightHandSide;
        known = true;
      } else if (operator == TokenType.QUESTION_QUESTION_EQ) {
        if (known && (held == null || held is NullLiteral)) {
          held = assignment.rightHandSide;
        } else if (!known || !_isCompletedCreation(held)) {
          known = false;
        }
      } else {
        known = false;
      }
    }
    return known && _isCompletedCreation(held);
  }

  bool _isCompletedCompleter(Expression? holder, Expression usage) {
    final unwrapped = _withoutBang(holder);
    final element = unwrapped is SimpleIdentifier ? unwrapped.element : null;
    if (element is! LocalVariableElement) return false;
    final finder = _ValueFinder(element);
    _body.accept(finder);
    Expression? held = finder.initializer;
    var since = 0;
    for (final assignment in finder.assignments) {
      if (assignment.offset > usage.offset) {
        if (_sharesLoop(usage, assignment)) return false;
        continue;
      }
      if (assignment.operator.type != TokenType.EQ || !_runsBefore(assignment, usage)) {
        return false;
      }
      held = assignment.rightHandSide;
      since = assignment.end;
    }
    final creation = held is CascadeExpression ? held.target : held;
    if (!_isCompleterCreation(creation)) return false;
    if (held is CascadeExpression && held.cascadeSections.any(_isCompleteCall)) return true;
    final calls = _CompleteCallFinder(element, usage, since);
    _body.accept(calls);
    return calls.found;
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (followHelpers && _wrapsHopGetter(node)) report(node);
    super.visitSimpleIdentifier(node);
  }

  bool _wrapsHop(MethodInvocation call) {
    final body = _helperBody(call);
    return body != null && _hopsIn(body);
  }

  bool _wrapsHopGetter(SimpleIdentifier reference) {
    final element = reference.element;
    if (element is! GetterElement) return false;
    final parent = reference.parent;
    final own = switch (parent) {
      PrefixedIdentifier(:final identifier) when identifier == reference => false,
      PropertyAccess(:final propertyName, :final realTarget) when propertyName == reference =>
        realTarget is ThisExpression,
      _ => true,
    };
    if (!own) return false;
    final body =
        _memberBody(element) ?? topLevelFunctionOf(_body, element)?.functionExpression.body;
    return body != null && _hopsIn(body);
  }

  bool _hopsIn(FunctionBody body) {
    var found = false;
    body.accept(ProviderTurnHopVisitor((_) => found = true, body, followHelpers: false));
    return found;
  }

  FunctionBody? _helperBody(MethodInvocation call) {
    final element = call.methodName.element;
    final target = call.realTarget;
    if (element is MethodElement && (target == null || target is ThisExpression)) {
      return _memberBody(element);
    }
    return topLevelFunctionOf(_body, element)?.functionExpression.body;
  }

  FunctionBody? _memberBody(ExecutableElement element) {
    final unit = _body.thisOrAncestorOfType<CompilationUnit>();
    for (final declaration in unit?.declarations ?? const <CompilationUnitMember>[]) {
      final members = switch (declaration) {
        ClassDeclaration(:final body) => body is BlockClassBody ? body.members : null,
        MixinDeclaration(:final body) => body.members,
        ExtensionDeclaration(:final body) => body is BlockClassBody ? body.members : null,
        EnumDeclaration(:final body) => body.members,
        _ => null,
      };
      for (final member in members ?? const <ClassMember>[]) {
        if (member is MethodDeclaration &&
            member.declaredFragment?.element.baseElement == element.baseElement) {
          return member.body;
        }
      }
    }
    return null;
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

Expression? _withoutBang(Expression? expression) {
  var current = expression;
  while (true) {
    if (current is ParenthesizedExpression) {
      current = current.expression;
    } else if (current is PostfixExpression && current.operator.type == TokenType.BANG) {
      current = current.operand;
    } else {
      return current;
    }
  }
}

bool _runsBefore(AstNode earlier, AstNode usage) {
  if (earlier.offset >= usage.offset) return false;
  if (earlier.thisOrAncestorOfType<FunctionBody>() != usage.thisOrAncestorOfType<FunctionBody>()) {
    return false;
  }
  AstNode? node = earlier;
  var leftFinally = false;
  while (node != null) {
    if (!leftFinally &&
        node is Statement &&
        node is! ExpressionStatement &&
        node is! VariableDeclarationStatement) {
      return false;
    }
    leftFinally = false;
    final parent = node.parent;
    if (parent is Block) {
      if (parent.offset <= usage.offset && usage.end <= parent.end) return true;
      final owner = parent.parent;
      if (owner is! TryStatement || owner.finallyBlock != parent) return false;
      node = owner;
      leftFinally = true;
    } else {
      node = parent;
    }
  }
  return false;
}

bool _sharesLoop(AstNode usage, AstNode other) {
  for (AstNode? node = usage; node != null; node = node.parent) {
    if ((node is ForStatement || node is WhileStatement || node is DoStatement) &&
        node.offset <= other.offset &&
        other.end <= node.end) {
      return true;
    }
  }
  return false;
}

final class _CompleteCallFinder extends RecursiveAstVisitor<void> {
  _CompleteCallFinder(this._element, this._usage, this._since);

  final LocalVariableElement _element;
  final AstNode _usage;
  final int _since;
  bool found = false;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final target = _withoutBang(node.realTarget);
    if (target is SimpleIdentifier &&
        target.element == _element &&
        node.offset >= _since &&
        _isCompleteCall(node) &&
        _runsBefore(node, _usage)) {
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

final class _ValueFinder extends RecursiveAstVisitor<void> {
  _ValueFinder(this._element);

  final LocalVariableElement _element;
  Expression? initializer;
  final assignments = <AssignmentExpression>[];

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    if (node.declaredFragment?.element == _element) initializer = node.initializer;
    super.visitVariableDeclaration(node);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    final target = node.leftHandSide;
    if (target is SimpleIdentifier &&
        (target.element == _element || node.writeElement == _element)) {
      assignments.add(node);
    }
    super.visitAssignmentExpression(node);
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
