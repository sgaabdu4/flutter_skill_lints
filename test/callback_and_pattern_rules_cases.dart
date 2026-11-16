import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_async_callback.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_simpler_patterns_null_check.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<PreferAsyncCallbackTest>(
    'PreferAsyncCallbackTest',
    PreferAsyncCallbackTest.new,
    {
      'reportsFieldType': (t) => t.reportsFieldType(),
      'reportsParameterType': (t) => t.reportsParameterType(),
      'acceptsOtherFutureTypes': (t) => t.acceptsOtherFutureTypes(),
      'acceptsFunctionsWithParametersOrTypeParameters': (t) =>
          t.acceptsFunctionsWithParametersOrTypeParameters(),
      'acceptsTypedefDeclarations': (t) => t.acceptsTypedefDeclarations(),
      'acceptsOtherReturnTypes': (t) => t.acceptsOtherReturnTypes(),
    },
  );
  analysisRuleSuite<PreferSimplerPatternsNullCheckTest>(
    'PreferSimplerPatternsNullCheckTest',
    PreferSimplerPatternsNullCheckTest.new,
    {
      'reportsNullCheckWithVariable': (t) => t.reportsNullCheckWithVariable(),
      'reportsNullCheckWithTypedVariable': (t) => t.reportsNullCheckWithTypedVariable(),
      'acceptsNullCheckPattern': (t) => t.acceptsNullCheckPattern(),
      'acceptsOtherComparisons': (t) => t.acceptsOtherComparisons(),
      'acceptsOtherRightOperands': (t) => t.acceptsOtherRightOperands(),
      'acceptsIfWithoutCase': (t) => t.acceptsIfWithoutCase(),
    },
  );
}

final class PreferAsyncCallbackTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferAsyncCallback();
    super.setUp();
  }

  Future<void> reportsFieldType() async {
    const source = 'class A {\n  Future<void> Function()? onTap;\n}\n';
    const type = 'Future<void> Function()?';
    await assertDiagnostics(source, [lint(source.indexOf(type), type.length)]);
  }

  Future<void> reportsParameterType() async {
    const source = 'void run(Future<void> Function() action) {}\n';
    const type = 'Future<void> Function()';
    await assertDiagnostics(source, [lint(source.indexOf(type), type.length)]);
  }

  Future<void> acceptsOtherFutureTypes() => assertNoDiagnostics('''
void run(
  Future<int> Function() count,
  Future Function() raw,
  Future<List<void>> Function() nested,
  Future<(int, int)> Function() pair,
) {}
''');

  Future<void> acceptsFunctionsWithParametersOrTypeParameters() => assertNoDiagnostics('''
void run(
  Future<void> Function(int value) withParameter,
  Future<void> Function<T>() generic,
) {}
''');

  Future<void> acceptsTypedefDeclarations() => assertNoDiagnostics('''
typedef Action = Future<void> Function();
''');

  Future<void> acceptsOtherReturnTypes() => assertNoDiagnostics('''
void run(void Function() plain, (int, int) Function() record, Object Function() any) {}
''');
}

final class PreferSimplerPatternsNullCheckTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferSimplerPatternsNullCheck();
    super.setUp();
  }

  Future<void> _expectReported(String pattern) async {
    final source = 'void f(int? value) {\n  if (value case $pattern) {}\n}\n';
    await assertDiagnostics(source, [lint(source.indexOf(pattern), pattern.length)]);
  }

  Future<void> reportsNullCheckWithVariable() => _expectReported('!= null && final x');

  Future<void> reportsNullCheckWithTypedVariable() => _expectReported('!= null && final int x');

  Future<void> acceptsNullCheckPattern() => assertNoDiagnostics('''
void f(int? value) {
  if (value case final x?) {}
}
''');

  Future<void> acceptsOtherComparisons() => assertNoDiagnostics('''
void f(int? value) {
  if (value case != 0 && final x) {}
  if (value case == null && final y) {}
}
''');

  Future<void> acceptsOtherRightOperands() => assertNoDiagnostics('''
void f(int? value) {
  if (value case != null && > 1) {}
  if (value case int() || null) {}
}
''');

  Future<void> acceptsIfWithoutCase() => assertNoDiagnostics('''
void f(int? value) {
  if (value != null) {}
}
''');
}
