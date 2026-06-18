// ignore_for_file: non_constant_identifier_names

import 'dart:math' as math;

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
// ignore: implementation_imports
import 'package:analyzer_testing/src/analysis_rule/pub_package_resolution.dart'
    show ExpectedDiagnostic;
import 'package:flutter_skill_lints/src/rules/architecture_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/data_crash_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/dialog_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/freezed_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/hive_persistence_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/notifier_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/riverpod_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/router_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/runtime_bug_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/services_extended_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/services_mixins_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/source_scanner_rule.dart';
import 'package:flutter_skill_lints/src/rules/state_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/test_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/ui_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/value_object_source_rules.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
part 'source_scanner_rules_test/source_scanner_rules_part_01.dart';
part 'source_scanner_rules_test/source_scanner_rules_part_02.dart';
part 'source_scanner_rules_test/source_scanner_rules_part_03.dart';
part 'source_scanner_rules_test/source_scanner_rules_part_04.dart';
part 'source_scanner_rules_test/source_scanner_rules_part_05.dart';
part 'source_scanner_rules_test/source_scanner_rules_part_06.dart';
part 'source_scanner_rules_test/source_scanner_rules_part_07.dart';
part 'source_scanner_rules_test/source_scanner_rules_part_08.dart';
part 'source_scanner_rules_test/source_scanner_rules_part_09.dart';
part 'source_scanner_rules_test/source_scanner_rules_part_10.dart';
part 'source_scanner_rules_test/source_scanner_rules_part_11.dart';
part 'source_scanner_rules_test/source_scanner_rules_part_12.dart';
part 'source_scanner_rules_test/source_scanner_rules_part_13.dart';
part 'source_scanner_rules_test/source_scanner_rules_part_14.dart';
part 'source_scanner_rules_test/source_scanner_rules_part_15.dart';
part 'source_scanner_rules_test/source_scanner_rules_part_16.dart';
part 'source_scanner_rules_test/source_scanner_rules_part_17.dart';
part 'source_scanner_rules_test/source_scanner_rules_part_18.dart';
part 'source_scanner_rules_test/source_scanner_rules_part_19.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RiverpodReadInitStateTest);
    defineReflectiveTests(RiverpodServiceLocatorTest);
    defineReflectiveTests(RiverpodManualProviderTest);
    defineReflectiveTests(RiverpodNotifierOverrideWithValueTest);
    defineReflectiveTests(RiverpodConsumerStateDerivedCacheTest);
    defineReflectiveTests(RiverpodWidgetProviderArgWrapperTest);
    defineReflectiveTests(RiverpodConsumerStateProviderSubscriptionTest);
    defineReflectiveTests(RiverpodListenManualForbiddenTest);
    defineReflectiveTests(RiverpodEventCounterSignalForbiddenTest);
    defineReflectiveTests(RiverpodWatchNoSelectTest);
    defineReflectiveTests(RiverpodSelectArrowSyntaxTest);
    defineReflectiveTests(RiverpodSelectIdentityForbiddenTest);
    defineReflectiveTests(RiverpodMutationExperimentalWarningTest);
    defineReflectiveTests(RiverpodAutoDisposeKeepAliveDependenciesTest);
    defineReflectiveTests(RiverpodFeatureNotifierKeepaliveTest);
    defineReflectiveTests(RiverpodKeepaliveFamilyTest);
    defineReflectiveTests(DartStaticNamespaceTest);
    defineReflectiveTests(FreezedPerClassExplicitToJsonTest);
    defineReflectiveTests(FreezedToJsonWithFromJsonTest);
    defineReflectiveTests(FreezedLegacyWhenMapTest);
    defineReflectiveTests(FreezedRequiredValueClassTest);
    defineReflectiveTests(UseFreezedInsteadOfImmutableTest);
    defineReflectiveTests(FreezedOneClassPerFileTest);
    defineReflectiveTests(ArchDomainImportTest);
    defineReflectiveTests(ArchDomainSerializationTest);
    defineReflectiveTests(ArchInterfaceContractTest);
    defineReflectiveTests(ArchRepositoryGeneratedExtendsTest);
    defineReflectiveTests(ArchConcreteDependencyTest);
    defineReflectiveTests(ArchDatasourceTryCatchTest);
    defineReflectiveTests(ArchWidgetPathTest);
    defineReflectiveTests(AtomicProviderAccessTest);
    defineReflectiveTests(TypedIdRawIdTest);
    defineReflectiveTests(RecordsMapReturnTest);
    defineReflectiveTests(ObjectMapCastTest);
    defineReflectiveTests(StyleRawTokenTest);
    defineReflectiveTests(StyleRawTextStyleTest);
    defineReflectiveTests(StringsHardcodedTest);
    defineReflectiveTests(L10nContextDirectAccessTest);
    defineReflectiveTests(UiSnackbarBoundaryTest);
    defineReflectiveTests(WidgetInfraDependencyBoundaryTest);
    defineReflectiveTests(WidgetTopLevelFunctionBoundaryTest);
    defineReflectiveTests(WidgetActionsNamespaceBoundaryTest);
    defineReflectiveTests(WidgetTryCatchBoundaryTest);
    defineReflectiveTests(WidgetAwaitsNotifierResultTest);
    defineReflectiveTests(WidgetLocalMutationFlagTest);
    defineReflectiveTests(WidgetDerivedCollectionLogicTest);
    defineReflectiveTests(A11yTextScaleClampTest);
    defineReflectiveTests(AppShellBootstrapSideEffectsTest);
    defineReflectiveTests(DateTimeNowRequiresTimezoneIntentTest);
    defineReflectiveTests(PerfBuildWorkTest);
    defineReflectiveTests(PerfListviewChildrenTest);
    defineReflectiveTests(NullableCollectionTypeTest);
    defineReflectiveTests(StateEmptyStringSentinelTest);
    defineReflectiveTests(StateBoolStringSentinelTest);
    defineReflectiveTests(StateRawResponseTest);
    defineReflectiveTests(StateRawErrorToStringTest);
    defineReflectiveTests(StateFreezedNullableErrorTest);
    defineReflectiveTests(StateBroadInvalidationTest);
    defineReflectiveTests(AsyncContextMountedStyleTest);
    defineReflectiveTests(BareStateMountedForbiddenTest);
    defineReflectiveTests(RouterStringNavTest);
    defineReflectiveTests(RouterPopThenPushTest);
    defineReflectiveTests(PopFallbackHelperMustCheckNavigatorStackTest);
    defineReflectiveTests(RouterRedirectWatchTest);
    defineReflectiveTests(RouterRedirectLoadingBounceTest);
    defineReflectiveTests(RouterComplexExtraTest);
    defineReflectiveTests(RouterGoRouterOfTest);
    defineReflectiveTests(RouterUntypedNavigatorPushTest);
    defineReflectiveTests(RouterContextNavigationExtensionTest);
    defineReflectiveTests(RouterNavigationWrapperApiTest);
    defineReflectiveTests(RouterDirectRouteCallTest);
    defineReflectiveTests(RouterRawRouteDefinitionTest);
    defineReflectiveTests(RouterModalLocalHelpersTest);
    defineReflectiveTests(RouterProviderScopeNavigationReadTest);
    defineReflectiveTests(NotifierLocalDependencyCacheTest);
    defineReflectiveTests(NotifierEnsureDepsTest);
    defineReflectiveTests(NotifierWatchMethodTest);
    defineReflectiveTests(ServiceSingletonTest);
    defineReflectiveTests(ServiceInlineConcreteDependencyTest);
    defineReflectiveTests(HiddenDependencyDefaultParamTest);
    defineReflectiveTests(ServiceProviderWatchDependencyTest);
    defineReflectiveTests(MixinMixinClassTest);
    defineReflectiveTests(MixinNameSuffixTest);
    defineReflectiveTests(MixinMutableStateTest);
    defineReflectiveTests(DataLogRethrowTest);
    defineReflectiveTests(CrashPossiblePiiTest);
    defineReflectiveTests(TestProviderContainerTest);
    defineReflectiveTests(TestUncontrolledScopeTest);
    defineReflectiveTests(TestCreateContainerTest);
    defineReflectiveTests(TestMockConcreteTest);
    defineReflectiveTests(TestPumpAndSettleTest);
    defineReflectiveTests(TestTapAtTest);
    defineReflectiveTests(TestInlineValueKeyTest);
    defineReflectiveTests(TestFirstMatchFinderTest);
    defineReflectiveTests(DomainEmptyStringSentinelTest);
    defineReflectiveTests(VoPublicRawConstructorTest);
    defineReflectiveTests(DomainEntityPrimitiveFactoryTest);
    defineReflectiveTests(DomainCustomCopyWithTest);
    defineReflectiveTests(FreezedDisableMapWhenRequiredTest);
    defineReflectiveTests(HiveFieldNoVoTypeTest);
    defineReflectiveTests(DialogWidgetSubscribesToMutableProviderTest);
    defineReflectiveTests(ModalHighFrequencyWatchNotLeafTest);
    defineReflectiveTests(DialogButtonPopThenStateMutationTest);
    defineReflectiveTests(SelectReturnsUnstableRecordIdentityTest);
    defineReflectiveTests(BuildMethodAssignsToFieldTest);
    defineReflectiveTests(BuildCallsMutatingInstanceMethodTest);
    defineReflectiveTests(WidgetCallsNotifierTeardownAfterAwaitTest);
    defineReflectiveTests(PopScopeBypassUsesGoNotPopTest);
    defineReflectiveTests(ModalHelperRequiresRouteSettingsTest);
    defineReflectiveTests(SyncSaveAllNoDirtyGuardTest);
    defineReflectiveTests(SaveAllFullCollectionAfterSubsetMutationTest);
    defineReflectiveTests(CollectionGetterAllocatesEachAccessTest);
    defineReflectiveTests(ExpandoDerivedCacheForbiddenTest);
    defineReflectiveTests(AdHocIdIndexLookupTest);
    defineReflectiveTests(LinearIdLookupInHotPathTest);
    defineReflectiveTests(NestedLinearLookupByIdTest);
    defineReflectiveTests(AppwriteBlockingFunctionExecutionInClientTest);
    defineReflectiveTests(DestructiveFailureLoggedBeforeReconcileTest);
    defineReflectiveTests(StorageClearPreservesMigrationStateTest);
    defineReflectiveTests(NotifierPersistenceNoDebounceTest);
    defineReflectiveTests(NotifierAsyncInitStaleStateWriteTest);
    defineReflectiveTests(WebViewInitInBuildNoGateTest);
    defineReflectiveTests(ServiceStorageReadNoMemoTest);
    defineReflectiveTests(KeepAliveWatchesUnboundedCollectionTest);
    defineReflectiveTests(DatasourceMissingBatchLoaderTest);
    defineReflectiveTests(NotifierZeroValueSaveNoGuardTest);
    defineReflectiveTests(NotifierParamRequiresValueObjectTest);
    defineReflectiveTests(TextFieldOnChangedNoDebounceTest);
    defineReflectiveTests(SliderOnChangedNoDebounceTest);
    defineReflectiveTests(ScrollListenerNoThrottleTest);
    defineReflectiveTests(UserVisibleDurationTooLongTest);
    defineReflectiveTests(FullCollectionLoadInLoopTest);
    defineReflectiveTests(UnguardedFireAndForgetPlatformCommandTest);
    // Regression suite — alternate TP shapes + edge FP guards.
    defineReflectiveTests(DialogWidgetSubscribesPathBasedTest);
    defineReflectiveTests(DialogWidgetReadOnlyAllowedTest);
    defineReflectiveTests(DialogPopThenStateMutationOfContextVariantTest);
    defineReflectiveTests(SelectUnstableRecordNamedFieldsTest);
    defineReflectiveTests(SelectAllowsStableRecordMapMethodTest);
    defineReflectiveTests(BuildAssignsThisFieldTest);
    defineReflectiveTests(BuildAllowsAssignmentInsideClosureTest);
    defineReflectiveTests(WidgetTeardownAwaitWithGapTest);
    defineReflectiveTests(WidgetTeardownAllowsNonNotifierClearTest);
    defineReflectiveTests(PopScopeBypassPopWithFallbackVariantTest);
    defineReflectiveTests(ModalHelperShowGeneralDialogTest);
    defineReflectiveTests(SyncSaveAllAllowsLengthGuardTest);
    defineReflectiveTests(SyncSaveAllAllowsOuterDirtyGuardTest);
    defineReflectiveTests(NotifierPersistenceDelayedAllowedTest);
    defineReflectiveTests(WebViewVideoPlayerNoGateTest);
    defineReflectiveTests(WebViewAllowsUserOpenedGateTest);
    defineReflectiveTests(KeepAliveWatchesPostsCollectionTest);
    defineReflectiveTests(DatasourceRemoteSixGettersTest);
    defineReflectiveTests(DatasourceAllowsListReturnGettersTest);
    defineReflectiveTests(NotifierZeroValueAmountNoGuardTest);
    defineReflectiveTests(NotifierParamRequiresVoBytesTest);
    defineReflectiveTests(NotifierParamAllowsNonUnitStringTest);
    defineReflectiveTests(TextFieldCupertinoNoDebounceTest);
    defineReflectiveTests(TextFieldAllowsDebouncerReferenceTest);
    defineReflectiveTests(SliderRangeSliderNoDebounceTest);
    defineReflectiveTests(ScrollListenerWidgetPrefixTest);
    defineReflectiveTests(ScrollListenerAllowsDebouncerTest);
    defineReflectiveTests(UserVisibleDurationAllowsSnappyDebounceTest);
    defineReflectiveTests(UserVisibleDurationAllowsRetryBackoffTest);
    defineReflectiveTests(UserVisibleDurationAllowsDismissTimerTest);
    defineReflectiveTests(UserVisibleDurationAllowsSnackBarDurationTest);
    defineReflectiveTests(DebugPrintBlankingMasksMatchesTest);
    defineReflectiveTests(IsTestFileSkipsRuleTest);
    defineReflectiveTests(DialogRuleSkipsTestFileTest);
    defineReflectiveTests(DebugPrintMultilineBlankingTest);
    defineReflectiveTests(DatasourceBoundaryFourGettersAllowedTest);
    defineReflectiveTests(DatasourceBoundaryFiveGettersFiresTest);
  });
}

abstract class _SourceRuleTest extends AnalysisRuleTest {
  List<ScannerRule> get rules;
  String get ruleName;
  String get source;
  String get needle;
  String? get path => null;
  bool get lineStart => false;
  bool get addIgnorePrefix => true;

  @override
  void setUp() {
    rule = rules.singleWhere((rule) => rule.name == ruleName);
    _addFlutterPackage();
    super.setUp();
  }

  Future<void> test_reportsDiagnostic() async {
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);
    final expected = compatLint(analyzedSource, needle, ruleName, lineStart: lineStart);
    final filePath = path;
    if (filePath == null) {
      await assertDiagnostics(analyzedSource, [expected]);
      return;
    }

    newFile(filePath, analyzedSource);
    await assertDiagnosticsInFile(filePath, [expected]);
  }

  Future<void> assertAllows(String source, {String? path, bool addIgnorePrefix = true}) async {
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);
    if (path == null) {
      await assertNoDiagnostics(analyzedSource);
      return;
    }

    newFile(path, analyzedSource);
    await assertNoDiagnosticsInFile(path);
  }

  String _analyzedSource(String source, {required bool addIgnorePrefix}) {
    if (!addIgnorePrefix) return source;
    return '''
// ignore_for_file: extends_non_class, final_not_initialized, implements_non_class, undefined_function, undefined_identifier, undefined_method, unused_import
// ignore_for_file: non_type_as_type_argument, unchecked_use_of_nullable_value, undefined_class, undefined_getter, undefined_setter
$source''';
  }

  ExpectedDiagnostic compatLint(
    String source,
    String needle,
    String name, {
    bool lineStart = false,
  }) {
    var offset = source.indexOf(needle);
    if (offset < 0) {
      throw StateError('Needle not found: $needle');
    }
    if (lineStart) {
      offset = source.lastIndexOf('\n', offset) + 1;
    }

    final lineEnd = source.indexOf('\n', offset);
    final end = lineEnd < 0 ? source.length : lineEnd;
    return lint(offset, math.max(1, end - offset), name: name);
  }

  void _addFlutterPackage() {
    newPackage('flutter').addFile('lib/widgets.dart', r'''
class BuildContext {}
class Widget {}
''');
  }
}
