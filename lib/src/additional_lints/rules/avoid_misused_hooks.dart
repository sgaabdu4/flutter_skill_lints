import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'package:flutter_skill_lints/src/additional_lints/hook_detection.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';

/// Warns when hooks are used from deferred callbacks or repeated control flow.
///
/// This complements `avoid_conditional_hooks`: hooks must execute in the same
/// order during each build, and callbacks run outside the build hook context.
class AvoidMisusedHooks extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_misused_hooks',
    'Avoid using hooks in callbacks, loops, try blocks, or catch/finally blocks.',
    correctionMessage: 'Call hooks at the top level of the hook build method or custom hook.',
  );

  AvoidMisusedHooks()
    : super(
        name: 'avoid_misused_hooks',
        description:
            'Warns when hooks are called from callbacks, loops, try blocks, '
            'or catch/finally blocks.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final visitor = _Visitor(this);
    registry.addClassDeclaration(this, visitor);
    registry.addFunctionDeclaration(this, visitor);
    registry.addInstanceCreationExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidMisusedHooks rule;

  _Visitor(this.rule);

  static const _hookWidgetChecker = TypeChecker.any([
    TypeChecker.fromName('HookWidget', packageName: 'flutter_hooks'),
    TypeChecker.fromName('HookConsumerWidget', packageName: 'hooks_riverpod'),
  ]);

  static final _isHookName = hookNameRegex;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final element = node.declaredFragment?.element;
    if (element == null || !_hookWidgetChecker.isSuperOf(element)) return;

    final body = node.body;
    if (body is! BlockClassBody) return;

    for (final member in body.members.whereType<MethodDeclaration>()) {
      if (member.name.lexeme == 'build') {
        _checkBody(member.body);
      }
    }
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (!_isHookName.hasMatch(node.name.lexeme)) return;
    _checkBody(node.functionExpression.body);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final body = maybeHookBuilderBody(node);
    if (body == null) return;
    _checkBody(body);
  }

  void _checkBody(AstNode body) {
    body.accept(_MisusedHookFinder(rule));
  }
}

class _MisusedHookFinder extends RecursiveAstVisitor<void> {
  final AvoidMisusedHooks rule;
  int _misuseDepth = 0;

  _MisusedHookFinder(this.rule);

  static final _isHookName = hookNameRegex;

  void _checkHook(AstNode node) {
    if (_misuseDepth > 0 && _isHookName.hasMatch(node.beginToken.lexeme)) {
      rule.reportAtNode(node);
    }
  }

  void _withMisuse(AstNode node) {
    _misuseDepth++;
    node.accept(this);
    _misuseDepth--;
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _checkHook(node);
    super.visitMethodInvocation(node);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    _checkHook(node);
    super.visitFunctionExpressionInvocation(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    _withMisuse(node.body);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _withMisuse(node.functionExpression.body);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (maybeHookBuilderBody(node) != null) return;
    _checkHook(node);
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitForStatement(ForStatement node) {
    _withMisuse(node.body);
  }

  @override
  void visitForElement(ForElement node) {
    _withMisuse(node.body);
  }

  @override
  void visitDoStatement(DoStatement node) {
    _withMisuse(node.body);
    node.condition.accept(this);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    node.condition.accept(this);
    _withMisuse(node.body);
  }

  @override
  void visitTryStatement(TryStatement node) {
    _withMisuse(node.body);
    for (final catchClause in node.catchClauses) {
      _withMisuse(catchClause.body);
    }
    if (node.finallyBlock case final finallyBlock?) {
      _withMisuse(finallyBlock);
    }
  }
}
