import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when a test `group` callback contains no test calls.
final class AvoidEmptyTestGroups extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_empty_test_groups',
    'Avoid test groups without test cases.',
    correctionMessage: 'Add a test case or remove the empty group.',
  );

  AvoidEmptyTestGroups()
    : super(
        name: 'avoid_empty_test_groups',
        description: 'Warns when a test group contains no test calls.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addMethodInvocation(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidEmptyTestGroups rule;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'group') return;

    final callback = _callbackArgument(node);
    if (callback == null) return;

    final finder = _TestCallFinder();
    callback.body.accept(finder);
    if (!finder.hasTestCall) {
      rule.reportAtNode(node.methodName);
    }
  }

  static FunctionExpression? _callbackArgument(MethodInvocation node) {
    final positionalArgs = node.argumentList.arguments.where(
      (argument) => argument is! NamedExpression,
    );
    if (positionalArgs.length < 2) return null;

    final callback = positionalArgs.elementAt(1);
    return callback is FunctionExpression ? callback : null;
  }
}

final class _TestCallFinder extends RecursiveAstVisitor<void> {
  static const Set<String> _testMethodNames = {'test', 'testWidgets'};

  bool hasTestCall = false;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_testMethodNames.contains(node.methodName.name)) {
      hasTestCall = true;
      return;
    }
    super.visitMethodInvocation(node);
  }
}
