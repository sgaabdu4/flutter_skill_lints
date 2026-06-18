// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_bitwise_operators_with_booleans.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_conditions_with_boolean_literals.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_constant_assert_conditions.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidBitwiseOperatorsWithBooleansTest);
    defineReflectiveTests(AvoidConditionsWithBooleanLiteralsTest);
    defineReflectiveTests(AvoidConstantAssertConditionsTest);
  });
}

@reflectiveTest
final class AvoidBitwiseOperatorsWithBooleansTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidBitwiseOperatorsWithBooleans();
    super.setUp();
  }

  Future<void> test_ampersandWithBools_lint() async {
    const source = r'''
bool both(bool left, bool right) => left & right;
''';

    await assertDiagnostics(source, [lint(source.indexOf('left & right'), 'left & right'.length)]);
  }

  Future<void> test_barWithBools_lint() async {
    const source = r'''
bool either(bool left, bool right) => left | right;
''';

    await assertDiagnostics(source, [lint(source.indexOf('left | right'), 'left | right'.length)]);
  }

  Future<void> test_caretWithBools_lint() async {
    const source = r'''
bool different(bool left, bool right) => left ^ right;
''';

    await assertDiagnostics(source, [lint(source.indexOf('left ^ right'), 'left ^ right'.length)]);
  }

  Future<void> test_logicalOperators_noLint() async {
    await assertNoDiagnostics(r'''
bool both(bool left, bool right) => left && right;
bool either(bool left, bool right) => left || right;
''');
  }

  Future<void> test_intBitwiseOperators_noLint() async {
    await assertNoDiagnostics(r'''
int mask(int left, int right) => left & right;
''');
  }

  Future<void> test_customOperatorReturnBool_noLint() async {
    await assertNoDiagnostics(r'''
final class Flag {
  const Flag();
  bool operator &(Flag other) => true;
}

bool both(Flag left, Flag right) => left & right;
''');
  }
}

@reflectiveTest
final class AvoidConditionsWithBooleanLiteralsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidConditionsWithBooleanLiterals();
    super.setUp();
  }

  Future<void> test_whileConditionLiteral_lint() async {
    const source = r'''
void f() {
  while (true) {
    break;
  }
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('true'), 'true'.length)]);
  }

  Future<void> test_logicalConditionLiteral_lint() async {
    const source = r'''
int value(bool ready) {
  if (ready && true) {
    return 1;
  }
  return 0;
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('true'), 'true'.length)]);
  }

  Future<void> test_conditionalExpressionLiteral_lint() async {
    const source = r'''
int value(bool ready) => ready && true ? 1 : 0;
''';

    await assertDiagnostics(source, [lint(source.indexOf('true'), 'true'.length)]);
  }

  Future<void> test_nullableBoolComparison_noLint() async {
    await assertNoDiagnostics(r'''
bool value(bool? ready) => ready == true;
''');
  }

  Future<void> test_booleanLiteralArgument_noLint() async {
    await assertNoDiagnostics(r'''
bool isReady(bool value) => value;
int value(bool ready) {
  if (isReady(true)) {
    return 1;
  }
  return 0;
}
''');
  }
}

@reflectiveTest
final class AvoidConstantAssertConditionsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidConstantAssertConditions();
    super.setUp();
  }

  Future<void> test_assertBoolLiteral_lint() async {
    const source = r'''
void f() {
  assert(true);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('true'), 'true'.length)]);
  }

  Future<void> test_assertConstantComparison_lint() async {
    const source = r'''
void f() {
  assert(1 == 1);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('1 == 1'), '1 == 1'.length)]);
  }

  Future<void> test_assertConstIdentifier_lint() async {
    const source = r'''
const ready = true;
void f() {
  assert(ready);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('ready);'), 'ready'.length)]);
  }

  Future<void> test_assertRuntimeCondition_noLint() async {
    await assertNoDiagnostics(r'''
void f(bool ready) {
  assert(ready);
}
''');
  }

  Future<void> test_assertRuntimeComparison_noLint() async {
    await assertNoDiagnostics(r'''
void f(int value) {
  assert(value > 0);
}
''');
  }
}
