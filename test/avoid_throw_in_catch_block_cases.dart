import 'package:flutter_skill_lints/src/additional_lints/fixes/avoid_throw_in_catch_block_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_throw_in_catch_block.dart';

import 'analysis_rule_suite.dart';
import 'fix_test_support.dart';

void main() {
  analysisRuleSuite<_AvoidThrowInCatchBlockTest>(
    'AvoidThrowInCatchBlockTest',
    _AvoidThrowInCatchBlockTest.new,
    {
      'reportsThrowInCatch': (t) => t._reportsThrowInCatch(),
      'acceptsThrowInTryBody': (t) => t._acceptsThrowInTryBody(),
      'acceptsThrowInsideClosure': (t) => t._acceptsThrowInsideClosure(),
      'reusesExistingStackTrace': (t) => t._reusesExistingStackTrace(),
      'addsStackTraceToCatchWithException': (t) => t._addsStackTraceToCatchWithException(),
      'addsStackTraceToOnClauseWithoutCatch': (t) => t._addsStackTraceToOnClauseWithoutCatch(),
    },
  );
}

final class _AvoidThrowInCatchBlockTest extends FixRuleTest {
  @override
  void setUp() {
    rule = AvoidThrowInCatchBlock();
    super.setUp();
  }

  static const _plain = '''
void f() {
  try {
    print(1);
  } catch (e) {
    throw Exception('x');
  }
}
''';

  Future<void> _reportsThrowInCatch() => assertDiagnostics(_plain, [
    lint(_plain.indexOf("throw Exception('x')"), "throw Exception('x')".length),
  ]);

  Future<void> _acceptsThrowInTryBody() => assertNoDiagnostics('''
void f() {
  try {
    throw Exception('x');
  } catch (e) {
    print(e);
  }
}
''');

  Future<void> _acceptsThrowInsideClosure() => assertNoDiagnostics('''
void f() {
  try {
    print(1);
  } catch (e) {
    void fail() => throw Exception('x');
    Function g = () => throw Exception('y');
    print(fail);
    print(g);
  }
}
''');

  Future<void> _reusesExistingStackTrace() => expectFix(
    '''
void f() {
  try {
    print(1);
  } catch (e, st) {
    throw Exception('x');
  }
}
''',
    (context) => AvoidThrowInCatchBlockFix(context: context),
    expected: '''
void f() {
  try {
    print(1);
  } catch (e, st) {
    Error.throwWithStackTrace(Exception('x'), st);
  }
}
''',
  );

  Future<void> _addsStackTraceToCatchWithException() => expectFix(
    _plain,
    (context) => AvoidThrowInCatchBlockFix(context: context),
    expected: '''
void f() {
  try {
    print(1);
  } catch (e, stackTrace) {
    Error.throwWithStackTrace(Exception('x'), stackTrace);
  }
}
''',
  );

  Future<void> _addsStackTraceToOnClauseWithoutCatch() => expectFix(
    '''
void f() {
  try {
    print(1);
  } on Exception {
    throw Exception('x');
  }
}
''',
    (context) => AvoidThrowInCatchBlockFix(context: context),
    expected: '''
void f() {
  try {
    print(1);
  } on Exception catch (_, stackTrace) {
    Error.throwWithStackTrace(Exception('x'), stackTrace);
  }
}
''',
  );
}
