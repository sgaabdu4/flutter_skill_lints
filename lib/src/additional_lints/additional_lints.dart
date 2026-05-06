/// Additional analyzer diagnostics used by `flutter_skill_lints`.
///
/// These rules, fixes, and assists preserve their diagnostic IDs so existing
/// analyzer configuration can keep using the same rule names through the
/// `flutter_skill_lints` plugin.
library;

import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';
// Assists
import 'package:flutter_skill_lints/src/additional_lints/assists/convert_iterable_map_to_collection_for.dart';
import 'package:flutter_skill_lints/src/additional_lints/fixes/add_suffix_fix.dart';
// Fixes
import 'package:flutter_skill_lints/src/additional_lints/fixes/always_remove_listener_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/fixes/avoid_border_all_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/fixes/avoid_cascade_after_if_null_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/fixes/avoid_commented_out_code_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/fixes/avoid_duplicate_cascades_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/fixes/avoid_expanded_as_spacer_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/fixes/avoid_generics_shadowing_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/fixes/avoid_incomplete_copy_with_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/fixes/avoid_incorrect_image_opacity_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/fixes/avoid_map_keys_contains_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/fixes/avoid_notifier_constructors_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/fixes/avoid_only_rethrow_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/fixes/avoid_ref_read_inside_build_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/fixes/avoid_state_constructors_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/fixes/avoid_throw_in_catch_block_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/fixes/avoid_unnecessary_consumer_widgets_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/fixes/avoid_unnecessary_gesture_detector_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/fixes/avoid_unnecessary_hook_widgets_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/fixes/avoid_unnecessary_overrides_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/fixes/avoid_unnecessary_overrides_in_state_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/fixes/avoid_unnecessary_setstate_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/fixes/avoid_unnecessary_stateful_widgets_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/fixes/avoid_wrapping_in_padding_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/fixes/change_widget_name_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/fixes/dispose_fields_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/fixes/dispose_provided_instances_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/fixes/prefer_abstract_final_static_class_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/fixes/prefer_any_or_every_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/fixes/prefer_async_callback_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/fixes/prefer_center_over_align_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/fixes/prefer_compute_over_isolate_run_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/fixes/prefer_const_border_radius_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/fixes/prefer_constrained_box_over_container_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/fixes/prefer_container_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/fixes/prefer_contains_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/fixes/prefer_correct_edge_insets_constructor_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/fixes/prefer_enums_by_name_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/fixes/prefer_expect_later_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/fixes/prefer_explicit_function_type_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/fixes/prefer_for_loop_in_children_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/fixes/prefer_iterable_of_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/fixes/prefer_padding_over_container_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/fixes/prefer_return_await_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/fixes/prefer_simpler_patterns_null_check_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/fixes/prefer_single_setstate_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/fixes/prefer_sized_box_square_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/fixes/prefer_text_rich_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/fixes/prefer_type_over_var_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/fixes/prefer_use_callback_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/fixes/prefer_use_prefix_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/fixes/prefer_void_callback_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/fixes/prefer_wildcard_pattern_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/fixes/proper_super_calls_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/fixes/use_closest_build_context_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/fixes/use_dedicated_media_query_methods_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/fixes/use_existing_variable_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/fixes/use_ref_and_state_synchronously_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/fixes/use_ref_read_synchronously_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/fixes/use_sliver_prefix_fix.dart';
// Rules
import 'package:flutter_skill_lints/src/additional_lints/rules/always_remove_listener.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_accessing_collections_by_constant_index.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_border_all.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_cascade_after_if_null.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_collection_equality_checks.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_collection_methods_with_unrelated_types.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_commented_out_code.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_conditional_hooks.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_constant_conditions.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_contradictory_expressions.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_duplicate_cascades.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_expanded_as_spacer.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_flexible_outside_flex.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_generics_shadowing.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_incomplete_copy_with.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_incorrect_image_opacity.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_map_keys_contains.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_misused_test_matchers.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_mounted_in_setstate.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_notifier_constructors.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_only_rethrow.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_public_notifier_properties.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_ref_inside_state_dispose.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_ref_read_inside_build.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_returning_widgets.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_shrink_wrap_in_lists.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_single_child_in_multi_child_widgets.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_state_constructors.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_throw_in_catch_block.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_unassigned_stream_subscriptions.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_unnecessary_consumer_widgets.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_unnecessary_gesture_detector.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_unnecessary_hook_widgets.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_unnecessary_overrides.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_unnecessary_overrides_in_state.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_unnecessary_setstate.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_unnecessary_stateful_widgets.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_wrapping_in_padding.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/dispose_fields.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/dispose_provided_instances.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_abstract_final_static_class.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_align_over_container.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_any_or_every.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_async_callback.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_center_over_align.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_compute_over_isolate_run.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_const_border_radius.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_constrained_box_over_container.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_container.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_contains.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_correct_edge_insets_constructor.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_enums_by_name.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_expect_later.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_explicit_function_type.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_for_loop_in_children.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_iterable_of.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_padding_over_container.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_return_await.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_simpler_patterns_null_check.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_single_setstate.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_single_widget_per_file.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_sized_box_square.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_spacing.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_test_matchers.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_text_rich.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_transform_over_container.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_type_over_var.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_use_callback.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_use_prefix.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_void_callback.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_wildcard_pattern.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/proper_super_calls.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/use_closest_build_context.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/use_dedicated_media_query_methods.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/use_existing_variable.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/use_notifier_suffix.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/use_ref_and_state_synchronously.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/use_ref_read_synchronously.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/use_sliver_prefix.dart';

/// Top-level plugin variable required by analysis_server_plugin.
final plugin = AdditionalLintsPlugin();

/// Additional Dart and Flutter diagnostics for the Flutter skill profile.
class AdditionalLintsPlugin extends Plugin {
  @override
  String get name => 'Flutter Skill Additional Lints';

  @override
  void register(PluginRegistry registry) {
    // Register warning rules (enabled by default)
    registry.registerWarningRule(AlwaysRemoveListener());
    registry.registerWarningRule(AvoidCascadeAfterIfNull());
    registry.registerWarningRule(AvoidCommentedOutCode());
    registry.registerWarningRule(AvoidDuplicateCascades());
    registry.registerWarningRule(AvoidConstantConditions());
    registry.registerWarningRule(AvoidContradictoryExpressions());
    registry.registerWarningRule(AvoidAccessingCollectionsByConstantIndex());
    registry.registerWarningRule(AvoidGenericsShadowing());
    registry.registerWarningRule(AvoidMapKeysContains());
    registry.registerWarningRule(AvoidMisusedTestMatchers());
    registry.registerWarningRule(AvoidOnlyRethrow());
    registry.registerWarningRule(AvoidThrowInCatchBlock());
    registry.registerWarningRule(AvoidUnassignedStreamSubscriptions());
    registry.registerWarningRule(AvoidFlexibleOutsideFlex());
    registry.registerWarningRule(AvoidIncompleteCopyWith());
    registry.registerWarningRule(AvoidIncorrectImageOpacity());
    registry.registerWarningRule(AvoidUnnecessaryGestureDetector());
    registry.registerWarningRule(AvoidUnnecessaryOverrides());
    registry.registerWarningRule(AvoidUnnecessaryOverridesInState());
    registry.registerWarningRule(AvoidUnnecessarySetstate());
    registry.registerWarningRule(AvoidUnnecessaryStatefulWidgets());
    registry.registerWarningRule(AvoidMountedInSetstate());
    registry.registerWarningRule(AvoidCollectionEqualityChecks());
    registry.registerWarningRule(DisposeFields());
    registry.registerWarningRule(DisposeProvidedInstances());
    registry.registerWarningRule(AvoidCollectionMethodsWithUnrelatedTypes());
    registry.registerWarningRule(PreferAbstractFinalStaticClass());
    registry.registerWarningRule(PreferCenterOverAlign());
    registry.registerWarningRule(PreferAlignOverContainer());
    registry.registerWarningRule(PreferExplicitFunctionType());
    registry.registerWarningRule(PreferPaddingOverContainer());
    registry.registerWarningRule(PreferReturnAwait());
    registry.registerWarningRule(PreferSimplerPatternsNullCheck());
    registry.registerWarningRule(PreferWildcardPattern());
    registry.registerWarningRule(PreferTypeOverVar());
    registry.registerWarningRule(PreferAnyOrEvery());
    registry.registerWarningRule(PreferContains());
    registry.registerWarningRule(PreferEnumsByName());
    registry.registerWarningRule(PreferExpectLater());
    registry.registerWarningRule(PreferIterableOf());
    registry.registerWarningRule(AvoidSingleChildInMultiChildWidgets());
    registry.registerWarningRule(AvoidUnnecessaryHookWidgets());
    registry.registerWarningRule(AvoidConditionalHooks());
    registry.registerWarningRule(AvoidUnnecessaryConsumerWidgets());
    registry.registerWarningRule(UseNotifierSuffix());
    registry.registerWarningRule(UseDedicatedMediaQueryMethods());
    registry.registerWarningRule(PreferSingleWidgetPerFile());
    registry.registerWarningRule(PreferSpacing());
    registry.registerWarningRule(PreferTestMatchers());
    registry.registerWarningRule(ProperSuperCalls());
    registry.registerWarningRule(UseClosestBuildContext());
    registry.registerWarningRule(UseExistingVariable());
    registry.registerWarningRule(AvoidBorderAll());
    registry.registerWarningRule(AvoidExpandedAsSpacer());
    registry.registerWarningRule(AvoidReturningWidgets());
    registry.registerWarningRule(AvoidShrinkWrapInLists());
    registry.registerWarningRule(AvoidNotifierConstructors());
    registry.registerWarningRule(AvoidPublicNotifierProperties());
    registry.registerWarningRule(AvoidRefInsideStateDispose());
    registry.registerWarningRule(AvoidRefReadInsideBuild());
    registry.registerWarningRule(AvoidStateConstructors());
    registry.registerWarningRule(PreferAsyncCallback());
    registry.registerWarningRule(PreferComputeOverIsolateRun());
    registry.registerWarningRule(PreferConstBorderRadius());
    registry.registerWarningRule(AvoidWrappingInPadding());
    registry.registerWarningRule(PreferConstrainedBoxOverContainer());
    registry.registerWarningRule(PreferContainer());
    registry.registerWarningRule(PreferCorrectEdgeInsetsConstructor());
    registry.registerWarningRule(PreferForLoopInChildren());
    registry.registerWarningRule(PreferSingleSetstate());
    registry.registerWarningRule(PreferSizedBoxSquare());
    registry.registerWarningRule(PreferTextRich());
    registry.registerWarningRule(PreferTransformOverContainer());
    registry.registerWarningRule(PreferVoidCallback());
    registry.registerWarningRule(UseRefAndStateSynchronously());
    registry.registerWarningRule(UseRefReadSynchronously());
    registry.registerWarningRule(PreferUseCallback());
    registry.registerWarningRule(PreferUsePrefix());
    registry.registerWarningRule(UseSliverPrefix());

    // Register fixes for rules
    registry.registerFixForRule(AlwaysRemoveListener.code, AlwaysRemoveListenerFix.new);
    registry.registerFixForRule(AvoidCascadeAfterIfNull.code, AvoidCascadeAfterIfNullFix.new);
    registry.registerFixForRule(DisposeFields.code, DisposeFieldsFix.new);
    registry.registerFixForRule(DisposeProvidedInstances.code, DisposeProvidedInstancesFix.new);
    registry.registerFixForRule(AvoidCommentedOutCode.code, AvoidCommentedOutCodeFix.new);
    registry.registerFixForRule(AvoidDuplicateCascades.code, AvoidDuplicateCascadesFix.new);
    registry.registerFixForRule(
      PreferAbstractFinalStaticClass.code,
      PreferAbstractFinalStaticClassFix.new,
    );
    registry.registerFixForRule(PreferCenterOverAlign.code, PreferCenterOverAlignFix.new);
    registry.registerFixForRule(PreferAlignOverContainer.code, ChangeWidgetNameFix.alignFix);
    registry.registerFixForRule(PreferExplicitFunctionType.code, PreferExplicitFunctionTypeFix.new);
    registry.registerFixForRule(PreferPaddingOverContainer.code, PreferPaddingOverContainerFix.new);
    registry.registerFixForRule(PreferAnyOrEvery.code, PreferAnyOrEveryFix.new);
    registry.registerFixForRule(PreferContains.code, PreferContainsFix.new);
    registry.registerFixForRule(PreferEnumsByName.code, PreferEnumsByNameFix.new);
    registry.registerFixForRule(PreferExpectLater.code, PreferExpectLaterFix.new);
    registry.registerFixForRule(PreferIterableOf.code, PreferIterableOfFix.new);
    registry.registerFixForRule(PreferReturnAwait.code, PreferReturnAwaitFix.new);
    registry.registerFixForRule(
      PreferSimplerPatternsNullCheck.code,
      PreferSimplerPatternsNullCheckFix.new,
    );
    registry.registerFixForRule(PreferWildcardPattern.code, PreferWildcardPatternFix.new);
    registry.registerFixForRule(PreferTypeOverVar.code, PreferTypeOverVarFix.new);
    registry.registerFixForRule(
      AvoidUnnecessaryHookWidgets.code,
      AvoidUnnecessaryHookWidgetsFix.new,
    );
    registry.registerFixForRule(
      UseDedicatedMediaQueryMethods.code,
      UseDedicatedMediaQueryMethodsFix.new,
    );
    registry.registerFixForRule(UseNotifierSuffix.code, AddSuffixFix.notifierFix);
    registry.registerFixForRule(
      AvoidUnnecessaryConsumerWidgets.code,
      AvoidUnnecessaryConsumerWidgetsFix.new,
    );
    registry.registerFixForRule(AvoidGenericsShadowing.code, AvoidGenericsShadowingFix.new);
    registry.registerFixForRule(AvoidMapKeysContains.code, AvoidMapKeysContainsFix.new);
    registry.registerFixForRule(AvoidOnlyRethrow.code, AvoidOnlyRethrowFix.new);
    registry.registerFixForRule(AvoidThrowInCatchBlock.code, AvoidThrowInCatchBlockFix.new);
    registry.registerFixForRule(AvoidIncompleteCopyWith.code, AvoidIncompleteCopyWithFix.new);
    registry.registerFixForRule(AvoidIncorrectImageOpacity.code, AvoidIncorrectImageOpacityFix.new);
    registry.registerFixForRule(
      AvoidUnnecessaryGestureDetector.code,
      AvoidUnnecessaryGestureDetectorFix.new,
    );
    registry.registerFixForRule(AvoidUnnecessaryOverrides.code, AvoidUnnecessaryOverridesFix.new);
    registry.registerFixForRule(
      AvoidUnnecessaryOverridesInState.code,
      AvoidUnnecessaryOverridesInStateFix.new,
    );
    registry.registerFixForRule(AvoidUnnecessarySetstate.code, AvoidUnnecessarySetstateFix.new);
    registry.registerFixForRule(
      AvoidUnnecessaryStatefulWidgets.code,
      AvoidUnnecessaryStatefulWidgetsFix.new,
    );

    registry.registerFixForRule(ProperSuperCalls.code, ProperSuperCallsFix.new);
    registry.registerFixForRule(UseClosestBuildContext.code, UseClosestBuildContextFix.new);
    registry.registerFixForRule(UseExistingVariable.code, UseExistingVariableFix.new);
    registry.registerFixForRule(AvoidBorderAll.code, AvoidBorderAllFix.new);
    registry.registerFixForRule(AvoidExpandedAsSpacer.code, AvoidExpandedAsSpacerFix.new);
    registry.registerFixForRule(AvoidNotifierConstructors.code, AvoidNotifierConstructorsFix.new);
    registry.registerFixForRule(AvoidRefReadInsideBuild.code, AvoidRefReadInsideBuildFix.new);
    registry.registerFixForRule(AvoidStateConstructors.code, AvoidStateConstructorsFix.new);
    registry.registerFixForRule(PreferAsyncCallback.code, PreferAsyncCallbackFix.new);
    registry.registerFixForRule(
      PreferComputeOverIsolateRun.code,
      PreferComputeOverIsolateRunFix.new,
    );
    registry.registerFixForRule(PreferConstBorderRadius.code, PreferConstBorderRadiusFix.new);
    registry.registerFixForRule(
      PreferConstrainedBoxOverContainer.code,
      PreferConstrainedBoxOverContainerFix.new,
    );
    registry.registerFixForRule(AvoidWrappingInPadding.code, AvoidWrappingInPaddingFix.new);
    registry.registerFixForRule(PreferContainer.code, PreferContainerFix.new);
    registry.registerFixForRule(
      PreferCorrectEdgeInsetsConstructor.code,
      PreferCorrectEdgeInsetsConstructorFix.new,
    );
    registry.registerFixForRule(PreferForLoopInChildren.code, PreferForLoopInChildrenFix.new);
    registry.registerFixForRule(PreferSingleSetstate.code, PreferSingleSetstateFix.new);
    registry.registerFixForRule(PreferSizedBoxSquare.code, PreferSizedBoxSquareFix.new);
    registry.registerFixForRule(PreferTextRich.code, PreferTextRichFix.new);
    registry.registerFixForRule(
      PreferTransformOverContainer.code,
      ChangeWidgetNameFix.transformFix,
    );
    registry.registerFixForRule(PreferVoidCallback.code, PreferVoidCallbackFix.new);
    registry.registerFixForRule(
      UseRefAndStateSynchronously.code,
      UseRefAndStateSynchronouslyFix.new,
    );
    registry.registerFixForRule(UseRefReadSynchronously.code, UseRefReadSynchronouslyFix.new);
    registry.registerFixForRule(PreferUseCallback.code, PreferUseCallbackFix.new);
    registry.registerFixForRule(PreferUsePrefix.code, PreferUsePrefixFix.new);
    registry.registerFixForRule(UseSliverPrefix.code, UseSliverPrefixFix.new);
    // Register assists
    registry.registerAssist(ConvertIterableMapToCollectionFor.new);
  }
}
