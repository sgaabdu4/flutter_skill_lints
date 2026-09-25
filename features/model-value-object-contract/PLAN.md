# Model, Value Object and records skill contract

Status: Complete

## Outcome + scope

Make the Freezed, Value Object, records and primitive-extension lints match the building-flutter-apps skill exactly. This covers the model audit rows and closed issues #38, #50, #64, #75 and #86. Per the coordinator, every rule touched here reports at error severity. Three rules are added for skill text that had no lint: ad-hoc intl formatting, inline `num.clamp`, and `@RecordUse` outside dart:ffi bindings. Two rules that the skill contradicts are removed. No other rules change.

## Repository context

Owners: `lib/src/rules/value_object_source_rules.dart`, `freezed_source_rules.dart`, `ui_source_rules.dart` (+ `ui_source_rules_part_01.dart`), `runtime_bug_source_rules.dart`, and the additional lints `avoid_throw`, `avoid_returning_widgets`, `prefer_class_destructuring`, `avoid_positional_record_fields` and `freezed_legacy_when_map`. Tests go in the existing test file for each rule (`test/source_scanner_rules_test/*`, `test/additional_lints_*`). `test/plugin_registration_test.dart` holds the counts and the error-severity list. The counts are also in `doc/building-flutter-apps-lint-coverage.md`, `doc/building-flutter-apps-lint-inventory.md` and `README.md`.

## Decisions + authorization

Blockers: None
Authority: Autonomous package repair authorized by the user. Coordinator decisions: every touched rule is ERROR; `avoid_declaring_call_method` and `move_records_to_typedefs` are removed; row 29 ships per `primitive-formatting.md:60`; `prefer_dot_shorthands` stays ERROR. No CHANGELOG or version change.
- Removed `move_records_to_typedefs`: the skill has no typedef text. It shows inline record signatures (`dart-patterns-records.md:69`, `:79`; `atomic-design.md:285`), so there is nothing to narrow the rule to.
- Removed `avoid_declaring_call_method`: the skill has no such rule, and its own `Debouncer.call` contradicts it.
- Doc conflict: `lists-forms-workflows.md:258` uses `(i + batchSize).clamp(0, items.length)`, which `inline_num_clamp` reports. The skill doc will change to `min(i + batchSize, items.length)`; the rule is not loosened for it.
- Skipped (no sound resolved shape, or owned elsewhere): row 2 (repository rich-model methods), row 22 (Debouncer in a widget file), rows 14 and 24 (arch), `annotate_overrides`, `use_context_is_current_modal_route` (testnav).

## Acceptance + steps

- [x] Model skill MUST/NEVER diagnostics report at ERROR (asserted in `plugin_registration_test`).
- [x] #86 `avoid_throw`: codegen notifiers (`_$X extends $Notifier`) resolve through riverpod `AnyNotifier`, so their typed throws report; a datasource `FormatException` stays clean.
- [x] #38/#64 `domain_entity_primitive_factory`: redirecting Freezed union cases (including parameterless and optional diagnostic payloads) are allowed; body factories such as `fromPrimitives` still report.
- [x] #50 `freezed_legacy_when_map`: every legacy Freezed helper reports; Riverpod `AsyncValue.when`/`maybeWhen` stay clean.
- [x] #75 `avoid_positional_record_fields`: positional pairs such as the skill's `Future` record wait are allowed; 3+ positional fields report (`dart-patterns-records.md:68`).
- [x] Freezed redirect parameters: raw String/int IDs report, and domain parameters resolve from the redirect. The composite Money redirect is allowed and non-const raw Value Object redirects are checked.
- [x] `avoid_returning_widgets` (ERROR): members of an extension on a resolved Widget collection that return a Widget collection are allowed.
- [x] `prefer_class_destructuring` (ERROR): property reads passed straight to a constructor don't count. The rule uses the shared test-source check, so its tests are no longer vacuous.
- [x] `datetime_now_requires_timezone_intent`: raw `DateTime.now()` is allowed in static members of a resolved `extension ... on DateTime`, and date windows anywhere in that extension. This replaces the old path and regex allowance.
- [x] `ad_hoc_id_index_lookup`: the `indexOfByKey(...)[id]` form reports; a cached index stays clean.
- [x] `ui_snackbar_boundary` (context-ui.md:69): `SnackBarUtils.show...` reports in classes whose resolved supertypes reach riverpod `AnyNotifier`/`Notifier`/`AsyncNotifier`/`StreamNotifier` or state_notifier `StateNotifier`, and in repository/datasource files. A UI helper that wraps SnackBarUtils and a non-SnackBarUtils `show*` stay clean. The message now names every layer.
- [x] New `ad_hoc_intl_format` (primitive-formatting.md:33, :60): resolved `package:intl` `DateFormat` construction is allowed only in an extension on dart:core `DateTime`, and `NumberFormat` only in one on `num`/`int`/`double`.
- [x] New `inline_num_clamp` (primitive-formatting.md:60): resolved dart:core `num.clamp` is allowed only inside an extension on `num`/`int`/`double`. Other types' `clamp` methods (for example `TextScaler`) are ignored.
- [x] New `record_use_outside_ffi` (dart-patterns-records.md:56-57): package:meta `@RecordUse` reports in libraries that don't import `dart:ffi`.
- [x] Counts updated: 190 skill rules, 198 skill codes, 278 additional codes (237 rules), 472 total. The inventory, coverage matrix and README are updated.

## Baseline + execution

Result: Passed
Evidence: Each fix first had a test that failed without it. The new rules' 14 tests all failed before the rules were registered. The row 25 notifier and repository tests failed before the resolved visitor.
Current baseline: `dart analyze` clean; 2,188 tests pass (1 skipped).
Execution: Three builder sessions on one branch, with each green step committed; then the probe and hard-eng.

## Risks + recovery

`ui_snackbar_boundary` still reports `ScaffoldMessenger.of`/`SnackBarUtils.show` on any line of a UI-path file (the unchanged UI branch). A UI helper that lives under a UI path would report even though context-ui.md:69 allows it. `ad_hoc_id_index_lookup` stays regex-based. Its `iterable_extensions.dart` path skip and `prefer_class_destructuring`'s name-based l10n skip were already there and were left unchanged. `inline_num_clamp` and `ad_hoc_intl_format` skip test files, like `datetime_now_requires_timezone_intent`.

## ux_reference

N/A — analyzer lint rule; no app surface.

## Verification

Result: Passed
Evidence: Focused tests pass in each rule's existing test file, and the full suite passes (2,188 passed, 1 skipped). `dart format` and `dart analyze` are clean. Hard-eng Draft gate: see the branch report.
E2E: Passed — the probe app uses this worktree as a path dependency. `lib/features/ex/presentation/providers/ex_notifier.dart` (codegen `SnackBarUtils.showError`) and `lib/features/ex/data/repositories/ex_repository.dart` report `ui_snackbar_boundary`. `lib/core/utils/ex_snack_bars.dart` is clean. In `ex_panel.dart`, `DateFormat('yyyy-MM-dd')` and `NumberFormat.currency` report `ad_hoc_intl_format` and `n.clamp(0, 10)` reports `inline_num_clamp`, while the skill's `DateTimeX`/`NumX` extensions and `count.clamped(0, 10)` are clean. `@RecordUse` in `lib/features/ru/application/tracked.dart` reports; the `dart:ffi` binding in `lib/core/native/square_bindings.dart` is clean. Closed-issue files copied in: #50 `AsyncValue.when` clean, Freezed `when`/`map` report. #64 redirecting cases clean, `fromPrimitives` reports. #38 `probe_b_failure.dart` clean. #75 `probe_b_records.dart` clean. #86: codegen notifier typed throw reports, datasource `FormatException` and repository typed failure clean, `Exception`/`StateError` report. Also clean: `date_time_extensions.dart`, `widget_list_extensions.dart`, `debouncer.dart`, the records files, and the redirecting union cases in `vx/shape.dart`. All findings are at error severity.
Delivery target: Merge
Delivery: Pending — scoped PR, required CI, merge and main CI.
