import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_return_await.dart';

import 'analysis_rule_suite.dart';
import 'fix_test_support.dart';

void main() {
  analysisRuleSuite<PreferReturnAwaitTest>('PreferReturnAwaitTest', PreferReturnAwaitTest.new, {
    'reportsFutureReturnedInTryBody': (t) => t.reportsFutureReturnedInTryBody(),
    'reportsFutureReturnedInCatchClause': (t) => t.reportsFutureReturnedInCatchClause(),
    'reportsFutureOrReturnedInTryBody': (t) => t.reportsFutureOrReturnedInTryBody(),
    'acceptsAwaitedReturn': (t) => t.acceptsAwaitedReturn(),
    'acceptsReturnInFinallyBlock': (t) => t.acceptsReturnInFinallyBlock(),
    'acceptsReturnOutsideTry': (t) => t.acceptsReturnOutsideTry(),
    'acceptsReturnInSynchronousFunction': (t) => t.acceptsReturnInSynchronousFunction(),
    'acceptsReturnInsideNestedClosure': (t) => t.acceptsReturnInsideNestedClosure(),
    'acceptsNonFutureAndEmptyReturns': (t) => t.acceptsNonFutureAndEmptyReturns(),
  });
}

final class PreferReturnAwaitTest extends FixRuleTest {
  @override
  void setUp() {
    rule = PreferReturnAwait();
    super.setUp();
  }

  static const _prelude = '''
import 'dart:async';

Future<int> fetch() async => 1;
FutureOr<int> maybe() => 1;
''';

  Future<void> _expectReported(String body, String returned) async {
    final source = '$_prelude\n$body\n';
    await expectOnlyRuleDiagnostics(source, [
      (offset: source.lastIndexOf(returned), length: returned.length),
    ]);
  }

  Future<void> reportsFutureReturnedInTryBody() => _expectReported('''
Future<int> run() async {
  try {
    return fetch();
  } catch (e) {
    return 0;
  }
}''', 'fetch()');

  Future<void> reportsFutureReturnedInCatchClause() => _expectReported('''
Future<int> run() async {
  try {
    return 1;
  } catch (e) {
    return fetch();
  }
}''', 'fetch()');

  Future<void> reportsFutureOrReturnedInTryBody() => _expectReported('''
Future<int> run() async {
  try {
    return maybe();
  } catch (e) {
    return 0;
  }
}''', 'maybe()');

  Future<void> acceptsAwaitedReturn() => assertNoDiagnostics('''
$_prelude
Future<int> run() async {
  try {
    return await fetch();
  } catch (e) {
    return 0;
  }
}
''');

  Future<void> acceptsReturnInFinallyBlock() => assertNoDiagnostics('''
$_prelude
Future<int> run() async {
  try {
    print('a');
  } finally {
    return fetch();
  }
}
''');

  Future<void> acceptsReturnOutsideTry() => assertNoDiagnostics('''
$_prelude
Future<int> run() async {
  return fetch();
}
''');

  Future<void> acceptsReturnInSynchronousFunction() => assertNoDiagnostics('''
$_prelude
Future<int> run() {
  try {
    return fetch();
  } catch (e) {
    return fetch();
  }
}
''');

  Future<void> acceptsReturnInsideNestedClosure() => assertNoDiagnostics('''
$_prelude
Future<int> run() async {
  try {
    final later = () async {
      return fetch();
    };
    return await later();
  } catch (e) {
    return 0;
  }
}
''');

  Future<void> acceptsNonFutureAndEmptyReturns() => assertNoDiagnostics('''
$_prelude
Future<void> run() async {
  try {
    if (1 > 2) return;
    final value = 1;
    return;
  } catch (e) {
    return;
  }
}

int plain() {
  try {
    return 1;
  } catch (e) {
    return 2;
  }
}
''');
}
