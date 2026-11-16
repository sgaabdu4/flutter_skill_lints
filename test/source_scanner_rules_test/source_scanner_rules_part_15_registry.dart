part of '../source_scanner_rules_test.dart';

void _defineSourceScannerRulesPart15Tests() {
  analysisRuleSuite<SyncSaveAllNoDirtyGuardTest>(
    'SyncSaveAllNoDirtyGuardTest',
    SyncSaveAllNoDirtyGuardTest.new,
    {
      'test_allowsWhenGuarded': (t) => t._allowsWhenGuarded(),
      'test_allowsNonEntitySaveAll': (t) => t._allowsNonEntitySaveAll(),
      'test_reportsMultilineSaveAll': (t) => t._reportsMultilineSaveAll(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
  analysisRuleSuite<SaveAllFullCollectionAfterSubsetMutationTest>(
    'SaveAllFullCollectionAfterSubsetMutationTest',
    SaveAllFullCollectionAfterSubsetMutationTest.new,
    {
      'test_allowsChangedSubsetWrite': (t) => t._allowsChangedSubsetWrite(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
  analysisRuleSuite<CollectionGetterAllocatesEachAccessTest>(
    'CollectionGetterAllocatesEachAccessTest',
    CollectionGetterAllocatesEachAccessTest.new,
    {
      'test_allowsLateFinalCachedGetter': (t) => t._allowsLateFinalCachedGetter(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
  analysisRuleSuite<ExpandoDerivedCacheForbiddenTest>(
    'ExpandoDerivedCacheForbiddenTest',
    ExpandoDerivedCacheForbiddenTest.new,
    {
      'test_allowsLateFinalDerivedIndex': (t) => t._allowsLateFinalDerivedIndex(),
      'test_skipsTestFiles': (t) => t._skipsTestFiles(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
  analysisRuleSuite<AdHocIdIndexLookupTest>('AdHocIdIndexLookupTest', AdHocIdIndexLookupTest.new, {
    'test_allowsSharedLookupExtension': (t) => t._allowsSharedLookupExtension(),
    'test_reportsIndexOfByKeySubscriptedInPlace': (t) => t._reportsIndexOfByKeySubscriptedInPlace(),
    'test_allowsSkillCachedIndexOfByKey': (t) => t._allowsSkillCachedIndexOfByKey(),
    'test_allowsReturnedIndexMap': (t) => t._allowsReturnedIndexMap(),
    'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
  });
  analysisRuleSuite<LinearIdLookupInHotPathTest>(
    'LinearIdLookupInHotPathTest',
    LinearIdLookupInHotPathTest.new,
    {
      'test_reportsMultilineLookupInIterationCallback': (t) =>
          t._reportsMultilineLookupInIterationCallback(),
      'test_reportsLookupInForEachCallback': (t) => t._reportsLookupInForEachCallback(),
      'test_reportsLookupInCollectionFor': (t) => t._reportsLookupInCollectionFor(),
      'test_reportsNestedIndexWhereLookup': (t) => t._reportsNestedIndexWhereLookup(),
      'test_reportsManualLookupLoopInsideLoop': (t) => t._reportsManualLookupLoopInsideLoop(),
      'test_reportsLookupInBuild': (t) => t._reportsLookupInBuild(),
      'test_reportsIndexedManualLookupInsideCallback': (t) =>
          t._reportsIndexedManualLookupInsideCallback(),
      'test_reportsLookupInWidgetBuilderFunction': (t) => t._reportsLookupInWidgetBuilderFunction(),
      'test_allowsLookupInSingleCallMapCallback': (t) => t._allowsLookupInSingleCallMapCallback(),
      'test_reportsLookupOverIdListInNotifier': (t) => t._reportsLookupOverIdListInNotifier(),
      'test_reportsCompoundAndBlockPredicatesInLoop': (t) =>
          t._reportsCompoundAndBlockPredicatesInLoop(),
      'test_reportsLookupInGetters': (t) => t._reportsLookupInGetters(),
      'test_allowsOneOffRepositoryMutation': (t) => t._allowsOneOffRepositoryMutation(),
      'test_allowsOneOffNotifierLookup': (t) => t._allowsOneOffNotifierLookup(),
      'test_allowsSingleManualLookupLoop': (t) => t._allowsSingleManualLookupLoop(),
      'test_allowsLookupInTapCallbackInsideBuild': (t) => t._allowsLookupInTapCallbackInsideBuild(),
      'test_allowsLookupInLoopIterable': (t) => t._allowsLookupInLoopIterable(),
      'test_allowsMapIndex': (t) => t._allowsMapIndex(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
  analysisRuleSuite<NestedLinearLookupByIdTest>(
    'NestedLinearLookupByIdTest',
    NestedLinearLookupByIdTest.new,
    {
      'test_reportsMultilineIndexWhereLookup': (t) => t._reportsMultilineIndexWhereLookup(),
      'test_reportsLookupOverIdListInNotifier': (t) => t._reportsLookupOverIdListInNotifier(),
      'test_allowsLookupByUnrelatedLongerName': (t) => t._allowsLookupByUnrelatedLongerName(),
      'test_reportsNestedLookupInTopLevelFunction': (t) =>
          t._reportsNestedLookupInTopLevelFunction(),
      'test_reportsNestedLookupInCollectionFor': (t) => t._reportsNestedLookupInCollectionFor(),
      'test_allowsLookupNotKeyedByLoopVariable': (t) => t._allowsLookupNotKeyedByLoopVariable(),
      'test_allowsPreIndexedMap': (t) => t._allowsPreIndexedMap(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
  analysisRuleSuite<AppwriteBlockingFunctionExecutionInClientTest>(
    'AppwriteBlockingFunctionExecutionInClientTest',
    AppwriteBlockingFunctionExecutionInClientTest.new,
    {
      'test_reportsOmittedXasyncInLongRunningMethod': (t) =>
          t._reportsOmittedXasyncInLongRunningMethod(),
      'test_reportsClientWaitingForBackendCompletion': (t) =>
          t._reportsClientWaitingForBackendCompletion(),
      'test_allowsUnresolvedWaitForCompletionLookalike': (t) =>
          t._allowsUnresolvedWaitForCompletionLookalike(),
      'test_allowsAsyncExecution': (t) => t._allowsAsyncExecution(),
      'test_allowsForwardingWrapperWithXasyncParameter': (t) =>
          t._allowsForwardingWrapperWithXasyncParameter(),
      'test_allowsShortInteractiveFunction': (t) => t._allowsShortInteractiveFunction(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
  analysisRuleSuite<DestructiveFailureLoggedBeforeReconcileTest>(
    'DestructiveFailureLoggedBeforeReconcileTest',
    DestructiveFailureLoggedBeforeReconcileTest.new,
    {
      'test_allowsReconcileBeforeTelemetry': (t) => t._allowsReconcileBeforeTelemetry(),
      'test_reportsSkillTelemetryBeforeWaitForReconcile': (t) =>
          t._reportsSkillTelemetryBeforeWaitForReconcile(),
      'test_reportsTelemetryWithoutReconcileAfterAsyncStart': (t) =>
          t._reportsTelemetryWithoutReconcileAfterAsyncStart(),
      'test_allowsSkillAsyncStartThenReconcile': (t) => t._allowsSkillAsyncStartThenReconcile(),
      'test_allowsOrdinaryDestructiveTelemetry': (t) => t._allowsOrdinaryDestructiveTelemetry(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
}
