import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Warns when a function or method mutates one of its parameters.
final class AvoidMutatingParameters extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_mutating_parameters',
    'Avoid mutating parameters.',
    correctionMessage: 'Copy the value into a local variable or return a new value.',
  );

  AvoidMutatingParameters()
    : super(
        name: 'avoid_mutating_parameters',
        description: 'Warns when parameters are reassigned or mutated through direct writes.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final visitor = _Visitor(this);
    registry
      ..addFunctionDeclaration(this, visitor)
      ..addFunctionExpression(this, visitor)
      ..addMethodDeclaration(this, visitor);
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidMutatingParameters rule;

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _check(node.functionExpression.parameters, node.functionExpression.body);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    if (node.parent is FunctionDeclaration) return;
    _check(
      node.parameters,
      node.body,
      sdkOptionsBuilderParameters: _sentryFlutterOptionsBuilderParameters(node),
    );
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _check(node.parameters, node.body);
  }

  void _check(
    FormalParameterList? parameters,
    FunctionBody body, {
    Set<FormalParameterElement> sdkOptionsBuilderParameters = const {},
  }) {
    final names = formalParameterNames(parameters);
    final parameterElements = _formalParameterElements(parameters);
    if (names.isEmpty) return;
    body.accept(
      _MutationVisitor(
        rule,
        names,
        parameterElements: parameterElements,
        sdkOptionsBuilderParameters: sdkOptionsBuilderParameters,
      ),
    );
  }
}

Set<FormalParameterElement> _formalParameterElements(FormalParameterList? parameters) {
  final elements = <FormalParameterElement>{};
  for (final parameter in parameters?.parameters ?? const <FormalParameter>[]) {
    final element = parameter.declaredFragment?.element;
    if (element is FormalParameterElement) elements.add(element);
  }
  return elements;
}

final class _MutationVisitor extends RecursiveAstVisitor<void> {
  _MutationVisitor(
    this.rule,
    this.parameters, {
    required this.parameterElements,
    this.sdkOptionsBuilderParameters = const {},
  });

  final AvoidMutatingParameters rule;
  final Set<String> parameters;
  final Set<FormalParameterElement> parameterElements;
  final Set<FormalParameterElement> sdkOptionsBuilderParameters;
  int _nestedFunctionDepth = 0;

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    final target = _writeTarget(node.leftHandSide);
    if (target != null) {
      rule.reportAtNode(target);
    }
    super.visitAssignmentExpression(node);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    if (!node.operator.type.isIncrementOperator) return;
    final target = _writeTarget(node.operand);
    if (target != null) {
      rule.reportAtNode(target);
    }
    super.visitPostfixExpression(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    if (!node.operator.type.isIncrementOperator) return;
    final target = _writeTarget(node.operand);
    if (target != null) {
      rule.reportAtNode(target);
    }
    super.visitPrefixExpression(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    if (sdkOptionsBuilderParameters.isEmpty) return;
    _nestedFunctionDepth++;
    super.visitFunctionExpression(node);
    _nestedFunctionDepth--;
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (sdkOptionsBuilderParameters.isEmpty) return;
    _nestedFunctionDepth++;
    super.visitFunctionDeclaration(node);
    _nestedFunctionDepth--;
  }

  AstNode? _writeTarget(Expression expression) {
    if (_nestedFunctionDepth > 0) {
      return _sdkOptionsParameterWriteTarget(expression, sdkOptionsBuilderParameters);
    }
    return _parameterWriteTarget(
      expression,
      parameters,
      parameterElements: parameterElements,
      sdkOptionsBuilderParameters: sdkOptionsBuilderParameters,
    );
  }
}

Set<FormalParameterElement> _sentryFlutterOptionsBuilderParameters(FunctionExpression node) {
  final callbackParameter = node.correspondingParameter;
  final initMethod = callbackParameter?.enclosingElement;
  if (callbackParameter == null || initMethod is! MethodElement || initMethod.name != 'init') {
    return const {};
  }

  final owner = initMethod.enclosingElement;
  if (owner == null ||
      (owner is! ClassElement && owner is! MixinElement) ||
      owner.name != 'SentryFlutter' ||
      initMethod.library.identifier != 'package:sentry_flutter/src/sentry_flutter.dart') {
    return const {};
  }

  final callbackTypeAlias = callbackParameter.type.alias?.element;
  if (callbackTypeAlias == null ||
      callbackTypeAlias.name != 'FlutterOptionsConfiguration' ||
      callbackTypeAlias.enclosingElement.identifier !=
          'package:sentry_flutter/src/sentry_flutter.dart') {
    return const {};
  }

  final aliasedType = callbackTypeAlias.aliasedType;
  if (aliasedType is! FunctionType ||
      aliasedType.formalParameters.length != 1 ||
      !_isSentryFlutterOptionsType(aliasedType.formalParameters.single.type)) {
    return const {};
  }

  final callbackParameters = node.parameters?.parameters;
  if (callbackParameters == null ||
      callbackParameters.length != aliasedType.formalParameters.length) {
    return const {};
  }

  final parameter = callbackParameters.single.declaredFragment?.element;
  if (parameter == null || !_isSentryFlutterOptionsType(parameter.type)) return const {};
  return {parameter};
}

bool _isSentryFlutterOptionsType(DartType type) {
  if (type is! InterfaceType) return false;
  final element = type.element;
  return element is ClassElement &&
      element.name == 'SentryFlutterOptions' &&
      element.library.identifier == 'package:sentry_flutter/src/sentry_flutter_options.dart';
}

AstNode? _sdkOptionsParameterWriteTarget(
  Expression expression,
  Set<FormalParameterElement> parameters,
) {
  return switch (expression) {
    SimpleIdentifier() when _isSdkOptionsParameter(expression, parameters) => expression,
    PrefixedIdentifier(:final prefix, :final identifier)
        when _isSdkOptionsParameter(prefix, parameters) =>
      identifier,
    PropertyAccess(target: final SimpleIdentifier target, :final propertyName)
        when _isSdkOptionsParameter(target, parameters) =>
      propertyName,
    PropertyAccess(isCascaded: true, :final propertyName)
        when _cascadeTargetsSdkOptionsParameter(expression, parameters) =>
      propertyName,
    IndexExpression(target: final SimpleIdentifier target)
        when _isSdkOptionsParameter(target, parameters) =>
      expression,
    _ => null,
  };
}

bool _isSdkOptionsParameter(SimpleIdentifier identifier, Set<FormalParameterElement> parameters) {
  final element = identifier.element;
  return element is FormalParameterElement &&
      parameters.any((parameter) => parameter.baseElement == element.baseElement);
}

bool _cascadeTargetsSdkOptionsParameter(AstNode node, Set<FormalParameterElement> parameters) {
  final target = _cascadeTargetIdentifier(node);
  return target != null && _isSdkOptionsParameter(target, parameters);
}

SimpleIdentifier? _cascadeTargetIdentifier(AstNode node) {
  AstNode? ancestor = node.parent;
  while (ancestor != null && ancestor is! CascadeExpression) {
    ancestor = ancestor.parent;
  }
  if (ancestor is! CascadeExpression) return null;
  final target = ancestor.target;
  return target is SimpleIdentifier ? target : null;
}

AstNode? _parameterWriteTarget(
  Expression expression,
  Set<String> parameters, {
  required Set<FormalParameterElement> parameterElements,
  Set<FormalParameterElement> sdkOptionsBuilderParameters = const {},
}) {
  return switch (expression) {
    SimpleIdentifier(:final name)
        when parameters.contains(name) &&
            !_shadowsSdkOptionsParameter(expression, sdkOptionsBuilderParameters) =>
      expression,
    PrefixedIdentifier(:final prefix, :final identifier)
        when parameters.contains(prefix.name) &&
            !_shadowsSdkOptionsParameter(prefix, sdkOptionsBuilderParameters) &&
            !_isSdkOptionsParameter(prefix, sdkOptionsBuilderParameters) =>
      identifier,
    PropertyAccess(target: final SimpleIdentifier target, :final propertyName)
        when parameters.contains(target.name) &&
            !_shadowsSdkOptionsParameter(target, sdkOptionsBuilderParameters) &&
            !_isSdkOptionsParameter(target, sdkOptionsBuilderParameters) =>
      propertyName,
    PropertyAccess(isCascaded: true, :final propertyName)
        when _cascadeTargetsParameter(expression, parameterElements, sdkOptionsBuilderParameters) =>
      propertyName,
    IndexExpression(target: final SimpleIdentifier target)
        when parameters.contains(target.name) &&
            !_shadowsSdkOptionsParameter(target, sdkOptionsBuilderParameters) =>
      expression,
    _ => null,
  };
}

bool _shadowsSdkOptionsParameter(
  SimpleIdentifier identifier,
  Set<FormalParameterElement> sdkOptionsBuilderParameters,
) {
  return sdkOptionsBuilderParameters.any((parameter) => parameter.name == identifier.name) &&
      !_isSdkOptionsParameter(identifier, sdkOptionsBuilderParameters);
}

bool _cascadeTargetsParameter(
  AstNode node,
  Set<FormalParameterElement> parameters,
  Set<FormalParameterElement> sdkOptionsBuilderParameters,
) {
  final target = _cascadeTargetIdentifier(node);
  if (target == null) return false;
  final element = target.element;
  return element is FormalParameterElement &&
      parameters.any((parameter) => parameter.baseElement == element.baseElement) &&
      !_shadowsSdkOptionsParameter(target, sdkOptionsBuilderParameters) &&
      !_isSdkOptionsParameter(target, sdkOptionsBuilderParameters);
}
