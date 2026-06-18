// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_non_null_assertion.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_nullable_interpolation.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_nullable_tostring.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidNullableInterpolationTest);
    defineReflectiveTests(AvoidNullableToStringTest);
    defineReflectiveTests(AvoidNonNullAssertionTest);
  });
}

@reflectiveTest
final class AvoidNullableInterpolationTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidNullableInterpolation();
    super.setUp();
  }

  Future<void> test_nullableExpression_lint() async {
    const source = r'''
String label(String? name) => 'Hello $name';
''';

    await assertDiagnostics(source, [lint(source.lastIndexOf('name'), 'name'.length)]);
  }

  Future<void> test_nullableInterpolatedExpression_lint() async {
    const source = r'''
String label(int? count) => 'Count ${count}';
''';

    await assertDiagnostics(source, [lint(source.lastIndexOf('count'), 'count'.length)]);
  }

  Future<void> test_nonNullableExpression_noLint() async {
    await assertNoDiagnostics(r'''
String label(String name) => 'Hello $name';
''');
  }
}

@reflectiveTest
final class AvoidNullableToStringTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidNullableToString();
    super.setUp();
  }

  Future<void> test_nullableTarget_lint() async {
    const source = r'''
String label(Object? value) => value.toString();
''';

    await assertDiagnostics(source, [lint(source.indexOf('toString'), 'toString'.length)]);
  }

  Future<void> test_nullableCascadeTarget_lint() async {
    const source = r'''
void update(String? value) {
  value?..toString();
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('toString'), 'toString'.length)]);
  }

  Future<void> test_nonNullableTarget_noLint() async {
    await assertNoDiagnostics(r'''
String label(Object value) => value.toString();
''');
  }
}

@reflectiveTest
final class AvoidNonNullAssertionTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidNonNullAssertion();
    super.setUp();
  }

  Future<void> test_postfixBang_lint() async {
    const source = r'''
String label(String? value) => value!;
''';

    await assertDiagnostics(source, [lint(source.indexOf('!'), '!'.length)]);
  }

  Future<void> test_isNotNullCheck_noLint() async {
    await assertNoDiagnostics(r'''
bool hasValue(String? value) => value != null;
''');
  }
}
