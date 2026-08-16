import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';

/// Warns when one async function updates the same value on both sides of an
/// await point.
final class RequireAtomicAsyncUpdates extends FunctionAndMethodDeclarationRule {
  static const LintCode code = LintCode(
    'require_atomic_async_updates',
    'Keep async updates atomic around await points.',
    correctionMessage:
        'Compute the new value after the await, or split the loading/status update from the data update.',
  );

  RequireAtomicAsyncUpdates()
    : super(
        name: 'require_atomic_async_updates',
        description: 'Warns when the same variable or field is assigned before and after an await.',
        code: code,
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final RequireAtomicAsyncUpdates rule;

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    final body = node.functionExpression.body;
    if (body.isAsynchronous) _checkBody(body);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.body.isAsynchronous) _checkBody(node.body);
  }

  void _checkBody(FunctionBody body) {
    if (body is! BlockFunctionBody) return;

    final beforeAwait = <String>{};
    var seenAwait = false;

    for (final statement in body.block.statements) {
      final assignments = _AssignmentsCollector.collect(statement);
      if (seenAwait) {
        for (final assignment in assignments) {
          if (beforeAwait.contains(assignment.key)) {
            rule.reportAtNode(assignment.node);
          }
        }
      } else {
        beforeAwait.addAll(assignments.map((assignment) => assignment.key));
      }

      if (_ContainsAwait.check(statement)) {
        seenAwait = true;
      }
    }
  }
}

final class _Assignment {
  const _Assignment(this.key, this.node);

  final String key;
  final AstNode node;
}

final class _AssignmentsCollector extends RecursiveAstVisitor<void> {
  final _assignments = <_Assignment>[];

  static List<_Assignment> collect(AstNode node) {
    final collector = _AssignmentsCollector();
    node.accept(collector);
    return collector._assignments;
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    if (node.operator.lexeme == '=') {
      final key = _targetKey(node.leftHandSide);
      if (key != null) _assignments.add(_Assignment(key, node.leftHandSide));
    }
    super.visitAssignmentExpression(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    final lexeme = node.operator.lexeme;
    if (lexeme == '++' || lexeme == '--') _record(node.operand);
    super.visitPrefixExpression(node);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    final lexeme = node.operator.lexeme;
    if (lexeme == '++' || lexeme == '--') _record(node.operand);
    super.visitPostfixExpression(node);
  }

  void _record(Expression expression) {
    final key = _targetKey(expression);
    if (key != null) _assignments.add(_Assignment(key, expression));
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}
}

final class _ContainsAwait extends RecursiveAstVisitor<void> {
  bool found = false;

  static bool check(AstNode node) {
    final visitor = _ContainsAwait();
    node.accept(visitor);
    return visitor.found;
  }

  @override
  void visitAwaitExpression(AwaitExpression node) {
    found = true;
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}
}

String? _targetKey(Expression expression) {
  return switch (expression.unParenthesized) {
    SimpleIdentifier(:final name) => name,
    PrefixedIdentifier(:final prefix, :final identifier) => '${prefix.name}.${identifier.name}',
    PropertyAccess(:final target?, :final propertyName) =>
      '${target.toSource()}.${propertyName.name}',
    _ => null,
  };
}
