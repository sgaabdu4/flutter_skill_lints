import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';
import 'package:flutter_skill_lints/src/mounted_guard_utils.dart';

/// Warns when one async function updates the same value on both sides of an
/// await point.
final class RequireAtomicAsyncUpdates extends FunctionAndMethodDeclarationRule {
  static const LintCode code = LintCode(
    'require_atomic_async_updates',
    'Keep async updates atomic around await points.',
    correctionMessage: 'Compute the new value after the await, or split the loading/status update from the data update.',
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
    _processBlock(body.block, _LinearState(owner: _enclosingClass(body.parent)), reported);
    for (final node in reported) {
      rule.reportAtNode(node);
    }
  }

  ClassElement? _enclosingClass(AstNode? node) {
    final declaration = switch (node) {
      MethodDeclaration(:final declaredFragment) => declaredFragment?.element,
      FunctionDeclaration(:final declaredFragment) => declaredFragment?.element,
      _ => null,
    };
    final owner = declaration?.enclosingElement;
    return owner is ClassElement ? owner : null;
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
    if (state.seenAwait && _isReturningInvalidRequestGuard(statement, state)) {
      state.hasMountedRevisionGuardAfterAwait = true;
    }
    return true;
  }

  void _processNode(AstNode node, _LinearState state, Set<AstNode> reported) {
    final containsAwait = _ContainsAwait.check(node);
    if (containsAwait) state.hasMountedRevisionGuardAfterAwait = false;
    final assignments = _AssignmentsCollector.collect(node);
    _captureRevisionsBeforeAwait(node, state);
    _recordAssignments(assignments, state, reported);
    _advanceAwaitState(containsAwait, assignments, state);
  }

  void _captureRevisionsBeforeAwait(AstNode node, _LinearState state) {
    if (state.seenAwait) return;
    for (final capture in _RevisionCaptures.collect(node, state.owner)) {
      state.revisionTokens[capture.token] = capture.revision;
    }
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
      final earlier = state.beforeAwait[assignment.key];
      if (earlier != null &&
          earlier.any(
            (previous) => !_isGuardedLoadingResultTransition(previous, assignment, state),
          )) {
        reported.add(assignment.node);
      }
    }
  }

  void _advanceAwaitState(bool containsAwait, List<_Assignment> assignments, _LinearState state) {
    if (containsAwait) state.seenAwait = true;
    if (state.seenAwait && assignments.any((assignment) => assignment.key == 'state')) {
      state.hasMountedRevisionGuardAfterAwait = false;
    }
  }

  bool _isGuardedLoadingResultTransition(
    _Assignment previous,
    _Assignment current,
    _LinearState state,
  ) {
    if (!state.hasMountedRevisionGuardAfterAwait ||
        previous.key != 'state' ||
        current.key != 'state' ||
        !_isRiverpodNotifierState(previous) ||
        !_isRiverpodNotifierState(current)) {
      return false;
    }
    final previousArguments = previous.copyWithArguments;
    final currentArguments = current.copyWithArguments;
    if (previousArguments == null || currentArguments == null) return false;
    final wasLoading = previousArguments['loading'];
    final isLoading = currentArguments['loading'];
    if (wasLoading is BooleanLiteral &&
        wasLoading.value &&
        isLoading is BooleanLiteral &&
        !isLoading.value) {
      final previousDataFields = previousArguments.keys.where((name) => name != 'loading').toSet();
      final currentDataFields = currentArguments.keys.where((name) => name != 'loading').toSet();
      return currentDataFields.isNotEmpty &&
          previousDataFields.intersection(currentDataFields).isEmpty;
    }
    return false;
  }

  bool _isReturningInvalidRequestGuard(IfStatement statement, _LinearState state) {
    if (!_alwaysReturns(statement.thenStatement)) return false;
    final terms = _disjunctionTerms(statement.expression);
    final mounted = terms.any(_isUnmountedRiverpodRef);
    final revision = terms.any((term) => _isRevisionMismatch(term, state));
    return mounted && revision;
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

  bool _isRevisionMismatch(Expression expression, _LinearState state) {
    final value = expression.unParenthesized;
    if (value is! BinaryExpression || value.operator.lexeme != '!=') return false;
    final left = value.leftOperand.unParenthesized;
    final right = value.rightOperand.unParenthesized;
    if (left is! SimpleIdentifier || right is! SimpleIdentifier) return false;
    final leftElement = left.element;
    final rightElement = right.element;
    if (leftElement == null || rightElement == null) return false;
    final leftOwner = _normalizeElement(leftElement);
    final rightOwner = _normalizeElement(rightElement);
    return state.revisionTokens[leftOwner] == rightOwner ||
        state.revisionTokens[rightOwner] == leftOwner;
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
    this.owner,
    this.seenAwait = false,
    this.hasMountedRevisionGuardAfterAwait = false,
    Map<String, List<_Assignment>>? beforeAwait,
    Map<Element, Element>? revisionTokens,
  }) : beforeAwait = beforeAwait ?? <String, List<_Assignment>>{},
       revisionTokens = revisionTokens ?? <Element, Element>{};

  bool seenAwait;
  bool hasMountedRevisionGuardAfterAwait;
  final ClassElement? owner;
  final Map<String, List<_Assignment>> beforeAwait;
  final Map<Element, Element> revisionTokens;

  _LinearState copy() => _LinearState(
    owner: owner,
    seenAwait: seenAwait,
    hasMountedRevisionGuardAfterAwait: hasMountedRevisionGuardAfterAwait,
    beforeAwait: {
      for (final entry in beforeAwait.entries) entry.key: [...entry.value],
    },
    revisionTokens: {...revisionTokens},
  );
}

final class _RevisionCapture {
  const _RevisionCapture(this.token, this.revision);

  final Element token;
  final Element revision;
}

final class _RevisionCaptures extends RecursiveAstVisitor<void> {
  final captures = <_RevisionCapture>[];

  _RevisionCaptures(this.owner);

  final ClassElement? owner;

  static List<_RevisionCapture> collect(AstNode node, ClassElement? owner) {
    if (node is! VariableDeclarationStatement) return const [];
    final visitor = _RevisionCaptures(owner);
    node.accept(visitor);
    return visitor.captures;
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    final token = node.declaredFragment?.element;
    final initializer = node.initializer?.unParenthesized;
    final revision = switch (initializer) {
      PrefixExpression(:final operator, :final writeElement) when operator.lexeme == '++' =>
        writeElement,
      _ => null,
    };
    final normalizedRevision = revision == null ? null : _normalizeElement(revision);
    if (token is LocalVariableElement &&
        token.isFinal &&
        !token.isLate &&
        normalizedRevision is FieldElement &&
        !normalizedRevision.isStatic &&
        !normalizedRevision.isLate &&
        normalizedRevision.type.isDartCoreInt &&
        _belongsToOwner(normalizedRevision)) {
      captures.add(_RevisionCapture(token, normalizedRevision));
    }
    super.visitVariableDeclaration(node);
  }

  bool _belongsToOwner(FieldElement revision) {
    final currentOwner = owner;
    if (currentOwner == null) return false;
    final revisionOwner = revision.enclosingElement;
    return revisionOwner == currentOwner ||
        currentOwner.allSupertypes.any((type) => type.element == revisionOwner);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}
}

final class _Assignment {
  const _Assignment(this.key, this.node, this.copyWithArguments, this.targetElement);

  final String key;
  final AstNode node;
  final Map<String, Expression>? copyWithArguments;
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
        _assignments.add(
          _Assignment(key, node.leftHandSide, _copyWithArguments(node), node.writeElement),
        );
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
    if (key != null) _assignments.add(_Assignment(key, expression, null, targetElement));
  }

  Map<String, Expression>? _copyWithArguments(AssignmentExpression assignment) {
    final left = assignment.leftHandSide.unParenthesized;
    final right = assignment.rightHandSide.unParenthesized;
    if (right is MethodInvocation &&
        right.methodName.name == 'copyWith' &&
        right.target?.unParenthesized.toSource() == left.toSource()) {
      return {
        for (final argument in right.argumentList.arguments.whereType<NamedArgument>())
          argument.name.lexeme: argument.argumentExpression,
      };
    }
    if (right is! FunctionExpressionInvocation || right.function is! PropertyAccess) return null;
    final access = right.function as PropertyAccess;
    final target = access.target;
    final getter = access.propertyName.element;
    if (access.propertyName.name != 'copyWith' ||
        target?.unParenthesized.toSource() != left.toSource() ||
        getter is! GetterElement ||
        !getter.firstFragment.libraryFragment.source.fullName.endsWith('.freezed.dart') ||
        target?.staticType == null ||
        right.staticType != target?.staticType ||
        target?.staticType is! InterfaceType ||
        !isFreezedInterfaceType(target!.staticType as InterfaceType)) {
      return null;
    }
    return {
      for (final argument in right.argumentList.arguments.whereType<NamedArgument>())
        argument.name.lexeme: argument.argumentExpression,
    };
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

Element _normalizeElement(Element element) =>
    element is PropertyAccessorElement ? element.variable : element;
