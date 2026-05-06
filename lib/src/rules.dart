import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/rules/avoid_dynamic_except_json_maps.dart';
import 'package:flutter_skill_lints/src/rules/avoid_legacy_riverpod_apis.dart';
import 'package:flutter_skill_lints/src/rules/avoid_null_bang.dart';
import 'package:flutter_skill_lints/src/rules/avoid_route_param_throw_in_build.dart';
import 'package:flutter_skill_lints/src/rules/avoid_showcase_key_filtering.dart';
import 'package:flutter_skill_lints/src/rules/avoid_shrink_wrap.dart';
import 'package:flutter_skill_lints/src/rules/avoid_silent_repository_null_return.dart';
import 'package:flutter_skill_lints/src/rules/avoid_sync_notifier_state_read.dart';
import 'package:flutter_skill_lints/src/rules/avoid_widget_build_helpers.dart';
import 'package:flutter_skill_lints/src/rules/flutter_skill_project_config.dart';
import 'package:flutter_skill_lints/src/rules/flutter_skill_scanner_compat.dart';
import 'package:flutter_skill_lints/src/rules/guard_context_pop.dart';
import 'package:flutter_skill_lints/src/rules/use_context_mounted_after_await.dart';
import 'package:flutter_skill_lints/src/rules/use_ref_invalidate.dart';
import 'package:flutter_skill_lints/src/rules/use_ref_mounted_after_await.dart';
import 'package:flutter_skill_lints/src/rules/use_sealed_freezed_classes.dart';

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
  AvoidRouteParamThrowInBuild(),
  AvoidShowcaseKeyFiltering(),
  AvoidSilentRepositoryNullReturn(),
  AvoidSyncNotifierStateRead(),
  FlutterSkillProjectConfig(),
  FlutterSkillScannerCompat(),
];
