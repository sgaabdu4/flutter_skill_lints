import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Don't read state or run immediate loading work in sync Notifier.build().
final class AvoidSyncNotifierStateRead extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_sync_notifier_state_read',
    "Don't read state or run immediate loading work in sync Notifier.build().",
    correctionMessage:
        'Return initial state from build(). Move the load into AsyncNotifier.build(), '
        'or start it from the event that causes it.',
    severity: DiagnosticSeverity.ERROR,
  );

  AvoidSyncNotifierStateRead()
    : super(
        name: 'avoid_sync_notifier_state_read',
        description:
            'Bans sync Notifier.build() state reads and immediate loading/listening traps.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (isGeneratedRuleContext(context)) return;
    registry.addMethodDeclaration(this, _Visitor(this));
  }
}

final class _Visitor extends RecursiveAstVisitor<void> {
  _Visitor(this.rule);

  final AvoidSyncNotifierStateRead rule;

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.name.lexeme != 'build' || node.body.isAsynchronous) return;
    final classNode = enclosingClass(node);
    if (classNode == null || !isNotifierClass(classNode)) return;
    node.body.accept(_BodyVisitor(rule, classNode));
  }
}

final _loadInitFetchPattern = RegExp(r'^_(?:load|init|fetch|listen|refresh|setup)[A-Za-z0-9_]*$');

final class _BodyVisitor extends RecursiveAstVisitor<void> {
  _BodyVisitor(this.rule, this.classNode);

  final AvoidSyncNotifierStateRead rule;
  final ClassDeclaration classNode;

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (_isNotifierStateRead(node)) rule.reportAtNode(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final name = node.methodName.name;
    if (_loadInitFetchPattern.hasMatch(name)) {
      rule.reportAtNode(node);
      return;
    }
    final helper = _ownHelper(classNode, node);
    if (helper != null && _helperReadsState(classNode, helper, {})) {
      rule.reportAtNode(node);
      return;
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitNamedArgument(NamedArgument node) {
    if (node.name.lexeme != 'fireImmediately') {
      super.visitNamedArgument(node);
      return;
    }
    final expression = node.argumentExpression;
    if (expression is BooleanLiteral && expression.value) {
      rule.reportAtNode(node);
    }
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _reportLoadTearOffs(node, node.argumentList);
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitDotShorthandConstructorInvocation(DotShorthandConstructorInvocation node) {
    _reportLoadTearOffs(node, node.argumentList);
    super.visitDotShorthandConstructorInvocation(node);
  }

  void _reportLoadTearOffs(AstNode call, ArgumentList arguments) {
    if (!_isMicrotaskCall(call)) return;
    for (final argument in arguments.arguments) {
      if (argument is SimpleIdentifier && _loadInitFetchPattern.hasMatch(argument.name)) {
        rule.reportAtNode(argument);
      }
    }
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    if (_isMicrotaskCall(node.parent?.parent) || _isCompletionOfMicrotask(node)) {
      super.visitFunctionExpression(node);
    }
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}
}

bool _isNotifierStateRead(SimpleIdentifier node) {
  if (node.name != 'state') return false;
  final parent = node.parent;
  if (parent is PropertyAccess &&
      parent.propertyName == node &&
      parent.realTarget is! ThisExpression &&
      parent.realTarget is! SuperExpression) {
    return false;
  }
  if (parent is PrefixedIdentifier && parent.identifier == node) return false;
  final access = parent is PropertyAccess && parent.propertyName == node ? parent : node;
  final element = _readElement(access, node.element);
  return element is PropertyAccessorElement && element.enclosingElement is InterfaceElement;
}

Element? _readElement(Expression access, Element? element) => switch (access.parent) {
  AssignmentExpression(:final leftHandSide, :final operator, :final readElement)
      when leftHandSide == access =>
    operator.type == TokenType.EQ ? null : readElement,
  PostfixExpression(:final operand, :final readElement) when operand == access =>
    readElement ?? element,
  PrefixExpression(:final operand, :final readElement) when operand == access =>
    readElement ?? element,
  _ => element,
};

bool _isMicrotaskCall(AstNode? call) {
  final element = switch (call) {
    InstanceCreationExpression(:final constructorName) => constructorName.element,
    DotShorthandConstructorInvocation(:final element) => element,
    _ => null,
  };
  return element != null &&
      element.name == 'microtask' &&
      element.library.identifier == 'dart:async';
}

const _completionMethods = {'then', 'catchError', 'whenComplete'};

bool _isCompletionOfMicrotask(FunctionExpression node) {
  final call = node.parent?.parent;
  return call is MethodInvocation && _isCompletionChainOfMicrotask(call);
}

bool _isCompletionChainOfMicrotask(MethodInvocation call) {
  if (!_completionMethods.contains(call.methodName.name)) return false;
  var target = call.realTarget;
  while (target is ParenthesizedExpression) {
    target = target.expression;
  }
  return _isMicrotaskCall(target) ||
      (target is MethodInvocation && _isCompletionChainOfMicrotask(target));
}

/// A same-class method invoked on the notifier itself.
MethodDeclaration? _ownHelper(ClassDeclaration classNode, MethodInvocation node) {
  final target = node.target;
  if (target != null && target is! ThisExpression) return null;
  final element = node.methodName.element;
  if (element is! MethodElement) return null;
  final body = classBodyOf(classNode);
  if (body == null) return null;
  for (final member in body.members) {
    if (member is MethodDeclaration && member.declaredFragment?.element == element) return member;
  }
  return null;
}

/// Whether [helper] reads `state` before its first await, directly or via another helper.
bool _helperReadsState(
  ClassDeclaration classNode,
  MethodDeclaration helper,
  Set<MethodDeclaration> seen,
) {
  if (!seen.add(helper)) return false;
  final finder = _SyncStateReadFinder(classNode, seen);
  helper.body.accept(finder);
  return finder.found;
}

final class _SyncStateReadFinder extends RecursiveAstVisitor<void> {
  _SyncStateReadFinder(this.classNode, this.seen);

  final ClassDeclaration classNode;
  final Set<MethodDeclaration> seen;
  bool found = false;
  bool _pastAwait = false;

  bool get _done => found || _pastAwait;

  @override
  void visitAwaitExpression(AwaitExpression node) {
    if (_done) return;
    super.visitAwaitExpression(node);
    _pastAwait = true;
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (!_done && _isNotifierStateRead(node)) found = true;
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_done) return;
    final helper = _ownHelper(classNode, node);
    if (helper != null && _helperReadsState(classNode, helper, seen)) {
      found = true;
      return;
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}
}
