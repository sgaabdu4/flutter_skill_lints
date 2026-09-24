# Resolved lint classification

Status: Complete

## Outcome + scope

Fix reported analyzer defects #79–81: geometric `dart:ui Path.close()` is not disposal, an indexed Map field named `values` is not `Enum.values`, and a private named constructor is not a discarded variable read. Keep actual disposal, enum-index and discarded-variable diagnostics; leave factory-body and reactive-provider rules unchanged.

## Repository context

Owners: Existing disposal utility and three rules in `lib/src/additional_lints/`, with their focused rule test suites. Published 0.12.11 analyzer reproductions include true-positive controls. No package dependencies or configuration changes are needed.

## Decisions + authorization

Blockers: None
Authority: Corrective fixes for #79–81 are authorized. Versioning and publication follow separate delivery review.

## Acceptance + steps

- [x] `dart:ui Path` creation and drawing do not report disposal, while a genuine closeable or cancellable resource left open still reports and explicit cleanup clears.
- [x] Resolved enum `values[index]` reports; a Map field or other non-enum `values[index]` does not.
- [x] Contextual and explicit private named constructor references clear; a genuine read of an underscore-only variable still reports.
- [x] Focused red/green rule tests, real Flutter analyzer replay, strict analysis, full suite and native Complete pass on the final diff.

## Baseline + execution

Result: Passed
Evidence: Published 0.12.11 analyzer reported seven exact targeted diagnostics: four false-positive locations and three true controls, with no Dart compile-time errors. Native Draft baseline passed on published-source HEAD: 2,002 tests (one opt-in skip), 73.79% line coverage, strict analysis, zero Decimate findings and the other required checks.
Execution: Add focused failing controls at existing suites, repair the resolved semantic owners, then run integrated gates and review the final diff.

## Risks + recovery

`close` names alone do not prove cleanup semantics. Preserve real close/cancel disposal contracts and report on the same tokens as the published rules. Do not broaden exemptions to all path-like classes, all `.values`, or all underscore identifiers.

## ux_reference

N/A — analyzer diagnostics have no visual interface.

## Verification

Result: Passed
Evidence: New rule controls failed against the published behavior and pass after correction, including a resolved mock `dart:ui Path` case red on the old logic and green after the fix. All 73 focused tests and strict `dart analyze lib test` pass. Actual local-path Flutter analyzer replay removes exactly four false-positive locations and retains exactly three true-positive controls, with no compile-time errors. Native Complete passed on the final source: 2,013 tests, one opt-in skip, 73.82% line coverage, strict analysis, zero Decimate findings and all other required checks.
E2E: Passed — actual Flutter analyzer plugin replay on synthetic code distinguishes geometric `dart:ui Path.close`, Map `.values`, private named constructors, and their genuine violation controls.
Delivery target: Merge
Delivery: Pending — review, CI, publication and hosted verification.
