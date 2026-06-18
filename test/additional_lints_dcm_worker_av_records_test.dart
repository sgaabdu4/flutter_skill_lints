// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_function_type_in_records.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_mixing_named_and_positional_fields.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_nested_records.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidNestedRecordsTest);
    defineReflectiveTests(AvoidMixingNamedAndPositionalFieldsTest);
    defineReflectiveTests(AvoidFunctionTypeInRecordsTest);
  });
}

@reflectiveTest
final class AvoidNestedRecordsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidNestedRecords();
    super.setUp();
  }

  Future<void> test_nestedLiteralPositionalField_lint() async {
    const source = r'''
void f() {
  final value = ((1, 2), label: 'point');
  print(value);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('(1, 2)'), '(1, 2)'.length)]);
  }

  Future<void> test_nestedLiteralNamedField_lint() async {
    const source = r'''
void f() {
  final value = (point: (1, 2), label: 'point');
  print(value);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('(1, 2)'), '(1, 2)'.length)]);
  }

  Future<void> test_nestedTypeNamedField_lint() async {
    const source = r'''
typedef PointRecord = ({(int, int) point, String label});
''';

    await assertDiagnostics(source, [lint(source.indexOf('(int, int)'), '(int, int)'.length)]);
  }

  Future<void> test_flatRecords_noLint() async {
    await assertNoDiagnostics(r'''
typedef PointRecord = ({int x, int y});

void f() {
  final value = (x: 1, y: 2);
  print(value);
}
''');
  }
}

@reflectiveTest
final class AvoidMixingNamedAndPositionalFieldsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidMixingNamedAndPositionalFields();
    super.setUp();
  }

  Future<void> test_recordLiteralMixedFields_lint() async {
    const source = r'''
void f() {
  final value = ('Ada', score: 10);
  print(value);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf("('Ada'"), "('Ada', score: 10)".length)]);
  }

  Future<void> test_recordTypeMixedFields_lint() async {
    const source = r'''
typedef UserRecord = (String, {int score});
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('(String'), '(String, {int score})'.length),
    ]);
  }

  Future<void> test_singleStyleRecords_noLint() async {
    await assertNoDiagnostics(r'''
typedef NamedRecord = ({String name, int score});
typedef PositionalRecord = (String, int);

void f() {
  final named = (name: 'Ada', score: 10);
  final positional = ('Ada', 10);
  print((named, positional));
}
''');
  }
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

  Future<void> test_genericFunctionTypeField_lint() async {
    const source = r'''
typedef HandlerRecord = ({void Function(int value) onTap, String label});
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('void Function'), 'void Function(int value)'.length),
    ]);
  }

  Future<void> test_functionNamedTypeField_lint() async {
    const source = r'''
typedef HandlerRecord = ({Function onTap, String label});
''';

    await assertDiagnostics(source, [lint(source.indexOf('Function'), 'Function'.length)]);
  }

  Future<void> test_valueFields_noLint() async {
    await assertNoDiagnostics(r'''
typedef LabelRecord = ({String label, int count});

void f() {
  final value = (label: 'count', count: 1);
  print(value);
}
''');
  }
}
