# Changelog

## [Unreleased]

- Added `full_collection_load_in_loop`: flags an awaited
  `getAll`/`fetchAll`/`loadAll`-style full-collection load inside a `for`/`while`
  loop body (an O(items × rows) N+1). Load once before the loop or add a batched
  lookup that resolves all keys in a single pass.
- Added `unguarded_fire_and_forget_platform_command`: flags fire-and-forget
  native/webview/media controller commands (`runJavaScript`, `playVideo`,
  `seekTo`, ...) that are neither awaited, captured, returned, nor error-handled.
  Their rejections escape to `PlatformDispatcher.onError` and are commonly
  misreported as fatal crashes; route them through an error-handling helper.

## [0.7.0] - 2026-06-14

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
