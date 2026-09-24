# UI preview and localization contract

Status: Complete

## Outcome + scope

Align the widget-preview, localization, hardcoded-string, and accessibility lints with the building-flutter-apps skill (`widget-previews.md`, `localization.md`, `atomic-design.md`). Stop false positives on the skill's own `@Preview` example, stop endorsing `*Strings` constants classes, add the missing preview and l10n contracts, and raise every touched rule to error severity.

## Repository context

Owners: `lib/src/rules/ui_source_rules/ui_source_rules_part_01.dart` (`strings_hardcoded`, `l10n_context_direct_access`, `widget_top_level_function_boundary`), `lib/src/rules/source_scanner_rule.dart`, `lib/src/additional_lints/rules/` (`avoid_hardcoded_strings`, `avoid_returning_widgets`, `prefer_action_button_tooltip`, `avoid_missing_image_alt`, `prefer_text_rich`), shared resolved helpers in `lib/src/ast_utils.dart`, new rules in `lib/src/rules/widget_preview_rules.dart` and `lib/src/rules/l10n_contract_rules.dart`.

## Decisions + authorization

Blockers: None
Authority: Coordinator-assigned builder (uiB) under the flutter_skill_lints fix brief; no push, no CHANGELOG or version edits.

- `@Preview` is identified by resolved annotation type (assignable to Flutter `Preview` or `MultiPreview`); look-alike annotations still report. Only `@Preview` declarations are exempt, nothing else.
- The skill never endorses a `*Strings` constants class (R6: all user-facing strings use AppLocalizations). The `_strings.dart`, `_constants.dart`, `_keys.dart`, and `/constants/` exemptions were removed, and resolved `const` String variables and static fields in user-facing slots are reported.
- The top-level sheet helper in `common-patterns/modals-navigation.md` is not exempted. It conflicts with the skill's NEVER rule on top-level helpers in widget files and is a skill documentation bug.
- Screens are placement-defined (`presentation/screens/`, `atomic-design.md`); the screen check uses the resolved library of the constructed widget, not a name suffix.
- The gen-l10n class is identified by its fingerprint: a static field typed as Flutter `LocalizationsDelegate`.
- Arbitrary native plugins cannot be identified soundly from the semantic model. The preview dependency check covers `dart:io`, Flutter platform channels, Hive, Firebase, Dio, and `http`; other plugins stay a review/runtime boundary.
- Notifier copy tracking covers AppLocalizations reads, literals returned from `build` or assigned to `state` (directly, via `AsyncData`, conditionals, switch expressions, or user-facing named arguments). Values that reach state indirectly through locals or helper calls are not tracked.

## Acceptance + steps

- [x] Severity ERROR on `strings_hardcoded`, `avoid_hardcoded_strings`, `l10n_context_direct_access`, `widget_top_level_function_boundary`, `avoid_returning_widgets`, `prefer_action_button_tooltip`, `avoid_missing_image_alt`, `prefer_text_rich`, and all new rules.
- [x] Resolved `@Preview` functions are allowed by `widget_top_level_function_boundary` and `avoid_returning_widgets`; preview sample text is allowed by `strings_hardcoded` and `avoid_hardcoded_strings`.
- [x] Corrections point to gen-l10n ARB + AppLocalizations; `*Strings` exemptions removed; `Text(AppStrings.welcome)` reports.
- [x] New rules: `widget_preview_import_leak`, `widget_preview_platform_dependency`, `widget_preview_screen`, `l10n_string_concatenation`, `l10n_notifier_localized_copy`; registration counts and inventory/coverage docs updated.

## Baseline + execution

Result: Passed
Evidence: Baseline `dart test` on origin/main: 2,144 tests passed.
Current baseline: 2,191 tests pass after the change.
Execution: One builder, four green commits (severities, preview false positives, strings/l10n contract, new rules), then consumer probe and native gates.

## Risks + recovery

Removing the strings-file exemptions and raising severity to error surfaces existing violations in consumer apps; this is the skill contract. The notifier literal check can flag String state used as a semantic key; the skill prefers enum or sealed semantic state there. Revert per commit if a rule misfires.

## ux_reference

N/A — analyzer diagnostics only; no app surface.

## Verification

Result: Passed
Evidence: `dart format lib test` clean, `dart analyze` no issues, `dart test` 2,191 passed. Consumer probe (`scratchpad/probe-ui-preview-l10n-contract`, plugin path set to this worktree): resolved preview files report no top-level/returning-widget/hardcoded-string diagnostics, and a non-preview top-level widget helper still reports all four. `Text(AppStrings.welcome)` reports `avoid_hardcoded_strings`. Leaked preview imports (3), preview IO/Hive/Dio (5), previews of screens (2), l10n concatenation (4), and notifier copy (4) report as errors. Placeholder messages and enum notifier state stay clean.
E2E: N/A — lint package; the consumer probe exercises the real analyzer plugin.
Delivery target: Merge
Delivery: Pending — coordinator review and PR.
