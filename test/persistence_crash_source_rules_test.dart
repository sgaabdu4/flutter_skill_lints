// ignore_for_file: non_constant_identifier_names

import 'dart:math' as math;

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/rules/persistence_crash_source_rules.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CrashDirectFirebaseCallTest);
    defineReflectiveTests(CrashInitBeforeRunAppTest);
    defineReflectiveTests(FireAndForgetMissingCatchTest);
    defineReflectiveTests(HiveDuplicateFieldIdTest);
    defineReflectiveTests(HiveDuplicateTypeIdTest);
    defineReflectiveTests(HiveReservedTypeIdsMissingTest);
    defineReflectiveTests(HiveTestCloseMissingTest);
  });
}

abstract class _PersistenceCrashRuleTest extends AnalysisRuleTest {
  String get ruleName;

  @override
  void setUp() {
    rule = persistenceCrashSourceRules.singleWhere((rule) => rule.name == ruleName);
    super.setUp();
  }

  Future<void> assertRuleDiagnostic(String source, String needle, {String? path}) async {
    final analyzedSource = _withIgnorePrefix(source);
    final filePath = path ?? '$testPackageLibPath/source.dart';
    newFile(filePath, analyzedSource);
    await assertDiagnosticsInFile(filePath, [_lintFor(analyzedSource, needle, ruleName)]);
  }

  Future<void> assertRuleNoDiagnostics(String source, {String? path}) async {
    final filePath = path ?? '$testPackageLibPath/source.dart';
    newFile(filePath, _withIgnorePrefix(source));
    await assertNoDiagnosticsInFile(filePath);
  }

  T _lintFor<T>(String source, String needle, String name) {
    final offset = source.indexOf(needle);
    if (offset < 0) {
      throw StateError('Needle not found: $needle');
    }

    final lineEnd = source.indexOf('\n', offset);
    final end = lineEnd < 0 ? source.length : lineEnd;
    return lint(offset, math.max(1, end - offset), name: name) as T;
  }

  String _withIgnorePrefix(String source) => '''
// ignore_for_file: avoid_void_async, discarded_futures, final_not_initialized, undefined_getter, unused_element, unused_import
$source''';
}

@reflectiveTest
final class CrashDirectFirebaseCallTest extends _PersistenceCrashRuleTest {
  @override
  String get ruleName => 'crash_direct_firebase_call';

  Future<void> test_reportsOutsideBackend() async {
    await assertRuleDiagnostic(
      r'''
class FirebaseCrashlytics {
  static final instance = FirebaseCrashlytics();
  Future<void> recordError(Object error, StackTrace stack) async {}
}

Future<void> submit() async {
  await FirebaseCrashlytics.instance.recordError(Exception('x'), StackTrace.current);
}
''',
      'FirebaseCrashlytics.instance.recordError',
      path: '$testPackageLibPath/features/checkout/checkout_notifier.dart',
    );
  }

  Future<void> test_crashService_noDiagnostic() async {
    await assertRuleNoDiagnostics(r'''
class FirebaseCrashlytics {
  static final instance = FirebaseCrashlytics();
  Future<void> recordError(Object error, StackTrace stack) async {}
}

abstract final class Crash {
  static Future<void> init() async {
    await FirebaseCrashlytics.instance.recordError(Exception('x'), StackTrace.current);
  }
}
''', path: '$testPackageLibPath/core/services/crash_service.dart');
  }
}

@reflectiveTest
final class CrashInitBeforeRunAppTest extends _PersistenceCrashRuleTest {
  @override
  String get ruleName => 'crash_init_before_run_app';

  Future<void> test_reportsMissingInit() async {
    await assertRuleDiagnostic(
      r'''
void runApp(Object app) {}

Future<void> main() async {
  runApp(Object());
}
''',
      'runApp(Object())',
      path: '$testPackageLibPath/main.dart',
    );
  }

  Future<void> test_initBeforeRunApp_noDiagnostic() async {
    await assertRuleNoDiagnostics(r'''
abstract final class Crash {
  static Future<void> init() async {}
}

void runApp(Object app) {}

Future<void> main() async {
  await Crash.init();
  runApp(Object());
}
''', path: '$testPackageLibPath/main.dart');
  }
}

@reflectiveTest
final class FireAndForgetMissingCatchTest extends _PersistenceCrashRuleTest {
  @override
  String get ruleName => 'fire_and_forget_missing_catch';

  Future<void> test_reportsInlineAsyncMissingCatch() async {
    await assertRuleDiagnostic(r'''
import 'dart:async';

class Client {
  Future<void> sync() async {}
}

void mirror(Client client) {
  unawaited(() async {
    await client.sync();
  }());
}
''', 'unawaited(() async');
  }

  Future<void> test_inlineAsyncWithCatch_noDiagnostic() async {
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

  Future<void> test_guardedHelper_noDiagnostic() async {
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
}

@reflectiveTest
final class HiveDuplicateFieldIdTest extends _PersistenceCrashRuleTest {
  @override
  String get ruleName => 'hive_duplicate_field_id';

  Future<void> test_reportsDuplicateField() async {
    await assertRuleDiagnostic(r'''
class HiveType {
  const HiveType({required int typeId});
}

class HiveField {
  const HiveField(int id);
}

@HiveType(typeId: 1)
class CacheEntry {
  @HiveField(0)
  final String key = '';

  @HiveField(0)
  final String value = '';
}
''', '@HiveField(0)\n  final String value');
  }
}

@reflectiveTest
final class HiveDuplicateTypeIdTest extends _PersistenceCrashRuleTest {
  @override
  String get ruleName => 'hive_duplicate_type_id';

  Future<void> test_reportsDuplicateTypeId() async {
    await assertRuleDiagnostic(r'''
class HiveType {
  const HiveType({required int typeId});
}

@HiveType(typeId: 1)
class CacheEntry {}

@HiveType(typeId: 1)
class UserEntry {}
''', '@HiveType(typeId: 1)\nclass UserEntry');
  }
}

@reflectiveTest
final class HiveReservedTypeIdsMissingTest extends _PersistenceCrashRuleTest {
  @override
  String get ruleName => 'hive_reserved_type_ids_missing';

  Future<void> test_reportsMissingReservedTypeIds() async {
    await assertRuleDiagnostic(r'''
class HiveType {
  const HiveType({required int typeId});
}

class GenerateAdapters {
  const GenerateAdapters(List<Object> adapters, {int firstTypeId = 0});
}

class AdapterSpec<T> {
  const AdapterSpec();
}

@HiveType(typeId: 0)
class CacheEntry {}

@GenerateAdapters([AdapterSpec<User>()], firstTypeId: 1)
void hiveAdapters() {}

class User {}
''', '@GenerateAdapters');
  }

  Future<void> test_reservedTypeIdsPresent_noDiagnostic() async {
    await assertRuleNoDiagnostics(r'''
class HiveType {
  const HiveType({required int typeId});
}

class GenerateAdapters {
  const GenerateAdapters(
    List<Object> adapters, {
    int firstTypeId = 0,
    Set<int> reservedTypeIds = const {},
  });
}

class AdapterSpec<T> {
  const AdapterSpec();
}

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
}

@reflectiveTest
final class HiveTestCloseMissingTest extends _PersistenceCrashRuleTest {
  @override
  String get ruleName => 'hive_test_close_missing';

  Future<void> test_reportsMissingCloseInTest() async {
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

  Future<void> test_closePresent_noDiagnostic() async {
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
