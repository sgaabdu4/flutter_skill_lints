part of '../persistence_crash_source_rules_test.dart';

abstract class _HiveRuleTest extends _PersistenceCrashRuleTest {
  @override
  void setUp() {
    newPackage('hive_ce').addFile('lib/hive_ce.dart', r'''
class HiveType {
  const HiveType({required this.typeId});
  final int typeId;
}

class HiveField {
  const HiveField(this.index);
  final int index;
}

class AdapterSpec<T> {
  const AdapterSpec();
}

class GenerateAdapters {
  const GenerateAdapters(this.specs, {this.firstTypeId = 0, this.reservedTypeIds = const {}});
  final List<AdapterSpec<Object?>> specs;
  final int firstTypeId;
  final Set<int> reservedTypeIds;
}

abstract class Box<E> {
  E? get(Object key);
}

abstract class HiveInterface {
  Future<Box<E>> openBox<E>(String name);
}

HiveInterface get Hive => throw UnimplementedError();
''');
    newPackage('freezed_annotation').addFile('lib/freezed_annotation.dart', r'''
class Freezed {
  const Freezed();
}

const freezed = Freezed();
''');
    newPackage('riverpod').addFile('lib/riverpod.dart', r'''
abstract class Notifier<T> {
  T build();
  late T state;
}
''');
    super.setUp();
  }

  void newLibFile(String name, String content) => newFile('$testPackageLibPath/$name', content);
}

final class _HiveDuplicateFieldIdTest extends _HiveRuleTest {
  static Map<String, Future<void> Function(_HiveDuplicateFieldIdTest)> get _allCases =>
      caseSet<_HiveDuplicateFieldIdTest>(
        parent: const {},
        own: {
          'test_reportsDuplicateField': (t) => t._reportsDuplicateField(),
          'test_allowsSameIndexesInSeparateHiveTypes': (t) =>
              t._allowsSameIndexesInSeparateHiveTypes(),
        },
      );

  @override
  String get ruleName => 'hive_duplicate_field_id';

  Future<void> _reportsDuplicateField() async {
    await assertRuleDiagnostic(r'''
import 'package:hive_ce/hive_ce.dart';

@HiveType(typeId: 1)
class CacheEntry {
  @HiveField(0)
  final String key = '';

  @HiveField(0)
  final String value = '';
}
''', '@HiveField(0)\n  final String value');
  }

  Future<void> _allowsSameIndexesInSeparateHiveTypes() async {
    await assertRuleNoDiagnostics(r'''
import 'package:hive_ce/hive_ce.dart';

@HiveType(typeId: 1)
class FirstEntry {
  @HiveField(0)
  final String key = '';

  @HiveField(1)
  final String value = '';
}

@HiveType(typeId: 2)
class SecondEntry {
  @HiveField(0)
  final String key = '';

  @HiveField(1)
  final String value = '';
}
''');
  }
}

final class _HiveDuplicateTypeIdTest extends _HiveRuleTest {
  static Map<String, Future<void> Function(_HiveDuplicateTypeIdTest)> get _allCases =>
      caseSet<_HiveDuplicateTypeIdTest>(
        parent: const {},
        own: {
          'test_reportsDuplicateTypeId': (t) => t._reportsDuplicateTypeId(),
          'test_reportsDuplicateWithImportedHiveType': (t) =>
              t._reportsDuplicateWithImportedHiveType(),
          'test_reportsDuplicatesJoinedThroughGeneratedRegistrar': (t) =>
              t._reportsDuplicatesJoinedThroughGeneratedRegistrar(),
          'test_reportsDuplicatesJoinedByDirectImports': (t) =>
              t._reportsDuplicatesJoinedByDirectImports(),
          'test_leavesDeeperJoinToTheImportedLibrary': (t) =>
              t._leavesDeeperJoinToTheImportedLibrary(),
          'test_allowsDistinctTypeIdsAcrossFiles': (t) => t._allowsDistinctTypeIdsAcrossFiles(),
        },
      );

  @override
  String get ruleName => 'hive_duplicate_type_id';

  Future<void> _reportsDuplicateTypeId() async {
    await assertRuleDiagnostic(r'''
import 'package:hive_ce/hive_ce.dart';

@HiveType(typeId: 1)
class CacheEntry {}

@HiveType(typeId: 1)
class UserEntry {}
''', '@HiveType(typeId: 1)\nclass UserEntry');
  }

  Future<void> _reportsDuplicateWithImportedHiveType() async {
    newLibFile('first_entry.dart', r'''
import 'package:hive_ce/hive_ce.dart';

@HiveType(typeId: 7)
class FirstEntry {}
''');
    await assertRuleDiagnostic(r'''
import 'package:hive_ce/hive_ce.dart';
import 'package:test/first_entry.dart';

@HiveType(typeId: 7)
class SecondEntry {}
''', '@HiveType(typeId: 7)');
  }

  Future<void> _reportsDuplicatesJoinedThroughGeneratedRegistrar() async {
    _newCrossFileEntries(secondTypeId: 7);
    newLibFile('hive_registrar.g.dart', r'''
import 'package:test/first_entry.dart';
import 'package:test/second_entry.dart';
''');
    await assertRuleDiagnostic(r'''
import 'package:test/hive_registrar.g.dart';

void initializeStorage() {}
''', "import 'package:test/hive_registrar.g.dart';");
  }

  Future<void> _reportsDuplicatesJoinedByDirectImports() async {
    _newCrossFileEntries(secondTypeId: 7);
    await assertRuleDiagnostic(r'''
import 'package:test/first_entry.dart';
import 'package:test/second_entry.dart';

void initializeStorage() {}
''', "import 'package:test/second_entry.dart';");
  }

  Future<void> _leavesDeeperJoinToTheImportedLibrary() async {
    _newCrossFileEntries(secondTypeId: 7);
    newLibFile('entries.dart', r'''
export 'package:test/first_entry.dart';
export 'package:test/second_entry.dart';
''');
    await assertRuleNoDiagnostics(r'''
import 'package:test/entries.dart';

void initializeStorage() {}
''');
  }

  Future<void> _allowsDistinctTypeIdsAcrossFiles() async {
    _newCrossFileEntries(secondTypeId: 8);
    await assertRuleNoDiagnostics(r'''
import 'package:test/first_entry.dart';
import 'package:test/second_entry.dart';

void initializeStorage() {}
''');
  }

  void _newCrossFileEntries({required int secondTypeId}) {
    newLibFile('first_entry.dart', r'''
import 'package:hive_ce/hive_ce.dart';

@HiveType(typeId: 7)
class FirstEntry {}
''');
    newLibFile('second_entry.dart', '''
import 'package:hive_ce/hive_ce.dart';

@HiveType(typeId: $secondTypeId)
class SecondEntry {}
''');
  }
}

final class _HiveReservedTypeIdsMissingTest extends _HiveRuleTest {
  static Map<String, Future<void> Function(_HiveReservedTypeIdsMissingTest)> get _allCases =>
      caseSet<_HiveReservedTypeIdsMissingTest>(
        parent: const {},
        own: {
          'test_reportsMissingReservedTypeIds': (t) => t._reportsMissingReservedTypeIds(),
          'test_reportsReservationThatOmitsTheHiveTypeId': (t) =>
              t._reportsReservationThatOmitsTheHiveTypeId(),
          'test_reservedTypeIdsPresent_noDiagnostic': (t) =>
              t._reservedTypeIdsPresentNoDiagnostic(),
          'test_reportsHiveTypeInAnotherFileOfTheRegistrationScope': (t) =>
              t._reportsHiveTypeInAnotherFileOfTheRegistrationScope(),
          'test_allowsReservedHiveTypeInAnotherFile': (t) =>
              t._allowsReservedHiveTypeInAnotherFile(),
        },
      );

  @override
  String get ruleName => 'hive_reserved_type_ids_missing';

  Future<void> _reportsMissingReservedTypeIds() async {
    await assertRuleDiagnostic(r'''
import 'package:hive_ce/hive_ce.dart';

@HiveType(typeId: 0)
class CacheEntry {}

@GenerateAdapters([AdapterSpec<User>()], firstTypeId: 1)
void hiveAdapters() {}

class User {}
''', '@GenerateAdapters');
  }

  Future<void> _reportsReservationThatOmitsTheHiveTypeId() async {
    await assertRuleDiagnostic(r'''
import 'package:hive_ce/hive_ce.dart';

@HiveType(typeId: 0)
class CacheEntry {}

@GenerateAdapters([AdapterSpec<User>()], firstTypeId: 1, reservedTypeIds: {5})
void hiveAdapters() {}

class User {}
''', '@GenerateAdapters');
  }

  Future<void> _reservedTypeIdsPresentNoDiagnostic() async {
    await assertRuleNoDiagnostics(r'''
import 'package:hive_ce/hive_ce.dart';

@HiveType(typeId: 0)
class CacheEntry {}

@GenerateAdapters(
  [AdapterSpec<User>()],
  firstTypeId: 1,
  reservedTypeIds: {0},
)
void hiveAdapters() {}

class User {}
''');
  }

  Future<void> _reportsHiveTypeInAnotherFileOfTheRegistrationScope() async {
    _newDocLayout(reservation: '');
    await assertRuleDiagnostic(r'''
import 'package:test/cache_entry.dart';
import 'package:test/hive_adapters.dart';

void initializeStorage() {}
''', "import 'package:test/hive_adapters.dart';");
  }

  Future<void> _allowsReservedHiveTypeInAnotherFile() async {
    _newDocLayout(reservation: ', reservedTypeIds: {0}');
    await assertRuleNoDiagnostics(r'''
import 'package:test/cache_entry.dart';
import 'package:test/hive_adapters.dart';

void initializeStorage() {}
''');
  }

  void _newDocLayout({required String reservation}) {
    newLibFile('cache_entry.dart', r'''
import 'package:hive_ce/hive_ce.dart';

@HiveType(typeId: 0)
class CacheEntry {}
''');
    newLibFile('hive_adapters.dart', '''
import 'package:hive_ce/hive_ce.dart';

class UserModel {}

@GenerateAdapters([AdapterSpec<UserModel>()], firstTypeId: 1$reservation)
void hiveAdapters() {}
''');
  }
}

final class _HiveTypeOnFreezedClassTest extends _HiveRuleTest {
  static Map<String, Future<void> Function(_HiveTypeOnFreezedClassTest)> get _allCases =>
      caseSet<_HiveTypeOnFreezedClassTest>(
        parent: const {},
        own: {
          'test_reportsHiveTypeOnFreezedClass': (t) => t._reportsHiveTypeOnFreezedClass(),
          'test_allowsHiveTypeOnPlainClass': (t) => t._allowsHiveTypeOnPlainClass(),
        },
      );

  @override
  String get ruleName => 'hive_type_on_freezed_class';

  Future<void> _reportsHiveTypeOnFreezedClass() async {
    await assertRuleDiagnostic(r'''
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce/hive_ce.dart';

@freezed
@HiveType(typeId: 31)
class RunModel {}
''', '@HiveType(typeId: 31)');
  }

  Future<void> _allowsHiveTypeOnPlainClass() async {
    await assertRuleNoDiagnostics(r'''
import 'package:hive_ce/hive_ce.dart';

@HiveType(typeId: 0)
class CacheEntry {
  CacheEntry({required this.key});

  @HiveField(0)
  final String key;
}
''');
  }
}

final class _HiveAdapterSpecDomainTypeTest extends _HiveRuleTest {
  static Map<String, Future<void> Function(_HiveAdapterSpecDomainTypeTest)> get _allCases =>
      caseSet<_HiveAdapterSpecDomainTypeTest>(
        parent: const {},
        own: {
          'test_reportsDomainEntitySpec': (t) => t._reportsDomainEntitySpec(),
          'test_allowsDataModelSpec': (t) => t._allowsDataModelSpec(),
        },
      );

  @override
  String get ruleName => 'hive_adapter_spec_domain_type';

  Future<void> _reportsDomainEntitySpec() async {
    newLibFile('features/run/domain/entities/run.dart', 'class Run {}\n');
    await assertRuleDiagnostic(r'''
import 'package:hive_ce/hive_ce.dart';
import 'package:test/features/run/domain/entities/run.dart';

@GenerateAdapters([
  AdapterSpec<Run>(),
], firstTypeId: 1)
void hiveAdapters() {}
''', 'AdapterSpec<Run>()');
  }

  Future<void> _allowsDataModelSpec() async {
    newLibFile('features/run/data/models/run_model.dart', 'class RunModel {}\n');
    await assertRuleNoDiagnostics(r'''
import 'package:hive_ce/hive_ce.dart';
import 'package:test/features/run/data/models/run_model.dart';

@GenerateAdapters([
  AdapterSpec<RunModel>(),
], firstTypeId: 1)
void hiveAdapters() {}
''');
  }
}

final class _NotifierHiveAccessTest extends _HiveRuleTest {
  static Map<String, Future<void> Function(_NotifierHiveAccessTest)> get _allCases =>
      caseSet<_NotifierHiveAccessTest>(
        parent: const {},
        own: {
          'test_reportsHiveInNotifier': (t) => t._reportsHiveInNotifier(),
          'test_allowsRepositoryNotifierAndHiveDatasource': (t) =>
              t._allowsRepositoryNotifierAndHiveDatasource(),
        },
      );

  @override
  String get ruleName => 'notifier_hive_access';

  Future<void> _reportsHiveInNotifier() async {
    await assertRuleDiagnostic(r'''
import 'package:hive_ce/hive_ce.dart';
import 'package:riverpod/riverpod.dart';

class CountNotifier extends Notifier<int> {
  @override
  int build() => 0;

  Future<void> load() async {
    final box = await Hive.openBox<int>('counts');
    state = box.get('n') ?? 0;
  }
}
''', "Hive.openBox<int>('counts');");
  }

  Future<void> _allowsRepositoryNotifierAndHiveDatasource() async {
    await assertRuleNoDiagnostics(r'''
import 'package:hive_ce/hive_ce.dart';
import 'package:riverpod/riverpod.dart';

abstract interface class ICountRepository {
  Future<int> load();
}

class HiveCountDatasource implements ICountRepository {
  @override
  Future<int> load() async {
    final box = await Hive.openBox<int>('counts');
    return box.get('n') ?? 0;
  }
}

class CountNotifier extends Notifier<int> {
  CountNotifier(this._repository);

  final ICountRepository _repository;

  @override
  int build() => 0;

  Future<void> load() async {
    state = await _repository.load();
  }
}
''');
  }
}

final class _HiveTestCloseMissingTest extends _PersistenceCrashRuleTest {
  static Map<String, Future<void> Function(_HiveTestCloseMissingTest)> get _allCases =>
      caseSet<_HiveTestCloseMissingTest>(
        parent: const {},
        own: {
          'test_reportsMissingCloseInTest': (t) => t._reportsMissingCloseInTest(),
          'test_closePresent_noDiagnostic': (t) => t._closePresentNoDiagnostic(),
        },
      );

  @override
  String get ruleName => 'hive_test_close_missing';

  Future<void> _reportsMissingCloseInTest() async {
    await assertRuleDiagnostic(
      r'''
class Hive {
  static void init(String path) {}
}

void setUpStorage() {
  Hive.init('tmp');
}
''',
      'Hive.init',
      path: '$testPackageRootPath/test/hive_helper_test.dart',
    );
  }

  Future<void> _closePresentNoDiagnostic() async {
    await assertRuleNoDiagnostics(r'''
class Hive {
  static void init(String path) {}
  static Future<void> close() async {}
}

void setUpStorage() {
  Hive.init('tmp');
}

Future<void> tearDownStorage() async {
  await Hive.close();
}
''', path: '$testPackageRootPath/test/hive_helper_test.dart');
  }
}

final class _FireAndForgetMissingCatchTest extends _PersistenceCrashRuleTest {
  static Map<String, Future<void> Function(_FireAndForgetMissingCatchTest)> get _allCases =>
      caseSet<_FireAndForgetMissingCatchTest>(
        parent: const {},
        own: {
          'test_reportsInlineAsyncMissingCatch': (t) => t._reportsInlineAsyncMissingCatch(),
          'test_inlineAsyncWithCatch_noDiagnostic': (t) => t._inlineAsyncWithCatchNoDiagnostic(),
          'test_calleeThatCatchesInternally_noDiagnostic': (t) =>
              t._calleeThatCatchesInternallyNoDiagnostic(),
          'test_reportsCalleeWithoutCatch': (t) => t._reportsCalleeWithoutCatch(),
          'test_resolvesCalleesInImportedLibraries': (t) => t._resolvesCalleesInImportedLibraries(),
          'test_emptyCalleeBody_noDiagnostic': (t) => t._emptyCalleeBodyNoDiagnostic(),
          'test_mutationRunCallee_noDiagnostic': (t) => t._mutationRunCalleeNoDiagnostic(),
          'test_reportsLocalMutationLookalike': (t) => t._reportsLocalMutationLookalike(),
          'test_navigationCallee_noDiagnostic': (t) => t._navigationCalleeNoDiagnostic(),
          'test_maybePopCallee_noDiagnostic': (t) => t._maybePopCalleeNoDiagnostic(),
          'test_reportsNavigationThenUncaughtRemoteWork': (t) =>
              t._reportsNavigationThenUncaughtRemoteWork(),
          'test_calleeDelegatingToCatchingMethod_noDiagnostic': (t) =>
              t._calleeDelegatingToCatchingMethodNoDiagnostic(),
          'test_importedNotifierDelegatingToCatchingMethod_noDiagnostic': (t) =>
              t._importedNotifierDelegatingToCatchingMethodNoDiagnostic(),
          'test_reportsImportedNotifierDelegatingToUncaughtMethod': (t) =>
              t._reportsImportedNotifierDelegatingToUncaughtMethod(),
          'test_reportsCalleeThrowingBeforeCaughtWork': (t) =>
              t._reportsCalleeThrowingBeforeCaughtWork(),
          'test_guardedHelper_noDiagnostic': (t) => t._guardedHelperNoDiagnostic(),
        },
      );

  @override
  String get ruleName => 'fire_and_forget_missing_catch';

  @override
  void setUp() {
    _riverpodPackage();
    _navigationPackages();
    super.setUp();
  }

  Future<void> _reportsInlineAsyncMissingCatch() async {
    await assertRuleDiagnostic(r'''
import 'dart:async';
abstract interface class Client {
  Future<void> sync();
}
void mirror(Client client) {
  unawaited(() async {
    await client.sync();
  }());
}
''', 'unawaited(() async');
  }

  Future<void> _inlineAsyncWithCatchNoDiagnostic() async {
    await assertRuleNoDiagnostics(r'''
import 'dart:async';
class Client {
  Future<void> sync() async {}
}

void mirror(Client client) {
  unawaited(() async {
    try {
      await client.sync();
    } on Exception {
      // handled
    }
  }());
}
''');
  }

  Future<void> _calleeThatCatchesInternallyNoDiagnostic() async {
    await assertRuleNoDiagnostics(r'''
import 'dart:async';

class RemoteMirror {
  Future<void> sync() async {
    try {
      await Future<void>.value();
    } on Exception {
      // handled
    }
  }
}

void mirror(RemoteMirror remoteMirror) {
  unawaited(remoteMirror.sync());
}
''');
  }

  Future<void> _reportsCalleeWithoutCatch() async {
    await assertRuleDiagnostic(r'''
import 'dart:async';

Future<void> trackUncaught(String name) async {
  await Future<void>.value();
}

void track() {
  unawaited(trackUncaught('x'));
}
''', 'unawaited(trackUncaught');
  }

  Future<void> _resolvesCalleesInImportedLibraries() async {
    newFile('$testPackageLibPath/analytics.dart', r'''
Future<void> trackEvent(String name) async {
  try {
    await Future<void>.value();
  } on Exception {
    // handled
  }
}

Future<void> trackUncaught(String name) async {
  await Future<void>.value();
}
''');
    await assertRuleDiagnostic(r'''
import 'dart:async';

import 'analytics.dart';

void track() {
  unawaited(trackEvent('sign_in'));
  unawaited(trackUncaught('x'));
}
''', 'unawaited(trackUncaught');
  }

  Future<void> _emptyCalleeBodyNoDiagnostic() async {
    await assertRuleNoDiagnostics(r'''
import 'dart:async';

final class PushTokenRefresh {
  PushTokenRefresh._();

  static final PushTokenRefresh instance = PushTokenRefresh._();

  Future<void> refresh() async {}
}

void onResume() {
  unawaited(PushTokenRefresh.instance.refresh());
}
''');
  }

  // riverpod-codegen.md Mutations: `run` records failures in the mutation state.
  Future<void> _mutationRunCalleeNoDiagnostic() async {
    await assertRuleNoDiagnostics(r'''
import 'dart:async';

import 'package:riverpod/riverpod.dart';

final addTodoMutation = Mutation<void>();

class AddTodoScreen {
  Future<void> _addTodo(Object ref) => addTodoMutation.run(ref, (tsx) async {
    await Future<void>.value();
  });

  void onPressed(Object ref) => unawaited(_addTodo(ref));
  void retry(Object ref) => unawaited(addTodoMutation.run(ref, (tsx) async {}));
}
''');
  }

  Future<void> _reportsLocalMutationLookalike() async {
    await assertRuleDiagnostic(r'''
import 'dart:async';

class Mutation<T> {
  Future<T> run(Object target, Future<T> Function(Object tsx) cb) => cb(target);
}

final addTodoMutation = Mutation<void>();

Future<void> _addTodo(Object ref) => addTodoMutation.run(ref, (tsx) async {});

void onPressed(Object ref) {
  unawaited(_addTodo(ref));
}
''', 'unawaited(_addTodo');
  }

  // modals-navigation.md: route futures complete with the popped result, not an error.
  Future<void> _navigationCalleeNoDiagnostic() async {
    newFile('$testPackageLibPath/core/extensions/context_extensions.dart', r'''
import 'package:flutter/material.dart';

extension ModalContextX on BuildContext {
  Future<T?> showAppSheet<T>({required String routeName, required WidgetBuilder builder}) {
    return showModalBottomSheet<T>(
      context: this,
      routeSettings: RouteSettings(name: routeName),
      builder: builder,
    );
  }
}
''');
    newFile('$testPackageLibPath/routes.dart', r'''
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

mixin $CreateExerciseRoute on GoRouteData {
  String get location => '/create';
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);
}

class CreateExerciseRoute extends GoRouteData with $CreateExerciseRoute {
  const CreateExerciseRoute();
}

class StubRoute {
  const StubRoute();
  Future<T?> push<T>(BuildContext context) async => null;
}
''');
    await assertRuleNoDiagnostics(r'''
import 'dart:async';

import 'package:flutter/material.dart';

import 'core/extensions/context_extensions.dart';
import 'routes.dart';

enum CreateChoice { exercise }

class CreateScreen {
  Future<void> _openCreateSheet(BuildContext context) async {
    final choice = await context.showAppSheet<CreateChoice>(
      routeName: 'create-sheet',
      builder: (_) => const SizedBox(),
    );
    if (!context.mounted) return;
    if (choice != CreateChoice.exercise) return;
    await const CreateExerciseRoute().push<String>(context);
  }

  Future<void> _openStub(BuildContext context) async {
    await const StubRoute().push<String>(context);
  }

  void onPressed(BuildContext context) {
    unawaited(_openCreateSheet(context));
    unawaited(_openStub(context));
  }
}
''');
  }

  // routing-app-shell.md: `maybePop` completes with whether a route was popped, not an error.
  Future<void> _maybePopCalleeNoDiagnostic() async {
    await assertRuleNoDiagnostics(r'''
import 'dart:async';

import 'package:flutter/material.dart';

class ShellScreen {
  Future<void> _createWorkout(BuildContext sheetContext) async {
    await Navigator.of(sheetContext).maybePop();
    if (!sheetContext.mounted) return;
  }

  void onCreateWorkout(BuildContext sheetContext) => unawaited(_createWorkout(sheetContext));
}
''');
  }

  Future<void> _reportsNavigationThenUncaughtRemoteWork() async {
    await assertRuleDiagnostic(r'''
import 'dart:async';

import 'package:flutter/material.dart';

abstract interface class Remote {
  Future<void> sync();
}

class SyncScreen {
  SyncScreen(this.remote);
  final Remote remote;

  Future<void> _confirmAndSync(BuildContext context) async {
    final ok = await showModalBottomSheet<bool>(context: context, builder: (_) => const SizedBox());
    if (ok != true) return;
    await remote.sync();
  }

  void onPressed(BuildContext context) {
    unawaited(_confirmAndSync(context));
  }
}
''', 'unawaited(_confirmAndSync');
  }

  // lists-forms-workflows.md: `loadMore` delegates to `_loadPage`, which catches.
  Future<void> _calleeDelegatingToCatchingMethodNoDiagnostic() async {
    await assertRuleNoDiagnostics(r'''
import 'dart:async';

abstract interface class Repository {
  Future<List<int>> fetchPage(int page);
}

class PaginatedNotifier {
  PaginatedNotifier(this.repository);
  final Repository repository;
  bool isLoading = false;

  Future<void> _loadPage(int page) async {
    isLoading = true;
    try {
      await repository.fetchPage(page);
    } catch (e) {
      isLoading = false;
    }
  }

  Future<void> loadMore() async {
    if (isLoading) return;
    await _loadPage(1);
  }
}

void onScroll(PaginatedNotifier notifier) {
  unawaited(notifier.loadMore());
}
''');
  }

  // lists-forms-workflows.md:40-84: an imported notifier's loadMore awaits `_loadPage`, which catches.
  Future<void> _importedNotifierDelegatingToCatchingMethodNoDiagnostic() async {
    newFile('$testPackageLibPath/paginated_notifier.dart', _paginatedNotifier);
    await assertRuleNoDiagnostics(r'''
import 'dart:async';

import 'paginated_notifier.dart';

void onScroll(PaginatedNotifier notifier) {
  unawaited(notifier.loadMore());
  unawaited(notifier.refresh());
}
''');
  }

  Future<void> _reportsImportedNotifierDelegatingToUncaughtMethod() async {
    newFile('$testPackageLibPath/paginated_notifier.dart', _paginatedNotifier);
    await assertRuleDiagnostic(r'''
import 'dart:async';

import 'paginated_notifier.dart';

void onScroll(PaginatedNotifier notifier) {
  unawaited(notifier.loadNext());
}
''', 'unawaited(notifier.loadNext');
  }

  static const _paginatedNotifier = r'''
abstract interface class Repository {
  Future<List<int>> fetchPage(int page);
}

class PaginatedNotifier {
  PaginatedNotifier(this.repository);
  final Repository repository;
  bool isLoading = false;

  Future<void> _loadPage(int page) async {
    isLoading = true;
    try {
      await repository.fetchPage(page);
    } catch (e) {
      isLoading = false;
    }
  }

  Future<void> _fetchUncaught(int page) async {
    await repository.fetchPage(page);
  }

  Future<void> loadMore() async {
    if (isLoading) return;
    await _loadPage(1);
  }

  Future<void> refresh() async => _loadPage(0);

  Future<void> loadNext() async {
    await this._fetchUncaught(2);
  }
}
''';

  Future<void> _reportsCalleeThrowingBeforeCaughtWork() async {
    await assertRuleDiagnostic(r'''
import 'dart:async';

Future<void> _safe() async {
  try {
    await Future<void>.value();
  } on Exception {
    // handled
  }
}

Future<void> checked(bool ready) async {
  if (!ready) throw Exception('not ready');
  await _safe();
}

void start() {
  unawaited(checked(false));
}
''', 'unawaited(checked');
  }

  Future<void> _guardedHelperNoDiagnostic() async {
    await assertRuleNoDiagnostics(r'''
import 'dart:async';

class Client {
  Future<void> sync() async {}
}

void mirror(Client client) {
  unawaited(_send(() => client.sync(), 'Client.sync'));
}

Future<void> _send(Future<void> Function() operation, String operationName) async {
  try {
    await operation();
  } on Exception {
    // handled
  }
}
''');
  }

  void _riverpodPackage() {
    newPackage('riverpod').addFile('lib/riverpod.dart', r'''
abstract class Mutation<ResultT> {
  factory Mutation() = _Mutation<ResultT>;
  Future<ResultT> run(Object target, Future<ResultT> Function(Object tsx) cb);
}

final class _Mutation<ResultT> implements Mutation<ResultT> {
  @override
  Future<ResultT> run(Object target, Future<ResultT> Function(Object tsx) cb) async {
    try {
      return await cb(target);
    } catch (error) {
      rethrow;
    }
  }
}
''');
  }

  void _navigationPackages() {
    newPackage('flutter').addFile('lib/material.dart', r'''
class BuildContext {
  bool get mounted => true;
}
abstract class Widget {
  const Widget();
}
class SizedBox extends Widget {
  const SizedBox();
}
typedef WidgetBuilder = Widget Function(BuildContext context);
class RouteSettings {
  const RouteSettings({String? name});
}
Future<T?> showModalBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  RouteSettings? routeSettings,
}) async => null;
class NavigatorState {
  Future<bool> maybePop<T>([T? result]) async => _popDisposition();
  Future<bool> _popDisposition() async => throw StateError('no route');
}
class Navigator {
  static NavigatorState of(BuildContext context) => NavigatorState();
}
''');
    newPackage('go_router').addFile('lib/go_router.dart', r'''
import 'package:flutter/material.dart';
abstract class GoRouteData {
  const GoRouteData();
  Future<T?> push<T>(BuildContext context) => throw UnimplementedError();
}
extension GoRouterHelper on BuildContext {
  Future<T?> push<T>(String location) async => null;
}
''');
  }
}

void _definePersistenceCrashSourceRulesPart01Tests() {
  analysisRuleSuite<_FireAndForgetMissingCatchTest>(
    'FireAndForgetMissingCatchTest',
    _FireAndForgetMissingCatchTest.new,
    _FireAndForgetMissingCatchTest._allCases,
  );
  analysisRuleSuite<_HiveDuplicateFieldIdTest>(
    'HiveDuplicateFieldIdTest',
    _HiveDuplicateFieldIdTest.new,
    _HiveDuplicateFieldIdTest._allCases,
  );
  analysisRuleSuite<_HiveDuplicateTypeIdTest>(
    'HiveDuplicateTypeIdTest',
    _HiveDuplicateTypeIdTest.new,
    _HiveDuplicateTypeIdTest._allCases,
  );
  analysisRuleSuite<_HiveReservedTypeIdsMissingTest>(
    'HiveReservedTypeIdsMissingTest',
    _HiveReservedTypeIdsMissingTest.new,
    _HiveReservedTypeIdsMissingTest._allCases,
  );
  analysisRuleSuite<_HiveTestCloseMissingTest>(
    'HiveTestCloseMissingTest',
    _HiveTestCloseMissingTest.new,
    _HiveTestCloseMissingTest._allCases,
  );
  analysisRuleSuite<_HiveTypeOnFreezedClassTest>(
    'HiveTypeOnFreezedClassTest',
    _HiveTypeOnFreezedClassTest.new,
    _HiveTypeOnFreezedClassTest._allCases,
  );
  analysisRuleSuite<_HiveAdapterSpecDomainTypeTest>(
    'HiveAdapterSpecDomainTypeTest',
    _HiveAdapterSpecDomainTypeTest.new,
    _HiveAdapterSpecDomainTypeTest._allCases,
  );
  analysisRuleSuite<_NotifierHiveAccessTest>(
    'NotifierHiveAccessTest',
    _NotifierHiveAccessTest.new,
    _NotifierHiveAccessTest._allCases,
  );
}
