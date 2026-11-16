import 'package:analyzer/error/error.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_empty_spread.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_map_keys_contains.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_misused_set_literals.dart';
import 'package:test/test.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<_AvoidMapKeysContainsTest>(
    'AvoidMapKeysContainsTest',
    _AvoidMapKeysContainsTest.new,
    _AvoidMapKeysContainsTest._allCases,
  );
  analysisRuleSuite<_AvoidEmptySpreadTest>(
    'AvoidEmptySpreadTest',
    _AvoidEmptySpreadTest.new,
    _AvoidEmptySpreadTest._allCases,
  );
  analysisRuleSuite<_AvoidMisusedSetLiteralsTest>(
    'AvoidMisusedSetLiteralsTest',
    _AvoidMisusedSetLiteralsTest.new,
    _AvoidMisusedSetLiteralsTest._allCases,
  );
}

final class _AvoidMapKeysContainsTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidMapKeysContainsTest)> get _allCases =>
      caseSet<_AvoidMapKeysContainsTest>(
        parent: const {},
        own: {
          'test_complexTarget_lint': (t) => t._complexTargetLint(),
          'test_mapKeysContains_lint': (t) => t._mapKeysContainsLint(),
          'test_containsKey_noLint': (t) => t._containsKeyNoLint(),
          'test_iterableContains_noLint': (t) => t._iterableContainsNoLint(),
          'test_severity_error': (t) => t._severityError(),
        },
      );

  @override
  void setUp() {
    rule = AvoidMapKeysContains();
    super.setUp();
  }

  Future<void> _complexTargetLint() async {
    const source = r'''
class Holder {
  Map<String, int> get values => {'a': 1};
}

void f(Holder holder) {
  holder.values.keys.contains('a');
}
''';

    await assertDiagnostics(source, [
      lint(
        source.indexOf("holder.values.keys.contains('a')"),
        "holder.values.keys.contains('a')".length,
      ),
    ]);
  }

  Future<void> _mapKeysContainsLint() async {
    const source = r'''
void f(Map<String, int> values) {
  values.keys.contains('a');
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf("values.keys.contains('a')"), "values.keys.contains('a')".length),
    ]);
  }

  Future<void> _containsKeyNoLint() async {
    await assertNoDiagnostics(r'''
void f(Map<String, int> values) {
  values.containsKey('a');
}
''');
  }

  Future<void> _iterableContainsNoLint() async {
    await assertNoDiagnostics(r'''
void f(Iterable<String> values) {
  values.contains('a');
}
''');
  }

  Future<void> _severityError() async {
    expect(AvoidMapKeysContains.code.severity, DiagnosticSeverity.ERROR);
  }
}

final class _AvoidEmptySpreadTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidEmptySpreadTest)> get _allCases =>
      caseSet<_AvoidEmptySpreadTest>(
        parent: const {},
        own: {
          'test_emptyListSpread_lint': (t) => t._emptyListSpreadLint(),
          'test_emptyMapSpread_lint': (t) => t._emptyMapSpreadLint(),
          'test_emptySetSpread_lint': (t) => t._emptySetSpreadLint(),
          'test_nonEmptySpread_noLint': (t) => t._nonEmptySpreadNoLint(),
          'test_severity_error': (t) => t._severityError(),
        },
      );

  @override
  void setUp() {
    rule = AvoidEmptySpread();
    super.setUp();
  }

  Future<void> _emptyListSpreadLint() async {
    const source = r'''
void f() {
  final values = [1, ...[], 2];
  print(values);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('...[]'), '...[]'.length)]);
  }

  Future<void> _emptyMapSpreadLint() async {
    const source = r'''
void f() {
  final values = {'a': 1, ...{}};
  print(values);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('...{}'), '...{}'.length)]);
  }

  Future<void> _emptySetSpreadLint() async {
    const source = r'''
void f() {
  final values = {1, ...<int>{}};
  print(values);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('...<int>{}'), '...<int>{}'.length)]);
  }

  Future<void> _nonEmptySpreadNoLint() async {
    await assertNoDiagnostics(r'''
void f() {
  final list = [1, ...[2]];
  final set = {1, ...{2}};
  final map = {'a': 1, ...{'b': 2}};
  print([list, set, map]);
}
''');
  }

  Future<void> _severityError() async {
    expect(AvoidEmptySpread.code.severity, DiagnosticSeverity.ERROR);
  }
}

final class _AvoidMisusedSetLiteralsTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidMisusedSetLiteralsTest)> get _allCases =>
      caseSet<_AvoidMisusedSetLiteralsTest>(
        parent: const {},
        own: {
          'test_setLiteralAsExpressionStatement_lint': (t) =>
              t._setLiteralAsExpressionStatementLint(),
          'test_setLiteralInIfCondition_lint': (t) => t._setLiteralInIfConditionLint(),
          'test_setLiteralInWhenClause_lint': (t) => t._setLiteralInWhenClauseLint(),
          'test_setLiteralValue_noLint': (t) => t._setLiteralValueNoLint(),
          'test_setLiteralMethodCondition_noLint': (t) => t._setLiteralMethodConditionNoLint(),
          'test_severity_error': (t) => t._severityError(),
        },
      );

  @override
  void setUp() {
    rule = AvoidMisusedSetLiterals();
    super.setUp();
  }

  Future<void> _setLiteralAsExpressionStatementLint() async {
    const source = r'''
void f() {
  <int>{1};
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('<int>{1}'), '<int>{1}'.length)]);
  }

  Future<void> _setLiteralInIfConditionLint() async {
    const source = r'''
void f() {
  if ({1} as dynamic) {
    print('bad');
  }
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('{1}'), '{1}'.length)]);
  }

  Future<void> _setLiteralInWhenClauseLint() async {
    const source = r'''
void f(Object value) {
  switch (value) {
    case final value when {value} as dynamic:
      print(value);
  }
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('{value}'), '{value}'.length)]);
  }

  Future<void> _setLiteralValueNoLint() async {
    await assertNoDiagnostics(r'''
void f() {
  final values = {1, 2};
  print(values);
}
''');
  }

  Future<void> _setLiteralMethodConditionNoLint() async {
    await assertNoDiagnostics(r'''
void f() {
  if ({1, 2}.contains(1)) {
    print('ok');
  }
}
''');
  }

  Future<void> _severityError() async {
    expect(AvoidMisusedSetLiterals.code.severity, DiagnosticSeverity.ERROR);
  }
}
