import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_async_call_in_sync_function.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_missed_calls.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_async_await.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<AvoidAsyncCallInSyncFunctionTest>(
    'AvoidAsyncCallInSyncFunctionTest',
    AvoidAsyncCallInSyncFunctionTest.new,
    {
      'test_futureCallInSyncFunction_lint': (t) => t._futureCallInSyncFunctionLint(),
      'test_asyncFunctionAwait_noLint': (t) => t._asyncFunctionAwaitNoLint(),
      'test_returnedFutureFromSyncFunction_noLint': (t) =>
          t._returnedFutureFromSyncFunctionNoLint(),
      'test_assignedFutureInSyncFunction_noLint': (t) => t._assignedFutureInSyncFunctionNoLint(),
      'test_explicitUnawaited_noLint': (t) => t._explicitUnawaitedNoLint(),
    },
  );
  analysisRuleSuite<PreferAsyncAwaitTest>('PreferAsyncAwaitTest', PreferAsyncAwaitTest.new, {
    'test_futureThen_lint': (t) => t._futureThenLint(),
    'test_futureCatchError_lint': (t) => t._futureCatchErrorLint(),
    'test_futureThenInDatasource_noLint': (t) => t._futureThenInDatasourceNoLint(),
    'test_streamListen_noLint': (t) => t._streamListenNoLint(),
    'test_userTypeThen_noLint': (t) => t._userTypeThenNoLint(),
  });
  analysisRuleSuite<AvoidMissedCallsTest>('AvoidMissedCallsTest', AvoidMissedCallsTest.new, {
    'test_bareFutureCall_lint': (t) => t._bareFutureCallLint(),
    'test_awaitedFuture_noLint': (t) => t._awaitedFutureNoLint(),
    'test_assignedFuture_noLint': (t) => t._assignedFutureNoLint(),
    'test_futureAssignmentStatement_noLint': (t) => t._futureAssignmentStatementNoLint(),
    'test_returnedFuture_noLint': (t) => t._returnedFutureNoLint(),
  });
}

final class AvoidAsyncCallInSyncFunctionTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidAsyncCallInSyncFunction();
    super.setUp();
  }

  Future<void> _futureCallInSyncFunctionLint() async {
    const source = r'''
Future<void> load() async {}

void start() {
  load();
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('load();'), 'load()'.length)]);
  }

  Future<void> _asyncFunctionAwaitNoLint() async {
    await assertNoDiagnostics(r'''
Future<void> load() async {}

Future<void> start() async {
  await load();
}
''');
  }

  Future<void> _returnedFutureFromSyncFunctionNoLint() async {
    await assertNoDiagnostics(r'''
Future<void> load() async {}

Future<void> start() {
  return load();
}
''');
  }

  Future<void> _assignedFutureInSyncFunctionNoLint() async {
    await assertNoDiagnostics(r'''
Future<void> pending = Future<void>.value();

void reset() {
  pending = Future<void>.value();
}
''');
  }

  Future<void> _explicitUnawaitedNoLint() async {
    await assertNoDiagnostics(r'''
import 'dart:async';

Future<void> load() async {}

void start() {
  unawaited(load());
}
''');
  }
}

final class PreferAsyncAwaitTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferAsyncAwait();
    super.setUp();
  }

  Future<void> _futureThenLint() async {
    const source = r'''
Future<int> load() async => 1;

Future<int> start() {
  return load().then((value) => value + 1);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('then'), 'then'.length)]);
  }

  Future<void> _futureCatchErrorLint() async {
    const source = r'''
Future<int> load() async => 1;

Future<int> start() {
  return load().catchError((Object _) => 0);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('catchError'), 'catchError'.length)]);
  }

  Future<void> _futureThenInDatasourceNoLint() async {
    final path = '$testPackageLibPath/features/users/data/datasources/user_datasource.dart';
    newFile(path, r'''
Future<int> load() async => 1;

Future<int> start() {
  return load().then((value) => value + 1);
}
''');
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> _streamListenNoLint() async {
    await assertNoDiagnostics(r'''
Stream<int> values() => Stream<int>.fromIterable(const [1]);

void start() {
  values().listen((value) {});
}
''');
  }

  Future<void> _userTypeThenNoLint() async {
    await assertNoDiagnostics(r'''
class Task {
  int then(int Function(int value) callback) => callback(1);
}

void start(Task task) {
  task.then((value) => value);
}
''');
  }
}

final class AvoidMissedCallsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidMissedCalls();
    super.setUp();
  }

  Future<void> _bareFutureCallLint() async {
    const source = r'''
Future<void> save() async {}

Future<void> submit() async {
  save();
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('save();'), 'save()'.length)]);
  }

  Future<void> _awaitedFutureNoLint() async {
    await assertNoDiagnostics(r'''
Future<void> save() async {}

Future<void> submit() async {
  await save();
}
''');
  }

  Future<void> _assignedFutureNoLint() async {
    await assertNoDiagnostics(r'''
import 'dart:async';

Future<void> save() async {}

void submit() {
  final pending = save();
  unawaited(pending);
}
''');
  }

  Future<void> _futureAssignmentStatementNoLint() async {
    await assertNoDiagnostics(r'''
Future<void> pending = Future<void>.value();

void submit() {
  pending = Future<void>.value();
}
''');
  }

  Future<void> _returnedFutureNoLint() async {
    await assertNoDiagnostics(r'''
Future<void> save() async {}

Future<void> submit() {
  return save();
}
''');
  }
}
