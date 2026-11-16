import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_local_contract_key_constants.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<_AvoidLocalContractKeyConstantsTest>(
    'AvoidLocalContractKeyConstantsTest',
    _AvoidLocalContractKeyConstantsTest.new,
    _AvoidLocalContractKeyConstantsTest._allCases,
  );
}

final class _AvoidLocalContractKeyConstantsTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidLocalContractKeyConstantsTest)> get _allCases =>
      caseSet<_AvoidLocalContractKeyConstantsTest>(
        parent: const {},
        own: {
          'test_reportsNotifierLocalKeyConstants': (t) => t._reportsNotifierLocalKeyConstants(),
          'test_reportsNotifierLocalKeyRegistryConstants': (t) =>
              t._reportsNotifierLocalKeyRegistryConstants(),
          'test_reportsRepositoryLocalActionConstants': (t) =>
              t._reportsRepositoryLocalActionConstants(),
          'test_allowsDedicatedKeysOwner': (t) => t._allowsDedicatedKeysOwner(),
          'test_allowsDedicatedRequestOwner': (t) => t._allowsDedicatedRequestOwner(),
          'test_allowsDedicatedFeatureConstantsOwnerInNotifierPath': (t) =>
              t._allowsDedicatedFeatureConstantsOwnerInNotifierPath(),
          'test_allowsFeatureConstantsFolder': (t) => t._allowsFeatureConstantsFolder(),
          'test_reportsContractConstantsHiddenInNonOwnerClassInNotifierPath': (t) =>
              t._reportsContractConstantsHiddenInNonOwnerClassInNotifierPath(),
          'test_allowsStorageKeysAndApiPathsOwners': (t) => t._allowsStorageKeysAndApiPathsOwners(),
          'test_reportsRepositoryLocalStorageKey': (t) => t._reportsRepositoryLocalStorageKey(),
          'test_allowsNonContractLocalConstants': (t) => t._allowsNonContractLocalConstants(),
        },
      );

  @override
  void setUp() {
    rule = AvoidLocalContractKeyConstants();
    super.setUp();
  }

  Future<void> _reportsNotifierLocalKeyConstants() async {
    const source = r'''
class ActiveWorkoutNotifier {
  static const _activeWorkoutIdKey = 'activeWorkoutId';
  static const _setsKey = 'sets';

  Object? read(Map<String, Object?> draft) => draft[_activeWorkoutIdKey];
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('_activeWorkoutIdKey'), '_activeWorkoutIdKey'.length),
      lint(source.indexOf('_setsKey'), '_setsKey'.length),
    ]);
  }

  Future<void> _reportsNotifierLocalKeyRegistryConstants() async {
    const source = r'''
class ActiveWorkoutNotifier {
  static const _activeWorkoutIdKey = 'activeWorkoutId';
  static const _setsKey = 'sets';
  static const _draftKeys = {
    _activeWorkoutIdKey,
    _setsKey,
  };
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('_activeWorkoutIdKey'), '_activeWorkoutIdKey'.length),
      lint(source.indexOf('_setsKey'), '_setsKey'.length),
      lint(source.indexOf('_draftKeys'), '_draftKeys'.length),
    ]);
  }

  Future<void> _reportsRepositoryLocalActionConstants() async {
    const source = r'''
class SquadRepository {
  static const _actionKey = 'action';
  static const _createAction = 'create';

  Map<String, Object?> body() => {_actionKey: _createAction};
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('_actionKey'), '_actionKey'.length),
      lint(source.indexOf('_createAction'), '_createAction'.length),
    ]);
  }

  Future<void> _allowsDedicatedKeysOwner() async {
    await assertNoDiagnostics(r'''
abstract final class ActiveWorkoutDraftKeys {
  static const id = 'activeWorkoutId';
  static const sets = 'sets';
}

class ActiveWorkoutNotifier {
  Object? read(Map<String, Object?> draft) => draft[ActiveWorkoutDraftKeys.id];
}
''');
  }

  Future<void> _allowsDedicatedRequestOwner() async {
    await assertNoDiagnostics(r'''
abstract final class SquadRequest {
  static const actionKey = 'action';
  static const createAction = 'create';
}

class SquadRepository {
  Map<String, Object?> body() => {
    SquadRequest.actionKey: SquadRequest.createAction,
  };
}
''');
  }

  Future<void> _allowsDedicatedFeatureConstantsOwnerInNotifierPath() async {
    final filePath =
        '$testPackageLibPath/features/workouts/presentation/notifiers/workout_limits.dart';
    newFile(filePath, r'''
abstract final class WorkoutLimits {
  static const maxRecentSessions = 60;
  static const draftKey = 'draft';
}

class WorkoutNotifier {
  Object? read(Map<String, Object?> draft) => draft[WorkoutLimits.draftKey];
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> _allowsFeatureConstantsFolder() async {
    final filePath = '$testPackageLibPath/features/workouts/constants/workout_constants.dart';
    newFile(filePath, r'''
abstract final class WorkoutConstants {
  static const draftKey = 'draft';
  static const maxRecentSessions = 60;
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> _reportsContractConstantsHiddenInNonOwnerClassInNotifierPath() async {
    final filePath =
        '$testPackageLibPath/features/workouts/presentation/notifiers/workout_helpers.dart';
    const source = r'''
abstract final class WorkoutHelpers {
  static const draftKey = 'draft';
}
''';
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [lint(source.indexOf('draftKey'), 'draftKey'.length)]);
  }

  Future<void> _allowsStorageKeysAndApiPathsOwners() async {
    final storageKeysPath = '$testPackageLibPath/core/constants/storage_keys.dart';
    newFile(storageKeysPath, r'''
abstract final class StorageKeys {
  static const todos = 'todos';
  static const syncDateKey = 'sync_date';
}
''');
    final apiPathsPath = '$testPackageLibPath/core/constants/api_paths.dart';
    newFile(apiPathsPath, r'''
abstract final class ApiPaths {
  static const products = '/products';
  static const productsPath = '/products';
}
''');
    await assertNoDiagnosticsInFile(storageKeysPath);
    await assertNoDiagnosticsInFile(apiPathsPath);
  }

  Future<void> _reportsRepositoryLocalStorageKey() async {
    const source = r'''
class SettingsRepository {
  static const exerciseSyncDateKey = 'sync_date_exercises';
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('exerciseSyncDateKey'), 'exerciseSyncDateKey'.length),
    ]);
  }

  Future<void> _allowsNonContractLocalConstants() async {
    await assertNoDiagnostics(r'''
class ActiveWorkoutNotifier {
  static const _emptyRoutineId = '';
  static const _defaultRetryCount = 2;
}
''');
  }
}
