part of '../flutter_skill_rules_test.dart';

void _defineFlutterSkillRulesPart02Tests() {
  analysisRuleSuite<UseRefMountedAfterAwaitTest>(
    'UseRefMountedAfterAwaitTest',
    UseRefMountedAfterAwaitTest.new,
    {
      'test_reportsRefAfterAwait': (t) => t._reportsRefAfterAwait(),
      'test_allowsGuardedRefAfterAwait': (t) => t._allowsGuardedRefAfterAwait(),
      'test_allowsCompoundMountedAndRevisionGuard': (t) =>
          t._allowsCompoundMountedAndRevisionGuard(),
      'test_shadowedDirectMountedGuardStillReports': (t) =>
          t._shadowedDirectMountedGuardStillReports(),
      'test_impureSuffixCanInvalidateMountedGuard': (t) =>
          t._impureSuffixCanInvalidateMountedGuard(),
      'test_lazyLocalSuffixCannotInvalidateMountedGuard': (t) =>
          t._lazyLocalSuffixCannotInvalidateMountedGuard(),
      'test_lazyStaticFieldSuffixCannotInvalidateMountedGuard': (t) =>
          t._lazyStaticFieldSuffixCannotInvalidateMountedGuard(),
      'test_overriddenFieldSuffixCannotInvalidateMountedGuard': (t) =>
          t._overriddenFieldSuffixCannotInvalidateMountedGuard(),
      'test_awaitInSurvivingElseRequiresFreshGuard': (t) =>
          t._awaitInSurvivingElseRequiresFreshGuard(),
      'test_incompleteMountedGuardStillReports': (t) => t._incompleteMountedGuardStillReports(),
      'test_mountedReturnBranchCannotUseStateBeforeReturn': (t) =>
          t._mountedReturnBranchCannotUseStateBeforeReturn(),
      'test_conjunctiveMountedGuardStillReports': (t) => t._conjunctiveMountedGuardStillReports(),
      'test_allowsResolvedPrivateMountedHelper': (t) => t._allowsResolvedPrivateMountedHelper(),
      'test_revisionOnlyHelperStillReports': (t) => t._revisionOnlyHelperStillReports(),
      'test_mixinOverriddenPrivateHelperStillReports': (t) =>
          t._mixinOverriddenPrivateHelperStillReports(),
      'test_helperCannotTrustGettersOverloadsOrShadowedRef': (t) =>
          t._helperCannotTrustGettersOverloadsOrShadowedRef(),
      'test_helperCannotTrustOverriddenRefGetter': (t) => t._helperCannotTrustOverriddenRefGetter(),
      'test_allowsSkillMountedGuardExamples': (t) => t._allowsSkillMountedGuardExamples(),
      'test_reportsNestedAccessAfterAwait': (t) => t._reportsNestedAccessAfterAwait(),
      'test_reportsInlineLoopAndClosureAwaits': (t) => t._reportsInlineLoopAndClosureAwaits(),
    },
  );
  analysisRuleSuite<AvoidRunZonedGuardedTest>(
    'AvoidRunZonedGuardedTest',
    AvoidRunZonedGuardedTest.new,
    {
      'test_reportsDirectRunZonedGuardedCall': (t) => t._reportsDirectRunZonedGuardedCall(),
      'test_ignoresUserMethodWithSameName': (t) => t._ignoresUserMethodWithSameName(),
    },
  );
  analysisRuleSuite<AvoidSilentRepositoryNullReturnTest>(
    'AvoidSilentRepositoryNullReturnTest',
    AvoidSilentRepositoryNullReturnTest.new,
    {
      'test_reportsNullRepositoryReturn': (t) => t._reportsNullRepositoryReturn(),
      'test_allowsEnsureBeforeNullCheck': (t) => t._allowsEnsureBeforeNullCheck(),
    },
  );
  analysisRuleSuite<AvoidSyncNotifierStateReadTest>(
    'AvoidSyncNotifierStateReadTest',
    AvoidSyncNotifierStateReadTest.new,
    {
      'test_reportsStateReadInSyncBuild': (t) => t._reportsStateReadInSyncBuild(),
      'test_reportsPostfixIncrementOfStateInSyncBuild': (t) =>
          t._reportsPostfixIncrementOfStateInSyncBuild(),
      'test_reportsPrefixIncrementOfStateInSyncBuild': (t) =>
          t._reportsPrefixIncrementOfStateInSyncBuild(),
      'test_reportsThisStateIncrementInSyncBuild': (t) => t._reportsThisStateIncrementInSyncBuild(),
      'test_reportsCompoundAssignmentOfStateInSyncBuild': (t) =>
          t._reportsCompoundAssignmentOfStateInSyncBuild(),
      'test_reportsCascadeAndSuperStateReadsInSyncBuild': (t) =>
          t._reportsCascadeAndSuperStateReadsInSyncBuild(),
      'test_allowsPlainWriteOfStateInSyncBuild': (t) => t._allowsPlainWriteOfStateInSyncBuild(),
      'test_reportsLoadAndStateReadInsideMicrotask': (t) =>
          t._reportsLoadAndStateReadInsideMicrotask(),
      'test_allowsLocalVariableNamedStateInsideMicrotask': (t) =>
          t._allowsLocalVariableNamedStateInsideMicrotask(),
      'test_allowsStateOfAnotherObjectInsideMicrotask': (t) =>
          t._allowsStateOfAnotherObjectInsideMicrotask(),
      'test_reportsLoadInsideShorthandMicrotaskClosure': (t) =>
          t._reportsLoadInsideShorthandMicrotaskClosure(),
      'test_reportsLoadTearOffPassedToMicrotask': (t) => t._reportsLoadTearOffPassedToMicrotask(),
      'test_reportsLoadTearOffPassedToShorthandMicrotask': (t) =>
          t._reportsLoadTearOffPassedToShorthandMicrotask(),
      'test_reportsHelperThatReadsStateTransitively': (t) =>
          t._reportsHelperThatReadsStateTransitively(),
      'test_allowsHelpersThatOnlyWriteOrReadAfterAwait': (t) =>
          t._allowsHelpersThatOnlyWriteOrReadAfterAwait(),
      'test_severityIsError': (t) => t._severityIsError(),
    },
  );
  analysisRuleSuite<UseUnawaitedForFireAndForgetFuturesTest>(
    'UseUnawaitedForFireAndForgetFuturesTest',
    UseUnawaitedForFireAndForgetFuturesTest.new,
    {
      'test_reportsFutureDroppedFromVoidCallback': (t) => t._reportsFutureDroppedFromVoidCallback(),
      'test_reportsFutureDroppedFromNullableNamedVoidCallback': (t) =>
          t._reportsFutureDroppedFromNullableNamedVoidCallback(),
      'test_allowsFutureFromNamedFutureCallback': (t) => t._allowsFutureFromNamedFutureCallback(),
      'test_allowsUnawaitedFutureFromVoidCallback': (t) =>
          t._allowsUnawaitedFutureFromVoidCallback(),
      'test_allowsAwaitedFutureFromAsyncCallback': (t) => t._allowsAwaitedFutureFromAsyncCallback(),
    },
  );
}
