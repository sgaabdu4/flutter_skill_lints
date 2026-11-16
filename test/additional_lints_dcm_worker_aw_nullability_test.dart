import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_nullable_interpolation.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_nullable_tostring.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<_AvoidNullableInterpolationTest>(
    'AvoidNullableInterpolationTest',
    _AvoidNullableInterpolationTest.new,
    _AvoidNullableInterpolationTest._allCases,
  );
  analysisRuleSuite<_AvoidNullableToStringTest>(
    'AvoidNullableToStringTest',
    _AvoidNullableToStringTest.new,
    _AvoidNullableToStringTest._allCases,
  );
}

final class _AvoidNullableInterpolationTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidNullableInterpolationTest)> get _allCases =>
      caseSet<_AvoidNullableInterpolationTest>(
        parent: const {},
        own: {
          'test_nullableExpression_lint': (t) => t._nullableExpressionLint(),
          'test_nullableInterpolatedExpression_lint': (t) =>
              t._nullableInterpolatedExpressionLint(),
          'test_nonNullableExpression_noLint': (t) => t._nonNullableExpressionNoLint(),
        },
      );

  @override
  void setUp() {
    rule = AvoidNullableInterpolation();
    super.setUp();
  }

  Future<void> _nullableExpressionLint() async {
    const source = r'''
String label(String? name) => 'Hello $name';
''';

    await assertDiagnostics(source, [lint(source.lastIndexOf('name'), 'name'.length)]);
  }

  Future<void> _nullableInterpolatedExpressionLint() async {
    const source = r'''
String label(int? count) => 'Count ${count}';
''';

    await assertDiagnostics(source, [lint(source.lastIndexOf('count'), 'count'.length)]);
  }

  Future<void> _nonNullableExpressionNoLint() async {
    await assertNoDiagnostics(r'''
String label(String name) => 'Hello $name';
''');
  }
}

final class _AvoidNullableToStringTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidNullableToStringTest)> get _allCases =>
      caseSet<_AvoidNullableToStringTest>(
        parent: const {},
        own: {
          'test_nullableTarget_lint': (t) => t._nullableTargetLint(),
          'test_nullableCascadeTarget_lint': (t) => t._nullableCascadeTargetLint(),
          'test_nonNullableTarget_noLint': (t) => t._nonNullableTargetNoLint(),
        },
      );

  @override
  void setUp() {
    rule = AvoidNullableToString();
    super.setUp();
  }

  Future<void> _nullableTargetLint() async {
    const source = r'''
String label(Object? value) => value.toString();
''';

    await assertDiagnostics(source, [lint(source.indexOf('toString'), 'toString'.length)]);
  }

  Future<void> _nullableCascadeTargetLint() async {
    const source = r'''
void update(String? value) {
  value?..toString();
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('toString'), 'toString'.length)]);
  }

  Future<void> _nonNullableTargetNoLint() async {
    await assertNoDiagnostics(r'''
String label(Object value) => value.toString();
''');
  }
}
