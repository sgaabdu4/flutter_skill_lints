# building-flutter-apps Lint Coverage

This audit covers both plugin surfaces:

- `lib/src/rules/**`: 230 registered `building-flutter-apps` warning rules.
- `lib/src/rules/**`: 238 `building-flutter-apps` diagnostic codes.
- `lib/src/additional_lints/rules/**`: 275 additional diagnostics.
- Total unique diagnostics: 511.

## Full Rule Inventory

Read [building-flutter-apps-lint-inventory.md](building-flutter-apps-lint-inventory.md).

## `avoid_throw` typed-failure boundary

`avoid_throw` reports at error severity. It accepts a statically resolved
subtype of `dart:core Exception`
outside presentation code, including the documented parser `FormatException`
case. A direct throw of the base `Exception`, an `Error` subtype, `dynamic`, or
an untyped value remains a diagnostic. A resolved `dart:core`
`Error.throwWithStackTrace` call follows the same contract for its error
argument, so `Error.throwWithStackTrace('invalid', StackTrace.current)` reports
while a typed `Exception` with a stack does not. Propagating the error and
stack trace caught by the same enclosing catch clause
(`on Object catch (e, s) { Error.throwWithStackTrace(e, s); }`) stays allowed;
an error paired with another stack, or a saved pair passed through helper
parameters, is judged by the error's static type. Same-named APIs outside
`dart:core` are ignored.

Presentation code includes Riverpod notifier methods. A class counts as a
notifier when its resolved supertypes reach `AnyNotifier`, `Notifier`,
`AsyncNotifier` or `StreamNotifier` from `riverpod`, or `StateNotifier`. That
covers `@riverpod` codegen notifiers (`class Form extends _$Form`), whose
generated base extends `$Notifier`, not the hand-written `Notifier`.

A validated Value Object factory under `domain/values/` may throw
`ArgumentError.value(<parameter>, ...)` from an `if` guard whose condition
reads that parameter directly or through a `final` local initialized from it
(`final trimmed = input.trim(); if (trimmed.isEmpty) ...`). The same guard is
allowed in a private static helper of the Value Object class (the skill's
extracted `static double _guard(double v, String unit)`); public or instance
helpers and other thrown values still report. Guards on `var`
locals, reassigned locals, or locals unrelated to the parameter still report,
as do other throws in the factory.

The scoped-provider stub from the Riverpod codegen guidance is allowed: a
top-level function annotated with the resolved `riverpod_annotation`
`@Riverpod(...)` that declares `dependencies:` and whose expression body is
the bare `throw UnimplementedError()`, because it must be overridden before
use. A message argument, `@riverpod` providers, block bodies, other thrown
values, and same-named
non-Riverpod annotations still report.

Typed throws still report in resolved Flutter `Widget`/`State` members, in
closures passed to resolved Flutter widget callbacks, and in methods on
classes that resolve to Riverpod `Notifier`, `AsyncNotifier`, `StreamNotifier`,
or `StateNotifier` types. Direct same-unit top-level function and method
references passed to Flutter widget callbacks are also tracked, including
explicit generic tear-offs. The analyzer cannot prove whether a downstream
caller catches a thrown failure, follow
callback variables or references across files, or discover every UI call
graph. Unknown and dynamically typed values therefore remain diagnostics
rather than being inferred as recoverable.

## State, async and lifecycle contract

These rules report as `ERROR` and follow `state-management-lifecycle.md`,
`state-management/async-mutations.md` and `common-patterns.md`:

- `use_ref_mounted_after_await` and `use_context_mounted_after_await` share one
  flow-sensitive scanner. It tracks guards through nested `if`/`try`/`catch`,
  loops, expression bodies and async widget callbacks. A captured
  `context.mounted` guard protects `context`. `State.context` is resolved as a
  getter, so it still needs `mounted`. Pure `mounted` guard suffixes, including
  enum `==`/`!=` checks, are accepted.
- `avoid_mounted_check_in_finally` and `avoid_only_rethrow` report as `ERROR`.
- `notifier_ensure_deps` accepts a direct resolved `ref.read(...)` for a
  dependency. `require_atomic_async_updates` accepts a resolved `!ref.mounted`
  guard.
- `arch_datasource_try_catch` flags only a trailing datasource catch clause
  whose body is only `rethrow`. `data_log_rethrow` flags data-layer catches whose
  body is only reporting calls followed by `rethrow`. A reporting call is a
  resolved `print` (`dart:core`), `log` (`dart:developer`) or Flutter
  `debugPrint`, or any call that receives the caught error or stack trace.
  Translation, rollback and local-first recovery catches stay allowed, and the
  two rules never report the same catch.
- `state_raw_error_to_string` flags a String `error:` argument built from a
  resolved catch exception or stack trace, or from `.toString()` on a
  non-String. `state_freezed_nullable_error` flags `String`/`String?` fields and
  redirecting-factory parameters named like `error` in `*State` classes,
  whether or not they use Freezed. Flutter `State<T>` subclasses are excluded by
  resolved supertype. The class-name suffix is the only single-file
  notifier-state classifier.
- `riverpod_event_counter_signal_forbidden` also resolves `@riverpod` classes and
  functions by their generated provider name.
- `notifier_local_dependency_cache` flags notifier fields typed as a
  repository, service or datasource. It also flags fields that cache a resolved
  `ref.read(...)` of a dependency type. Constructing a client directly is not a
  provider-read cache.
- `notifier_watch_method` flags resolved `ref.watch` and `ref.listen` in any
  non-static notifier method other than `build`.
- `widget_calls_notifier_teardown_after_await` also flags `.go(context)` and
  `context.go(...)` after an awaited notifier mutation in the same widget block.
  Screens self-navigate from the observed state. Push, `goBranch` and `go` after
  an awaited modal stay allowed.

## Existing Coverage

Core skill rules already covered before this pass:

- Riverpod/codegen: `avoid_legacy_riverpod_apis`, `riverpod_read_init_state`,
  `riverpod_service_locator`, `riverpod_manual_provider`,
  `riverpod_generated_provider_alias`, `riverpod_widget_ref_outside_widget`,
  `riverpod_consumer_state_derived_cache`, `riverpod_watch_no_select`,
  `riverpod_select_arrow_syntax`, `riverpod_mutation_experimental_warning`,
  `riverpod_mutation_top_level`, `riverpod_mutation_ref_read`,
  `async_value_switch_over_when`,
  `riverpod_auto_dispose_keepalive_dependencies`,
  `riverpod_keepalive_family`, `use_ref_invalidate`.
- Async safety: `use_ref_mounted_after_await`,
  `use_context_mounted_after_await`, `async_context_mounted_style`,
  `avoid_sync_notifier_state_read`,
  `use_unawaited_for_fire_and_forget_futures`.
- Notifiers: `avoid_silent_repository_null_return`, `notifier_ensure_deps`,
  `notifier_watch_method`, `notifier_stored_ref_field`.
- Freezed/serialization: `use_sealed_freezed_classes`,
  `freezed_per_class_explicit_to_json`, `freezed_to_json_with_from_json`,
  `freezed_legacy_when_map`, `use_freezed_instead_of_immutable`,
  `freezed_one_class_per_file`, `dart_static_namespace`.
- Architecture: `arch_domain_import`, `arch_storage_sdk_import`, `arch_domain_serialization`,
  `arch_interface_contract`, `arch_concrete_dependency`,
  `arch_repository_inline_entity_mapping`,
  `arch_datasource_try_catch`, `arch_widget_path`, `atomic_provider_access`,
  `atomic_page_consumer_widget`, `typed_id_raw_id`, `records_map_return`, `avoid_object_map_cast`,
  `vo_public_raw_constructor`, `domain_entity_primitive_factory`,
  `domain_raw_required_string`, `domain_unit_primitive`,
  `domain_custom_copy_with`, `freezed_disable_map_when_required`,
  `use_hive_ce_flutter_import`, `hive_field_no_vo_type`.
- Navigation: `guard_context_pop`, `pop_fallback_helper_must_check_navigator_stack`,
  `avoid_route_param_throw_in_build`, `router_string_nav`, `router_gorouter_of`,
  `router_untyped_navigator_push`, `router_direct_route_call`,
  `router_raw_route_definition`,
  `router_modal_local_helpers`,
  `router_container_navigation_escape`,
  `router_context_navigation_extension`,
  `router_navigation_wrapper_api`, `router_pop_then_push`,
  `router_redirect_watch`, `router_redirect_loading_bounce`,
  `router_splash_waits_for_initial_sync`,
  `router_complex_extra`.
- Reusable presentation widgets: `presentation_widget_navigation_forbidden`,
  `presentation_widget_controller_state`,
  `presentation_widget_infrastructure_dependency`.
- UI/performance/date: `avoid_widget_build_helpers`, `avoid_shrink_wrap`,
  `style_raw_token`, `style_raw_text_style`, `strings_hardcoded`,
  `l10n_context_direct_access`, `l10n_string_concatenation`,
  `l10n_notifier_localized_copy`, `widget_preview_import_leak`,
  `widget_preview_platform_dependency`, `widget_preview_screen`,
  `ui_snackbar_boundary`,
  `widget_material_boundary` (raw `Material` / `Ink` / `InkWell` outside owners),
  `a11y_text_scale_clamp`, `datetime_now_requires_timezone_intent`,
  `ad_hoc_intl_format`, `inline_num_clamp`, `record_use_outside_ffi`,
  `avoid_private_widget_classes`, `perf_build_work`, `perf_listview_children`,
  `state_empty_string_sentinel`, `state_bool_string_sentinel`,
  `state_raw_response`, `state_raw_error_to_string`,
  `state_broad_invalidation`.
- Tests/config: `flutter_skill_project_config`, `test_provider_container`,
  `test_uncontrolled_scope`, `test_create_container`, `test_mock_concrete`,
  `test_pump_and_settle`, `test_tap_at`, `test_inline_value_key`,
  `test_first_match_finder`, `test_notifier_override`,
  `test_text_label_selector`, `test_e2e_blind_sleep`.
- Effective Dart/config shape: canonical configs require
   `always_declare_return_types`, `type_annotate_public_apis`,
   `avoid_positional_boolean_parameters`,
   `avoid_equals_and_hash_code_on_mutable_classes`, `avoid_returning_this`,
   `avoid_setters_without_getters`, `prefer_mixin`, and
  `use_to_and_as_if_applicable`. `prefer_type_over_var` was removed because it
  conflicts with Effective Dart's local-variable inference guidance.
- Effective Dart Design API safety not covered by upstream lints:
  `avoid_futureor_return_type`,
  `avoid_nullable_async_or_collection_return_type`, and
  `avoid_public_late_final_without_initializer`.

Additional-lint coverage that also maps to the skill refs:

- `use_dedicated_media_query_methods` covers `MediaQuery.of(context).size`
  style usage and suggests `MediaQuery.sizeOf(context)` or other dedicated
  methods.
- `use_context_is_current_modal_route` covers route-current guards and keeps
  raw `ModalRoute` current-route checks inside the context extension owner.
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
| `analysis-options.md` | `cfg_analysis_options_canonical`, `cfg_strict_analysis`, `cfg_required_lints`, `cfg_generated_exclude`, `cfg_prohibited_lint_plugins`, `avoid_flutter_skill_lint_suppression` |
| `analysis_options.yaml` | Canonical include/plugins/analyzer/linter block; duplicate checks leave `flutter_lints` and `riverpod_lint` owned rules to those packages |
| `architecture.md` | `arch_domain_import`, `arch_storage_sdk_import`, `arch_domain_serialization`, `arch_interface_contract`, `arch_repository_generated_extends`, `arch_concrete_dependency`, `arch_datasource_try_catch`, `arch_widget_path`, `arch_model_missing_to_entity`, `arch_repository_inline_entity_mapping`, `arch_model_extends_entity`, `atomic_provider_access`, `avoid_object_map_cast`, `avoid_inline_error_codes`, `avoid_local_contract_key_constants`, runtime boundary for dual persistence owners |
| `atomic-design.md` | `style_raw_token`, `style_raw_text_style`, `strings_hardcoded`, `atomic_provider_access`, `atomic_page_consumer_widget`, `arch_widget_path`, `widget_material_boundary`, runtime boundary for cross-feature widget promotion |
| `common-patterns.md` | `router_string_nav`, `router_gorouter_of`, `router_untyped_navigator_push`, `router_direct_route_call`, `router_raw_route_definition`, `router_modal_local_helpers`, `router_container_navigation_escape`, `router_context_navigation_extension`, `router_navigation_wrapper_api`, `router_pop_then_push`, `pop_fallback_helper_must_check_navigator_stack` (mounted + root/local Navigator fallback), `router_redirect_watch`, `router_redirect_loading_bounce`, `router_splash_waits_for_initial_sync`, `router_complex_extra`, `router_impure_redirect`, `router_shell_tab_push`, `guard_context_pop`, `use_context_is_current_modal_route`, `avoid_route_param_throw_in_build`, `state_broad_invalidation`, `widget_local_mutation_flag`, `storage_clear_preserves_migration_state`, runtime boundary for UX-specific debounce duration |
| `dart-mcp-e2e-testing.md` | `cfg_e2e_entrypoint`, `avoid_flutter_host_driver_imports`, `test_inline_value_key`, `test_tap_at`, `test_first_match_finder`, `riverpod_notifier_override_with_value`, `test_e2e_blind_sleep`, runtime boundary for real device, logs, source-of-truth, cleanup, and multi-actor proof |
| `dart-patterns-records.md` | `record_use_outside_ffi`, `records_map_return`, `typed_id_raw_id`, `avoid_null_bang`, `prefer_wildcard_pattern`, `prefer_class_destructuring`, `use_existing_destructuring` |
| `error-reporting.md` | `crash_direct_firebase_call`, `crash_direct_sentry_call`, `crash_init_before_run_app`, `crash_custom_global_error_handler`, `avoid_run_zoned_guarded`, `crash_facade_public_api`, `crash_error_recursion`, `crash_sentry_send_default_pii`, `crash_sentry_capture_opt_in`, `crash_sentry_auth_token_in_source`, `crash_possible_pii` (keyword heuristic), `data_log_rethrow`, `destructive_failure_logged_before_reconcile` (name heuristic), runtime boundary for CI symbol upload, replay, performance/profile sampling, request bodies/headers, and user identity |
| `extensions-utilities.md` | `ui_snackbar_boundary`, `datetime_now_requires_timezone_intent`, `ad_hoc_intl_format`, `inline_num_clamp`, `avoid_magic_literals`, `use_context_is_current_modal_route`, `dart_static_namespace`, `service_static_side_effect`, `fire_and_forget_missing_catch`, `use_unawaited_for_fire_and_forget_futures` |
| `flutter-optimizations.md` | `avoid_shrink_wrap`, `perf_listview_children`, `perf_build_work`, `a11y_text_scale_clamp`, `flutter_key_created_in_build`, `flutter_unique_or_global_key`, `flutter_opacity_widget`, `flutter_save_layer_filter`, `flutter_clip_save_layer`, `flutter_intrinsic_layout`, `flutter_animated_builder_child`, `flutter_widget_operator_equals`, `avoid_list_in_single_child_scroll_view`, `avoid_clip_rrect_container`, `use_dedicated_media_query_methods`, `dispose_fields` |
| `freezed-sealed.md` | `use_sealed_freezed_classes`, `use_freezed_instead_of_immutable`, `freezed_one_class_per_file`, `freezed_missing_private_constructor`, `freezed_per_class_explicit_to_json`, `freezed_to_json_with_from_json`, `freezed_legacy_when_map`, `async_value_switch_over_when`, `arch_domain_json_annotation`, `cfg_explicit_to_json` |
| `hive-persistence.md` | `hive_reserved_type_ids_missing`, `hive_duplicate_type_id`, `hive_duplicate_field_id`, `hive_type_on_freezed_class`, `hive_adapter_spec_domain_type`, `notifier_hive_access`, `hive_test_close_missing`, `avoid_unvalidated_persisted_map_cast`, runtime boundary for historical TypeId permanence |
| `layout-diagnostics.md` | `avoid_shrink_wrap`, `avoid_shrink_wrap_in_lists`, `avoid_flexible_outside_flex`, `avoid_positioned_outside_stack`, `avoid_unbounded_list_in_column`, `avoid_unbounded_text_field_in_row`, `avoid_orientation_layout`, `use_dedicated_media_query_methods`, `prefer_spacing` limited to repeated uniform gaps, runtime boundary for device-type layout checks |
| `localization.md` | `strings_hardcoded`, `avoid_hardcoded_strings`, `l10n_context_direct_access`, `l10n_string_concatenation`, `l10n_notifier_localized_copy` |
| `mixins.md` | `mixin_mixin_class`, `mixin_name_suffix`, `mixin_mutable_state` |
| `networking.md` | `network_http_call_in_widget_or_notifier`, `datasource_concrete_http_client`, `network_failure_null_fallback`, `network_secret_in_widget`, `network_raw_http_failure_in_widget_or_notifier`, `appwrite_blocking_function_execution_in_client` (name heuristic), `destructive_failure_logged_before_reconcile`, runtime boundary for base-URL constants in widgets, source-of-truth refresh after mutations, and retry safety |
| `performance.md` | `riverpod_watch_no_select`, `avoid_widget_build_helpers`, `avoid_shrink_wrap`, `avoid_private_widget_classes`, `perf_listview_children`, `perf_build_work`, `state_empty_string_sentinel`, `state_bool_string_sentinel`, `state_raw_response`, `state_raw_error_to_string`, `a11y_text_scale_clamp`, `user_visible_duration_too_long`, `notifier_timer_without_on_dispose`, `flutter_*` optimization rules |
| `presentation-widgets.md` | `presentation_widget_navigation_forbidden`, `presentation_widget_controller_state`, `presentation_widget_infrastructure_dependency` |
| `riverpod-codegen.md` | `avoid_legacy_riverpod_apis`, `riverpod_read_init_state`, `riverpod_service_locator`, `riverpod_manual_provider`, `riverpod_generated_provider_alias`, `riverpod_widget_ref_outside_widget`, `riverpod_consumer_state_derived_cache`, `riverpod_consumer_state_provider_subscription`, `riverpod_listen_manual_forbidden`, `riverpod_event_counter_signal_forbidden`, `service_provider_watch_dependency`, `riverpod_config_destructuring`, `riverpod_watch_no_select`, `riverpod_select_arrow_syntax`, `riverpod_mutation_experimental_warning`, `riverpod_mutation_top_level`, `riverpod_mutation_ref_read`, `riverpod_auto_dispose_keepalive_dependencies`, `riverpod_feature_notifier_keepalive`, `riverpod_keepalive_family`, `use_ref_invalidate`; Riverpod-owned dependency/scoping/provider-shape diagnostics stay with `riverpod_lint` |
	| `services-and-singletons.md` | `service_singleton`, `service_static_side_effect`, `service_random_per_call`, `hidden_dependency_fallback`, `hidden_dependency_default_param`, `service_inline_concrete_dependency`, `service_provider_watch_dependency`, `fire_and_forget_missing_catch`, `use_unawaited_for_fire_and_forget_futures`, `fire_forget_in_tests`, `appwrite_blocking_function_execution_in_client` |
| `state-management.md` | `use_ref_mounted_after_await`, `use_context_mounted_after_await`, `async_context_mounted_style`, `avoid_mounted_check_in_finally`, `avoid_sync_notifier_state_read`, `avoid_silent_repository_null_return`, `notifier_ensure_deps`, `notifier_watch_method`, `notifier_stored_ref_field`, `service_provider_watch_dependency`, `riverpod_event_counter_signal_forbidden`, `widget_awaits_notifier_result`, `widget_local_mutation_flag`, `state_empty_string_sentinel`, `state_bool_string_sentinel`, `state_broad_invalidation`, `state_freezed_nullable_error`, runtime boundary for source-of-truth freshness |
| `testing.md` | `cfg_e2e_entrypoint`, `test_provider_container`, `test_uncontrolled_scope`, `test_create_container`, `test_mock_concrete`, `test_pump_and_settle`, `test_tap_at`, `test_inline_value_key`, `test_first_match_finder`, `test_notifier_override`, `test_text_label_selector`, runtime boundary for event-contract and cross-runtime drift proof |
| `widget-previews.md` | `widget_preview_import_leak`, `widget_preview_platform_dependency` (dart:io, platform channels, Hive, Firebase, Dio, http; arbitrary native plugins are a runtime boundary), `widget_preview_screen` |

## Added In This Pass

Dart-source drift parity:

- `arch_repository_generated_extends`
- `riverpod_auto_dispose_keepalive_dependencies`
- `riverpod_feature_notifier_keepalive`
- `riverpod_select_arrow_syntax`
- `riverpod_mutation_experimental_warning`
- `riverpod_mutation_top_level`
- `riverpod_mutation_ref_read`
- `async_value_switch_over_when`
- `state_freezed_nullable_error`

Architecture/Freezed:

- `arch_model_missing_to_entity`
- `arch_model_extends_entity`
- `arch_domain_json_annotation`
- `freezed_missing_private_constructor`


- `pop_fallback_helper_must_check_navigator_stack`
- `router_impure_redirect`
- `router_shell_tab_push`

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

- `appwrite_blocking_function_execution_in_client`
- `destructive_failure_logged_before_reconcile`
- `storage_clear_preserves_migration_state`
- `hive_reserved_type_ids_missing`
- `hive_duplicate_type_id`
- `hive_duplicate_field_id`
- `hive_type_on_freezed_class`
- `hive_adapter_spec_domain_type`
- `notifier_hive_access`
- `hive_test_close_missing`
- `crash_direct_firebase_call`
- `crash_init_before_run_app`
- `fire_and_forget_missing_catch`
- `use_unawaited_for_fire_and_forget_futures`
- `service_static_side_effect`
- `service_random_per_call`
- `fire_forget_in_tests`

Registry/test helper improvements:

- `avoid_unnecessary_else_after_control_flow` enforces flat guard-style control
  flow after `return` / `throw` / `break` / `continue`, matching the skill's
  critical rule and Effective Dart's preference for clear control flow.
- `cfg_e2e_entrypoint` checks Flutter apps for `lib/main_dev.dart` with
  `enableFlutterDriverExtension()` before `runApp(...)`.
- `test_keys.dart` is treated as a central key registry filename.
- `test_first_match_finder` is narrower: `.first` only fires around finder
  usage instead of arbitrary collection access.

E2E and persistence boundaries:

- `avoid_flutter_host_driver_imports` rejects direct and transitive Flutter UI,
  target-only driver, and app-package imports from `test_driver/` host files.
- `avoid_unvalidated_persisted_map_cast` rejects direct typed-map casts in
  local persistence paths while allowing remote JSON decoding paths.

Modal snapshot / state teardown (0.7.0) — `dialog_source_rules`:

- `dialog_widget_subscribes_to_mutable_provider` — dialog/sheet widgets must
  not `ref.watch` the same provider their button calls
  `ref.read(...notifier).method()` on; pass an immutable snapshot through the
  constructor instead.
- `dialog_button_pop_then_state_mutation` — code after `Navigator.pop()` /
  `context.pop()` inside a dialog runs against a dying widget tree; move the
  side effect to the caller after `await showDialog<T>(...)`.
- `select_returns_unstable_record_identity` — record selects that read
  getters returning a fresh `Map`/`Set`/`List`/`Items`/`Entries` per call
  cause a rebuild on every notify; watch primitives or memoize.
- `build_method_assigns_to_field` — `build()` must be pure; no `this.x = ...`
  or `_field = ...` inside build.
- `widget_calls_notifier_teardown_after_await` — a widget that awaits a
  notifier mutation then calls `reset` / `clear` / `dispose` on the same
  notifier, or navigates with `.go(context)` / `context.go(...)`, may already
  be unmounted; let the notifier own success teardown and the screen
  self-navigate from observed state.
- `popscope_bypass_uses_go_not_pop` — pop navigation after an awaited modal
  triggers `PopScope.onPopInvoked`; use a typed `<Route>().go`.
- `modal_helper_requires_route_settings` — `showDialog` / `showModalBottomSheet`
  (and project `show*Dialog` / `show*Sheet` helpers) must pass `routeSettings`
  so the modal appears in observer/analytics logs.

Runtime-bug surface (0.7.0) — `runtime_bug_source_rules`:

- `sync_save_all_no_dirty_guard` — `.saveAll(... .map(Model.fromEntity)...)`
  in a sync push without a `changed.isEmpty` early-return rewrites the entire
  collection every cycle.
- `appwrite_blocking_function_execution_in_client` — Appwrite
  `createExecution(...)` calls inside destructive/sync/import/export/migration
  client methods must pass `xasync: true` and reconcile source-of-truth state
  instead of waiting synchronously for a potentially long-running Function.
- `destructive_failure_logged_before_reconcile` — delete/remove/deactivate
  catch blocks should call a reconcile/verify/wait-for source-of-truth check
  before Crash/Sentry/Firebase error reporting.
- `storage_clear_preserves_migration_state` — datasource/repository
  reset/clear methods must not read and restore migration/version/install markers
  before `.clear()` and restore them after, unless the wipe is intentionally
  destructive.
- `notifier_persistence_no_debounce` — a notifier with `_schedule*Persist` /
  `_persistDraft` helper reached from a synchronous or state-writing mutation
  path but no `Timer` / `Future.delayed` / `Debouncer` coalesces nothing;
  queue/generation tokens prevent stale writes only. Awaited one-shot
  lifecycle writes are allowed.
- `riverpod_listen_manual_forbidden` — `ref.listenManual(...)` is forbidden;
  use `ref.listen` in `build` for widget UI side effects, or move durable
  subscriptions to provider/notifier/service lifecycle.
- `riverpod_event_counter_signal_forbidden` — standalone `*Signal` / `*Event`
  / `*Pulse` / `*Serial` Riverpod providers (manual or `@riverpod` by generated
  provider name) are forbidden; fold the event
  serial/payload into the owning notifier state and listen to a concrete
  `.select((state) => state.successSerial)` field, or rename durable status
  state to a concrete `*StatusNotifier` / `*Lifecycle` provider.
- `webview_init_in_build_no_gate` — `InAppWebView` / `WebViewWidget` /
  `YoutubePlayer` / `VideoPlayer` constructed in `build()` without a
  `_user*` / `*Tapped` / `*Requested` boolean gate field pays the
  platform-channel cost on every mount.
- `service_storage_read_no_memo` — a `*Service` class whose method reads from
  `_storage.read` / `_box.get` with no `Map<String, ...>` memoization field
  re-hits storage every call.
- `service_provider_watch_dependency` — service/repository/datasource/client
  provider factories and Riverpod notifier members (including `build()`) must
  wire stable infrastructure deps with `ref.read`, not `ref.watch`; watching a
  resolved reactive state or config value (for example rebuilding a client from
  a live config provider) is allowed.
- `riverpod_config_destructuring` — a local read from `ref.watch`/`ref.read`
  of a provider whose resolved value is a `*Config` class, and used only
  through property reads, must be destructured
  (`final BackendConfig(:endpoint, :apiKey) = ref.watch(backendConfigProvider);`).
- `hidden_dependency_default_param` — constructor/function dependency seams such
  as `clock`, `delay`, `generator`, `authenticator`, or `createExecution` must
  be required and wired at the provider/composition root, not optional/defaulted.
- `keepalive_watches_unbounded_collection` — `@Riverpod(keepAlive: true)`
  whose `build()` returns or derives from `s.logs` / `s.items` /
  `s.entries` / `s.posts` etc. retains every entry for the session, including
  a pure projection that returns the source list reference (the skill's
  NEVER example); derive a bounded projection such as `s.count` instead. A
  provider whose watched source resolves (across files, via the generated
  `@ProviderFor`) to a `@Riverpod(keepAlive: true)` declaration is allowed,
  matching the performance guide's all-keepAlive lifecycle rule.
- `datasource_missing_batch_loader` — abstract `*LocalDatasource` /
  `*RemoteDatasource` with 5+ single-value async getters and no
  `loadAll` / `getAll` / `readAll` / `loadSettings` / `getSnapshot` forces
  N storage hits per screen.
- `notifier_zero_value_save_no_guard` — `ref.read(...notifier).save*(amount: ..,
  count: ..)` (and similar named args whose resolved type is `int`, `double` or
  `num`) without an enclosing `> 0` / `isNotEmpty` guard or an earlier
  `if (amount <= 0 && count <= 0) return;` persists empty rows the user did not
  intend. Value Object arguments such as `Distance` need no guard.
- `notifier_param_requires_value_object` — unit-bearing primitive locals
  (`*Meters` / `*Seconds` / `*Cents` / `*Bytes` / `*Pixels` etc.) passed into
  a notifier `save*` call should be wrapped at the widget→notifier boundary
  in a domain Value Object.
- `text_field_on_changed_no_debounce` — `TextField` /  `TextFormField` /
  `CupertinoTextField` / `SearchBar` `onChanged` (lambda or tear-off) that
  reaches async or remote work (an `await`, a Future/Stream-typed call, an
  async callee, or an unresolved call) without a `Timer` / `Debouncer` /
  `Future.delayed` in the file fires per keystroke. Project callees in other
  files are followed too, and a callee file that owns such a debounce counts
  as debounced. Synchronous state-only form updates (`copyWith` plus local
  validation) are allowed.
- `slider_on_changed_no_debounce` — `Slider` / `RangeSlider` / `CupertinoSlider`
  `onChanged` (lambda or tear-off) that reaches async or remote work fires
  continuously during drag; move to `onChangeEnd` or debounce.
- `scroll_listener_no_throttle` — `_scrollController.addListener(...)` doing
  notifier or async work without a `Timer` / `Debouncer` in the file fires
  on every scroll tick.

Source scanner change (0.7.0):

- `SourceScannerSource` now blanks `debugPrint(...)` / `print(...)` call
  bodies before any rule runs so identifiers buried inside log strings can
  never trigger a downstream rule. Char positions are preserved so diagnostic
  offsets stay aligned across blank zones.

## Deliberately Not Duplicated

These belong to `riverpod_lint`, the analyzer, or generated-code diagnostics,
so this plugin should not add duplicate reports:

- `prefer_contains` is already enabled by `package:flutter_lints/flutter.yaml`
  through `package:lints/recommended.yaml`.
- `avoid_public_notifier_properties` and `avoid_ref_inside_state_dispose` are
  owned by `riverpod_lint 3.1.9`. Verified against the
  [Riverpod lint changelog](https://pub.dev/packages/riverpod_lint/changelog).
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

The lint package uses the shared analyzer-14.4 family in its `pubspec.yaml`:

- `analyzer 14.4.0`
- `analyzer_plugin 0.14.17`
- `analysis_server_plugin 0.3.23`
- `analyzer_testing 0.4.2`
- `riverpod_lint 3.1.9` in a Dart 3.13 consuming app's top-level `plugins:` block

The real analysis-server smoke test resolves both plugins together and checks
that diagnostics are emitted without `server.pluginError`. The analyzer-14.4
family is the shared package contract. The Flutter generator family remains
separate because its build process resolves analyzer 12.x for code generation.
Version truth lives in the Flutter skill's
`references/core-stack.md`.

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
