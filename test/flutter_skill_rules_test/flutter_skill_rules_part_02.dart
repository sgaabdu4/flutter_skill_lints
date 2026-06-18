// ignore_for_file: non_constant_identifier_names

part of '../flutter_skill_rules_test.dart';

@reflectiveTest
final class AvoidRunZonedGuardedTest extends _FlutterSkillRuleTest {
  @override
  void setUp() {
    rule = AvoidRunZonedGuarded();
    super.setUp();
  }

  Future<void> test_reportsDirectRunZonedGuardedCall() async {
    const source = r'''
R runZonedGuarded<R>(R Function() body, void Function(Object, StackTrace) onError) {
  return body();
}

void main() {
  runZonedGuarded(() {}, (e, s) {});
}
''';
    await assertDiagnostics(source, [lintForLast(source, 'runZonedGuarded')]);
  }

  Future<void> test_ignoresUserMethodWithSameName() async {
    await assertNoDiagnostics(r'''
class Zone {
  void runZonedGuarded() {}
}

void main() {
  Zone().runZonedGuarded();
}
''');
  }
}

@reflectiveTest
final class AvoidSilentRepositoryNullReturnTest extends _FlutterSkillRuleTest {
  @override
  void setUp() {
    rule = AvoidSilentRepositoryNullReturn();
    super.setUp();
  }

  Future<void> test_reportsNullRepositoryReturn() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';

class TodosNotifier extends Notifier<int> {
  Object? _repository;

  @override
  int build() => 0;

  Future<void> saveTodo() async {
    if (_repository == null) return;
  }
}
''';
    await assertDiagnostics(source, [lintFor(source, '_repository == null')]);
  }

  Future<void> test_allowsEnsureBeforeNullCheck() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

class TodosNotifier extends Notifier<int> {
  Object? _repository;

  @override
  int build() => 0;

  Future<void> saveTodo() async {
    await _ensureRepository();
    if (_repository == null) return;
  }

  Future<void> _ensureRepository() async {}
}
''');
  }
}

@reflectiveTest
final class AvoidSyncNotifierStateReadTest extends _FlutterSkillRuleTest {
  @override
  void setUp() {
    rule = AvoidSyncNotifierStateRead();
    super.setUp();
  }

  Future<void> test_reportsStateReadInSyncBuild() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';

class TodosNotifier extends Notifier<int> {
  @override
  int build() {
    return state;
  }
}
''';
    await assertDiagnostics(source, [lintFor(source, 'state')]);
  }

  Future<void> test_allowsDeferredLoad() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

class TodosNotifier extends Notifier<int> {
  @override
  int build() {
    Future.microtask(_load);
    return 0;
  }

  void _load() {}
}
''');
  }
}

@reflectiveTest
final class UseUnawaitedForFireAndForgetFuturesTest extends _FlutterSkillRuleTest {
  @override
  void setUp() {
    rule = UseUnawaitedForFireAndForgetFutures();
    super.setUp();
  }

  Future<void> test_reportsFutureDroppedFromVoidCallback() async {
    const source = r'''
import 'dart:async';

typedef VoidCallback = void Function();

Future<void> showDialogBottomSheet<T>() async {}

void build(VoidCallback onPressed) {}

void example() {
  build(() {
    showDialogBottomSheet<void>();
  });
}
''';

    await assertDiagnostics(source, [lintFor(source, 'showDialogBottomSheet<void>()')]);
  }

  Future<void> test_allowsUnawaitedFutureFromVoidCallback() async {
    await assertNoDiagnostics(r'''
import 'dart:async';

typedef VoidCallback = void Function();

Future<void> showDialogBottomSheet<T>() async {}

void build(VoidCallback onPressed) {}

void example() {
  build(() {
    unawaited(showDialogBottomSheet<void>());
  });
}
''');
  }

  Future<void> test_allowsAwaitedFutureFromAsyncCallback() async {
    await assertNoDiagnostics(r'''
typedef AsyncCallback = Future<void> Function();

Future<void> showDialogBottomSheet<T>() async {}

void build(AsyncCallback onPressed) {}

void example() {
  build(() async {
    await showDialogBottomSheet<void>();
  });
}
''');
  }
}
