// ignore_for_file: non_constant_identifier_names

import 'package:analyzer/error/error.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_continue.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_labels.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_local_functions.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidContinueTest);
    defineReflectiveTests(AvoidLabelsTest);
    defineReflectiveTests(AvoidLocalFunctionsTest);
  });
}

@reflectiveTest
final class AvoidContinueTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidContinue();
    super.setUp();
  }

  Future<void> test_continueStatement_lint() async {
    const source = r'''
void f(List<int> values) {
  for (final value in values) {
    if (value.isEven) continue;
    print(value);
  }
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('continue'), 'continue'.length)]);
  }

  Future<void> test_loopWithoutContinue_noLint() async {
    await assertNoDiagnostics(r'''
void f(List<int> values) {
  for (final value in values) {
    if (value.isOdd) {
      print(value);
    }
  }
}
''');
  }

  Future<void> test_severity_info() async {
    expect(AvoidContinue.code.severity, DiagnosticSeverity.INFO);
  }
}

@reflectiveTest
final class AvoidLabelsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidLabels();
    super.setUp();
  }

  Future<void> test_labeledStatement_lint() async {
    const source = r'''
void f() {
  retry:
  for (var i = 0; i < 2; i++) {
    if (i.isEven) {
      break retry;
    }
  }
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('retry:'), 'retry:'.length)]);
  }

  Future<void> test_labeledBreak_lint() async {
    const source = r'''
void f() {
  outer:
  for (var i = 0; i < 2; i++) {
    for (var j = 0; j < 2; j++) {
      if (j == i) {
        break outer;
      }
    }
  }
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('outer:'), 'outer:'.length)]);
  }

  Future<void> test_labeledContinue_lint() async {
    const source = r'''
void f() {
  outer:
  for (var i = 0; i < 2; i++) {
    for (var j = 0; j < 2; j++) {
      if (j == i) {
        continue outer;
      }
    }
  }
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('outer:'), 'outer:'.length)]);
  }

  Future<void> test_unlabeledBreakAndContinue_noLint() async {
    await assertNoDiagnostics(r'''
void f(List<int> values) {
  for (final value in values) {
    if (value.isNegative) break;
    if (value.isEven) continue;
    print(value);
  }
}
''');
  }

  Future<void> test_severity_error() async {
    expect(AvoidLabels.code.severity, DiagnosticSeverity.ERROR);
  }
}

@reflectiveTest
final class AvoidLocalFunctionsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidLocalFunctions();
    super.setUp();
  }

  Future<void> test_localFunction_lint() async {
    const source = r'''
void f() {
  int local(int value) => value + 1;
  print(local(1));
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('local'), 'local'.length)]);
  }

  Future<void> test_topLevelFunction_noLint() async {
    await assertNoDiagnostics(r'''
int helper(int value) => value + 1;

void f() {
  print(helper(1));
}
''');
  }

  Future<void> test_anonymousFunction_noLint() async {
    await assertNoDiagnostics(r'''
void f() {
  final values = [1, 2, 3].map((value) => value + 1);
  print(values);
}
''');
  }

  Future<void> test_severity_info() async {
    expect(AvoidLocalFunctions.code.severity, DiagnosticSeverity.INFO);
  }
}
