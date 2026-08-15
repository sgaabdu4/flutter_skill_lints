import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/error.dart';

import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_unused_local_variable.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Reports local variables read before a local assignment is seen.
final class AvoidUnassignedLocalVariable extends BlockCheckRule {
  static const LintCode code = LintCode(
    'avoid_unassigned_local_variable',
    'Local variable is read before it is assigned.',
    correctionMessage: 'Assign the variable before reading it.',
  );

  AvoidUnassignedLocalVariable()
    : super(
        name: 'avoid_unassigned_local_variable',
        description: 'Reports local variable reads before assignment when safely detectable.',
        code: code,
      );

  @override
  void checkBlock(Block node) {
    _BlockChecker(this).check(node);
  }
}

final class _BlockChecker {
  _BlockChecker(this.rule);

  final AvoidUnassignedLocalVariable rule;
  final Map<Object, bool> _assigned = {};

  void check(Block block) {
    forEachSimpleBlockStatement(
      block,
      onVariableDeclaration: _declare,
      onExpression: _scanExpression,
      onReturn: (expression) {
        if (expression != null) _checkReads(expression);
        _forgetUnassignedValues();
      },
      onOther: _forgetUnassignedValues,
    );
  }

  void _declare(VariableDeclarationList list) {
    for (final variable in list.variables) {
      final initializer = variable.initializer;
      if (initializer != null) _checkReads(initializer);

      final key = localVariableKey(variable);
      if (key != null) {
        _assigned[key] = initializer != null;
      }
    }
  }

  void _scanExpression(Expression expression) {
    if (expression is AssignmentExpression && expression.operator.type == TokenType.EQ) {
      _checkReads(expression.rightHandSide);
      _recordWrite(expression.leftHandSide);
      return;
    }
    _checkReads(expression);
  }

  void _recordWrite(Expression target) {
    final key = _targetKey(target);
    if (key != null && _assigned.containsKey(key)) {
      _assigned[key] = true;
    }
  }

  void _checkReads(AstNode node) {
    node.accept(_ReadVisitor(rule, _assigned));
  }

  void _forgetUnassignedValues() {
    for (final key in _assigned.keys.toList()) {
      _assigned[key] = true;
    }
  }
}

final class _ReadVisitor extends GetterReadVisitor {
  const _ReadVisitor(this.rule, this.assigned);

  final AvoidUnassignedLocalVariable rule;
  final Map<Object, bool> assigned;

  @override
  void checkGetterRead(SimpleIdentifier node, Object key) {
    if (assigned[key] == false) {
      rule.reportAtNode(node);
    }
  }
}

Object? _targetKey(Expression expression) {
  return switch (expression.unParenthesized) {
    SimpleIdentifier(:final element) => element,
    _ => null,
  };
}
