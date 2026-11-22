# Release 0.16.0: base control rule and Hard Eng theme path rule

Status: Complete

## Outcome + scope

`dart analyze` reports base buttons, text fields, dropdowns, dialogs, search widgets, checkboxes, radios, switches and sliders built outside the shared UI library, treats `lib/core/widgets/` as the shared UI library, and judges a theme or token file the way Hard Eng does. Out of scope: the string rule `avoid_magic_literals`, which keeps its own `/core/theme/` test.

## Repository context

Owners: `lib/src/rules/ui_single_source_rules.dart` (new rule), `lib/src/rules/ui_theme_paths.dart` (theme path port), `lib/src/rules/source_scanner_rule.dart` (`isThemeDefFile`, `isUiLibraryFile`), `lib/src/rules/ui_source_rules/ui_source_rules_part_01.dart` (token rules), `README.md` and `doc/` (counts, inventory), `CHANGELOG.md` and `pubspec.yaml` (version). Hard Eng's `is_theme_path` in `.hooks/ui_rules.py` is the source this change follows.
Same cause: N/A — the two rule changes have different causes: a missing rule, and a theme test that differs from Hard Eng's.
Single source: `isThemeDefFile` uses the single ported `isThemePath` test for all token rules (replacing the old `/core/theme/` and `_tokens.dart` test), and the library path lives once in `isUiLibraryFile`; `avoid_magic_literals` is out of scope and keeps its separate `/core/theme/` string test.

## Decisions + authorization

Decisions: (1) Shared UI library is fixed to `lib/core/widgets/` per `building-flutter-apps`, intentionally diverging from Source 1's `hard-eng.gates.json` `ui_library` lookup; (2) the base-control `scannerRule` resolves built classes via AST/type resolution without a text pre-skip so cross-file `typedef` aliases and context-inferred `.new()` calls report; (3) checkboxes, radios, switches, and sliders are included alongside buttons, text fields, dropdowns, dialogs, and search widgets; (4) delivered in a single PR in this repository.
Blockers: None
Handoff: Approval
Authority: Standing approval of 2026-11-15 for this package, Hard Eng UI single source plan, and maintainer approval on 2026-11-22 to publish `0.16.0` and run the UI single source rollout.

## Acceptance + steps

- [x] Base buttons, text fields, dropdowns, dialogs, search widgets, checkboxes, radios, switches and sliders outside the library report; inside it none → `test/ui_single_source_rules_test.dart::base controls and raw values outside the library and theme are reported`
- [x] A `.symmetric(vertical: 2)`, a `.new(fontSize: 18)` and a widget option `fontSize: 13` report outside theme files, and a `palette/` or `colors/` folder is a theme folder → `test/ui_single_source_rules_test.dart::base controls and raw values outside the library and theme are reported`
- [x] The shared UI library is `lib/core/widgets/`; a `shipping.ui_library` key is ignored → `test/ui_single_source_rules_test.dart::base controls and raw values outside the library and theme are reported`
- [x] A real analyzer server run: a control in `lib/core/widgets/` is clean and one in `lib/screens/` reports once → `integration_test/plugin_smoke_test.dart::loads canonical configuration with riverpod_lint in a real Flutter analysis server run`
- [x] The theme path function answers at least 94 rows of `tool/test_fixtures/theme_paths.json`, fetched from `raw.githubusercontent.com` at the revision in `test/theme_paths_revision.txt` into ignored `.dart_tool/theme_paths/` (no submodule, so the published repo tree holds no gitlink); a failed fetch fails the test → `test/theme_path_cases_test.dart::theme path function answers every case of the Flutter skill case file`
- [x] A base control with type arguments (`DropdownButton<Map<String, int>>`) reports → `test/ui_single_source_rules_test.dart::base controls and raw values outside the library and theme are reported`
- [x] The rule count, the inventory and the version agree → `test/plugin_registration_test.dart::registers every rule once` and the CI version check
- [x] Stop hook and `check --quick` timing on a copy of a real Flutter app (2 forced runs each, before vs after the new rules) shows no added Stop-hook time → N/A — recorded in Verification below

## Baseline + execution

Result: Passed
Evidence: On main 8b1d029 the new test failed because the rule did not exist, and with the old theme test restored the `palette/` and `colors/` rows failed. After the change the full `dart test` run failed only the registration rows (rule count, diagnostic count, rule docs), which the counts, inventory and doc comment then fixed.
Execution: One builder; delivered in one PR in this repository, with separate repair commits for rule counts and review findings.

## Risks + recovery

Risk: a project with base controls outside `lib/core/widgets/` gets new errors. Recovery: move the control into the library. Risk: a `palette/` or `colors/` folder now exempts token rules. Recovery: rename the folder.

## ux_reference

N/A — analyzer rules only; no rendered interface of this package changes.

## Sources + coverage

Sources: the Hard Eng UI single source plan (read in full); Hard Eng's `is_theme_path` (read in full).
Reviewer: Independent second reader checked both sources against this plan and reported mismatches on `ui_library` (`hard-eng.gates.json` ignored), Decision 12 timing proof, and unlogged `scannerRule`/scope/fixture details.
Deliverables: None

- Hard Eng UI single source plan, base control rule (including checkboxes, radios, switches and sliders): In scope — Base buttons, text fields, dropdowns, dialogs, search widgets, checkboxes, radios, switches and sliders outside the library report
- Hard Eng UI single source plan, raw-token gaps: In scope — A `.symmetric(vertical: 2)`, a `.new(fontSize: 18)` and a widget option `fontSize: 13` report outside theme files, and a `palette/` or `colors/` folder is a theme folder
- Hard Eng UI single source plan, `ui_library` from `hard-eng.gates.json`: Proposal — fix the shared UI library to `lib/core/widgets/` per `building-flutter-apps` and ignore `shipping.ui_library`; yes — user, 2026-11-22 maintainer approval
- Hard Eng `is_theme_path` and pinned case list: In scope — The theme path function answers at least 94 rows of `tool/test_fixtures/theme_paths.json`, fetched from `raw.githubusercontent.com` at the revision in `test/theme_paths_revision.txt` into ignored `.dart_tool/theme_paths/`
- Hard Eng `is_theme_path`, `avoid_magic_literals` string rule: Proposal — keep `/core/theme/` in `avoid_magic_literals` outside token-rule scope; yes — user, 2026-11-22 maintainer approval
- Hard Eng UI single source plan, `scannerRule` class resolution refinement: In scope — A base control with type arguments (`DropdownButton<Map<String, int>>`) reports
- Hard Eng UI single source plan, Decision 12 Stop hook and `check --quick` timing proof: In scope — Stop hook and `check --quick` timing on a copy of a real Flutter app

## Verification

Result: Passed
Evidence: `dart test` passed 3,606 tests (exit 0). `dart analyze --fatal-infos .`, `dart format --set-exit-if-changed .` and `dart pub publish --dry-run` (0 warnings) were clean. The new test failed before the rule existed, and failed on the `palette/` and `colors/` rows with the old theme test restored. On a copy of a real Flutter app, `dart analyze` with the new plugin adds only 9 `ui_base_control_outside_library` errors (one scratch file, 8 real controls) and no other change. Decision 12 balanced ABBA timing on a real Flutter app copy (`^0.15.0` base vs local `0.16.0` head with `isUiLibraryFile` early return, 2 forced runs each with `types-lint` running `dart analyze --fatal-infos .`): Stop hook CPU `45.26 s` and `35.33 s` (base, wall `27.63 s` and `21.76 s`) vs `25.10 s` and `30.35 s` (head, wall `16.13 s` and `17.68 s`; head faster on both runs); `check --quick` CPU `59.14 s` and `58.33 s` (base, wall `45.23 s` and `41.36 s`) vs `61.88 s` and `32.58 s` (head, wall `42.65 s` and `20.19 s`; head faster on both wall runs and lower mean CPU `47.23 s` vs `58.74 s`).
E2E: N/A — no user journey; the real analyzer server run on the app copy is the timing run above.
Real service: Passed — raw.githubusercontent.com: cleared `.dart_tool/theme_paths/` and ran `dart test test/theme_path_cases_test.dart` on a live cache miss; fetched `tool/test_fixtures/theme_paths.json` at revision `81c9e29ebc3107df0f37653a7f31c154cb4ffd17` (HTTP 200, 11,029 bytes, all 94 rows matched; no fake used; non-200 refusal not induced against live GitHub raw endpoint).
Retro: (1) the rule count test pinned two counts, and the first run found only one -> None — the full run found the second before the push, and the repair has its own commit; (2) the theme case file the plan names did not exist at first -> the test was added once the skill repository held it, and it is fetched by the test, not held as a submodule, so the publish workflow needs no submodule checkout.

Review fixed: a `typedef AppField = TextField` from another file, and a control whose type comes from context such as `acceptField(.new())`, escaped the rule :: both are reported now; the rule resolves the built class and no longer skips a file that never names a control.
Review declined: self-contained fixture packages with their own `pubspec.yaml` under `test/fixtures/` should be marked `isTestFile` :: Dart analyzes a directory with its own `pubspec.yaml` as a separate package (inheriting parent `analysis_options.yaml` unless it adds its own; `analyzer: exclude:` skips excluded paths in normal scans from an ancestor root, but Dart can still analyze an excluded file or directory when it is named explicitly on the `dart analyze` command line or depending on inherited options when `dart analyze` is launched from inside it), so production rules such as `a11y_text_scale_clamp` apply to its `lib/main.dart` whenever analyzed; this trade-off is intentional because marking its `lib/main.dart` as `isTestFile` causes test-only rules (`test_uncontrolled_scope`) to misfire on valid `runApp(ProviderScope(...))` startup code, as proved by `test/ui_single_source_rules_test.dart::allowsProviderScopeInSelfContainedFixtureMain`.

Delivery target: Merge
Delivery: Pending — required remote proof.
