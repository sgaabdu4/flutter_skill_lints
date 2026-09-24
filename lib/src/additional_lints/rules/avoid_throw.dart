import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Warns when an untyped or non-recoverable value is thrown.
///
/// Resolved `dart:core` `Error.throwWithStackTrace` calls follow the same
/// contract, except when they propagate the error and stack trace caught by
/// the same enclosing catch clause. The documented scoped Riverpod provider
/// stub (`@Riverpod(dependencies: [...])` with an expression body of
/// `throw UnimplementedError()`) is allowed because it must be overridden.
/// Typed [Exception] subtypes, including `FormatException`, may be thrown by
/// parsers and infrastructure code. Throws in resolved Flutter `Widget` or
/// `State` members, Flutter widget callbacks, and Riverpod notifier methods
/// remain warnings. Direct same-unit function and method references passed to
/// Flutter callbacks are recognized. The rule cannot prove that a caller
/// catches a failure or discover every callback connection across files.
class AvoidThrow extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_throw',
    'Avoid throw expressions.',
    correctionMessage: 'Return a typed failure or use the project error boundary.',
    severity: DiagnosticSeverity.ERROR,
  );

  AvoidThrow()
    : super(
        name: 'avoid_throw',
        description: 'Warns when an untyped or non-recoverable value is thrown.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (isGeneratedRuleContext(context)) return;
    final visitor = _Visitor(this, context.definingUnit.file.path);
    registry.addThrowExpression(this, visitor);
    registry.addMethodInvocation(this, visitor);
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.path);

  final AvoidThrow rule;
  final String path;
  Set<Element>? _flutterCallbackTargets;

  @override
  void visitThrowExpression(ThrowExpression node) {
    if (_isValueObjectArgumentGuard(node, path) || _isScopedProviderOverrideStub(node)) return;
    if (_isRecoverableException(node.expression.staticType) && !_isPresentationContext(node)) {
      return;
    }
    rule.reportAtNode(node);
  }

  /// Applies the direct-throw contract to resolved `dart:core`
  /// `Error.throwWithStackTrace`, except when it propagates the error and
  /// stack trace caught by the same enclosing catch clause.
  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (!_isCoreThrowWithStackTrace(node.methodName.element)) return;
    final arguments = node.argumentList.arguments;
    if (arguments.length != 2) return;
    final error = arguments[0].argumentExpression;
    if (_isCaughtPairPropagation(node, error, arguments[1].argumentExpression)) return;
    if (_isRecoverableException(error.staticType) && !_isPresentationContext(node)) return;
    rule.reportAtNode(node);
  }

  bool _isPresentationContext(AstNode node) {
    for (AstNode? current = node.parent; current != null; current = current.parent) {
      if (_isPresentationBoundary(node, current)) return true;
    }
    return false;
  }

  bool _isPresentationBoundary(AstNode node, AstNode ancestor) {
    if (ancestor is MethodDeclaration) {
      return _isFlutterWidgetOrStateMember(ancestor) || _isPresentationMethod(node, ancestor);
    }
    if (ancestor is ClassMember) return _isFlutterWidgetOrStateMember(ancestor);
    if (ancestor is FunctionExpression) return _isFlutterWidgetCallback(ancestor);
    if (ancestor is FunctionDeclaration) {
      return _isResolvedFlutterCallbackTarget(node, ancestor.declaredFragment?.element);
    }
    return false;
  }

  bool _isPresentationMethod(AstNode node, MethodDeclaration method) =>
      _isRiverpodNotifierMethod(method) ||
      _isResolvedFlutterCallbackTarget(node, method.declaredFragment?.element);

  bool _isFlutterWidgetOrStateMember(ClassMember member) {
    final classElement = enclosingClass(member)?.declaredFragment?.element;
    return classElement != null &&
        (_flutterWidgetChecker.isSuperOf(classElement) ||
            _flutterStateChecker.isSuperOf(classElement));
  }

  bool _isFlutterWidgetCallback(FunctionExpression function) {
    final argument = _namedArgumentOfFunctionExpression(function);
    return argument != null && _isFlutterWidgetCallbackArgument(argument);
  }

  bool _isResolvedFlutterCallbackTarget(AstNode node, Element? element) {
    if (element is! ExecutableElement ||
        (element is! TopLevelFunctionElement && element is! MethodElement)) {
      return false;
    }

    final unit = node.thisOrAncestorOfType<CompilationUnit>();
    if (unit == null) return false;
    final targets = _flutterCallbackTargets ??= _findFlutterCallbackTargets(unit);
    return targets.contains(element);
  }

  Set<Element> _findFlutterCallbackTargets(CompilationUnit unit) {
    final targets = <Element>{};
    unit.accept(_FlutterCallbackTargetFinder(targets));
    return targets;
  }

  NamedArgument? _namedArgumentOfFunctionExpression(FunctionExpression function) {
    AstNode? parent = function.parent;
    while (parent is ParenthesizedExpression) {
      parent = parent.parent;
    }
    if (parent is! NamedArgument || parent.argumentExpression.unParenthesized != function) {
      return null;
    }
    return parent;
  }

  bool _isRiverpodNotifierMethod(MethodDeclaration method) {
    final classElement = enclosingClass(method)?.declaredFragment?.element;
    return classElement != null && _riverpodNotifierChecker.isSuperOf(classElement);
  }
}

final class _FlutterCallbackTargetFinder extends RecursiveAstVisitor<void> {
  const _FlutterCallbackTargetFinder(this.targets);

  final Set<Element> targets;

  @override
  void visitNamedArgument(NamedArgument node) {
    if (_isFlutterWidgetCallbackArgument(node)) {
      final target = _callbackTargetElement(node.argumentExpression);
      if (target != null && (target is TopLevelFunctionElement || target is MethodElement)) {
        targets.add(target);
      }
    }
    super.visitNamedArgument(node);
  }
}

bool _isFlutterWidgetCallbackArgument(NamedArgument argument) {
  final parameter = argument.correspondingParameter;
  final callbackType = parameter?.type;
  if (parameter == null || callbackType is! FunctionType) return false;

  final executable = parameter.enclosingElement;
  if (executable is! ExecutableElement) return false;
  final owner = executable.enclosingElement;
  if (owner is InterfaceElement && _flutterWidgetChecker.isSuperOf(owner)) {
    return true;
  }

  return executable.library.identifier.startsWith('package:flutter/') &&
      _flutterWidgetChecker.isAssignableFromType(callbackType.returnType);
}

Element? _callbackTargetElement(Expression expression) {
  final target = expression.unParenthesized;
  return switch (target) {
    SimpleIdentifier() => target.element,
    PrefixedIdentifier() => target.identifier.element,
    PropertyAccess() => target.propertyName.element,
    FunctionReference() => _callbackTargetElement(target.function),
    _ => null,
  };
}

const _exceptionChecker = TypeChecker.fromUrl('dart:core#Exception');
const _errorChecker = TypeChecker.fromUrl('dart:core#Error');
const _flutterWidgetChecker = TypeChecker.fromName('Widget', packageName: 'flutter');
const _flutterStateChecker = TypeChecker.fromName('State', packageName: 'flutter');
const _riverpodAnnotationChecker = TypeChecker.fromName(
  'Riverpod',
  packageName: 'riverpod_annotation',
);
const _riverpodNotifierChecker = TypeChecker.any([
  TypeChecker.fromName('Notifier', packageName: 'riverpod'),
  TypeChecker.fromName('AsyncNotifier', packageName: 'riverpod'),
  TypeChecker.fromName('StreamNotifier', packageName: 'riverpod'),
  TypeChecker.fromName('StateNotifier', packageName: 'state_notifier'),
]);

bool _isRecoverableException(DartType? type) {
  if (type is! InterfaceType || !_exceptionChecker.isAssignableFromType(type)) {
    return false;
  }
  if (_errorChecker.isAssignableFromType(type)) return false;

  final element = type.element;
  return element.name != 'Exception' || element.library.identifier != 'dart:core';
}

bool _isCoreThrowWithStackTrace(Element? element) {
  if (element is! MethodElement || !element.isStatic || element.name != 'throwWithStackTrace') {
    return false;
  }
  final owner = element.enclosingElement;
  return owner is ClassElement && owner.name == 'Error' && owner.library.identifier == 'dart:core';
}

bool _isCaughtPairPropagation(AstNode node, Expression error, Expression stackTrace) {
  if (error is! SimpleIdentifier || stackTrace is! SimpleIdentifier) return false;
  for (var clause = node.thisOrAncestorOfType<CatchClause>(); clause != null;) {
    final caughtError = clause.exceptionParameter?.declaredFragment?.element;
    if (caughtError != null && caughtError == error.element) {
      final caughtStack = clause.stackTraceParameter?.declaredFragment?.element;
      return caughtStack != null && caughtStack == stackTrace.element;
    }
    clause = clause.parent?.thisOrAncestorOfType<CatchClause>();
  }
  return false;
}

/// The documented scoped-provider stub that must be overridden before use:
/// `@Riverpod(dependencies: [...]) T name(Ref ref) => throw UnimplementedError();`
bool _isScopedProviderOverrideStub(ThrowExpression node) {
  final body = node.parent;
  final function = body?.parent?.parent;
  if (body is! ExpressionFunctionBody ||
      function is! FunctionDeclaration ||
      function.parent is! CompilationUnit) {
    return false;
  }
  final error = node.expression;
  return error is InstanceCreationExpression &&
      _isCoreClassType(error.staticType, 'UnimplementedError') &&
      function.metadata.any(_isScopedRiverpodAnnotation);
}

bool _isScopedRiverpodAnnotation(Annotation annotation) {
  final constructor = annotation.element;
  if (constructor is! ConstructorElement ||
      !_riverpodAnnotationChecker.isExactly(constructor.enclosingElement)) {
    return false;
  }
  final arguments = annotation.arguments?.arguments ?? const <Argument>[];
  return arguments.any(
    (argument) => argument is NamedArgument && argument.name.lexeme == 'dependencies',
  );
}

bool _isValueObjectArgumentGuard(ThrowExpression node, String path) {
  if (!path.replaceAll('\\', '/').contains('/domain/values/')) return false;
  final parameter = _argumentErrorValueParameter(node.expression);
  if (parameter == null) return false;
  IfStatement? guard;
  for (AstNode? parent = node.parent; parent != null; parent = parent.parent) {
    if (parent is IfStatement && _contains(parent.thenStatement, node)) guard ??= parent;
    if (parent is ConstructorDeclaration) {
      return parent.factoryKeyword != null &&
          guard != null &&
          _referencesParameter(guard.expression, parameter, parent.body, {});
    }
  }
  return false;
}

/// The formal parameter passed as the value of a `dart:core`
/// `ArgumentError.value(...)` creation, if [error] is one.
FormalParameterElement? _argumentErrorValueParameter(Expression error) {
  if (error is! InstanceCreationExpression ||
      error.constructorName.element?.name != 'value' ||
      !_isCoreClassType(error.staticType, 'ArgumentError')) {
    return null;
  }
  final arguments = error.argumentList.arguments;
  if (arguments.isEmpty) return null;
  final value = arguments.first.argumentExpression;
  final parameter = value is SimpleIdentifier ? value.element : null;
  return parameter is FormalParameterElement ? parameter : null;
}

bool _contains(AstNode outer, AstNode inner) =>
    outer.offset <= inner.offset && outer.end >= inner.end;

bool _isCoreClassType(DartType? type, String name) =>
    type is InterfaceType &&
    type.element.name == name &&
    type.element.library.identifier == 'dart:core';

/// Whether [expression] reads [parameter] directly or through a `final` local
/// of [body] whose initializer (transitively) reads it.
bool _referencesParameter(
  Expression expression,
  FormalParameterElement parameter,
  FunctionBody body,
  Set<Element> visited,
) {
  final identifiers = <SimpleIdentifier>[];
  expression.accept(_IdentifierCollector(identifiers));
  for (final identifier in identifiers) {
    final element = identifier.element;
    if (element == parameter) return true;
    if (element is! LocalVariableElement || !element.isFinal || !visited.add(element)) continue;
    final initializer = _localInitializer(body, element);
    if (initializer != null && _referencesParameter(initializer, parameter, body, visited)) {
      return true;
    }
  }
  return false;
}

Expression? _localInitializer(FunctionBody body, LocalVariableElement local) {
  final declarations = <VariableDeclaration>[];
  body.accept(_LocalDeclarationCollector(declarations));
  for (final declaration in declarations) {
    if (declaration.declaredFragment?.element == local) return declaration.initializer;
  }
  return null;
}

final class _IdentifierCollector extends RecursiveAstVisitor<void> {
  const _IdentifierCollector(this.identifiers);

  final List<SimpleIdentifier> identifiers;

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) => identifiers.add(node);
}

final class _LocalDeclarationCollector extends RecursiveAstVisitor<void> {
  const _LocalDeclarationCollector(this.declarations);

  final List<VariableDeclaration> declarations;

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    declarations.add(node);
    super.visitVariableDeclaration(node);
  }
}
