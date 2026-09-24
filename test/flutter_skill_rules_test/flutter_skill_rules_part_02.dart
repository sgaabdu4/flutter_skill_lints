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

@reflectiveTest
final class UseRefMountedAfterAwaitTest extends _FlutterSkillRuleTest {
  @override
  void setUp() {
    rule = UseRefMountedAfterAwait();
    super.setUp();
  }

  Future<void> test_reportsRefAfterAwait() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';

final provider = Object();

class TodosNotifier extends Notifier<int> {
  @override
  int build() => 0;

  Future<void> load() async {
    await Future<void>.value();
    ref.read(provider);
  }
}
''';
    await assertDiagnostics(source, [lintFor(source, 'ref.read(provider)')]);
  }

  Future<void> test_allowsGuardedRefAfterAwait() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

final provider = Object();

class TodosNotifier extends Notifier<int> {
  @override
  int build() => 0;

  Future<void> load() async {
    await Future<void>.value();
    if (!ref.mounted) return;
    ref.read(provider);
  }
}
''');
  }

  Future<void> test_allowsCompoundMountedAndRevisionGuard() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';
class TodosNotifier extends Notifier<int> {
  @override
  int build() => 0;
  int _revision = 0;
  Future<void> load() async {
    final ticket = _revision;
    await Future<void>.value();
    if (!ref.mounted || ticket != _revision) return;
    state = 1;
  }
}
''');
  }

  Future<void> test_shadowedDirectMountedGuardStillReports() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';
class FakeRef {
  bool get mounted => true;
}
class TodosNotifier extends Notifier<int> {
  @override
  int build() => 0;
  int _revision = 0;
  Future<void> load() async {
    final ref = FakeRef();
    final ticket = _revision;
    await Future<void>.value();
    if (!ref.mounted || ticket != _revision) return;
    state = 1;
  }
  Future<void> loadOther(Ref ref) async {
    final ticket = _revision;
    await Future<void>.value();
    if (!ref.mounted || ticket != _revision) return;
    state = 2;
  }
}
''';
    await assertDiagnostics(source, [
      lint(source.indexOf('state = 1'), 5),
      lint(source.indexOf('state = 2'), 5),
    ]);
  }

  Future<void> test_impureSuffixCanInvalidateMountedGuard() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';
class TodosNotifier extends Notifier<int> {
  @override
  int build() => 0;
  bool invalidateAndReturnFalse() => false;
  Future<void> load() async {
    await Future<void>.value();
    if (!ref.mounted || invalidateAndReturnFalse()) return;
    state = 1;
  }
}
''';
    await assertDiagnostics(source, [lint(source.indexOf('state = 1'), 5)]);
  }

  Future<void> test_lazyLocalSuffixCannotInvalidateMountedGuard() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';
class TodosNotifier extends Notifier<int> {
  @override
  int build() => 0;
  bool invalidateAndReturnFalse() => false;
  Future<void> load() async {
    late final stale = invalidateAndReturnFalse();
    await Future<void>.value();
    if (!ref.mounted || stale) return;
    state = 1;
  }
}
''';
    await assertDiagnostics(source, [lint(source.indexOf('state = 1'), 5)]);
  }

  Future<void> test_lazyStaticFieldSuffixCannotInvalidateMountedGuard() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';
class TodosNotifier extends Notifier<int> {
  @override
  int build() => 0;
  static bool invalidateAndReturnFalse() => false;
  static final bool _stale = invalidateAndReturnFalse();
  Future<void> load() async {
    await Future<void>.value();
    if (!ref.mounted || _stale) return;
    state = 1;
  }
}
''';
    await assertDiagnostics(source, [lint(source.indexOf('state = 1'), 5)]);
  }

  Future<void> test_overriddenFieldSuffixCannotInvalidateMountedGuard() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';
class TodosNotifier extends Notifier<int> {
  @override
  int build() => 0;
  int revision = 0;
  Future<void> load() async {
    await Future<void>.value();
    if (!ref.mounted || revision == 1) return;
    state = 1;
  }
}
class Child extends TodosNotifier {
  @override
  int get revision => 0;
}
''';
    await assertDiagnostics(source, [lint(source.indexOf('state = 1'), 5)]);
  }

  Future<void> test_awaitInSurvivingElseRequiresFreshGuard() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';
class TodosNotifier extends Notifier<int> {
  @override
  int build() => 0;
  Future<void> load() async {
    await Future<void>.value();
    if (!ref.mounted) return;
    else { await Future<void>.value(); }
    state = 1;
  }
}
''';
    await assertDiagnostics(source, [lint(source.indexOf('state = 1'), 5)]);
  }

  Future<void> test_incompleteMountedGuardStillReports() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';
class TodosNotifier extends Notifier<int> {
  @override
  int build() => 0;
  Future<void> load(bool shouldReturn) async {
    await Future<void>.value();
    if (!ref.mounted) {
      if (shouldReturn) return;
    }
    state = 1;
  }
}
''';
    await assertDiagnostics(source, [lint(source.indexOf('state = 1'), 5)]);
  }

  Future<void> test_mountedReturnBranchCannotUseStateBeforeReturn() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';
class TodosNotifier extends Notifier<int> {
  @override
  int build() => 0;
  Future<void> load() async {
    await Future<void>.value();
    if (!ref.mounted) {
      state = 1;
      return;
    }
    state = 2;
  }
}
''';
    await assertDiagnostics(source, [lint(source.indexOf('state = 1'), 5)]);
  }

  Future<void> test_conjunctiveMountedGuardStillReports() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';
class TodosNotifier extends Notifier<int> {
  @override
  int build() => 0;
  Future<void> load(bool stale) async {
    await Future<void>.value();
    if (!ref.mounted && stale) return;
    state = 1;
  }
}
''';
    await assertDiagnostics(source, [lint(source.indexOf('state = 1'), 5)]);
  }

  Future<void> test_allowsResolvedPrivateMountedHelper() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';
class TodosNotifier extends Notifier<int> {
  @override
  int build() => 0;
  int _revision = 0;
  bool _isCurrent(int ticket) => ref.mounted && ticket == _revision;
  Future<void> load() async {
    final ticket = _revision;
    await Future<void>.value();
    if (!_isCurrent(ticket)) return;
    state = 1;
  }
}
''');
  }

  Future<void> test_revisionOnlyHelperStillReports() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';
class TodosNotifier extends Notifier<int> {
  @override
  int build() => 0;
  int revision = 0;
  bool _isCurrent(int ticket) => ticket == revision;
  Future<void> load() async {
    final ticket = revision;
    await Future<void>.value();
    if (!_isCurrent(ticket)) return;
    state = 1;
  }
}
''';
    await assertDiagnostics(source, [lint(source.indexOf('state = 1'), 5)]);
  }

  Future<void> test_mixinOverriddenPrivateHelperStillReports() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';
class TodosNotifier extends Notifier<int> {
  @override
  int build() => 0;
  int revision = 0;
  bool _isCurrent(int ticket) => ticket == revision && ref.mounted;
  Future<void> load() async {
    final ticket = revision;
    await Future<void>.value();
    if (!_isCurrent(ticket)) return;
    state = 1;
  }
}
mixin UnsafeGuard on TodosNotifier {
  @override
  bool _isCurrent(int ticket) => true;
}
class Child extends TodosNotifier with UnsafeGuard {}
''';
    await assertDiagnostics(source, [lint(source.indexOf('state = 1'), 5)]);
  }

  Future<void> test_helperCannotTrustGettersOverloadsOrShadowedRef() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';
class Value {
  @override
  bool operator ==(Object other) => true;
  @override
  int get hashCode => 0;
}
class TodosNotifier extends Notifier<int> {
  @override
  int build() => 0;
  bool get invalidatingFlag => true;
  final first = Value();
  final second = Value();
  bool _getterGuard() => ref.mounted && invalidatingFlag;
  bool _overloadedGuard() => ref.mounted && first == second;
  bool _shadowedGuard(Ref ref) => ref.mounted;
  Future<void> viaGetter() async {
    await Future<void>.value();
    if (!_getterGuard()) return;
    state = 1;
  }
  Future<void> viaOverload() async {
    await Future<void>.value();
    if (!_overloadedGuard()) return;
    state = 2;
  }
  Future<void> viaShadow(Ref other) async {
    await Future<void>.value();
    if (!_shadowedGuard(other)) return;
    state = 3;
  }
}
''';
    await assertDiagnostics(source, [
      lint(source.indexOf('state = 1'), 5),
      lint(source.indexOf('state = 2'), 5),
      lint(source.indexOf('state = 3'), 5),
    ]);
  }

  Future<void> test_helperCannotTrustOverriddenRefGetter() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';
class TodosNotifier extends Notifier<int> {
  @override
  int build() => 0;
  final alternateRef = Ref();
  @override
  Ref get ref => alternateRef;
  bool _isCurrent() => ref.mounted;
  Future<void> load() async {
    await Future<void>.value();
    if (!_isCurrent()) return;
    state = 1;
  }
}
''';
    await assertDiagnostics(source, [lint(source.indexOf('state = 1'), 5)]);
  }
}
