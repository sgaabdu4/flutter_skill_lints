import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/rules/architecture_extended_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/architecture_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/avoid_dynamic_except_json_maps.dart';
import 'package:flutter_skill_lints/src/rules/avoid_legacy_riverpod_apis.dart';
import 'package:flutter_skill_lints/src/rules/avoid_null_bang.dart';
import 'package:flutter_skill_lints/src/rules/avoid_route_param_throw_in_build.dart';
import 'package:flutter_skill_lints/src/rules/avoid_showcase_key_filtering.dart';
import 'package:flutter_skill_lints/src/rules/avoid_shrink_wrap.dart';
import 'package:flutter_skill_lints/src/rules/avoid_silent_repository_null_return.dart';
import 'package:flutter_skill_lints/src/rules/avoid_sync_notifier_state_read.dart';
import 'package:flutter_skill_lints/src/rules/avoid_widget_build_helpers.dart';
import 'package:flutter_skill_lints/src/rules/data_crash_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/flutter_optimization_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/flutter_skill_project_config.dart';
import 'package:flutter_skill_lints/src/rules/freezed_extended_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/freezed_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/guard_context_pop.dart';
import 'package:flutter_skill_lints/src/rules/notifier_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/persistence_crash_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/riverpod_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/router_extended_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/router_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/services_extended_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/services_mixins_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/showcase_extended_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/showcase_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/state_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/test_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/ui_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/use_context_mounted_after_await.dart';
import 'package:flutter_skill_lints/src/rules/use_ref_invalidate.dart';
import 'package:flutter_skill_lints/src/rules/use_ref_mounted_after_await.dart';
import 'package:flutter_skill_lints/src/rules/use_sealed_freezed_classes.dart';
import 'package:flutter_skill_lints/src/rules/use_unawaited_for_fire_and_forget_futures.dart';

final List<AbstractAnalysisRule> flutterSkillRules = [
  UseRefMountedAfterAwait(),
  UseContextMountedAfterAwait(),
  AvoidLegacyRiverpodApis(),
  AvoidDynamicExceptJsonMaps(),
  AvoidNullBang(),
  AvoidWidgetBuildHelpers(),
  AvoidShrinkWrap(),
  GuardContextPop(),
  UseRefInvalidate(),
  UseSealedFreezedClasses(),
  UseUnawaitedForFireAndForgetFutures(),
  AvoidRouteParamThrowInBuild(),
  AvoidShowcaseKeyFiltering(),
  AvoidSilentRepositoryNullReturn(),
  AvoidSyncNotifierStateRead(),
  FlutterSkillProjectConfig(),
  ...riverpodSourceRules,
  ...freezedSourceRules,
  ...freezedExtendedSourceRules,
  ...architectureSourceRules,
  ...architectureExtendedSourceRules,
  ...uiSourceRules,
  ...flutterOptimizationSourceRules,
  ...stateSourceRules,
  ...routerSourceRules,
  ...routerExtendedSourceRules,
  ...showcaseSourceRules,
  ...showcaseExtendedSourceRules,
  ...notifierSourceRules,
  ...servicesMixinsSourceRules,
  ...servicesExtendedSourceRules,
  ...dataCrashSourceRules,
  ...persistenceCrashSourceRules,
  ...testSourceRules,
];
