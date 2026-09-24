# State, async and lifecycle lint contract

Status: Complete

## Outcome + scope

Make the s1-owned state, async-guard and lifecycle lints match `building-flutter-apps` exactly (no looser, no stricter) for the audit rows in `state-management/async-mutations.md`, `state-management-lifecycle.md` and the three extra rows (data-layer status classification, local-datasource `FormatException` recovery and the `lists-forms-workflows.md` repo-work mounted guard). Every rule touched reports as `ERROR`. No new rule is registered, so rule counts are unchanged. CHANGELOG and the pubspec version are unchanged.

## Repository context

Owners: `lib/src/ast_utils.dart` (shared `AsyncStatementScanner`), `mounted_guard_utils.dart`, `require_atomic_async_updates.dart`, `notifier_dependency_capture.dart`, `dialog_source_rules.dart`, `data_crash_source_rules.dart` and the state and Riverpod source rules for `state_*`, `riverpod_event_counter_signal_forbidden` and `notifier_watch_method`. Tests go in each rule's existing `test/source_scanner_rules_test/*` part file. The shared mock Flutter package in `test/source_scanner_rules_test.dart` gained `StatefulWidget`, `State<T>` and a `foundation.dart` whose `debugPrint` is a function-typed variable, matching Flutter. The mock `State` in `test/flutter_skill_rules_test.dart` gained `mounted`.

## Decisions + authorization

Blockers: None
Authority: Coordinator-assigned builder s1 (`build/OWNERS.md`). Coordinator answers to the open questions:
- Editing `riverpod_event_counter_signal_forbidden` and `notifier_watch_method` is approved, and s1 owns them.
- The `*State` class-name classifier for `state_freezed_nullable_error` is accepted as a documented limit.
- The `data_log_rethrow` reporting-call definition is accepted: resolved `dart:core` `print`, `dart:developer` `log`, Flutter `debugPrint`, or any call that receives the caught error or stack element.
- `notifier_local_dependency_cache` and `notifier_ensure_deps` may fire at different locations (field and method) for the same member-held repository. This is accepted.
- `avoid_throw_in_catch_block` is left alone.
- Every rule touched is `ERROR`.
- The coordinator already ran the Hard Eng setup, so `curl|sh` is not re-run.
Earlier accepted decisions: `notifier_ensure_deps` dropped the capture-before-write requirement. `require_atomic_async_updates` dropped the revision-token and `loading:` checks.
Skipped: row 5 (`service_provider_watch_dependency`) belongs to builder riverpod and was fixed there.

## Acceptance + steps

- [x] Rows 1, 4, 10, 15 and extra row 3: `use_ref_mounted_after_await`, `avoid_mounted_check_in_finally`, `avoid_only_rethrow` and `widget_calls_notifier_teardown_after_await` report as `ERROR`.
- [x] Rows 2, 3: flow-sensitive `AsyncStatementScanner` tracks `ref.mounted` guards through braced if/try/catch/finally, inline awaits, loops and async closures.
- [x] Row 12 and coordinator ask: `use_context_mounted_after_await` uses the same scanner for async widget callbacks, nested blocks and expression bodies. A captured `context.mounted` guard protects `context`, while `State.context` (a resolved getter) needs `mounted`. Pure guard suffixes accept enum `==`/`!=`, which fixes the `modals-navigation.md:129` DO example.
- [x] Row 8: `notifier_ensure_deps` accepts a direct resolved `ref.read(...)`.
- [x] Row 9: `require_atomic_async_updates` accepts resolved `!ref.mounted` guards.
- [x] Rows 13, 14 and extra rows 1, 2: `arch_datasource_try_catch` flags only a trailing rethrow-only datasource catch. `data_log_rethrow` (now `ERROR`) flags reporting-only plus `rethrow` catches in data paths, including Flutter's function-typed `debugPrint`. The two rules never report the same catch.
- [x] Rows 16, 17: `state_raw_error_to_string` resolves raw exception text in `error:` arguments. `state_freezed_nullable_error` covers String error fields in any `*State` class and excludes Flutter `State<T>`.
- [x] Row 0: `riverpod_event_counter_signal_forbidden` resolves `@riverpod` classes and functions by generated provider name.
- [x] Row 7: `notifier_local_dependency_cache` flags repository/service/datasource-typed fields and resolved `ref.read` dependency caches. `_client ??= BackendHttpClient()` construction is not flagged.
- [x] Row 6: `notifier_watch_method` flags resolved `ref.watch` and `ref.listen` outside `build`.
- [x] Row 11: `widget_calls_notifier_teardown_after_await` also flags `.go(context)` and `context.go(...)` after an awaited notifier mutation in the same widget block. Push, `goBranch` and `go` after an awaited modal stay allowed.
- [x] Coverage doc records the changed behaviour. The inventory lists names only and is unchanged.

## Baseline + execution

Result: Passed
Evidence: Before the fix, `probe-state-async-lifecycle-contract/baseline.log` (`dart analyze` on a copy of the probe app pointed at this worktree) showed each row's gap, false positive or non-`ERROR` severity.
Current baseline: format clean, `dart analyze` no issues, 2,162 tests passed and 1 skipped.
Execution: One builder worked red-first, one row at a time, in each rule's existing file. Each green step was committed after the full suite passed.

## Risks + recovery

- `state_freezed_nullable_error` classifies notifier state by the `*State` class-name suffix, which is the only single-file signal. A differently named state class is not checked.
- `widget_calls_notifier_teardown_after_await` stays line-scanned like its teardown check. A widget that awaits a notifier, then awaits a confirm dialog, then calls `.go(context)` in the same block is flagged. No skill DO example does this: `modals-navigation.md:68` ends at the notifier await.
- `data_log_rethrow` treats a call as reporting when it receives the caught error, so a rollback call that passes the error and is the only non-rethrow statement would be flagged. A catch with any other statement stays legal.
- Recovery: each row is a separate commit and can be reverted alone.

## ux_reference

N/A — analyzer plugin rules and docs; no app surface.

## Verification

Result: Passed
Evidence: `dart format lib test` clean, `dart analyze` no issues, `dart test` 2,162 passed and 1 skipped. Hard Eng Draft check: see the E2E line and the builder report.
E2E: Passed — the real Flutter/Riverpod probe app analyzed with this worktree reports exactly the violation probes and keeps the controls clean. Covered: nested-if and catch `context` uses; the `go` chained off a save (`order_form_screen.dart:46`, with push, go-after-modal and sibling-callback controls clean); the rethrow-only datasource catch; four log-and-rethrow catches (debugPrint, developer.log, Crash.error); raw error strings and String error fields; four event providers; two dependency-cache fields; and `ref.watch`/`ref.listen` in methods.
Delivery target: Merge
Delivery: Pending — scoped PR, required CI, merge and main CI.
