import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_missing_interpolation.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_nullable_interpolation.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_throw_objects_without_tostring.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<AvoidNullableInterpolationTest>(
    'AvoidNullableInterpolationTest',
    AvoidNullableInterpolationTest.new,
    {
      'test_nullableLocal_lint': (t) => t._nullableLocalLint(),
      'test_nonNullableLocal_noLint': (t) => t._nonNullableLocalNoLint(),
      'test_promotedNullable_noLint': (t) => t._promotedNullableNoLint(),
    },
  );
  analysisRuleSuite<AvoidMissingInterpolationTest>(
    'AvoidMissingInterpolationTest',
    AvoidMissingInterpolationTest.new,
    {
      'test_matchesPriorLocal_lint': (t) => t._matchesPriorLocalLint(),
      'test_matchesParameter_lint': (t) => t._matchesParameterLint(),
      'test_structuralMapKeys_noLint': (t) => t._structuralMapKeysNoLint(),
      'test_mapValue_lint': (t) => t._mapValueLint(),
      'test_coreErrorParameterNames_noLint': (t) => t._coreErrorParameterNamesNoLint(),
      'test_unrelatedErrorClass_lint': (t) => t._unrelatedErrorClassLint(),
      'test_unrelatedNameParameter_lint': (t) => t._unrelatedNameParameterLint(),
      'test_noLocalName_noLint': (t) => t._noLocalNameNoLint(),
      'test_notExactlyIdentifier_noLint': (t) => t._notExactlyIdentifierNoLint(),
      'test_laterLocal_noLint': (t) => t._laterLocalNoLint(),
    },
  );
  analysisRuleSuite<AvoidThrowObjectsWithoutToStringTest>(
    'AvoidThrowObjectsWithoutToStringTest',
    AvoidThrowObjectsWithoutToStringTest.new,
    {
      'test_localClassWithoutToString_lint': (t) => t._localClassWithoutToStringLint(),
      'test_localClassWithToString_noLint': (t) => t._localClassWithToStringNoLint(),
      'test_throwString_noLint': (t) => t._throwStringNoLint(),
    },
  );
}

final class AvoidNullableInterpolationTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidNullableInterpolation();
    super.setUp();
  }

  Future<void> _nullableLocalLint() async {
    const source = r'''
void f(String? name) {
  print('Hello $name');
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('name\''), 'name'.length)]);
  }

  Future<void> _nonNullableLocalNoLint() async {
    await assertNoDiagnostics(r'''
void f(String name) {
  print('Hello $name');
}
''');
  }

  Future<void> _promotedNullableNoLint() async {
    await assertNoDiagnostics(r'''
void f(String? name) {
  if (name == null) return;
  print('Hello $name');
}
''');
  }
}

final class AvoidMissingInterpolationTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidMissingInterpolation();
    super.setUp();
  }

  Future<void> _matchesPriorLocalLint() async {
    const source = r'''
void f() {
  final total = 3;
  print('total');
}
''';

    await assertDiagnostics(source, [lint(source.indexOf("'total'"), "'total'".length)]);
  }

  Future<void> _matchesParameterLint() async {
    const source = r'''
void f(String label) {
  print('label');
}
''';

    await assertDiagnostics(source, [lint(source.indexOf("'label'"), "'label'".length)]);
  }

  Future<void> _structuralMapKeysNoLint() async {
    await assertNoDiagnostics(r'''
Map<String, Object> encode(int revision, String token) {
  final result = <String, Object>{'revision': revision, 'token': token};
  result['revision'] = revision + 1;
  print(result['token']);
  return result;
}
''');
  }

  Future<void> _mapValueLint() async {
    const source = r'''
Map<String, String> encode(String token) => {'value': 'token'};
''';
    await assertDiagnostics(source, [lint(source.indexOf("'token'"), 7)]);
  }

  Future<void> _coreErrorParameterNamesNoLint() async {
    await assertNoDiagnostics(r'''
void check(int count) {
  if (count == 0) throw ArgumentError('Must be positive', 'count');
}
''');
  }

  Future<void> _unrelatedErrorClassLint() async {
    const source = r'''
class ArgumentError {
  ArgumentError(Object value, String name);
}
void check(String count) => throw ArgumentError(count, 'count');
''';
    await assertDiagnostics(source, [lint(source.indexOf("'count'"), 7)]);
  }

  Future<void> _unrelatedNameParameterLint() async {
    const source = r'''
void display(String value, String name) {}
void check(String count) => display(count, 'count');
''';
    await assertDiagnostics(source, [lint(source.indexOf("'count'"), 7)]);
  }

  Future<void> _noLocalNameNoLint() async {
    await assertNoDiagnostics(r'''
void f() {
  print('total');
}
''');
  }

  Future<void> _notExactlyIdentifierNoLint() async {
    await assertNoDiagnostics(r'''
void f(String label) {
  print('hello label');
}
''');
  }

  Future<void> _laterLocalNoLint() async {
    await assertNoDiagnostics(r'''
void f() {
  print('total');
  final total = 3;
}
''');
  }
}

final class AvoidThrowObjectsWithoutToStringTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidThrowObjectsWithoutToString();
    super.setUp();
  }

  Future<void> _localClassWithoutToStringLint() async {
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

  Future<void> _localClassWithToStringNoLint() async {
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

  Future<void> _throwStringNoLint() async {
    await assertNoDiagnostics(r'''
void f() {
  throw 'failed';
}
''');
  }
}
