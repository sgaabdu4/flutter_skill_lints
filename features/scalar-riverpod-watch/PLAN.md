# Scalar Riverpod watch diagnostics

Status: Complete

## Outcome + scope

Allow direct watches of scalar provider values without suggesting an identity selector. Preserve diagnostics for broad structured state and forbidden identity selectors. Also prevent the shorthand bulk fix from editing diagnostics belonging to other rules. Release both corrections as 0.12.1.

## Repository context

Owners: `lib/src/rules/riverpod_source_rules.dart`, its rule parts, the scanner context, the existing scanner tests, and `prefer_dot_shorthands_fix.dart` with its existing tests. The current rule scans source text and provider names without considering the resolved watch result type. A synthetic boolean provider reproduces the contradictory diagnostics.

## Decisions + authorization

Blockers: None
Authority: Autonomous. The user explicitly approved fixing and releasing this lint package with synthetic examples before resuming consumer upgrades. One builder; no delegation. Admin merges are explicitly authorized for this repair/release only when every required check passes; branch rules remain unchanged.

## Acceptance + steps

- [x] Scalar watches, including nullable scalar values, remain valid without identity selectors; focused regression tests pass.
- [x] Broad structured watches still report, and identity selectors remain forbidden; existing and negative-control tests pass.
- [x] Generated notifier build methods may watch their dependencies directly.
- [x] Bulk shorthand fixes leave unrelated instance accesses unchanged; regression tests exercise a foreign diagnostic and retain valid shorthand edits.
- [x] Real analyzer-server consumer proof confirms the correction; full package checks pass.
- [x] Version and changelog describe the repair using only synthetic examples.

## Baseline + execution

Result: Passed
Evidence: The initial native Draft gate found the documentation parser treating `price` as a lint; PR #27 repairs it and is merged. A refreshed native Draft check on the new branch verifies the current Hard Eng setup before implementation.
Current baseline: The refreshed native Draft check passed all checks on the unchanged production tree: 1,780 tests and 70.63% line coverage. PR #27 is merged with green main CI and a passing native delivered check.
Execution: One builder implements at the existing rule owner, reviews the actual diff, and runs integrated checks.

## Risks + recovery

A broad exemption could conceal a useful rebuild boundary. Use resolved Dart types, test structured state as a negative control, and retain the identity-select rule. Do not disable or suppress consumer diagnostics.

## ux_reference

N/A — analyzer diagnostics only; no visual product surface changes.

## Verification

Result: Passed
Evidence: 634 focused tests and all 1,784 package tests pass; line coverage is 70.68%. Strict analysis passes after correcting two test-fixture quote-style findings. Format, import boundaries, zero-finding duplicate/dead-code checks, security, dependencies, secrets, performance and workflow checks pass. Actual diff reviewed against the requested scope.
E2E: Passed — the real Flutter analyzer accepts scalar watches while reporting the structured broad watch and forbidden identity selector. The native editor file-wide shorthand action rewrites two valid shorthands and preserves an unrelated ref.read call; subsequent analysis reports no syntax errors.
Delivery target: Merge
Delivery: Pending — PR/main CI, automatic release tag, pub.dev publication and published-package consumer verification.
