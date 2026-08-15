import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';

/// Warns when an `if` only chooses between opposite boolean literals.
class AvoidUnnecessaryIf extends IfStatementRule {
  static const LintCode code = LintCode(
    'avoid_unnecessary_if',
    'Avoid if statements that only choose between boolean literals.',
    correctionMessage: 'Use the condition or its negation directly.',
    severity: DiagnosticSeverity.ERROR,
  );

  AvoidUnnecessaryIf()
    : super(
        name: 'avoid_unnecessary_if',
        description: 'Warns when an if statement can be replaced with a boolean expression.',
        code: code,
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidUnnecessaryIf rule;

  @override
  void visitIfStatement(IfStatement node) {
    final elseStatement = node.elseStatement;
    if (elseStatement == null || elseStatement is IfStatement) return;

    if (_oppositeBooleanReturns(node.thenStatement, elseStatement) ||
        _oppositeBooleanAssignments(node.thenStatement, elseStatement)) {
      rule.reportAtNode(node);
    }
  }
}

bool _oppositeBooleanReturns(Statement thenStatement, Statement elseStatement) {
  final thenValue = _returnedBoolean(thenStatement);
  final elseValue = _returnedBoolean(elseStatement);
  return thenValue != null && elseValue != null && thenValue != elseValue;
}

bool? _returnedBoolean(Statement statement) {
  final unwrapped = _unwrapSingleStatementBlock(statement);
  return switch (unwrapped) {
    ReturnStatement(:final expression?) => _booleanLiteralValue(expression),
    _ => null,
  };
}

bool _oppositeBooleanAssignments(Statement thenStatement, Statement elseStatement) {
  final thenAssignment = _booleanAssignment(thenStatement);
  final elseAssignment = _booleanAssignment(elseStatement);
  return thenAssignment != null &&
      elseAssignment != null &&
      thenAssignment.variableSource == elseAssignment.variableSource &&
      thenAssignment.value != elseAssignment.value;
}

_BooleanAssignment? _booleanAssignment(Statement statement) {
  final unwrapped = _unwrapSingleStatementBlock(statement);
  if (unwrapped is! ExpressionStatement) return null;

  final expression = unwrapped.expression;
  if (expression is! AssignmentExpression) return null;
  if (expression.operator.type != TokenType.EQ) return null;

  final value = _booleanLiteralValue(expression.rightHandSide);
  if (value == null) return null;

  return _BooleanAssignment(_canonicalSource(expression.leftHandSide), value: value);
}

bool? _booleanLiteralValue(Expression expression) {
  final unwrapped = _unwrapParentheses(expression);
  return unwrapped is BooleanLiteral ? unwrapped.value : null;
}

Statement _unwrapSingleStatementBlock(Statement statement) {
  var current = statement;
  while (current is Block && current.statements.length == 1) {
    current = current.statements.single;
  }
  return current;
}

Expression _unwrapParentheses(Expression expression) {
  var current = expression;
  while (current is ParenthesizedExpression) {
    current = current.expression;
  }
  return current;
}

String _canonicalSource(AstNode node) {
  return node.toSource().replaceAll(RegExp(r'\s+'), ' ').trim();
}

final class _BooleanAssignment {
  const _BooleanAssignment(this.variableSource, {required this.value});

  final String variableSource;
  final bool value;
}
