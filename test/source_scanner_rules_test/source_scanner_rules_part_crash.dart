// ignore_for_file: non_constant_identifier_names

part of '../source_scanner_rules_test.dart';

abstract class _DataCrashRuleTest extends _SourceRuleTest {
  @override
  List<ScannerRule> get rules => dataCrashSourceRules;
}

@reflectiveTest
final class DataLogRethrowTest extends _DataCrashRuleTest {
  @override
  String get ruleName => 'data_log_rethrow';
  @override
  String get needle => 'log(error);';
  @override
  bool get lineStart => true;
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
  Future<void> test_reportsCrashReportThenRethrow() async {
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
      compatLint(source, 'Crash.error(error, stackTrace);', ruleName, lineStart: true),
    ]);
  }

  Future<void> test_reportsCrashReportThenThrowCaughtError() async {
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
      compatLint(source, 'Crash.error(error, stackTrace);', ruleName, lineStart: true),
    ]);
  }

  Future<void> test_allowsReportThenMappedTypedError() async {
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

  Future<void> test_allowsRethrowWithoutReport() async {
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

@reflectiveTest
final class CrashPossiblePiiTest extends _DataCrashRuleTest {
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

@reflectiveTest
final class CrashDirectSentryCallTest extends _CrashSdkRuleTest {
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

  Future<void> test_reportsImportAndCaptureCall() async {
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

  Future<void> test_reportsSdkUseInOtherCoreCrashFiles() async {
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

  Future<void> test_allowsCrashService() async {
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

  Future<void> test_allowsCrashFacadeCalls() async {
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

@reflectiveTest
final class CrashCustomGlobalErrorHandlerTest extends _CrashSdkRuleTest {
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

  Future<void> test_reportsPlatformDispatcherHandler() async {
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

  Future<void> test_reportsCustomHandlerInCrashService() async {
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

  Future<void> test_reportsCustomHandlerInsideCrashFacade() async {
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

  Future<void> test_reportsCrashlyticsHandlersOutsideCrashFacade() async {
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

  Future<void> test_reportsBootstrapHandlers() async {
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

  Future<void> test_allowsCrashlyticsHandlersInsideCrashFacade() async {
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

  Future<void> test_allowsReadingHandler() async {
    await assertAllows(r'''
import 'package:flutter/foundation.dart';

final previous = FlutterError.onError;
''', path: path);
  }
}

@reflectiveTest
final class CrashSentrySendDefaultPiiTest extends _CrashSdkRuleTest {
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

  Future<void> test_allowsFalse() async {
    await assertAllows(r'''
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> init() => SentryFlutter.init((options) {
  options.sendDefaultPii = false;
});
''', path: path);
  }

  Future<void> test_allowsUnrelatedOptionClass() async {
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

@reflectiveTest
final class CrashSentryCaptureOptInTest extends _CrashSdkRuleTest {
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

  Future<void> test_reportsViewHierarchy() async {
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

  Future<void> test_allowsDisabledCapture() async {
    await assertAllows(r'''
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> init() => SentryFlutter.init((options) {
  options.attachScreenshot = false;
  options.attachViewHierarchy = false;
});
''', path: path);
  }
}

@reflectiveTest
final class CrashFacadePublicApiTest extends _DataCrashRuleTest {
  @override
  String get ruleName => 'crash_facade_public_api';
  @override
  String get needle => 'setBackend(Object backend)';
  @override
  String get path => '$testPackageLibPath/core/crash/crash_service.dart';
  @override
  String get source => r'''
abstract final class Crash {
  static Object? _backend;
  static void setBackend(Object backend) => _backend = backend;
  static void error(Object error, StackTrace stackTrace) {}
}
''';

  Future<void> test_reportsPublicField() async {
    const source = r'''
abstract final class Crash {
  static const checkoutTag = 'checkout';
  static void log(String message) {}
}
''';
    newFile(path, source);

    await assertDiagnosticsInFile(path, [compatLint(source, "checkoutTag = 'checkout'", ruleName)]);
  }

  Future<void> test_allowsInitLogErrorAndPrivateMembers() async {
    await assertAllows(r'''
abstract final class Crash {
  static bool _enabled = false;
  static Future<void> init({required void Function() appRunner}) async {
    _enabled = true;
    appRunner();
  }
  static void log(String message, {Map<String, Object?> extras = const {}}) => _send(message);
  static void error(Object error, StackTrace stackTrace, {String? reason}) => _send(error);
  static void _send(Object value) {}
}
''', path: path);
  }
}

@reflectiveTest
final class CrashErrorRecursionTest extends _DataCrashRuleTest {
  @override
  String get ruleName => 'crash_error_recursion';
  @override
  String get needle => 'Crash.error(sendError, sendStack);';
  @override
  String get path => '$testPackageLibPath/core/crash/crash_service.dart';
  @override
  String get source => r'''
abstract final class Crash {
  static void error(Object error, StackTrace stackTrace) {
    try {
      _send(error);
    } on Object catch (sendError, sendStack) {
      Crash.error(sendError, sendStack);
    }
  }
  static void _send(Object value) {}
}
''';

  Future<void> test_allowsContainedSendFailure() async {
    await assertAllows(r'''
void debugPrint(String message) {}

abstract final class Crash {
  static void error(Object error, StackTrace stackTrace) {
    try {
      _send(error);
    } on Object catch (sendError) {
      debugPrint('crash send failed: ${sendError.runtimeType}');
    }
  }
  static void _send(Object value) {}
}
''', path: path);
  }

  Future<void> test_allowsFeatureCallsToCrashError() async {
    await assertAllows(r'''
abstract final class Crash {
  static void error(Object error, StackTrace stackTrace) {}
}

void submit(Object error) {
  Crash.error(error, StackTrace.current);
}
''', path: '$testPackageLibPath/features/checkout/data/checkout_repository.dart');
  }
}

@reflectiveTest
final class CrashSentryAuthTokenInSourceTest extends _DataCrashRuleTest {
  @override
  String get ruleName => 'crash_sentry_auth_token_in_source';
  @override
  String get needle => "'sntrys_fixture';";
  @override
  String get path => '$testPackageLibPath/core/config/sentry_upload.dart';
  @override
  String get source => r'''
const sentryAuthToken = 'sntrys_fixture';
''';

  Future<void> test_reportsEnvironmentBundledToken() async {
    const source = r'''
const sentryAuthToken = String.fromEnvironment('SENTRY_AUTH_TOKEN');
''';
    newFile(path, source);

    await assertDiagnosticsInFile(path, [
      compatLint(source, "String.fromEnvironment('SENTRY_AUTH_TOKEN')", ruleName),
    ]);
  }

  Future<void> test_allowsPublicDsnConfig() async {
    await assertAllows(r'''
const sentryDsn = String.fromEnvironment('SENTRY_DSN');
''', path: path);
  }
}
