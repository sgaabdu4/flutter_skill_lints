// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_unnecessary_block.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_unnecessary_parentheses.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_unnecessary_return.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidUnnecessaryParenthesesTest);
    defineReflectiveTests(AvoidUnnecessaryBlockTest);
    defineReflectiveTests(AvoidUnnecessaryReturnTest);
  });
}

@reflectiveTest
final class AvoidUnnecessaryParenthesesTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidUnnecessaryParentheses();
    super.setUp();
  }

  Future<void> test_returnExpression_lint() async {
    const source = r'''
int f(int value) {
  return (value);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('(value)'), '(value)'.length)]);
  }

  Future<void> test_variableInitializer_lint() async {
    const source = r'''
void f(int value) {
  final copy = (value);
  print(copy);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('(value)'), '(value)'.length)]);
  }

  Future<void> test_argument_lint() async {
    const source = r'''
void f(int value) {
  print((value));
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('(value)'), '(value)'.length)]);
  }

  Future<void> test_precedenceContext_noLint() async {
    await assertNoDiagnostics(r'''
int f(int a, int b, int c) {
  return a * (b + c);
}
''');
  }

  Future<void> test_conditionContext_noLint() async {
    await assertNoDiagnostics(r'''
void f(bool ready) {
  if ((ready)) {
    print('go');
  }
}
''');
  }
}

@reflectiveTest
final class AvoidUnnecessaryBlockTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidUnnecessaryBlock();
    super.setUp();
  }

  Future<void> test_blockOnlyContainsNestedBlock_lint() async {
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

  Future<void> test_ifBlockOnlyContainsNestedBlock_lint() async {
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

  Future<void> test_extraStatement_noLint() async {
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

@reflectiveTest
final class AvoidUnnecessaryReturnTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidUnnecessaryReturn();
    super.setUp();
  }

  Future<void> test_trailingReturnInVoidFunction_lint() async {
    const source = r'''
void f() {
  print('go');
  return;
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('return;'), 'return;'.length)]);
  }

  Future<void> test_trailingReturnInVoidMethod_lint() async {
    const source = r'''
class C {
  void f() {
    return;
  }
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('return;'), 'return;'.length)]);
  }

  Future<void> test_nonTrailingReturn_noLint() async {
    await assertNoDiagnostics(r'''
void f(bool ready) {
  if (!ready) {
    return;
  }
  print('go');
}
''');
  }

  Future<void> test_valueReturn_noLint() async {
    await assertNoDiagnostics(r'''
int f() {
  return 1;
}
''');
  }

  Future<void> test_futureVoidReturn_noLint() async {
    await assertNoDiagnostics(r'''
Future<void> f() async {
  return;
}
''');
  }
}
