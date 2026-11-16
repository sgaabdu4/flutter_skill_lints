import 'package:flutter_skill_lints/src/additional_lints/fixes/use_existing_variable_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/use_existing_variable.dart';

import 'analysis_rule_suite.dart';
import 'fix_test_support.dart';

void main() {
  analysisRuleSuite<_UseExistingVariableTest>(
    'UseExistingVariableTest',
    _UseExistingVariableTest.new,
    {
      'reportsRepeatedExpression': (t) => t._reportsRepeatedExpression(),
      'ignoresTrivialInitializers': (t) => t._ignoresTrivialInitializers(),
      'ignoresNonFinalVariables': (t) => t._ignoresNonFinalVariables(),
      'forgetsVariablesAfterSideEffects': (t) => t._forgetsVariablesAfterSideEffects(),
      'ignoresDifferentExpressions': (t) => t._ignoresDifferentExpressions(),
      'replacesRepeatedExpressionWithVariable': (t) => t._replacesRepeatedExpressionWithVariable(),
    },
  );
}

final class _UseExistingVariableTest extends FixRuleTest {
  @override
  void setUp() {
    rule = UseExistingVariable();
    super.setUp();
  }

  static const _repeated = '''
int f(int a, int b) {
  final c = a * b + 1;
  final d = a * b + 1;
  return c + d;
}
''';

  Future<void> _reportsRepeatedExpression() async {
    const source = _repeated;
    await assertDiagnostics(source, [lint(source.lastIndexOf('a * b + 1'), 'a * b + 1'.length)]);
  }

  Future<void> _ignoresTrivialInitializers() => assertNoDiagnostics('''
int f(int a) {
  final c = a;
  final d = a;
  final e = 1;
  final g = 1;
  final h = [1];
  final i = [1];
  return c + d + e + g + h.length + i.length;
}
''');

  Future<void> _ignoresNonFinalVariables() => assertNoDiagnostics('''
int f(int a, int b) {
  var c = a * b + 1;
  var d = a * b + 1;
  return c + d;
}
''');

  Future<void> _forgetsVariablesAfterSideEffects() => assertNoDiagnostics('''
void touch() {}

int f(int a, int b) {
  final c = a * b + 1;
  touch();
  final d = a * b + 1;
  return c + d;
}
''');

  Future<void> _ignoresDifferentExpressions() => assertNoDiagnostics('''
int f(int a, int b) {
  final c = a * b + 1;
  final d = a * b + 2;
  return c + d;
}
''');

  Future<void> _replacesRepeatedExpressionWithVariable() => expectFix(
    _repeated,
    (context) => UseExistingVariableFix(context: context),
    expected: '''
int f(int a, int b) {
  final c = a * b + 1;
  final d = c;
  return c + d;
}
''',
  );
}
