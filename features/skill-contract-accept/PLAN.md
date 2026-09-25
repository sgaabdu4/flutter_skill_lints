# Skill contract acceptance lint fixes

Status: Complete

## Outcome + scope

Align six acceptance findings with the building-flutter-apps skill (fixed docs v5.12.0). Each skill DO example must produce no flutter_skill_lints diagnostic. Each NEVER or WRONG example that names a lint must report that lint at error severity. The branch touches `prefer_dot_shorthands`, `fire_and_forget_missing_catch`, `avoid_magic_literals`, `dialog_widget_subscribes_to_mutable_provider`, `select_returns_unstable_record_identity`, `appwrite_blocking_function_execution_in_client` and `linear_id_lookup_in_hot_path`. No rule is added or removed, so the registered counts do not change.

## Repository context

Owners: `lib/src/additional_lints/rules/prefer_dot_shorthands.dart`, `lib/src/additional_lints/rules/avoid_magic_literals.dart`, `lib/src/rules/persistence_crash_source_rules.dart`, `lib/src/rules/dialog_source_rules.dart`, and `lib/src/rules/runtime_bug_source_rules/runtime_bug_source_rules_part_01.dart` and `_part_03.dart`, plus their tests and `doc/building-flutter-apps-lint-coverage.md`. The skill sources are `common-patterns/modals-navigation.md` (the :15 NEVER example and the :162 DO example), `extensions/context-ui.md` (dialog helpers), `networking.md` (:161, "Long-Running Remote Work") and `common-patterns/debounce-gate-batch.md` (:138, "Collection getters and id lookup").

## Decisions + authorization

Blockers: None
Authority: The coordinator assigned these six items on `fix/skill-contract-accept` from `fix/skill-contract-alignment`. The work is local commits only. Pushing is out of scope.

Decisions:
- `prefer_dot_shorthands` reports only enum values, static members and named constructors. Unnamed constructor calls are no longer reported.
- `fire_and_forget_missing_catch` treats a resolved callee as handled in three cases: its body catches internally; or it throws nothing and every future it awaits or returns is handled; or it has no future and makes no call. A handled future is a Riverpod `Mutation.run`, a Flutter or go_router route or modal future (including a go_router_builder override of `GoRouteData.push`), or a callee that is itself handled (up to depth 3).
  - Bodies declared in another library are available only as a parsed AST. `getResolvedLibraryByElement` is asynchronous and cannot run in a synchronous rule. Unqualified top-level calls in such a body are resolved through the declaring library's scope.
  - Any future that cannot be resolved still reports.
- `avoid_magic_literals` exempts a string bound to a resolved `routeName` parameter or to Flutter's `RouteSettings(name:)`. The exemption is keyed on the parameter element and the owning class's library. A lookalike `RouteSettings` class still reports, and so does `key:`.
- `dialog_widget_subscribes_to_mutable_provider` and `select_returns_unstable_record_identity` now read the resolved AST, not source lines.
  - Provider roots strip `.select`, `.notifier`, `.future`, family calls and casts. Roots compare by element when resolved and by name otherwise.
  - A record field is unstable when it reads an explicit getter returning a `Map`, `Set` or `Iterable`. A stored field is stable. When a read is unresolved, the old getter-name pattern decides.
  - `select_returns_unstable_record_identity` is now an error, because modals-navigation.md:15 is a NEVER example.
- `appwrite_blocking_function_execution_in_client` also reports a named argument that meets four conditions:
  - It binds to a resolved `bool` parameter named `waitForCompletion`.
  - Its value is the literal `true`.
  - The invoked method's name, or the enclosing method's name, is a destructive or batch name.
  - This matches the networking.md:161 WRONG shape, `remote.deleteAccount(userId, waitForCompletion: true)`. The RIGHT calls `startDeleteAccount` and `waitForAccountDeleted(..., maxAttempts: 60)` stay clean.
- `linear_id_lookup_in_hot_path` treats a getter, whether a class member or top-level, as a hot path, because the lookup scans on every access. That is the debounce-gate-batch.md "Collection getters" contract.
  - A plain method is still a one-off. The skill qualifies the rule with "in hot paths" (performance.md:40, collections-helpers.md:6), and the #87 controls stay clean.

## Acceptance + steps

- [x] The `prefer_dot_shorthands` red test and control for unnamed and named constructors pass.
- [x] The `fire_and_forget_missing_catch` tests pass:
  - The modals-navigation.md DO example (`unawaited(_openCreateSheet(context))` through `context.showAppSheet` and a go_router_builder route) is clean.
  - The `Mutation.run` and transitive-catch callees are clean.
  - Navigation followed by uncaught remote work, a local `Mutation` lookalike and a callee that throws before caught work all still report.
- [x] `routeName: 'create-sheet'` and `RouteSettings(name: ...)` are clean. `key:` and a lookalike `RouteSettings` still report.
- [x] The multi-line modals-navigation.md:15 NEVER example reports both dialog rules. Resolved getters decide record-field identity. Both rules are errors.
- [x] networking.md:161 `waitForCompletion: true` reports. Its RIGHT calls, `waitForCompletion: false`, a non-destructive call and an unresolved lookalike stay clean.
- [x] Member and top-level getter id lookups report. The one-off repository mutation and notifier lookup controls stay clean.

## Baseline + execution

Result: Passed
Evidence: The acceptance probe against `fix/skill-contract-alignment` produced these results:
- `fire_and_forget_missing_catch` and `avoid_magic_literals` fired on the modals-navigation.md DO example.
- Neither dialog rule fired on the multi-line `ref.watch(` in the :15 NEVER example.
- `appwrite_blocking_function_execution_in_client` missed networking.md:161.
- `prefer_dot_shorthands` reported unnamed constructor calls.
Each item began with a red unit test.
Execution: Each item was one commit: red test, then fix, then controls.

## Risks + recovery

- A cross-library callee body is parsed, not resolved. A helper in another library that returns a target-qualified extension future, such as a hand-written `context.push(...)`, therefore still reports `fire_and_forget_missing_catch`.
- An explicit getter that only forwards a stored collection is treated as unstable in a record select.
- Existing getters that do id lookups now report `linear_id_lookup_in_hot_path`. The skill intends this.

To recover, revert the commit for the affected item.

## ux_reference

N/A — analyzer diagnostics have no rendered application UI.

## Verification

Result: Passed
Evidence: The branch was verified on the integrated `fix/skill-contract-alignment` head, merged after `fix/skill-contract-sweep`. `dart format --output=none --set-exit-if-changed lib test` changed no files. `dart analyze` found no issues. `dart test` passed 2,628 tests with one intentional skip. `python3 .hooks/hard-eng.py check --base origin/main --plan-stage Draft` passed every gate: lockfile, vulnerabilities, format, types-lint, security, import-boundaries, tests (79.16% line coverage), dead-code-duplicates, performance, secrets, actionlint and zizmor.

On this branch alone, format, analyze and test passed (2,618 tests), and hard-eng failed on two findings inherited from `fix/skill-contract-alignment`. The first was `source_scanner_rules_part_07.dart` at 1,051 lines. The second was a 5-line dart-decimate clone between `riverpod_source_rules_part_02.dart` and `state_source_rules.dart`. Sweep commits 9088ddf and 038dc53 fixed both, and neither finding remains on the integrated head.

The sweep's test that every skill code is an error, outside a reasoned allowlist, passes. `select_returns_unstable_record_identity` left that allowlist. It and `dialog_widget_subscribes_to_mutable_provider` are now in the error-severity assertion list in `test/plugin_registration_test.dart`.
E2E: Passed — a copy of the acceptance probe was analyzed with the plugin loaded from this worktree:
- `create_screen.dart` (the modals-navigation.md DO example) no longer reports `fire_and_forget_missing_catch` or `avoid_magic_literals`.
- The :15 NEVER dialog reports `dialog_widget_subscribes_to_mutable_provider` and `select_returns_unstable_record_identity` as errors.
- Both `appwrite_blocking_function_execution_in_client` probes report errors.
- The build-path `linear_id_lookup_in_hot_path` probe reports.
Delivery target: Merge
Delivery: Pending — merged into `fix/skill-contract-alignment` after the sweep branch; the combined PR, required CI, merge and main CI remain.
