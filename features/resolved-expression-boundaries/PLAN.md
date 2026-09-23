# Resolved expression boundaries

Status: Complete

## Outcome + scope

Correct three analyzer false positives: assignments are not replaceable reads, member comparisons need matching receivers, and a resolved synchronous notifier form update does not imply an asynchronous request requiring debounce. Keep actual duplicate reads, contradictory same-receiver comparisons and async request diagnostics.

## Repository context

Reuse use_existing_variable.dart, avoid_contradictory_expressions.dart and runtime_bug_source_rules.dart with its existing part. Extend the existing expression, boolean and source-scanner regression suites, plus the real Flutter analyzer smoke. No new dependency or product files.

## Decisions + authorization

Blockers: None
Authority: Autonomous. The user authorized fixing and releasing lint-package defects blocking consumer upgrades. One builder, no delegation. Admin merge only after all required checks pass; retain branch protections.

## Acceptance + steps

- [x] Assignment/update targets never suggest replacement with a previously read value; repeated reads still report.
- [x] Comparisons on distinct receivers are not called contradictory; contradictory same-receiver comparisons still report.
- [x] Resolved synchronous notifier updates are accepted; async requests still require debounce.
- [x] Synthetic regression tests, real Flutter analyzer proof and integrated checks pass.

## Baseline + execution

Result: Passed
Evidence: Exact main 8b943b0 passed native Complete and delivery checks, 1,837 tests, 71.36% line coverage, PR #31, main Dart CI 35903031273, main Hard Eng 35903031285 and publisher 35903542406. Published 0.12.4 archive matches 553 tracked source files; hosted analyzer positive/negative controls pass. Reuse this matching baseline.
Execution: Reproduce each defect, repair the existing semantic owner, review the complete public payload and verify before shipping.

## Risks + recovery

Do not confuse matching member declarations with matching runtime receivers. Skip a write target without skipping legitimate reads inside its index or right-hand side. Preserve conservative warnings for unresolved and asynchronous callback work.

## ux_reference

N/A — analyzer diagnostics only; no product UI changes.

## Verification

Result: Passed
Evidence: Synthetic red/green regressions cover read/write targets, distinct and same receivers, synchronous/async/async-void methods and callback isolation. 676 focused tests passed; the added null-asserted-read regression passes with the write-target suite. A real Flutter analyzer smoke retains exactly one negative control for each corrected rule. Strict analysis passes. Native Complete passed: 1,851 tests, 71.93% line coverage, strict analysis, performance, graph/complexity, dependency and security checks.
E2E: Passed — real Flutter analysis verifies positive and negative controls.
Delivery target: Merge
Delivery: Pending — PR/main CI, automatic pub.dev publication, archive comparison and hosted consumer proof.
