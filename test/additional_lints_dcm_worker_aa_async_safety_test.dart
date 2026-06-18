// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_passing_async_when_sync_expected.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_uncaught_future_errors.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/require_atomic_async_updates.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidUncaughtFutureErrorsTest);
    defineReflectiveTests(RequireAtomicAsyncUpdatesTest);
    defineReflectiveTests(AvoidPassingAsyncWhenSyncExpectedTest);
  });
}

@reflectiveTest
final class AvoidUncaughtFutureErrorsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidUncaughtFutureErrors();
    super.setUp();
  }

  Future<void> test_unawaitedNamedFuture_noLint() async {
    await assertNoDiagnostics(r'''
import 'dart:async';

Future<void> save() async {}

void submit() {
  unawaited(save());
}
''');
  }

  Future<void> test_unawaitedInlineAsyncWithoutTry_lint() async {
    const source = r'''
import 'dart:async';

Future<void> save() async {}

void submit() {
  unawaited(() async {
    await save();
  }());
}
''';

    await assertDiagnostics(source, [
      lint(source.lastIndexOf('() async'), '() async {\n    await save();\n  }()'.length),
    ]);
  }

  Future<void> test_unawaitedInlineAsyncWithTry_noLint() async {
    await assertNoDiagnostics(r'''
import 'dart:async';

Future<void> save() async {}

void submit() {
  unawaited(() async {
    try {
      await save();
    } on Object {
      return;
    }
  }());
}
''');
  }

  Future<void> test_awaitedFuture_noLint() async {
    await assertNoDiagnostics(r'''
Future<void> save() async {}

Future<void> submit() async {
  await save();
}
''');
  }
}

@reflectiveTest
final class RequireAtomicAsyncUpdatesTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = RequireAtomicAsyncUpdates();
    super.setUp();
  }

  Future<void> test_sameVariableAssignedBeforeAndAfterAwait_lint() async {
    const source = r'''
Future<void> save() async {}

Future<void> submit() async {
  var count = 0;
  count = 1;
  await save();
  count = 2;
}
''';

    await assertDiagnostics(source, [lint(source.lastIndexOf('count = 2'), 'count'.length)]);
  }

  Future<void> test_stateAssignedBeforeAndAfterAwait_lint() async {
    const source = r'''
Future<void> save() async {}

class Counter {
  Object? state;

  Future<void> submit() async {
    state = 'loading';
    await save();
    state = 'done';
  }
}
''';

    await assertDiagnostics(source, [lint(source.lastIndexOf('state ='), 'state'.length)]);
  }

  Future<void> test_differentVariablesAcrossAwait_noLint() async {
    await assertNoDiagnostics(r'''
Future<void> save() async {}

Future<void> submit() async {
  var started = false;
  var completed = false;
  started = true;
  await save();
  completed = true;
}
''');
  }
}

@reflectiveTest
final class AvoidPassingAsyncWhenSyncExpectedTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidPassingAsyncWhenSyncExpected();
    super.setUp();
  }

  Future<void> test_asyncNamedCallbackForVoidFunction_lint() async {
    const source = r'''
void run({required void Function() callback}) {}

void start() {
  run(callback: () async {});
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('() async'), '() async {}'.length)]);
  }

  Future<void> test_asyncPositionalCallbackForVoidFunction_lint() async {
    const source = r'''
void run(void Function() callback) {}

void start() {
  run(() async {});
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('() async'), '() async {}'.length)]);
  }

  Future<void> test_asyncCallbackForFutureFunction_noLint() async {
    await assertNoDiagnostics(r'''
void run(Future<void> Function() callback) {}

void start() {
  run(() async {});
}
''');
  }
}
