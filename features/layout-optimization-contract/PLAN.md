# Layout and optimization skill contract

Status: Complete

## Outcome + scope

Make the lints for the skill's `layout-diagnostics.md` and `flutter-optimizations.md` references match the skill text: report skill MUST/NEVER violations as errors, stop reporting the skill's own examples, and cover documented layout failures with resolved Flutter widget types. Rules owned by other builders (hardcoded strings, `performance.md` rows) are out of scope.

## Repository context

Owners: `lib/src/rules/flutter_optimization_source_rules.dart`, `lib/src/rules/avoid_shrink_wrap.dart`, `lib/src/additional_lints/rules/{avoid_flexible_outside_flex,avoid_shrink_wrap_in_lists,use_dedicated_media_query_methods,prefer_dedicated_media_query_methods,dispose_fields,prefer_spacing}.dart`, the shared parent walk in `lib/src/additional_lints/flutter_widget_helpers.dart`, and the new `lib/src/rules/layout_diagnostics_rules.dart`. Inventory and counts live in `doc/`, `README.md` and `test/plugin_registration_test.dart`.

## Decisions + authorization

Blockers: None
Authority: Owner decision that every lint enforcing a skill MUST/NEVER rule is an ERROR; builder brief for the perf layout/optimization rows.
- `prefer_compute_over_isolate_run` is removed: the skill prescribes `Isolate.run` for one-shot work and never prefers `compute`, so the rule could only report skill-conforming code.
- `prefer_spacing` keeps reporting two or more uniform interior gaps; a single `SizedBox` gap (the skill's own rows) and `spaceBetween` rows are left alone.
- `user_visible_duration_too_long` is unchanged: `performance.md` sets a NEVER budget of 120ms for visual animation, and the optimization example's 300ms cannot be allowed without a literal exemption.
- Device-type layout checks are a runtime boundary: platform checks cannot be told apart from platform behavior soundly.

## Acceptance + steps

- [x] Opacity, save-layer filter, clip save-layer, intrinsic layout, UniqueKey/GlobalKey, key-in-build, AnimatedBuilder child, shrinkWrap, Flexible outside flex, dedicated MediaQuery and dispose_fields report as errors.
- [x] The skill's `Isolate.run` example, single-gap rows and `spaceBetween` rows no longer report.
- [x] Expanded/Flexible directly under ListView, GridView, CustomScrollView or SingleChildScrollView report.
- [x] New resolved rules: `avoid_positioned_outside_stack`, `avoid_unbounded_list_in_column`, `avoid_unbounded_text_field_in_row` (errors); `avoid_list_in_single_child_scroll_view`, `avoid_orientation_layout`, `avoid_clip_rrect_container` (warnings). Each has reported cases and skill-shaped negative controls.
- [x] Registration counts, inventory, coverage matrix and README counts updated.

## Baseline + execution

Result: Passed
Evidence: Audit probe `probe-perf` showed the rows as info/warning, false positives on the skill's examples, and no diagnostics for the gap shapes.
Current baseline: Full suite green after each step; one commit per green step.
Execution: Single builder on `fix/layout-optimization-contract`.

## Risks + recovery

New rules only report direct, resolved widget shapes; composed widgets, callbacks and method-wrapped children end the proof, so extracted widgets are never guessed. Errors can be downgraded per rule by reverting the severity line.

## ux_reference

N/A — analyzer rules only; no app surface.

## Verification

Result: Passed
Evidence: `dart format lib test` clean, `dart analyze` no issues, `dart test` 2,158 passed (1 skipped smoke test, expectations updated for the error severity). Consumer probe `probe-layout-optimization-contract` reports every violation probe at the new severity, the gap probes through the new rules, and none of the skill-shaped controls.
E2E: Passed — real Flutter consumer probe analyzed with the plugin from this worktree via `dart analyze`.
Delivery target: Merge
Delivery: Pending — branch committed locally; not pushed.
