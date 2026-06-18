// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_missing_interpolation.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_nullable_interpolation.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_throw_objects_without_tostring.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidNullableInterpolationTest);
    defineReflectiveTests(AvoidMissingInterpolationTest);
    defineReflectiveTests(AvoidThrowObjectsWithoutToStringTest);
  });
}

@reflectiveTest
final class AvoidNullableInterpolationTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidNullableInterpolation();
    super.setUp();
  }

  Future<void> test_nullableLocal_lint() async {
    const source = r'''
void f(String? name) {
  print('Hello $name');
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('name\''), 'name'.length)]);
  }

  Future<void> test_nonNullableLocal_noLint() async {
    await assertNoDiagnostics(r'''
void f(String name) {
  print('Hello $name');
}
''');
  }

  Future<void> test_promotedNullable_noLint() async {
    await assertNoDiagnostics(r'''
void f(String? name) {
  if (name == null) return;
  print('Hello $name');
}
''');
  }
}

@reflectiveTest
final class AvoidMissingInterpolationTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidMissingInterpolation();
    super.setUp();
  }

  Future<void> test_matchesPriorLocal_lint() async {
    const source = r'''
void f() {
  final total = 3;
  print('total');
}
''';

    await assertDiagnostics(source, [lint(source.indexOf("'total'"), "'total'".length)]);
  }

  Future<void> test_matchesParameter_lint() async {
    const source = r'''
void f(String label) {
  print('label');
}
''';

    await assertDiagnostics(source, [lint(source.indexOf("'label'"), "'label'".length)]);
  }

  Future<void> test_noLocalName_noLint() async {
    await assertNoDiagnostics(r'''
void f() {
  print('total');
}
''');
  }

  Future<void> test_notExactlyIdentifier_noLint() async {
    await assertNoDiagnostics(r'''
void f(String label) {
  print('hello label');
}
''');
  }

  Future<void> test_laterLocal_noLint() async {
    await assertNoDiagnostics(r'''
void f() {
  print('total');
  final total = 3;
}
''');
  }
}

@reflectiveTest
final class AvoidThrowObjectsWithoutToStringTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidThrowObjectsWithoutToString();
    super.setUp();
  }

  Future<void> test_localClassWithoutToString_lint() async {
    const source = r'''
class LocalFailure {
  const LocalFailure();
}

void f() {
  throw const LocalFailure();
}
''';

    await assertDiagnostics(source, [
      lint(source.lastIndexOf('const LocalFailure()'), 'const LocalFailure()'.length),
    ]);
  }

  Future<void> test_localClassWithToString_noLint() async {
    await assertNoDiagnostics(r'''
class LocalFailure {
  const LocalFailure();

  @override
  String toString() => 'LocalFailure';
}

void f() {
  throw const LocalFailure();
}
''');
  }

  Future<void> test_throwString_noLint() async {
    await assertNoDiagnostics(r'''
void f() {
  throw 'failed';
}
''');
  }
}
