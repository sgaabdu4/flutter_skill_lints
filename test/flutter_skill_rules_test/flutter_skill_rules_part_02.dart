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
          'test_reportsNoStateReadForLocalVariableNamedStateInsideMicrotask': (t) =>
              t._reportsNoStateReadForLocalVariableNamedStateInsideMicrotask(),
          'test_reportsNoStateReadForStateOfAnotherObjectInsideMicrotask': (t) =>
              t._reportsNoStateReadForStateOfAnotherObjectInsideMicrotask(),
          'test_reportsLoadInsideShorthandMicrotaskClosure': (t) =>
              t._reportsLoadInsideShorthandMicrotaskClosure(),
          'test_reportsLoadTearOffPassedToMicrotask': (t) =>
              t._reportsLoadTearOffPassedToMicrotask(),
          'test_reportsLoadTearOffPassedToShorthandMicrotask': (t) =>
              t._reportsLoadTearOffPassedToShorthandMicrotask(),
          'test_reportsLoadInsideImportPrefixedMicrotask': (t) =>
              t._reportsLoadInsideImportPrefixedMicrotask(),
          'test_reportsLoadInsideTypedefAliasedMicrotask': (t) =>
              t._reportsLoadInsideTypedefAliasedMicrotask(),
          'test_reportsLoadInsideThenOfMicrotask': (t) => t._reportsLoadInsideThenOfMicrotask(),
          'test_reportsLoadInsideCascadeOnMicrotask': (t) =>
              t._reportsLoadInsideCascadeOnMicrotask(),
          'test_reportsLoadInsideTypedShorthandMicrotask': (t) =>
              t._reportsLoadInsideTypedShorthandMicrotask(),
          'test_reportsLoadInsideCatchErrorOfMicrotask': (t) =>
              t._reportsLoadInsideCatchErrorOfMicrotask(),
          'test_reportsLoadInsideWhenCompleteOfMicrotask': (t) =>
              t._reportsLoadInsideWhenCompleteOfMicrotask(),
          'test_reportsLoadInsideOnErrorClosureOfMicrotask': (t) =>
              t._reportsLoadInsideOnErrorClosureOfMicrotask(),
          'test_reportsLoadPassedAsOnErrorOfMicrotask': (t) =>
              t._reportsLoadPassedAsOnErrorOfMicrotask(),
          'test_reportsLoadTearOffPassedToThenOfMicrotask': (t) =>
              t._reportsLoadTearOffPassedToThenOfMicrotask(),
          'test_allowsMicrotaskOutsideBuild': (t) => t._allowsMicrotaskOutsideBuild(),
          'test_reportsNoLoadOrStateReadForMicrotaskWithoutLoadWork': (t) =>
              t._reportsNoLoadOrStateReadForMicrotaskWithoutLoadWork(),
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

  @override
  void assertDiagnosticsIn(List<Diagnostic> diagnostics, List<Object?> expectedDiagnostics) =>
      super.assertDiagnosticsIn([
        for (final diagnostic in diagnostics)
          if (diagnostic.diagnosticCode != AvoidSyncNotifierStateRead.providerCode) diagnostic,
      ], expectedDiagnostics.cast());

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

  Future<void> _reportsNoStateReadForLocalVariableNamedStateInsideMicrotask() async {
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

  Future<void> _reportsNoStateReadForStateOfAnotherObjectInsideMicrotask() async {
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

  Future<void> _reportsLoadInsideImportPrefixedMicrotask() async {
    const source = r'''
import 'dart:async' as async;
import 'package:riverpod/riverpod.dart';

class TodosNotifier extends Notifier<int> {
  @override
  int build() {
    async.Future.microtask(() => _loadTodos());
    return 0;
  }

  void _loadTodos() {}
}
''';
    await assertDiagnostics(source, [lintFor(source, '_loadTodos()')]);
  }

  Future<void> _reportsLoadInsideTypedefAliasedMicrotask() async {
    const source = r'''
import 'dart:async';
import 'package:riverpod/riverpod.dart';

typedef Hop = Future<void>;

class TodosNotifier extends Notifier<int> {
  @override
  int build() {
    Hop.microtask(() => _loadTodos());
    return 0;
  }

  void _loadTodos() {}
}
''';
    await assertDiagnostics(source, [lintFor(source, '_loadTodos()')]);
  }

  Future<void> _reportsLoadInsideThenOfMicrotask() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';

class TodosNotifier extends Notifier<int> {
  @override
  int build() {
    Future.microtask(() {}).then((_) => _loadTodos());
    return 0;
  }

  void _loadTodos() {}
}
''';
    await assertDiagnostics(source, [lintFor(source, '_loadTodos()')]);
  }

  Future<void> _reportsLoadInsideCascadeOnMicrotask() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';

class TodosNotifier extends Notifier<int> {
  @override
  int build() {
    Future<void>.microtask(() {})..then((_) => _loadTodos());
    return 0;
  }

  void _loadTodos() {}
}
''';
    await assertDiagnostics(source, [lintFor(source, '_loadTodos()')]);
  }

  Future<void> _reportsLoadInsideTypedShorthandMicrotask() async {
    const source = r'''
import 'dart:async';
import 'package:riverpod/riverpod.dart';

class TodosNotifier extends Notifier<int> {
  @override
  int build() {
    final Future<void> hop = .microtask(() => _loadTodos());
    return 0;
  }

  void _loadTodos() {}
}
''';
    await assertDiagnostics(source, [lintFor(source, '_loadTodos()')]);
  }

  Future<void> _reportsLoadInsideCatchErrorOfMicrotask() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';

class TodosNotifier extends Notifier<int> {
  @override
  int build() {
    Future.microtask(() {}).catchError((_) => _loadTodos());
    return 0;
  }

  void _loadTodos() {}
}
''';
    await assertDiagnostics(source, [lintFor(source, '_loadTodos()')]);
  }

  Future<void> _reportsLoadInsideWhenCompleteOfMicrotask() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';

class TodosNotifier extends Notifier<int> {
  @override
  int build() {
    Future.microtask(() {}).whenComplete(() => _loadTodos());
    return 0;
  }

  void _loadTodos() {}
}
''';
    await assertDiagnostics(source, [lintFor(source, '_loadTodos()')]);
  }

  Future<void> _reportsLoadInsideOnErrorClosureOfMicrotask() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';

class TodosNotifier extends Notifier<int> {
  @override
  int build() {
    Future.microtask(() {}).then((_) {}, onError: (_) => _loadTodos());
    return 0;
  }

  void _loadTodos() {}
}
''';
    await assertDiagnostics(source, [lintFor(source, '_loadTodos()')]);
  }

  Future<void> _reportsLoadPassedAsOnErrorOfMicrotask() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';

class TodosNotifier extends Notifier<int> {
  @override
  int build() {
    Future.microtask(() {}).then((_) {}, onError: _loadTodos);
    return 0;
  }

  void _loadTodos(Object error) {}
}
''';
    await assertDiagnostics(source, [lintFor(source, '_loadTodos')]);
  }

  Future<void> _reportsLoadTearOffPassedToThenOfMicrotask() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';

class TodosNotifier extends Notifier<int> {
  @override
  int build() {
    Future.microtask(() {}).then(_loadTodos);
    return 0;
  }

  void _loadTodos(Object? value) {}
}
''';
    await assertDiagnostics(source, [lintFor(source, '_loadTodos')]);
  }

  Future<void> _allowsMicrotaskOutsideBuild() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

class TodosNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void refresh() {
    Future.microtask(() => _loadTodos());
    Future.microtask(() {}).then((_) => _loadTodos());
  }

  void _loadTodos() {}
}
''');
  }

  Future<void> _reportsNoLoadOrStateReadForMicrotaskWithoutLoadWork() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

class TodosNotifier extends Notifier<int> {
  @override
  int build() {
    Future.microtask(() {}).then((_) => print('done'));
    return 0;
  }
}
''');
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

void _defineFlutterSkillRulesPart02Tests() {
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
}
