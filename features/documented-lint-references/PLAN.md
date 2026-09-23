# Documented lint reference parser

Status: Complete

## Outcome + scope

Repair the documentation contract test so parenthetical field examples are not treated as registered lint names. Keep unknown lint references detectable. Include the required Hard Eng startup update.

## Repository context

Owner: `test/plugin_registration_test.dart`. The native baseline fails because the companion value-object guidance includes `price` as an example inside parentheses on a Lints line.

## Decisions + authorization

Blockers: None
Authority: Autonomous package repair and release authorized by the user; this prerequisite is confined to the test parser and its regression proof.

## Acceptance + steps

- [x] Parenthetical examples, including nested parentheses, are excluded from lint references.
- [x] Real references on either side of descriptions remain checked, including unknown names.
- [x] Full native checks pass without modifying the companion documentation or disabling a check.

## Baseline + execution

Result: Passed
Evidence: `python3 .hooks/hard-eng.py check --base origin/main --plan-stage Draft` failed the documentation-reference test on the example `price`; other native checks passed.
Current baseline: The repaired full native Draft check passed all gates; 1,780 tests passed with 70.63% source line coverage. The original failure above is retained as regression evidence.
Execution: One builder repairs the existing parser, adds focused regression cases, then runs all native checks and ships the repair before feature work.

## Risks + recovery

Overly broad filtering could hide unknown references. Test known and unknown top-level names, quoted parentheses, and nested prose explicitly.

## ux_reference

N/A — test-only parser and generated tooling update; no app surface.

## Verification

Result: Passed
Evidence: All 15 plugin-registration tests passed. The full native Draft gate passed analysis, formatting, 1,780 tests, 70.63% line coverage, boundaries, duplicate/dead-code checks, performance, security, dependency and secret scans, and workflow checks. Actual diff reviewed; only synthetic examples were added.
E2E: N/A — test helper reads local Markdown; the existing documentation integration test exercises its real input.
Delivery target: Merge
Delivery: Pending — scoped PR, required CI, merge and main CI.
