// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_local_contract_key_constants.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidLocalContractKeyConstantsTest);
  });
}

@reflectiveTest
final class AvoidLocalContractKeyConstantsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidLocalContractKeyConstants();
    super.setUp();
  }

  Future<void> test_reportsNotifierLocalKeyConstants() async {
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

  Future<void> test_reportsNotifierLocalKeyRegistryConstants() async {
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

  Future<void> test_reportsRepositoryLocalActionConstants() async {
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

  Future<void> test_allowsDedicatedKeysOwner() async {
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

  Future<void> test_allowsDedicatedRequestOwner() async {
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

  Future<void> test_allowsDedicatedFeatureConstantsOwnerInNotifierPath() async {
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

  Future<void> test_allowsFeatureConstantsFolder() async {
    final filePath = '$testPackageLibPath/features/workouts/constants/workout_constants.dart';
    newFile(filePath, r'''
abstract final class WorkoutConstants {
  static const draftKey = 'draft';
  static const maxRecentSessions = 60;
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_reportsContractConstantsHiddenInNonOwnerClassInNotifierPath() async {
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

  Future<void> test_allowsNonContractLocalConstants() async {
    await assertNoDiagnostics(r'''
class ActiveWorkoutNotifier {
  static const _emptyRoutineId = '';
  static const _defaultRetryCount = 2;
}
''');
  }
}
