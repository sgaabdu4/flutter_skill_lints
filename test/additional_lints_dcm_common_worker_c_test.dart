// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_duplicate_collection_elements.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_mixing_named_and_positional_fields.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_unnecessary_digit_separators.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidDuplicateCollectionElementsTest);
    defineReflectiveTests(AvoidMixingNamedAndPositionalFieldsTest);
    defineReflectiveTests(AvoidUnnecessaryDigitSeparatorsTest);
  });
}

@reflectiveTest
final class AvoidDuplicateCollectionElementsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidDuplicateCollectionElements();
    super.setUp();
  }

  Future<void> test_constListDuplicateLiteral_lint() async {
    const source = r'''
const values = [1, 2, 1];
''';

    await assertDiagnostics(source, [lint(source.lastIndexOf('1'), 1)]);
  }

  Future<void> test_constListDuplicateString_lint() async {
    const source = r'''
const values = ['ready', 'ready'];
''';

    await assertDiagnostics(source, [lint(source.lastIndexOf("'ready'"), "'ready'".length)]);
  }

  Future<void> test_runtimeListDuplicateLiteral_noLint() async {
    await assertNoDiagnostics(r'''
final values = [1, 2, 1];
''');
  }

  Future<void> test_constCollectionDistinctElements_noLint() async {
    await assertNoDiagnostics(r'''
const values = [1, 2, 3];
const labels = {'ready': 1, 'done': 2};
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
final user = ('Ada', score: 10);
''';

    await assertDiagnostics(source, [lint(source.indexOf("('Ada'"), "('Ada', score: 10)".length)]);
  }

  Future<void> test_recordTypeMixedFields_lint() async {
    const source = r'''
(String, {int score})? user;
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('(String'), '(String, {int score})?'.length),
    ]);
  }

  Future<void> test_namedOnlyRecord_noLint() async {
    await assertNoDiagnostics(r'''
final user = (name: 'Ada', score: 10);
({String name, int score}) typed = (name: 'Ada', score: 10);
''');
  }

  Future<void> test_positionalOnlyRecord_noLint() async {
    await assertNoDiagnostics(r'''
final user = ('Ada', 10);
(String, int) typed = ('Ada', 10);
''');
  }
}

@reflectiveTest
final class AvoidUnnecessaryDigitSeparatorsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidUnnecessaryDigitSeparators();
    super.setUp();
  }

  Future<void> test_shortIntegerWithSeparator_lint() async {
    const source = r'''
const value = 1_0;
''';

    await assertDiagnostics(source, [lint(source.indexOf('1_0'), '1_0'.length)]);
  }

  Future<void> test_shortFractionWithSeparator_lint() async {
    const source = r'''
const value = 1_2.5;
''';

    await assertDiagnostics(source, [lint(source.indexOf('1_2.5'), '1_2.5'.length)]);
  }

  Future<void> test_groupedLargeNumber_noLint() async {
    await assertNoDiagnostics(r'''
const value = 1_000;
const hex = 0xFF_FF;
''');
  }

  Future<void> test_plainShortNumber_noLint() async {
    await assertNoDiagnostics(r'''
const value = 10;
const ratio = 12.5;
''');
  }
}
