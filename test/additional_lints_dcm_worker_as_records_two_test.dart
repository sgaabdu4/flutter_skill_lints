// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_one_field_records.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_positional_record_field_access.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_positional_record_fields.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_redundant_positional_field_name.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidOneFieldRecordsTest);
    defineReflectiveTests(AvoidPositionalRecordFieldsTest);
    defineReflectiveTests(AvoidPositionalRecordFieldAccessTest);
    defineReflectiveTests(AvoidRedundantPositionalFieldNameTest);
  });
}

@reflectiveTest
final class AvoidOneFieldRecordsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidOneFieldRecords();
    super.setUp();
  }

  Future<void> test_oneNamedFieldLiteral_lint() async {
    const source = r'''
void f() {
  final value = (id: 1);
  print(value);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('(id: 1)'), '(id: 1)'.length)]);
  }

  Future<void> test_onePositionalFieldType_lint() async {
    const source = r'''
typedef IdRecord = (int,);
''';

    await assertDiagnostics(source, [lint(source.indexOf('(int,)'), '(int,)'.length)]);
  }

  Future<void> test_parenthesizedExpression_noLint() async {
    await assertNoDiagnostics(r'''
void f() {
  final value = (1);
  print(value);
}
''');
  }

  Future<void> test_twoFieldRecords_noLint() async {
    await assertNoDiagnostics(r'''
typedef PointRecord = ({int x, int y});

void f() {
  final value = (1, 2);
  print(value);
}
''');
  }
}

@reflectiveTest
final class AvoidPositionalRecordFieldsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidPositionalRecordFields();
    super.setUp();
  }

  Future<void> test_positionalLiteral_lint() async {
    const source = r'''
void f() {
  final value = ('calendar', true);
  print(value);
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf("'calendar'"), "'calendar'".length),
      lint(source.indexOf('true'), 'true'.length),
    ]);
  }

  Future<void> test_positionalType_lint() async {
    const source = r'''
typedef PreferencesProjection = (bool?, bool?, bool?);
''';
    final first = source.indexOf('bool?');
    final second = source.indexOf('bool?', first + 1);
    final third = source.indexOf('bool?', second + 1);

    await assertDiagnostics(source, [
      lint(first, 'bool?'.length),
      lint(second, 'bool?'.length),
      lint(third, 'bool?'.length),
    ]);
  }

  Future<void> test_namedRecord_noLint() async {
    await assertNoDiagnostics(r'''
typedef PreferencesProjection = ({bool? calendar, bool? loggedExercises, bool? recentSessions});

void f() {
  PreferencesProjection value = (calendar: true, loggedExercises: null, recentSessions: false);
  print(value);
}
''');
  }
}

@reflectiveTest
final class AvoidPositionalRecordFieldAccessTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidPositionalRecordFieldAccess();
    super.setUp();
  }

  Future<void> test_prefixedIdentifier_lint() async {
    const source = r'''
void f((int, String) value) {
  print(value.$1);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf(r'$1'), r'$1'.length)]);
  }

  Future<void> test_propertyAccess_lint() async {
    const source = r'''
void f((int, String) value) {
  print((value).$2);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf(r'$2'), r'$2'.length)]);
  }

  Future<void> test_namedRecordAccess_noLint() async {
    await assertNoDiagnostics(r'''
void f(({int id, String label}) value) {
  print(value.id);
}
''');
  }

  Future<void> test_nonRecordDollarGetter_noLint() async {
    await assertNoDiagnostics(r'''
class Value {
  int get $1 => 1;
}

void f(Value value) {
  print(value.$1);
}
''');
  }
}

@reflectiveTest
final class AvoidRedundantPositionalFieldNameTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidRedundantPositionalFieldName();
    super.setUp();
  }

  Future<void> test_positionalFieldName_lint() async {
    const source = r'''
typedef PointRecord = (int x, int y);
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('x,'), 'x'.length),
      lint(source.indexOf('y)'), 'y'.length),
    ]);
  }

  Future<void> test_namedFields_noLint() async {
    await assertNoDiagnostics(r'''
typedef PointRecord = ({int x, int y});
''');
  }

  Future<void> test_unnamedPositionalFields_noLint() async {
    await assertNoDiagnostics(r'''
typedef PointRecord = (int, int);
''');
  }
}
