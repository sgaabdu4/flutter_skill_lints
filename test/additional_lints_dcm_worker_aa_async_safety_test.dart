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
    newPackage('riverpod').addFile('lib/riverpod.dart', r'''
class Ref {
  bool get mounted => true;
}
class Notifier<T> {
  final Ref ref = Ref();
  late T state;
}
''');
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

  Future<void> test_terminalBranchUpdatesAreMutuallyExclusive_noLint() async {
    await assertNoDiagnostics(r'''
Future<void> clear() async {}

class Controller {
  Object? state;

  Future<void> apply(bool expired) async {
    if (expired) {
      await clear();
      state = 'expired';
      return;
    }
    state = 'available';
  }
}
''');
  }

  Future<void> test_reportsAwaitedUpdateInTerminalBranchAfterPriorWrite_lint() async {
    const source = r'''
Future<void> clear() async {}

class Controller {
  Object? state;

  Future<void> apply(bool expired) async {
    state = 'checking';
    if (expired) {
      await clear();
      state = 'expired';
      return;
    }
  }
}
''';
    await assertDiagnostics(source, [
      lint(source.lastIndexOf("state = 'expired'"), 'state'.length),
    ]);
  }

  Future<void> test_allowsGuardedLoadingToResultTransition_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

class ViewState {
  const ViewState();
  ViewState copyWith({bool? loading, int? value}) => this;
}

Future<int> request() async => 1;

class Controller extends Notifier<ViewState> {
  Controller() {
    state = const ViewState();
  }

  int revision = 0;

  Future<void> refresh() async {
    final ticket = ++revision;
    state = state.copyWith(loading: true);
    final value = await request();
    if (!ref.mounted || ticket != revision) return;
    state = state.copyWith(loading: false, value: value);
  }
}
''');
  }

  Future<void> test_reportsFakeGeneratedCopyWithWithoutFreezedAnnotation_lint() async {
    newFile('$testPackageLibPath/view_state.dart', r'''
part 'view_state.freezed.dart';

class ViewState with _$ViewState {
  const ViewState({required this.loading, this.value});

  final bool loading;
  final int? value;
}
''');
    newFile('$testPackageLibPath/view_state.freezed.dart', r'''
part of 'view_state.dart';

mixin _$ViewState {
  ViewStateCopyWith get copyWith => ViewStateCopyWith(this as ViewState);
}

class ViewStateCopyWith {
  ViewStateCopyWith(this.state);
  final ViewState state;

  ViewState call({bool? loading, int? value}) => ViewState(
    loading: loading ?? state.loading,
    value: value ?? state.value,
  );
}
''');
    const source = r'''
import 'package:riverpod/riverpod.dart';
import 'view_state.dart';

Future<int> request() async => 1;

class Controller extends Notifier<ViewState> {
  ViewState build() => const ViewState(loading: false);

  int revision = 0;

  Future<void> refresh() async {
    final ticket = ++revision;
    state = state.copyWith(loading: true);
    final value = await request();
    if (!ref.mounted || ticket != revision) return;
    state = state.copyWith(loading: false, value: value);
  }
}
''';
    await assertDiagnostics(source, [
      lint(source.lastIndexOf('state = state.copyWith'), 'state'.length),
    ]);
  }

  Future<void> test_reportsGuardedUpdateToSameDataField_lint() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';

class ViewState {
  const ViewState();
  ViewState copyWith({bool? loading, int? value}) => this;
}

Future<int> request() async => 1;

class Controller extends Notifier<ViewState> {
  Controller() {
    state = const ViewState();
  }

  int revision = 0;

  Future<void> refresh() async {
    final ticket = ++revision;
    state = state.copyWith(value: 1);
    final value = await request();
    if (!ref.mounted || ticket != revision) return;
    state = state.copyWith(loading: false, value: value);
  }
}
''';
    await assertDiagnostics(source, [
      lint(source.lastIndexOf('state = state.copyWith'), 'state'.length),
    ]);
  }

  Future<void> test_reportsUnrelatedInequalityAsStaleGuard_lint() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';

class ViewState {
  const ViewState();
  ViewState copyWith({bool? loading, int? value}) => this;
}

Future<int> request() async => 1;

class Controller extends Notifier<ViewState> {
  Controller() { state = const ViewState(); }
  int revision = 0;

  Future<void> refresh(int a, int b) async {
    final ticket = ++revision;
    state = state.copyWith(loading: true);
    final value = await request();
    if (!ref.mounted || a != b) return;
    state = state.copyWith(loading: false, value: value);
  }
}
''';
    await assertDiagnostics(source, [
      lint(source.lastIndexOf('state = state.copyWith'), 'state'.length),
    ]);
  }

  Future<void> test_reportsPostAwaitTokenCaptureAsStaleGuard_lint() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';

class ViewState {
  const ViewState();
  ViewState copyWith({bool? loading, int? value}) => this;
}

Future<int> request() async => 1;

class Controller extends Notifier<ViewState> {
  Controller() { state = const ViewState(); }
  int revision = 0;

  Future<void> refresh() async {
    state = state.copyWith(loading: true);
    final value = await request();
    final ticket = ++revision;
    if (!ref.mounted || ticket != revision) return;
    state = state.copyWith(loading: false, value: value);
  }
}
''';
    await assertDiagnostics(source, [
      lint(source.lastIndexOf('state = state.copyWith'), 'state'.length),
    ]);
  }

  Future<void> test_reportsLocalCounterAsStaleGuard_lint() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';

class ViewState {
  const ViewState();
  ViewState copyWith({bool? loading, int? value}) => this;
}

Future<int> request() async => 1;

class Controller extends Notifier<ViewState> {
  Controller() { state = const ViewState(); }

  Future<void> refresh() async {
    var revision = 0;
    final ticket = ++revision;
    state = state.copyWith(loading: true);
    final value = await request();
    if (!ref.mounted || ticket != revision) return;
    state = state.copyWith(loading: false, value: value);
  }
}
''';
    await assertDiagnostics(source, [
      lint(source.lastIndexOf('state = state.copyWith'), 'state'.length),
    ]);
  }

  Future<void> test_reportsMutableTokenAsStaleGuard_lint() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';

class ViewState {
  const ViewState();
  ViewState copyWith({bool? loading, int? value}) => this;
}

Future<int> request() async => 1;

class Controller extends Notifier<ViewState> {
  Controller() { state = const ViewState(); }
  int revision = 0;

  Future<void> refresh() async {
    var ticket = ++revision;
    state = state.copyWith(loading: true);
    final value = await request();
    if (!ref.mounted || ticket != revision) return;
    state = state.copyWith(loading: false, value: value);
    ticket++;
  }
}
''';
    await assertDiagnostics(source, [
      lint(source.lastIndexOf('state = state.copyWith'), 'state'.length),
    ]);
  }

  Future<void> test_reportsLocalStateAndMountedNames_lint() async {
    const source = r'''
class LocalRef { bool get mounted => true; }
class ViewState {
  const ViewState();
  ViewState copyWith({bool? loading, int? value}) => this;
}
Future<int> request() async => 1;

class Controller {
  final LocalRef ref = LocalRef();
  int revision = 0;
  ViewState state = const ViewState();

  Future<void> refresh() async {
    final ticket = ++revision;
    state = state.copyWith(loading: true);
    final value = await request();
    if (!ref.mounted || ticket != revision) return;
    state = state.copyWith(loading: false, value: value);
  }
}
''';
    await assertDiagnostics(source, [
      lint(source.lastIndexOf('state = state.copyWith'), 'state'.length),
    ]);
  }

  Future<void> test_reportsTransitionAfterSecondAwait_lint() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';

class ViewState {
  const ViewState();
  ViewState copyWith({bool? loading, int? value}) => this;
}

Future<int> request() async => 1;
Future<void> save() async {}

class Controller extends Notifier<ViewState> {
  Controller() { state = const ViewState(); }
  int revision = 0;

  Future<void> refresh() async {
    final ticket = ++revision;
    state = state.copyWith(loading: true);
    final value = await request();
    if (!ref.mounted || ticket != revision) return;
    await save();
    state = state.copyWith(loading: false, value: value);
  }
}
''';
    await assertDiagnostics(source, [
      lint(source.lastIndexOf('state = state.copyWith'), 'state'.length),
    ]);
  }

  Future<void> test_reportsManyConditionalWritesWithoutPathExplosion_lint() async {
    final conditionalWrites = List.generate(
      32,
      (index) => 'if (condition$index) state = $index;',
    ).join('\n');
    final source =
        '''
Future<void> save() async {}

class Controller {
  Object? state;
  ${List.generate(32, (index) => 'bool condition$index = true;').join('\n  ')}

  Future<void> update() async {
    $conditionalWrites
    await save();
    state = 'done';
  }
}
''';
    await assertDiagnostics(source, [lint(source.lastIndexOf("state = 'done'"), 'state'.length)]);
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
