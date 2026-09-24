# Riverpod mutation and service lint contract

Status: Complete

## Outcome + scope

Make the Riverpod mutation, service-locator, keepAlive-family and broad-watch lints match `references/riverpod-codegen.md` (line 107 and lines 250 onward) and the verbatim `freezed-sealed.md` switch examples. Scope is the audit rows in `state-s3.json` plus the two `riverpod_watch_no_select` rows in `model-s3.json`. Each lint that enforces a skill MUST/NEVER rule reports as an error.

## Repository context

Owners: `lib/src/rules/riverpod_source_rules.dart` and its `riverpod_source_rules/` parts. Tests: `test/source_scanner_rules_test/source_scanner_rules_part_01..04.dart`. Registration counts: `test/plugin_registration_test.dart`, `README.md`, `doc/building-flutter-apps-lint-coverage.md`, `doc/building-flutter-apps-lint-inventory.md`, `doc/coverage-audit.md`.

## Decisions + authorization

Blockers: None
Authority: The owner said every lint that enforces a skill MUST/NEVER rule is an error. Rules owned by other builders are not edited.

- `riverpod_watch_no_select`: now an error. A watch that resolves to Riverpod `MutationState` is allowed (skill: flags for simple checks). A switch over a watched sealed type whose cases are variant patterns (`Authenticated(:final user)`, `AsyncData(:final value)`) counts as using the whole value. A field pattern on the sealed base type still reports.
- `riverpod_keepalive_family`: now an error. The #4709 note must be on the provider's own declaration: a leading comment, a doc comment, or a comment before the provider name. The ±6-line window is gone, so a neighbour's note no longer silences an adjacent family.
- `riverpod_mutation_experimental_warning`: now an error. It checks resolved Riverpod `Mutation<T>()` creations in any path, not only notifier paths. The experimental note must be on the declaration itself, either leading or trailing on the same line.
- New `riverpod_mutation_top_level` (error): a resolved Riverpod `Mutation<T>()` must initialize a top-level `final`.
- New `riverpod_mutation_ref_read` (error): a Riverpod `read` inside a resolved `Mutation.run` callback reports. The fix is `tsx.get`.
- `riverpod_service_locator`: reads the class declaration from the AST and matches the suffixes `ServiceLocator`, `ServiceFactory` and `BackendProvider`. Matching by name is correct here because the skill bans these classes by name ("NEVER create `ServiceFactory`, `ServiceLocator`, or `BackendProvider` class"). There is no registry-shape heuristic.
- Not implemented on this branch: "keepAlive for SDK client/service providers" (riverpod-codegen.md:426). The only classifier for service/client providers checks resolved return-type names in `service_provider_watch_dependency`, and another builder owns that rule. It goes to that owner: a top-level `@riverpod` function (no keepAlive) whose return type passes that classifier.
- Declined: "destructuring for config access" (riverpod-codegen.md:428). No resolved element marks a value as "config", so the check would be a name heuristic.
- The experimental-note check now looks only at `Mutation<T>()` creations. A bare `Mutation<T>` type annotation no longer reports, because the skill puts the note on the declaration that creates the mutation.
- Not a lint defect: the `strings_hardcoded`/`avoid_hardcoded_strings` findings on freezed-sealed.md's `Text('Error: $error')`. That snippet conflicts with the l10n rules, and neither rule is owned here.
- Not a lint defect: the `discarded_futures`, `avoid_missed_calls` and `avoid_async_call_in_sync_function` findings on the doc's `addTodoMutation.run(...)` and `Future.microtask(() => _loadProduct(...))` snippets. The skill's own `analysis_options.yaml` enables `discarded_futures`, and services-and-singletons.md rule 1 requires `unawaited(...)`. The snippets contradict the skill, so the doc needs fixing.

## Acceptance + steps

- [x] Skill examples report nothing: file-scope mutation with a trailing note, `tsx.get`, `ref.watch(mutation).isPending`, sealed-union and AsyncValue switches, and a family with its own #4709 note.
- [x] Real violations report: a mutation in build() or a static field, `ref.read` in `run`, an unnoted mutation in a screen, a family next to a neighbour's note, prefixed locator/factory classes, and a field read on the sealed base type.
- [x] Local lookalikes (non-Riverpod `Mutation`, `MutationState`, `run`) stay silent.
- [x] Registration counts and docs list the two new rules.

## Baseline + execution

Result: Passed
Evidence: The audit probes in `probe-state` showed each row's baseline (silent violations, warning severity, and false positives on the doc snippets).
Current baseline: Probe copy `probe-state-mutation-service-contract` was analyzed against this worktree. `analyze.log` holds the findings.
Execution: One builder. Red test first for each rule, then the fix, then a commit per green step.

## Risks + recovery

Resolved checks depend on Riverpod's `Mutation`/`MutationState` living under `package:riverpod/`, and they do in riverpod 3.4.3. If Riverpod moves these types, the mutation rules go silent rather than reporting false positives. The tests use a synthetic `package:riverpod` stub to pin this contract.

## ux_reference

N/A — analyzer diagnostics only; no app surface.

## Verification

Result: Passed
Evidence: `dart format lib test` made no changes. `dart analyze` found no issues. `dart test`: 2,162 tests passed (1 skipped). `hard-eng.py check --plan-stage Draft` passed every gate after `_ownedComments` was split to clear the complexity gate. Consumer probe (`analyze.log`) findings for the rules on this branch: add_todo_screen.dart:10 `riverpod_mutation_experimental_warning`, :14 `riverpod_mutation_top_level`, :23 top_level + experimental_warning, :37 `riverpod_mutation_ref_read`; cart_session_notifier.dart:39 experimental_warning; codegen_providers.dart:27 and :40, keepalive_family.dart:7 and keepalive_family_sync.dart:7 `riverpod_keepalive_family`; codegen_providers.dart:108, :113 and :118 `riverpod_service_locator`; auth_gate_screen.dart:90 and order_form_screen.dart:74 `riverpod_watch_no_select`. Clean controls: add_todo_screen.dart:7 and :33, the `isPending` watches, checkout_mutation_notifier.dart:5, codegen_providers.dart:35 (own #4709 note), and the auth_gate union and AsyncValue switches.
E2E: Passed — real Flutter consumer probe analyzed with the plugin at this worktree; the reproductions and controls behaved as listed above.
Delivery target: Merge
Delivery: Pending — branch `fix/state-mutation-service-contract`, not pushed.
