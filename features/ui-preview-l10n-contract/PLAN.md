# UI preview and localization contract

Status: Complete

## Outcome + scope

Align the widget-preview, localization, hardcoded-string, and accessibility lints with the building-flutter-apps skill (`widget-previews.md`, `localization.md`, `atomic-design.md`). Stop false positives on the skill's own `@Preview` example, stop endorsing `*Strings` constants classes, add the missing preview and l10n contracts, and raise every touched rule to error severity. Follow-up rows: close the reopened #52 l10n gap (prose passed to widget callbacks), drop `avoid_missing_controller` (#44), exempt atomic-design pages from `avoid_unnecessary_consumer_widgets`, and exempt `@Preview` sample data from `avoid_magic_literals`.

## Repository context

Owners: `lib/src/rules/ui_source_rules/ui_source_rules_part_01.dart` (`strings_hardcoded`, `l10n_context_direct_access`, `widget_top_level_function_boundary`), `lib/src/rules/source_scanner_rule.dart`, `lib/src/additional_lints/rules/` (`avoid_hardcoded_strings`, `avoid_returning_widgets`, `prefer_action_button_tooltip`, `avoid_missing_image_alt`, `prefer_text_rich`, `avoid_magic_literals`, `avoid_unnecessary_consumer_widgets`; `avoid_missing_controller` removed), shared resolved helpers in `lib/src/ast_utils.dart`, new rules in `lib/src/rules/widget_preview_rules.dart` and `lib/src/rules/l10n_contract_rules.dart`.

## Decisions + authorization

Blockers: None
Authority: Coordinator-assigned builder (uiB) under the flutter_skill_lints fix brief; no push, no CHANGELOG or version edits.

- `@Preview` is identified by resolved annotation type (assignable to Flutter `Preview` or `MultiPreview`); look-alike annotations still report. Only `@Preview` declarations are exempt, nothing else.
- The skill never endorses a `*Strings` constants class (R6: all user-facing strings use AppLocalizations). The `_strings.dart`, `_constants.dart`, `_keys.dart`, and `/constants/` exemptions were removed, and resolved `const` String variables and static fields in user-facing slots are reported.
- The top-level sheet helper in `common-patterns/modals-navigation.md` is not exempted. It conflicts with the skill's NEVER rule on top-level helpers in widget files and is a skill documentation bug.
- Screens are placement-defined (`presentation/screens/`, `atomic-design.md`); the screen check uses the resolved library of the constructed widget, not a name suffix.
- The gen-l10n class is identified by its fingerprint: a static field typed as Flutter `LocalizationsDelegate`.
- Arbitrary native plugins cannot be identified soundly from the semantic model. The preview dependency check covers `dart:io`, Flutter platform channels, Hive, Firebase, Dio, and `http`; other plugins stay a review/runtime boundary.
- #52 (localization.md:6, :19): `avoid_hardcoded_strings` (resolved AST) is extended rather than the line-regex `strings_hardcoded`. It reports prose passed as an argument to a function-typed value inside a class assignable to Flutter `Widget` or `State`: a `FunctionExpressionInvocation` whose callee is function-typed (callback fields, parameters, locals such as `widget.onError(...)`) or `.call(...)` on a function-typed target. Declared methods and functions (`notifier.addTodo('New Todo')`, `logEvent(...)`, `context.go(...)`) stay clean. Prose means the literal text (string, interpolation with values as `$`, or resolved `const` String) has a letter and either contains whitespace or ends in `.`, `!`, `?`, or `…` after a letter; IDs, keys, file names, and URLs (`user_42`, `Authorization`, `config.json`, `https://…/v1.2/…`) stay clean. Top-level functions outside widget/State classes are out of scope and stay a review boundary.
- #44: the skill never requires a TextField controller (grep of the skill for `controller`/`TextEditingController`/`TextField` finds only disposal rules, `presentation-widgets` State fields, and the controller-free DO example in `common-patterns/debounce-gate-batch.md:21-31`). `avoid_missing_controller` is deleted and added to the off-profile list; additional rules 239→238, additional codes 280→279, total 471→470.
- Pages (atomic-design.md:418, :475; architecture.md:59) MUST be `ConsumerWidget`/`ConsumerStatefulWidget`. `avoid_unnecessary_consumer_widgets` exempts a public, concrete class declared in a production `presentation/screens/` library, the same classifier as `atomic_page_consumer_widget` on `fix/ui-presentation-contract`. The skill places pages only under `presentation/screens/`, so no `pages/` path is added. Private helpers in screens files and widgets elsewhere still report.
- `avoid_magic_literals` exempts literals inside resolved `@Preview` functions, methods, and constructors, and inside classes that carry a resolved preview annotation or extend `Preview`/`MultiPreview` (widget-previews.md:79-91 sample data such as `id: 'preview-1'`). Look-alike `Preview` annotations still report.
- Notifier copy tracking covers AppLocalizations reads, literals returned from `build` or assigned to `state` (directly, via `AsyncData`, conditionals, switch expressions, or user-facing named arguments). Values that reach state indirectly through locals or helper calls are not tracked.

## Acceptance + steps

- [x] Severity ERROR on `strings_hardcoded`, `avoid_hardcoded_strings`, `l10n_context_direct_access`, `widget_top_level_function_boundary`, `avoid_returning_widgets`, `prefer_action_button_tooltip`, `avoid_missing_image_alt`, `prefer_text_rich`, and all new rules.
- [x] Resolved `@Preview` functions are allowed by `widget_top_level_function_boundary` and `avoid_returning_widgets`; preview sample text is allowed by `strings_hardcoded` and `avoid_hardcoded_strings`.
- [x] Corrections point to gen-l10n ARB + AppLocalizations; `*Strings` exemptions removed; `Text(AppStrings.welcome)` reports.
- [x] #52: prose passed to widget/State callbacks reports under `avoid_hardcoded_strings`; IDs, keys, protocol strings, declared methods, and preview code stay clean.
- [x] #44: `avoid_missing_controller` removed from registration, sources, tests, and counts.
- [x] Provider-free pages under `presentation/screens/` are not flagged by `avoid_unnecessary_consumer_widgets`; the rule is ERROR.
- [x] `avoid_magic_literals` allows resolved `@Preview` sample data, reports look-alikes, and is ERROR.
- [x] New rules: `widget_preview_import_leak`, `widget_preview_platform_dependency`, `widget_preview_screen`, `l10n_string_concatenation`, `l10n_notifier_localized_copy`; registration counts and inventory/coverage docs updated.

## Baseline + execution

Result: Passed
Evidence: Baseline `dart test` on origin/main: 2,144 tests passed.
Current baseline: 2,203 tests pass after the change (2,191 after the first pass; five `avoid_missing_controller` tests removed; 17 added).
Execution: First builder: four green commits (severities, preview false positives, strings/l10n contract, new rules). Follow-up builder: four green commits (#44 removal, magic-literal previews, consumer pages, #52 callback prose), then consumer probe and native gates.

## Risks + recovery

Removing the strings-file exemptions and raising severity to error surfaces existing violations in consumer apps; this is the skill contract. The notifier literal check can flag String state used as a semantic key; the skill prefers enum or sealed semantic state there. The callback prose check can flag a non-visible prose string (for example a log message) passed to a widget callback; the fix is a semantic value or an ARB lookup. Revert per commit if a rule misfires.

## ux_reference

N/A — analyzer diagnostics only; no app surface.

## Verification

Result: Passed
Evidence: `dart format lib test` clean, `dart analyze` no issues, `dart test` 2,203 passed. Consumer probe (`scratchpad/probe-ui-preview-l10n-contract`, plugin path set to this worktree): resolved preview files report no top-level/returning-widget/hardcoded-string diagnostics, and a non-preview top-level widget helper still reports all four. `Text(AppStrings.welcome)` reports `avoid_hardcoded_strings`. Leaked preview imports (3), preview IO/Hive/Dio (5), previews of screens (2), l10n concatenation (4), and notifier copy (4) report as errors. Placeholder messages and enum notifier state stay clean. Follow-up probe: `p52_form.dart:31` `widget.onError('Please choose a time first')` and `p52_controls.dart:15-16` report `avoid_hardcoded_strings` (ERROR) while `user_42`, `Authorization`, and `config.json` callback arguments stay clean; the protocol key and `id:` argument still report `avoid_magic_literals`. The controller-free `TextField(onChanged:)` has no controller diagnostic. A provider-free `AboutScreen` under `presentation/screens/` is clean while the same `AboutCard` under `widgets/` reports. The `@Preview` card with `productId: 'preview-1'` is clean; the look-alike annotation reports `avoid_magic_literals`.
E2E: N/A — lint package; the consumer probe exercises the real analyzer plugin.
Delivery target: Merge
Delivery: Pending — coordinator review and PR.
