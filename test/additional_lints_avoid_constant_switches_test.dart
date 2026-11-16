import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_constant_switches.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<AvoidConstantSwitchesTest>(
    'AvoidConstantSwitchesTest',
    AvoidConstantSwitchesTest.new,
    {
      'test_switchStatementOnIntLiteral': (t) => t._switchStatementOnIntLiteral(),
      'test_switchStatementOnStringLiteral': (t) => t._switchStatementOnStringLiteral(),
      'test_switchStatementOnConstVariable': (t) => t._switchStatementOnConstVariable(),
      'test_switchStatementOnStaticConstField': (t) => t._switchStatementOnStaticConstField(),
      'test_switchExpressionOnIntLiteral': (t) => t._switchExpressionOnIntLiteral(),
      'test_switchExpressionOnConstVariable': (t) => t._switchExpressionOnConstVariable(),
      'test_switchStatementOnBoolLiteral': (t) => t._switchStatementOnBoolLiteral(),
      'test_switchStatementOnNegativeNumber': (t) => t._switchStatementOnNegativeNumber(),
      'test_switchStatementOnParameter_noLint': (t) => t._switchStatementOnParameterNoLint(),
      'test_switchExpressionOnParameter_noLint': (t) => t._switchExpressionOnParameterNoLint(),
      'test_switchStatementOnMethodCall_noLint': (t) => t._switchStatementOnMethodCallNoLint(),
      'test_switchStatementOnNonConstFinal_noLint': (t) =>
          t._switchStatementOnNonConstFinalNoLint(),
      'test_switchStatementOnPropertyAccess_noLint': (t) =>
          t._switchStatementOnPropertyAccessNoLint(),
    },
  );
}

class AvoidConstantSwitchesTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidConstantSwitches();
    super.setUp();
  }

  Future<void> _switchStatementOnIntLiteral() async {
    await assertDiagnostics(
      r'''
void f() {
  switch (42) {
    case 42:
      break;
  }
}
''',
      [lint(21, 2)],
    );
  }

  Future<void> _switchStatementOnStringLiteral() async {
    await assertDiagnostics(
      r'''
void f() {
  switch ('hello') {
    case 'hello':
      break;
  }
}
''',
      [lint(21, 7)],
    );
  }

  Future<void> _switchStatementOnConstVariable() async {
    await assertDiagnostics(
      r'''
const x = 10;
void f() {
  switch (x) {
    case 10:
      break;
  }
}
''',
      [lint(35, 1)],
    );
  }

  Future<void> _switchStatementOnStaticConstField() async {
    await assertDiagnostics(
      r'''
abstract final class Config {
  static const value = '1';
}
void f() {
  switch (Config.value) {
    case '1':
      break;
    default:
      break;
  }
}
''',
      [lint(81, 12)],
    );
  }

  Future<void> _switchExpressionOnIntLiteral() async {
    await assertDiagnostics(
      r'''
void f() {
  final x = switch (42) {
    42 => 'yes',
    _ => 'no',
  };
}
''',
      [lint(31, 2)],
    );
  }

  Future<void> _switchExpressionOnConstVariable() async {
    await assertDiagnostics(
      r'''
const val = 'a';
void f() {
  final x = switch (val) {
    'a' => 1,
    _ => 2,
  };
}
''',
      [lint(48, 3)],
    );
  }

  Future<void> _switchStatementOnBoolLiteral() async {
    await assertDiagnostics(
      r'''
void f() {
  switch (true) {
    case true:
      break;
    default:
      break;
  }
}
''',
      [lint(21, 4)],
    );
  }

  Future<void> _switchStatementOnNegativeNumber() async {
    await assertDiagnostics(
      r'''
void f() {
  switch (-1) {
    case -1:
      break;
    default:
      break;
  }
}
''',
      [lint(21, 2)],
    );
  }

  Future<void> _switchStatementOnParameterNoLint() async {
    await assertNoDiagnostics(r'''
void f(int x) {
  switch (x) {
    case 1:
      break;
  }
}
''');
  }

  Future<void> _switchExpressionOnParameterNoLint() async {
    await assertNoDiagnostics(r'''
String f(int x) {
  return switch (x) {
    1 => 'one',
    _ => 'other',
  };
}
''');
  }

  Future<void> _switchStatementOnMethodCallNoLint() async {
    await assertNoDiagnostics(r'''
int getValue() => 1;
void f() {
  switch (getValue()) {
    case 1:
      break;
  }
}
''');
  }

  Future<void> _switchStatementOnNonConstFinalNoLint() async {
    await assertNoDiagnostics(r'''
void f(int x) {
  final y = x + 1;
  switch (y) {
    case 1:
      break;
  }
}
''');
  }

  Future<void> _switchStatementOnPropertyAccessNoLint() async {
    await assertNoDiagnostics(r'''
void f(List<int> list) {
  switch (list.length) {
    case 0:
      break;
  }
}
''');
  }
}
