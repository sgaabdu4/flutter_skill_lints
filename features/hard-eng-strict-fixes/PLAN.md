# Pass the strict Hard Eng rules in flutter_skill_lints

Status: Complete

## Outcome + scope

The package passes HE-COMMENT-LINES, HE-NO-SWITCH-OFF (except the findings judged false) and the dart-decimate health gate with `max_crap` 30. No rule, test or behavior is removed. Non-goal: change the `test_` method names or the lints, which the owner decided to leave open.

## Repository context

Owners: `lib/src/**` (comment blocks, unused members, tests for untested rules and fixes), `test/**`, `integration_test/plugin_smoke_test.dart`, `.dart-decimaterc.json`, `.github/workflows/dart.yml`, `.github/workflows/publish.yml`.
Same cause: N/A — no earlier fix of these causes; searched `features/` for comment cuts, which only touched files of their own task.
Single source: N/A — no value or rule is copied by this change.

## Decisions + authorization

Blockers: None
Handoff: Approval
Authority: The owner asked for this fix wave and a draft PR first. The coordinator ruled that 253 off-switch hits are false or stay open: 124 sit inside raw-string lint samples, 129 are `ignore_for_file: non_constant_identifier_names` on `test_` methods. Merge and release are not part of this task.

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
Evidence: Run 1, `python3 .hooks/hard-eng.py check` with the branch's own hooks: exit 0; lockfile, performance, actionlint, vulnerabilities, freshness, secrets-history, zizmor, format, secrets-files, types-lint, security, tests (3,291 passed in 160 s, line coverage 92.42%) and dead-code-duplicates all PASS. Two earlier runs at a machine load of 100 to 225 timed out at the 180 s pre-push limit and passed with `CI=1`. Run 2, the same command in a scratch copy with Hard Eng develop's `.hooks/` and `.agents/`: exit 1 at HE-NO-SWITCH-OFF with 253 hits, which are exactly the two classes the coordinator ruled open or false (129 file-level `ignore_for_file: non_constant_identifier_names` lines on `test_` methods and 124 lint sample strings); no comment-lines hit. The check stops at that refusal, so only `check --quick` ran there (lockfile, format, secrets-files, types-lint, all PASS); tests, security, vulnerabilities and dead-code-duplicates are not checked under develop's hooks. Run 3, `npx -y dart-decimate@0.0.76 --version` then `check . --threshold 0 --format json --strict`: dart-decimate 0.0.76, verdict pass, 0 findings, exit 0. Regression check against base 4dfebb2e: the base ran 2,790 tests (1 skipped) and the branch runs 3,291 with none skipped; every base test name still runs except the smoke test, which moved to `integration_test/` and passed in the CI Flutter smoke job. The existing `use_existing_destructuring_test.dart` is byte for byte as on main. The other edited test files differ from main only in comments and in stub code moved to `test/support/`. `dart format` clean and `dart analyze --fatal-infos` clean.
E2E: N/A — no user journey; the rule tests run the real analyzer on an in-memory project.
Real service: N/A — the change calls no outside service; it only changes analyzer rule code and its tests.
Retro: Done — the new tests found faults in rules and fixes (fixes that never ran, wrong indentation, a greedy suffix match); each was repaired with its test. Test files load the analyzer once each, so new cases run from four files.

Delivery target: PR
Delivery: Pending — draft PR, then ready for review.
