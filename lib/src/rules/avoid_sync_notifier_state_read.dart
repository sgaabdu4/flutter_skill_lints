import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Don't read state or run immediate loading work in sync Notifier.build().
///
/// Why: Bans sync Notifier.build() state reads and immediate loading/listening traps. Return
/// initial state from build() and defer loading with Future.microtask.
final class AvoidSyncNotifierStateRead extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_sync_notifier_state_read',
    "Don't read state or run immediate loading work in sync Notifier.build().",
    correctionMessage: 'Return initial state from build() and defer loading with Future.microtask.',
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

final class _BodyVisitor extends RecursiveAstVisitor<void> {
  _BodyVisitor(this.rule, this.classNode);

  final AvoidSyncNotifierStateRead rule;
  final ClassDeclaration classNode;

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.name != 'state') return;
    final parent = node.parent;
    if (parent is AssignmentExpression && parent.leftHandSide == node) return;
    rule.reportAtNode(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (containsFutureMicrotaskAncestor(node)) return;
    final name = node.methodName.name;
    if (RegExp(r'^_(?:load|init|fetch|listen|refresh|setup)[A-Za-z0-9_]*$').hasMatch(name)) {
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
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}
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
    if (_done || node.name != 'state') return;
    final parent = node.parent;
    if (parent is AssignmentExpression && parent.leftHandSide == node) return;
    if (parent is PropertyAccess &&
        parent.propertyName == node &&
        parent.target is! ThisExpression) {
      return;
    }
    if (parent is PrefixedIdentifier && parent.identifier == node) return;
    final element = node.element;
    if (element is PropertyAccessorElement && element.enclosingElement is InterfaceElement) {
      found = true;
    }
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_done) return;
    if (containsFutureMicrotaskAncestor(node)) return;
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
