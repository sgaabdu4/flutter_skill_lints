part of '../source_scanner_rules_test.dart';

void _defineSourceScannerRulesPart12Tests() {
  analysisRuleSuite<TestMockConcreteTest>('TestMockConcreteTest', TestMockConcreteTest.new, {
    'test_allowsAbstractContractsWithoutNamingPrefix': (t) =>
        t._allowsAbstractContractsWithoutNamingPrefix(),
    'test_reportsConcreteContractWithInterfacePrefix': (t) =>
        t._reportsConcreteContractWithInterfacePrefix(),
    'test_reportsExternalSdkPartDeclarations': (t) => t._reportsExternalSdkPartDeclarations(),
    'test_allowsExternalAbstractPartDeclaration': (t) => t._allowsExternalAbstractPartDeclaration(),
    'test_reportsExternalPluginControllerMocks': (t) => t._reportsExternalPluginControllerMocks(),
    'test_localConcreteSdkNameStillReports': (t) => t._localConcreteSdkNameStillReports(),
    'test_localFunctionsAndStorageConcreteNamesStillReport': (t) =>
        t._localFunctionsAndStorageConcreteNamesStillReport(),
    'test_allowsLocalFunctionsAndStorageInterfaces': (t) =>
        t._allowsLocalFunctionsAndStorageInterfaces(),
    'test_concreteAliasStillReports': (t) => t._concreteAliasStillReports(),
    'test_reportsFakeOfConcreteContract': (t) => t._reportsFakeOfConcreteContract(),
    'test_allowsSkillFakeOfInterface': (t) => t._allowsSkillFakeOfInterface(),
    'test_allowsLocalClassNamedMock': (t) => t._allowsLocalClassNamedMock(),
    'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
  });
  analysisRuleSuite<TestPumpAndSettleTest>('TestPumpAndSettleTest', TestPumpAndSettleTest.new, {
    'test_allowsExplicitDurationArgument': (t) => t._allowsExplicitDurationArgument(),
    'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
  });
  analysisRuleSuite<TestTapAtTest>('TestTapAtTest', TestTapAtTest.new, {
    'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
  });
  analysisRuleSuite<TestInlineValueKeyTest>('TestInlineValueKeyTest', TestInlineValueKeyTest.new, {
    'test_reportsInlineKeyFactoryString': (t) => t._reportsInlineKeyFactoryString(),
    'test_allowsRegistryConstantKeys': (t) => t._allowsRegistryConstantKeys(),
    'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
  });
  analysisRuleSuite<TestFirstMatchFinderTest>(
    'TestFirstMatchFinderTest',
    TestFirstMatchFinderTest.new,
    {
      'test_allowsIterableFirstAccess': (t) => t._allowsIterableFirstAccess(),
      'test_reportsFirstOnFinder': (t) => t._reportsFirstOnFinder(),
      'test_allowsIterableFirstInsideFinderArgument': (t) =>
          t._allowsIterableFirstInsideFinderArgument(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
  analysisRuleSuite<TestNotifierOverrideTest>(
    'TestNotifierOverrideTest',
    TestNotifierOverrideTest.new,
    {
      'test_reportsFamilyNotifierOverride': (t) => t._reportsFamilyNotifierOverride(),
      'test_allowsSkillBuildValueAndRepositoryOverrides': (t) =>
          t._allowsSkillBuildValueAndRepositoryOverrides(),
      'test_allowsNotifierOverrideOutsideTests': (t) => t._allowsNotifierOverrideOutsideTests(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
  analysisRuleSuite<TestE2eBlindSleepTest>('TestE2eBlindSleepTest', TestE2eBlindSleepTest.new, {
    'test_reportsHostDriverDelay': (t) => t._reportsHostDriverDelay(),
    'test_allowsPollingLoopAndUnawaitedDelay': (t) => t._allowsPollingLoopAndUnawaitedDelay(),
    'test_allowsDelayOutsideE2e': (t) => t._allowsDelayOutsideE2e(),
    'test_allowsLocalDelayedLookalike': (t) => t._allowsLocalDelayedLookalike(),
    'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
  });
  analysisRuleSuite<TestTextLabelSelectorTest>(
    'TestTextLabelSelectorTest',
    TestTextLabelSelectorTest.new,
    {
      'test_reportsWidgetWithTextAndNestedLabelFinders': (t) =>
          t._reportsWidgetWithTextAndNestedLabelFinders(),
      'test_allowsSkillTextAssertionsAndKeyTaps': (t) => t._allowsSkillTextAssertionsAndKeyTaps(),
      'test_allowsStableTextInE2e': (t) => t._allowsStableTextInE2e(),
      'test_allowsNonLiteralLabel': (t) => t._allowsNonLiteralLabel(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
  analysisRuleSuite<DomainEmptyStringSentinelTest>(
    'DomainEmptyStringSentinelTest',
    DomainEmptyStringSentinelTest.new,
    {
      'test_reportsConstructorDefaultThisField': (t) => t._reportsConstructorDefaultThisField(),
      'test_allowsOptionalDomainTextAsNullable': (t) => t._allowsOptionalDomainTextAsNullable(),
      'test_allowsDataModelWireEmptyDefault': (t) => t._allowsDataModelWireEmptyDefault(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
  analysisRuleSuite<VoPublicRawConstructorTest>(
    'VoPublicRawConstructorTest',
    VoPublicRawConstructorTest.new,
    {
      'test_allowsPrivateRawRedirect': (t) => t._allowsPrivateRawRedirect(),
      'test_allowsValidatedFactoryWithoutRedirect': (t) =>
          t._allowsValidatedFactoryWithoutRedirect(),
      'test_allowsRedirectOutsideValueObjectsPath': (t) =>
          t._allowsRedirectOutsideValueObjectsPath(),
      'test_allowsParameterlessPublicRedirect': (t) => t._allowsParameterlessPublicRedirect(),
      'test_reportsAnonymousPublicRawRedirect': (t) => t._reportsAnonymousPublicRawRedirect(),
      'test_reportsNullablePrimitiveParam': (t) => t._reportsNullablePrimitiveParam(),
      'test_reportsMultiParamPublicRawRedirect': (t) => t._reportsMultiParamPublicRawRedirect(),
      'test_allowsCompositeCanonicalRedirect': (t) => t._allowsCompositeCanonicalRedirect(),
      'test_reportsSingleFieldAndNonConstPublicRedirects': (t) =>
          t._reportsSingleFieldAndNonConstPublicRedirects(),
      'test_reportsPassthroughPublicFactory': (t) => t._reportsPassthroughPublicFactory(),
      'test_allowsValidatedFactoryWithAssert': (t) => t._allowsValidatedFactoryWithAssert(),
      'test_allowsTransformingFactory': (t) => t._allowsTransformingFactory(),
      'test_reportsMultiLinePublicRawRedirect': (t) => t._reportsMultiLinePublicRawRedirect(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
}
