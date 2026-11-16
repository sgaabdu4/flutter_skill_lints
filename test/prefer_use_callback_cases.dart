import 'package:flutter_skill_lints/src/additional_lints/fixes/prefer_use_callback_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_use_callback.dart';

import 'analysis_rule_suite.dart';
import 'fix_test_support.dart';

void main() {
  analysisRuleSuite<_PreferUseCallbackTest>('PreferUseCallbackTest', _PreferUseCallbackTest.new, {
    'reportsMemoizedFunction': (t) => t._reportsMemoizedFunction(),
    'reportsBlockBodyReturningFunction': (t) => t._reportsBlockBodyReturningFunction(),
    'acceptsMemoizedValue': (t) => t._acceptsMemoizedValue(),
    'acceptsNonFunctionFactory': (t) => t._acceptsNonFunctionFactory(),
    'acceptsMultiStatementFactory': (t) => t._acceptsMultiStatementFactory(),
    'acceptsOtherFunctions': (t) => t._acceptsOtherFunctions(),
    'rewritesExpressionBody': (t) => t._rewritesExpressionBody(),
    'rewritesSingleReturnBlock': (t) => t._rewritesSingleReturnBlock(),
  });
}

final class _PreferUseCallbackTest extends FixRuleTest {
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

  Future<void> _reportsMemoizedFunction() => assertDiagnostics(_memoized, [
    lint(_memoized.indexOf('useMemoized('), 'useMemoized(() => () => print(a), [a])'.length),
  ]);

  Future<void> _reportsBlockBodyReturningFunction() async {
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

  Future<void> _acceptsMemoizedValue() => assertNoDiagnostics('''
${_hooks}void f(int a) {
  useMemoized(() => a + 1, [a]);
}
''');

  Future<void> _acceptsNonFunctionFactory() => assertNoDiagnostics('''
${_hooks}void f(Function() make) {
  useMemoized(make, []);
}
''');

  Future<void> _acceptsMultiStatementFactory() => assertNoDiagnostics('''
${_hooks}void f(int a) {
  useMemoized(() {
    print(a);
    return () => print(a);
  }, [a]);
}
''');

  Future<void> _acceptsOtherFunctions() => assertNoDiagnostics('''
T remember<T>(T Function() factory) => factory();

void f(int a) {
  remember(() => () => print(a));
}
''');

  Future<void> _rewritesExpressionBody() => expectFix(
    _memoized,
    (context) => PreferUseCallbackFix(context: context),
    expected:
        '''
${_hooks}void f(int a) {
  useCallback(() => print(a), [a]);
}
''',
  );

  Future<void> _rewritesSingleReturnBlock() => expectFix(
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
