// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_nullable_tostring.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_unnecessary_nullable_return_type.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_correct_json_casts.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferCorrectJsonCastsTest);
    defineReflectiveTests(AvoidUnnecessaryNullableReturnTypeTest);
    defineReflectiveTests(AvoidNullableToStringTest);
  });
}

@reflectiveTest
final class PreferCorrectJsonCastsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferCorrectJsonCasts();
    super.setUp();
  }

  Future<void> test_jsonListStringCast_lint() async {
    const source = r'''
List<String> read(Map<String, dynamic> json) {
  return json['items'] as List<String>;
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf("json['items'] as List<String>"), "json['items'] as List<String>".length),
    ]);
  }

  Future<void> test_jsonMapStringValueCast_lint() async {
    const source = r'''
Map<String, String> read(Map<String, Object?> json) {
  return json['labels'] as Map<String, String>;
}
''';

    await assertDiagnostics(source, [
      lint(
        source.indexOf("json['labels'] as Map<String, String>"),
        "json['labels'] as Map<String, String>".length,
      ),
    ]);
  }

  Future<void> test_jsonScalarCast_noLint() async {
    await assertNoDiagnostics(r'''
String read(Map<String, dynamic> json) {
  return json['name'] as String;
}
''');
  }

  Future<void> test_jsonDynamicCollectionCast_noLint() async {
    await assertNoDiagnostics(r'''
List<dynamic> read(Map<String, dynamic> json) {
  return json['items'] as List<dynamic>;
}
''');
  }

  Future<void> test_nonJsonMapCast_noLint() async {
    await assertNoDiagnostics(r'''
List<String> read(Map<String, List<String>> cache) {
  return cache['items'] as List<String>;
}
''');
  }
}

@reflectiveTest
final class AvoidUnnecessaryNullableReturnTypeTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidUnnecessaryNullableReturnType();
    super.setUp();
  }

  Future<void> test_expressionBodyNonNull_lint() async {
    const source = r'''
String? label() => 'ready';
''';

    await assertDiagnostics(source, [lint(source.indexOf('String?'), 'String?'.length)]);
  }

  Future<void> test_blockBodyAllReturnsNonNull_lint() async {
    const source = r'''
String? label(bool enabled) {
  if (enabled) {
    return 'enabled';
  }
  return 'disabled';
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('String?'), 'String?'.length)]);
  }

  Future<void> test_nullableReturnPath_noLint() async {
    await assertNoDiagnostics(r'''
String? label(bool enabled) {
  if (enabled) {
    return 'enabled';
  }
  return null;
}
''');
  }

  Future<void> test_nullableExpressionPath_noLint() async {
    await assertNoDiagnostics(r'''
String? label(bool enabled) {
  if (enabled) {
    return maybeLabel();
  }
  return 'disabled';
}

String? maybeLabel() => null;
''');
  }

  Future<void> test_override_noLint() async {
    await assertNoDiagnostics(r'''
abstract class Base {
  String? label();
}

class Child extends Base {
  @override
  String? label() => 'ready';
}
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
String label(String? value) => value.toString();
''';

    await assertDiagnostics(source, [lint(source.indexOf('toString'), 'toString'.length)]);
  }

  Future<void> test_nonNullableTarget_noLint() async {
    await assertNoDiagnostics(r'''
String label(String value) => value.toString();
''');
  }

  Future<void> test_promotedNullableTarget_noLint() async {
    await assertNoDiagnostics(r'''
String label(String? value) {
  if (value == null) return 'missing';
  return value.toString();
}
''');
  }
}
