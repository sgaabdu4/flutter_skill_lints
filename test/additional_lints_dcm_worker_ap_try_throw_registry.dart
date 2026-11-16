part of 'additional_lints_dcm_worker_ap_try_throw_test.dart';

void _defineAdditionalLintsDcmWorkerApTryThrowTestTests() {
  analysisRuleSuite<AvoidNestedTryStatementsTest>(
    'AvoidNestedTryStatementsTest',
    AvoidNestedTryStatementsTest.new,
    {
      'test_tryInsideTryBody_lint': (t) => t._tryInsideTryBodyLint(),
      'test_tryInsideCatch_lint': (t) => t._tryInsideCatchLint(),
      'test_tryInsideLocalFunction_noLint': (t) => t._tryInsideLocalFunctionNoLint(),
      'test_sequentialTryStatements_noLint': (t) => t._sequentialTryStatementsNoLint(),
    },
  );
  analysisRuleSuite<AvoidIdenticalExceptionHandlingBlocksTest>(
    'AvoidIdenticalExceptionHandlingBlocksTest',
    AvoidIdenticalExceptionHandlingBlocksTest.new,
    {
      'test_identicalCatchBodies_lintSecondBody': (t) => t._identicalCatchBodiesLintSecondBody(),
      'test_identicalCatchBodiesWithDifferentWhitespace_lintSecondBody': (t) =>
          t._identicalCatchBodiesWithDifferentWhitespaceLintSecondBody(),
      'test_differentCatchBodies_noLint': (t) => t._differentCatchBodiesNoLint(),
      'test_emptyCatchBodies_noLint': (t) => t._emptyCatchBodiesNoLint(),
    },
  );
  analysisRuleSuite<AvoidThrowTest>('AvoidThrowTest', AvoidThrowTest.new, {
    'test_severity_error': (t) async => t._severityError(),
    'test_scopedProviderOverrideStub_noLint': (t) => t._scopedProviderOverrideStubNoLint(),
    'test_nonScopedOrNonStubProviderThrow_lint': (t) => t._nonScopedOrNonStubProviderThrowLint(),
    'test_throwStatement_lint': (t) => t._throwStatementLint(),
    'test_throwExpressionBody_lint': (t) => t._throwExpressionBodyLint(),
    'test_documentedParserFormatException_noLint': (t) =>
        t._documentedParserFormatExceptionNoLint(),
    'test_typedExceptionSubtypeOutsidePresentation_noLint': (t) =>
        t._typedExceptionSubtypeOutsidePresentationNoLint(),
    'test_baseExceptionErrorsAndUntypedValues_lint': (t) =>
        t._baseExceptionErrorsAndUntypedValuesLint(),
    'test_nonExceptionFormatExceptionLookalike_lint': (t) =>
        t._nonExceptionFormatExceptionLookalikeLint(),
    'test_widgetAndStateBuildStillReportTypedThrows': (t) =>
        t._widgetAndStateBuildStillReportTypedThrows(),
    'test_widgetHelperMethodStillReportsTypedThrow': (t) =>
        t._widgetHelperMethodStillReportsTypedThrow(),
    'test_sameUnitFlutterCallbackFunctionAndGenericTearoffsStillReport': (t) =>
        t._sameUnitFlutterCallbackFunctionAndGenericTearoffsStillReport(),
    'test_resolvedWidgetCallbackAndDeferredThrowStillReport': (t) =>
        t._resolvedWidgetCallbackAndDeferredThrowStillReport(),
    'test_lookalikeWidgetCallbackDoesNotCreateUiBoundary': (t) =>
        t._lookalikeWidgetCallbackDoesNotCreateUiBoundary(),
    'test_genericErrorCallbackDoesNotHideUntypedThrow': (t) =>
        t._genericErrorCallbackDoesNotHideUntypedThrow(),
    'test_actualRiverpodNotifierMutationStillReportsTypedThrow': (t) =>
        t._actualRiverpodNotifierMutationStillReportsTypedThrow(),
    'test_codegenRiverpodNotifierTypedThrow_lint': (t) =>
        t._codegenRiverpodNotifierTypedThrowLint(),
    'test_datasourceTypedThrowNextToCodegenNotifier_noLint': (t) =>
        t._datasourceTypedThrowNextToCodegenNotifierNoLint(),
    'test_validatedValueObjectArgumentGuard_noLint': (t) =>
        t._validatedValueObjectArgumentGuardNoLint(),
    'test_valueObjectExtractedGuardHelper_noLint': (t) =>
        t._valueObjectExtractedGuardHelperNoLint(),
    'test_guardHelperOutsideContract_lint': (t) => t._guardHelperOutsideContractLint(),
    'test_unrelatedThrowInValueObject_stillReports': (t) =>
        t._unrelatedThrowInValueObjectStillReports(),
    'test_valueObjectGuardThroughFinalParameterLocal_noLint': (t) =>
        t._valueObjectGuardThroughFinalParameterLocalNoLint(),
    'test_valueObjectGuardThroughNonFinalOrUnrelatedLocal_lint': (t) =>
        t._valueObjectGuardThroughNonFinalOrUnrelatedLocalLint(),
    'test_coreThrowWithStackTraceUntypedValue_lint': (t) =>
        t._coreThrowWithStackTraceUntypedValueLint(),
    'test_coreThrowWithStackTracePropagationAndTypedFailure_noLint': (t) =>
        t._coreThrowWithStackTracePropagationAndTypedFailureNoLint(),
    'test_coreThrowWithStackTraceInPresentation_lint': (t) =>
        t._coreThrowWithStackTraceInPresentationLint(),
    'test_nonCoreThrowWithStackTrace_noLint': (t) => t._nonCoreThrowWithStackTraceNoLint(),
    'test_rethrow_noLint': (t) => t._rethrowNoLint(),
    'test_generatedLocalizationThrow_noLint': (t) => t._generatedLocalizationThrowNoLint(),
  });
  analysisRuleSuite<AvoidOnlyRethrowTest>('AvoidOnlyRethrowTest', AvoidOnlyRethrowTest.new, {
    'test_trailingRethrowOnlyCatch_lint': (t) => t._trailingRethrowOnlyCatchLint(),
    'test_rethrowOnlyCatchBeforeFinally_lint': (t) => t._rethrowOnlyCatchBeforeFinallyLint(),
    'test_skillDataLayerCatches_noLint': (t) => t._skillDataLayerCatchesNoLint(),
  });
}
