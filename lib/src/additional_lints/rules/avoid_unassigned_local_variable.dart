import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'avoid_unused_local_variable.dart';

/// Reports local variables read before a local assignment is seen.
final class AvoidUnassignedLocalVariable extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_unassigned_local_variable',
    'Local variable is read before it is assigned.',
    correctionMessage: 'Assign the variable before reading it.',
    severity: DiagnosticSeverity.INFO,
  );

  AvoidUnassignedLocalVariable()
    : super(
        name: 'avoid_unassigned_local_variable',
        description: 'Reports local variable reads before assignment when safely detectable.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addBlock(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidUnassignedLocalVariable rule;

  @override
  void visitBlock(Block node) {
    _BlockChecker(rule).check(node);
  }
}

final class _BlockChecker {
  _BlockChecker(this.rule);

  final AvoidUnassignedLocalVariable rule;
  final Map<Object, bool> _assigned = {};

  void check(Block block) {
    for (final statement in block.statements) {
      if (statement is VariableDeclarationStatement) {
        _declare(statement.variables);
        continue;
      }
      if (statement is ExpressionStatement) {
        _scanExpression(statement.expression);
        continue;
      }
      if (statement is ReturnStatement) {
        final expression = statement.expression;
        if (expression != null) _checkReads(expression);
        _forgetUnassignedValues();
        continue;
      }
      _forgetUnassignedValues();
    }
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

final class _ReadVisitor extends RecursiveAstVisitor<void> {
  const _ReadVisitor(this.rule, this.assigned);

  final AvoidUnassignedLocalVariable rule;
  final Map<Object, bool> assigned;

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (!node.inGetterContext()) return;
    final key = node.element;
    if (key != null && assigned[key] == false) {
      rule.reportAtNode(node);
    }
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}
}

Object? _targetKey(Expression expression) {
  return switch (expression.unParenthesized) {
    SimpleIdentifier(:final element) => element,
    _ => null,
  };
}
