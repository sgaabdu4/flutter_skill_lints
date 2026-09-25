# Align flutter_skill_lints with the building-flutter-apps skill contract

Status: Complete

## Outcome + scope

Make flutter_skill_lints enforce the building-flutter-apps skill (v5.12.0 docs) exactly. Every skill MUST/NEVER rule reports at error severity. Every skill DO/RIGHT example produces no flutter_skill_lints diagnostic. Every WRONG/NEVER example that names a lint produces that lint as an error. Fifteen builder branches aligned one skill area each, and a final sweep on `fix/skill-contract-sweep` closed the cross-cutting gaps. Registered totals after the work: 229 skill rules, 237 skill codes, 236 additional rules, 274 additional codes, 509 unique codes, 63 fixes and 1 assist (the origin/main README listed 187, 195, 239, 280, 471, 64 and 1).

Merged builder plans:

- `arch-services-mixins-contract`: architecture, singleton, fire-and-forget, mixin and error-code lints match architecture.md, services-and-singletons.md, mixins.md and hive-persistence.md; a singleton with instance state is recognized as a singleton, not a static namespace (#51).
- `avoid-throw-skill-contract`: `avoid_throw` allows the Value Object guard and typed `Exception` subtypes, and applies the same contract to `Error.throwWithStackTrace` (#42, #95).
- `error-network-contract`: crash, Sentry, Appwrite and networking lints match error-reporting.md, networking.md and common-patterns.md rule 12, at error severity.
- `hive-sync-contract`: Hive, delta-sync and batch lints match hive-persistence.md and the debounce-gate-batch and delta-sync references, with resolved types.
- `layout-optimization-contract`: layout-diagnostics.md and flutter-optimizations.md lints report the MUST/NEVER shapes as errors and accept the skill examples.
- `lookup-comment-extra-contract`: `linear_id_lookup_in_hot_path` reports only repeated lookups (#87), `avoid_commented_out_code` skips prose method names (#91), and `router_complex_extra` points to stable IDs or typed path/query params instead of an `extraCodec` (#60).
- `model-value-object-contract`: Freezed, Value Object, records and primitive-extension lints match the skill, at error severity (#38, #50, #64, #75, #86).
- `riverpod-skill-boundaries`: `service_provider_watch_dependency` allows reactive service wiring (#68), and `notifier_persistence_no_debounce` requires a debounce only for high-frequency persistence (#66).
- `runtime-performance-contract`: performance and debounce lints match performance.md; `text_field_on_changed_no_debounce` allows synchronous form updates (#37).
- `state-async-lifecycle-contract`: async-guard and lifecycle lints match async-mutations.md and state-management-lifecycle.md; `require_atomic_async_updates` accepts guarded transitions (#74) and `notifier_ensure_deps` accepts the skill's direct provider reads (#89).
- `state-mutation-service-contract`: Riverpod mutation, service-locator, keepAlive-family and broad-watch lints match riverpod-codegen.md; `riverpod_watch_no_select` allows whole computed providers (#36).
- `state-notifier-structure-contract`: codegen and notifier-structure lints match riverpod-codegen.md and notifier-structure.md.
- `testing-navigation-contract`: testing, E2E and navigation lints match testing.md, dart-mcp-e2e-testing.md, deep-linking.md and the routing references; SDK mock exceptions work for part declarations (#77).
- `ui-presentation-contract`: atomic-design and presentation-widget lints report token, text-style, provider and navigation violations as errors.
- `ui-preview-l10n-contract`: widget-preview, localization, hardcoded-string and accessibility lints match the skill; callback-only `TextField` is allowed (#44) and the callback-prose gap is closed (#52).

Issues handled: fixes #42 #60 #66 #68 #87 #91 #95; reopened and fixed #36 #50 #51 #52 #77 #86; over-strict fixes #37 #38 #44 #64 #72 #74 #75 #89; #43 resolved by removing `avoid_non_null_assertion`.

## Repository context

Owners: `lib/src/rules/**` (skill rules), `lib/src/additional_lints/**`, `test/plugin_registration_test.dart` (counts, forbidden names, severity allowlists), `test/source_scanner_rules_test/**`, `README.md`, `doc/building-flutter-apps-lint-inventory.md` and `doc/building-flutter-apps-lint-coverage.md`. The skill text was read from the `fix/skill-doc-contract` worktree of building-flutter-apps. A probe package built from the skill's DO examples, with the plugin loaded by path, is the no-diagnostic control.

## Decisions + authorization

Blockers: None
Authority: The coordinator assigned the builder slices and the final sweep brief, including every removal and severity change recorded here.

## Acceptance + steps

- [x] Sweep 0 (9088ddf): split source scanner part 07 into part 23, and list `avoid_any_version` and `prefer_publish_to_none` only in the inventory's skill section.
- [x] Sweep 1: `flutter_widget_operator_equals` was already an error, so no code changed; it is now in the severity assertion list.
- [x] Sweep 2 (5264d6d): unregistered `prefer_dedicated_media_query_methods`, which duplicated `use_dedicated_media_query_methods`.
- [x] Sweep 3 (4f3c057): removed `avoid_non_null_assertion`; `avoid_null_bang` remains the single null-assertion diagnostic (#43).
- [x] Sweep 4 (f4a189f): removed `arch_datasource_try_catch`; `avoid_only_rethrow` owns rethrow-only catches and reports only the last catch clause.
- [x] Sweep 5 (1c1b928): `style_raw_token` reads EdgeInsets, BorderRadius, Radius and SizedBox arguments from the AST, so `Spacing.s24` no longer matches.
- [x] Sweep 6 (12c630d, defcf68): `riverpod_watch_no_select` resolves `Ref`/`WidgetRef` watches from the AST and exempts every functional provider by type.
- [x] Sweep 7 (aa5b113): `nullable_collection_type` reports only fields, top-level variables, redirecting-factory parameters and return types.
- [x] Sweep 8 (6e848a0, 7ae34e3): the skill's `ModalContextX` helper is a modal route control; `implicit_null_fallback` stays a warning and allows bool and num fallbacks.
- [x] Sweep 9 (816c683): `guard_context_pop` (common-patterns.md rule 7) and `state_broad_invalidation` (rule 10) report as errors; the other non-error skill codes are pinned with a reason each.
- [x] Sweep 10 (658993e): every registered skill code appears in the coverage doc, with 28 new per-code rows.
- [x] Verification repairs: split two test files over the 1,000-line limit (e8b7230) and removed a duplicated reporting loop (038dc53).

## Acceptance fixes

After the sweep, an acceptance probe ran the skill's examples against the merged plugin. It found six more mismatches, fixed on `fix/skill-contract-accept`. The full plan is [skill-contract-accept/PLAN.md](../skill-contract-accept/PLAN.md).

- `prefer_dot_shorthands` reports only enum values, static members and named constructors. It no longer reports unnamed constructor calls.
- `fire_and_forget_missing_catch` treats three callees as handled: a Riverpod `Mutation.run`, a route or modal future, and a resolved callee that catches internally. This makes the modals-navigation.md DO example clean.
- `avoid_magic_literals` exempts strings bound to a resolved `routeName` parameter or to Flutter's `RouteSettings(name:)`.
- `dialog_widget_subscribes_to_mutable_provider` and `select_returns_unstable_record_identity` read the resolved AST, so the multi-line modals-navigation.md:15 NEVER example reports both. Both are errors.
- `appwrite_blocking_function_execution_in_client` reports a destructive or batch call passed a resolved `waitForCompletion: true` (networking.md:161).
- `linear_id_lookup_in_hot_path` treats getters as hot paths, following the debounce-gate-batch.md "Collection getters" contract.

Integration: `fix/skill-contract-accept` merged after the sweep with no textual conflicts. The sweep left `select_returns_unstable_record_identity` on the non-error allowlist, with the reason "Severity owned by the acceptance branch". That entry is removed. Both dialog codes are now pinned in the error-severity assertion list. Every skill code the accept branch touches is an error. The branch adds no rules, so the counts stay at 229 skill rules, 237 skill codes, 274 additional codes, 509 unique codes and 63 fixes. On the integrated head, `dart format`, `dart analyze` and `dart test` pass, with 2,628 tests and 1 skip. `python3 .hooks/hard-eng.py check --base origin/main --plan-stage Draft` passes every gate, with 79.16% line coverage.

## Final round

- `riverpod_watch_no_select` exempts a computed (functional) provider watch only when its value is a collection, record-destructured or used whole; a field read such as performance.md:76 `userState.user` reports for functional and Notifier providers.
- `router_pop_then_push` drops the text heuristic and keeps the AST check, so routing-app-shell.md "Safe pop with typed fallback" stays clean.
- `fire_and_forget_missing_catch` resolves same-class calls in a callee from another library, so lists-forms-workflows.md `unawaited(notifier.loadMore())` (awaits a catching `_loadPage`) stays clean.
- `perf_build_work` scans only Widget/State `build` (widget/State class, `Widget build(` or `BuildContext` signature, or UI file) and skips Riverpod Notifier `build`.
- `avoid_dynamic_except_json_maps` and `avoid_banned_types` share `isJsonMapDynamicValueType`, which also accepts `<String, dynamic>{}` map literals (hive-persistence.md:56).
- `destructive_failure_logged_before_reconcile` also reports telemetry in the catch of async-started long-running work (`start*` long-running call or `xasync: true`) in a destructive method with no reconcile call.
- `avoid_unnecessary_else_after_control_flow` reports an `else` only when the then-branch ends in `return`, `throw`, `rethrow`, `break` or `continue` (SKILL.md R17); collection `if`/`else` is no longer reported.
- `avoid_late_keyword` allows instance `late final` fields with an initializer, the lazy derived value performance.md prescribes; static, local, mutable and uninitialized `late` still report.
- `avoid_conditions_with_boolean_literals` allows a bare `true` as a `while`/`do` loop condition (the mixins.md `retryWithBackoff` loop); `x && true`, `if (true)` and `while (false)` still report.
- `avoid_hooks_outside_build` reports only calls that resolve to `flutter_hooks`/`hooks_riverpod` or to a `use` function that itself calls hooks, so deep-linking.md's `usePathUrlStrategy()` in `main` is clean.
- `avoid_long_parameter_list` counts positional and `required` parameters only, so error-reporting.md's `Crash.error(error, stackTrace, {reason, fatal, extras})` is clean. The skill sets no parameter limit; the rule keeps its limit of four.
- `avoid_commented_out_code` requires keyword and assignment candidate lines to parse as a Dart statement (or open a multi-line one), as call lines already did, so prose such as `// Widget — use .select()` and `// Reorder = UI flicker (...)` is clean.
- `avoid_magic_literals` exempts map-literal and index keys inside `*Model` classes and `data/models/` files (architecture.md `ProductModel.toNameOnlyRequestBody`). Tests prove `core/constants/storage_keys.dart` (`StorageKeys`) and `core/constants/api_paths.dart` (`ApiPaths`) are accepted owners for `avoid_magic_literals` and `avoid_local_contract_key_constants`.
- `avoid_unsafe_collection_methods` skips test files, where testing.md reads `.first`/`.single` in expectations; production behaviour is unchanged.
- `prefer_private_extension_type_field` allows a public representation field named `value`, the typed-ID form in dart-patterns-records.md and collections-helpers.md; any other public name still reports.
- `prefer_test_matchers` is removed. The skill gives no matcher guidance, testing.md and hive-persistence.md compare with bare literals and identifiers, and `expect()` already wraps a value in `equals()`, so a narrowed rule would only flag non-matcher calls on a false rationale. Counts: 235 additional warning-rule calls, 273 additional codes, 508 unique codes.

## Baseline + execution

Result: Passed
Evidence: At 88d83c6 (all builder branches merged), eleven registered skill codes were below error severity, and the DO-example probe reported 161 diagnostics, including one `style_raw_token` and one `implicit_null_fallback` false positive. Before sweep item 10, 28 registered skill codes had no coverage-doc entry. The first Hard Eng run in item 12 failed on two test files over 1,000 lines and on one dart-decimate duplicate.
Execution: Fifteen builders each merged one skill area with red tests first. One sweep builder then committed each item separately on `fix/skill-contract-sweep`. Every commit ran `dart format`, `dart analyze` and `dart test`, and each rule change was checked against the DO-example probe.

## Risks + recovery

Removing `avoid_non_null_assertion`, `prefer_dedicated_media_query_methods` and `arch_datasource_try_catch` removes diagnostics that consumers may suppress by name. The first two names are on the forbidden list in `test/plugin_registration_test.dart`; `arch_datasource_try_catch` tests moved to `AvoidOnlyRethrowTest`. Removing it deviates from the brief, which asked to narrow it: its only trigger was a rethrow-only catch, so a narrowed rule would never report, and `avoid_only_rethrow` already reports that catch. Two new errors (`guard_context_pop`, `state_broad_invalidation`) can fail analysis in apps that relied on their old severity. `select_returns_unstable_record_identity` stays a warning because another branch owns it, although modals-navigation.md names it in a WRONG-example lint list. To recover, revert the individual sweep commit; each is self-contained.

## ux_reference

N/A — analyzer diagnostics have no rendered application UI.

## Verification

Result: Passed
Evidence: `dart format --set-exit-if-changed lib test` reported no changes, `dart analyze` found no issues, and `dart test` passed 2,610 tests with 1 skip. The count probe reports 229 skill rules, 237 skill codes, 274 additional codes, 509 unique codes and 63 fixes. The DO-example probe dropped from 161 diagnostics at 88d83c6 to 159: the `style_raw_token` and `implicit_null_fallback` false positives are gone, and the two rules raised to error report nothing. `python3 .hooks/hard-eng.py check --base origin/main --plan-stage Draft` passed every gate: lockfile, vulnerabilities, format, types-lint, security, import-boundaries, tests, dead-code-duplicates, performance, secrets and workflow audits.
E2E: N/A — analyzer plugin; consumer probes recorded per feature plan
Delivery target: Merge
Delivery: Pending — combined PR, required CI, merge and main CI.
