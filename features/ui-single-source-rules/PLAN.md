# Release 0.16.0: base control rule and Hard Eng theme path rule

Status: Ready

## Outcome + scope

`dart analyze` reports base buttons, text fields, dropdowns, dialogs and search widgets built outside the shared UI library, reads the library paths from `hard-eng.gates.json`, and judges a theme or token file the way Hard Eng does. Out of scope: the theme path case file in the Flutter skill repository (it does not exist yet), a pub.dev release, and the string rule `avoid_magic_literals`, which keeps its own `/core/theme/` test.

## Repository context

Owners: `lib/src/rules/ui_single_source_rules.dart` (new rule), `lib/src/rules/ui_project_paths.dart` (theme path port and gates reader), `lib/src/rules/source_scanner_rule.dart` (`isThemeDefFile`, `isUiLibraryFile`), `lib/src/rules/ui_source_rules/ui_source_rules_part_01.dart` (token rules), `README.md` and `doc/` (counts, inventory), `CHANGELOG.md` and `pubspec.yaml` (version). Hard Eng's `is_theme_path` in `.hooks/ui_rules.py` and `shipping.ui_library` in `hard-eng.gates.json` are the sources this change follows.
Same cause: N/A — the two rule changes have different causes: a missing rule, and a theme test that differs from Hard Eng's.
Single source: the theme path test and the library paths each live once here; the old `isThemeDefFile` test is replaced, not kept beside the new one.

## Decisions + authorization

Blockers: the theme path case file does not exist in the Flutter skill repository, so the case file test is not in this change.
Handoff: Approval
Authority: Standing approval of 2026-11-15 for this package, and the Hard Eng UI single source plan for the rules.

## Acceptance + steps

- [x] Base buttons, text fields, dropdowns, dialogs and search widgets outside the library report; inside it none → `test/ui_single_source_rules_test.dart::base controls and raw values outside the library and theme are reported`
- [x] A `.symmetric(vertical: 2)`, a `.new(fontSize: 18)` and a widget option `fontSize: 13` report outside theme files, and a `palette/` or `colors/` folder is a theme folder → `test/ui_single_source_rules_test.dart::base controls and raw values outside the library and theme are reported`
- [x] Library paths come from `shipping.ui_library` of the nearest `hard-eng.gates.json`, with `lib/core/widgets/` when the file or the key is missing → `test/ui_single_source_rules_test.dart::base controls and raw values outside the library and theme are reported`
- [x] The rule count, the inventory and the version agree → `test/plugin_registration_test.dart::registers every rule once` and the CI version check
- [ ] The theme path test passes every case of the Flutter skill's case file → N/A — blocked: the case file does not exist yet

## Baseline + execution

Result: Passed
Evidence: On main 8b1d029 the new test failed because the rule did not exist, and with the old theme test restored the `palette/` and `colors/` rows failed. After the change the full `dart test` run failed only the registration rows (rule count, diagnostic count, rule docs), which the counts, inventory and doc comment then fixed.
Execution: One builder; one commit for the rule, the theme path port and the plan.

## Risks + recovery

Risk: a project with base controls outside `lib/core/widgets/` and no `ui_library` key gets new errors. Recovery: list its library folder in `ui_library`, or move the control into the library. Risk: a `palette/` or `colors/` folder now exempts token rules. Recovery: rename the folder.

## ux_reference

N/A — analyzer rules only; no rendered interface of this package changes.

## Sources + coverage

Sources: the Hard Eng UI single source plan rows for the lint plugin, Hard Eng's `is_theme_path` and `shipping.ui_library`.

## Verification

Result: Pending
Evidence: Pending the final run.
E2E: N/A — no user journey; the real analyzer server run is the timing run below.
Retro: Pending.

Delivery target: PR
Delivery: Pending.
