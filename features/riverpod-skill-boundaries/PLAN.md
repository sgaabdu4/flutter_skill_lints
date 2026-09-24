# Riverpod skill boundaries

Status: Complete

## Outcome + scope

Align two Riverpod lints with the building-flutter-apps skill. `service_provider_watch_dependency` (#68) must allow a service or client factory to watch reactive state or config, and still report watches of stable infrastructure providers. `notifier_persistence_no_debounce` (#66) must require a debounce only for persist helpers reached from synchronous or repeated mutation paths. Awaited one-shot lifecycle writes are out of scope for the rule.

## Repository context

Owners: `lib/src/rules/services_extended_source_rules.dart` (#68) and `lib/src/rules/runtime_bug_source_rules.dart` with its `part_01` scan (#66). Tests: `ServiceProviderWatchDependencyTest` in `test/source_scanner_rules_test/source_scanner_rules_part_11.dart` and `NotifierPersistenceNoDebounceTest` in `source_scanner_rules_part_18.dart`. Skill sources: `riverpod-codegen.md` rule 3, `services-and-singletons.md` rule 7, and `performance.md` rule 16 plus "Debounce full-state persistence".

## Decisions + authorization

Blockers: None
Authority: Autonomous lint repair on a scoped branch. No CHANGELOG, version, push or other rules.

- #68: classify the resolved value type of each `ref.watch(...)` invocation. Unwrap `Future`, `Stream` and riverpod `AsyncValue`, then apply the same stable-infrastructure classification the rule already uses for the factory's return type (name classification plus the resolved Appwrite `Service` base). If the watched value is a resolved type outside that classification, the watch is reactive state or config and is allowed. Unresolved, `dynamic` and `Object` values stay reported. Every `ref.watch` on a line is now checked, not only the first one.
- #66: resolve each persist helper's uses to the declared method element, so a lookalike local function does not count. A use qualifies as a mutation path when it is a tear-off, sits in a synchronous body, or sits in an async body that writes `state` without first awaiting another result. A helper called only from another helper inherits that helper's verdict. A helper with no resolved uses in its class stays reported, as before. The rule has no name or `*Id` exemptions.
- Owner decision: rules that enforce a skill MUST/NEVER rule are errors. `notifier_persistence_no_debounce` moves from warning to `ERROR`, and `service_provider_watch_dependency` stays `ERROR`.

## Acceptance + steps

- [x] The #68 reproduction, a watched `Provider<String>` credential, is allowed. A client rebuilt from a watched `Future<AppConfig>` config is allowed.
- [x] Watching a stable client beside a reactive credential reports only the client watch. `AsyncValue<Datasource>` and `Future<appwrite.Account>` watches report.
- [x] The #66 reproduction (awaited create/reuse handle writes) is allowed, and so is a state write after an awaited lifecycle result.
- [x] A lookalike local `_persist*` function in a setter is not treated as the helper.
- [x] Async `setTheme` (state write, then awaited persist) and synchronous `updateDraft` still report, and so do the existing true positives.

## Baseline + execution

Result: Passed
Evidence: Red first. 4 new #68 tests and 3 new #66 tests failed on `origin/main` (b0878e9) before the fixes.
Current baseline: `dart format` made no changes, `dart analyze` found no issues, and `dart test` passed 2,153 tests (1 skipped).
Execution: One builder. Commit cc291d5 contains the #68 fix and tests; commit 89a9843 contains the #66 fix, tests and descriptions. A follow-up commit splits the helper resolution to stay within the dart-decimate complexity budget and raises the #66 severity to error.

## Risks + recovery

- #68 depends on resolved types. Before codegen runs, providers are unresolved, and the rule reports as it did before.
- A config type whose name matches the stable-infrastructure classification, such as `ClientConfig`, is still treated as infrastructure. This follows the rule's existing classification.
- #66: an async state-writing method that awaits another result before persisting counts as a lifecycle write. Revert the two commits to restore the previous behavior.

## ux_reference

N/A — analyzer lint change; no app surface.

## Verification

Result: Passed
Evidence: Focused suites passed: 16 `ServiceProviderWatchDependencyTest` and 11 `NotifierPersistenceNoDebounceTest` cases. The full suite passed 2,153 tests. `dart analyze` found no issues and format made no changes. The full native Draft hard-eng gate passed, including dead-code-duplicates. Actual diff reviewed.
E2E: Passed — `probe-riverpod-skill-boundaries` (Riverpod 3.4.3 with riverpod_generator codegen) was analyzed against this worktree. It reported `service_provider_watch_dependency` only for the watch of the stable `httpApiClientProvider` (api_service_providers.dart:62). It reported `notifier_persistence_no_debounce`, at error severity, only for `ThemeNotifier._persistTheme` and `DraftNotifier._persistDraft`. The #68 credential watch, the live config watches, the #66 `ResourceNotifier` lifecycle writes and the lookalike local function were not reported.
Delivery target: Merge
Delivery: Pending — scoped PR, required CI, merge and main CI.
