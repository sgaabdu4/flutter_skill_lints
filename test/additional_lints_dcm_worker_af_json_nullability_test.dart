import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_nullable_tostring.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_unnecessary_nullable_return_type.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_correct_json_casts.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<PreferCorrectJsonCastsTest>(
    'PreferCorrectJsonCastsTest',
    PreferCorrectJsonCastsTest.new,
    {
      'test_jsonListStringCast_lint': (t) => t._jsonListStringCastLint(),
      'test_jsonMapStringValueCast_lint': (t) => t._jsonMapStringValueCastLint(),
      'test_jsonScalarCast_noLint': (t) => t._jsonScalarCastNoLint(),
      'test_jsonDynamicCollectionCast_noLint': (t) => t._jsonDynamicCollectionCastNoLint(),
      'test_nonJsonMapCast_noLint': (t) => t._nonJsonMapCastNoLint(),
    },
  );
  analysisRuleSuite<AvoidUnnecessaryNullableReturnTypeTest>(
    'AvoidUnnecessaryNullableReturnTypeTest',
    AvoidUnnecessaryNullableReturnTypeTest.new,
    {
      'test_expressionBodyNonNull_lint': (t) => t._expressionBodyNonNullLint(),
      'test_blockBodyAllReturnsNonNull_lint': (t) => t._blockBodyAllReturnsNonNullLint(),
      'test_nullableReturnPath_noLint': (t) => t._nullableReturnPathNoLint(),
      'test_nullableExpressionPath_noLint': (t) => t._nullableExpressionPathNoLint(),
      'test_override_noLint': (t) => t._overrideNoLint(),
    },
  );
  analysisRuleSuite<AvoidNullableToStringTest>(
    'AvoidNullableToStringTest',
    AvoidNullableToStringTest.new,
    {
      'test_nullableTarget_lint': (t) => t._nullableTargetLint(),
      'test_nonNullableTarget_noLint': (t) => t._nonNullableTargetNoLint(),
      'test_promotedNullableTarget_noLint': (t) => t._promotedNullableTargetNoLint(),
    },
  );
}

final class PreferCorrectJsonCastsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferCorrectJsonCasts();
    super.setUp();
  }

  Future<void> _jsonListStringCastLint() async {
    const source = r'''
List<String> read(Map<String, dynamic> json) {
  return json['items'] as List<String>;
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf("json['items'] as List<String>"), "json['items'] as List<String>".length),
    ]);
  }

  Future<void> _jsonMapStringValueCastLint() async {
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

  Future<void> _jsonScalarCastNoLint() async {
    await assertNoDiagnostics(r'''
String read(Map<String, dynamic> json) {
  return json['name'] as String;
}
''');
  }

  Future<void> _jsonDynamicCollectionCastNoLint() async {
    await assertNoDiagnostics(r'''
List<dynamic> read(Map<String, dynamic> json) {
  return json['items'] as List<dynamic>;
}
''');
  }

  Future<void> _nonJsonMapCastNoLint() async {
    await assertNoDiagnostics(r'''
List<String> read(Map<String, List<String>> cache) {
  return cache['items'] as List<String>;
}
''');
  }
}

final class AvoidUnnecessaryNullableReturnTypeTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidUnnecessaryNullableReturnType();
    super.setUp();
  }

  Future<void> _expressionBodyNonNullLint() async {
    const source = r'''
String? label() => 'ready';
''';

    await assertDiagnostics(source, [lint(source.indexOf('String?'), 'String?'.length)]);
  }

  Future<void> _blockBodyAllReturnsNonNullLint() async {
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

  Future<void> _nullableReturnPathNoLint() async {
    await assertNoDiagnostics(r'''
String? label(bool enabled) {
  if (enabled) {
    return 'enabled';
  }
  return null;
}
''');
  }

  Future<void> _nullableExpressionPathNoLint() async {
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

  Future<void> _overrideNoLint() async {
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

final class AvoidNullableToStringTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidNullableToString();
    super.setUp();
  }

  Future<void> _nullableTargetLint() async {
    const source = r'''
String label(String? value) => value.toString();
''';

    await assertDiagnostics(source, [lint(source.indexOf('toString'), 'toString'.length)]);
  }

  Future<void> _nonNullableTargetNoLint() async {
    await assertNoDiagnostics(r'''
String label(String value) => value.toString();
''');
  }

  Future<void> _promotedNullableTargetNoLint() async {
    await assertNoDiagnostics(r'''
String label(String? value) {
  if (value == null) return 'missing';
  return value.toString();
}
''');
  }
}
