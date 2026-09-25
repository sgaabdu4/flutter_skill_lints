import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/mounted_guard_utils.dart';

/// Warns when one async function updates the same value on both sides of an
/// await point.
final class RequireAtomicAsyncUpdates extends FunctionAndMethodDeclarationRule {
  static const LintCode code = LintCode(
    'require_atomic_async_updates',
    'Keep async updates atomic around await points.',
    correctionMessage: 'Compute the new value after the await, or split the loading/status update from the data update.',
    severity: DiagnosticSeverity.ERROR,
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

    final reported = <AstNode>{};
    _processBlock(body.block, _LinearState(), reported);
    for (final node in reported) {
      rule.reportAtNode(node);
    }
  }

  void _processBlock(Block block, _LinearState state, Set<AstNode> reported) {
    for (final statement in block.statements) {
      if (statement is! IfStatement || !_processReturningGuard(statement, state, reported)) {
        _processNode(statement, state, reported);
      }
      if (statement is ReturnStatement) break;
    }
  }

  void _processTerminalBranch(Statement statement, _LinearState state, Set<AstNode> reported) {
    if (statement is Block) {
      _processBlock(statement, state, reported);
      return;
    }
    if (statement is IfStatement && _processReturningGuard(statement, state, reported)) return;
    _processNode(statement, state, reported);
  }

  bool _processReturningGuard(IfStatement statement, _LinearState state, Set<AstNode> reported) {
    if (statement.elseStatement != null || !_alwaysReturns(statement.thenStatement)) return false;
    _processNode(statement.expression, state, reported);
    _processTerminalBranch(statement.thenStatement, state.copy(), reported);
    if (state.seenAwait && _disjunctionTerms(statement.expression).any(_isUnmountedRiverpodRef)) {
      state.hasMountedGuardAfterAwait = true;
    }
    return true;
  }

  void _processNode(AstNode node, _LinearState state, Set<AstNode> reported) {
    final containsAwait = _ContainsAwait.check(node);
    if (containsAwait) state.hasMountedGuardAfterAwait = false;
    final assignments = _AssignmentsCollector.collect(node);
    _recordAssignments(assignments, state, reported);
    if (containsAwait) state.seenAwait = true;
  }

  void _recordAssignments(
    List<_Assignment> assignments,
    _LinearState state,
    Set<AstNode> reported,
  ) {
    if (!state.seenAwait) {
      for (final assignment in assignments) {
        state.beforeAwait.putIfAbsent(assignment.key, () => []).add(assignment);
      }
      return;
    }
    for (final assignment in assignments) {
      // A notifier resumes with fresh `state` once `ref.mounted` is checked
      // (skill: async-mutations.md loadMore/save).
      if (state.hasMountedGuardAfterAwait && _isRiverpodNotifierState(assignment)) continue;
      if (state.beforeAwait.containsKey(assignment.key)) reported.add(assignment.node);
    }
  }

  bool _alwaysReturns(Statement statement) {
    if (statement is ReturnStatement) return true;
    if (statement is Block && statement.statements.isNotEmpty) {
      return statement.statements.last is ReturnStatement;
    }
    return false;
  }

  List<Expression> _disjunctionTerms(Expression expression) {
    final value = expression.unParenthesized;
    if (value is BinaryExpression && value.operator.lexeme == '||') {
      return [..._disjunctionTerms(value.leftOperand), ..._disjunctionTerms(value.rightOperand)];
    }
    return [value];
  }

  bool _isUnmountedRiverpodRef(Expression expression) {
    final value = expression.unParenthesized;
    if (value is! PrefixExpression || value.operator.lexeme != '!') return false;
    final mounted = value.operand.unParenthesized;
    return mounted is PrefixedIdentifier &&
            mounted.identifier.name == 'mounted' &&
            mounted.prefix.name == 'ref' &&
            isRiverpodRefAccess(mounted) ||
        mounted is PropertyAccess &&
            mounted.propertyName.name == 'mounted' &&
            mounted.target?.toSource() == 'ref' &&
            isRiverpodRefAccess(mounted);
  }

  bool _isRiverpodNotifierState(_Assignment assignment) {
    final element = assignment.targetElement;
    if (element is! PropertyAccessorElement) return false;
    final library = element.library.uri.toString();
    return library.startsWith('package:riverpod/') ||
        library.startsWith('package:flutter_riverpod/');
  }
}

final class _LinearState {
  _LinearState({
    this.seenAwait = false,
    this.hasMountedGuardAfterAwait = false,
    Map<String, List<_Assignment>>? beforeAwait,
  }) : beforeAwait = beforeAwait ?? <String, List<_Assignment>>{};

  bool seenAwait;
  bool hasMountedGuardAfterAwait;
  final Map<String, List<_Assignment>> beforeAwait;

  _LinearState copy() => _LinearState(
    seenAwait: seenAwait,
    hasMountedGuardAfterAwait: hasMountedGuardAfterAwait,
    beforeAwait: {
      for (final entry in beforeAwait.entries) entry.key: [...entry.value],
    },
  );
}

final class _Assignment {
  const _Assignment(this.key, this.node, this.targetElement);

  final String key;
  final AstNode node;
  final Element? targetElement;
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
      if (key != null) {
        _assignments.add(_Assignment(key, node.leftHandSide, node.writeElement));
      }
    }
    super.visitAssignmentExpression(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    final lexeme = node.operator.lexeme;
    if (lexeme == '++' || lexeme == '--') _record(node.operand, node.writeElement);
    super.visitPrefixExpression(node);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    final lexeme = node.operator.lexeme;
    if (lexeme == '++' || lexeme == '--') _record(node.operand, node.writeElement);
    super.visitPostfixExpression(node);
  }

  void _record(Expression expression, Element? targetElement) {
    final key = _targetKey(expression);
    if (key != null) _assignments.add(_Assignment(key, expression, targetElement));
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
