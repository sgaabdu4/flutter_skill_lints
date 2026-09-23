# Flutter initialization, cleanup and layout checks

Status: Complete

## Outcome + scope

Respect valid Dart default initialization and Flutter lifecycle/layout boundaries. Correct existing checks for implicitly initialized nullable locals, fields initialized in State.initState, registered cleanup callbacks and Expanded widgets whose layout parent is supplied by widget composition. Retain diagnostics for proven uninitialized reads, missing cleanup and invalid render-object parents.

## Repository context

Owners: avoid_unassigned_local_variable.dart, avoid_unassigned_late_fields.dart, avoid_disposing_late_fields.dart, unassigned_field_analysis.dart, avoid_undisposed_instances.dart and avoid_flexible_outside_flex.dart. Reuse their existing analyzer regression suites and real Flutter plugin smoke.

## Decisions + authorization

Blockers: None
Authority: Autonomous. The user approved repairing and releasing this lint package to unblock consumer upgrades. One builder; no delegation. Admin merge only after required CI passes; branch protections stay unchanged.

## Acceptance + steps

- [x] Implicitly initialized nullable locals are accepted; late and unassigned final locals retain diagnostics.
- [x] Flutter State fields assigned unconditionally in initState are accepted for initialization and disposal; conditional, deferred and non-Flutter lookalikes retain diagnostics.
- [x] Registered cleanup callbacks are recognized; unregistered method tear-offs do not count as cleanup.
- [x] Extracted/composed Flex children are accepted while known incompatible render-object parents still report.
- [x] Synthetic positive and negative controls, strict analysis, integrated gates and real Flutter analyzer proof pass.

## Baseline + execution

Result: Passed
Evidence: Reuse exact current main 6f348b46 code/configuration/environment evidence: 1,813 tests, 71.09% line coverage, strict analysis and native Complete checks passed. PR #30, main Dart CI 35898748123, main Hard Eng 35898748042, publisher 35899318890 and native delivered check passed. Published 0.12.3 archive files match main; hosted callback regression passes.
Execution: Reproduce each boundary using synthetic fixtures, fix its existing owner, review the actual diff and run integrated checks before release.

## Risks + recovery

Do not infer safe initialization from a conditional or deferred assignment. Do not infer cleanup from a bare method tear-off. Unknown composed widget ancestry cannot establish an invalid parent, but explicit render-object violations must remain visible.

## ux_reference

N/A — analyzer diagnostics only; no product UI changes.

## Verification

Result: Passed
Evidence: Red/green regressions reproduce and repair each boundary. 110 focused tests including the real Flutter analyzer smoke passed; 31 initialization regressions passed after the receiver safeguard. Strict analysis reports no issues. Native Complete passed: 1,837 package tests, 71.35% line coverage, strict analysis, graph/complexity checks, dependency and security checks.
E2E: Passed — real Flutter analyzer confirms valid lifecycle, cleanup and widget composition examples while negative controls still report.
Delivery target: Merge
Delivery: Pending — required PR/main CI, automatic pub.dev publication and archive/consumer proof.
