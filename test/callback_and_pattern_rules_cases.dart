import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_async_callback.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_simpler_patterns_null_check.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<_PreferAsyncCallbackTest>(
    'PreferAsyncCallbackTest',
    _PreferAsyncCallbackTest.new,
    {
      'reportsFieldType': (t) => t._reportsFieldType(),
      'reportsParameterType': (t) => t._reportsParameterType(),
      'acceptsOtherFutureTypes': (t) => t._acceptsOtherFutureTypes(),
      'acceptsFunctionsWithParametersOrTypeParameters': (t) =>
          t._acceptsFunctionsWithParametersOrTypeParameters(),
      'acceptsTypedefDeclarations': (t) => t._acceptsTypedefDeclarations(),
      'acceptsOtherReturnTypes': (t) => t._acceptsOtherReturnTypes(),
    },
  );
  analysisRuleSuite<_PreferSimplerPatternsNullCheckTest>(
    'PreferSimplerPatternsNullCheckTest',
    _PreferSimplerPatternsNullCheckTest.new,
    {
      'reportsNullCheckWithVariable': (t) => t._reportsNullCheckWithVariable(),
      'reportsNullCheckWithTypedVariable': (t) => t._reportsNullCheckWithTypedVariable(),
      'acceptsNullCheckPattern': (t) => t._acceptsNullCheckPattern(),
      'acceptsOtherComparisons': (t) => t._acceptsOtherComparisons(),
      'acceptsOtherRightOperands': (t) => t._acceptsOtherRightOperands(),
      'acceptsIfWithoutCase': (t) => t._acceptsIfWithoutCase(),
    },
  );
}

final class _PreferAsyncCallbackTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferAsyncCallback();
    super.setUp();
  }

  Future<void> _reportsFieldType() async {
    const source = 'class A {\n  Future<void> Function()? onTap;\n}\n';
    const type = 'Future<void> Function()?';
    await assertDiagnostics(source, [lint(source.indexOf(type), type.length)]);
  }

  Future<void> _reportsParameterType() async {
    const source = 'void run(Future<void> Function() action) {}\n';
    const type = 'Future<void> Function()';
    await assertDiagnostics(source, [lint(source.indexOf(type), type.length)]);
  }

  Future<void> _acceptsOtherFutureTypes() => assertNoDiagnostics('''
void run(
  Future<int> Function() count,
  Future Function() raw,
  Future<List<void>> Function() nested,
  Future<(int, int)> Function() pair,
) {}
''');

  Future<void> _acceptsFunctionsWithParametersOrTypeParameters() => assertNoDiagnostics('''
void run(
  Future<void> Function(int value) withParameter,
  Future<void> Function<T>() generic,
) {}
''');

  Future<void> _acceptsTypedefDeclarations() => assertNoDiagnostics('''
typedef Action = Future<void> Function();
''');

  Future<void> _acceptsOtherReturnTypes() => assertNoDiagnostics('''
void run(void Function() plain, (int, int) Function() record, Object Function() any) {}
''');
}

final class _PreferSimplerPatternsNullCheckTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferSimplerPatternsNullCheck();
    super.setUp();
  }

  Future<void> _expectReported(String pattern) async {
    final source = 'void f(int? value) {\n  if (value case $pattern) {}\n}\n';
    await assertDiagnostics(source, [lint(source.indexOf(pattern), pattern.length)]);
  }

  Future<void> _reportsNullCheckWithVariable() => _expectReported('!= null && final x');

  Future<void> _reportsNullCheckWithTypedVariable() => _expectReported('!= null && final int x');

  Future<void> _acceptsNullCheckPattern() => assertNoDiagnostics('''
void f(int? value) {
  if (value case final x?) {}
}
''');

  Future<void> _acceptsOtherComparisons() => assertNoDiagnostics('''
void f(int? value) {
  if (value case != 0 && final x) {}
  if (value case == null && final y) {}
}
''');

  Future<void> _acceptsOtherRightOperands() => assertNoDiagnostics('''
void f(int? value) {
  if (value case != null && > 1) {}
  if (value case int() || null) {}
}
''');

  Future<void> _acceptsIfWithoutCase() => assertNoDiagnostics('''
void f(int? value) {
  if (value != null) {}
}
''');
}
