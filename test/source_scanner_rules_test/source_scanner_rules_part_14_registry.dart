part of '../source_scanner_rules_test.dart';

void _defineSourceScannerRulesPart14Tests() {
  analysisRuleSuite<DialogWidgetSubscribesToMutableProviderTest>(
    'DialogWidgetSubscribesToMutableProviderTest',
    DialogWidgetSubscribesToMutableProviderTest.new,
    {
      'test_reportsMultilineWatchFromSkillNeverExample': (t) =>
          t._reportsMultilineWatchFromSkillNeverExample(),
      'test_severityIsError': (t) => t._severityIsError(),
      'test_allowsNonDialogClass': (t) => t._allowsNonDialogClass(),
      'test_allowsDialogWithSnapshotPattern': (t) => t._allowsDialogWithSnapshotPattern(),
      'test_reportsConsumerStateSheetFromPath': (t) => t._reportsConsumerStateSheetFromPath(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
  analysisRuleSuite<ModalHighFrequencyWatchNotLeafTest>(
    'ModalHighFrequencyWatchNotLeafTest',
    ModalHighFrequencyWatchNotLeafTest.new,
    {
      'test_reportsMultilineSelect': (t) => t._reportsMultilineSelect(),
      'test_allowsLeafNonModalClass': (t) => t._allowsLeafNonModalClass(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
  analysisRuleSuite<DialogButtonPopThenStateMutationTest>(
    'DialogButtonPopThenStateMutationTest',
    DialogButtonPopThenStateMutationTest.new,
    {
      'test_allowsPopWithResultNoFollowUp': (t) => t._allowsPopWithResultNoFollowUp(),
      'test_allowsPostPopInNonDialogClass': (t) => t._allowsPostPopInNonDialogClass(),
      'test_reportsSecondPopAfterRootNavigatorPop': (t) =>
          t._reportsSecondPopAfterRootNavigatorPop(),
      'test_reportsTypedRoutePushAfterSheetPop': (t) => t._reportsTypedRoutePushAfterSheetPop(),
      'test_allowsSeparateButtonPopsWithResults': (t) => t._allowsSeparateButtonPopsWithResults(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
  analysisRuleSuite<SelectReturnsUnstableRecordIdentityTest>(
    'SelectReturnsUnstableRecordIdentityTest',
    SelectReturnsUnstableRecordIdentityTest.new,
    {
      'test_reportsMultilineSelectFromSkillNeverExample': (t) =>
          t._reportsMultilineSelectFromSkillNeverExample(),
      'test_resolvedGettersDecideRecordFieldIdentity': (t) =>
          t._resolvedGettersDecideRecordFieldIdentity(),
      'test_severityIsError': (t) => t._severityIsError(),
      'test_allowsPrimitiveSelect': (t) => t._allowsPrimitiveSelect(),
      'test_allowsRecordOfStableFields': (t) => t._allowsRecordOfStableFields(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
  analysisRuleSuite<BuildMethodAssignsToFieldTest>(
    'BuildMethodAssignsToFieldTest',
    BuildMethodAssignsToFieldTest.new,
    {
      'test_allowsLocalFinal': (t) => t._allowsLocalFinal(),
      'test_allowsAssignmentOutsideBuild': (t) => t._allowsAssignmentOutsideBuild(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
  analysisRuleSuite<BuildCallsMutatingInstanceMethodTest>(
    'BuildCallsMutatingInstanceMethodTest',
    BuildCallsMutatingInstanceMethodTest.new,
    {
      'test_allowsArrowEventCallback': (t) => t._allowsArrowEventCallback(),
      'test_reportsImmediateArrowInvocation': (t) => t._reportsImmediateArrowInvocation(),
      'test_reportsImmediateBlockInvocation': (t) => t._reportsImmediateBlockInvocation(),
      'test_reportsImmediateCallAfterCallbackOnSameLine': (t) =>
          t._reportsImmediateCallAfterCallbackOnSameLine(),
      'test_reportsImmediateCallInvocation': (t) => t._reportsImmediateCallInvocation(),
      'test_allowsPureHelperFromBuild': (t) => t._allowsPureHelperFromBuild(),
      'test_reportsControllerPropertyMutation': (t) => t._reportsControllerPropertyMutation(),
      'test_allowsMutatingHelperInsideMultilineCallback': (t) =>
          t._allowsMutatingHelperInsideMultilineCallback(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
  analysisRuleSuite<WidgetCallsNotifierTeardownAfterAwaitTest>(
    'WidgetCallsNotifierTeardownAfterAwaitTest',
    WidgetCallsNotifierTeardownAfterAwaitTest.new,
    {
      'test_allowsResetWithoutAwait': (t) => t._allowsResetWithoutAwait(),
      'test_reportsGoNavigationChainedOffAwaitedMutation': (t) =>
          t._reportsGoNavigationChainedOffAwaitedMutation(),
      'test_allowsNavigationNotChainedOffNotifierMutation': (t) =>
          t._allowsNavigationNotChainedOffNotifierMutation(),
      'test_allowsResetInsideNotifier': (t) => t._allowsResetInsideNotifier(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
  analysisRuleSuite<PopScopeBypassUsesGoNotPopTest>(
    'PopScopeBypassUsesGoNotPopTest',
    PopScopeBypassUsesGoNotPopTest.new,
    {
      'test_allowsTypedRouteGo': (t) => t._allowsTypedRouteGo(),
      'test_allowsPopWithFallbackWithoutPrecedingModal': (t) =>
          t._allowsPopWithFallbackWithoutPrecedingModal(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
  analysisRuleSuite<ModalHelperRequiresRouteSettingsTest>(
    'ModalHelperRequiresRouteSettingsTest',
    ModalHelperRequiresRouteSettingsTest.new,
    {
      'test_allowsWithRouteSettings': (t) => t._allowsWithRouteSettings(),
      'test_allowsSheetWithRouteSettings': (t) => t._allowsSheetWithRouteSettings(),
      'test_allowsSkillShowAppSheetHelperAndCallers': (t) =>
          t._allowsSkillShowAppSheetHelperAndCallers(),
      'test_allowsSkillModalContextExtension': (t) => t._allowsSkillModalContextExtension(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
}
