# AST member and callback boundaries

Status: Complete

## Outcome + scope

Correct the Freezed private-constructor and build-mutation rules when valid object patterns or arrow callbacks are present. Keep diagnostics for implemented instance members and immediately executed mutations. Use actual Dart syntax instead of matching those constructs as text.

## Repository context

Owners: freezed_extended_source_rules.dart, dialog_source_rules.dart and their existing scanner regression suites. Text matching currently mistakes a factory's object pattern for an instance method and an arrow event callback for an immediate build call.

## Decisions + authorization

Blockers: None
Authority: Autonomous. The user approved repairing and releasing this lint package to unblock app upgrades. One builder; no delegation. Admin merge only after required CI passes; branch protections stay unchanged.

## Acceptance + steps

- [x] Factory-local object patterns and static methods do not require private Freezed constructors; custom instance implementations still do.
- [x] Arrow and block event callbacks may mutate state later; direct calls and immediately invoked functions still report.
- [x] Existing and synthetic negative-control regressions pass with strict analysis and integrated native checks.
- [x] Release notes describe only the reproduced corrections; published bytes and hosted behavior are verified during delivery.

## Baseline + execution

Result: Passed
Evidence: Reuse unchanged main 726ab71d code/configuration/environment evidence: all 1,804 tests, 71.08% coverage and the native Complete gate passed. PR #29, main Dart CI 35894616050, main Hard Eng 35894616027, publisher 35895116604 and the native delivered check passed. All 430 checked archive files match main.
Execution: One builder adds failing synthetic tests, repairs the two existing owners, reviews the actual diff and runs integrated checks.

## Risks + recovery

A broad callback exemption could conceal immediate execution. Include direct, nested and immediately invoked negative controls. Inspect only class-level implemented instance members for Freezed.

## ux_reference

N/A — analyzer behavior only; no visual product surface changes.

## Verification

Result: Passed
Evidence: Synthetic red tests reproduced factory/static member and callback-boundary failures, including an immediate call hidden after a callback on the same line. All 651 scanner tests pass; strict analysis has no issues. The real Flutter analyzer smoke passes and reports exactly the direct build mutation while accepting the arrow event callback. Actual diff reviewed: two existing rule owners, regression suites and release metadata only. Integrated Complete checks are required before shipping.
E2E: Passed — real Flutter analyzer accepts an arrow event callback and reports exactly the immediate mutating build call.
Delivery target: Merge
Delivery: Pending — required PR/main CI, automatic pub.dev publication and archive/consumer proof.
