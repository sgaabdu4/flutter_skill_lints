import 'package:analyzer/error/error.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_unconditional_break.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_unnecessary_continue.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_unreachable_for_loop.dart';
import 'package:test/test.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<AvoidUnnecessaryContinueTest>(
    'AvoidUnnecessaryContinueTest',
    AvoidUnnecessaryContinueTest.new,
    {
      'test_continueAsLastBlockStatement_lint': (t) => t._continueAsLastBlockStatementLint(),
      'test_continueAsDirectLoopBody_lint': (t) => t._continueAsDirectLoopBodyLint(),
      'test_continueBeforeStatement_noLint': (t) => t._continueBeforeStatementNoLint(),
      'test_labeledContinue_noLint': (t) => t._labeledContinueNoLint(),
      'test_severity_error': (t) => t._severityError(),
    },
  );
  analysisRuleSuite<AvoidUnconditionalBreakTest>(
    'AvoidUnconditionalBreakTest',
    AvoidUnconditionalBreakTest.new,
    {
      'test_breakAsFirstLoopBlockStatement_lint': (t) => t._breakAsFirstLoopBlockStatementLint(),
      'test_breakAsDirectLoopBody_lint': (t) => t._breakAsDirectLoopBodyLint(),
      'test_breakAsFirstSwitchCaseStatement_lint': (t) => t._breakAsFirstSwitchCaseStatementLint(),
      'test_conditionalBreak_noLint': (t) => t._conditionalBreakNoLint(),
      'test_breakAfterStatement_noLint': (t) => t._breakAfterStatementNoLint(),
      'test_labeledBreak_noLint': (t) => t._labeledBreakNoLint(),
      'test_severity_info': (t) => t._severityInfo(),
    },
  );
  analysisRuleSuite<AvoidUnreachableForLoopTest>(
    'AvoidUnreachableForLoopTest',
    AvoidUnreachableForLoopTest.new,
    {
      'test_literalFalseCondition_lint': (t) => t._literalFalseConditionLint(),
      'test_literalTrueCondition_noLint': (t) => t._literalTrueConditionNoLint(),
      'test_missingCondition_noLint': (t) => t._missingConditionNoLint(),
      'test_nonLiteralFalseCondition_noLint': (t) => t._nonLiteralFalseConditionNoLint(),
      'test_severity_error': (t) => t._severityError(),
    },
  );
}

final class AvoidUnnecessaryContinueTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidUnnecessaryContinue();
    super.setUp();
  }

  Future<void> _continueAsLastBlockStatementLint() async {
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

  Future<void> _continueAsDirectLoopBodyLint() async {
    const source = r'''
void f() {
  while (true) continue;
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('continue'), 'continue'.length)]);
  }

  Future<void> _continueBeforeStatementNoLint() async {
    await assertNoDiagnostics(r'''
void f(List<int> values) {
  for (final value in values) {
    if (value.isEven) continue;
    print(value);
  }
}
''');
  }

  Future<void> _labeledContinueNoLint() async {
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

  Future<void> _severityError() async {
    expect(AvoidUnnecessaryContinue.code.severity, DiagnosticSeverity.ERROR);
  }
}

final class AvoidUnconditionalBreakTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidUnconditionalBreak();
    super.setUp();
  }

  Future<void> _breakAsFirstLoopBlockStatementLint() async {
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

  Future<void> _breakAsDirectLoopBodyLint() async {
    const source = r'''
void f() {
  while (true) break;
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('break'), 'break'.length)]);
  }

  Future<void> _breakAsFirstSwitchCaseStatementLint() async {
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

  Future<void> _conditionalBreakNoLint() async {
    await assertNoDiagnostics(r'''
void f(List<int> values) {
  for (final value in values) {
    if (value.isNegative) break;
    print(value);
  }
}
''');
  }

  Future<void> _breakAfterStatementNoLint() async {
    await assertNoDiagnostics(r'''
void f(List<int> values) {
  for (final value in values) {
    print(value);
    break;
  }
}
''');
  }

  Future<void> _labeledBreakNoLint() async {
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

  Future<void> _severityInfo() async {
    expect(AvoidUnconditionalBreak.code.severity, DiagnosticSeverity.INFO);
  }
}

final class AvoidUnreachableForLoopTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidUnreachableForLoop();
    super.setUp();
  }

  Future<void> _literalFalseConditionLint() async {
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

  Future<void> _literalTrueConditionNoLint() async {
    await assertNoDiagnostics(r'''
void f() {
  for (var i = 0; true; i++) {
    print(i);
  }
}
''');
  }

  Future<void> _missingConditionNoLint() async {
    await assertNoDiagnostics(r'''
void f() {
  for (;;) {
    print(1);
  }
}
''');
  }

  Future<void> _nonLiteralFalseConditionNoLint() async {
    await assertNoDiagnostics(r'''
void f(bool done) {
  for (var i = 0; done == false; i++) {
    print(i);
  }
}
''');
  }

  Future<void> _severityError() async {
    expect(AvoidUnreachableForLoop.code.severity, DiagnosticSeverity.ERROR);
  }
}
