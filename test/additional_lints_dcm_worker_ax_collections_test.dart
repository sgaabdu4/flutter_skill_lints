// ignore_for_file: non_constant_identifier_names

import 'package:analyzer/error/error.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_empty_spread.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_map_keys_contains.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_misused_set_literals.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidMapKeysContainsTest);
    defineReflectiveTests(AvoidEmptySpreadTest);
    defineReflectiveTests(AvoidMisusedSetLiteralsTest);
  });
}

@reflectiveTest
final class AvoidMapKeysContainsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidMapKeysContains();
    super.setUp();
  }

  Future<void> test_complexTarget_lint() async {
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

  Future<void> test_mapKeysContains_lint() async {
    const source = r'''
void f(Map<String, int> values) {
  values.keys.contains('a');
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf("values.keys.contains('a')"), "values.keys.contains('a')".length),
    ]);
  }

  Future<void> test_containsKey_noLint() async {
    await assertNoDiagnostics(r'''
void f(Map<String, int> values) {
  values.containsKey('a');
}
''');
  }

  Future<void> test_iterableContains_noLint() async {
    await assertNoDiagnostics(r'''
void f(Iterable<String> values) {
  values.contains('a');
}
''');
  }

  Future<void> test_severity_error() async {
    expect(AvoidMapKeysContains.code.severity, DiagnosticSeverity.ERROR);
  }
}

@reflectiveTest
final class AvoidEmptySpreadTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidEmptySpread();
    super.setUp();
  }

  Future<void> test_emptyListSpread_lint() async {
    const source = r'''
void f() {
  final values = [1, ...[], 2];
  print(values);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('...[]'), '...[]'.length)]);
  }

  Future<void> test_emptyMapSpread_lint() async {
    const source = r'''
void f() {
  final values = {'a': 1, ...{}};
  print(values);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('...{}'), '...{}'.length)]);
  }

  Future<void> test_emptySetSpread_lint() async {
    const source = r'''
void f() {
  final values = {1, ...<int>{}};
  print(values);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('...<int>{}'), '...<int>{}'.length)]);
  }

  Future<void> test_nonEmptySpread_noLint() async {
    await assertNoDiagnostics(r'''
void f() {
  final list = [1, ...[2]];
  final set = {1, ...{2}};
  final map = {'a': 1, ...{'b': 2}};
  print([list, set, map]);
}
''');
  }

  Future<void> test_severity_error() async {
    expect(AvoidEmptySpread.code.severity, DiagnosticSeverity.ERROR);
  }
}

@reflectiveTest
final class AvoidMisusedSetLiteralsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidMisusedSetLiterals();
    super.setUp();
  }

  Future<void> test_setLiteralAsExpressionStatement_lint() async {
    const source = r'''
void f() {
  <int>{1};
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('<int>{1}'), '<int>{1}'.length)]);
  }

  Future<void> test_setLiteralInIfCondition_lint() async {
    const source = r'''
void f() {
  if ({1} as dynamic) {
    print('bad');
  }
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('{1}'), '{1}'.length)]);
  }

  Future<void> test_setLiteralInWhenClause_lint() async {
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

  Future<void> test_setLiteralValue_noLint() async {
    await assertNoDiagnostics(r'''
void f() {
  final values = {1, 2};
  print(values);
}
''');
  }

  Future<void> test_setLiteralMethodCondition_noLint() async {
    await assertNoDiagnostics(r'''
void f() {
  if ({1, 2}.contains(1)) {
    print('ok');
  }
}
''');
  }

  Future<void> test_severity_error() async {
    expect(AvoidMisusedSetLiterals.code.severity, DiagnosticSeverity.ERROR);
  }
}
