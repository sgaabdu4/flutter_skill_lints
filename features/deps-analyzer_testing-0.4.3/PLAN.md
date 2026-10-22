# Bump analyzer_testing from 0.4.2 to 0.4.3

Status: Complete

## Outcome + scope

The package resolves `analyzer_testing` 0.4.3 instead of 0.4.2, with every repository check passing. The newer analyzer (14.5, pulled in by the bump) resolves a Freezed callable `state.copyWith(...)` as a function invocation on a prefixed identifier, so `state_raw_response` must match that shape too. Out of scope: other dependencies, the package version, and the publish workflow.

## Repository context

Owners: `pubspec.lock` (dependency lock); `lib/src/rules/state_source_rules.dart` (`_stateCopyWithArguments`).
The Hard Eng comment gate applies to that changed file, so its multi-line rule doc comments are removed; each restated the rule's problem and correction messages. Dependabot opened PR #111 with the bump; this plan records it for the Hard Eng plan gate.

## Decisions + authorization

Blockers: None
Handoff: Approval
Authority: The owner asked on 2026-10-22 to merge all open PRs that can go green.

## Acceptance + steps

- [x] `analyzer_testing` resolves to 0.4.3 -> `pubspec.lock` on this branch.
- [x] `state_raw_response` still reports a Freezed callable `copyWith` under analyzer 14.5 -> `test/source_scanner_rules_test.dart` `StateRawResponseTest.test_reportsFreezedCallableCopyWith`.
- [x] Repository checks pass with the new version -> the PR's Hard Eng CI check runs `python3 .hooks/hard-eng.py check` with every toolchain.

## Baseline + execution

Result: Passed
Evidence: With only the plan, CI failed `StateRawResponseTest | test_reportsFreezedCallableCopyWith` (expected lint not found); the same test passes on `8fa34e6`. A debug print showed `FunctionExpressionInvocation` with a `PrefixedIdentifier` function.
Execution: Dependabot change, one pattern added to the rule, and this plan.

## Risks + recovery

A minor or patch release can change behaviour. Recovery = revert the PR.

## ux_reference

N/A — dependency update only; no rendered interface changes.

## Verification

Result: Passed
Evidence: `dart test` (Dart 3.13.6) in the cloud container: 2714 passed, 1 skipped. PR CI runs the full `python3 .hooks/hard-eng.py check` on this branch, including tests and coverage.
E2E: N/A — no user journey changes; the package tests cover the library.

Delivery target: Merge
Delivery: Pending — PR merged into main with every required check passing.
