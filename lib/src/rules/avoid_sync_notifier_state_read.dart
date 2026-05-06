import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

final class AvoidSyncNotifierStateRead extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_sync_notifier_state_read',
    "Don't read state or run immediate loading work in sync Notifier.build().",
    correctionMessage: 'Return initial state from build() and defer loading with Future.microtask.',
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
    node.body.accept(_BodyVisitor(rule));
  }
}

final class _BodyVisitor extends RecursiveAstVisitor<void> {
  _BodyVisitor(this.rule);

  final AvoidSyncNotifierStateRead rule;

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
    super.visitMethodInvocation(node);
  }

  @override
  void visitNamedExpression(NamedExpression node) {
    if (node.name.label.name != 'fireImmediately') {
      super.visitNamedExpression(node);
      return;
    }
    final expression = node.expression;
    if (expression is BooleanLiteral && expression.value) {
      rule.reportAtNode(node);
    }
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}
}
