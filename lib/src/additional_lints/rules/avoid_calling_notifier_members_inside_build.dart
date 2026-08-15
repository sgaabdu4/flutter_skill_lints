import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'package:flutter_skill_lints/src/additional_lints/ast_node_analysis.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/riverpod_consumer_checkers.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Warns when a notifier member is called directly from a Consumer build.
///
/// A build method must stay side-effect free. Trigger notifier mutations from
/// callbacks, listeners, or explicit lifecycle code instead.
class AvoidCallingNotifierMembersInsideBuild extends MethodDeclarationRule {
  static const LintCode code = LintCode(
    'avoid_calling_notifier_members_inside_build',
    'Avoid calling notifier members inside build methods.',
    correctionMessage:
        'Move notifier calls out of build. Keep ref.read(provider.notifier) '
        'calls inside callbacks, listeners, or lifecycle methods.',
  );

  AvoidCallingNotifierMembersInsideBuild()
    : super(
        name: 'avoid_calling_notifier_members_inside_build',
        description:
            'Warns when ref.read/watch(provider.notifier).member() is called '
            'inside a Riverpod Consumer build method.',
        code: code,
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidCallingNotifierMembersInsideBuild rule;

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.name.lexeme != 'build') return;

    final classDecl = enclosingClassDeclaration(node);
    final element = classDecl?.declaredFragment?.element;
    if (element == null) return;
    if (!consumerWidgetChecker.isSuperOf(element) && !consumerStateChecker.isSuperOf(element)) {
      return;
    }

    node.body.visitChildren(_NotifierMemberCallFinder(rule));
  }
}

final class _NotifierMemberCallFinder extends RecursiveAstVisitor<void> {
  const _NotifierMemberCallFinder(this.rule);

  final AvoidCallingNotifierMembersInsideBuild rule;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.target case final MethodInvocation target when _isNotifierRead(target)) {
      rule.reportAtNode(node.methodName);
      return;
    }

    super.visitMethodInvocation(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}
}

bool _isNotifierRead(MethodInvocation node) {
  if (node.methodName.name case final name when name != 'read' && name != 'watch') {
    return false;
  }
  final target = node.target;
  if (target is! SimpleIdentifier || target.name != 'ref') return false;
  if (node.argumentList.arguments.length != 1) return false;

  final argument = node.argumentList.arguments.single;
  return isNotifierSelector(argument.argumentExpression);
}
