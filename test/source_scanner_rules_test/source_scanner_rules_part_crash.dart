part of '../source_scanner_rules_test.dart';

abstract class _DataCrashRuleTest extends _SourceRuleTest {
  @override
  List<ScannerRule> get rules => dataCrashSourceRules;
}

final class _DataLogRethrowTest extends _DataCrashRuleTest {
  static Map<String, Future<void> Function(_DataLogRethrowTest)> get _allCases =>
      caseSet<_DataLogRethrowTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_reportsReportingCallsBeforeRethrow': (t) => t._reportsReportingCallsBeforeRethrow(),
          'test_reportsFlutterDebugPrintBeforeRethrow': (t) =>
              t._reportsFlutterDebugPrintBeforeRethrow(),
          'test_allowsSkillDataLayerCatches': (t) => t._allowsSkillDataLayerCatches(),
          'test_reportsRollbackThatReportsBeforeRethrow': (t) =>
              t._reportsRollbackThatReportsBeforeRethrow(),
          'test_reportsCrashReportThenRethrow': (t) => t._reportsCrashReportThenRethrow(),
          'test_reportsCrashReportThenThrowCaughtError': (t) =>
              t._reportsCrashReportThenThrowCaughtError(),
          'test_allowsReportThenMappedTypedError': (t) => t._allowsReportThenMappedTypedError(),
          'test_allowsRethrowWithoutReport': (t) => t._allowsRethrowWithoutReport(),
        },
      );

  @override
  String get ruleName => 'data_log_rethrow';
  @override
  String get needle => 'log(error);';
  @override
  String get path => '$testPackageLibPath/features/todos/data/repositories/todo_repository.dart';
  @override
  String get source => r'''
void log(Object value) {}

void load() {
  try {
    throw Object();
  } catch (error) {
    log(error);
    rethrow;
  }
}
''';

  /// The state-management-lifecycle.md:74-84 WRONG example.
  Future<void> _reportsReportingCallsBeforeRethrow() async {
    final analyzedSource = _analyzedSource(r'''
class Crash {
  static void error(Object error, StackTrace stackTrace, {String? reason}) {}
}

class TodoRepository {
  Future<void> remove(String id) async {
    try {
      await Future<void>.value();
    } on Exception catch (e, s) {
      Crash.error(e, s, reason: 'remove');
      rethrow;
    }
  }

  Future<void> save() async {
    try {
      await Future<void>.value();
    } catch (_) {
      print('save failed');
      rethrow;
    }
  }
}
''', addIgnorePrefix: addIgnorePrefix);
    newFile(path, analyzedSource);
    await assertDiagnosticsInFile(path, [
      compatLint(analyzedSource, "Crash.error(e, s, reason: 'remove');", ruleName),
      compatLint(analyzedSource, "print('save failed');", ruleName),
    ]);
  }

  /// Flutter debugPrint resolves as a FunctionExpressionInvocation.
  Future<void> _reportsFlutterDebugPrintBeforeRethrow() async {
    final analyzedSource = _analyzedSource(r'''
import 'package:flutter/foundation.dart';

class ProductRemoteDataSource {
  Future<List<String>> fetchAll() async {
    try {
      return await Future.value(const <String>[]);
    } on Exception catch (e) {
      debugPrint('fetch failed $e');
      rethrow;
    }
  }

  Future<void> remove() async {
    try {
      await Future<void>.value();
    } catch (_) {
      debugPrint('remove failed');
      rethrow;
    }
  }
}
''', addIgnorePrefix: addIgnorePrefix);
    newFile(path, analyzedSource);
    await assertDiagnosticsInFile(path, [
      compatLint(analyzedSource, r"debugPrint('fetch failed $e');", ruleName),
      compatLint(analyzedSource, "debugPrint('remove failed');", ruleName),
    ]);
  }

  /// Translation, rollback and local-first swallow + log (state-management-lifecycle.md:69-72).
  Future<void> _allowsSkillDataLayerCatches() async {
    await assertAllows(r'''
class Crash {
  static void error(Object error, StackTrace stackTrace, {String? reason}) {}
}

class TodoFailure implements Exception {
  const TodoFailure(this.cause);
  final Object cause;
}

class TodoRepository {
  Future<void> translate() async {
    try {
      await Future<void>.value();
    } on Exception catch (e, s) {
      Crash.error(e, s);
      Error.throwWithStackTrace(TodoFailure(e), s);
    }
  }

  Future<void> rollback(String id) async {
    try {
      await Future<void>.value();
    } catch (_) {
      await restore(id);
      rethrow;
    }
  }

  Future<void> mirror() async {
    try {
      await Future<void>.value();
    } catch (e, s) {
      Crash.error(e, s, reason: 'remote mirror');
    }
  }

  Future<void> restore(String id) async {}
}
''', path: path);
  }

  /// Rollback rethrows must not report a second incident.
  Future<void> _reportsRollbackThatReportsBeforeRethrow() async {
    const source = r'''
abstract final class Crash {
  static void error(Object error, StackTrace stackTrace, {String? reason}) {}
}

class TodoRepository {
  Future<void> rollback(String id) async {
    try {
      await Future<void>.value();
    } catch (e, s) {
      await restore(id);
      Crash.error(e, s, reason: 'rollback');
      rethrow;
    }
  }

  Future<void> restore(String id) async {}
}
''';
    newFile(path, source);

    await assertDiagnosticsInFile(path, [
      compatLint(source, "Crash.error(e, s, reason: 'rollback');", ruleName),
    ]);
  }

  Future<void> _reportsCrashReportThenRethrow() async {
    const source = r'''
abstract final class Crash {
  static void error(Object error, StackTrace stackTrace) {}
}

class TodoRepository {
  Future<int> load(Future<int> Function() source) async {
    try {
      return await source();
    } on Exception catch (error, stackTrace) {
      Crash.error(error, stackTrace);
      rethrow;
    }
  }
}
''';
    final filePath = '$testPackageLibPath/features/todos/data/repositories/todo_repository.dart';
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [
      compatLint(source, 'Crash.error(error, stackTrace);', ruleName),
    ]);
  }

  Future<void> _reportsCrashReportThenThrowCaughtError() async {
    const source = r'''
abstract final class Crash {
  static void error(Object error, StackTrace stackTrace) {}
}

Future<int> load(Future<int> Function() source) async {
  try {
    return await source();
  } on Exception catch (error, stackTrace) {
    Crash.error(error, stackTrace);
    throw error;
  }
}
''';
    final filePath = '$testPackageLibPath/features/todos/data/datasources/todo_datasource.dart';
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [
      compatLint(source, 'Crash.error(error, stackTrace);', ruleName),
    ]);
  }

  Future<void> _allowsReportThenMappedTypedError() async {
    await assertAllows(r'''
abstract final class Crash {
  static void error(Object error, StackTrace stackTrace) {}
}

class AppException implements Exception {}

Future<int> load(Future<int> Function() source) async {
  try {
    return await source();
  } on Exception catch (error, stackTrace) {
    Crash.error(error, stackTrace);
    throw AppException();
  }
}
''', path: path);
  }

  Future<void> _allowsRethrowWithoutReport() async {
    await assertAllows(r'''
Future<int> load(Future<int> Function() source) async {
  try {
    return await source();
  } on Exception {
    rethrow;
  }
}
''', path: path);
  }
}

final class _CrashPossiblePiiTest extends _DataCrashRuleTest {
  static Map<String, Future<void> Function(_CrashPossiblePiiTest)> get _allCases =>
      caseSet<_CrashPossiblePiiTest>(parent: _SourceRuleTest._allCases, own: {});

  @override
  String get ruleName => 'crash_possible_pii';
  @override
  String get needle => 'Crash.error(email)';
  @override
  bool get lineStart => true;
  @override
  String get source => r'''
class Crash {
  static void error(Object value) {}
}

final email = Object();

void recordCrash() {
  Crash.error(email);
}
''';
}

abstract class _CrashSdkRuleTest extends _DataCrashRuleTest {
  @override
  void setUp() {
    final sentry = newPackage('sentry_flutter');
    sentry.addFile('lib/src/options.dart', r'''
class SentryFlutterOptions {
  bool sendDefaultPii = false;
  bool attachScreenshot = false;
  bool attachViewHierarchy = false;
}
''');
    sentry.addFile('lib/sentry_flutter.dart', r'''
import 'src/options.dart';
export 'src/options.dart';

abstract final class Sentry {
  static Future<void> captureException(Object error, {StackTrace? stackTrace}) async {}
}

abstract final class SentryFlutter {
  static Future<void> init(void Function(SentryFlutterOptions) configure, {Object? appRunner}) async {}
}
''');
    newPackage('firebase_crashlytics').addFile('lib/firebase_crashlytics.dart', r'''
class FirebaseCrashlytics {
  static final FirebaseCrashlytics instance = FirebaseCrashlytics();
  void recordFlutterFatalError(Object details) {}
  Future<void> recordError(Object error, StackTrace? stack, {bool fatal = false}) async {}
}
''');
    newPackage('flutter').addFile('lib/foundation.dart', r'''
class FlutterError {
  static void Function(Object details)? onError;
  static void presentError(Object details) {}
}
''');
    super.setUp();
    sdkRoot.getFile('lib/ui/ui.dart').writeAsStringSync(r'''
library dart.ui;

class PlatformDispatcher {
  static PlatformDispatcher get instance => PlatformDispatcher();
  bool Function(Object error, StackTrace stack)? onError;
}
''');
    final libraries = sdkRoot.getFile('lib/_internal/sdk_library_metadata/lib/libraries.dart');
    libraries.writeAsStringSync(
      libraries.readAsStringSync().replaceFirst(
        '};',
        '  "ui": const LibraryInfo("ui/ui.dart", categories: "Shared"),\n};',
      ),
    );
  }

  String get crashServicePath => '$testPackageLibPath/core/crash/crash_service.dart';
}

final class _CrashDirectSentryCallTest extends _CrashSdkRuleTest {
  static Map<String, Future<void> Function(_CrashDirectSentryCallTest)> get _allCases =>
      caseSet<_CrashDirectSentryCallTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_reportsImportAndCaptureCall': (t) => t._reportsImportAndCaptureCall(),
          'test_reportsSdkUseInOtherCoreCrashFiles': (t) => t._reportsSdkUseInOtherCoreCrashFiles(),
          'test_allowsCrashService': (t) => t._allowsCrashService(),
          'test_allowsCrashFacadeCalls': (t) => t._allowsCrashFacadeCalls(),
        },
      );

  @override
  String get ruleName => 'crash_direct_sentry_call';
  @override
  String get needle => "import 'package:sentry_flutter/sentry_flutter.dart';";
  @override
  String get path => '$testPackageLibPath/features/checkout/data/checkout_repository.dart';
  @override
  String get source => r'''
import 'package:sentry_flutter/sentry_flutter.dart';
''';

  Future<void> _reportsImportAndCaptureCall() async {
    const source = r'''
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> submit(Object error) async {
  await Sentry.captureException(error);
}
''';
    newFile(path, source);

    await assertDiagnosticsInFile(path, [
      compatLint(source, "import 'package:sentry_flutter", ruleName),
      compatLint(source, 'Sentry.captureException(error)', ruleName),
    ]);
  }

  Future<void> _reportsSdkUseInOtherCoreCrashFiles() async {
    final filePath = '$testPackageLibPath/core/crash/sentry_config.dart';
    const source = r'''
// ignore_for_file: unused_import
import 'package:sentry_flutter/sentry_flutter.dart';
''';
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [
      compatLint(source, "import 'package:sentry_flutter", ruleName),
    ]);
  }

  Future<void> _allowsCrashService() async {
    await assertAllows(r'''
import 'package:sentry_flutter/sentry_flutter.dart';

abstract final class Crash {
  static Future<void> init({required void Function() appRunner}) =>
      SentryFlutter.init((options) {}, appRunner: appRunner);

  static void error(Object error, StackTrace stackTrace) {
    Sentry.captureException(error, stackTrace: stackTrace);
  }
}
''', path: crashServicePath);
  }

  Future<void> _allowsCrashFacadeCalls() async {
    await assertAllows(r'''
abstract final class Crash {
  static void error(Object error, StackTrace stackTrace) {}
}

void submit(Object error) {
  Crash.error(error, StackTrace.current);
}
''', path: path);
  }
}

final class _CrashCustomGlobalErrorHandlerTest extends _CrashSdkRuleTest {
  static Map<String, Future<void> Function(_CrashCustomGlobalErrorHandlerTest)> get _allCases =>
      caseSet<_CrashCustomGlobalErrorHandlerTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_reportsPlatformDispatcherHandler': (t) => t._reportsPlatformDispatcherHandler(),
          'test_reportsCustomHandlerInCrashService': (t) => t._reportsCustomHandlerInCrashService(),
          'test_reportsCustomHandlerInsideCrashFacade': (t) =>
              t._reportsCustomHandlerInsideCrashFacade(),
          'test_reportsCrashlyticsHandlersOutsideCrashFacade': (t) =>
              t._reportsCrashlyticsHandlersOutsideCrashFacade(),
          'test_reportsBootstrapHandlers': (t) => t._reportsBootstrapHandlers(),
          'test_allowsCrashlyticsHandlersInsideCrashFacade': (t) =>
              t._allowsCrashlyticsHandlersInsideCrashFacade(),
          'test_allowsReadingHandler': (t) => t._allowsReadingHandler(),
          'test_allowsStartupForwardingToLocalDiagnosticsOnly': (t) =>
              t._allowsStartupForwardingToLocalDiagnosticsOnly(),
          'test_reportsLocalHandlerOverwritingSdkFromExternalHelper': (t) =>
              t._reportsLocalHandlerOverwritingSdkFromExternalHelper(),
          'test_reportsRemoteArbitraryAndRecursiveFacadeHandlers': (t) =>
              t._reportsRemoteArbitraryAndRecursiveFacadeHandlers(),
          'test_reportsThrowAfterLocalForwarding': (t) => t._reportsThrowAfterLocalForwarding(),
        },
      );

  @override
  String get ruleName => 'crash_custom_global_error_handler';
  @override
  String get needle => 'FlutterError.onError = FlutterError.presentError;';
  @override
  String get path => '$testPackageLibPath/core/crash/crash_handlers.dart';
  @override
  String get source => r'''
import 'package:flutter/foundation.dart';

void installHandlers() {
  FlutterError.onError = FlutterError.presentError;
}
''';

  Future<void> _reportsPlatformDispatcherHandler() async {
    const source = r'''
import 'dart:ui';

void installHandlers() {
  PlatformDispatcher.instance.onError = (error, stack) => true;
}
''';
    newFile(path, source);

    await assertDiagnosticsInFile(path, [
      compatLint(source, 'PlatformDispatcher.instance.onError', ruleName),
    ]);
  }

  Future<void> _reportsCustomHandlerInCrashService() async {
    const source = r'''
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void installHandlers() {
  FlutterError.onError = (details) => Sentry.captureException(details);
}
''';
    newFile(crashServicePath, source);

    await assertDiagnosticsInFile(crashServicePath, [
      compatLint(source, 'FlutterError.onError =', ruleName),
    ]);
  }

  Future<void> _reportsCustomHandlerInsideCrashFacade() async {
    const source = r'''
import 'dart:async';

import 'package:flutter/foundation.dart';

abstract final class Crash {
  static Future<void> init({required FutureOr<void> Function() appRunner}) async {
    FlutterError.onError = FlutterError.presentError;
    await appRunner();
  }
}
''';
    newFile(crashServicePath, source);

    await assertDiagnosticsInFile(crashServicePath, [
      compatLint(source, 'FlutterError.onError =', ruleName),
    ]);
  }

  Future<void> _reportsCrashlyticsHandlersOutsideCrashFacade() async {
    const source = r'''
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

void installHandlers() {
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
}
''';
    newFile(crashServicePath, source);

    await assertDiagnosticsInFile(crashServicePath, [
      compatLint(source, 'FlutterError.onError =', ruleName),
    ]);
  }

  Future<void> _reportsBootstrapHandlers() async {
    const source = r'''
import 'dart:ui';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

Future<void> bootstrap() async {
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
}
''';
    final bootstrapPath = '$testPackageLibPath/bootstrap.dart';
    newFile(bootstrapPath, source);

    await assertDiagnosticsInFile(bootstrapPath, [
      compatLint(source, 'FlutterError.onError =', ruleName),
      compatLint(source, 'PlatformDispatcher.instance.onError =', ruleName),
    ]);
  }

  Future<void> _allowsCrashlyticsHandlersInsideCrashFacade() async {
    newFile(crashServicePath, r'''
import 'dart:async';
import 'dart:ui';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

abstract final class Crash {
  static Future<void> init({required FutureOr<void> Function() appRunner}) async {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
    await appRunner();
  }
}
''');
    final mainPath = '$testPackageLibPath/main.dart';
    newFile(mainPath, r'''
import 'core/crash/crash_service.dart';

void runApp(Object app) {}

Future<void> main() async {
  await Crash.init(appRunner: () => runApp(Object()));
}
''');

    await assertNoDiagnosticsInFile(crashServicePath);
    await assertNoDiagnosticsInFile(mainPath);
  }

  Future<void> _allowsReadingHandler() async {
    await assertAllows(r'''
import 'package:flutter/foundation.dart';

final previous = FlutterError.onError;
''', path: path);
  }

  Future<void> _allowsStartupForwardingToLocalDiagnosticsOnly() async {
    await assertAllows(r'''
import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';

abstract final class SentryFlutter {
  static void init() {}
}
abstract final class Crash {
  static Future<void> init(StackTrace stack, {required FutureOr<void> Function() appRunner}) async {
    SentryFlutter.init();
    FlutterError.onError = (details) => error(details, stack);
    PlatformDispatcher.instance.onError = (exception, stack) {
      error(exception, stack);
      return true;
    };
    await appRunner();
  }
  static void error(Object error, StackTrace stack) {
    debugPrint('Uncaught ${error.runtimeType}');
    debugPrint('$stack');
  }
}
''', path: crashServicePath);
  }

  Future<void> _reportsLocalHandlerOverwritingSdkFromExternalHelper() async {
    const source = r'''
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> bootstrap(StackTrace stack) => SentryFlutter.init(
  (options) {},
  appRunner: () => Crash.init(stack),
);

abstract final class Crash {
  static void init(StackTrace stack) {
    FlutterError.onError = (details) => error(details, stack);
    PlatformDispatcher.instance.onError = (exception, stack) {
      error(exception, stack);
      return true;
    };
  }
  static void error(Object error, StackTrace stack) {
    debugPrint('Uncaught ${error.runtimeType}');
  }
}
''';
    newFile(crashServicePath, source);
    await assertDiagnosticsInFile(crashServicePath, [
      compatLint(source, 'FlutterError.onError =', ruleName),
      compatLint(source, 'PlatformDispatcher.instance.onError =', ruleName),
    ]);
  }

  Future<void> _reportsRemoteArbitraryAndRecursiveFacadeHandlers() async {
    for (final body in [
      'Sentry.captureException(error);',
      'relay(error);',
      'Crash.error(error, stack);',
    ]) {
      final source =
          '''
import 'package:flutter/foundation.dart';
${body.startsWith('Sentry.') ? "import 'package:sentry_flutter/sentry_flutter.dart';" : ''}

void relay(Object error) {}
abstract final class Crash {
  static void init(StackTrace stack) {
    FlutterError.onError = (details) => error(details, stack);
  }
  static void error(Object error, StackTrace stack) { $body }
}
''';
      newFile(crashServicePath, source);
      await assertDiagnosticsInFile(crashServicePath, [
        compatLint(source, 'FlutterError.onError =', ruleName),
      ]);
    }
  }

  Future<void> _reportsThrowAfterLocalForwarding() async {
    for (final callback in [
      'error(exception, stack); throw exception;',
      'try { error(exception, stack); return true; } catch (_) { rethrow; }',
    ]) {
      final source =
          r'''
import 'dart:ui';
import 'package:flutter/foundation.dart';

abstract final class Crash {
  static void init() {
    PlatformDispatcher.instance.onError = (exception, stack) {
      FORWARD
    };
  }
  static void error(Object error, StackTrace stack) {
    debugPrint('Uncaught ${error.runtimeType}');
  }
}
'''
              .replaceFirst('FORWARD', callback);
      newFile(crashServicePath, source);
      await assertDiagnosticsInFile(crashServicePath, [
        compatLint(source, 'PlatformDispatcher.instance.onError =', ruleName),
      ]);
    }
  }
}

final class _CrashSentrySendDefaultPiiTest extends _CrashSdkRuleTest {
  static Map<String, Future<void> Function(_CrashSentrySendDefaultPiiTest)> get _allCases =>
      caseSet<_CrashSentrySendDefaultPiiTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_allowsFalse': (t) => t._allowsFalse(),
          'test_allowsUnrelatedOptionClass': (t) => t._allowsUnrelatedOptionClass(),
        },
      );

  @override
  String get ruleName => 'crash_sentry_send_default_pii';
  @override
  String get needle => 'options.sendDefaultPii = true;';
  @override
  String get path => crashServicePath;
  @override
  String get source => r'''
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> init() => SentryFlutter.init((options) {
  options.sendDefaultPii = true;
});
''';

  Future<void> _allowsFalse() async {
    await assertAllows(r'''
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> init() => SentryFlutter.init((options) {
  options.sendDefaultPii = false;
});
''', path: path);
  }

  Future<void> _allowsUnrelatedOptionClass() async {
    await assertAllows(r'''
class AnalyticsOptions {
  bool sendDefaultPii = false;
}

void configure(AnalyticsOptions options) {
  options.sendDefaultPii = true;
}
''', path: path);
  }
}

final class _CrashSentryCaptureOptInTest extends _CrashSdkRuleTest {
  static Map<String, Future<void> Function(_CrashSentryCaptureOptInTest)> get _allCases =>
      caseSet<_CrashSentryCaptureOptInTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_reportsViewHierarchy': (t) => t._reportsViewHierarchy(),
          'test_allowsDisabledCapture': (t) => t._allowsDisabledCapture(),
        },
      );

  @override
  String get ruleName => 'crash_sentry_capture_opt_in';
  @override
  String get needle => 'options.attachScreenshot = true;';
  @override
  String get path => crashServicePath;
  @override
  String get source => r'''
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> init() => SentryFlutter.init((options) {
  options.attachScreenshot = true;
});
''';

  Future<void> _reportsViewHierarchy() async {
    const source = r'''
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> init() => SentryFlutter.init((options) {
  options.attachViewHierarchy = true;
});
''';
    newFile(path, source);

    await assertDiagnosticsInFile(path, [
      compatLint(source, 'options.attachViewHierarchy = true;', ruleName),
    ]);
  }

  Future<void> _allowsDisabledCapture() async {
    await assertAllows(r'''
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> init() => SentryFlutter.init((options) {
  options.attachScreenshot = false;
  options.attachViewHierarchy = false;
});
''', path: path);
  }
}

void _defineSourceScannerRulesPartCrashTests() {
  analysisRuleSuite<_DataLogRethrowTest>(
    'DataLogRethrowTest',
    _DataLogRethrowTest.new,
    _DataLogRethrowTest._allCases,
  );
  analysisRuleSuite<_CrashPossiblePiiTest>(
    'CrashPossiblePiiTest',
    _CrashPossiblePiiTest.new,
    _CrashPossiblePiiTest._allCases,
  );
  analysisRuleSuite<_CrashDirectSentryCallTest>(
    'CrashDirectSentryCallTest',
    _CrashDirectSentryCallTest.new,
    _CrashDirectSentryCallTest._allCases,
  );
  analysisRuleSuite<_CrashCustomGlobalErrorHandlerTest>(
    'CrashCustomGlobalErrorHandlerTest',
    _CrashCustomGlobalErrorHandlerTest.new,
    _CrashCustomGlobalErrorHandlerTest._allCases,
  );
  analysisRuleSuite<_CrashSentrySendDefaultPiiTest>(
    'CrashSentrySendDefaultPiiTest',
    _CrashSentrySendDefaultPiiTest.new,
    _CrashSentrySendDefaultPiiTest._allCases,
  );
  analysisRuleSuite<_CrashSentryCaptureOptInTest>(
    'CrashSentryCaptureOptInTest',
    _CrashSentryCaptureOptInTest.new,
    _CrashSentryCaptureOptInTest._allCases,
  );
}
