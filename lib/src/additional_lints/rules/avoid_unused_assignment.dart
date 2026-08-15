import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/error.dart';

import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_unused_local_variable.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Reports local variables that are assigned again before their value is read.
final class AvoidUnusedAssignment extends BlockCheckRule {
  static const LintCode code = LintCode(
    'avoid_unused_assignment',
    'Local variable is assigned before the previous value is read.',
    correctionMessage: 'Remove the previous assignment or read the value before assigning again.',
    severity: DiagnosticSeverity.ERROR,
  );

  AvoidUnusedAssignment()
    : super(
        name: 'avoid_unused_assignment',
        description: 'Reports local variable assignments overwritten before being read.',
        code: code,
      );

  @override
  void checkBlock(Block node) {
    _BlockChecker(this).check(node);
  }
}

final class _BlockChecker {
  _BlockChecker(this.rule);

  final AvoidUnusedAssignment rule;
  final Map<Object, _VariableWriteState> _variables = {};

  void check(Block block) {
    forEachSimpleBlockStatement(
      block,
      onVariableDeclaration: _declare,
      onExpression: _scanExpression,
      onReturn: (expression) {
        if (expression != null) _recordReads(expression);
        _forgetUnreadValues();
      },
      onOther: _forgetUnreadValues,
    );
  }

  void _declare(VariableDeclarationList list) {
    for (final variable in list.variables) {
      final key = localVariableKey(variable);
      if (key == null) continue;
      _variables[key] = _VariableWriteState(hasUnreadValue: variable.initializer != null);
      final initializer = variable.initializer;
      if (initializer != null) _recordReads(initializer);
    }
  }

  void _scanExpression(Expression expression) {
    if (expression is AssignmentExpression && expression.operator.type == TokenType.EQ) {
      _recordReads(expression.rightHandSide);
      _recordWrite(expression.leftHandSide);
      return;
    }
    _recordReads(expression);
  }

  void _recordWrite(Expression target) {
    final key = _targetKey(target);
    if (key == null) return;
    final variable = _variables[key];
    if (variable == null) return;

    if (variable.hasUnreadValue) {
      rule.reportAtNode(_targetName(target) ?? target);
    }
    variable.hasUnreadValue = true;
  }

  void _recordReads(AstNode node) {
    node.accept(_ReadVisitor(_variables));
  }

  void _forgetUnreadValues() {
    for (final variable in _variables.values) {
      variable.hasUnreadValue = false;
    }
  }
}

final class _VariableWriteState {
  _VariableWriteState({required this.hasUnreadValue});

  bool hasUnreadValue;
}

final class _ReadVisitor extends GetterReadVisitor {
  const _ReadVisitor(this.variables);

  final Map<Object, _VariableWriteState> variables;

  @override
  void checkGetterRead(SimpleIdentifier node, Object key) {
    final variable = variables[key];
    if (variable != null) {
      variable.hasUnreadValue = false;
    }
  }
}

Object? _targetKey(Expression expression) {
  return switch (expression.unParenthesized) {
    SimpleIdentifier(:final element) => element,
    _ => null,
  };
}

AstNode? _targetName(Expression expression) {
  return switch (expression.unParenthesized) {
    SimpleIdentifier() => expression,
    _ => null,
  };
}
