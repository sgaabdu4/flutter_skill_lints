import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';

/// Reports `Iterable.reduce` calls that can throw on empty iterables.
class AvoidUnsafeReduce extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_unsafe_reduce',
    'Calling reduce() without proving the iterable is non-empty can throw.',
    correctionMessage: 'Check isNotEmpty first or use fold() with an initial value.',
  );

  AvoidUnsafeReduce()
    : super(
        name: 'avoid_unsafe_reduce',
        description: 'Reports reduce() calls on iterables that may be empty.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addMethodInvocation(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidUnsafeReduce rule;

  _Visitor(this.rule);

  static const _iterableChecker = TypeChecker.fromUrl('dart:core#Iterable');

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'reduce') return;

    final target = node.realTarget;
    if (target == null) return;
    if (!_isIterable(target)) return;
    if (hasNonEmptyProof(node, target)) return;

    rule.reportAtNode(node);
  }

  static bool _isIterable(Expression expression) {
    final type = expression.staticType;
    return type != null && _iterableChecker.isAssignableFromType(type);
  }
}

bool hasNonEmptyProof(AstNode use, Expression target) {
  if (_isEmptyCollectionLiteral(target)) return false;

  final targetSource = _stableTargetSource(target);
  if (targetSource == null) return false;

  for (AstNode? current = use; current != null; current = current.parent) {
    if (_ancestorProvesNonEmpty(current, targetSource)) return true;
    if (current is FunctionBody) return false;
  }

  return false;
}

bool _ancestorProvesNonEmpty(AstNode current, String targetSource) {
  final parent = current.parent;
  if (parent is IfStatement && parent.thenStatement == current) {
    return _conditionProvesNonEmpty(parent.expression, targetSource);
  }
  if (parent is! Block) return false;
  final statement = current is Statement ? current : current.thisOrAncestorOfType<Statement>();
  return statement != null &&
      _previousStatementsProveNonEmpty(parent.statements, statement, targetSource);
}

bool _previousStatementsProveNonEmpty(
  NodeList<Statement> statements,
  Statement currentStatement,
  String targetSource,
) {
  for (final statement in statements) {
    if (statement == currentStatement) return false;
    if (_isEmptyGuardExit(statement, targetSource)) return true;
  }

  return false;
}

bool _isEmptyGuardExit(Statement statement, String targetSource) {
  if (statement case IfStatement(
    expression: final condition,
    thenStatement: final thenStatement,
    elseStatement: null,
  )) {
    return _conditionChecksEmpty(condition, targetSource) && _alwaysExits(thenStatement);
  }

  return false;
}

bool _conditionProvesNonEmpty(Expression condition, String targetSource) {
  final expression = _unwrap(condition);

  if (_conditionChecksNotEmpty(expression, targetSource)) return true;

  if (expression case BinaryExpression(
    leftOperand: final left,
    operator: final operator,
    rightOperand: final right,
  ) when operator.lexeme == '&&') {
    return _conditionProvesNonEmpty(left, targetSource) ||
        _conditionProvesNonEmpty(right, targetSource);
  }

  return false;
}

bool _conditionChecksEmpty(Expression condition, String targetSource) {
  final expression = _unwrap(condition);

  if (_matchesProperty(expression, targetSource, 'isEmpty')) return true;

  if (expression case PrefixExpression(
    operator: final operator,
    operand: final operand,
  ) when operator.lexeme == '!') {
    return _conditionChecksNotEmpty(operand, targetSource);
  }

  return false;
}

bool _conditionChecksNotEmpty(Expression condition, String targetSource) {
  final expression = _unwrap(condition);

  if (_matchesProperty(expression, targetSource, 'isNotEmpty')) return true;

  if (expression case PrefixExpression(
    operator: final operator,
    operand: final operand,
  ) when operator.lexeme == '!') {
    return _conditionChecksEmpty(operand, targetSource);
  }

  return false;
}

bool _matchesProperty(Expression expression, String targetSource, String propertyName) {
  return switch (_unwrap(expression)) {
    PrefixedIdentifier(prefix: final prefix, identifier: SimpleIdentifier(name: final name))
        when name == propertyName && _stableTargetSource(prefix) == targetSource =>
      true,
    PropertyAccess(target: final target?, propertyName: SimpleIdentifier(name: final name))
        when name == propertyName && _stableTargetSource(target) == targetSource =>
      true,
    _ => false,
  };
}

bool _alwaysExits(Statement statement) {
  final body = statement is Block ? statement.statements : [statement];
  return body.any(
    (statement) =>
        statement is ReturnStatement ||
        statement is ExpressionStatement && statement.expression is ThrowExpression,
  );
}

String? _stableTargetSource(Expression expression) {
  final target = _unwrap(expression);

  return switch (target) {
    SimpleIdentifier() => target.name,
    PrefixedIdentifier() => target.toSource(),
    PropertyAccess(target: _?) => target.toSource(),
    _ => null,
  };
}

Expression _unwrap(Expression expression) {
  var current = expression;
  while (current is ParenthesizedExpression) {
    current = current.expression;
  }
  return current;
}

bool _isEmptyCollectionLiteral(Expression expression) {
  final target = _unwrap(expression);
  return switch (target) {
    ListLiteral(elements: final elements) when elements.isEmpty => true,
    SetOrMapLiteral(elements: final elements) when elements.isEmpty => true,
    _ => false,
  };
}
