# Lifecycle and allocation boundaries

Status: Complete

## Outcome + scope

Follow-up: publication of 0.12.6 was cancelled before upload after detecting that a nullability suffix is not proof of a non-null type. Use the analyzer type system for Container properties and preserve the cancelled tag; publish the correction as 0.12.7.

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
- [x] Literal null, dynamic and nullable generic Container properties remain unknown/transparent; non-null generic properties still establish an invalid parent.
- [x] Synthetic regression tests, real Flutter analysis and native gates pass.

## Baseline + execution

Result: Passed
Evidence: Main 7155bde passed native Complete and delivered gates, 1,851 tests and 71.93% coverage. PR #32 and main CI 35907903419/35907903346 passed. Publisher 35908429321 succeeded; 553 published archive files match main and hosted 0.12.5 negative controls pass. Original baseline retained. Follow-up baseline 1695f85 passed main CI 35913463411 and 35913463528 and native delivered verification; the new nullability regression test reproduces the defect before its correction.
Execution: Prove failures, repair the owning rules, review the public payload, then verify and release.

## Risks + recovery

Distinguish inline immediate invocation from a deferred callback. Keep family signatures and constant-expression duplicate diagnostics intact. Constructor recognition does not imply transitive purity analysis of arbitrary methods. The debounce exemption is deliberately limited to proven trivial assignments; complex synchronous methods remain conservative warnings. Nullable Container properties do not establish an incompatible parent. Published-version comparisons exposed two false negatives despite passing release gates; passing historical checks are not evidence of regression-free behavior.

## ux_reference

N/A — analyzer diagnostics only.

## Verification

Result: Passed
Evidence: Nullability follow-up: the new literal-null test fails against 1695f85 for the expected diagnostic; all 36 Flutter safety tests pass with the type-system correction, including dynamic and generic bounds. Strict analysis and the strengthened real Flutter/Riverpod smoke pass. Four actual Flutter widget cases independently confirm both invalid parents fail and null/transparent Containers work. Prior integrated proof: 1,866 tests, 72.09% coverage and native Complete/pre-push checks passed; Final 0.12.7 native Complete passed with 1,868 tests and 72.09% line coverage; all other required checks passed.
E2E: Passed — real Flutter analyzer distinguishes literal null, dynamic, nullable generic and non-null generic Container properties, while retaining all previous audit controls. Four Flutter runtime layout cases pass.
Delivery target: Merge
Delivery: Pending — 0.12.6 publisher 35913972222 was cancelled and upload skipped. PR 33 merged at 1695f85 with both main CI runs passed. The 0.12.7 follow-up requires PR/main CI, automatic publication, archive comparison and hosted proof.
