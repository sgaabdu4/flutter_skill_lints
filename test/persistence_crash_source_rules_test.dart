import 'dart:math' as math;

import 'package:analyzer/error/error.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/rules/persistence_crash_source_rules.dart';

import 'analysis_rule_suite.dart';

part 'persistence_crash_source_rules_test/persistence_crash_source_rules_part_01.dart';
part 'persistence_crash_source_rules_test/persistence_crash_source_rules_part_01_registry.dart';

void main() {
  analysisRuleSuite<CrashDirectFirebaseCallTest>(
    'CrashDirectFirebaseCallTest',
    CrashDirectFirebaseCallTest.new,
    {
      'test_reportsOutsideBackend': (t) => t._reportsOutsideBackend(),
      'test_crashService_noDiagnostic': (t) => t._crashServiceNoDiagnostic(),
      'test_reportsOtherCoreCrashFiles': (t) => t._reportsOtherCoreCrashFiles(),
    },
  );
  analysisRuleSuite<CrashInitBeforeRunAppTest>(
    'CrashInitBeforeRunAppTest',
    CrashInitBeforeRunAppTest.new,
    {
      'test_reportsMissingInit': (t) => t._reportsMissingInit(),
      'test_noErrorReporting_noDiagnostic': (t) => t._noErrorReportingNoDiagnostic(),
      'test_reachableCrashFacadeWithoutInit_reports': (t) =>
          t._reachableCrashFacadeWithoutInitReports(),
      'test_crashFacadeBeforeUnrelatedSiblingImport_reports': (t) =>
          t._crashFacadeBeforeUnrelatedSiblingImportReports(),
      'test_sentryProviderWithoutCrashInit_reports': (t) =>
          t._sentryProviderWithoutCrashInitReports(),
      'test_crashlyticsProviderInImportedFileWithoutCrashInit_reports': (t) =>
          t._crashlyticsProviderInImportedFileWithoutCrashInitReports(),
      'test_initBeforeRunApp_noDiagnostic': (t) => t._initBeforeRunAppNoDiagnostic(),
      'test_crashAppRunner_noDiagnostic': (t) => t._crashAppRunnerNoDiagnostic(),
      'test_awaitedTopLevelAppRunnerAfterMain_noDiagnostic': (t) =>
          t._awaitedTopLevelAppRunnerAfterMainNoDiagnostic(),
      'test_forwardedTopLevelAppRunnerBeforeMain_noDiagnostic': (t) =>
          t._forwardedTopLevelAppRunnerBeforeMainNoDiagnostic(),
      'test_unawaitedTopLevelAppRunner_stillReports': (t) =>
          t._unawaitedTopLevelAppRunnerStillReports(),
      'test_conditionalTopLevelAppRunner_stillReports': (t) =>
          t._conditionalTopLevelAppRunnerStillReports(),
      'test_unreachableTopLevelAppRunner_stillReports': (t) =>
          t._unreachableTopLevelAppRunnerStillReports(),
      'test_conditionalCallToTopLevelAppRunner_stillReports': (t) =>
          t._conditionalCallToTopLevelAppRunnerStillReports(),
      'test_callCycleDoesNotReachTopLevelAppRunner_stillReports': (t) =>
          t._callCycleDoesNotReachTopLevelAppRunnerStillReports(),
      'test_topLevelAppRunnerAfterDirectRunApp_stillReports': (t) =>
          t._topLevelAppRunnerAfterDirectRunAppStillReports(),
      'test_runAppBeforeCrashInitInHelper_stillReports': (t) =>
          t._runAppBeforeCrashInitInHelperStillReports(),
      'test_returnBeforeCrashAppRunner_stillReports': (t) =>
          t._returnBeforeCrashAppRunnerStillReports(),
      'test_throwBeforeAwaitedRunner_stillReports': (t) =>
          t._throwBeforeAwaitedRunnerStillReports(),
      'test_awaitedResolvedInitializer_noDiagnostic': (t) =>
          t._awaitedResolvedInitializerNoDiagnostic(),
      'test_shadowedCrashParameterInWrapper_stillReports': (t) =>
          t._shadowedCrashParameterInWrapperStillReports(),
      'test_shadowedCrashLocalInWrapper_stillReports': (t) =>
          t._shadowedCrashLocalInWrapperStillReports(),
      'test_unrelatedAwaitedInitializer_stillReports': (t) =>
          t._unrelatedAwaitedInitializerStillReports(),
      'test_initializerInDifferentFunction_stillReports': (t) =>
          t._initializerInDifferentFunctionStillReports(),
      'test_conditionalCrashInitInWrapper_stillReports': (t) =>
          t._conditionalCrashInitInWrapperStillReports(),
      'test_unawaitedCrashInitInWrapper_stillReports': (t) =>
          t._unawaitedCrashInitInWrapperStillReports(),
      'test_conditionalDirectCrashInit_stillReports': (t) =>
          t._conditionalDirectCrashInitStillReports(),
    },
  );
  _definePersistenceCrashSourceRulesPart01Tests();
}

abstract class _PersistenceCrashRuleTest extends AnalysisRuleTest {
  String get ruleName;

  @override
  List<DiagnosticCode> get ignoredDiagnosticCodes => [
    ...super.ignoredDiagnosticCodes,
    for (final name in const ['undefined_static_member_read_not_found'])
      errorCodeByUniqueName(name)!,
  ];

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

final class CrashDirectFirebaseCallTest extends _PersistenceCrashRuleTest {
  @override
  String get ruleName => 'crash_direct_firebase_call';

  Future<void> _reportsOutsideBackend() async {
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

  Future<void> _crashServiceNoDiagnostic() async {
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

  Future<void> _reportsOtherCoreCrashFiles() async {
    await assertRuleDiagnostic(
      r'''
class FirebaseCrashlytics {
  static final instance = FirebaseCrashlytics();
  Future<void> recordError(Object error, StackTrace stack) async {}
}
Future<void> installHandlers() async {
  await FirebaseCrashlytics.instance.recordError(Exception('x'), StackTrace.current);
}
''',
      'FirebaseCrashlytics.instance.recordError',
      path: '$testPackageLibPath/core/crash/crash_handlers.dart',
    );
  }
}

final class CrashInitBeforeRunAppTest extends _PersistenceCrashRuleTest {
  @override
  String get ruleName => 'crash_init_before_run_app';

  @override
  void setUp() {
    newPackage('sentry_flutter').addFile('lib/sentry_flutter.dart', r'''
abstract final class SentryFlutter {
  static Future<void> init(void Function(Object options) configure) async {}
}
''');
    newPackage('firebase_crashlytics').addFile('lib/firebase_crashlytics.dart', r'''
class FirebaseCrashlytics {
  static final instance = FirebaseCrashlytics();
}
''');
    super.setUp();
  }

  Future<void> _reportsMissingInit() async {
    await assertRuleDiagnostic(
      r'''
abstract final class Crash {
  static Future<void> init() async {}
}
void runApp(Object app) {}
Future<void> main() async {
  runApp(Object());
}
''',
      'runApp(Object())',
      path: '$testPackageLibPath/main.dart',
    );
  }

  Future<void> _noErrorReportingNoDiagnostic() async {
    newFile('$testPackageLibPath/app.dart', r'''
class App {}
''');
    await assertRuleNoDiagnostics(r'''
import 'app.dart';
void runApp(Object app) {}
Future<void> main() async {
  runApp(App());
}
''', path: '$testPackageLibPath/main.dart');
  }

  Future<void> _reachableCrashFacadeWithoutInitReports() async {
    newFile('$testPackageLibPath/core/crash_service.dart', r'''
abstract final class Crash {
  static Future<void> init() async {}
  static void error(Object error, StackTrace stackTrace) {}
}
''');
    newFile('$testPackageLibPath/app.dart', r'''
import 'core/crash_service.dart';
class App {
  void fail(Object error) => Crash.error(error, StackTrace.current);
}
''');
    await assertRuleDiagnostic(
      r'''
import 'app.dart';
void runApp(Object app) {}
Future<void> main() async {
  runApp(App());
}
''',
      'runApp(App())',
      path: '$testPackageLibPath/main.dart',
    );
  }

  Future<void> _crashFacadeBeforeUnrelatedSiblingImportReports() async {
    newFile('$testPackageLibPath/app.dart', r'''
class App {}
''');
    newFile('$testPackageLibPath/crash.dart', r'''
abstract final class Crash {
  static Future<void> init() async {}
}
''');
    await assertRuleDiagnostic(
      r'''
import 'app.dart';
import 'crash.dart';
void runApp(Object app) {}
Future<void> main() async {
  runApp(App());
}
''',
      'runApp(App())',
      path: '$testPackageLibPath/main.dart',
    );
  }

  Future<void> _sentryProviderWithoutCrashInitReports() async {
    await assertRuleDiagnostic(
      r'''
import 'package:sentry_flutter/sentry_flutter.dart';
void runApp(Object app) {}
Future<void> main() async {
  await SentryFlutter.init((options) {});
  runApp(Object());
}
''',
      'runApp(Object())',
      path: '$testPackageLibPath/main.dart',
    );
  }

  Future<void> _crashlyticsProviderInImportedFileWithoutCrashInitReports() async {
    newFile('$testPackageLibPath/core/reporting.dart', r'''
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
final reporter = FirebaseCrashlytics.instance;
''');
    await assertRuleDiagnostic(
      r'''
import 'core/reporting.dart';
void runApp(Object app) {}
Future<void> main() async {
  runApp(reporter);
}
''',
      'runApp(reporter)',
      path: '$testPackageLibPath/main.dart',
    );
  }

  Future<void> _initBeforeRunAppNoDiagnostic() async {
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

  Future<void> _crashAppRunnerNoDiagnostic() async {
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

  Future<void> _awaitedTopLevelAppRunnerAfterMainNoDiagnostic() async {
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

  Future<void> _forwardedTopLevelAppRunnerBeforeMainNoDiagnostic() async {
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

  Future<void> _unawaitedTopLevelAppRunnerStillReports() async {
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

  Future<void> _conditionalTopLevelAppRunnerStillReports() async {
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

  Future<void> _unreachableTopLevelAppRunnerStillReports() async {
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

  Future<void> _conditionalCallToTopLevelAppRunnerStillReports() async {
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

  Future<void> _callCycleDoesNotReachTopLevelAppRunnerStillReports() async {
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

  Future<void> _topLevelAppRunnerAfterDirectRunAppStillReports() async {
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

  Future<void> _runAppBeforeCrashInitInHelperStillReports() async {
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

  Future<void> _returnBeforeCrashAppRunnerStillReports() async {
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

  Future<void> _throwBeforeAwaitedRunnerStillReports() async {
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

  Future<void> _awaitedResolvedInitializerNoDiagnostic() async {
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

  Future<void> _shadowedCrashParameterInWrapperStillReports() async {
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

  Future<void> _shadowedCrashLocalInWrapperStillReports() async {
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

  Future<void> _unrelatedAwaitedInitializerStillReports() async {
    newFile('$testPackageLibPath/crash.dart', r'''
abstract final class Crash { static Future<void> init() async {} }
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

  Future<void> _initializerInDifferentFunctionStillReports() async {
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

  Future<void> _conditionalCrashInitInWrapperStillReports() async {
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

  Future<void> _unawaitedCrashInitInWrapperStillReports() async {
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

  Future<void> _conditionalDirectCrashInitStillReports() async {
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
