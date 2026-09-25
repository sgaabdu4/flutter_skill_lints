import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/dart/element/type_visitor.dart';
import 'package:analyzer/error/error.dart';

/// Prefers Dart's dot shorthand whenever an existing context supplies the type.
final class PreferDotShorthands extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_dot_shorthands',
    'Use dot shorthand when the surrounding context already supplies the type.',
    correctionMessage: 'Remove the repeated type name.',
    severity: DiagnosticSeverity.ERROR,
  );

  PreferDotShorthands()
    : super(
        name: 'prefer_dot_shorthands',
        description: 'Prefers concise dot shorthand for contextually typed static access.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final visitor = _Visitor(this, context.typeSystem);
    registry
      ..addPrefixedIdentifier(this, visitor)
      ..addPropertyAccess(this, visitor)
      ..addMethodInvocation(this, visitor)
      ..addInstanceCreationExpression(this, visitor);
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule, this.typeSystem);

  final PreferDotShorthands rule;
  final TypeSystem typeSystem;

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) => _check(node);

  @override
  void visitPropertyAccess(PropertyAccess node) => _check(node);

  @override
  void visitMethodInvocation(MethodInvocation node) => _check(node);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) => _check(node);

  void _check(Expression expression) {
    final namespace = _candidateNamespace(expression);
    if (namespace == null) return;

    final contextExpression = _outermostSelector(expression);
    final expectedType = _expectedType(contextExpression);
    if (expectedType == null) return;

    final namespaceType = _namespaceType(expectedType);
    if (namespaceType is! InterfaceType ||
        !identical(namespaceType.element.baseElement, namespace.baseElement)) {
      return;
    }

    final resultType = contextExpression.staticType;
    if (resultType == null || !typeSystem.isSubtypeOf(resultType, expectedType)) return;
    if (expression is InstanceCreationExpression &&
        !typeSystem.isSubtypeOf(namespaceType, resultType)) {
      return;
    }

    rule.reportAtNode(expression);
  }

  InstanceElement? _candidateNamespace(Expression expression) {
    if (expression is PrefixedIdentifier) {
      final prefix = expression.prefix;
      final namespace = _interfaceElement(prefix);
      final owner = _staticMemberOwner(expression.identifier.element);
      if (namespace != null && identical(namespace.baseElement, owner?.baseElement)) {
        return namespace;
      }
    }
    if (expression case PropertyAccess(:final target)) {
      final namespace = _interfaceElement(target);
      final owner = _staticMemberOwner(expression.propertyName.element);
      if (target != null &&
          namespace != null &&
          identical(namespace.baseElement, owner?.baseElement)) {
        return namespace;
      }
    }
    if (expression case MethodInvocation(:final target)) {
      final namespace = _interfaceElement(target);
      final owner = _staticMemberOwner(expression.methodName.element);
      if (target != null &&
          namespace != null &&
          identical(namespace.baseElement, owner?.baseElement)) {
        return namespace;
      }
    }
    if (expression case InstanceCreationExpression(constructorName: ConstructorName(:final element))
        when element != null) {
      return element.enclosingElement;
    }
    return null;
  }

  InstanceElement? _interfaceElement(Expression? expression) {
    final element = switch (expression) {
      SimpleIdentifier(:final element) => element,
      PrefixedIdentifier(identifier: SimpleIdentifier(:final element)) => element,
      _ => null,
    };
    if (element is InstanceElement) return element;
    if (element is TypeAliasElement) {
      final aliasedElement = _namespaceType(element.aliasedType).element;
      return aliasedElement is InstanceElement ? aliasedElement : null;
    }
    return null;
  }

  InstanceElement? _staticMemberOwner(Element? element) => switch (element) {
    ExecutableElement(isStatic: true, enclosingElement: final InstanceElement owner) => owner,
    VariableElement(isStatic: true, enclosingElement: final InstanceElement owner) => owner,
    _ => null,
  };

  DartType _namespaceType(DartType type) {
    var result = typeSystem.promoteToNonNull(type);
    while (result is InterfaceType && result.isDartAsyncFutureOr) {
      result = typeSystem.promoteToNonNull(result.typeArguments.single);
    }
    return result;
  }

  Expression _outermostSelector(Expression expression) {
    var current = expression;
    while (true) {
      final parent = current.parent;
      if (parent case PropertyAccess(target: final target) when identical(target, current)) {
        current = parent;
        continue;
      }
      if (parent case MethodInvocation(target: final target) when identical(target, current)) {
        current = parent;
        continue;
      }
      return current;
    }
  }

  DartType? _expectedType(Expression expression) {
    final parent = expression.parent;
    return _directExpectedType(expression, parent) ??
        _controlFlowExpectedType(expression, parent) ??
        _collectionExpectedType(expression, parent);
  }

  DartType? _directExpectedType(Expression expression, AstNode? parent) {
    if (parent is ParenthesizedExpression) return _expectedType(parent);
    if (parent is NamedArgument) {
      return _argumentExpectedType(parent, parent.correspondingParameter);
    }
    if (parent is ArgumentList) {
      return _argumentExpectedType(expression, expression.correspondingParameter);
    }
    if (parent is VariableDeclaration && identical(parent.initializer, expression)) {
      final list = parent.parent;
      return list is VariableDeclarationList ? list.type?.type : null;
    }
    if (parent is AssignmentExpression && identical(parent.rightHandSide, expression)) {
      return parent.writeType;
    }
    if (parent is ReturnStatement || parent is ExpressionFunctionBody) {
      return _returnContextType(parent!);
    }
    return null;
  }

  DartType? _controlFlowExpectedType(Expression expression, AstNode? parent) {
    if (parent is ConditionalExpression) return _expectedType(parent);
    if (parent is BinaryExpression && identical(parent.rightOperand, expression)) {
      if (parent.operator.type == TokenType.EQ_EQ || parent.operator.type == TokenType.BANG_EQ) {
        return parent.leftOperand.staticType;
      }
      if (parent.operator.type == TokenType.QUESTION_QUESTION) return _expectedType(parent);
    }
    if (parent is SwitchExpressionCase) {
      final switchNode = parent.parent;
      if (switchNode is SwitchExpression) return _expectedType(switchNode);
    }
    if (parent is ConstantPattern) {
      return parent.matchedValueType;
    }
    if (parent is FormalParameterDefaultClause) {
      final parameter = parent.parent;
      return parameter is FormalParameter ? parameter.type?.type : null;
    }
    return null;
  }

  DartType? _collectionExpectedType(Expression expression, AstNode? parent) {
    if (parent is ListLiteral) return _listElementType(parent);
    if (parent is SetOrMapLiteral && parent.isSet) return _setElementType(parent);
    if (parent is MapLiteralEntry) return _mapEntryType(parent, expression);
    return null;
  }

  DartType? _returnContextType(AstNode node) {
    AstNode? current = node;
    FunctionBody? body;
    while (current != null) {
      if (current is FunctionBody) body ??= current;
      switch (current) {
        case FunctionExpression() when current.parent is! FunctionDeclaration:
          return null;
        case FunctionDeclaration(:final returnType):
          return _adjustReturnType(returnType?.type, body);
        case MethodDeclaration(:final returnType):
          return _adjustReturnType(returnType?.type, body);
      }
      current = current.parent;
    }
    return null;
  }

  DartType? _adjustReturnType(DartType? returnType, FunctionBody? body) {
    if (returnType == null || body == null || body.isGenerator) return null;
    return body.isAsynchronous ? typeSystem.flatten(returnType) : returnType;
  }

  DartType? _argumentExpectedType(AstNode argument, FormalParameterElement? parameter) {
    if (parameter == null) return null;
    final parent = argument.parent;
    final argumentList = parent is NamedArgument ? parent.parent : parent;
    if (argumentList is! ArgumentList) return null;

    final inferred = _inferredTypeParameters(argumentList.parent);
    if (inferred.isNotEmpty) {
      final dependencies = _TypeParameterCollector.collect(parameter.baseElement.type);
      if (dependencies.any(inferred.contains)) return null;
    }
    return parameter.type;
  }

  Set<TypeParameterElement> _inferredTypeParameters(AstNode? invocation) => switch (invocation) {
    MethodInvocation(typeArguments: null, methodName: SimpleIdentifier(:final element))
        when element is ExecutableElement =>
      element.baseElement.type.typeParameters.toSet(),
    FunctionExpressionInvocation(typeArguments: null, function: final function)
        when function.staticType is FunctionType =>
      (function.staticType! as FunctionType).typeParameters.toSet(),
    InstanceCreationExpression(
      constructorName: ConstructorName(type: NamedType(typeArguments: null), :final element),
    )
        when element != null =>
      element.enclosingElement.typeParameters.toSet(),
    _ => const {},
  };

  DartType? _listElementType(ListLiteral literal) {
    final explicit = literal.typeArguments?.arguments.firstOrNull?.type;
    if (explicit != null) return explicit;
    final contextType = _expectedType(literal);
    return contextType is InterfaceType && contextType.isDartCoreList
        ? contextType.typeArguments.firstOrNull
        : null;
  }

  DartType? _setElementType(SetOrMapLiteral literal) {
    final explicit = literal.typeArguments?.arguments.firstOrNull?.type;
    if (explicit != null) return explicit;
    final contextType = _expectedType(literal);
    return contextType is InterfaceType && contextType.isDartCoreSet
        ? contextType.typeArguments.firstOrNull
        : null;
  }

  DartType? _mapEntryType(MapLiteralEntry entry, Expression expression) {
    final literal = entry.parent;
    if (literal is! SetOrMapLiteral || !literal.isMap) return null;
    final arguments = literal.typeArguments?.arguments;
    DartType? keyType;
    DartType? valueType;
    if (arguments != null && arguments.length == 2) {
      keyType = arguments[0].type;
      valueType = arguments[1].type;
    } else {
      final contextType = _expectedType(literal);
      if (contextType is! InterfaceType || !contextType.isDartCoreMap) return null;
      keyType = contextType.typeArguments.firstOrNull;
      valueType = contextType.typeArguments.length == 2 ? contextType.typeArguments[1] : null;
    }
    return identical(entry.key, expression) ? keyType : valueType;
  }
}

final class _TypeParameterCollector extends UnifyingTypeVisitor<void> {
  final Set<TypeParameterElement> elements = {};

  static Set<TypeParameterElement> collect(DartType type) {
    final visitor = _TypeParameterCollector();
    type.accept(visitor);
    return visitor.elements;
  }

  @override
  void visitDartType(DartType type) {}

  @override
  void visitFunctionType(FunctionType type) {
    type.returnType.accept(this);
    for (final parameter in type.formalParameters) {
      parameter.type.accept(this);
    }
  }

  @override
  void visitInterfaceType(InterfaceType type) {
    for (final argument in type.typeArguments) {
      argument.accept(this);
    }
  }

  @override
  void visitRecordType(RecordType type) {
    for (final field in [...type.positionalFields, ...type.namedFields]) {
      field.type.accept(this);
    }
  }

  @override
  void visitTypeParameterType(TypeParameterType type) {
    elements.add(type.element);
  }
}
