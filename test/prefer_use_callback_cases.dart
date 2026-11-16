import 'package:flutter_skill_lints/src/additional_lints/fixes/prefer_use_callback_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_use_callback.dart';

import 'analysis_rule_suite.dart';
import 'fix_test_support.dart';

void main() {
  analysisRuleSuite<PreferUseCallbackTest>('PreferUseCallbackTest', PreferUseCallbackTest.new, {
    'reportsMemoizedFunction': (t) => t.reportsMemoizedFunction(),
    'reportsBlockBodyReturningFunction': (t) => t.reportsBlockBodyReturningFunction(),
    'acceptsMemoizedValue': (t) => t.acceptsMemoizedValue(),
    'acceptsNonFunctionFactory': (t) => t.acceptsNonFunctionFactory(),
    'acceptsMultiStatementFactory': (t) => t.acceptsMultiStatementFactory(),
    'acceptsOtherFunctions': (t) => t.acceptsOtherFunctions(),
    'rewritesExpressionBody': (t) => t.rewritesExpressionBody(),
    'rewritesSingleReturnBlock': (t) => t.rewritesSingleReturnBlock(),
  });
}

final class PreferUseCallbackTest extends FixRuleTest {
  @override
  void setUp() {
    rule = PreferUseCallback();
    super.setUp();
  }

  static const _hooks = '''
T useMemoized<T>(T Function() factory, [List<Object?> keys = const []]) => factory();

void useCallback(Function callback, List<Object?> keys) {}

''';

  static const _memoized =
      '''
${_hooks}void f(int a) {
  useMemoized(() => () => print(a), [a]);
}
''';

  Future<void> reportsMemoizedFunction() => assertDiagnostics(_memoized, [
    lint(_memoized.indexOf('useMemoized('), 'useMemoized(() => () => print(a), [a])'.length),
  ]);

  Future<void> reportsBlockBodyReturningFunction() async {
    const source =
        '''
${_hooks}void f(int a) {
  useMemoized(() {
    return () => print(a);
  }, [a]);
}
''';
    const call = '''useMemoized(() {
    return () => print(a);
  }, [a])''';
    await assertDiagnostics(source, [lint(source.indexOf(call), call.length)]);
  }

  Future<void> acceptsMemoizedValue() => assertNoDiagnostics('''
${_hooks}void f(int a) {
  useMemoized(() => a + 1, [a]);
}
''');

  Future<void> acceptsNonFunctionFactory() => assertNoDiagnostics('''
${_hooks}void f(Function() make) {
  useMemoized(make, []);
}
''');

  Future<void> acceptsMultiStatementFactory() => assertNoDiagnostics('''
${_hooks}void f(int a) {
  useMemoized(() {
    print(a);
    return () => print(a);
  }, [a]);
}
''');

  Future<void> acceptsOtherFunctions() => assertNoDiagnostics('''
T remember<T>(T Function() factory) => factory();

void f(int a) {
  remember(() => () => print(a));
}
''');

  Future<void> rewritesExpressionBody() => expectFix(
    _memoized,
    (context) => PreferUseCallbackFix(context: context),
    expected:
        '''
${_hooks}void f(int a) {
  useCallback(() => print(a), [a]);
}
''',
  );

  Future<void> rewritesSingleReturnBlock() => expectFix(
    '''
${_hooks}void f(int a) {
  useMemoized(() {
    return () => print(a);
  }, [a]);
}
''',
    (context) => PreferUseCallbackFix(context: context),
    expected:
        '''
${_hooks}void f(int a) {
  useCallback(() => print(a), [a]);
}
''',
  );
}
