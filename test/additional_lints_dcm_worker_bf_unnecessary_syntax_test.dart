import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_unnecessary_block.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_unnecessary_parentheses.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_unnecessary_return.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<AvoidUnnecessaryParenthesesTest>(
    'AvoidUnnecessaryParenthesesTest',
    AvoidUnnecessaryParenthesesTest.new,
    {
      'test_returnExpression_lint': (t) => t._returnExpressionLint(),
      'test_variableInitializer_lint': (t) => t._variableInitializerLint(),
      'test_argument_lint': (t) => t._argumentLint(),
      'test_precedenceContext_noLint': (t) => t._precedenceContextNoLint(),
      'test_conditionContext_noLint': (t) => t._conditionContextNoLint(),
    },
  );
  analysisRuleSuite<AvoidUnnecessaryBlockTest>(
    'AvoidUnnecessaryBlockTest',
    AvoidUnnecessaryBlockTest.new,
    {
      'test_blockOnlyContainsNestedBlock_lint': (t) => t._blockOnlyContainsNestedBlockLint(),
      'test_ifBlockOnlyContainsNestedBlock_lint': (t) => t._ifBlockOnlyContainsNestedBlockLint(),
      'test_extraStatement_noLint': (t) => t._extraStatementNoLint(),
    },
  );
  analysisRuleSuite<AvoidUnnecessaryReturnTest>(
    'AvoidUnnecessaryReturnTest',
    AvoidUnnecessaryReturnTest.new,
    {
      'test_trailingReturnInVoidFunction_lint': (t) => t._trailingReturnInVoidFunctionLint(),
      'test_trailingReturnInVoidMethod_lint': (t) => t._trailingReturnInVoidMethodLint(),
      'test_nonTrailingReturn_noLint': (t) => t._nonTrailingReturnNoLint(),
      'test_valueReturn_noLint': (t) => t._valueReturnNoLint(),
      'test_futureVoidReturn_noLint': (t) => t._futureVoidReturnNoLint(),
    },
  );
}

final class AvoidUnnecessaryParenthesesTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidUnnecessaryParentheses();
    super.setUp();
  }

  Future<void> _returnExpressionLint() async {
    const source = r'''
int f(int value) {
  return (value);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('(value)'), '(value)'.length)]);
  }

  Future<void> _variableInitializerLint() async {
    const source = r'''
void f(int value) {
  final copy = (value);
  print(copy);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('(value)'), '(value)'.length)]);
  }

  Future<void> _argumentLint() async {
    const source = r'''
void f(int value) {
  print((value));
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('(value)'), '(value)'.length)]);
  }

  Future<void> _precedenceContextNoLint() async {
    await assertNoDiagnostics(r'''
int f(int a, int b, int c) {
  return a * (b + c);
}
''');
  }

  Future<void> _conditionContextNoLint() async {
    await assertNoDiagnostics(r'''
void f(bool ready) {
  if ((ready)) {
    print('go');
  }
}
''');
  }
}

final class AvoidUnnecessaryBlockTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidUnnecessaryBlock();
    super.setUp();
  }

  Future<void> _blockOnlyContainsNestedBlockLint() async {
    const source = r'''
void f() {
  {
    print('go');
  }
}
''';

    await assertDiagnostics(source, [
      lint(
        source.indexOf('{\n    print'),
        source.indexOf('\n  }') - source.indexOf('{\n    print') + 4,
      ),
    ]);
  }

  Future<void> _ifBlockOnlyContainsNestedBlockLint() async {
    const source = r'''
void f(bool ready) {
  if (ready) {
    {
      print('go');
    }
  }
}
''';

    await assertDiagnostics(source, [
      lint(
        source.indexOf('{\n      print'),
        source.indexOf('\n    }') - source.indexOf('{\n      print') + 6,
      ),
    ]);
  }

  Future<void> _extraStatementNoLint() async {
    await assertNoDiagnostics(r'''
void f() {
  print('start');
  {
    print('go');
  }
}
''');
  }
}

final class AvoidUnnecessaryReturnTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidUnnecessaryReturn();
    super.setUp();
  }

  Future<void> _trailingReturnInVoidFunctionLint() async {
    const source = r'''
void f() {
  print('go');
  return;
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('return;'), 'return;'.length)]);
  }

  Future<void> _trailingReturnInVoidMethodLint() async {
    const source = r'''
class C {
  void f() {
    return;
  }
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('return;'), 'return;'.length)]);
  }

  Future<void> _nonTrailingReturnNoLint() async {
    await assertNoDiagnostics(r'''
void f(bool ready) {
  if (!ready) {
    return;
  }
  print('go');
}
''');
  }

  Future<void> _valueReturnNoLint() async {
    await assertNoDiagnostics(r'''
int f() {
  return 1;
}
''');
  }

  Future<void> _futureVoidReturnNoLint() async {
    await assertNoDiagnostics(r'''
Future<void> f() async {
  return;
}
''');
  }
}
