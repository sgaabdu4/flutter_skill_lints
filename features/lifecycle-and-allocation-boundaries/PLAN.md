# Lifecycle and allocation boundaries

Status: Complete

## Outcome + scope

Repair three reproduced analyzer false positives: deferred reads are not immediate initState work, unrelated required parameters do not make a provider a family, and separate non-constant constructor calls are not reusable values. Also correct two regressions found by comparing published releases: void notifier methods can launch expensive work, and Container properties can introduce a render-object parent for Expanded.

## Repository context

Use the existing Riverpod scanner and use_existing_variable rule. Extend their synthetic tests and the real Flutter analyzer smoke. Split the existing duplicate-expression test class into a part because its current file is at the handwritten size limit. No new dependencies.

## Decisions + authorization

Blockers: None
Authority: Autonomous. User approved repair and release of lint defects blocking consumer upgrades. Preserve protections; approved admin merge only after required CI passes. One builder, no delegation.

## Acceptance + steps

- [x] Direct and immediately invoked initState reads and synchronous callbacks report; proven deferred SDK callbacks and adjacent methods do not.
- [x] Actual family parameters report; unrelated fields and method parameters do not.
- [x] Non-constant constructor calls remain distinct; genuine repeated reads and constant expressions still report.
- [x] Direct state assignments remain allowed; synchronous methods forwarding asynchronous work still warn, including imported notifier declarations.
- [x] Padded and constrained Containers around Expanded report; transparent Containers and extracted widgets remain allowed.
- [x] Synthetic regression tests, real Flutter analysis and native gates pass.

## Baseline + execution

Result: Passed
Evidence: Main 7155bde passed native Complete and delivered gates, 1,851 tests and 71.93% coverage. PR #32 and main CI 35907903419/35907903346 passed. Publisher 35908429321 succeeded; 553 published archive files match main and hosted 0.12.5 negative controls pass. Reuse this exact baseline.
Execution: Prove failures, repair the owning rules, review the public payload, then verify and release.

## Risks + recovery

Distinguish inline immediate invocation from a deferred callback. Keep family signatures and constant-expression duplicate diagnostics intact. Constructor recognition does not imply transitive purity analysis of arbitrary methods. The debounce exemption is deliberately limited to proven trivial assignments; complex synchronous methods remain conservative warnings. Nullable Container properties do not establish an incompatible parent. Published-version comparisons exposed two false negatives despite passing release gates; passing historical checks are not evidence of regression-free behavior.

## ux_reference

N/A — analyzer diagnostics only.

## Verification

Result: Passed
Evidence: Focused scanner, allocation and layout suites pass (701 tests before the added shorthand allocation case); the strengthened real Flutter plugin smoke passes, and strict analysis reports no issues. Two published regressions reproduced on hosted 0.12.5 with 0.12.0 comparison controls. The original three defects failed their focused red tests before repair. Reviewed all library changes since 0.12.0 plus this candidate; no rule disabling or weaker configuration. Native Complete passed all checks: 1,866 tests, 72.09% line coverage, strict analysis, duplication and import checks, security, vulnerability and secret scans. A separate real Flutter widget run confirmed padded/width Containers cause the expected parent-data error and a transparent Container works (three passing cases).
E2E: Passed — real Flutter/Riverpod analyzer verifies imported notifier bodies, request forwarding, direct and deferred lifecycle reads, Container layout, distinct allocations, and actual family signatures.
Delivery target: Merge
Delivery: Pending — PR/main CI, automatic pub.dev publication, archive comparison and hosted consumer proof.
