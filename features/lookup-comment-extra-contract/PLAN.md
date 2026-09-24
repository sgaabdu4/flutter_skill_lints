# Lookup, comment and router-extra contracts

Status: Complete

## Outcome + scope

Align three lints with the building-flutter-apps skill. `linear_id_lookup_in_hot_path` (#87) reports only repeated id lookups: inside a loop, a collection-for, an iteration callback over a collection, or a widget build path. It no longer reports one-off lookups based on class names. `avoid_commented_out_code` (#91) no longer treats parenthesized or hyphenated prose as a call. `router_complex_extra` (#60) keeps reporting every `extra`. Its correction now points to stable IDs or path/query params through typed routes, and no longer suggests an `extraCodec`.

## Repository context

Owners: `lib/src/rules/runtime_bug_source_rules/` (lookup rule), `lib/src/additional_lints/rules/avoid_commented_out_code.dart`, and `lib/src/rules/router_source_rules/router_source_rules_part_01.dart`. Tests: `test/source_scanner_rules_test/source_scanner_rules_part_15.dart`, `test/additional_lints_false_positive_test.dart` (the comment rule had no test file) and `test/plugin_registration_test.dart`.

## Decisions + authorization

Blockers: None
Authority: The user decided the per-issue scope. Skill `references/performance.md` rule 15 and "Pre-index repeated id lookups" ban repeated lookups only. The skill uses typed routes and never uses `extra`, so the rule keeps flagging `extra` even when a codec is configured.

- Repetition comes from the resolved AST, with no name checks. A loop body, condition or updater counts. So does a collection-for element or a positional callback on an `Iterable`/`Map` target (`Map.putIfAbsent`/`update` run once and are excluded). A function or method whose resolved return type is Flutter `Widget` counts as a build path. The walk stops at any other closure, such as `onPressed`, and at declarations.
- The old name-keyed `*ById` manual-loop check is removed. A manual `for` scan comparing the loop item's `.id` (or `list[i].id`) is still reported when it runs inside a repeated context. That is the quadratic case `nested_linear_lookup_by_id` does not see.
- The old `indexWhere`-inside-`for` suppression is removed. The canonical nested case is now reported by both `linear_id_lookup_in_hot_path` and `nested_linear_lookup_by_id` (before, that already happened for `firstWhere`).
- Comment rule: a call-looking line needs no whitespace before `(`, as formatted Dart has none. A complete line must also parse as a Dart statement. A line that leaves a paren open still counts as the start of a multi-line call.

## Acceptance + steps

- [x] #60: the correction message drops the `extraCodec` advice and names stable IDs, path/query params and typed routes. `extra` is still reported with a codec attached.
- [x] #91: `// Glucose (GOD-POD Method)`, `// Cholesterol (total)` and `// Glucose(GOD-POD Method)` are allowed. `// foo(bar);`, `// foo(bar)`, `// final x = 1;`, multi-line calls and blocks still report.
- [x] #87: the one-off repository `replace` and one-off notifier/helper lookups are allowed. Lookups in a loop, `map`/`forEach` callback, collection-for, nested repository loop, manual loop inside a loop or callback, `build`, and a widget-returning function still report. `onPressed`, a loop iterable and `putIfAbsent` are allowed.

## Baseline + execution

Result: Passed
Evidence: Red tests first. The router message test failed on the old text. The two comment false-positive tests failed. 10 lookup tests failed (3 one-off allows and 7 repeated or build cases).
Current baseline: `dart analyze` finds no issues. `dart test` passes 2,165 tests.
Execution: One commit per issue, each green: #60, then #91, then #87.

## Risks + recovery

Dropping the class gate could over-report cold loops. Loops are the repeated case the skill bans, so this matches the skill. Lookups in widget-returning helpers outside `build` now report, which matches the per-frame build path. Recovery is a revert of the single rule commit.

## ux_reference

N/A — lint rules only; no app surface.

## Verification

Result: Passed
Evidence: Full `dart analyze` is clean and `dart test` passes 2,165 tests. The probe app, pointed at this worktree, confirms each fix. `ExampleRepository.replace` is no longer reported, and its loop-based `replaceAll` still is. A widget `build` lookup reports and its `onPressed` lookup does not. The #91 comments are not reported, and `// foo(bar);` / `// final x = 1;` still are. `state.extra` with an attached `extraCodec` still reports, with the new typed-route correction.
E2E: N/A — lint rules; exercised through `dart analyze` in the probe consumer app.
Delivery target: Merge
Delivery: Pending — scoped PR, required CI, merge and main CI.
