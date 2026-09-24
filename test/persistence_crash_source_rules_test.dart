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
    defineReflectiveTests(HiveTypeOnFreezedClassTest);
    defineReflectiveTests(HiveAdapterSpecDomainTypeTest);
    defineReflectiveTests(NotifierHiveAccessTest);
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

  Future<void> test_crashAppRunner_noDiagnostic() async {
    await assertRuleNoDiagnostics(r'''
abstract final class Crash {
  static Future<void> init({required void Function() appRunner}) async { appRunner(); }
}
void runApp(Object app) {}
Future<void> main() async {
  await Crash.init(appRunner: () => runApp(Object()));
}
''', path: '$testPackageLibPath/main.dart');
  }

  Future<void> test_awaitedTopLevelAppRunnerAfterMain_noDiagnostic() async {
    newFile('$testPackageLibPath/crash.dart', r'''
abstract final class Crash {
  static Future<void> init({required void Function() appRunner}) async { appRunner(); }
}
''');
    await assertRuleNoDiagnostics(r'''
import 'crash.dart';
void runApp(Object app) {}
Future<void> main() async { await runAppRoot(); }
Future<void> runAppRoot() async { await Crash.init(appRunner: () { runApp(Object()); }); }
''', path: '$testPackageLibPath/main.dart');
  }

  Future<void> test_forwardedTopLevelAppRunnerBeforeMain_noDiagnostic() async {
    await assertRuleNoDiagnostics(r'''
abstract final class Crash {
  static Future<void> init({required void Function() appRunner}) async { appRunner(); }
}
void runApp(Object app) {}
void ensureInitialized() {}
Future<void> runAppRoot() async {
  ensureInitialized();
  await Crash.init(appRunner: () { runApp(Object()); });
}
Future<void> forwardStartup() async { await runAppRoot(); }
Future<void> main() => forwardStartup();
''', path: '$testPackageLibPath/main.dart');
  }

  Future<void> test_unawaitedTopLevelAppRunner_stillReports() async {
    await assertRuleDiagnostic(
      r'''
abstract final class Crash {
  static Future<void> init({required void Function() appRunner}) async { appRunner(); }
}
void runApp(Object app) {}
Future<void> main() async { runAppRoot(); }
Future<void> runAppRoot() async {
  await Crash.init(appRunner: () { runApp(Object()); });
}
''',
      'runApp(Object())',
      path: '$testPackageLibPath/main.dart',
    );
  }

  Future<void> test_conditionalTopLevelAppRunner_stillReports() async {
    await assertRuleDiagnostic(
      r'''
abstract final class Crash {
  static Future<void> init({required void Function() appRunner}) async { appRunner(); }
}
void runApp(Object app) {}
Future<void> main() async { await runAppRoot(false); }
Future<void> runAppRoot(bool enabled) async {
  if (!enabled) return;
  await Crash.init(appRunner: () { runApp(Object()); });
}
''',
      'runApp(Object())',
      path: '$testPackageLibPath/main.dart',
    );
  }

  Future<void> test_unreachableTopLevelAppRunner_stillReports() async {
    await assertRuleDiagnostic(
      r'''
abstract final class Crash {
  static Future<void> init({required void Function() appRunner}) async { appRunner(); }
}
void runApp(Object app) {}
Future<void> main() async { await unrelated(); }
Future<void> unrelated() async {}
Future<void> runAppRoot() async {
  await Crash.init(appRunner: () { runApp(Object()); });
}
''',
      'runApp(Object())',
      path: '$testPackageLibPath/main.dart',
    );
  }

  Future<void> test_conditionalCallToTopLevelAppRunner_stillReports() async {
    await assertRuleDiagnostic(
      r'''
abstract final class Crash {
  static Future<void> init({required void Function() appRunner}) async { appRunner(); }
}
void runApp(Object app) {}
Future<void> main(List<String> arguments) async {
  if (arguments.isNotEmpty) await runAppRoot();
}
Future<void> runAppRoot() async {
  await Crash.init(appRunner: () { runApp(Object()); });
}
''',
      'runApp(Object())',
      path: '$testPackageLibPath/main.dart',
    );
  }

  Future<void> test_callCycleDoesNotReachTopLevelAppRunner_stillReports() async {
    await assertRuleDiagnostic(
      r'''
abstract final class Crash {
  static Future<void> init({required void Function() appRunner}) async { appRunner(); }
}
void runApp(Object app) {}
Future<void> main() async { await first(); }
Future<void> first() async { await second(); }
Future<void> second() async { await first(); }
Future<void> runAppRoot() async {
  await Crash.init(appRunner: () { runApp(Object()); });
}
''',
      'runApp(Object())',
      path: '$testPackageLibPath/main.dart',
    );
  }

  Future<void> test_topLevelAppRunnerAfterDirectRunApp_stillReports() async {
    await assertRuleDiagnostic(
      r'''
abstract final class Crash {
  static Future<void> init({required void Function() appRunner}) async { appRunner(); }
}
void runApp(Object app) {}
Future<void> runAppRoot() async {
  await Crash.init(appRunner: () { runApp(Object()); });
}
Future<void> main() async {
  runApp(Object());
  await runAppRoot();
}
''',
      'runApp(Object())',
      path: '$testPackageLibPath/main.dart',
    );
  }

  Future<void> test_runAppBeforeCrashInitInHelper_stillReports() async {
    await assertRuleDiagnostic(
      r'''
abstract final class Crash { static Future<void> init() async {} }
void runApp(Object app) {}
Future<void> main() async { await runAppRoot(); }
Future<void> runAppRoot() async {
  runApp(Object());
  await Crash.init();
}
''',
      'runApp(Object())',
      path: '$testPackageLibPath/main.dart',
    );
  }

  Future<void> test_returnBeforeCrashAppRunner_stillReports() async {
    await assertRuleDiagnostic(
      r'''
abstract final class Crash { static Future<void> init({required void Function() appRunner}) async { appRunner(); } }
void runApp(Object app) {}
Future<void> main() async { await runAppRoot(); }
Future<void> runAppRoot() async {
  return;
  // ignore: dead_code
  await Crash.init(appRunner: () { runApp(Object()); });
}
''',
      'runApp(Object())',
      path: '$testPackageLibPath/main.dart',
    );
  }

  Future<void> test_throwBeforeAwaitedRunner_stillReports() async {
    await assertRuleDiagnostic(
      r'''
abstract final class Crash { static Future<void> init({required void Function() appRunner}) async { appRunner(); } }
void runApp(Object app) {}
Future<void> main() async {
  throw 0;
  // ignore: dead_code
  await runAppRoot();
}
Future<void> runAppRoot() async { await Crash.init(appRunner: () { runApp(Object()); }); }
''',
      'runApp(Object())',
      path: '$testPackageLibPath/main.dart',
    );
  }

  Future<void> test_awaitedResolvedInitializer_noDiagnostic() async {
    newFile('$testPackageLibPath/crash.dart', r'''
abstract final class Crash {
  static Future<void> init() async {}
}
class CrashReporter {
  Future<void> initialize() => Crash.init();
}
''');
    await assertRuleNoDiagnostics(r'''
import 'crash.dart';
void runApp(Object app) {}
Future<void> main() async {
  await CrashReporter().initialize();
  runApp(Object());
}
''', path: '$testPackageLibPath/main.dart');
  }

  Future<void> test_shadowedCrashParameterInWrapper_stillReports() async {
    newFile('$testPackageLibPath/crash.dart', r'''
abstract final class Crash { static Future<void> init() async {} }
class Other { Future<void> init() async {} }
class CrashReporter {
  Future<void> initialize(Other Crash) => Crash.init();
}
''');
    await assertRuleDiagnostic(
      r'''
import 'crash.dart';
void runApp(Object app) {}
Future<void> main() async {
  await CrashReporter().initialize(Other());
  runApp(Object());
}
''',
      'runApp(Object())',
      path: '$testPackageLibPath/main.dart',
    );
  }

  Future<void> test_shadowedCrashLocalInWrapper_stillReports() async {
    newFile('$testPackageLibPath/crash.dart', r'''
abstract final class Crash { static Future<void> init() async {} }
class Other { Future<void> init() async {} }
class CrashReporter {
  Future<void> initialize() {
    final Crash = Other();
    return Crash.init();
  }
}
''');
    await assertRuleDiagnostic(
      r'''
import 'crash.dart';
void runApp(Object app) {}
Future<void> main() async {
  await CrashReporter().initialize();
  runApp(Object());
}
''',
      'runApp(Object())',
      path: '$testPackageLibPath/main.dart',
    );
  }

  Future<void> test_unrelatedAwaitedInitializer_stillReports() async {
    newFile('$testPackageLibPath/crash.dart', r'''
class CrashReporter {
  Future<void> initialize() async {}
}
''');
    await assertRuleDiagnostic(
      r'''
import 'crash.dart';
void runApp(Object app) {}
Future<void> main() async {
  await CrashReporter().initialize();
  runApp(Object());
}
''',
      'runApp(Object())',
      path: '$testPackageLibPath/main.dart',
    );
  }

  Future<void> test_initializerInDifferentFunction_stillReports() async {
    newFile('$testPackageLibPath/crash.dart', r'''
abstract final class Crash { static Future<void> init() async {} }
class CrashReporter { Future<void> initialize() => Crash.init(); }
''');
    await assertRuleDiagnostic(
      r'''
import 'crash.dart';
void runApp(Object app) {}
Future<void> other() async { await CrashReporter().initialize(); }
Future<void> main() async { runApp(Object()); }
''',
      'runApp(Object())',
      path: '$testPackageLibPath/main.dart',
    );
  }

  Future<void> test_conditionalCrashInitInWrapper_stillReports() async {
    newFile('$testPackageLibPath/crash.dart', r'''
abstract final class Crash { static Future<void> init() async {} }
class CrashReporter {
  Future<void> initialize(bool enabled) async {
    if (enabled) await Crash.init();
  }
}
''');
    await assertRuleDiagnostic(
      r'''
import 'crash.dart';
void runApp(Object app) {}
Future<void> main() async {
  await CrashReporter().initialize(false);
  runApp(Object());
}
''',
      'runApp(Object())',
      path: '$testPackageLibPath/main.dart',
    );
  }

  Future<void> test_unawaitedCrashInitInWrapper_stillReports() async {
    newFile('$testPackageLibPath/crash.dart', r'''
abstract final class Crash { static Future<void> init() async {} }
class CrashReporter {
  Future<void> initialize() async { Crash.init(); }
}
''');
    await assertRuleDiagnostic(
      r'''
import 'crash.dart';
void runApp(Object app) {}
Future<void> main() async {
  await CrashReporter().initialize();
  runApp(Object());
}
''',
      'runApp(Object())',
      path: '$testPackageLibPath/main.dart',
    );
  }

  Future<void> test_conditionalDirectCrashInit_stillReports() async {
    await assertRuleDiagnostic(
      r'''
abstract final class Crash { static Future<void> init() async {} }
void runApp(Object app) {}
bool shouldInitialize() => false;
Future<void> main() async {
  if (shouldInitialize()) await Crash.init();
  runApp(Object());
}
''',
      'runApp(Object())',
      path: '$testPackageLibPath/main.dart',
    );
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

  Future<void> test_calleeThatCatchesInternally_noDiagnostic() async {
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

  Future<void> test_reportsCalleeWithoutCatch() async {
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

  Future<void> test_resolvesCalleesInImportedLibraries() async {
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

  Future<void> test_emptyCalleeBody_noDiagnostic() async {
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

@reflectiveTest
final class HiveDuplicateFieldIdTest extends _HiveRuleTest {
  @override
  String get ruleName => 'hive_duplicate_field_id';

  Future<void> test_reportsDuplicateField() async {
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

  Future<void> test_allowsSameIndexesInSeparateHiveTypes() async {
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

@reflectiveTest
final class HiveDuplicateTypeIdTest extends _HiveRuleTest {
  @override
  String get ruleName => 'hive_duplicate_type_id';

  Future<void> test_reportsDuplicateTypeId() async {
    await assertRuleDiagnostic(r'''
import 'package:hive_ce/hive_ce.dart';

@HiveType(typeId: 1)
class CacheEntry {}

@HiveType(typeId: 1)
class UserEntry {}
''', '@HiveType(typeId: 1)\nclass UserEntry');
  }

  Future<void> test_reportsDuplicateWithImportedHiveType() async {
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

  Future<void> test_reportsDuplicatesJoinedThroughGeneratedRegistrar() async {
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

  Future<void> test_reportsDuplicatesJoinedByDirectImports() async {
    _newCrossFileEntries(secondTypeId: 7);
    await assertRuleDiagnostic(r'''
import 'package:test/first_entry.dart';
import 'package:test/second_entry.dart';

void initializeStorage() {}
''', "import 'package:test/second_entry.dart';");
  }

  Future<void> test_leavesDeeperJoinToTheImportedLibrary() async {
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

  Future<void> test_allowsDistinctTypeIdsAcrossFiles() async {
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

@reflectiveTest
final class HiveReservedTypeIdsMissingTest extends _HiveRuleTest {
  @override
  String get ruleName => 'hive_reserved_type_ids_missing';

  Future<void> test_reportsMissingReservedTypeIds() async {
    await assertRuleDiagnostic(r'''
import 'package:hive_ce/hive_ce.dart';

@HiveType(typeId: 0)
class CacheEntry {}

@GenerateAdapters([AdapterSpec<User>()], firstTypeId: 1)
void hiveAdapters() {}

class User {}
''', '@GenerateAdapters');
  }

  Future<void> test_reportsReservationThatOmitsTheHiveTypeId() async {
    await assertRuleDiagnostic(r'''
import 'package:hive_ce/hive_ce.dart';

@HiveType(typeId: 0)
class CacheEntry {}

@GenerateAdapters([AdapterSpec<User>()], firstTypeId: 1, reservedTypeIds: {5})
void hiveAdapters() {}

class User {}
''', '@GenerateAdapters');
  }

  Future<void> test_reservedTypeIdsPresent_noDiagnostic() async {
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

  Future<void> test_reportsHiveTypeInAnotherFileOfTheRegistrationScope() async {
    _newDocLayout(reservation: '');
    await assertRuleDiagnostic(r'''
import 'package:test/cache_entry.dart';
import 'package:test/hive_adapters.dart';

void initializeStorage() {}
''', "import 'package:test/hive_adapters.dart';");
  }

  Future<void> test_allowsReservedHiveTypeInAnotherFile() async {
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

@reflectiveTest
final class HiveTypeOnFreezedClassTest extends _HiveRuleTest {
  @override
  String get ruleName => 'hive_type_on_freezed_class';

  Future<void> test_reportsHiveTypeOnFreezedClass() async {
    await assertRuleDiagnostic(r'''
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce/hive_ce.dart';

@freezed
@HiveType(typeId: 31)
class RunModel {}
''', '@HiveType(typeId: 31)');
  }

  Future<void> test_allowsHiveTypeOnPlainClass() async {
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

@reflectiveTest
final class HiveAdapterSpecDomainTypeTest extends _HiveRuleTest {
  @override
  String get ruleName => 'hive_adapter_spec_domain_type';

  Future<void> test_reportsDomainEntitySpec() async {
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

  Future<void> test_allowsDataModelSpec() async {
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

@reflectiveTest
final class NotifierHiveAccessTest extends _HiveRuleTest {
  @override
  String get ruleName => 'notifier_hive_access';

  Future<void> test_reportsHiveInNotifier() async {
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

  Future<void> test_allowsRepositoryNotifierAndHiveDatasource() async {
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
