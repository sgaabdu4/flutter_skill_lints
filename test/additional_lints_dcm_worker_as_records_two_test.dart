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
  final value = ('calendar', true, 3);
  print(value);
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf("'calendar'"), "'calendar'".length),
      lint(source.indexOf('true'), 'true'.length),
      lint(source.indexOf('3)'), 1),
    ]);
  }

  Future<void> test_skillPositionalPairAndWildcardDestructuring_noLint() async {
    await assertNoDiagnostics(r'''
(String, int) userInfo() => ('Alice', 30);

int wildcards(String id, String sku) {
  final (name, age) = userInfo();
  final (_, price, _) = (id, 9.99, sku);
  var total = 0.0;
  (_, total, _) = (id, price + age + name.length, sku);
  return total.round();
}
''');
  }

  Future<void> test_threePositionalFieldsBoundToVariable_lint() async {
    const source = r'''
(String, int, bool) profile() => throw 'todo';
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('String'), 'String'.length),
      lint(source.indexOf('int'), 'int'.length),
      lint(source.indexOf('bool'), 'bool'.length),
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

  Future<void> test_sdkFutureRecordWait_noLint() async {
    final asyncPath = '$dartSdkPath/lib/async/async.dart';
    newFile(asyncPath, '''
${getFile(asyncPath).readAsStringSync()}
extension FutureRecord2<T1, T2> on (Future<T1>, Future<T2>) {
  Future<(T1, T2)> get wait => throw UnimplementedError();
}
''');
    await assertNoDiagnostics(r'''
import 'dart:async';
Future<void> load() async {
  final (count, label) = await (Future.value(1), Future.value('ready')).wait;
  print('$count $label');
}
''');
  }

  Future<void> test_unrelatedWaitGetter_stillReports() async {
    const source = r'''
extension FakeWait on (int, String, bool) {
  int get wait => $1;
}
void load() {
  final count = (1, 'ready', true).wait;
  print(count);
}
''';
    await assertDiagnostics(source, [
      lint(source.indexOf('int, String'), 'int'.length),
      lint(source.indexOf('String,'), 'String'.length),
      lint(source.indexOf('bool)'), 'bool'.length),
      lint(source.indexOf('1, '), 1),
      lint(source.indexOf("'ready',"), "'ready'".length),
      lint(source.indexOf('true).wait'), 'true'.length),
    ]);
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
