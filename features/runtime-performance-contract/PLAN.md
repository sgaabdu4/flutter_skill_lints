# Runtime performance contract

Status: Complete

## Outcome + scope

Make the performance and debounce lints match the building-flutter-apps skill exactly: every MUST/NEVER they enforce reports as an error, the skill's NEVER shapes report, and the skill's DO examples stay clean. Scope is the perf-owned rows of the skill audit: `perf_listview_children` (row 4), `widget_derived_collection_logic` (row 8), `state_raw_response` (row 11), `user_visible_duration_too_long` (row 17), `riverpod_auto_dispose_keepalive_dependencies` (row 18), `keepalive_watches_unbounded_collection` (row 19) and `text_field_on_changed_no_debounce` / `slider_on_changed_no_debounce` (row 22, issue #37).

## Repository context

Owners: `lib/src/rules/runtime_bug_source_rules/runtime_bug_source_rules_part_02.dart` (onChanged debounce), `lib/src/rules/runtime_bug_source_rules.dart` (keepAlive collection watches), `lib/src/rules/riverpod_source_rules.dart` and `riverpod_source_rules_part_01.dart` (keepAlive dependencies), `lib/src/rules/state_source_rules.dart` (raw responses), and the UI and duration rule parts. Skill sources: `references/performance.md`, `references/common-patterns/debounce-gate-batch.md`, `references/common-patterns/lists-forms-workflows.md`.

## Decisions + authorization

Blockers: None
Authority: Coordinator-assigned builder slice; rules owned by other builders are unchanged.
- #37: onChanged work is found through resolved elements. Callees in the analyzed unit walk the resolved AST. Project callees in other files are parsed and typed through the callee's element model (locals, parameters, members, extensions, library scope). A call that cannot be typed counts as work (conservative, per #37). A callee file that owns a debounce mechanism counts as debounced, the same trust the rule already gives the widget file, so the skill's notifier-side `Debouncer` DO stays clean.
- Row 18: dependencies are resolved through the generated `@ProviderFor` variable to the source's `@Riverpod(keepAlive: true)` in any file. The rule fires only when there is at least one watch and every watch resolves keepAlive.
- Row 19: pure projections of unbounded collections in keepAlive providers report; bounded projections (`int` counts) and keepAlive-over-keepAlive projections stay clean.
- CP:27 500ms: no change; `user_visible_duration_too_long` stays strict.

## Acceptance + steps

- [x] Touched MUST/NEVER rules report at ERROR severity.
- [x] Row 4: dynamic-only `ListView(children:)` reports.
- [x] Row 8: expression-bodied derived collection helpers report.
- [x] Row 11: multi-line and Freezed callable `copyWith` with raw responses report.
- [x] Row 17: an `async` method no longer exempts foreground hard waits.
- [x] Row 18: cross-file all-keepAlive dependencies report; mixed, unresolved, family and read-only uses stay clean.
- [x] Row 19: keepAlive pure projections of unbounded collections report; the skill's bounded DO stays clean.
- [x] #37: synchronous `copyWith` plus validation handlers (issue repro, skill `setName`) stay clean in the same file and across files, including a Freezed state; async requests and sync forwarders (`unawaited(fetch())`, `ref.read<T>(...).search()`) report across files; the debounce-gate-batch.md:21-31 Timer DO stays clean.

## Baseline + execution

Result: Passed
Evidence: The skill audit (probe app) found rows 4, 18 and 22 present at warning, rows 8, 11 and 17 false negatives, and row 19 a false positive; cross-file row 18 (`vProductCount` over keepAlive `productProvider`) was silent.
Current baseline: All rows are fixed on this branch; the full suite passes.
Execution: One builder, red test first per row in the rule's existing test file, one commit per green step.

## Risks + recovery

The cross-file walker is a partial typer over unparsed code: a closure parameter or untyped local it cannot type counts as work, so an unusual cross-file handler can report conservatively. The two named skill DO controls and the Freezed callable `copyWith` stay clean under tests and the probe. The callee-file debounce trust is file-wide, like the existing widget-file trust. Recovery is a focused control test plus a typing rule in `_ParsedWorkFinder`.

## ux_reference

N/A — analyzer lint behavior only; no app surface.

## Verification

Result: Passed
Evidence: `dart format lib test` clean, `dart analyze` no issues, `dart test` 2,167 passed and 1 skipped, and `RUN_FLUTTER_PLUGIN_SMOKE=1 dart test test/integration_plugin_smoke_test.dart` passed (audit_boundaries lines 11 and 12 report). Hard Eng: see below.
E2E: Passed — probe `dart analyze` (probe-runtime-performance-contract, build_runner run): `text_field_on_changed_no_debounce` reports p37_form.dart:55-57, p37b_form.dart:53 and p37b_cross_file_fields.dart:15-16, and is clean on the skill `setName`/`setPrice` over a real `@freezed` state, the skill `SearchNotifier` with `Debouncer`, and the issue repro; `riverpod_auto_dispose_keepalive_dependencies` reports at ERROR on cart_total_providers.dart:7 and :10, search_notifier.dart:15 and perf_notifiers.dart:239 (the audit's cross-file gap), with the mixed and keepAlive controls clean; `keepalive_watches_unbounded_collection` reports runtime_contract_notifiers.dart:17 and :50 with the :54 and :57 DO controls clean.
Delivery target: Merge
Delivery: Pending — combined PR by the coordinator.
