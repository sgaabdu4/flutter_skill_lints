// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_async_call_in_sync_function.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_missed_calls.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_async_await.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidAsyncCallInSyncFunctionTest);
    defineReflectiveTests(PreferAsyncAwaitTest);
    defineReflectiveTests(AvoidMissedCallsTest);
  });
}

@reflectiveTest
final class AvoidAsyncCallInSyncFunctionTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidAsyncCallInSyncFunction();
    super.setUp();
  }

  Future<void> test_futureCallInSyncFunction_lint() async {
    const source = r'''
Future<void> load() async {}

void start() {
  load();
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('load();'), 'load()'.length)]);
  }

  Future<void> test_asyncFunctionAwait_noLint() async {
    await assertNoDiagnostics(r'''
Future<void> load() async {}

Future<void> start() async {
  await load();
}
''');
  }

  Future<void> test_returnedFutureFromSyncFunction_noLint() async {
    await assertNoDiagnostics(r'''
Future<void> load() async {}

Future<void> start() {
  return load();
}
''');
  }

  Future<void> test_assignedFutureInSyncFunction_noLint() async {
    await assertNoDiagnostics(r'''
Future<void> pending = Future<void>.value();

void reset() {
  pending = Future<void>.value();
}
''');
  }

  Future<void> test_explicitUnawaited_noLint() async {
    await assertNoDiagnostics(r'''
import 'dart:async';

Future<void> load() async {}

void start() {
  unawaited(load());
}
''');
  }
}

@reflectiveTest
final class PreferAsyncAwaitTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferAsyncAwait();
    super.setUp();
  }

  Future<void> test_futureThen_lint() async {
    const source = r'''
Future<int> load() async => 1;

Future<int> start() {
  return load().then((value) => value + 1);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('then'), 'then'.length)]);
  }

  Future<void> test_futureCatchError_lint() async {
    const source = r'''
Future<int> load() async => 1;

Future<int> start() {
  return load().catchError((Object _) => 0);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('catchError'), 'catchError'.length)]);
  }

  Future<void> test_futureThenInDatasource_noLint() async {
    final path = '$testPackageLibPath/features/users/data/datasources/user_datasource.dart';
    newFile(path, r'''
Future<int> load() async => 1;

Future<int> start() {
  return load().then((value) => value + 1);
}
''');
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_streamListen_noLint() async {
    await assertNoDiagnostics(r'''
Stream<int> values() => Stream<int>.fromIterable(const [1]);

void start() {
  values().listen((value) {});
}
''');
  }

  Future<void> test_userTypeThen_noLint() async {
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

@reflectiveTest
final class AvoidMissedCallsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidMissedCalls();
    super.setUp();
  }

  Future<void> test_bareFutureCall_lint() async {
    const source = r'''
Future<void> save() async {}

Future<void> submit() async {
  save();
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('save();'), 'save()'.length)]);
  }

  Future<void> test_awaitedFuture_noLint() async {
    await assertNoDiagnostics(r'''
Future<void> save() async {}

Future<void> submit() async {
  await save();
}
''');
  }

  Future<void> test_assignedFuture_noLint() async {
    await assertNoDiagnostics(r'''
import 'dart:async';

Future<void> save() async {}

void submit() {
  final pending = save();
  unawaited(pending);
}
''');
  }

  Future<void> test_futureAssignmentStatement_noLint() async {
    await assertNoDiagnostics(r'''
Future<void> pending = Future<void>.value();

void submit() {
  pending = Future<void>.value();
}
''');
  }

  Future<void> test_returnedFuture_noLint() async {
    await assertNoDiagnostics(r'''
Future<void> save() async {}

Future<void> submit() {
  return save();
}
''');
  }
}
