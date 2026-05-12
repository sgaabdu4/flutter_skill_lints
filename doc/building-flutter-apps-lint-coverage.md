# building-flutter-apps Lint Coverage

Status: 2026-05-11.

This audit covers both plugin surfaces:

- `lib/src/rules/**`: 105 registered `building-flutter-apps` warning rules.
- `lib/src/rules/**`: 112 `building-flutter-apps` diagnostic codes.
- `lib/src/additional_lints/rules/**`: 81 additional diagnostics.
- Total unique diagnostics: 192.

## Full Rule Inventory

`building-flutter-apps` diagnostics in `lib/src/rules/**`:

```text
a11y_text_scale_clamp
arch_concrete_dependency
arch_datasource_try_catch
arch_domain_import
arch_domain_json_annotation
arch_domain_serialization
arch_interface_contract
arch_model_extends_entity
arch_model_missing_to_entity
arch_repository_generated_extends
arch_widget_path
async_context_mounted_style
atomic_provider_access
avoid_dynamic_except_json_maps
avoid_legacy_riverpod_apis
avoid_null_bang
avoid_object_map_cast
avoid_private_widget_classes
avoid_route_param_throw_in_build
avoid_showcase_key_filtering
avoid_shrink_wrap
avoid_silent_repository_null_return
avoid_sync_notifier_state_read
avoid_widget_build_helpers
cfg_analysis_options_canonical
cfg_e2e_entrypoint
cfg_explicit_to_json
cfg_freezed_annotation_ignore
cfg_generated_exclude
cfg_prohibited_lint_plugins
cfg_required_lints
cfg_strict_analysis
crash_direct_firebase_call
crash_init_before_run_app
crash_possible_pii
crash_run_zoned_guarded_legacy
dart_static_namespace
data_log_rethrow
fire_and_forget_missing_catch
fire_forget_in_tests
flutter_animated_builder_child
flutter_clip_save_layer
flutter_intrinsic_layout
flutter_key_created_in_build
flutter_opacity_widget
flutter_save_layer_filter
flutter_unique_or_global_key
flutter_widget_operator_equals
freezed_legacy_when_map
freezed_missing_private_constructor
freezed_per_class_explicit_to_json
freezed_to_json_with_from_json
guard_context_pop
hive_duplicate_field_id
hive_duplicate_type_id
hive_reserved_type_ids_missing
hive_test_close_missing
mixin_mixin_class
mixin_mutable_state
mixin_name_suffix
notifier_ensure_deps
notifier_watch_method
perf_build_work
perf_listview_children
records_map_return
riverpod_auto_dispose_keepalive_dependencies
riverpod_keepalive_family
riverpod_mutation_experimental_warning
riverpod_read_init_state
riverpod_select_arrow_syntax
riverpod_service_locator
riverpod_watch_no_select
router_impure_redirect
router_complex_extra
router_pop_then_push
router_redirect_loading_bounce
router_redirect_watch
router_shell_tab_push
router_string_nav
service_random_per_call
service_singleton
service_static_side_effect
showcase_default_scope
showcase_dispose_on_tap
showcase_get_named_unhandled
showcase_listen_manual_handle
showcase_prev_null_guard
showcase_scope_string_literal
showcase_v4_api
state_broad_invalidation
state_freezed_nullable_error
state_raw_error_to_string
state_raw_response
strings_hardcoded
style_raw_text_style
style_raw_token
test_create_container
test_first_match_finder
test_inline_value_key
test_mock_concrete
test_provider_container
test_pump_and_settle
test_tap_at
test_uncontrolled_scope
typed_id_raw_id
ui_snackbar_boundary
use_context_mounted_after_await
use_ref_invalidate
use_ref_mounted_after_await
use_sealed_freezed_classes
use_unawaited_for_fire_and_forget_futures
```

Additional diagnostics in `lib/src/additional_lints/rules/**`:

```text
always_remove_listener
avoid_accessing_collections_by_constant_index
avoid_border_all
avoid_cascade_after_if_null
avoid_collection_equality_checks
avoid_collection_methods_with_unrelated_types
avoid_commented_out_code
avoid_conditional_hooks
avoid_constant_conditions
avoid_constant_switches
avoid_contradictory_expressions
avoid_duplicate_cascades
avoid_expanded_as_spacer
avoid_flexible_outside_flex
avoid_generics_shadowing
avoid_incomplete_copy_with
avoid_incorrect_image_opacity
avoid_map_keys_contains
avoid_misused_test_matchers
avoid_mounted_check_in_finally
avoid_mounted_in_setstate
avoid_notifier_constructors
avoid_only_rethrow
avoid_ref_read_inside_build
avoid_returning_widgets
avoid_shrink_wrap_in_lists
avoid_single_child_in_multi_child_widgets
avoid_single_field_destructuring
avoid_state_constructors
avoid_throw_in_catch_block
avoid_unassigned_stream_subscriptions
avoid_unnecessary_consumer_widgets
avoid_unnecessary_gesture_detector
avoid_unnecessary_hook_widgets
avoid_unnecessary_overrides
avoid_unnecessary_overrides_in_state
avoid_unnecessary_setstate
avoid_unnecessary_stateful_widgets
avoid_wrapping_in_padding
dispose_fields
dispose_provided_instances
prefer_abstract_final_static_class
prefer_align_over_container
prefer_any_or_every
prefer_async_callback
prefer_center_over_align
prefer_class_destructuring
prefer_compute_over_isolate_run
prefer_const_border_radius
prefer_constrained_box_over_container
prefer_container
prefer_correct_edge_insets_constructor
prefer_enums_by_name
prefer_expect_later
prefer_explicit_function_type
prefer_for_loop_in_children
prefer_iterable_of
prefer_padding_over_container
prefer_return_await
prefer_simpler_patterns_null_check
prefer_single_setstate
prefer_single_widget_per_file
prefer_sized_box_square
prefer_spacing
prefer_test_matchers
prefer_text_rich
prefer_transform_over_container
prefer_type_over_var
prefer_use_callback
prefer_use_prefix
prefer_void_callback
prefer_wildcard_pattern
proper_super_calls
use_closest_build_context
use_dedicated_media_query_methods
use_existing_destructuring
use_existing_variable
use_notifier_suffix
use_ref_and_state_synchronously
use_ref_read_synchronously
use_sliver_prefix
```

## Existing Coverage

Core skill rules already covered before this pass:

- Riverpod/codegen: `avoid_legacy_riverpod_apis`, `riverpod_read_init_state`,
  `riverpod_service_locator`, `riverpod_watch_no_select`,
  `riverpod_select_arrow_syntax`, `riverpod_mutation_experimental_warning`,
  `riverpod_auto_dispose_keepalive_dependencies`,
  `riverpod_keepalive_family`, `use_ref_invalidate`.
- Async safety: `use_ref_mounted_after_await`,
  `use_context_mounted_after_await`, `async_context_mounted_style`,
  `avoid_sync_notifier_state_read`,
  `use_unawaited_for_fire_and_forget_futures`.
- Notifiers: `avoid_silent_repository_null_return`, `notifier_ensure_deps`,
  `notifier_watch_method`.
- Freezed/serialization: `use_sealed_freezed_classes`,
  `freezed_per_class_explicit_to_json`, `freezed_to_json_with_from_json`,
  `freezed_legacy_when_map`, `dart_static_namespace`.
- Architecture: `arch_domain_import`, `arch_domain_serialization`,
  `arch_interface_contract`, `arch_concrete_dependency`,
  `arch_datasource_try_catch`, `arch_widget_path`, `atomic_provider_access`,
  `typed_id_raw_id`, `records_map_return`, `avoid_object_map_cast`.
- Navigation: `guard_context_pop`, `avoid_route_param_throw_in_build`,
  `router_string_nav`, `router_pop_then_push`, `router_redirect_watch`,
  `router_redirect_loading_bounce`, `router_complex_extra`.
- UI/performance: `avoid_widget_build_helpers`, `avoid_shrink_wrap`,
  `style_raw_token`, `style_raw_text_style`, `strings_hardcoded`,
  `ui_snackbar_boundary`, `a11y_text_scale_clamp`,
  `avoid_private_widget_classes`, `perf_build_work`, `perf_listview_children`,
  `state_raw_response`, `state_raw_error_to_string`,
  `state_broad_invalidation`.
- Showcase: `avoid_showcase_key_filtering`, `showcase_listen_manual_handle`,
  `showcase_prev_null_guard`, `showcase_default_scope`,
  `showcase_dispose_on_tap`.
- Tests/config: `flutter_skill_project_config`, `test_provider_container`,
  `test_uncontrolled_scope`, `test_create_container`, `test_mock_concrete`,
  `test_pump_and_settle`, `test_tap_at`, `test_inline_value_key`,
  `test_first_match_finder`.

Additional-lint coverage that also maps to the skill refs:

- `use_dedicated_media_query_methods` covers `MediaQuery.of(context).size`
  style usage and suggests `MediaQuery.sizeOf(context)` or other dedicated
  methods.
- `prefer_compute_over_isolate_run` covers the Flutter optimization guidance
  around cross-platform isolate work.
- `avoid_incorrect_image_opacity`, `avoid_shrink_wrap_in_lists`,
  `use_sliver_prefix`, `always_remove_listener`, `dispose_fields`,
  `dispose_provided_instances`, `avoid_ref_read_inside_build`,
  and `avoid_mounted_in_setstate` overlap with performance, lifecycle, and
  Riverpod/widget safety references.

## Skill Reference Coverage Matrix

Every `building-flutter-apps` reference was reviewed for analyzer-suitable
rules. The table records the rule groups or runtime boundary that justify the
hover description and correction text.

| Skill reference | Analyzer-backed coverage or recorded boundary |
| --- | --- |
| `analysis-options.md` | `cfg_analysis_options_canonical`, `cfg_strict_analysis`, `cfg_required_lints`, `cfg_generated_exclude`, `cfg_freezed_annotation_ignore`, `cfg_prohibited_lint_plugins` |
| `analysis_options.yaml` | Canonical include/plugins/analyzer/linter block; duplicate checks leave `flutter_lints` and `riverpod_lint` owned rules to those packages |
| `architecture.md` | `arch_domain_import`, `arch_domain_serialization`, `arch_interface_contract`, `arch_repository_generated_extends`, `arch_concrete_dependency`, `arch_datasource_try_catch`, `arch_widget_path`, `arch_model_missing_to_entity`, `arch_model_extends_entity`, `atomic_provider_access`, `avoid_object_map_cast`, runtime boundary for dual persistence owners |
| `atomic-design.md` | `style_raw_token`, `style_raw_text_style`, `strings_hardcoded`, `atomic_provider_access`, `arch_widget_path`, runtime boundary for cross-feature widget promotion |
| `common-patterns.md` | `router_string_nav`, `router_pop_then_push`, `router_redirect_watch`, `router_redirect_loading_bounce`, `router_complex_extra`, `router_impure_redirect`, `router_shell_tab_push`, `guard_context_pop`, `avoid_route_param_throw_in_build`, `state_broad_invalidation`, runtime boundary for UX-specific debounce duration |
| `crashlytics.md` | `crash_direct_firebase_call`, `crash_init_before_run_app`, `crash_possible_pii`, `crash_run_zoned_guarded_legacy`, runtime boundary for CI symbol upload |
| `dart-mcp-e2e-testing.md` | `cfg_e2e_entrypoint`, `test_inline_value_key`, `test_tap_at`, `test_first_match_finder`, runtime boundary for real device, logs, source-of-truth, cleanup, and multi-actor proof |
| `dart-patterns-records.md` | `records_map_return`, `typed_id_raw_id`, `avoid_null_bang`, `prefer_wildcard_pattern`, `prefer_class_destructuring`, `use_existing_destructuring` |
| `extensions-utilities.md` | `ui_snackbar_boundary`, `dart_static_namespace`, `service_static_side_effect`, `fire_and_forget_missing_catch`, `use_unawaited_for_fire_and_forget_futures` |
| `flutter-optimizations.md` | `avoid_shrink_wrap`, `perf_listview_children`, `perf_build_work`, `a11y_text_scale_clamp`, `flutter_key_created_in_build`, `flutter_unique_or_global_key`, `flutter_opacity_widget`, `flutter_save_layer_filter`, `flutter_clip_save_layer`, `flutter_intrinsic_layout`, `flutter_animated_builder_child`, `flutter_widget_operator_equals`, `use_dedicated_media_query_methods`, `prefer_compute_over_isolate_run` |
| `freezed-sealed.md` | `use_sealed_freezed_classes`, `freezed_missing_private_constructor`, `freezed_per_class_explicit_to_json`, `freezed_to_json_with_from_json`, `freezed_legacy_when_map`, `arch_domain_json_annotation`, `cfg_explicit_to_json` |
| `hive-persistence.md` | `hive_reserved_type_ids_missing`, `hive_duplicate_type_id`, `hive_duplicate_field_id`, `hive_test_close_missing`, runtime boundary for historical TypeId permanence |
| `mixins.md` | `mixin_mixin_class`, `mixin_name_suffix`, `mixin_mutable_state` |
| `performance.md` | `riverpod_watch_no_select`, `avoid_widget_build_helpers`, `avoid_shrink_wrap`, `avoid_private_widget_classes`, `perf_listview_children`, `perf_build_work`, `state_raw_response`, `state_raw_error_to_string`, `a11y_text_scale_clamp`, `flutter_*` optimization rules |
| `riverpod-codegen.md` | `avoid_legacy_riverpod_apis`, `riverpod_read_init_state`, `riverpod_service_locator`, `riverpod_watch_no_select`, `riverpod_select_arrow_syntax`, `riverpod_mutation_experimental_warning`, `riverpod_auto_dispose_keepalive_dependencies`, `riverpod_keepalive_family`, `use_ref_invalidate`; Riverpod-owned dependency/scoping/provider-shape diagnostics stay with `riverpod_lint` |
| `services-and-singletons.md` | `service_singleton`, `service_static_side_effect`, `service_random_per_call`, `fire_and_forget_missing_catch`, `use_unawaited_for_fire_and_forget_futures`, `fire_forget_in_tests` |
| `showcase-tours.md` | `avoid_showcase_key_filtering`, `showcase_listen_manual_handle`, `showcase_prev_null_guard`, `showcase_default_scope`, `showcase_dispose_on_tap`, `showcase_v4_api`, `showcase_get_named_unhandled`, `showcase_scope_string_literal` |
| `state-management.md` | `use_ref_mounted_after_await`, `use_context_mounted_after_await`, `async_context_mounted_style`, `avoid_mounted_check_in_finally`, `avoid_sync_notifier_state_read`, `avoid_silent_repository_null_return`, `notifier_ensure_deps`, `notifier_watch_method`, `state_broad_invalidation`, `state_freezed_nullable_error`, runtime boundary for source-of-truth freshness |
| `testing.md` | `cfg_e2e_entrypoint`, `test_provider_container`, `test_uncontrolled_scope`, `test_create_container`, `test_mock_concrete`, `test_pump_and_settle`, `test_tap_at`, `test_inline_value_key`, `test_first_match_finder`, runtime boundary for event-contract and cross-runtime drift proof |

## Added In This Pass

Dart-source drift parity:

- `arch_repository_generated_extends`
- `riverpod_auto_dispose_keepalive_dependencies`
- `riverpod_select_arrow_syntax`
- `riverpod_mutation_experimental_warning`
- `state_freezed_nullable_error`
- `crash_run_zoned_guarded_legacy`

Architecture/Freezed:

- `arch_model_missing_to_entity`
- `arch_model_extends_entity`
- `arch_domain_json_annotation`
- `freezed_missing_private_constructor`

Navigation/Showcase:

- `router_impure_redirect`
- `router_shell_tab_push`
- `showcase_v4_api`
- `showcase_get_named_unhandled`
- `showcase_scope_string_literal`

Flutter optimization:

- `flutter_key_created_in_build`
- `flutter_unique_or_global_key`
- `flutter_opacity_widget`
- `flutter_save_layer_filter`
- `flutter_clip_save_layer`
- `flutter_intrinsic_layout`
- `flutter_animated_builder_child`
- `flutter_widget_operator_equals`

Hive/Crash/services:

- `hive_reserved_type_ids_missing`
- `hive_duplicate_type_id`
- `hive_duplicate_field_id`
- `hive_test_close_missing`
- `crash_direct_firebase_call`
- `crash_init_before_run_app`
- `fire_and_forget_missing_catch`
- `use_unawaited_for_fire_and_forget_futures`
- `service_static_side_effect`
- `service_random_per_call`
- `fire_forget_in_tests`

Registry/test helper improvements:

- `cfg_e2e_entrypoint` checks Flutter apps for `lib/main_dev.dart` with
  `enableFlutterDriverExtension()` before `runApp(...)`.
- `test_keys.dart` is treated as a central key registry filename.
- `test_first_match_finder` is narrower: `.first` only fires around finder
  usage instead of arbitrary collection access.

## Deliberately Not Duplicated

These belong to `riverpod_lint`, the analyzer, or generated-code diagnostics,
so this plugin should not add duplicate reports:

- `prefer_contains` is already enabled by `package:flutter_lints/flutter.yaml`
  through `package:lints/recommended.yaml`.
- `avoid_public_notifier_properties` and `avoid_ref_inside_state_dispose` are
  owned by `riverpod_lint` prerelease `3.1.4-dev.3`. Verified against
  `/tmp/riverpod-lint-8e393e4e` at
  `8e393e4e44cea3ca919db6bb5c68a012e132ab59`.
- Missing `part` files or generated `.g.dart` wiring.
- Riverpod generated provider dependency metadata and scoped-provider override
  diagnostics already owned by Riverpod tooling.
- Basic Dart lints already required by the canonical analysis options, such as
  `prefer_const_constructors`, `unawaited_futures`, `discarded_futures`,
  `avoid_void_async`, `cancel_subscriptions`, and `close_sinks`. The package
  only adds companion guidance for the `VoidCallback` fire-and-forget case
  where `unawaited(...)` is the intended fix, while reusable helpers should
  return `Future<void>` and let callers choose `await` or `unawaited(...)`.

## Riverpod Package Compatibility

External check source:
`/tmp/riverpod-lint-8e393e4e/packages` at
`8e393e4e44cea3ca919db6bb5c68a012e132ab59`.

The local package targets `analyzer: ^12.1.0`,
`analyzer_plugin: ^0.14.8`, and `analysis_server_plugin: ^0.3.14`.
The checked Riverpod packages that use analyzer APIs accept the same analyzer
12 line, so no extra dependency is needed here. Per the Flutter skill config,
`riverpod_lint` stays in the consuming app's top-level `plugins:` block instead
of this package's `pubspec.yaml`.

| Package | Version | SDK | Analyzer/API constraint | Compatible |
| --- | --- | --- | --- | --- |
| `flutter_riverpod` | `3.3.2-dev.2` | `^3.7.0` | none | yes |
| `hooks_riverpod` | `3.3.2-dev.2` | `^3.7.0` | none | yes |
| `internal_lint` | workspace | `^3.10.0` | `analyzer ^12.0.0`, `analyzer_plugin ^0.14.0` | yes |
| `lint_visitor_generator` | workspace | `^3.7.0` | `analyzer ^12.0.0` | yes |
| `riverpod` | `3.3.2-dev.2` | `^3.7.0` | `analyzer ^12.0.0` | yes |
| `riverpod_analyzer_utils` | `1.0.0-dev.10` | `^3.7.0` | `analyzer ^12.0.0` | yes |
| `riverpod_analyzer_utils_tests` | workspace | `^3.7.0` | `analyzer ^12.0.0` | yes |
| `riverpod_annotation` | `4.0.3-dev.2` | `^3.7.0` | none | yes |
| `riverpod_devtool` | workspace | `^3.10.0` | none | yes |
| `riverpod_devtool_generator` | workspace | `^3.8.0` | `analyzer ^12.0.0` | yes |
| `riverpod_generator` | `4.0.4-dev.3` | `^3.7.0` | `analyzer ^12.0.0` | yes |
| `riverpod_lint` | `3.1.4-dev.3` | `^3.10.0` | `analyzer ^12.0.0`, `analyzer_plugin ^0.14.0`, `analysis_server_plugin ^0.3.0` | yes |
| `riverpod_lint_flutter_test` | workspace | `^3.7.0` | `analyzer ^12.0.0`, `analyzer_plugin ^0.14.0` | yes |
| `riverpod_sqflite` | `0.4.3-dev.2` | `^3.7.0` | none | yes |

## Runtime Proof Boundaries

These skill requirements are recorded as runtime or review proof obligations
instead of standalone analyzer diagnostics because a Dart file diagnostic cannot
prove the behavior by itself:

- Event-family mapping for realtime/sync/push/collaboration.
- Source-of-truth refresh proof after stale/generated/derived remote mutation.
- Writer/observer E2E proof, relaunch behavior, cleanup, and log inspection.
- Cross-runtime drift proof when the backend/runtime source is outside the
  analyzed Dart package.
- Hive TypeId/HiveField permanence across git history or released versions.
- Crashlytics symbol upload in CI.
- Accessibility outcomes such as contrast, 48x48 tap targets, and screen reader quality.

The former context-sensitive review bucket is now represented by either an
analyzer-backed diagnostic or this runtime-proof boundary:

- Prop drilling is covered by `riverpod_watch_no_select` and
  `atomic_provider_access`; legitimate data-only children remain a review proof.
- Dual persistence ownership is recorded as a review proof because it needs
  feature-level state ownership knowledge across files and storage backends.
- Source-of-truth refresh is recorded as runtime proof because only the backend
  read path can prove freshness.
- Debounce usage is covered by skill review and tests; the user-visible duration
  still depends on feature UX.
- `GlobalKey`/`UniqueKey`, `Opacity`, `Intrinsic*`, filter widgets, and
  widget equality have analyzer diagnostics in `flutter_optimization_source_rules`.
- Widget promotion to `core/widgets/` remains a review proof because it depends
  on cross-feature reuse intent, not only local syntax.
