import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';
import 'package:flutter_skill_lints/src/rules/provider_turn_hop_visitor.dart';

/// Don't read state or run immediate loading work in sync Notifier.build().
final class AvoidSyncNotifierStateRead extends MultiAnalysisRule {
  static const LintCode code = LintCode(
    'avoid_sync_notifier_state_read',
    "Don't read state or run immediate loading work in sync Notifier.build().",
    correctionMessage:
        'Return initial state from build(). Move the load into AsyncNotifier.build(), '
        'or start it from the event that causes it.',
    severity: DiagnosticSeverity.ERROR,
  );

  static const LintCode providerCode = LintCode(
    'avoid_provider_turn_hop',
    "Don't hop a zero-delay turn in a provider body.",
    correctionMessage:
        'Return the value from the provider. Start the work from the event that causes it, '
        'or move it into a Notifier or AsyncNotifier whose build() returns initial state.',
    severity: DiagnosticSeverity.ERROR,
  );

  AvoidSyncNotifierStateRead()
    : super(
        name: 'avoid_sync_notifier_state_read',
        description:
            'Bans sync Notifier.build() state reads and immediate loading/listening traps.',
      );

  @override
  List<DiagnosticCode> get diagnosticCodes => [code, providerCode];

  void reportBuild(AstNode node) => reportAtNode(node, diagnosticCode: code);

  void reportProvider(AstNode node) => reportAtNode(node, diagnosticCode: providerCode);

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (isGeneratedRuleContext(context)) return;
    registry.addArgumentList(this, _Visitor(this));
    registry.addMethodDeclaration(this, _Visitor(this));
    registry.addFunctionDeclaration(this, _Visitor(this));
    registry.addFunctionExpression(this, _Visitor(this));
  }
}

final class _Visitor extends RecursiveAstVisitor<void> {
  _Visitor(this.rule);

  final AvoidSyncNotifierStateRead rule;

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (hasRiverpodCodegenAnnotation(node)) {
      final body = node.functionExpression.body;
      body.accept(ProviderTurnHopVisitor(rule.reportProvider, body));
    }
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    final parameters = node.parameters?.parameters;
    if (node.parent is! ArgumentList || parameters == null || parameters.isEmpty) return;
    final type = parameters.first.declaredFragment?.element.type;
    if (type != null && _riverpodRefChecker.isAssignableFromType(type)) {
      node.body.accept(ProviderTurnHopVisitor(rule.reportProvider, node.body));
    }
  }

  @override
  void visitArgumentList(ArgumentList node) {
    if (!_createsProvider(node.parent)) return;
    for (final argument in node.arguments) {
      final expression = argument.argumentExpression;
      final element = switch (expression) {
        SimpleIdentifier() => expression.element,
        PrefixedIdentifier() => expression.identifier.element,
        _ => null,
      };
      final declaration = element is TopLevelFunctionElement
          ? topLevelFunctionOf(node, element)
          : null;
      final parameters = declaration?.functionExpression.parameters?.parameters;
      final type = parameters == null || parameters.isEmpty
          ? null
          : parameters.first.declaredFragment?.element.type;
      if (declaration != null && type != null && _riverpodRefChecker.isAssignableFromType(type)) {
        final body = declaration.functionExpression.body;
        body.accept(ProviderTurnHopVisitor(rule.reportProvider, body));
      }
    }
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.name.lexeme != 'build') return;
    final classNode = enclosingClass(node);
    if (classNode == null) return;
    if (_isResolvedNotifier(classNode)) {
      node.body.accept(ProviderTurnHopVisitor(rule.reportProvider, node.body));
    }
    if (node.body.isAsynchronous || !isNotifierClass(classNode)) return;
    node.body.accept(_BodyVisitor(rule, classNode));
  }
}

bool _createsProvider(AstNode? call) {
  final type = call is Expression ? call.staticType : null;
  final uri = type is InterfaceType ? type.element.library.uri.toString() : '';
  return const [
    'package:riverpod/',
    'package:flutter_riverpod/',
    'package:hooks_riverpod/',
  ].any(uri.startsWith);
}

bool _isResolvedNotifier(ClassDeclaration node) {
  final element = node.declaredFragment?.element;
  return hasRiverpodCodegenAnnotation(node) ||
      (element != null && _riverpodNotifierChecker.isSuperOf(element));
}

const _riverpodNotifierChecker = TypeChecker.any([
  TypeChecker.fromName('AnyNotifier', packageName: 'riverpod'),
  TypeChecker.fromName('Notifier', packageName: 'riverpod'),
  TypeChecker.fromName('AsyncNotifier', packageName: 'riverpod'),
  TypeChecker.fromName('StreamNotifier', packageName: 'riverpod'),
]);

final _loadInitFetchPattern = RegExp(r'^_(?:load|init|fetch|listen|refresh|setup)[A-Za-z0-9_]*$');

const _riverpodRefChecker = TypeChecker.fromName('Ref', packageName: 'riverpod');

abstract base class _HopVisitor extends RecursiveAstVisitor<void> {
  _HopVisitor(this.rule, this.loadPattern);

  final AvoidSyncNotifierStateRead rule;
  final RegExp loadPattern;
  bool inHop = false;

  void reportCompletionTearOffs(MethodInvocation node) {
    if (_isCompletionChainOfMicrotask(node)) _reportLoadTearOffs(node.argumentList);
  }

  void _reportLoadTearOffs(ArgumentList arguments) {
    for (final argument in arguments.arguments) {
      final expression = argument.argumentExpression;
      final name = switch (expression) {
        SimpleIdentifier() => expression.name,
        PrefixedIdentifier() => expression.identifier.name,
        _ => null,
      };
      if (name != null && loadPattern.hasMatch(name)) rule.reportBuild(expression);
    }
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (_isMicrotaskCall(node)) _reportLoadTearOffs(node.argumentList);
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitDotShorthandConstructorInvocation(DotShorthandConstructorInvocation node) {
    if (_isMicrotaskCall(node)) _reportLoadTearOffs(node.argumentList);
    super.visitDotShorthandConstructorInvocation(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    if (!_isMicrotaskCall(node.parent?.parent) && !_isCompletionOfMicrotask(node)) return;
    final wasInHop = inHop;
    inHop = true;
    super.visitFunctionExpression(node);
    inHop = wasInHop;
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}
}

final class _BodyVisitor extends _HopVisitor {
  _BodyVisitor(AvoidSyncNotifierStateRead rule, this.classNode)
    : super(rule, _loadInitFetchPattern);

  final ClassDeclaration classNode;

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (_isNotifierStateRead(node)) rule.reportBuild(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    reportCompletionTearOffs(node);
    if (loadPattern.hasMatch(node.methodName.name)) {
      rule.reportBuild(node);
      return;
    }
    final helper = _ownHelper(classNode, node);
    if (helper != null && _helperReadsState(classNode, helper, {})) {
      rule.reportBuild(node);
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
      rule.reportBuild(node);
    }
  }
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
  final parent = node.parent;
  final call = (parent is NamedArgument ? parent.parent : parent)?.parent;
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
