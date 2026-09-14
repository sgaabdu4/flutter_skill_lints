import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/error/error.dart';

/// Prefers Dart's dot shorthand whenever an existing context supplies the type.
final class PreferDotShorthands extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_dot_shorthands',
    'Use dot shorthand when the surrounding context already supplies the type.',
    correctionMessage: 'Remove the repeated type name.',
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
    final candidate = _candidate(expression);
    if (candidate == null) return;

    final expressionType = expression.staticType;
    if (expressionType == null || !typeSystem.isSubtypeOf(expressionType, candidate.type)) {
      return;
    }

    final contextExpression = _outermostSelector(expression);
    final expectedType = _expectedType(contextExpression);
    if (expectedType == null) return;

    final nonNullExpected = typeSystem.promoteToNonNull(expectedType);
    final sameNamespace =
        typeSystem.isSubtypeOf(candidate.type, nonNullExpected) &&
        typeSystem.isSubtypeOf(nonNullExpected, candidate.type);
    if (!sameNamespace) return;

    rule.reportAtNode(expression);
  }

  ({AstNode prefix, DartType type})? _candidate(Expression expression) {
    if (expression is PrefixedIdentifier) {
      final prefix = expression.prefix;
      final element = prefix.element;
      final type = element is InstanceElement ? element.thisType : null;
      if (type != null) {
        return (prefix: prefix, type: type);
      }
    }
    if (expression case PropertyAccess(:final target)) {
      final element = _interfaceElement(target);
      final type = element?.thisType;
      if (target != null && type != null) {
        return (prefix: target, type: type);
      }
    }
    if (expression case MethodInvocation(:final target)) {
      final element = _interfaceElement(target);
      final type = element?.thisType;
      if (target != null && type != null) {
        return (prefix: target, type: type);
      }
    }
    if (expression
        case InstanceCreationExpression(
          constructorName: ConstructorName(:final type),
          :final staticType,
        )
        when staticType != null) {
      return (prefix: type, type: staticType);
    }
    return null;
  }

  InstanceElement? _interfaceElement(Expression? expression) => switch (expression) {
    SimpleIdentifier(element: final InstanceElement element) => element,
    PrefixedIdentifier(identifier: SimpleIdentifier(element: final InstanceElement element)) =>
      element,
    _ => null,
  };

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
    if (parent is NamedArgument) return parent.correspondingParameter?.type;
    if (parent is ArgumentList) {
      return expression.correspondingParameter?.type;
    }
    if (parent is VariableDeclaration && identical(parent.initializer, expression)) {
      final list = parent.parent;
      return list is VariableDeclarationList ? list.type?.type : null;
    }
    if (parent is AssignmentExpression && identical(parent.rightHandSide, expression)) {
      return parent.writeType;
    }
    if (parent is ReturnStatement || parent is ExpressionFunctionBody) {
      return _declaredReturnType(parent!);
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

  DartType? _declaredReturnType(AstNode node) {
    AstNode? current = node.parent;
    while (current != null) {
      switch (current) {
        case FunctionExpression(parent: final FunctionDeclaration declaration):
          return declaration.returnType?.type;
        case FunctionExpression():
          return null;
        case MethodDeclaration(:final returnType):
          return returnType?.type;
      }
      current = current.parent;
    }
    return null;
  }

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
