# Riverpod skill boundaries

Status: Complete

## Outcome + scope

Align two Riverpod lints with the building-flutter-apps skill. `service_provider_watch_dependency` (#68) must allow a service or client factory to watch reactive state or config, and still report watches of stable infrastructure providers. `notifier_persistence_no_debounce` (#66) must require a debounce only for persist helpers reached from synchronous or repeated mutation paths. Awaited one-shot lifecycle writes are out of scope for the rule. Two follow-up gaps: `service_provider_watch_dependency` must also report a Riverpod notifier member, including `build()`, that watches stable infrastructure (`async-mutations.md` read-first rule 3, `riverpod-codegen.md` rule 3). A new error rule, `riverpod_config_destructuring`, enforces `riverpod-codegen.md` rule 4, "MUST use destructuring for clean config access".

## Repository context

Owners: `lib/src/rules/services_extended_source_rules.dart` (#68) and `lib/src/rules/runtime_bug_source_rules.dart` with its `part_01` scan (#66). Tests: `ServiceProviderWatchDependencyTest` in `test/source_scanner_rules_test/source_scanner_rules_part_19.dart` (moved from `part_11`, which would otherwise exceed the 1,000-line limit) and `NotifierPersistenceNoDebounceTest` in `source_scanner_rules_part_18.dart`. Skill sources: `riverpod-codegen.md` rules 3 and 4 with the config -> client -> services pattern, `state-management/async-mutations.md` read-first rule 3, `services-and-singletons.md` rule 7, and `performance.md` rule 16 plus "Debounce full-state persistence". `riverpod_config_destructuring` lives beside `service_provider_watch_dependency` in `services_extended_source_rules.dart`. Its tests are `RiverpodConfigDestructuringTest` in `source_scanner_rules_part_11.dart`. Registration counts are in `test/plugin_registration_test.dart`, `README.md` and `doc/building-flutter-apps-lint-coverage.md`, and the name is in `doc/building-flutter-apps-lint-inventory.md`.

## Decisions + authorization

Blockers: None
Authority: Autonomous lint repair on a scoped branch. No CHANGELOG, version, push or other rules.

- #68: classify the resolved value type of each `ref.watch(...)` invocation. Unwrap `Future`, `Stream` and riverpod `AsyncValue`, then apply the same stable-infrastructure classification the rule already uses for the factory's return type (name classification plus the resolved Appwrite `Service` base). If the watched value is a resolved type outside that classification, the watch is reactive state or config and is allowed. Unresolved, `dynamic` and `Object` values stay reported. Every `ref.watch` on a line is now checked, not only the first one.
- #66: resolve each persist helper's uses to the declared method element, so a lookalike local function does not count. A use qualifies as a mutation path when it is a tear-off, sits in a synchronous body, or sits in an async body that writes `state` without first awaiting another result. A helper called only from another helper inherits that helper's verdict. A helper with no resolved uses in its class stays reported, as before. The rule has no name or `*Id` exemptions.
- Notifier members: a `ref.watch(...)` inside a class whose resolved supertypes include riverpod's `AnyNotifier` reports only when its resolved value passes the same stable-infrastructure classifier. Unresolved values are not reported, because `build()` legitimately watches state and data. The storage argument of riverpod's `persist(...)` extension method is allowed, because the skill's `riverpod-codegen.md` persist example watches `storageProvider.future` in `build()`.
- `riverpod_config_destructuring` (ERROR): a local initialized from `ref.watch(...)` or `ref.read(...)`, optionally awaited, whose resolved type is a class named `*Config` (the skill's config -> client -> services convention) reports when every resolved use of the local is a getter read. A local passed whole, called, reassigned or unused does not report, and the skill's `final BackendConfig(:endpoint, :apiKey) = ...` pattern is allowed. The correction also offers an inline single-field read, so the fix does not trip `avoid_single_field_destructuring`.
- Owner decision: rules that enforce a skill MUST/NEVER rule are errors. `notifier_persistence_no_debounce` moves from warning to `ERROR`, and `service_provider_watch_dependency` stays `ERROR`.

## Acceptance + steps

- [x] The #68 reproduction, a watched `Provider<String>` credential, is allowed. A client rebuilt from a watched `Future<AppConfig>` config is allowed.
- [x] Watching a stable client beside a reactive credential reports only the client watch. `AsyncValue<Datasource>` and `Future<appwrite.Account>` watches report.
- [x] The #66 reproduction (awaited create/reuse handle writes) is allowed, and so is a state write after an awaited lifecycle result.
- [x] A lookalike local `_persist*` function in a setter is not treated as the helper.
- [x] Async `setTheme` (state write, then awaited persist) and synchronous `updateDraft` still report, and so do the existing true positives.
- [x] An `AsyncNotifier.build()` watching a repository provider reports, and so does a notifier getter watching `repositoryProvider.future`. Notifier watches of state, data and config providers, the `persist(ref.watch(storageProvider.future))` shape and a lookalike local `AnyNotifier` base are allowed.
- [x] `final config = ref.watch(backendConfigProvider)` read only through properties reports, and so does an awaited `ref.read` of a config. The skill's destructured shape, a config passed whole, a config method call, an unused config local and a non-config local are allowed.
- [x] Registration counts and docs list 188 skill rules, 196 skill codes and 472 unique codes.

## Baseline + execution

Result: Passed
Evidence: Red first. 4 new #68 tests and 3 new #66 tests failed on `origin/main` (b0878e9) before the fixes.
Current baseline: `dart format` made no changes, `dart analyze` found no issues, and `dart test` passed 2,161 tests (1 skipped).
Execution: One builder. Commit cc291d5 contains the #68 fix and tests; commit 89a9843 contains the #66 fix, tests and descriptions. A follow-up commit splits the helper resolution to stay within the dart-decimate complexity budget and raises the #66 severity to error.
Follow-up: A second builder added the notifier-member path (5c82fd1) and `riverpod_config_destructuring` with counts and docs (8e661d9, 5c5afe8). Red first: the notifier repro test and, before the persist check existed, the persist control failed. All four new `RiverpodConfigDestructuringTest` cases failed before the rule was registered.

## Risks + recovery

- #68 depends on resolved types. Before codegen runs, providers are unresolved, and the rule reports as it did before.
- A config type whose name matches the stable-infrastructure classification, such as `ClientConfig`, is still treated as infrastructure. This follows the rule's existing classification.
- #66: an async state-writing method that awaits another result before persisting counts as a lifecycle write. Revert commits cc291d5, 89a9843 and 4ad8842 to restore the previous behavior.
- A watched value whose static type is a record or function type, not an interface type, is still reported in a stable factory. This follows the existing classification.
- Notifier members: before codegen, `_$X` is unresolved, so the class is not classified as a notifier and nothing reports. A state type whose name matches the infrastructure classification, such as a `SyncQueue` state class, would report. This follows the existing classification.
- `riverpod_config_destructuring` relies on the `*Config` class-name convention and on the literal `ref.watch(`/`ref.read(` receiver name. A config held under another suffix is not checked. Revert 8e661d9 and 5c5afe8 to remove the rule. Revert 5c82fd1 to restore factory-only watch checks.
- The skill's own `hive-persistence.md` repository factory watches `orderLocalDatasourceProvider.future`, which the factory path reports. This is a skill-side inconsistency, and the rule is left unchanged.

## ux_reference

N/A — analyzer lint change; no app surface.

## Verification

Result: Passed
Evidence: Focused suites passed: 20 `ServiceProviderWatchDependencyTest`, 4 `RiverpodConfigDestructuringTest` and 10 `NotifierPersistenceNoDebounceTest` cases. The full suite passed 2,161 tests (1 skipped). `dart analyze` found no issues and format made no changes. The full native Draft hard-eng gate passed, including dead-code-duplicates. Actual diff reviewed.
E2E: Passed — `probe-riverpod-skill-boundaries` (Riverpod 3.4.3 with riverpod_generator codegen) was analyzed against this worktree. It reported `service_provider_watch_dependency` only for the watch of the stable `httpApiClientProvider` (api_service_providers.dart:62). It reported `notifier_persistence_no_debounce`, at error severity, only for `ThemeNotifier._persistTheme` and `DraftNotifier._persistDraft`. The #68 credential watch, the live config watches, the #66 `ResourceNotifier` lifecycle writes and the lookalike local function were not reported. Follow-up: `probe-riverpod2` (the same stack with codegen) reported, at error severity, only `service_provider_watch_dependency` at products_notifier.dart:15 (`ProductsNotifier.build` watching `productRepositoryProvider`) and `riverpod_config_destructuring` at backend_providers.dart:39 (`uploadClient`). The skill's destructured `backendClient`, the whole-config `analyticsClient`, the `VisibleProducts` state, data and config watches, and the `RecentProductIds` `persist(ref.watch(storageProvider.future))` were not reported.
Delivery target: Merge
Delivery: Pending — scoped PR, required CI, merge and main CI.
