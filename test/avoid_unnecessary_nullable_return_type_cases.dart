import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_unnecessary_nullable_return_type.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<AvoidUnnecessaryNullableReturnTypeExitTest>(
    'AvoidUnnecessaryNullableReturnTypeExitTest',
    AvoidUnnecessaryNullableReturnTypeExitTest.new,
    {
      'reportsIfElseWithReturningBlocks': (t) => t.reportsIfElseWithReturningBlocks(),
      'reportsIfElseThatEndsInThrow': (t) => t.reportsIfElseThatEndsInThrow(),
      'reportsElseIfChainThatAlwaysReturns': (t) => t.reportsElseIfChainThatAlwaysReturns(),
      'acceptsElseBranchThatOnlyCallsNeverFunction': (t) =>
          t.acceptsElseBranchThatOnlyCallsNeverFunction(),
      'acceptsElseIfChainEndingInNeverCall': (t) => t.acceptsElseIfChainEndingInNeverCall(),
    },
  );
}

final class AvoidUnnecessaryNullableReturnTypeExitTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidUnnecessaryNullableReturnType();
    super.setUp();
  }

  Future<void> _expectReported(String body) async {
    final source = 'String? label(bool a, bool b) {\n$body\n}\n';
    await assertDiagnostics(source, [lint(source.indexOf('String?'), 'String?'.length)]);
  }

  Future<void> reportsIfElseWithReturningBlocks() => _expectReported('''
  if (a) {
    return 'a';
  } else {
    return 'b';
  }''');

  Future<void> reportsIfElseThatEndsInThrow() => _expectReported('''
  if (a) {
    return 'a';
  } else {
    throw 'b';
  }''');

  Future<void> reportsElseIfChainThatAlwaysReturns() => _expectReported('''
  if (a) {
    return 'a';
  } else if (b) {
    return 'b';
  } else {
    return 'c';
  }''');

  Future<void> acceptsElseBranchThatOnlyCallsNeverFunction() => assertNoDiagnostics('''
Never fail() => throw 'failed';

String? label(bool a) {
  if (a) {
    return 'a';
  } else {
    fail();
  }
}
''');

  Future<void> acceptsElseIfChainEndingInNeverCall() => assertNoDiagnostics('''
Never fail() => throw 'failed';

String? label(bool a, bool b) {
  if (a) {
    return 'a';
  } else if (b) {
    return 'b';
  } else {
    fail();
  }
}
''');
}
