part of '../persistence_crash_source_rules_test.dart';

void _definePersistenceCrashSourceRulesPart01Tests() {
  analysisRuleSuite<FireAndForgetMissingCatchTest>(
    'FireAndForgetMissingCatchTest',
    FireAndForgetMissingCatchTest.new,
    {
      'test_reportsInlineAsyncMissingCatch': (t) => t._reportsInlineAsyncMissingCatch(),
      'test_inlineAsyncWithCatch_noDiagnostic': (t) => t._inlineAsyncWithCatchNoDiagnostic(),
      'test_calleeThatCatchesInternally_noDiagnostic': (t) =>
          t._calleeThatCatchesInternallyNoDiagnostic(),
      'test_reportsCalleeWithoutCatch': (t) => t._reportsCalleeWithoutCatch(),
      'test_resolvesCalleesInImportedLibraries': (t) => t._resolvesCalleesInImportedLibraries(),
      'test_emptyCalleeBody_noDiagnostic': (t) => t._emptyCalleeBodyNoDiagnostic(),
      'test_mutationRunCallee_noDiagnostic': (t) => t._mutationRunCalleeNoDiagnostic(),
      'test_reportsLocalMutationLookalike': (t) => t._reportsLocalMutationLookalike(),
      'test_navigationCallee_noDiagnostic': (t) => t._navigationCalleeNoDiagnostic(),
      'test_maybePopCallee_noDiagnostic': (t) => t._maybePopCalleeNoDiagnostic(),
      'test_reportsNavigationThenUncaughtRemoteWork': (t) =>
          t._reportsNavigationThenUncaughtRemoteWork(),
      'test_calleeDelegatingToCatchingMethod_noDiagnostic': (t) =>
          t._calleeDelegatingToCatchingMethodNoDiagnostic(),
      'test_importedNotifierDelegatingToCatchingMethod_noDiagnostic': (t) =>
          t._importedNotifierDelegatingToCatchingMethodNoDiagnostic(),
      'test_reportsImportedNotifierDelegatingToUncaughtMethod': (t) =>
          t._reportsImportedNotifierDelegatingToUncaughtMethod(),
      'test_reportsCalleeThrowingBeforeCaughtWork': (t) =>
          t._reportsCalleeThrowingBeforeCaughtWork(),
      'test_guardedHelper_noDiagnostic': (t) => t._guardedHelperNoDiagnostic(),
    },
  );
  analysisRuleSuite<HiveDuplicateFieldIdTest>(
    'HiveDuplicateFieldIdTest',
    HiveDuplicateFieldIdTest.new,
    {
      'test_reportsDuplicateField': (t) => t._reportsDuplicateField(),
      'test_allowsSameIndexesInSeparateHiveTypes': (t) => t._allowsSameIndexesInSeparateHiveTypes(),
    },
  );
  analysisRuleSuite<HiveDuplicateTypeIdTest>(
    'HiveDuplicateTypeIdTest',
    HiveDuplicateTypeIdTest.new,
    {
      'test_reportsDuplicateTypeId': (t) => t._reportsDuplicateTypeId(),
      'test_reportsDuplicateWithImportedHiveType': (t) => t._reportsDuplicateWithImportedHiveType(),
      'test_reportsDuplicatesJoinedThroughGeneratedRegistrar': (t) =>
          t._reportsDuplicatesJoinedThroughGeneratedRegistrar(),
      'test_reportsDuplicatesJoinedByDirectImports': (t) =>
          t._reportsDuplicatesJoinedByDirectImports(),
      'test_leavesDeeperJoinToTheImportedLibrary': (t) => t._leavesDeeperJoinToTheImportedLibrary(),
      'test_allowsDistinctTypeIdsAcrossFiles': (t) => t._allowsDistinctTypeIdsAcrossFiles(),
    },
  );
  analysisRuleSuite<HiveReservedTypeIdsMissingTest>(
    'HiveReservedTypeIdsMissingTest',
    HiveReservedTypeIdsMissingTest.new,
    {
      'test_reportsMissingReservedTypeIds': (t) => t._reportsMissingReservedTypeIds(),
      'test_reportsReservationThatOmitsTheHiveTypeId': (t) =>
          t._reportsReservationThatOmitsTheHiveTypeId(),
      'test_reservedTypeIdsPresent_noDiagnostic': (t) => t._reservedTypeIdsPresentNoDiagnostic(),
      'test_reportsHiveTypeInAnotherFileOfTheRegistrationScope': (t) =>
          t._reportsHiveTypeInAnotherFileOfTheRegistrationScope(),
      'test_allowsReservedHiveTypeInAnotherFile': (t) => t._allowsReservedHiveTypeInAnotherFile(),
    },
  );
  analysisRuleSuite<HiveTestCloseMissingTest>(
    'HiveTestCloseMissingTest',
    HiveTestCloseMissingTest.new,
    {
      'test_reportsMissingCloseInTest': (t) => t._reportsMissingCloseInTest(),
      'test_closePresent_noDiagnostic': (t) => t._closePresentNoDiagnostic(),
    },
  );
  analysisRuleSuite<HiveTypeOnFreezedClassTest>(
    'HiveTypeOnFreezedClassTest',
    HiveTypeOnFreezedClassTest.new,
    {
      'test_reportsHiveTypeOnFreezedClass': (t) => t._reportsHiveTypeOnFreezedClass(),
      'test_allowsHiveTypeOnPlainClass': (t) => t._allowsHiveTypeOnPlainClass(),
    },
  );
  analysisRuleSuite<HiveAdapterSpecDomainTypeTest>(
    'HiveAdapterSpecDomainTypeTest',
    HiveAdapterSpecDomainTypeTest.new,
    {
      'test_reportsDomainEntitySpec': (t) => t._reportsDomainEntitySpec(),
      'test_allowsDataModelSpec': (t) => t._allowsDataModelSpec(),
    },
  );
  analysisRuleSuite<NotifierHiveAccessTest>('NotifierHiveAccessTest', NotifierHiveAccessTest.new, {
    'test_reportsHiveInNotifier': (t) => t._reportsHiveInNotifier(),
    'test_allowsRepositoryNotifierAndHiveDatasource': (t) =>
        t._allowsRepositoryNotifierAndHiveDatasource(),
  });
}
