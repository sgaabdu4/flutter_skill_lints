import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_duplicate_collection_elements.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_mixing_named_and_positional_fields.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_unnecessary_digit_separators.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<_AvoidDuplicateCollectionElementsTest>(
    'AvoidDuplicateCollectionElementsTest',
    _AvoidDuplicateCollectionElementsTest.new,
    _AvoidDuplicateCollectionElementsTest._allCases,
  );
  analysisRuleSuite<_AvoidMixingNamedAndPositionalFieldsTest>(
    'AvoidMixingNamedAndPositionalFieldsTest',
    _AvoidMixingNamedAndPositionalFieldsTest.new,
    _AvoidMixingNamedAndPositionalFieldsTest._allCases,
  );
  analysisRuleSuite<_AvoidUnnecessaryDigitSeparatorsTest>(
    'AvoidUnnecessaryDigitSeparatorsTest',
    _AvoidUnnecessaryDigitSeparatorsTest.new,
    _AvoidUnnecessaryDigitSeparatorsTest._allCases,
  );
}

final class _AvoidDuplicateCollectionElementsTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidDuplicateCollectionElementsTest)> get _allCases =>
      caseSet<_AvoidDuplicateCollectionElementsTest>(
        parent: const {},
        own: {
          'test_constListDuplicateLiteral_lint': (t) => t._constListDuplicateLiteralLint(),
          'test_constListDuplicateString_lint': (t) => t._constListDuplicateStringLint(),
          'test_runtimeListDuplicateLiteral_noLint': (t) => t._runtimeListDuplicateLiteralNoLint(),
          'test_constCollectionDistinctElements_noLint': (t) =>
              t._constCollectionDistinctElementsNoLint(),
        },
      );

  @override
  void setUp() {
    rule = AvoidDuplicateCollectionElements();
    super.setUp();
  }

  Future<void> _constListDuplicateLiteralLint() async {
    const source = r'''
const values = [1, 2, 1];
''';

    await assertDiagnostics(source, [lint(source.lastIndexOf('1'), 1)]);
  }

  Future<void> _constListDuplicateStringLint() async {
    const source = r'''
const values = ['ready', 'ready'];
''';

    await assertDiagnostics(source, [lint(source.lastIndexOf("'ready'"), "'ready'".length)]);
  }

  Future<void> _runtimeListDuplicateLiteralNoLint() async {
    await assertNoDiagnostics(r'''
final values = [1, 2, 1];
''');
  }

  Future<void> _constCollectionDistinctElementsNoLint() async {
    await assertNoDiagnostics(r'''
const values = [1, 2, 3];
const labels = {'ready': 1, 'done': 2};
''');
  }
}

final class _AvoidMixingNamedAndPositionalFieldsTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidMixingNamedAndPositionalFieldsTest)>
  get _allCases => caseSet<_AvoidMixingNamedAndPositionalFieldsTest>(
    parent: const {},
    own: {
      'test_recordLiteralMixedFields_lint': (t) => t._recordLiteralMixedFieldsLint(),
      'test_recordTypeMixedFields_lint': (t) => t._recordTypeMixedFieldsLint(),
      'test_namedOnlyRecord_noLint': (t) => t._namedOnlyRecordNoLint(),
      'test_positionalOnlyRecord_noLint': (t) => t._positionalOnlyRecordNoLint(),
    },
  );

  @override
  void setUp() {
    rule = AvoidMixingNamedAndPositionalFields();
    super.setUp();
  }

  Future<void> _recordLiteralMixedFieldsLint() async {
    const source = r'''
final user = ('Ada', score: 10);
''';

    await assertDiagnostics(source, [lint(source.indexOf("('Ada'"), "('Ada', score: 10)".length)]);
  }

  Future<void> _recordTypeMixedFieldsLint() async {
    const source = r'''
(String, {int score})? user;
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('(String'), '(String, {int score})?'.length),
    ]);
  }

  Future<void> _namedOnlyRecordNoLint() async {
    await assertNoDiagnostics(r'''
final user = (name: 'Ada', score: 10);
({String name, int score}) typed = (name: 'Ada', score: 10);
''');
  }

  Future<void> _positionalOnlyRecordNoLint() async {
    await assertNoDiagnostics(r'''
final user = ('Ada', 10);
(String, int) typed = ('Ada', 10);
''');
  }
}

final class _AvoidUnnecessaryDigitSeparatorsTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidUnnecessaryDigitSeparatorsTest)> get _allCases =>
      caseSet<_AvoidUnnecessaryDigitSeparatorsTest>(
        parent: const {},
        own: {
          'test_shortIntegerWithSeparator_lint': (t) => t._shortIntegerWithSeparatorLint(),
          'test_shortFractionWithSeparator_lint': (t) => t._shortFractionWithSeparatorLint(),
          'test_groupedLargeNumber_noLint': (t) => t._groupedLargeNumberNoLint(),
          'test_plainShortNumber_noLint': (t) => t._plainShortNumberNoLint(),
        },
      );

  @override
  void setUp() {
    rule = AvoidUnnecessaryDigitSeparators();
    super.setUp();
  }

  Future<void> _shortIntegerWithSeparatorLint() async {
    const source = r'''
const value = 1_0;
''';

    await assertDiagnostics(source, [lint(source.indexOf('1_0'), '1_0'.length)]);
  }

  Future<void> _shortFractionWithSeparatorLint() async {
    const source = r'''
const value = 1_2.5;
''';

    await assertDiagnostics(source, [lint(source.indexOf('1_2.5'), '1_2.5'.length)]);
  }

  Future<void> _groupedLargeNumberNoLint() async {
    await assertNoDiagnostics(r'''
const value = 1_000;
const hex = 0xFF_FF;
''');
  }

  Future<void> _plainShortNumberNoLint() async {
    await assertNoDiagnostics(r'''
const value = 10;
const ratio = 12.5;
''');
  }
}
