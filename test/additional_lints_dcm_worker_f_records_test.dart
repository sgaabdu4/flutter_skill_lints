import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_function_type_in_records.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_long_records.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_nested_records.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<AvoidFunctionTypeInRecordsTest>(
    'AvoidFunctionTypeInRecordsTest',
    AvoidFunctionTypeInRecordsTest.new,
    {
      'test_functionLiteralField_lint': (t) => t._functionLiteralFieldLint(),
      'test_functionTypedField_lint': (t) => t._functionTypedFieldLint(),
      'test_valueFields_noLint': (t) => t._valueFieldsNoLint(),
    },
  );
  analysisRuleSuite<AvoidNestedRecordsTest>('AvoidNestedRecordsTest', AvoidNestedRecordsTest.new, {
    'test_nestedLiteralField_lint': (t) => t._nestedLiteralFieldLint(),
    'test_nestedTypeField_lint': (t) => t._nestedTypeFieldLint(),
    'test_flatRecord_noLint': (t) => t._flatRecordNoLint(),
  });
  analysisRuleSuite<AvoidLongRecordsTest>('AvoidLongRecordsTest', AvoidLongRecordsTest.new, {
    'test_fourFieldLiteral_lint': (t) => t._fourFieldLiteralLint(),
    'test_fourFieldType_lint': (t) => t._fourFieldTypeLint(),
    'test_threeFields_noLint': (t) => t._threeFieldsNoLint(),
  });
}

final class AvoidFunctionTypeInRecordsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidFunctionTypeInRecords();
    super.setUp();
  }

  Future<void> _functionLiteralFieldLint() async {
    const source = r'''
void f() {
  final value = (() => 1, label: 'count');
  print(value);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('() => 1'), '() => 1'.length)]);
  }

  Future<void> _functionTypedFieldLint() async {
    const source = r'''
typedef HandlerRecord = ({void Function() onTap, String label});
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('void Function()'), 'void Function()'.length),
    ]);
  }

  Future<void> _valueFieldsNoLint() async {
    await assertNoDiagnostics(r'''
typedef LabelRecord = ({String label, int count});

void f() {
  final value = (1, label: 'count');
  print(value);
}
''');
  }
}

final class AvoidNestedRecordsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidNestedRecords();
    super.setUp();
  }

  Future<void> _nestedLiteralFieldLint() async {
    const source = r'''
void f() {
  final value = ((1, 2), label: 'point');
  print(value);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('(1, 2)'), '(1, 2)'.length)]);
  }

  Future<void> _nestedTypeFieldLint() async {
    const source = r'''
typedef PointRecord = ((int, int), String);
''';

    await assertDiagnostics(source, [lint(source.indexOf('(int, int)'), '(int, int)'.length)]);
  }

  Future<void> _flatRecordNoLint() async {
    await assertNoDiagnostics(r'''
typedef PointRecord = ({int x, int y});

void f() {
  final value = (1, y: 2);
  print(value);
}
''');
  }
}

final class AvoidLongRecordsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidLongRecords();
    super.setUp();
  }

  Future<void> _fourFieldLiteralLint() async {
    const source = r'''
void f() {
  final value = (1, 2, 3, 4);
  print(value);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('(1, 2, 3, 4)'), '(1, 2, 3, 4)'.length)]);
  }

  Future<void> _fourFieldTypeLint() async {
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

  Future<void> _threeFieldsNoLint() async {
    await assertNoDiagnostics(r'''
typedef UserRecord = ({String id, String name, int age});

void f() {
  final value = (1, label: 'count', active: true);
  print(value);
}
''');
  }
}
