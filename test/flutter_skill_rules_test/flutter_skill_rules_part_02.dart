part of '../flutter_skill_rules_test.dart';

final class _AvoidRunZonedGuardedTest extends _FlutterSkillRuleTest {
  static Map<String, Future<void> Function(_AvoidRunZonedGuardedTest)> get _allCases =>
      caseSet<_AvoidRunZonedGuardedTest>(
        parent: const {},
        own: {
          'test_reportsDirectRunZonedGuardedCall': (t) => t._reportsDirectRunZonedGuardedCall(),
          'test_ignoresUserMethodWithSameName': (t) => t._ignoresUserMethodWithSameName(),
        },
      );

  @override
  void setUp() {
    rule = AvoidRunZonedGuarded();
    super.setUp();
  }

  Future<void> _reportsDirectRunZonedGuardedCall() async {
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

  Future<void> _ignoresUserMethodWithSameName() async {
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

final class _AvoidSilentRepositoryNullReturnTest extends _FlutterSkillRuleTest {
  static Map<String, Future<void> Function(_AvoidSilentRepositoryNullReturnTest)> get _allCases =>
      caseSet<_AvoidSilentRepositoryNullReturnTest>(
        parent: const {},
        own: {
          'test_reportsNullRepositoryReturn': (t) => t._reportsNullRepositoryReturn(),
          'test_allowsEnsureBeforeNullCheck': (t) => t._allowsEnsureBeforeNullCheck(),
        },
      );

  @override
  void setUp() {
    rule = AvoidSilentRepositoryNullReturn();
    super.setUp();
  }

  Future<void> _reportsNullRepositoryReturn() async {
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

  Future<void> _allowsEnsureBeforeNullCheck() async {
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

final class _AvoidSyncNotifierStateReadTest extends _FlutterSkillRuleTest {
  static Map<String, Future<void> Function(_AvoidSyncNotifierStateReadTest)> get _allCases =>
      caseSet<_AvoidSyncNotifierStateReadTest>(
        parent: const {},
        own: {
          'test_reportsStateReadInSyncBuild': (t) => t._reportsStateReadInSyncBuild(),
          'test_reportsPostfixIncrementOfStateInSyncBuild': (t) =>
              t._reportsPostfixIncrementOfStateInSyncBuild(),
          'test_reportsPrefixIncrementOfStateInSyncBuild': (t) =>
              t._reportsPrefixIncrementOfStateInSyncBuild(),
          'test_reportsThisStateIncrementInSyncBuild': (t) =>
              t._reportsThisStateIncrementInSyncBuild(),
          'test_reportsCompoundAssignmentOfStateInSyncBuild': (t) =>
              t._reportsCompoundAssignmentOfStateInSyncBuild(),
          'test_reportsCascadeAndSuperStateReadsInSyncBuild': (t) =>
              t._reportsCascadeAndSuperStateReadsInSyncBuild(),
          'test_allowsPlainWriteOfStateInSyncBuild': (t) => t._allowsPlainWriteOfStateInSyncBuild(),
          'test_reportsLoadAndStateReadInsideMicrotask': (t) =>
              t._reportsLoadAndStateReadInsideMicrotask(),
          'test_allowsLocalVariableNamedStateInsideMicrotask': (t) =>
              t._allowsLocalVariableNamedStateInsideMicrotask(),
          'test_allowsStateOfAnotherObjectInsideMicrotask': (t) =>
              t._allowsStateOfAnotherObjectInsideMicrotask(),
          'test_reportsLoadInsideShorthandMicrotaskClosure': (t) =>
              t._reportsLoadInsideShorthandMicrotaskClosure(),
          'test_reportsLoadTearOffPassedToMicrotask': (t) =>
              t._reportsLoadTearOffPassedToMicrotask(),
          'test_reportsLoadTearOffPassedToShorthandMicrotask': (t) =>
              t._reportsLoadTearOffPassedToShorthandMicrotask(),
          'test_reportsHelperThatReadsStateTransitively': (t) =>
              t._reportsHelperThatReadsStateTransitively(),
          'test_allowsHelpersThatOnlyWriteOrReadAfterAwait': (t) =>
              t._allowsHelpersThatOnlyWriteOrReadAfterAwait(),
          'test_severityIsError': (t) => t._severityIsError(),
        },
      );

  @override
  void setUp() {
    rule = AvoidSyncNotifierStateRead();
    super.setUp();
  }

  Future<void> _reportsStateReadInSyncBuild() async {
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

  Future<void> _reportsPostfixIncrementOfStateInSyncBuild() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';

class TodosNotifier extends Notifier<int> {
  @override
  int build() {
    state++;
    return 0;
  }
}
''';
    await assertDiagnostics(source, [lintFor(source, 'state')]);
  }

  Future<void> _reportsPrefixIncrementOfStateInSyncBuild() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';

class TodosNotifier extends Notifier<int> {
  @override
  int build() {
    --state;
    return 0;
  }
}
''';
    await assertDiagnostics(source, [lintFor(source, 'state')]);
  }

  Future<void> _reportsThisStateIncrementInSyncBuild() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';

class TodosNotifier extends Notifier<int> {
  @override
  int build() {
    this.state++;
    return 0;
  }
}
''';
    await assertDiagnostics(source, [lintFor(source, 'state')]);
  }

  Future<void> _reportsCompoundAssignmentOfStateInSyncBuild() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';

class TodosNotifier extends Notifier<int> {
  @override
  int build() {
    state += 1;
    this.state -= 1;
    return 0;
  }
}
''';
    final second = source.indexOf('state -=');
    await assertDiagnostics(source, [lintFor(source, 'state'), lint(second, 'state'.length)]);
  }

  Future<void> _reportsCascadeAndSuperStateReadsInSyncBuild() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';

class TodosNotifier extends Notifier<int> {
  @override
  int build() {
    this..state += 1;
    this..state.abs();
    print(super.state);
    super.state++;
    return 0;
  }
}
''';
    final reads = RegExp(r'\bstate\b').allMatches(source.substring(source.indexOf('int build')));
    final start = source.indexOf('int build');
    await assertDiagnostics(source, [
      for (final read in reads) lint(start + read.start, 'state'.length),
    ]);
  }

  Future<void> _allowsPlainWriteOfStateInSyncBuild() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

class TodosNotifier extends Notifier<int> {
  @override
  int build() {
    state = 1;
    this.state = 2;
    return 0;
  }
}
''');
  }

  Future<void> _reportsLoadAndStateReadInsideMicrotask() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';

class TodosNotifier extends Notifier<int> {
  @override
  int build() {
    Future.microtask(() {
      _loadTodos();
      print(state);
    });
    return 0;
  }

  void _loadTodos() {}
}
''';
    await assertDiagnostics(source, [lintFor(source, '_loadTodos()'), lintFor(source, 'state')]);
  }

  Future<void> _allowsLocalVariableNamedStateInsideMicrotask() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

class TodosNotifier extends Notifier<int> {
  @override
  int build() {
    Future.microtask(() {
      final state = 1;
      print(state);
    });
    return 0;
  }
}
''');
  }

  Future<void> _allowsStateOfAnotherObjectInsideMicrotask() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

class Holder {
  int state = 0;
}

class TodosNotifier extends Notifier<int> {
  @override
  int build() {
    final other = Holder();
    Future.microtask(() {
      print(other.state);
    });
    return 0;
  }
}
''');
  }

  Future<void> _reportsLoadInsideShorthandMicrotaskClosure() async {
    const source = r'''
import 'dart:async';

import 'package:riverpod/riverpod.dart';

class TodosNotifier extends Notifier<int> {
  @override
  int build() {
    unawaited(.microtask(() => _loadTodos()));
    return 0;
  }

  void _loadTodos() {}
}
''';
    await assertDiagnostics(source, [lintFor(source, '_loadTodos()')]);
  }

  Future<void> _reportsLoadTearOffPassedToMicrotask() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';

class TodosNotifier extends Notifier<int> {
  @override
  int build() {
    Future.microtask(_loadTodos);
    return 0;
  }

  void _loadTodos() {}
}
''';
    await assertDiagnostics(source, [lintFor(source, '_loadTodos')]);
  }

  Future<void> _reportsLoadTearOffPassedToShorthandMicrotask() async {
    const source = r'''
import 'dart:async';

import 'package:riverpod/riverpod.dart';

class TodosNotifier extends Notifier<int> {
  @override
  int build() {
    unawaited(.microtask(_loadTodos));
    return 0;
  }

  void _loadTodos() {}
}
''';
    await assertDiagnostics(source, [lintFor(source, '_loadTodos')]);
  }

  Future<void> _reportsHelperThatReadsStateTransitively() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';

class TodosNotifier extends Notifier<int> {
  @override
  int build() {
    _prime();
    _warm();
    return 0;
  }

  void _prime() {
    if (state > 0) return;
  }

  void _warm() => this._touch();

  void _touch() => print(state);
}
''';
    await assertDiagnostics(source, [lintFor(source, '_prime()'), lintFor(source, '_warm()')]);
  }

  Future<void> _allowsHelpersThatOnlyWriteOrReadAfterAwait() async {
    await assertNoDiagnostics(r'''
import 'dart:async';

import 'package:riverpod/riverpod.dart';

class TodosNotifier extends Notifier<int> {
  @override
  int build() {
    _seed();
    unawaited(_later());
    _register(() => state);
    return 0;
  }

  void _seed() {
    state = 1;
  }

  Future<void> _later() async {
    await Future<void>.value();
    state = state + 1;
  }

  void _register(int Function() read) {}
}
''');
  }

  Future<void> _severityIsError() async {
    expect(AvoidSyncNotifierStateRead.code.severity, DiagnosticSeverity.ERROR);
  }
}

final class _UseUnawaitedForFireAndForgetFuturesTest extends _FlutterSkillRuleTest {
  static Map<String, Future<void> Function(_UseUnawaitedForFireAndForgetFuturesTest)>
  get _allCases => caseSet<_UseUnawaitedForFireAndForgetFuturesTest>(
    parent: const {},
    own: {
      'test_reportsFutureDroppedFromVoidCallback': (t) => t._reportsFutureDroppedFromVoidCallback(),
      'test_reportsFutureDroppedFromNullableNamedVoidCallback': (t) =>
          t._reportsFutureDroppedFromNullableNamedVoidCallback(),
      'test_allowsFutureFromNamedFutureCallback': (t) => t._allowsFutureFromNamedFutureCallback(),
      'test_allowsUnawaitedFutureFromVoidCallback': (t) =>
          t._allowsUnawaitedFutureFromVoidCallback(),
      'test_allowsAwaitedFutureFromAsyncCallback': (t) => t._allowsAwaitedFutureFromAsyncCallback(),
    },
  );

  @override
  void setUp() {
    rule = UseUnawaitedForFireAndForgetFutures();
    super.setUp();
  }

  Future<void> _reportsFutureDroppedFromVoidCallback() async {
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

  Future<void> _reportsFutureDroppedFromNullableNamedVoidCallback() async {
    const source = r'''
Future<void> trackTap() async {}

class TextButton {
  const TextButton({this.onPressed});

  final void Function()? onPressed;
}

TextButton example() {
  return TextButton(
    onPressed: () {
      trackTap();
    },
  );
}
''';

    await assertDiagnostics(source, [lintForLast(source, 'trackTap()')]);
  }

  Future<void> _allowsFutureFromNamedFutureCallback() async {
    await assertNoDiagnostics(r'''
Future<void> trackTap() async {}

class AsyncButton {
  const AsyncButton({this.onPressed});

  final Future<void> Function()? onPressed;
}

AsyncButton example() {
  return AsyncButton(
    onPressed: () {
      return trackTap();
    },
  );
}
''');
  }

  Future<void> _allowsUnawaitedFutureFromVoidCallback() async {
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

  Future<void> _allowsAwaitedFutureFromAsyncCallback() async {
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

final class _UseRefMountedAfterAwaitTest extends _FlutterSkillRuleTest {
  static Map<String, Future<void> Function(_UseRefMountedAfterAwaitTest)> get _allCases =>
      caseSet<_UseRefMountedAfterAwaitTest>(
        parent: const {},
        own: {
          'test_reportsRefAfterAwait': (t) => t._reportsRefAfterAwait(),
          'test_allowsGuardedRefAfterAwait': (t) => t._allowsGuardedRefAfterAwait(),
          'test_allowsCompoundMountedAndRevisionGuard': (t) =>
              t._allowsCompoundMountedAndRevisionGuard(),
          'test_shadowedDirectMountedGuardStillReports': (t) =>
              t._shadowedDirectMountedGuardStillReports(),
          'test_impureSuffixCanInvalidateMountedGuard': (t) =>
              t._impureSuffixCanInvalidateMountedGuard(),
          'test_lazyLocalSuffixCannotInvalidateMountedGuard': (t) =>
              t._lazyLocalSuffixCannotInvalidateMountedGuard(),
          'test_lazyStaticFieldSuffixCannotInvalidateMountedGuard': (t) =>
              t._lazyStaticFieldSuffixCannotInvalidateMountedGuard(),
          'test_overriddenFieldSuffixCannotInvalidateMountedGuard': (t) =>
              t._overriddenFieldSuffixCannotInvalidateMountedGuard(),
          'test_awaitInSurvivingElseRequiresFreshGuard': (t) =>
              t._awaitInSurvivingElseRequiresFreshGuard(),
          'test_incompleteMountedGuardStillReports': (t) => t._incompleteMountedGuardStillReports(),
          'test_mountedReturnBranchCannotUseStateBeforeReturn': (t) =>
              t._mountedReturnBranchCannotUseStateBeforeReturn(),
          'test_conjunctiveMountedGuardStillReports': (t) =>
              t._conjunctiveMountedGuardStillReports(),
          'test_allowsResolvedPrivateMountedHelper': (t) => t._allowsResolvedPrivateMountedHelper(),
          'test_revisionOnlyHelperStillReports': (t) => t._revisionOnlyHelperStillReports(),
          'test_mixinOverriddenPrivateHelperStillReports': (t) =>
              t._mixinOverriddenPrivateHelperStillReports(),
          'test_helperCannotTrustGettersOverloadsOrShadowedRef': (t) =>
              t._helperCannotTrustGettersOverloadsOrShadowedRef(),
          'test_helperCannotTrustOverriddenRefGetter': (t) =>
              t._helperCannotTrustOverriddenRefGetter(),
          'test_allowsSkillMountedGuardExamples': (t) => t._allowsSkillMountedGuardExamples(),
          'test_reportsNestedAccessAfterAwait': (t) => t._reportsNestedAccessAfterAwait(),
          'test_reportsInlineLoopAndClosureAwaits': (t) => t._reportsInlineLoopAndClosureAwaits(),
        },
      );

  @override
  void setUp() {
    rule = UseRefMountedAfterAwait();
    super.setUp();
  }

  Future<void> _reportsRefAfterAwait() async {
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

  Future<void> _allowsGuardedRefAfterAwait() async {
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

  Future<void> _allowsCompoundMountedAndRevisionGuard() async {
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

  Future<void> _shadowedDirectMountedGuardStillReports() async {
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

  Future<void> _impureSuffixCanInvalidateMountedGuard() async {
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

  Future<void> _lazyLocalSuffixCannotInvalidateMountedGuard() async {
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

  Future<void> _lazyStaticFieldSuffixCannotInvalidateMountedGuard() async {
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

  Future<void> _overriddenFieldSuffixCannotInvalidateMountedGuard() async {
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

  Future<void> _awaitInSurvivingElseRequiresFreshGuard() async {
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

  Future<void> _incompleteMountedGuardStillReports() async {
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

  Future<void> _mountedReturnBranchCannotUseStateBeforeReturn() async {
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

  Future<void> _conjunctiveMountedGuardStillReports() async {
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

  Future<void> _allowsResolvedPrivateMountedHelper() async {
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

  Future<void> _revisionOnlyHelperStillReports() async {
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

  Future<void> _mixinOverriddenPrivateHelperStillReports() async {
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

  Future<void> _helperCannotTrustGettersOverloadsOrShadowedRef() async {
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

  Future<void> _helperCannotTrustOverriddenRefGetter() async {
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

  Future<void> _allowsSkillMountedGuardExamples() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';
class Repo {
  Future<void> save(int value) async {}
  Future<int> fetch() async => 0;
}
final repoProvider = Provider((ref) => Repo());
class OrderNotifier extends Notifier<int> {
  @override
  int build() => 0;
  bool _isActive() => ref.mounted;
  Future<void> save() async {
    state = 1;
    try {
      await ref.read(repoProvider).save(state);
      if (!ref.mounted) return;
      state = 2;
    } catch (error) {
      if (!ref.mounted) return;
      state = 3;
    }
  }
  Future<void> refresh() async {
    state = 1;
    try {
      await ref.read(repoProvider).fetch();
    } finally {
      if (ref.mounted) {
        state = 0;
      }
    }
  }
  Future<void> loadMore() async {
    if (state > 9) return;
    state = 1;
    final page = await ref.read(repoProvider).fetch();
    if (!ref.mounted) return;
    state = page;
  }
  Future<void> reloadAll(List<int> ids) async {
    for (final id in ids) {
      if (!_isActive()) return;
      state = id;
      await ref.read(repoProvider).save(id);
    }
  }
  Future<void> reloadEach(List<int> ids) async {
    for (final id in ids) {
      state = id;
      await ref.read(repoProvider).save(id);
      if (!ref.mounted) return;
    }
    state = 0;
  }
  void start() {
    Future.microtask(() async {
      await ref.read(repoProvider).fetch();
      if (!ref.mounted) return;
      state = 1;
    });
  }
}
''');
  }

  Future<void> _reportsNestedAccessAfterAwait() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';
class OrderNotifier extends Notifier<int> {
  @override
  int build() => 0;
  Future<void> ifBlock(bool empty) async {
    await Future<void>.value();
    if (empty) {
      state = 1;
    }
  }
  Future<void> tryBody() async {
    await Future<void>.value();
    try {
      state = 2;
    } catch (_) {
      return;
    }
  }
  Future<void> catchBody() async {
    try {
      await Future<void>.value();
      if (!ref.mounted) return;
    } catch (error) {
      state = 3;
    }
  }
  Future<void> finallyBody() async {
    try {
      await Future<void>.value();
    } finally {
      state = 4;
    }
  }
}
''';
    await assertDiagnostics(source, [
      lint(source.indexOf('state = 1'), 5),
      lint(source.indexOf('state = 2'), 5),
      lint(source.indexOf('state = 3'), 5),
      lint(source.indexOf('state = 4'), 5),
    ]);
  }

  Future<void> _reportsInlineLoopAndClosureAwaits() async {
    const source = r'''
import 'dart:async';
import 'package:riverpod/riverpod.dart';
class OrderNotifier extends Notifier<int> {
  @override
  int build() => 0;
  Future<int> fetch() async => 1;
  Future<void> inline() async {
    state = state + await fetch();
  }
  Future<void> argument() async {
    print([await fetch(), ref.hashCode]);
  }
  Future<void> pages() async {
    for (var i = 0; i < 3; i++) {
      state = i;
      await fetch();
    }
  }
  void start() {
    unawaited(Future.microtask(() async {
      final value = await fetch();
      state = value;
    }));
  }
}
''';
    await assertDiagnostics(source, [
      lint(source.indexOf('state = state'), 5),
      lint(source.indexOf('ref.hashCode'), 12),
      lint(source.indexOf('state = i'), 5),
      lint(source.indexOf('state = value'), 5),
    ]);
  }
}

void _defineFlutterSkillRulesPart02Tests() {
  analysisRuleSuite<_UseRefMountedAfterAwaitTest>(
    'UseRefMountedAfterAwaitTest',
    _UseRefMountedAfterAwaitTest.new,
    _UseRefMountedAfterAwaitTest._allCases,
  );
  analysisRuleSuite<_AvoidRunZonedGuardedTest>(
    'AvoidRunZonedGuardedTest',
    _AvoidRunZonedGuardedTest.new,
    _AvoidRunZonedGuardedTest._allCases,
  );
  analysisRuleSuite<_AvoidSilentRepositoryNullReturnTest>(
    'AvoidSilentRepositoryNullReturnTest',
    _AvoidSilentRepositoryNullReturnTest.new,
    _AvoidSilentRepositoryNullReturnTest._allCases,
  );
  analysisRuleSuite<_AvoidSyncNotifierStateReadTest>(
    'AvoidSyncNotifierStateReadTest',
    _AvoidSyncNotifierStateReadTest.new,
    _AvoidSyncNotifierStateReadTest._allCases,
  );
  analysisRuleSuite<_UseUnawaitedForFireAndForgetFuturesTest>(
    'UseUnawaitedForFireAndForgetFuturesTest',
    _UseUnawaitedForFireAndForgetFuturesTest.new,
    _UseUnawaitedForFireAndForgetFuturesTest._allCases,
  );
}
