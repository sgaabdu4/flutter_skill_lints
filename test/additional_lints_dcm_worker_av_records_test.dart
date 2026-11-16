import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_function_type_in_records.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_mixing_named_and_positional_fields.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_nested_records.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<AvoidNestedRecordsTest>('AvoidNestedRecordsTest', AvoidNestedRecordsTest.new, {
    'test_nestedLiteralPositionalField_lint': (t) => t._nestedLiteralPositionalFieldLint(),
    'test_nestedLiteralNamedField_lint': (t) => t._nestedLiteralNamedFieldLint(),
    'test_nestedTypeNamedField_lint': (t) => t._nestedTypeNamedFieldLint(),
    'test_flatRecords_noLint': (t) => t._flatRecordsNoLint(),
  });
  analysisRuleSuite<AvoidMixingNamedAndPositionalFieldsTest>(
    'AvoidMixingNamedAndPositionalFieldsTest',
    AvoidMixingNamedAndPositionalFieldsTest.new,
    {
      'test_recordLiteralMixedFields_lint': (t) => t._recordLiteralMixedFieldsLint(),
      'test_recordTypeMixedFields_lint': (t) => t._recordTypeMixedFieldsLint(),
      'test_singleStyleRecords_noLint': (t) => t._singleStyleRecordsNoLint(),
    },
  );
  analysisRuleSuite<AvoidFunctionTypeInRecordsTest>(
    'AvoidFunctionTypeInRecordsTest',
    AvoidFunctionTypeInRecordsTest.new,
    {
      'test_functionLiteralField_lint': (t) => t._functionLiteralFieldLint(),
      'test_genericFunctionTypeField_lint': (t) => t._genericFunctionTypeFieldLint(),
      'test_functionNamedTypeField_lint': (t) => t._functionNamedTypeFieldLint(),
      'test_valueFields_noLint': (t) => t._valueFieldsNoLint(),
    },
  );
}

final class AvoidNestedRecordsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidNestedRecords();
    super.setUp();
  }

  Future<void> _nestedLiteralPositionalFieldLint() async {
    const source = r'''
void f() {
  final value = ((1, 2), label: 'point');
  print(value);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('(1, 2)'), '(1, 2)'.length)]);
  }

  Future<void> _nestedLiteralNamedFieldLint() async {
    const source = r'''
void f() {
  final value = (point: (1, 2), label: 'point');
  print(value);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('(1, 2)'), '(1, 2)'.length)]);
  }

  Future<void> _nestedTypeNamedFieldLint() async {
    const source = r'''
typedef PointRecord = ({(int, int) point, String label});
''';

    await assertDiagnostics(source, [lint(source.indexOf('(int, int)'), '(int, int)'.length)]);
  }

  Future<void> _flatRecordsNoLint() async {
    await assertNoDiagnostics(r'''
typedef PointRecord = ({int x, int y});

void f() {
  final value = (x: 1, y: 2);
  print(value);
}
''');
  }
}

final class AvoidMixingNamedAndPositionalFieldsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidMixingNamedAndPositionalFields();
    super.setUp();
  }

  Future<void> _recordLiteralMixedFieldsLint() async {
    const source = r'''
void f() {
  final value = ('Ada', score: 10);
  print(value);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf("('Ada'"), "('Ada', score: 10)".length)]);
  }

  Future<void> _recordTypeMixedFieldsLint() async {
    const source = r'''
typedef UserRecord = (String, {int score});
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('(String'), '(String, {int score})'.length),
    ]);
  }

  Future<void> _singleStyleRecordsNoLint() async {
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

  Future<void> _genericFunctionTypeFieldLint() async {
    const source = r'''
typedef HandlerRecord = ({void Function(int value) onTap, String label});
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('void Function'), 'void Function(int value)'.length),
    ]);
  }

  Future<void> _functionNamedTypeFieldLint() async {
    const source = r'''
typedef HandlerRecord = ({Function onTap, String label});
''';

    await assertDiagnostics(source, [lint(source.indexOf('Function'), 'Function'.length)]);
  }

  Future<void> _valueFieldsNoLint() async {
    await assertNoDiagnostics(r'''
typedef LabelRecord = ({String label, int count});

void f() {
  final value = (label: 'count', count: 1);
  print(value);
}
''');
  }
}
