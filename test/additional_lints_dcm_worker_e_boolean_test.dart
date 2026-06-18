// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_inverted_boolean_checks.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_negations_in_equality_checks.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/no_equal_then_else.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidInvertedBooleanChecksTest);
    defineReflectiveTests(AvoidNegationsInEqualityChecksTest);
    defineReflectiveTests(NoEqualThenElseTest);
  });
}

@reflectiveTest
final class AvoidInvertedBooleanChecksTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidInvertedBooleanChecks();
    super.setUp();
  }

  Future<void> test_negatedEqualityCondition_lint() async {
    const source = r'''
bool same(int left, int right) {
  if (!(left == right)) {
    return false;
  }
  return true;
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('!(left == right)'), '!(left == right)'.length),
    ]);
  }

  Future<void> test_negatedIsCondition_lint() async {
    const source = r'''
bool isText(Object value) {
  if (!(value is String)) {
    return false;
  }
  return true;
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('!(value is String)'), '!(value is String)'.length),
    ]);
  }

  Future<void> test_plainBooleanNegation_noLint() async {
    await assertNoDiagnostics(r'''
bool missing(bool enabled) => !enabled;
''');
  }

  Future<void> test_negatedMethodCall_noLint() async {
    await assertNoDiagnostics(r'''
bool missing(String value) => !value.isEmpty;
''');
  }
}

@reflectiveTest
final class AvoidNegationsInEqualityChecksTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidNegationsInEqualityChecks();
    super.setUp();
  }

  Future<void> test_leftNegatedEquality_lint() async {
    const source = r'''
bool matches(bool ready, bool expected) => !ready == expected;
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('!ready == expected'), '!ready == expected'.length),
    ]);
  }

  Future<void> test_rightNegatedInequality_lint() async {
    const source = r'''
bool differs(bool ready, bool expected) => ready != !expected;
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('ready != !expected'), 'ready != !expected'.length),
    ]);
  }

  Future<void> test_bothSidesNegated_noLint() async {
    await assertNoDiagnostics(r'''
bool matches(bool left, bool right) => !left == !right;
''');
  }

  Future<void> test_plainEquality_noLint() async {
    await assertNoDiagnostics(r'''
bool matches(bool left, bool right) => left == right;
''');
  }
}

@reflectiveTest
final class NoEqualThenElseTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = NoEqualThenElse();
    super.setUp();
  }

  Future<void> test_conditionalSameExpressions_lint() async {
    const source = r'''
int value(bool ready, int count) => ready ? count + 1 : count + 1;
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('ready ?'), 'ready ? count + 1 : count + 1'.length),
    ]);
  }

  Future<void> test_ifElseSameReturns_lint() async {
    const source = r'''
int value(bool ready, int count) {
  if (ready) {
    return count;
  } else {
    return count;
  }
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('if (ready)'), source.indexOf('\n}') - source.indexOf('if (ready)')),
    ]);
  }

  Future<void> test_conditionalDifferentExpressions_noLint() async {
    await assertNoDiagnostics(r'''
int value(bool ready, int count) => ready ? count + 1 : count - 1;
''');
  }

  Future<void> test_ifElseIf_noLint() async {
    await assertNoDiagnostics(r'''
int value(bool first, bool second) {
  if (first) {
    return 1;
  } else if (second) {
    return 1;
  }
  return 0;
}
''');
  }
}
