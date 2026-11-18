# Release 0.16.0: base control rule and Hard Eng theme path rule

Status: Complete

## Outcome + scope

`dart analyze` reports base buttons, text fields, dropdowns, dialogs and search widgets built outside the shared UI library, reads the library paths from `hard-eng.gates.json`, and judges a theme or token file the way Hard Eng does. Out of scope: a pub.dev release, and the string rule `avoid_magic_literals`, which keeps its own `/core/theme/` test.

## Repository context

Owners: `lib/src/rules/ui_single_source_rules.dart` (new rule), `lib/src/rules/ui_project_paths.dart` (theme path port and gates reader), `lib/src/rules/source_scanner_rule.dart` (`isThemeDefFile`, `isUiLibraryFile`), `lib/src/rules/ui_source_rules/ui_source_rules_part_01.dart` (token rules), `README.md` and `doc/` (counts, inventory), `CHANGELOG.md` and `pubspec.yaml` (version). Hard Eng's `is_theme_path` in `.hooks/ui_rules.py` and `shipping.ui_library` in `hard-eng.gates.json` are the sources this change follows.
Same cause: N/A — the two rule changes have different causes: a missing rule, and a theme test that differs from Hard Eng's.
Single source: the theme path test and the library paths each live once here; the old `isThemeDefFile` test is replaced, not kept beside the new one.

## Decisions + authorization

Blockers: None
Handoff: Approval
Authority: Standing approval of 2026-11-15 for this package, and the Hard Eng UI single source plan for the rules.

## Acceptance + steps

- [x] Base buttons, text fields, dropdowns, dialogs and search widgets outside the library report; inside it none → `test/ui_single_source_rules_test.dart::base controls and raw values outside the library and theme are reported`
- [x] A `.symmetric(vertical: 2)`, a `.new(fontSize: 18)` and a widget option `fontSize: 13` report outside theme files, and a `palette/` or `colors/` folder is a theme folder → `test/ui_single_source_rules_test.dart::base controls and raw values outside the library and theme are reported`
- [x] Library paths come from `shipping.ui_library` of the nearest `hard-eng.gates.json`, with `lib/core/widgets/` when the file or the key is missing → `test/ui_single_source_rules_test.dart::base controls and raw values outside the library and theme are reported`
- [x] A real analyzer server run reads the nearest `hard-eng.gates.json`: a control in the listed library is clean and one outside it reports once → `integration_test/plugin_smoke_test.dart::loads canonical configuration with riverpod_lint in a real Flutter analysis server run`
- [x] The theme path function answers all 94 rows of the Flutter skill's case file, fetched at the revision in `test/theme_paths_revision.txt` (no submodule, so the published repo tree holds no gitlink); a failed fetch fails the test → `test/theme_path_cases_test.dart::theme path function answers every case of the Flutter skill case file`
- [x] A base control with type arguments (`DropdownButton<Map<String, int>>`) reports, and a `[...]` or `[!...]` set in a library path reads as Python `fnmatch` does → `test/ui_single_source_rules_test.dart::base controls and raw values outside the library and theme are reported`
- [x] The rule count, the inventory and the version agree → `test/plugin_registration_test.dart::registers every rule once` and the CI version check

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

Result: Passed
Evidence: `dart test` passed 3,598 tests (exit 0). `dart analyze --fatal-infos .`, `dart format --set-exit-if-changed .` and `dart pub publish --dry-run` (0 warnings) were clean. The new test failed before the rule existed, and failed on the `palette/` and `colors/` rows with the old theme test restored. On a copy of a real Flutter app, `dart analyze` with the new plugin adds only 9 `ui_base_control_outside_library` errors (one scratch file, 8 real controls) and no other change; CPU time (user plus sys) on the least loaded pair was 83.3 s before and 85.1 s after, and the other pairs differ by less than the noise of a loaded machine.
E2E: N/A — no user journey; the real analyzer server run on the app copy is the timing run above.
Retro: (1) the rule count test pinned two counts, and the first run found only one -> None — the full run found the second before the push, and the repair has its own commit; (2) the theme case file the plan names did not exist at first -> the test was added once the skill repository held it,, and it is fetched by the test, not held as a submodule, so the publish workflow needs no submodule checkout.

Review declined: A gates file added next to a source folder is ignored for up to ten seconds :: The analyzer does not re-run analysis when a non-Dart file changes, with or without the cache, and the ten second recheck of an empty lookup is the agreed trade-off for the cache.
Review declined: A `typedef AppField = TextField` from another file escapes the control rule :: The rule misses it: the alias declaration is not reported and the screen never names the control. Aliasing a Flutter base control in one file and building it in another is far-fetched, and a check on every constructor would add time to every file.

Delivery target: PR
Delivery: PR open, checks pending, not merged; merge waits for the owner.
