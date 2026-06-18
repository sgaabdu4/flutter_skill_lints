// ignore_for_file: non_constant_identifier_names

import 'package:analyzer/error/error.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_unconditional_break.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_unnecessary_continue.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_unreachable_for_loop.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidUnnecessaryContinueTest);
    defineReflectiveTests(AvoidUnconditionalBreakTest);
    defineReflectiveTests(AvoidUnreachableForLoopTest);
  });
}

@reflectiveTest
final class AvoidUnnecessaryContinueTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidUnnecessaryContinue();
    super.setUp();
  }

  Future<void> test_continueAsLastBlockStatement_lint() async {
    const source = r'''
void f(List<int> values) {
  for (final value in values) {
    print(value);
    continue;
  }
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('continue'), 'continue'.length)]);
  }

  Future<void> test_continueAsDirectLoopBody_lint() async {
    const source = r'''
void f() {
  while (true) continue;
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('continue'), 'continue'.length)]);
  }

  Future<void> test_continueBeforeStatement_noLint() async {
    await assertNoDiagnostics(r'''
void f(List<int> values) {
  for (final value in values) {
    if (value.isEven) continue;
    print(value);
  }
}
''');
  }

  Future<void> test_labeledContinue_noLint() async {
    await assertNoDiagnostics(r'''
// ignore_for_file: dead_code

void f(List<int> values) {
  outer:
  for (final value in values) {
    for (var i = 0; i < value; i++) {
      if (i.isEven) continue outer;
      print(i);
    }
  }
}
''');
  }

  Future<void> test_severity_error() async {
    expect(AvoidUnnecessaryContinue.code.severity, DiagnosticSeverity.ERROR);
  }
}

@reflectiveTest
final class AvoidUnconditionalBreakTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidUnconditionalBreak();
    super.setUp();
  }

  Future<void> test_breakAsFirstLoopBlockStatement_lint() async {
    const source = r'''
// ignore_for_file: dead_code

void f(List<int> values) {
  for (final value in values) {
    break;
  }
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('break'), 'break'.length)]);
  }

  Future<void> test_breakAsDirectLoopBody_lint() async {
    const source = r'''
void f() {
  while (true) break;
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('break'), 'break'.length)]);
  }

  Future<void> test_breakAsFirstSwitchCaseStatement_lint() async {
    const source = r'''
void f(int value) {
  switch (value) {
    case 1:
      break;
    default:
      print(value);
  }
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('break'), 'break'.length)]);
  }

  Future<void> test_conditionalBreak_noLint() async {
    await assertNoDiagnostics(r'''
void f(List<int> values) {
  for (final value in values) {
    if (value.isNegative) break;
    print(value);
  }
}
''');
  }

  Future<void> test_breakAfterStatement_noLint() async {
    await assertNoDiagnostics(r'''
void f(List<int> values) {
  for (final value in values) {
    print(value);
    break;
  }
}
''');
  }

  Future<void> test_labeledBreak_noLint() async {
    await assertNoDiagnostics(r'''
void f(List<int> values) {
  outer:
  for (final value in values) {
    while (value.isEven) {
      break outer;
    }
  }
}
''');
  }

  Future<void> test_severity_info() async {
    expect(AvoidUnconditionalBreak.code.severity, DiagnosticSeverity.INFO);
  }
}

@reflectiveTest
final class AvoidUnreachableForLoopTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidUnreachableForLoop();
    super.setUp();
  }

  Future<void> test_literalFalseCondition_lint() async {
    const source = r'''
// ignore_for_file: dead_code

void f() {
  for (var i = 0; false; i++) {
    print(i);
  }
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('false'), 'false'.length)]);
  }

  Future<void> test_literalTrueCondition_noLint() async {
    await assertNoDiagnostics(r'''
void f() {
  for (var i = 0; true; i++) {
    print(i);
  }
}
''');
  }

  Future<void> test_missingCondition_noLint() async {
    await assertNoDiagnostics(r'''
void f() {
  for (;;) {
    print(1);
  }
}
''');
  }

  Future<void> test_nonLiteralFalseCondition_noLint() async {
    await assertNoDiagnostics(r'''
void f(bool done) {
  for (var i = 0; done == false; i++) {
    print(i);
  }
}
''');
  }

  Future<void> test_severity_error() async {
    expect(AvoidUnreachableForLoop.code.severity, DiagnosticSeverity.ERROR);
  }
}
