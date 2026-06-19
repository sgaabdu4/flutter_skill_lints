import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../ast_node_analysis.dart';
import '../type_checker.dart';

/// Warns when a notifier member is called directly from a Consumer build.
///
/// A build method must stay side-effect free. Trigger notifier mutations from
/// callbacks, listeners, or explicit lifecycle code instead.
class AvoidCallingNotifierMembersInsideBuild extends AnalysisRule {
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
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addMethodDeclaration(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidCallingNotifierMembersInsideBuild rule;

  static const _consumerWidgetChecker = TypeChecker.any([
    TypeChecker.fromName('ConsumerWidget', packageName: 'flutter_riverpod'),
    TypeChecker.fromName('HookConsumerWidget', packageName: 'hooks_riverpod'),
  ]);

  static const _consumerStateChecker = TypeChecker.any([
    TypeChecker.fromName('ConsumerState', packageName: 'flutter_riverpod'),
    TypeChecker.fromName('HookConsumerState', packageName: 'hooks_riverpod'),
  ]);

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.name.lexeme != 'build') return;

    final classDecl = enclosingClassDeclaration(node);
    final element = classDecl?.declaredFragment?.element;
    if (element == null) return;
    if (!_consumerWidgetChecker.isSuperOf(element) && !_consumerStateChecker.isSuperOf(element)) {
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
  return _isNotifierSelector(argument);
}

bool _isNotifierSelector(Expression expression) {
  final unwrapped = expression.unParenthesized;
  return switch (unwrapped) {
    PrefixedIdentifier(:final identifier) => identifier.name == 'notifier',
    PropertyAccess(:final propertyName) => propertyName.name == 'notifier',
    _ => false,
  };
}
