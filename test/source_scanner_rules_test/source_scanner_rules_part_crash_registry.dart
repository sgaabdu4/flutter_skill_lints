part of '../source_scanner_rules_test.dart';

void _defineSourceScannerRulesPartCrashTests() {
  analysisRuleSuite<DataLogRethrowTest>('DataLogRethrowTest', DataLogRethrowTest.new, {
    'test_reportsReportingCallsBeforeRethrow': (t) => t._reportsReportingCallsBeforeRethrow(),
    'test_reportsFlutterDebugPrintBeforeRethrow': (t) => t._reportsFlutterDebugPrintBeforeRethrow(),
    'test_allowsSkillDataLayerCatches': (t) => t._allowsSkillDataLayerCatches(),
    'test_reportsRollbackThatReportsBeforeRethrow': (t) =>
        t._reportsRollbackThatReportsBeforeRethrow(),
    'test_reportsCrashReportThenRethrow': (t) => t._reportsCrashReportThenRethrow(),
    'test_reportsCrashReportThenThrowCaughtError': (t) =>
        t._reportsCrashReportThenThrowCaughtError(),
    'test_allowsReportThenMappedTypedError': (t) => t._allowsReportThenMappedTypedError(),
    'test_allowsRethrowWithoutReport': (t) => t._allowsRethrowWithoutReport(),
    'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
  });
  analysisRuleSuite<CrashPossiblePiiTest>('CrashPossiblePiiTest', CrashPossiblePiiTest.new, {
    'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
  });
  analysisRuleSuite<CrashDirectSentryCallTest>(
    'CrashDirectSentryCallTest',
    CrashDirectSentryCallTest.new,
    {
      'test_reportsImportAndCaptureCall': (t) => t._reportsImportAndCaptureCall(),
      'test_reportsSdkUseInOtherCoreCrashFiles': (t) => t._reportsSdkUseInOtherCoreCrashFiles(),
      'test_allowsCrashService': (t) => t._allowsCrashService(),
      'test_allowsCrashFacadeCalls': (t) => t._allowsCrashFacadeCalls(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
  analysisRuleSuite<CrashCustomGlobalErrorHandlerTest>(
    'CrashCustomGlobalErrorHandlerTest',
    CrashCustomGlobalErrorHandlerTest.new,
    {
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
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
  analysisRuleSuite<CrashSentrySendDefaultPiiTest>(
    'CrashSentrySendDefaultPiiTest',
    CrashSentrySendDefaultPiiTest.new,
    {
      'test_allowsFalse': (t) => t._allowsFalse(),
      'test_allowsUnrelatedOptionClass': (t) => t._allowsUnrelatedOptionClass(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
  analysisRuleSuite<CrashSentryCaptureOptInTest>(
    'CrashSentryCaptureOptInTest',
    CrashSentryCaptureOptInTest.new,
    {
      'test_reportsViewHierarchy': (t) => t._reportsViewHierarchy(),
      'test_allowsDisabledCapture': (t) => t._allowsDisabledCapture(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
  analysisRuleSuite<CrashFacadePublicApiTest>(
    'CrashFacadePublicApiTest',
    CrashFacadePublicApiTest.new,
    {
      'test_reportsPublicField': (t) => t._reportsPublicField(),
      'test_allowsInitLogErrorAndPrivateMembers': (t) => t._allowsInitLogErrorAndPrivateMembers(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
  analysisRuleSuite<CrashErrorRecursionTest>(
    'CrashErrorRecursionTest',
    CrashErrorRecursionTest.new,
    {
      'test_allowsContainedSendFailure': (t) => t._allowsContainedSendFailure(),
      'test_allowsStartupCallbacksForwardingToTerminalError': (t) =>
          t._allowsStartupCallbacksForwardingToTerminalError(),
      'test_reportsSendFailureFromStartupCallback': (t) =>
          t._reportsSendFailureFromStartupCallback(),
      'test_allowsFeatureCallsToCrashError': (t) => t._allowsFeatureCallsToCrashError(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
  analysisRuleSuite<CrashSentryAuthTokenInSourceTest>(
    'CrashSentryAuthTokenInSourceTest',
    CrashSentryAuthTokenInSourceTest.new,
    {
      'test_reportsEnvironmentBundledToken': (t) => t._reportsEnvironmentBundledToken(),
      'test_allowsPublicDsnConfig': (t) => t._allowsPublicDsnConfig(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
}
