# Riverpod mutation and service lint contract

Status: Complete

## Outcome + scope

Make the Riverpod mutation, service-locator, keepAlive-family and broad-watch lints match `references/riverpod-codegen.md` (line 107 and lines 250 onward) and the verbatim `freezed-sealed.md` switch examples. Scope is the audit rows in `state-s3.json` plus the two `riverpod_watch_no_select` rows in `model-s3.json`, and reopened issue #36 (performance.md:26-27 minimal view data and `.select()` at binding boundaries; freezed-sealed.md:9 and :136-146 `switch`, never `.when()`/`.map()`). Each lint that enforces a skill MUST/NEVER rule reports as an error.

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
- #36 `riverpod_watch_no_select`: `AsyncValue.when` no longer counts as a whole-value use. freezed-sealed.md:9 bans `.when()`/`.map()`, so the only whole-value AsyncValue dispatch is the sealed `switch`.
- #36 `riverpod_watch_no_select`: a constructor argument used to exempt any watched value. Now a watched value passed whole into an app widget constructor reports when it has a class type with more than one public field. Fields are counted as public instance fields plus public abstract getters, because Freezed puts its fields on the generated mixin; a concrete `copyWith` is not counted. These stay whole-value inputs: records, collections (any `Iterable`/`Map` subtype, such as `UnmodifiableListView`), SDK types (`Uri`, `DateTime`), and single-field classes. Primitives and enums were already exempt. An app widget is a subtype of Flutter's `Widget` that is not declared in `package:flutter/`. Framework widgets take framework config, such as `MaterialApp.router(routerConfig: router)` in routing-app-shell.md:381, not reusable-widget view data. Non-widget constructors keep the old exemption.
- #36 declined: "the full view model the widget requires". To tell whether a widget uses every field of the value it receives, the rule would have to read that widget's body. Reusable widgets live in other libraries, and a lint rule only sees resolved elements for them, not their bodies. The skill's DO examples never pass a watched multi-field class whole into an app widget. They select a record or fields (performance.md:88 UserSummaryScreen, architecture.md:354 ProductListScreen, atomic-design.md Pages) or pass a computed list (riverpod-codegen.md:181 HistoryScreen), so all of them stay clean. A widget that does need the whole class should get a select of the fields it renders, or a computed projection provider that returns a record or collection.
- New #36 `async_value_switch_over_when` (error): resolved Riverpod `AsyncValue` `when`/`maybeWhen`/`whenOrNull`/`map`/`maybeMap`/`mapOrNull` calls report anywhere in a file, with a correction that points to the `AsyncData`/`AsyncError`/`AsyncLoading` switch. `whenData` is a transform, not a union match, so it is allowed. `freezed_legacy_when_map` only covers `.freezed.dart` methods, so no existing rule overlapped.
- Follow-up, not changed here: the rule's line scanner does not match a watch split as `ref\n.watch(`, so the watch_page.dart:57 watch is only reported through `.when`. The name-based `_isProjectionProviderName` exemption list is also still in place. Both are outside #36.
- Declined: "destructuring for config access" (riverpod-codegen.md:428). No resolved element marks a value as "config", so the check would be a name heuristic.
- The experimental-note check now looks only at `Mutation<T>()` creations. A bare `Mutation<T>` type annotation no longer reports, because the skill puts the note on the declaration that creates the mutation.
- Not a lint defect: the `strings_hardcoded`/`avoid_hardcoded_strings` findings on freezed-sealed.md's `Text('Error: $error')`. That snippet conflicts with the l10n rules, and neither rule is owned here.
- Not a lint defect: the `discarded_futures`, `avoid_missed_calls` and `avoid_async_call_in_sync_function` findings on the doc's `addTodoMutation.run(...)` and `Future.microtask(() => _loadProduct(...))` snippets. The skill's own `analysis_options.yaml` enables `discarded_futures`, and services-and-singletons.md rule 1 requires `unawaited(...)`. The snippets contradict the skill, so the doc needs fixing.

## Acceptance + steps

- [x] Skill examples report nothing: file-scope mutation with a trailing note, `tsx.get`, `ref.watch(mutation).isPending`, sealed-union and AsyncValue switches, and a family with its own #4709 note.
- [x] Real violations report: a mutation in build() or a static field, `ref.read` in `run`, an unnoted mutation in a screen, a family next to a neighbour's note, prefixed locator/factory classes, and a field read on the sealed base type.
- [x] Local lookalikes (non-Riverpod `Mutation`, `MutationState`, `run`) stay silent.
- [x] Registration counts and docs list the two new rules.
- [x] #36: `AsyncValue.when` on a watched value reports `riverpod_watch_no_select`, and every Riverpod AsyncValue when/map helper reports `async_value_switch_over_when`. Same-named local lookalikes and `whenData` stay silent.
- [x] #36: a whole multi-field state passed into an app widget reports, both inline and through a local, with plain and Freezed-shaped classes. Lists, `Iterable` subtypes, records, SDK values, single-field Freezed-shaped classes and framework widgets stay clean.
- [x] Registration counts and docs list `async_value_switch_over_when`.

## Baseline + execution

Result: Passed
Evidence: The audit probes in `probe-state` showed each row's baseline (silent violations, warning severity, and false positives on the doc snippets). For #36, the closed-issue verifier probe (`probe-closed-b`, probe_b_watch_page.dart) showed that :36 and :46 (whole 3-field state into a widget) and the :57 `.when` were silent.
Current baseline: Probe copy `probe-state-mutation-service-contract` was analyzed against this worktree. `analyze.log` holds the findings.
Execution: One builder. Red test first for each rule, then the fix, then a commit per green step.

## Risks + recovery

Resolved checks depend on Riverpod's `Mutation`/`MutationState` living under `package:riverpod/`, and they do in riverpod 3.4.3. If Riverpod moves these types, the mutation rules go silent rather than reporting false positives. The tests use a synthetic `package:riverpod` stub to pin this contract.

## ux_reference

N/A — analyzer diagnostics only; no app surface.

## Verification

Result: Passed
Evidence: `dart format lib test` made no changes. `dart analyze` found no issues. `dart test`: 2,171 tests passed (1 skipped). `hard-eng.py check --plan-stage Draft` passed every gate (`probe-s3b/hard-eng.log`). Earlier, `_ownedComments` was split to clear the complexity gate. For #36, the select arrow-syntax tests moved unchanged to part_19 so the watch test file stays under 1,000 lines. Earlier rows: consumer probe `probe-state-mutation-service-contract/analyze.log` reported add_todo_screen.dart:10, :14, :23 and :37, cart_session_notifier.dart:39, the keepAlive-family and service-locator lines in codegen_providers.dart and keepalive_family*.dart, and auth_gate_screen.dart:90 and order_form_screen.dart:74. #36 consumer probe `probe-s3b/analyze.log`: probe_b_watch_page.dart:36 (inline whole state) and :46 (through a local) report `riverpod_watch_no_select`, :59 reports `async_value_switch_over_when`, and :88 (partial read) still reports. :12, :25 and the skill's `AsyncData(:final value)` switch at :73 are clean. In probe_b_skill_controls_page.dart, :83 (whole state into a widget from another file) reports `riverpod_watch_no_select` and :97 (`maybeWhen`) reports `async_value_switch_over_when`. The UserSummaryScreen record select, ProductListScreen field selects, HistoryScreen list, `MaterialApp.router` with the router (the `routerProvider` name and the non-projection `probeBShellProvider` name), the real `dart:core` `Uri` value and `whenData` are all clean.
E2E: Passed — real Flutter consumer probes analyzed with the plugin at this worktree; the reproductions and controls behaved as listed above.
Delivery target: Merge
Delivery: Pending — branch `fix/state-mutation-service-contract`, not pushed.
