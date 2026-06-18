import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when a test callback contains no assertion.
final class MissingTestAssertion extends AnalysisRule {
  static const LintCode code = LintCode(
    'missing_test_assertion',
    'Add an assertion to this test.',
    correctionMessage: 'Call expect(), expectLater(), or fail() so the test verifies behavior.',
  );

  MissingTestAssertion()
    : super(
        name: 'missing_test_assertion',
        description: 'Warns when a test callback contains no assertion call.',
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

  final MissingTestAssertion rule;

  static const _testFunctions = {'test', 'testWidgets'};

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (!_testFunctions.contains(node.methodName.name)) return;

    final callback = _callbackArgument(node);
    if (callback == null) return;

    final finder = _AssertionFinder();
    callback.body.accept(finder);
    if (!finder.hasAssertion) {
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

final class _AssertionFinder extends RecursiveAstVisitor<void> {
  static const _assertionFunctions = {
    'expect',
    'expectLater',
    'fail',
    'verify',
    'verifyInOrder',
    'verifyNever',
  };
  static const _assertionCallbackWrappers = {'fakeAsync'};

  bool hasAssertion = false;

  @override
  void visitFunctionExpression(FunctionExpression node) {
    return;
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_assertionFunctions.contains(node.methodName.name)) {
      hasAssertion = true;
      return;
    }

    if (_assertionCallbackWrappers.contains(node.methodName.name) &&
        _callbackArgumentHasAssertion(node)) {
      hasAssertion = true;
      return;
    }

    super.visitMethodInvocation(node);
  }

  static bool _callbackArgumentHasAssertion(MethodInvocation node) {
    for (final argument in node.argumentList.arguments) {
      if (argument is NamedExpression) continue;
      if (argument case final FunctionExpression callback) {
        final finder = _AssertionFinder();
        callback.body.accept(finder);
        return finder.hasAssertion;
      }
    }
    return false;
  }
}
