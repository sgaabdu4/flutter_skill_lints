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
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.path);

  final AvoidThrow rule;
  final String path;
  Set<Element>? _flutterCallbackTargets;

  @override
  void visitThrowExpression(ThrowExpression node) {
    if (_isValueObjectArgumentGuard(node, path)) return;
    if (_isRecoverableException(node.expression.staticType) && !_isPresentationContext(node)) {
      return;
    }
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

bool _isValueObjectArgumentGuard(ThrowExpression node, String path) {
  if (!path.replaceAll('\\', '/').contains('/domain/values/')) return false;
  final error = node.expression;
  if (error is! InstanceCreationExpression || error.constructorName.element?.name != 'value') {
    return false;
  }
  final type = error.staticType;
  if (type is! InterfaceType ||
      type.element.name != 'ArgumentError' ||
      type.element.library.identifier != 'dart:core') {
    return false;
  }
  final arguments = error.argumentList.arguments;
  if (arguments.isEmpty) return false;
  final value = arguments.first.argumentExpression;
  if (value is! SimpleIdentifier || value.element is! FormalParameterElement) return false;
  IfStatement? guard;
  ConstructorDeclaration? factory;
  for (AstNode? parent = node.parent; parent != null; parent = parent.parent) {
    if (parent is IfStatement &&
        parent.thenStatement.offset <= node.offset &&
        parent.thenStatement.end >= node.end) {
      guard ??= parent;
    }
    if (parent is ConstructorDeclaration) {
      factory = parent;
      break;
    }
  }
  return factory?.factoryKeyword != null &&
      guard != null &&
      RegExp('\\b${RegExp.escape(value.name)}\\b').hasMatch(guard.expression.toSource());
}
