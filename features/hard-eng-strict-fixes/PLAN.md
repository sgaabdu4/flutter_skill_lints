# Pass the strict Hard Eng rules in flutter_skill_lints

Status: Ready

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

- [ ] N/A — the proof is the whole-project pass of HE-COMMENT-LINES, which must list no `comment block` hit in `lib/` or `test/`.
- [ ] `integration_test/plugin_smoke_test.dart::loads canonical configuration with riverpod_lint in a real Flutter analysis server run` has no `skip:` and runs in the Flutter smoke job without a flag.
- [ ] N/A — the proof is dart-decimate 0.0.76, which must report no `unused-class-member`.
- [ ] N/A — the proof is dart-decimate 0.0.76 with `max_crap` 30, which must report no `high-crap-score`; the new tests are the work, not the proof.
- [ ] N/A — the proof is the passing test total after the change, at least the total before (2,782 plus new cases).

## Baseline + execution

Result: Passed
Evidence: Dart 3.14.0, base 4dfebb2e: `dart run coverage:test_with_coverage --branch-coverage` passed in 102 s. dart-decimate 0.0.76 reported 157 `high-crap-score` and 3 `unused-class-member`.
Execution: One builder for the mechanical cuts, then one worker per batch of untested rules and fixes.

## Risks + recovery

Risk: a doc comment cut to one sentence loses detail. Recovery: the git history of each cut commit.
Risk: new tests add run time. Recovery: the suite stays far under the 180 s pre-push limit.

## ux_reference

N/A — analyzer diagnostics have no visual interface.

## Sources + coverage

Sources: N/A — the request is the only source.

## Verification

Result: Pending
Evidence: Pending.
E2E: N/A — no user journey; the rule tests run the real analyzer on an in-memory project.
Real service: N/A — the change calls no outside service; it only changes analyzer rule code and its tests.
Retro: Pending

Delivery target: PR
Delivery: Pending — draft PR, then ready for review.
