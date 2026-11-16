# Pass the strict Hard Eng rules in flutter_skill_lints

Status: Complete

## Outcome + scope

The package passes HE-COMMENT-LINES, HE-NO-SWITCH-OFF (except the lint sample strings judged false) and the dart-decimate health gate with `max_crap` 30. Two rules that reported the same sites as another rule are removed: `avoid_banned_types` (same `dynamic` sites as `avoid_dynamic_except_json_maps`) and `strings_hardcoded` (same lines as `avoid_hardcoded_strings`). The project config rule reads `include:` files, accepts the `rule: true` map form, and asks for `riverpod_lint` and the `*.arb` exclude only when they apply. Two correction messages no longer advise an ignore. Sync `Notifier.build()` also reports load work started from `then`, `catchError` or `whenComplete` on a microtask. The 129 `ignore_for_file: non_constant_identifier_names` lines are gone: each `test_` method is a private lowerCamel method, and each class lists its cases once in a `_allCases` getter that `analysisRuleSuite` runs, with the old test names. A class or method left out of a registration fails `dart analyze --fatal-infos` as an unused element. Non-goal: change the lints include.

## Repository context

Owners: `lib/src/**` (comment blocks, unused members, tests for untested rules and fixes), `test/**`, `integration_test/plugin_smoke_test.dart`, `.dart-decimaterc.json`, `.github/workflows/dart.yml`, `.github/workflows/publish.yml`.
Same cause: N/A — no earlier fix of these causes; searched `features/` for comment cuts, which only touched files of their own task.
Single source: N/A — no value or rule is copied by this change.

## Decisions + authorization

Blockers: None
Handoff: Approval
Authority: The owner asked for this fix wave and a draft PR first. The coordinator ruled that the 124 off-switch hits inside raw-string lint samples are false, and later ruled that the 129 `test_` method ignores are removed by the private-method registration. Merge and release are not part of this task.

## Acceptance + steps

- [x] N/A — the proof is the whole-project pass of the comment-lines rule, which must list no `comment block` hit in `lib/` or `test/`.
- [x] `integration_test/plugin_smoke_test.dart::loads canonical configuration with riverpod_lint in a real Flutter analysis server run` has no `skip:` and runs in the Flutter smoke job without a flag.
- [x] N/A — the proof is dart-decimate 0.0.76, which must report no `unused-class-member`.
- [x] N/A — the proof is dart-decimate 0.0.76 with `max_crap` 30, which must report no `high-crap-score`; the new tests are the work, not the proof.
- [x] N/A — the proof is the passing test total after the change, at least the total before (2,782 plus new cases).

## Baseline + execution

Result: Passed
Evidence: Dart 3.14.0, base 4dfebb2e: `dart run coverage:test_with_coverage --branch-coverage` passed in 102 s. dart-decimate 0.0.76 reported 157 `high-crap-score` and 3 `unused-class-member`.
Execution: One builder for the mechanical cuts, then one worker per batch of untested rules and fixes.

## Risks + recovery

Risk: a doc comment cut to one sentence loses detail. Recovery: the git history of each cut commit.
Risk: new tests add run time, and the 180 s pre-push limit is tight. Measured: the full coverage run takes 160 to 167 s at a machine load of 40 to 70, and times out at 180 s at a load above 100 (the base suite took 102 s with no other load). Recovery: the new cases run from four aggregate files, so each analyzer load is paid once; CI uses the 600 s budget and passes.

## ux_reference

N/A — analyzer diagnostics have no visual interface.

## Sources + coverage

Sources: N/A — the request is the only source.

## Verification

Result: Passed
Evidence: Run 1, `python3 .hooks/hard-eng.py check` with the branch's own hooks: exit 0; lockfile, performance, actionlint, vulnerabilities, freshness, secrets-history, zizmor, secrets-files, format, types-lint, security, tests (3,291 passed in 149 s, line coverage 92.42%) and dead-code-duplicates all PASS. Earlier runs at machine load above 100 timed out at the 180 s pre-push limit and passed with `CI=1`. Run 2a, the same command in a scratch copy with the hooks of origin/develop (80756642): exit 1 at HE-NO-SWITCH-OFF with 124 hits, all `// ignore_for_file:` lines inside lint sample strings; the 129 `test_` hits and every comment-lines hit are gone. The check stops at that refusal, so no gate ran. Run 2b, the same scratch copy with the hooks of the unmerged branch `fix/whole-project-false-findings` (0d51fefe), which reads those strings correctly: the whole-project pass is clean; lockfile, performance, actionlint, vulnerabilities, freshness, secrets-history, zizmor, secrets-files, format, types-lint and tests (3,291 passed, `CI=1` budget) PASS; security and dead-code-duplicates FAIL on that branch's own files (`.hooks/source_scan.py:147` and `.agents/starters/flutter/pubspec.yaml`), not on package files. Run 3, `npx -y dart-decimate@0.0.76 --version` then `check . --threshold 0 --format json --strict`: dart-decimate 0.0.76, verdict pass, 0 findings, exit 0. Raw-read marks: a search of `lib/`, `test/`, `doc/` and the README for every raw-line off-switch form in item 2 of the addendum found none. Regression check against base 4dfebb2e: the base ran 2,790 tests (1 skipped) and the branch runs 3,291 with none skipped; every base test name still runs except the smoke test, which moved to `integration_test/` and passed in the CI Flutter smoke job. `dart format` clean and `dart analyze --fatal-infos` clean.
Test names: the full list of 3,291 test names, results and skip flags is equal before and after the rename (`dart test --reporter json`, compared as sorted multisets; logs `fsl-names-before.txt` and `fsl-names-after.txt`). `test_reflective_loader` is removed from `dev_dependencies`; nothing uses it.
E2E: N/A — no user journey; the rule tests run the real analyzer on an in-memory project.
Real service: N/A — the change calls no outside service; it only changes analyzer rule code and its tests.
Retro: Done — the new tests found faults in rules and fixes (fixes that never ran, wrong indentation, a greedy suffix match); each was repaired with its test. Test files load the analyzer once each, so new cases run from four files.

Delivery target: PR
Delivery: Pending — draft PR, then ready for review.
