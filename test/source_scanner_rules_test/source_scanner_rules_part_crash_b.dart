part of '../source_scanner_rules_test.dart';

final class _CrashFacadePublicApiTest extends _DataCrashRuleTest {
  static Map<String, Future<void> Function(_CrashFacadePublicApiTest)> get _allCases =>
      caseSet<_CrashFacadePublicApiTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_reportsPublicField': (t) => t._reportsPublicField(),
          'test_allowsInitLogErrorAndPrivateMembers': (t) =>
              t._allowsInitLogErrorAndPrivateMembers(),
        },
      );

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

  Future<void> _reportsPublicField() async {
    const source = r'''
abstract final class Crash {
  static const checkoutTag = 'checkout';
  static void log(String message) {}
}
''';
    newFile(path, source);

    await assertDiagnosticsInFile(path, [compatLint(source, "checkoutTag = 'checkout'", ruleName)]);
  }

  Future<void> _allowsInitLogErrorAndPrivateMembers() async {
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

final class _CrashErrorRecursionTest extends _CrashSdkRuleTest {
  static Map<String, Future<void> Function(_CrashErrorRecursionTest)> get _allCases =>
      caseSet<_CrashErrorRecursionTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_allowsContainedSendFailure': (t) => t._allowsContainedSendFailure(),
          'test_allowsStartupCallbacksForwardingToTerminalError': (t) =>
              t._allowsStartupCallbacksForwardingToTerminalError(),
          'test_reportsSendFailureFromStartupCallback': (t) =>
              t._reportsSendFailureFromStartupCallback(),
          'test_allowsFeatureCallsToCrashError': (t) => t._allowsFeatureCallsToCrashError(),
        },
      );

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

  Future<void> _allowsContainedSendFailure() async {
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

  Future<void> _allowsStartupCallbacksForwardingToTerminalError() async {
    await assertAllows(r'''
import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';

abstract final class Crash {
  static Future<void> init(StackTrace stack, {required FutureOr<void> Function() appRunner}) async {
    FlutterError.onError = (details) => error(details, stack);
    PlatformDispatcher.instance.onError = (exception, stack) {
      error(exception, stack);
      return true;
    };
    await appRunner();
  }

  static void error(Object error, StackTrace stackTrace) {}
}
''', path: path);
  }

  Future<void> _reportsSendFailureFromStartupCallback() async {
    const source = r'''
import 'dart:ui';

abstract final class Crash {
  static void init() {
    PlatformDispatcher.instance.onError = (exception, stack) {
      try {
        send(exception);
      } catch (failure, trace) {
        error(failure, trace);
      }
      return true;
    };
  }
  static void send(Object error) {}
  static void error(Object error, StackTrace stack) {}
}
''';
    newFile(path, source);
    await assertDiagnosticsInFile(path, [compatLint(source, 'error(failure, trace);', ruleName)]);
  }

  Future<void> _allowsFeatureCallsToCrashError() async {
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

final class _CrashSentryAuthTokenInSourceTest extends _DataCrashRuleTest {
  static Map<String, Future<void> Function(_CrashSentryAuthTokenInSourceTest)> get _allCases =>
      caseSet<_CrashSentryAuthTokenInSourceTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_reportsEnvironmentBundledToken': (t) => t._reportsEnvironmentBundledToken(),
          'test_allowsPublicDsnConfig': (t) => t._allowsPublicDsnConfig(),
        },
      );

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

  Future<void> _reportsEnvironmentBundledToken() async {
    const source = r'''
const sentryAuthToken = String.fromEnvironment('SENTRY_AUTH_TOKEN');
''';
    newFile(path, source);

    await assertDiagnosticsInFile(path, [
      compatLint(source, "String.fromEnvironment('SENTRY_AUTH_TOKEN')", ruleName),
    ]);
  }

  Future<void> _allowsPublicDsnConfig() async {
    await assertAllows(r'''
const sentryDsn = String.fromEnvironment('SENTRY_DSN');
''', path: path);
  }
}

void _defineSourceScannerRulesPartCrashBTests() {
  analysisRuleSuite<_CrashFacadePublicApiTest>(
    'CrashFacadePublicApiTest',
    _CrashFacadePublicApiTest.new,
    _CrashFacadePublicApiTest._allCases,
  );
  analysisRuleSuite<_CrashErrorRecursionTest>(
    'CrashErrorRecursionTest',
    _CrashErrorRecursionTest.new,
    _CrashErrorRecursionTest._allCases,
  );
  analysisRuleSuite<_CrashSentryAuthTokenInSourceTest>(
    'CrashSentryAuthTokenInSourceTest',
    _CrashSentryAuthTokenInSourceTest.new,
    _CrashSentryAuthTokenInSourceTest._allCases,
  );
}
