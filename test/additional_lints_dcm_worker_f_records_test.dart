// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_function_type_in_records.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_long_records.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_nested_records.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidFunctionTypeInRecordsTest);
    defineReflectiveTests(AvoidNestedRecordsTest);
    defineReflectiveTests(AvoidLongRecordsTest);
  });
}

@reflectiveTest
final class AvoidFunctionTypeInRecordsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidFunctionTypeInRecords();
    super.setUp();
  }

  Future<void> test_functionLiteralField_lint() async {
    const source = r'''
void f() {
  final value = (() => 1, label: 'count');
  print(value);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('() => 1'), '() => 1'.length)]);
  }

  Future<void> test_functionTypedField_lint() async {
    const source = r'''
typedef HandlerRecord = ({void Function() onTap, String label});
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('void Function()'), 'void Function()'.length),
    ]);
  }

  Future<void> test_valueFields_noLint() async {
    await assertNoDiagnostics(r'''
typedef LabelRecord = ({String label, int count});

void f() {
  final value = (1, label: 'count');
  print(value);
}
''');
  }
}

@reflectiveTest
final class AvoidNestedRecordsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidNestedRecords();
    super.setUp();
  }

  Future<void> test_nestedLiteralField_lint() async {
    const source = r'''
void f() {
  final value = ((1, 2), label: 'point');
  print(value);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('(1, 2)'), '(1, 2)'.length)]);
  }

  Future<void> test_nestedTypeField_lint() async {
    const source = r'''
typedef PointRecord = ((int, int), String);
''';

    await assertDiagnostics(source, [lint(source.indexOf('(int, int)'), '(int, int)'.length)]);
  }

  Future<void> test_flatRecord_noLint() async {
    await assertNoDiagnostics(r'''
typedef PointRecord = ({int x, int y});

void f() {
  final value = (1, y: 2);
  print(value);
}
''');
  }
}

@reflectiveTest
final class AvoidLongRecordsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidLongRecords();
    super.setUp();
  }

  Future<void> test_fourFieldLiteral_lint() async {
    const source = r'''
void f() {
  final value = (1, 2, 3, 4);
  print(value);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('(1, 2, 3, 4)'), '(1, 2, 3, 4)'.length)]);
  }

  Future<void> test_fourFieldType_lint() async {
    const source = r'''
typedef UserRecord = ({String id, String name, int age, bool active});
''';

    await assertDiagnostics(source, [
      lint(
        source.indexOf('({String id'),
        '({String id, String name, int age, bool active})'.length,
      ),
    ]);
  }

  Future<void> test_threeFields_noLint() async {
    await assertNoDiagnostics(r'''
typedef UserRecord = ({String id, String name, int age});

void f() {
  final value = (1, label: 'count', active: true);
  print(value);
}
''');
  }
}
