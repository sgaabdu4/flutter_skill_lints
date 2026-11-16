part of '../source_scanner_rules_test.dart';

void _defineSourceScannerRulesPart02Tests() {
  analysisRuleSuite<RiverpodEventCounterSignalForbiddenTest>(
    'RiverpodEventCounterSignalForbiddenTest',
    RiverpodEventCounterSignalForbiddenTest.new,
    {
      'test_reportsStatePlusOneVariant': (t) => t._reportsStatePlusOneVariant(),
      'test_reportsPayloadSignalProvider': (t) => t._reportsPayloadSignalProvider(),
      'test_reportsFunctionEventProvider': (t) => t._reportsFunctionEventProvider(),
      'test_reportsNotifierSuffixedEventClassAndNestedGenericFunction': (t) =>
          t._reportsNotifierSuffixedEventClassAndNestedGenericFunction(),
      'test_allowsEventNamesWithoutRiverpodAnnotation': (t) =>
          t._allowsEventNamesWithoutRiverpodAnnotation(),
      'test_allowsPayloadStreamName': (t) => t._allowsPayloadStreamName(),
      'test_allowsOwningNotifierStateSerial': (t) => t._allowsOwningNotifierStateSerial(),
      'test_allowsDomainCounterNotifier': (t) => t._allowsDomainCounterNotifier(),
      'test_allowsDurableStatusNotifier': (t) => t._allowsDurableStatusNotifier(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
  analysisRuleSuite<RiverpodWatchNoSelectTest>(
    'RiverpodWatchNoSelectTest',
    RiverpodWatchNoSelectTest.new,
    {
      'test_allowsGeneratedNotifierBuildDependencies': (t) =>
          t._allowsGeneratedNotifierBuildDependencies(),
      'test_allowsResolvedScalarResults': (t) => t._allowsResolvedScalarResults(),
      'test_reportsStructuredWatchBesideScalarOnSameLine': (t) =>
          t._reportsStructuredWatchBesideScalarOnSameLine(),
      'test_allowsMultilineFamilyProviderSelect': (t) => t._allowsMultilineFamilyProviderSelect(),
      'test_allowsDirectWatchOfComputedProjectionProvider': (t) =>
          t._allowsDirectWatchOfComputedProjectionProvider(),
      'test_reportsFieldReadOfComputedProvider': (t) => t._reportsFieldReadOfComputedProvider(),
      'test_reportsFieldReadOfNotifierProvider': (t) => t._reportsFieldReadOfNotifierProvider(),
      'test_reportsProjectionNamedNotifierProvider': (t) =>
          t._reportsProjectionNamedNotifierProvider(),
      'test_allowsWholeListAndDtoPassedToWidgets': (t) => t._allowsWholeListAndDtoPassedToWidgets(),
      'test_allowsWholeValuesThroughLocalBindings': (t) =>
          t._allowsWholeValuesThroughLocalBindings(),
      'test_reportsWholeMultiFieldStateIntoAppWidget': (t) =>
          t._reportsWholeMultiFieldStateIntoAppWidget(),
      'test_reportsWholeMultiFieldStateLocalIntoAppWidget': (t) =>
          t._reportsWholeMultiFieldStateLocalIntoAppWidget(),
      'test_reportsFreezedStateIntoAppWidget': (t) => t._reportsFreezedStateIntoAppWidget(),
      'test_allowsWholeViewValuesIntoAppWidget': (t) => t._allowsWholeViewValuesIntoAppWidget(),
      'test_allowsWholeValueIntoFrameworkWidget': (t) => t._allowsWholeValueIntoFrameworkWidget(),
      'test_allowsWholeListIteration': (t) => t._allowsWholeListIteration(),
      'test_reportsSelectingOneIndexedListItem': (t) => t._reportsSelectingOneIndexedListItem(),
      'test_reportsWholeAsyncValueWhenDispatch': (t) => t._reportsWholeAsyncValueWhenDispatch(),
      'test_reportsWholeDispatchOnSameNamedLocalAsyncValue': (t) =>
          t._reportsWholeDispatchOnSameNamedLocalAsyncValue(),
      'test_allowsWholeAsyncStatusSwitch': (t) => t._allowsWholeAsyncStatusSwitch(),
      'test_allowsSealedUnionVariantSwitch': (t) => t._allowsSealedUnionVariantSwitch(),
      'test_allowsAsyncValueVariantDestructuring': (t) => t._allowsAsyncValueVariantDestructuring(),
      'test_reportsSealedBaseTypeFieldPattern': (t) => t._reportsSealedBaseTypeFieldPattern(),
      'test_reportsPartialObjectPatternSwitch': (t) => t._reportsPartialObjectPatternSwitch(),
      'test_reportsPartialStateReads': (t) => t._reportsPartialStateReads(),
      'test_allowsMutationStateFlags': (t) => t._allowsMutationStateFlags(),
      'test_reportsLocalMutationStateLookalike': (t) => t._reportsLocalMutationStateLookalike(),
      'test_conditionalWholeListClearButPartialStateWarns': (t) =>
          t._conditionalWholeListClearButPartialStateWarns(),
      'test_reportsWatchSplitAcrossLines': (t) => t._reportsWatchSplitAcrossLines(),
      'test_allowsWatchOnNonRiverpodReceiver': (t) => t._allowsWatchOnNonRiverpodReceiver(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
}
