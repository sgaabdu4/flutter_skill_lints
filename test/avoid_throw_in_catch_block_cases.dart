import 'package:flutter_skill_lints/src/additional_lints/fixes/avoid_throw_in_catch_block_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_throw_in_catch_block.dart';

import 'analysis_rule_suite.dart';
import 'fix_test_support.dart';

void main() {
  analysisRuleSuite<AvoidThrowInCatchBlockTest>(
    'AvoidThrowInCatchBlockTest',
    AvoidThrowInCatchBlockTest.new,
    {
      'reportsThrowInCatch': (t) => t.reportsThrowInCatch(),
      'acceptsThrowInTryBody': (t) => t.acceptsThrowInTryBody(),
      'acceptsThrowInsideClosure': (t) => t.acceptsThrowInsideClosure(),
      'reusesExistingStackTrace': (t) => t.reusesExistingStackTrace(),
      'addsStackTraceToCatchWithException': (t) => t.addsStackTraceToCatchWithException(),
      'addsStackTraceToOnClauseWithoutCatch': (t) => t.addsStackTraceToOnClauseWithoutCatch(),
    },
  );
}

final class AvoidThrowInCatchBlockTest extends FixRuleTest {
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

  Future<void> reportsThrowInCatch() => assertDiagnostics(_plain, [
    lint(_plain.indexOf("throw Exception('x')"), "throw Exception('x')".length),
  ]);

  Future<void> acceptsThrowInTryBody() => assertNoDiagnostics('''
void f() {
  try {
    throw Exception('x');
  } catch (e) {
    print(e);
  }
}
''');

  Future<void> acceptsThrowInsideClosure() => assertNoDiagnostics('''
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

  Future<void> reusesExistingStackTrace() => expectFix(
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

  Future<void> addsStackTraceToCatchWithException() => expectFix(
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

  Future<void> addsStackTraceToOnClauseWithoutCatch() => expectFix(
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
