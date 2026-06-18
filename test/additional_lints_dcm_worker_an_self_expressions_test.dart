// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_equal_expressions.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_self_assignment.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_self_compare.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidEqualExpressionsTest);
    defineReflectiveTests(AvoidSelfAssignmentTest);
    defineReflectiveTests(AvoidSelfCompareTest);
  });
}

@reflectiveTest
final class AvoidEqualExpressionsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidEqualExpressions();
    super.setUp();
  }

  Future<void> test_logicalAndSameExpression_lint() async {
    const source = r'''
bool ready(bool enabled, bool valid) => (enabled && valid) && (enabled && valid);
''';

    await assertDiagnostics(source, [
      lint(
        source.indexOf('(enabled && valid) &&'),
        '(enabled && valid) && (enabled && valid)'.length,
      ),
    ]);
  }

  Future<void> test_ifNullSameExpression_lint() async {
    const source = r'''
String? value(String? name) => name ?? name;
''';

    await assertDiagnostics(source, [lint(source.indexOf('name ?? name'), 'name ?? name'.length)]);
  }

  Future<void> test_differentLogicalOperands_noLint() async {
    await assertNoDiagnostics(r'''
bool ready(bool enabled, bool valid) => enabled && valid;
''');
  }

  Future<void> test_repeatedCall_noLint() async {
    await assertNoDiagnostics(r'''
bool ready(bool Function() enabled) => enabled() && enabled();
''');
  }
}

@reflectiveTest
final class AvoidSelfAssignmentTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidSelfAssignment();
    super.setUp();
  }

  Future<void> test_localSelfAssignment_lint() async {
    const source = r'''
void normalize(int value) {
  value = value;
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('value = value'), 'value = value'.length),
    ]);
  }

  Future<void> test_fieldSelfAssignment_lint() async {
    const source = r'''
class User {
  String name = '';

  void rename() {
    this.name = this.name;
  }
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('this.name = this.name'), 'this.name = this.name'.length),
    ]);
  }

  Future<void> test_compoundAssignment_noLint() async {
    await assertNoDiagnostics(r'''
void increment(int value) {
  value += value;
}
''');
  }

  Future<void> test_differentAssignment_noLint() async {
    await assertNoDiagnostics(r'''
void normalize(int value) {
  final next = value.abs();
  value = next;
}
''');
  }
}

@reflectiveTest
final class AvoidSelfCompareTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidSelfCompare();
    super.setUp();
  }

  Future<void> test_identifierSelfCompare_lint() async {
    const source = r'''
bool same(int value) => value == value;
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('value == value'), 'value == value'.length),
    ]);
  }

  Future<void> test_propertySelfCompare_lint() async {
    const source = r'''
class User {
  User(this.name);

  final String name;
}

bool same(User user) => user.name != user.name;
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('user.name != user.name'), 'user.name != user.name'.length),
    ]);
  }

  Future<void> test_differentCompare_noLint() async {
    await assertNoDiagnostics(r'''
bool same(int left, int right) => left == right;
''');
  }

  Future<void> test_repeatedCall_noLint() async {
    await assertNoDiagnostics(r'''
bool same(int Function() next) => next() == next();
''');
  }
}
