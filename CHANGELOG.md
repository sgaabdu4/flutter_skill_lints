# Changelog

## [0.13.0] - 2026-09-25

Aligns every rule with building-flutter-apps 5.12.0. Skill MUST/NEVER rules
report as errors and are enabled by default; each skill DO example analyzes
clean and each WRONG example reports its named lint.

- Report every skill rule at error severity, enabled by default. A registration
  test rejects any skill code below error.
- Add skill rules for AsyncValue switches, page consumers, the Crash facade and
  Sentry configuration, Hive adapter boundaries, localized notifier copy,
  network failures, Riverpod mutations and generated providers, widget
  previews, E2E waits and selectors, and layout constraints:
  `ad_hoc_intl_format`, `arch_repository_inline_entity_mapping`,
  `arch_storage_sdk_import`, `async_value_switch_over_when`,
  `atomic_page_consumer_widget`, `avoid_clip_rrect_container`,
  `avoid_list_in_single_child_scroll_view`, `avoid_orientation_layout`,
  `avoid_positioned_outside_stack`, `avoid_unbounded_list_in_column`,
  `avoid_unbounded_text_field_in_row`, `crash_custom_global_error_handler`,
  `crash_direct_sentry_call`, `crash_error_recursion`,
  `crash_facade_public_api`, `crash_sentry_auth_token_in_source`,
  `crash_sentry_capture_opt_in`, `crash_sentry_send_default_pii`,
  `datasource_concrete_http_client`, `hive_adapter_spec_domain_type`,
  `hive_type_on_freezed_class`, `inline_num_clamp`,
  `l10n_notifier_localized_copy`, `l10n_string_concatenation`,
  `network_failure_null_fallback`, `network_http_call_in_widget_or_notifier`,
  `network_raw_http_failure_in_widget_or_notifier`, `network_secret_in_widget`,
  `notifier_hive_access`, `notifier_stored_ref_field`,
  `notifier_timer_without_on_dispose`, `record_use_outside_ffi`,
  `riverpod_config_destructuring`, `riverpod_generated_provider_alias`,
  `riverpod_mutation_ref_read`, `riverpod_mutation_top_level`,
  `riverpod_widget_ref_outside_widget`, `test_e2e_blind_sleep`,
  `test_notifier_override`, `test_text_label_selector`,
  `widget_preview_import_leak`, `widget_preview_platform_dependency` and
  `widget_preview_screen`.
- Remove rules the skill does not require or that contradict its examples:
  `arch_datasource_try_catch`, `avoid_declaring_call_method`,
  `avoid_missing_controller` (#44), `avoid_non_null_assertion` (#43; the skill's
  `avoid_null_bang` now reports each `!` once), `move_records_to_typedefs`,
  `prefer_compute_over_isolate_run`, `prefer_dedicated_media_query_methods` and
  `prefer_test_matchers`.
- Fix false positives against skill examples in `avoid_throw` (#42, #86, #95),
  `riverpod_watch_no_select` (#36), `freezed_legacy_when_map` (#50),
  `dart_static_namespace` (#51), `avoid_magic_literals` (#52),
  `ROUTER_COMPLEX_EXTRA` (#60), `notifier_persistence_no_debounce` (#66),
  `service_provider_watch_dependency` (#68), SDK mock detection for part
  declarations (#77), `linear_id_lookup_in_hot_path` (#87) and
  `avoid_commented_out_code` (#91).
- Narrow general-purpose lints to the skill's examples: `else` after an exit
  only, `late final` fields with an initializer, `while (true)` loops, resolved
  hook calls, required and positional parameters in `avoid_long_parameter_list`,
  JSON keys in models, `<String, dynamic>` map literals, collection reads in
  tests and a public `value` field on extension types.
- `riverpod_watch_no_select` reports a field read of a watched computed
  provider; `destructive_failure_logged_before_reconcile` reports telemetry in
  the catch of async-started long-running work that never reconciles.
- Replace name, path and line-text heuristics with resolved element checks
  across Riverpod, router, UI, persistence and crash rules.
- Accept `maybePop` route futures in fire-and-forget callees, static test
  helpers in `service_static_side_effect` and `abstract final` static
  namespaces (keys, codecs, mappers) in `freezed_required_value_class`.
- Stop a bodyless declaration such as `const Repo(this.remote);` from hiding
  the next method from source-scanned rules.

## [0.12.15] - 2026-09-25

- Enforce `avoid_null_bang` by default again, as an error. The 0.12.8 opt-in
  change removed the skill's documented `avoid_null_bang` check; an unsafe `!`
  now reports both `avoid_null_bang` and `avoid_non_null_assertion`.

## [0.12.14] - 2026-09-25

- Resolve provider return types before classifying stable infrastructure; computed
  collections and records remain reactive values, while actual resources retain checks.
- Recognize full list iteration and complete Riverpod async-state dispatch without
  exempting indexed leaf reads or unrelated APIs.
- Accept mounted, revision-guarded loading-to-result state transitions; retain
  diagnostics for unsafe guards, intervening awaits and conflicting writes.
- Recognize the resolved Sentry options builder while retaining rebinding,
  deferred mutation and writes outside the builder, including cascaded writes.
- Recognize Appwrite Functions and Storage SDK mock boundaries by their actual
  declarations; same-named local concrete contracts remain diagnosed.
- Validate captured notifier dependencies instead of relying on initializer
  helper names; retain late reads, unused captures and unsafe initialization.

- Permit direct throws of typed recoverable exceptions at parser and infrastructure boundaries;
  retain warnings in resolved UI callbacks and notifier methods, and for
  untyped failures and programmer errors.
- Recognize actual Mocktail and Mockito verification getters as test assertions;
  retain warnings for unrelated or shadowed lookalikes and deferred checks.

## [0.12.13] - 2026-09-24

- Restrict direct `SizedBox` spacing suggestions to equivalent uniform interior
  separators; preserve edge gaps, conditional children, keys and axis semantics.
- Resolve Flutter widget collection types before recommending collection-for
  builders. Numeric data transformations and custom API lookalikes remain valid.
- Limit fold suggestions to append-once widget builders that do not depend on
  the accumulated list. Filtered, reordered and accumulating folds remain valid.
- Preserve fixed-length list construction, immutable fold seeds, evaluated gap
  expressions and alignment modes whose layout changes when spacers are removed.

## [0.12.12] - 2026-09-24

- Recognize `dart:ui Path.close()` as a drawing operation, while continuing to
  report genuine resources that require disposal, closing, or cancellation.
- Resolve enum ownership, including typedefs and import prefixes, before
  reporting indexed `values` access. Ordinary map fields remain valid.
- Distinguish private named constructors from discarded-variable reads.

## [0.12.11] - 2026-09-24

- Fix allowed SDK mock detection for service declarations in Dart library parts;
  local concrete contracts and unrelated package lookalikes still report.
- Reject callback cleanup exceptions when a later condition or a preceding
  statement can replace the callback before the guarded cleanup.
- Require mounted guards to use the notifier's resolved Riverpod reference;
  same-named local values and another provider's reference do not qualify.
- Respect expression evaluation order when suggesting an existing variable:
  report pure repeats before an effect, and avoid stale reuse after calls,
  assignments, getters, or awaits.

## [0.12.10] - 2026-09-24

- Resolve test mock contracts by their declaration type, including aliases.
  Abstract contracts remain allowed; concrete contracts report regardless of
  naming, and SDK mock exceptions apply only to their actual package libraries.
- Preserve fresh reads after awaits and effectful calls or getters while still
  reporting repeated pure expressions.
- Accept mounted guards that combine lifecycle and revision checks, including
  proven private helpers. Incomplete returns, state access inside the rejected
  branch, shadowed references, and overridable helpers remain diagnosed.
- Allow the Dart SDK's positional future-record `.wait` receiver while retaining
  diagnostics for ordinary positional records and unrelated `.wait` getters.

## [0.12.9] - 2026-09-24

- Fix a 0.12.8 regression for awaited top-level startup helpers that initialize
  Crash before running the app. Resolve startup calls and callback ownership;
  retain warnings for unawaited, conditional, unreachable, and late initialization.
- Allow named local callbacks used for identity-guarded slot cleanup without
  conflicting with Dart declaration syntax. Different slots, shadowed callbacks,
  and no-op cleanup do not qualify.
- Distinguish existing Image lookups from Flutter Image construction; unlabeled
  constructors still report accessibility diagnostics.
- Accept the documented DateTimeX helper at its canonical path without exempting
  unrelated types or mismatched paths from filename checks.
- Recognize optional nullable diagnostic payloads in resolved Exception/Error
  Freezed unions while retaining primitive identity and conversion diagnostics.

- Recognize whole-value provider results bound through conditional expressions;
  partial state reads still require a selector.

## [0.12.8] - 2026-09-24

- Resolve test APIs, repository interfaces, notifier dependencies, and Freezed
  operations before suggesting changes. Unrelated methods with the same names,
  constructor-injected dependencies, and parameterless union cases stay allowed.
- Recognize proven synchronous state updates, whole-value provider consumption,
  and awaited crash initialization wrappers while retaining diagnostics for
  asynchronous work, partial reads, and missing initialization.
- Check nullable collection type syntax directly so conditional expressions and
  nullable callbacks do not produce collection warnings.
- Recognize assertions in project-owned test helpers and proven collection
  cardinality while retaining warnings for missing or invalidated proofs. Allow
  required value-object argument guards.
- Distinguish awaited UI confirmation from awaited notifier results, and generated
  Freezed copyWith operations from repeated data-property reads.
- Keep `avoid_non_null_assertion` enabled by default. The overlapping
  `avoid_null_bang` rule remains available by explicit opt-in, so an unsafe null
  assertion produces one diagnostic with the default configuration.
- Scan debug-call matches in one pass instead of repeatedly copying source
  suffixes, preserving nested-call masking and exact diagnostic offsets.
- Require the Driver entrypoint only when Flutter Driver is used, recognize the
  documented `Crash` facade filename, and distinguish singleton instance members
  and one-off callback prose from static namespaces and protocol identifiers.

## [0.12.7] - 2026-09-24

- Use the analyzer type system to prove Container properties are non-null. Literal
  null, dynamic values and nullable generic bounds no longer trigger invalid-parent
  warnings; non-null generic bounds remain covered.
- Include the corrections documented below. The 0.12.6 publication was cancelled
  before upload after finding the nullability edge case; its tag is not rewritten.

## [0.12.6] - Unreleased

- Fix a 0.12.5 debounce regression: synchronous void notifier methods that launch
  or forward work warn again. Exempt only simple state assignments with trivial
  arguments, including imported methods; unknown bodies remain conservative.
- Fix a 0.12.4 layout regression: Expanded and Flexible under padded, constrained,
  or otherwise render-wrapping Containers warn again. Transparent Containers can
  lead to an outer parent; extracted/custom widget composition remains accepted.
- Check the actual initState execution context. Deferred SDK callbacks and adjacent
  methods no longer trigger nearby-read warnings; direct reads, immediately invoked
  closures and synchronous callbacks still report.
- Determine keepAlive families from their signatures rather than nearby required
  fields or method parameters.
- Preserve independent non-constant constructor allocations in duplicate-expression
  checks while retaining diagnostics for constant expressions and repeated reads.
- Add regression controls and real Flutter/Riverpod integration coverage for both
  accepted and rejected cases. Compare published versions to reproduce the two
  regressions rather than treating historical green CI as proof of correctness.

## [0.12.5] - 2026-09-23

- Keep assignment and increment targets out of duplicate-read suggestions while
  retaining diagnostics for repeated right-hand-side and null-asserted reads.
- Compare receivers as well as member declarations when detecting contradictory
  conditions, so comparisons across different objects are accepted.
- Limit text-field and slider debounce checks to their actual onChanged callback,
  including indented widgets. Accept resolved synchronous void notifier updates;
  retain warnings for async, async-void and unresolved calls. Other callbacks
  such as onSubmitted no longer contribute work to onChanged.

## [0.12.4] - 2026-09-23

- Recognize implicit null initialization for mutable nullable locals while
  retaining diagnostics for unassigned late and final locals.
- Recognize unconditional synchronous initialization of a State's own fields in
  initState for late-field and disposal checks; conditional, deferred, async,
  shadowed and other-instance assignments still report.
- Recognize Future.whenComplete and Riverpod Ref.onDispose cleanup tear-offs.
- Allow extracted and composed Flexible/Expanded widgets; retain diagnostics
  for known incompatible render-object parents.

## [0.12.3] - 2026-09-23

- Inspect Freezed class members structurally so factory-local object patterns and
  static helpers do not require private constructors; implemented instance
  getters and methods still do.
- Distinguish deferred arrow/block callbacks from immediate build mutations,
  including immediately invoked functions and a direct call after a callback
  on the same line.

## [0.12.2] - 2026-09-23

- Allow cleanup-only try/finally in widgets while retaining catch-boundary checks.
- Recognize map/index keys and core error parameter names as intentional literals.
- Preserve stateful widgets whose inherited members own mutable state or lifecycle.
- Allow Riverpod Consumer and HookConsumer builder subscriptions while retaining
  warnings for nested callbacks and unrelated builder APIs.

## [0.12.1] - 2026-09-23

- Allow direct Riverpod watches of resolved scalar values, including nullable
  scalars and enums, while retaining structured-state and identity-select checks.
- Allow generated notifier build methods to watch provider dependencies directly.
- Keep file-wide dot-shorthand fixes from rewriting unrelated diagnostics.
- Correct documentation lint-reference parsing around parenthetical examples.

## [0.12.0] - 2026-09-23

- Add `domain_raw_required_string`: Freezed domain entity constructors must not
  take non-nullable `String` parameters; use a validated Value Object, or
  `String?` for optional text.
- Add `domain_unit_primitive`: Freezed domain entity constructors must not carry
  unit- or currency-named numbers such as `lengthCm`, `weightKg` or `price`;
  use a Value Object or `Duration`.
- Constructors with `HiveField(N)` markers keep their locked primitive slots,
  matching the skill's shipped-Hive-entity exception.
- Both are errors, so existing apps with raw domain fields fail analysis after
  upgrading until those fields use Value Objects.

## [0.11.2] - 2026-09-14

- Avoid shorthand constructor fixes when an explicit generic type is narrower
  than the contextual type, preserving the constructed runtime type.

## [0.11.1] - 2026-09-14

- Make `prefer_dot_shorthands` use Dart's exact static namespace and independent
  context, avoiding invalid fixes for extension helpers and inferred generics.
- Use the flattened value context for async returns and safely rewrite explicit
  `new`, generic constructors, static methods, aliases, and selector chains.
- Add the IDE file-wide autofix and keep Freezed opt-outs and timer-debounce
  checks compatible with valid dot shorthand.

## [0.11.0] - 2026-09-14

- Require Dart 3.13 and prefer contextual dot shorthands through a first-party
  analyzer diagnostic and IDE quick fix.
- Replace the removed strict-cast and strict-raw analyzer flags with
  `no_dynamic_casts` and `no_raw_types`.
- Update to analyzer 14.4, analyzer_plugin 0.14.17,
  analysis_server_plugin 0.3.23, and analyzer_testing 0.4.2.

## [0.10.2] - 2026-09-08

- Removed the deprecated `avoid_private_typedef_functions` lint from the
  canonical Flutter skill configuration and its configuration contract.

## [0.10.1] - 2026-09-08

- Fixed the release verification order so Dart Decimate scans only the package
  checkout, before the isolated privacy-scanner runtime is fetched.

## [0.10.0]

- Updated the analyzer plug-in dependencies to the analyzer 14.3 family and
  verified them with the current Riverpod lint plug-in.

## [0.9.1] - 2026-08-16

- Replaced the unreachable Dart example entrypoint with a package usage README.

## [0.9.0] - 2026-08-15

- Updated to the shared analyzer 13.3.0 family with analyzer_plugin 0.14.12,
  analysis_server_plugin 0.3.18, and analyzer_testing 0.3.2 so this plug-in
  can share one analysis server with current `riverpod_lint 3.1.8`.
- Kept analyzer 14.1.0 as a rejected standalone candidate because its
  dependency family cannot solve with the current Riverpod analysis plugin.
- Migrated rules and tests to the current analyzer AST and plug-in APIs.
- Added `avoid_flutter_host_driver_imports` for keeping direct and transitive
  Flutter and app code out of pure integration-test host drivers.
- Added `avoid_unvalidated_persisted_map_cast` for checking persisted map keys
  before converting them to typed maps, including local datasource paths.
- Added workspace dependency-override checks. A nearby audit file does not
  exempt a dependency override.
- Removed analyzer exclusions from the active rule and example source trees.

## [0.8.1] - 2026-07-25

- Removed the deprecated `avoid_null_checks_in_equality_operators` lint from
  the required Flutter skill configuration and shipped configuration examples.

## [0.8.0] - 2026-07-15

- Added `presentation_widget_navigation_forbidden` to reject GoRouter imports,
  BuildContext routing extensions, typed-route calls, and Navigator calls from
  reusable files under `presentation/widgets/`.
- Added `presentation_widget_controller_state` to reject navigation stacks,
  selected domain records, workflow status, and provider-derived caches in
  reusable widget State while allowing UI lifecycle controllers and timers.
- Added `presentation_widget_infrastructure_dependency` to reject provider
  reads and direct repository, datasource, service, client, persistence, and
  backend SDK dependencies in reusable presentation widgets.
- Added valid and invalid analyzer fixtures for typed callback widgets, screen
  orchestration, UI lifecycle state, navigation, workflow state, and
  infrastructure access.

## [0.7.2] - 2026-07-03

- Added `use_hive_ce_flutter_import`: production Flutter `lib/` files now
  import Hive through `package:hive_ce_flutter/hive_ce_flutter.dart` instead of
  `package:hive_ce/hive_ce.dart`, while tests can still use direct `hive_ce`
  imports for temp-box setup.
- Updated the building-flutter-apps Hive guidance and diagnostic counts for the
  new rule.

## [0.7.1] - 2026-06-24

- Added `router_splash_waits_for_initial_sync`: flags splash redirect gates that
  hold the cover screen while `InitialSyncStatus.syncing` is in progress. Initial
  data sync is a background concern—once auth and setup state are known, route to
  the authenticated shell and let local data hydrate instead of blocking startup
  on the splash screen.

## [0.7.0] - 2026-06-14

- Added `full_collection_load_in_loop`: flags an awaited
  `getAll`/`fetchAll`/`loadAll`-style full-collection load inside a `for`/`while`
  loop body (an O(items × rows) N+1). Load once before the loop or add a batched
  lookup that resolves all keys in a single pass.
- Added `unguarded_fire_and_forget_platform_command`: flags fire-and-forget
  native/webview/media controller commands (`runJavaScript`, `playVideo`,
  `seekTo`, ...) that are neither awaited, captured, returned, nor error-handled.
  Their rejections escape to `PlatformDispatcher.onError` and are commonly
  misreported as fatal crashes; route them through an error-handling helper.
- Kept the analyzer stack on the Riverpod-compatible analyzer 12 line while
  promoting lint docs, tests, and examples to stable `riverpod_lint 3.1.4`.
- Reconciled additional-lint AST usage with the analyzer 12 APIs loaded by the
  shared plugin environment used with `riverpod_lint 3.1.4`.
- Fixed `avoid_unassigned_fields` and `avoid_unassigned_late_fields` so
  analyzer-12 field-formal wrappers and redirecting constructors do not create
  false positives.
- Removed ShowcaseView guided-tour lint support and docs, including
  `avoid_showcase_key_filtering`, `showcase_default_scope`,
  `showcase_dispose_on_tap`, `showcase_get_named_unhandled`,
  `showcase_prev_null_guard`, and `showcase_scope_string_literal`.
- Split large source-scanner rule/test files and the lint inventory docs while
  preserving 183 core diagnostics, 279 additional diagnostics, and 459 unique
  diagnostic codes.

- Added `app_shell_bootstrap_side_effects` to keep `MaterialApp` /
  `CupertinoApp` / `WidgetsApp` shell widgets declarative and move bootstrap
  `ref.listen` orchestration into a dedicated root bootstrap widget.
- Added `riverpod_listen_manual_forbidden`; `ref.listenManual` is now banned
  outright, replacing stale manual-listener lifecycle guidance.

- Added 9 dialog/sheet rules in `dialog_source_rules.dart`:
  `dialog_widget_subscribes_to_mutable_provider`,
  `modal_high_frequency_watch_not_leaf`,
  `dialog_button_pop_then_state_mutation`,
  `select_returns_unstable_record_identity`,
  `build_method_assigns_to_field`,
  `build_calls_mutating_instance_method`,
  `widget_calls_notifier_teardown_after_await`,
  `popscope_bypass_uses_go_not_pop`,
  `modal_helper_requires_route_settings`.
- Added `pop_fallback_helper_must_check_navigator_stack` for generic
  `BuildContext` pop fallback helpers that check only GoRouter's `canPop` and
  miss mounted/root/local Navigator checks.
- Added 20 runtime-bug rules in `runtime_bug_source_rules.dart`:
  `sync_save_all_no_dirty_guard`,
  `save_all_full_collection_after_subset_mutation`,
  `collection_getter_allocates_each_access`,
  `expando_derived_cache_forbidden`, `ad_hoc_id_index_lookup`,
  `linear_id_lookup_in_hot_path`, `nested_linear_lookup_by_id`,
  `appwrite_blocking_function_execution_in_client`,
  `destructive_failure_logged_before_reconcile`,
  `storage_clear_preserves_migration_state`,
  `notifier_persistence_no_debounce`, `webview_init_in_build_no_gate`,
  `service_storage_read_no_memo`,
  `keepalive_watches_unbounded_collection`,
  `datasource_missing_batch_loader`, `notifier_zero_value_save_no_guard`,
  `notifier_param_requires_value_object`, `text_field_on_changed_no_debounce`,
  `slider_on_changed_no_debounce`, `scroll_listener_no_throttle`.
- `service_singleton` now allows only plain fire-and-forget singletons (private
  constructor + `static final instance` / trivial getter + `void` / `Future<void>`
  public methods) and flags state/data APIs plus debug/fake/backend seams.
- `service_static_side_effect` now allows only tiny direct fire-and-forget SDK
  facades and flags returned data/state, clock/random helpers, wide facades, or
  backend/fake/debug/provider seams.
- Source scanner now blanks `debugPrint(...)` / `print(...)` call bodies before
  pattern matching so identifiers buried inside a log string never trigger a
  downstream rule. Diagnostic offsets stay aligned.
- Bumped Flutter skill rule count to 177, Flutter skill diagnostic count to 187,
  additional analyzer warning rule count to 238, and total unique diagnostic
  count to 463 after removing the obsolete `require_main_error_hooks` rule.

## [0.6.5] - 2026-05-14

- Added `riverpod_consumer_state_derived_cache` for provider-derived
  `ConsumerState` cache/source/day-start fields.
- Added `l10n_context_direct_access` and `datetime_now_requires_timezone_intent`
  for l10n binding and `DateTimeX` current-time intent.
- Added `avoid_magic_literals` for raw key/path/id/limit/date-window/threshold
  literals and comparisons.
- Added `avoid_inline_error_codes`, `avoid_local_contract_key_constants`, and
  `avoid_flutter_skill_lint_suppression` for contracts and suppressions.
- Bumped Flutter skill rule count to 125 and diagnostic count to 132.
- Bumped additional analyzer warning rule count to 85.

## [0.6.4] - 2026-05-14

- Extended direct-route API diagnostics to catch route-specific wrapper methods
  such as `router.goHome()`.
- Extended navigation wrapper/context escape diagnostics to catch helper calls
  such as `navigateToHomeRoute(router)` and router `navigatorKey.currentContext`.
- Extended manual provider detection to multiline and generic
  `Provider.family<...>` declarations.

## [0.6.3] - 2026-05-13

- Added route SSOT diagnostics for generated typed route helpers:
  `router_direct_route_call`, `router_raw_route_definition`,
  `router_context_navigation_extension`,
  `router_navigation_wrapper_api`, `router_modal_local_helpers`, and
  `router_container_navigation_escape`. App code calls generated typed route
  helpers directly; raw route definitions stay in the router boundary or the
  shared test router helper.
- Tightened `router_string_nav` so raw string and named route navigation are
  blocked outside test-host string-route fixtures.
- Added `riverpod_manual_provider` to enforce `@riverpod` / `@Riverpod`
  codegen over manual provider declarations.
- Bumped Flutter skill rule count to 122 and diagnostic count to 129.

## [0.6.2] - 2026-05-13

- Tightened `use_context_mounted_after_await` so `context.mounted` after an
  async gap only satisfies the guard when `context` is a function parameter or
  local variable captured before the gap. This catches `State.context` getter
  reads such as `if (!context.mounted) return;` after `await`, which can throw
  when the `State` has already been disposed. Capture with
  `final context = this.context;` before awaiting.

## [0.6.1] - 2026-05-13

- Patch release for packaging/documentation alignment:
  - Updated README, example, and project-config test snippets to state the
    current `riverpod_lint` prerelease pin accurately: latest stable is
    `3.1.3`; this package still tests against `3.1.4-dev.3` for Riverpod
    3.3-era lint coverage.
  - No lint rule behavior changes.

## [0.6.0] - 2026-05-13

- **BREAKING — VO subfolder renamed `/domain/value_objects/` → `/domain/values/`.**
  Path gates in 4 source-scanner rules (`vo_public_raw_constructor`,
  `domain_entity_primitive_factory`, `domain_custom_copy_with`,
  `freezed_disable_map_when_required`) and the `hive_field_no_vo_type`
  import-regex auto-extension now match `/domain/values/`. Consumers
  upgrading from 0.5.x MUST migrate:
  1. `mv lib/**/domain/value_objects lib/**/domain/values` per feature
     and `lib/core/domain/value_objects` → `lib/core/domain/values`.
  2. Rewrite imports: `domain/value_objects/` → `domain/values/`.
  3. Re-run `dart analyze`.
  Without the rename:
  - `vo_public_raw_constructor`, `domain_custom_copy_with`,
    `freezed_disable_map_when_required` silently stop firing on existing VOs
    (3 guards regress).
  - `hive_field_no_vo_type` loses auto-extension from the old import path
    (Hive Model VO leak undetected).
  - `domain_entity_primitive_factory` starts erroring on every public
    primitive factory in old-path VOs (false positives across the board).
  Caret `^0.5.x` does NOT auto-pick this release — bump constraint to `^0.6.0`
  after migrating.

## [0.5.7] - 2026-05-13

- Doc drift fix (tvly-verified vs hive_ce + pub.dev):
  - `hive-persistence.md`: replaced "infers HiveField(N) from ctor order"
    with `hive_adapters.g.yaml` SSOT mechanism. Migration table: rename =
    `⚠️ manual yaml edit` (was wrongly `✅`). Added rows for reorder + type
    change (both ❌, per official docs).
  - `value-objects.md` Hive-collision: same correction + link to hive_ce docs.
  - `freezed_disable_map_when_required` message now states `freezed_annotation
    ^3.1.0` floor (options removed in 3.0.0, re-added in 3.1.0).
- Added `freezed_disable_map_when_required` (ERROR) in
  `lib/src/rules/value_object_source_rules.dart`: sealed Freezed Value
  Objects in `/domain/values/` must annotate
  `@Freezed(map: FreezedMapOptions.none, when: FreezedWhenOptions.none)`
  to disable codegen of legacy `.map()`/`.maybeMap()`/`.when()`/`.maybeWhen()`
  methods. Those APIs bypass the sealed exhaustiveness check and are
  forbidden by Critical Rule 7. Native Dart 3 `switch` becomes the only
  pattern-matching surface. Catches bare `@freezed`, partial opt-out
  (one of map/when missing), and multi-line annotations. Non-sealed
  Freezed classes and files outside `/domain/values/` are
  unaffected.
- Bumped Flutter skill rule count to 115 and diagnostic count to 122.
- Added Hive persistence boundary rule in
  `lib/src/rules/hive_persistence_source_rules.dart`:
  - `hive_field_no_vo_type` (ERROR): in `/data/models/`, `@freezed`
    constructor parameters must not be typed as a Value Object. Catches
    nullable (`Distance?`), generic (`List<Distance>`,
    `Map<String, Money>`), and `show`-clause-imported VOs. Persistence
    Models hold primitives; VOs live on the domain Entity; the mapper
    bridges via `Distance.fromMeters(...)` in `toEntity()`.
- Extended `vo_public_raw_constructor` to also catch zero-touch
  passthrough public factories
  (`factory X.kilograms(double v) => X._kilograms(v);`) — same risk as a
  raw redirect: caller skips validation. Validated factories (`assert`,
  transform, throw) and parameterless redirects (`Distance.zero()`) stay
  legal.
- Sharpened `vo_public_raw_constructor` correction message: now shows
  the concrete `throw ArgumentError.value(...)` guard shape inline and
  explicitly calls out that passthrough factories are rejected.
  Previous message ("expose a validated public factory") was too soft —
  LLMs ticked the "private redirect" box and added a passthrough,
  thinking the diagnostic was about naming. New message bakes the
  validation requirement into the example. Title rephrased from "Value
  Object raw constructors must be private" to "Value Object public
  factory must validate, not just forward."
- `references/value-objects.md` Forbidden section gains an explicit
  passthrough anti-pattern block + two corrective shapes: inline
  guards in the factory body, and an extracted `_guard()` helper (still
  passes the lint because the body is a function call, not bare arg).
- `SKILL.md` Critical Rule 12 rewritten to require explicit guards in
  the public factory body and to call out passthrough as rejected.

- Skill doc fixes:
  - `references/value-objects.md` Forbidden section gains a Hive collision
    block + corrective shapes (Option A: entity stays primitive, VO via
    getter; Option B: separate persistence Model + domain Entity with
    mapper).
  - `references/hive-persistence.md` adds a *VO Interop* section, includes
    it in the Contents TOC, and corrects the `@GenerateAdapters` example
    to register persistence Models (`UserModel`/`OrderModel`) rather than
    domain entities. Aligns with the file's own Recap rule #3.
  - `SKILL.md` Critical Rule 12 gains a Hive collision caveat: do not
    change ctor param types on `@GenerateAdapters`-registered classes
    with shipped user data; expose VOs via entity getter instead.
- Added three Value Object boundary rules in
  `lib/src/rules/value_object_source_rules.dart`:
  - `vo_public_raw_constructor` (ERROR): in `/domain/values/`, a
    redirecting factory of the form `const factory X.<name>(...) = _Impl;`
    must use a private redirect name (`._meters`, `._raw`). Public callers
    skip validation otherwise — every VO must travel through a validated
    factory.
  - `domain_entity_primitive_factory` (ERROR): in `/domain/` outside
    `/domain/values/`, a `@freezed` entity must not own named
    factories (`factory User.fromPrimitives(...)`). Primitive → VO
    conversion lives in data models, notifiers, or import services so
    the entity remains unrepresentable in invalid state.
  - `domain_custom_copy_with` (ERROR): no hand-written `copyWith` in
    `/domain/`. Let Freezed generate it from the redirect — drift
    between author intent and generated semantics (nullability,
    sentinels, equality) silently breaks callers otherwise.
- Cross-references SKILL.md Critical Rule 12 and
  `references/value-objects.md`.

## [0.5.6] - 2026-05-13

- Rewrote `arch_domain_import` correction message to guide users toward
  Value Objects (sealed Freezed class in `/domain/values/`) for
  shared primitive logic and entity getters for one-off derivations.
  Old message ("Move Flutter/package dependencies out of domain
  entities") was misleading — pure-Dart `core/extensions/` imports are
  also blocked, by design. Cross-references SKILL.md Critical Rules 11
  and 12.

## [0.5.5] - 2026-05-12

- Added `avoid_run_zoned_guarded` (AST rule) to flag `runZonedGuarded(...)`
  calls. Startup should stay simple: initialize Firebase/Crash with
  `await Crash.init()` before `runApp(...)`, not by wrapping the app in a
  zone. Catches direct calls and aliased `import 'dart:async' as a;` calls.
- Bumped Flutter skill rule count to 109 and diagnostic count to 116.

## [0.5.4] - 2026-05-12

- Added `router_gorouter_of` to flag `GoRouter.of(context).{go,push,replace,
  pushReplacement,goNamed,pushNamed,replaceNamed}` calls. Typed routes
  (`const FooRoute(...).push<T>(context)` / `.go(context)`) are the SSOT
  for navigation — they survive route renames and stay refactor-safe.
- Added `router_untyped_navigator_push` to flag
  `Navigator.{push,pushReplacement,pushAndRemoveUntil}` (incl.
  `Navigator.of(context).…`) when paired with `MaterialPageRoute`,
  `CupertinoPageRoute`, or `PageRouteBuilder`. Use a typed `@TypedGoRoute`
  then `const FooRoute(...).push<T>(context)`.
- Bumped Flutter skill rule count to 108 and diagnostic count to 115.
- Refreshed README example, `doc/building-flutter-apps-lint-coverage.md`,
  and `references/common-patterns.md` Critical Rules + Navigation
  anti-pattern block.

## [0.5.3] - 2026-05-12

- Added `riverpod_feature_notifier_keepalive` to flag non-family feature
  presentation notifiers that auto-dispose without an explicit ephemeral-state
  rationale.
- Extended the gated plugin smoke to assert the new diagnostic in a temporary
  Flutter app loaded through the Dart analyzer plugin system.

## [0.5.2] - 2026-05-12

- Added `avoid_mounted_check_in_finally` to flag
  `if (!ref.mounted) return;` (and `context.mounted` / bare `mounted`)
  shapes inside `finally` blocks. `return;` in `finally` swallows
  in-flight exceptions from the `try` body. Ships a quick-fix that
  rewrites the early-return into an `if (mounted) { ... }` guard around
  the trailing statements.
- Bumped additional analyzer rule count to 81 and quick-fix count to 64.
- Refreshed README counts and `doc/building-flutter-apps-lint-coverage.md`
  to list the new rule.

## [0.5.1] - 2026-05-11

- Removed stale `flutter_skill_lints` version pins from README, example
  analysis options, and project-config test fixtures. The plugin block now
  matches the companion skill's unpinned `flutter_skill_lints` setup while
  keeping the documented `riverpod_lint` prerelease pin.
- Clarified that `dart analyze` is the analyzer/plugin gate and can report
  project-config drift through Dart analysis units, but does not replace
  `flutter pub get` or pub.dev package validation for complete `pubspec.yaml`
  checks.
- Refreshed coverage docs to the current registered surface: 105 Flutter-skill
  warning rules, 112 Flutter-skill diagnostic codes, 80 additional warning
  rules, 63 fixes, and 1 assist.
- Updated `flutter_skill_project_config` wording from validation language to
  drift-reporting language; behavior is unchanged.

## [0.5.0] - 2026-05-11

- Added `router_complex_extra` to flag GoRouter typed-route `$extra`,
  `GoRouterState.extra` reads, and direct `extra:` navigation payloads.
  Route state must survive serialization, redirects, reloads, and modal
  pops; pass stable IDs or configure an explicit `extraCodec` instead.
- Bumped Flutter skill warning rule count to 105 and diagnostic code
  count to 112, and refreshed README plus
  `doc/building-flutter-apps-lint-coverage.md` to list the new rule.

## [0.4.0] - 2026-05-10

- Added analyzer diagnostics for the remaining Dart-source drift checks:
  `riverpod_select_arrow_syntax`, `riverpod_mutation_experimental_warning`,
  `arch_repository_generated_extends`, and `state_freezed_nullable_error`.
- Tightened `riverpod_keepalive_family` so codegen family providers with
  positional `Ref ref, value` parameters are reported, not only providers with
  `required` named parameters.
- Added `riverpod_auto_dispose_keepalive_dependencies` to flag computed
  auto-dispose providers whose same-file watched dependencies are all known
  `keepAlive`, matching the `building-flutter-apps` provider decision tree.
- Allowed documented `@Riverpod(keepAlive: true)` family workarounds for the
  open Riverpod TickerMode assertion issue `rrousselGit/riverpod#4709`.
- Added extra false-positive coverage for non-Riverpod `select` APIs,
  keep-alive providers without family arguments, generated notifier classes,
  Riverpod-generated provider classes named `*Repository`, Freezed DTOs with
  nullable error fields, non-notifier/qualified `Mutation<T>` usages,
  `Mutation<T>` declarations, and `runZonedGuarded` declarations/comments.
- Documented that non-Dart drift checks remain owned by `check_drift.sh`/CI
  because analyzer plugin diagnostics attach to Dart analysis units.

## [0.3.0] - 2026-05-10

- Expanded the Flutter skill analyzer surface with extended architecture,
  Freezed, routing, Flutter optimization, persistence, crash reporting,
  service, mixin, state, UI, and test diagnostics.
- Added `use_unawaited_for_fire_and_forget_futures` and broadened project
  configuration checks for analyzer plugins, strict analysis, generated-file
  excludes, Freezed annotation ignores, `explicit_to_json`, prohibited lint
  plugin dependencies, and deterministic Flutter Driver entrypoints.
- Tightened migrated `many_lints`-style coverage with additional false-positive
  tests, source scanner regression tests, and updated rule registration.
- Refreshed README rule counts, example configuration, and lint coverage
  documentation for the expanded diagnostic set.

## [0.2.0] - 2026-05-07

- Documentation pass: rewrote `README.md` for faster onboarding, added a Quick
  Start with copy-paste `analysis_options.yaml`, a tighter rule-group table,
  and a Troubleshooting section.
- Fixed the license badge link in the README.

## [0.1.1] - 2026-05-07

- Added `avoid_constant_switches`, a dead-logic warning for `switch`
  statements and expressions that switch on literals, const variables, or
  static const fields.
- Added automatic release tagging after successful `main` CI, followed by
  tag-based pub.dev publishing and GitHub Release creation.
- Split the migrated scanner surface into one registered analyzer rule per
  diagnostic ID, matching `many_lints`' specific rule-registration style.
- Re-ran the `many_lints 0.4.0` inventory audit, added the remaining allowed
  rules from `many_lints`, including `prefer_class_destructuring`, and kept the
  configured false-list diagnostics, including Cubit suffix checks, out of the
  default Flutter skill profile.

## [0.1.0] - 2026-05-06

- Initial analyzer plugin scaffold.
- Added Flutter skill rules for Riverpod async safety, mounted guards,
  legacy Riverpod APIs, dynamic/null-bang usage, widget helper methods,
  `shrinkWrap`, GoRouter pop guards, Freezed class shape, route-param
  throws, repository initialization, and synchronous notifier initialization.
- Added additional Dart/Flutter analyzer coverage inspired by `many_lints`: 79
  default warning rules, 61 fixes, and 1 assist.
- Added migrated Dart-source checks from the Flutter skill scanner.
- Added `flutter_skill_project_config` so stale analyzer configuration and
  `build.yaml` JSON settings report through analyzer diagnostics.
- Added a gated Flutter integration smoke with `riverpod_lint 3.1.4-dev.3`.
