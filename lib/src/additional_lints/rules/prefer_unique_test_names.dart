import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when test cases in the same group use the same name.
final class PreferUniqueTestNames extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_unique_test_names',
    'Use a unique test name.',
    correctionMessage: 'Rename this test so each test in the group has a distinct name.',
  );

  PreferUniqueTestNames()
    : super(
        name: 'prefer_unique_test_names',
        description: 'Warns when sibling test cases use the same literal name.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addCompilationUnit(this, _Visitor(this));
  }
}

final class _Visitor extends RecursiveAstVisitor<void> {
  _Visitor(this.rule);

  final PreferUniqueTestNames rule;
  final List<Set<String>> _testNameScopes = [<String>{}];

  static const _testFunctions = {'test', 'testWidgets'};

  Set<String> get _currentTestNames => _testNameScopes.last;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'group') {
      _visitGroup(node);
      return;
    }

    if (_testFunctions.contains(node.methodName.name)) {
      _checkTestName(node);
      return;
    }

    super.visitMethodInvocation(node);
  }

  void _visitGroup(MethodInvocation node) {
    final callback = _callbackArgument(node);
    if (callback == null) {
      super.visitMethodInvocation(node);
      return;
    }

    _testNameScopes.add(<String>{});
    try {
      callback.body.accept(this);
    } finally {
      _testNameScopes.removeLast();
    }
  }

  void _checkTestName(MethodInvocation node) {
    final name = _literalNameArgument(node);
    if (name == null) return;

    if (!_currentTestNames.add(name.stringValue ?? name.toSource())) {
      rule.reportAtNode(name);
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

  static StringLiteral? _literalNameArgument(MethodInvocation node) {
    final positionalArgs = node.argumentList.arguments.where(
      (argument) => argument is! NamedExpression,
    );
    if (positionalArgs.isEmpty) return null;

    final name = positionalArgs.first;
    return name is StringLiteral ? name : null;
  }
}
