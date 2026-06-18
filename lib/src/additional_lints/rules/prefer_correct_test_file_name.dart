import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when a file containing tests does not end with `_test.dart`.
final class PreferCorrectTestFileName extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_correct_test_file_name',
    'Test files should end with _test.dart.',
    correctionMessage: 'Rename this file so the test runner can discover it reliably.',
  );

  PreferCorrectTestFileName()
    : super(
        name: 'prefer_correct_test_file_name',
        description: 'Warns when a file containing tests is not named *_test.dart.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final path = context.definingUnit.file.path.replaceAll('\\', '/');
    if (path.endsWith('_test.dart')) return;

    registry.addMethodInvocation(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final PreferCorrectTestFileName rule;

  static const _testFunctions = {'group', 'test', 'testWidgets'};

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_testFunctions.contains(node.methodName.name)) {
      rule.reportAtNode(node.methodName);
    }
  }
}
