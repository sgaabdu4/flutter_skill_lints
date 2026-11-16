part of '../source_scanner_rules_test.dart';

void _defineSourceScannerRulesPart01Tests() {
  analysisRuleSuite<RiverpodReadInitStateTest>(
    'RiverpodReadInitStateTest',
    RiverpodReadInitStateTest.new,
    {
      'test_allowsReadInAnotherMethod': (t) => t._allowsReadInAnotherMethod(),
      'test_reportsReadInsidePostFrameCallback': (t) => t._reportsReadInsidePostFrameCallback(),
      'test_reportsReadInsideMicrotask': (t) => t._reportsReadInsideMicrotask(),
      'test_reportsImmediatelyInvokedRead': (t) => t._reportsImmediatelyInvokedRead(),
      'test_reportsSynchronousCallback': (t) => t._reportsSynchronousCallback(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
  analysisRuleSuite<RiverpodServiceLocatorTest>(
    'RiverpodServiceLocatorTest',
    RiverpodServiceLocatorTest.new,
    {
      'test_reportsPrefixedLocatorAndFactoryClasses': (t) =>
          t._reportsPrefixedLocatorAndFactoryClasses(),
      'test_allowsNamesThatOnlyContainTheBannedWords': (t) =>
          t._allowsNamesThatOnlyContainTheBannedWords(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
  analysisRuleSuite<RiverpodManualProviderTest>(
    'RiverpodManualProviderTest',
    RiverpodManualProviderTest.new,
    {
      'test_reportsTypedManualProvider': (t) => t._reportsTypedManualProvider(),
      'test_reportsFamilyProvider': (t) => t._reportsFamilyProvider(),
      'test_reportsGenericFamilyProvider': (t) => t._reportsGenericFamilyProvider(),
      'test_reportsMultilineGenericFamilyProvider': (t) =>
          t._reportsMultilineGenericFamilyProvider(),
      'test_reportsOtherManualProviderTypes': (t) => t._reportsOtherManualProviderTypes(),
      'test_allowsGeneratedProviderDeclaration': (t) => t._allowsGeneratedProviderDeclaration(),
      'test_allowsProviderScope': (t) => t._allowsProviderScope(),
      'test_reportsResolvedTypedAndReturnedProviders': (t) =>
          t._reportsResolvedTypedAndReturnedProviders(),
      'test_reportsResolvedUntypedProvidersOnce': (t) => t._reportsResolvedUntypedProvidersOnce(),
      'test_allowsGeneratedProviderSubclassesAndFamilyCalls': (t) =>
          t._allowsGeneratedProviderSubclassesAndFamilyCalls(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
  analysisRuleSuite<RiverpodNotifierOverrideWithValueTest>(
    'RiverpodNotifierOverrideWithValueTest',
    RiverpodNotifierOverrideWithValueTest.new,
    {
      'test_reportsSingleLineStateConstructorOverride': (t) =>
          t._reportsSingleLineStateConstructorOverride(),
      'test_allowsNotifierFactoryOverride': (t) => t._allowsNotifierFactoryOverride(),
      'test_allowsRepositoryValueOverride': (t) => t._allowsRepositoryValueOverride(),
      'test_allowsAsyncValueOverride': (t) => t._allowsAsyncValueOverride(),
      'test_allowsTestFileStateOverride': (t) => t._allowsTestFileStateOverride(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
  analysisRuleSuite<RiverpodConsumerStateDerivedCacheTest>(
    'RiverpodConsumerStateDerivedCacheTest',
    RiverpodConsumerStateDerivedCacheTest.new,
    {
      'test_reportsDayStartMemoizationField': (t) => t._reportsDayStartMemoizationField(),
      'test_reportsDerivedIndexField': (t) => t._reportsDerivedIndexField(),
      'test_reportsResolvedProviderDerivedFields': (t) => t._reportsResolvedProviderDerivedFields(),
      'test_allowsLifecycleHandlesSeededFromProviders': (t) =>
          t._allowsLifecycleHandlesSeededFromProviders(),
      'test_severityIsError': (t) => t._severityIsError(),
      'test_allowsControllerStateWithProviderWatch': (t) =>
          t._allowsControllerStateWithProviderWatch(),
      'test_allowsNonConsumerStateMemoizationHelper': (t) =>
          t._allowsNonConsumerStateMemoizationHelper(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
  analysisRuleSuite<RiverpodWidgetProviderArgWrapperTest>(
    'RiverpodWidgetProviderArgWrapperTest',
    RiverpodWidgetProviderArgWrapperTest.new,
    {
      'test_reportsConsumerStateProviderArgField': (t) => t._reportsConsumerStateProviderArgField(),
      'test_reportsBuildLocalProviderArgWrapper': (t) => t._reportsBuildLocalProviderArgWrapper(),
      'test_reportsInlineProviderArgWrapper': (t) => t._reportsInlineProviderArgWrapper(),
      'test_allowsDirectProviderIdArg': (t) => t._allowsDirectProviderIdArg(),
      'test_allowsUiConfigNotPassedToProvider': (t) => t._allowsUiConfigNotPassedToProvider(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
  analysisRuleSuite<RiverpodConsumerStateProviderSubscriptionTest>(
    'RiverpodConsumerStateProviderSubscriptionTest',
    RiverpodConsumerStateProviderSubscriptionTest.new,
    {
      'test_reportsPrefixedProviderSubscriptionField': (t) =>
          t._reportsPrefixedProviderSubscriptionField(),
      'test_allowsRefListenInBuildWithoutStoredHandle': (t) =>
          t._allowsRefListenInBuildWithoutStoredHandle(),
      'test_allowsProviderSubscriptionOutsideWidgetState': (t) =>
          t._allowsProviderSubscriptionOutsideWidgetState(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
  analysisRuleSuite<RiverpodListenManualForbiddenTest>(
    'RiverpodListenManualForbiddenTest',
    RiverpodListenManualForbiddenTest.new,
    {
      'test_reportsAssignedListenManual': (t) => t._reportsAssignedListenManual(),
      'test_reportsListenManualInTests': (t) => t._reportsListenManualInTests(),
      'test_allowsRefListenInBuild': (t) => t._allowsRefListenInBuild(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
}
