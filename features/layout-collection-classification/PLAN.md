# Layout and collection classification

Status: Complete

## Outcome + scope

Repair reported false positives #82 and #84 in the existing spacing and widget collection rules. Keep equivalent uniform layout suggestions and genuine Flutter widget-list builder diagnostics. No rule configuration, dependency or broad policy changes.

## Repository context

Owners: `prefer_spacing.dart`, `prefer_for_loop_in_children.dart` and focused synthetic rule tests. Version and changelog follow the repository's existing main-branch publication workflow.

## Decisions + authorization

Blockers: None
Authority: Genuine reproduced lint repairs, version publication and consumer updates are authorized.

## Acceptance + steps

- [x] Direct spacing recommendations preserve child positions, uniform gap values, keys and the known axis.
- [x] Only resolved Flutter widget collections report functional-list builder findings; numeric transforms and custom lookalikes remain clear.
- [x] Fold suggestions preserve append-once semantics and reject accumulation-dependent or reordered folds.
- [x] Published-source failing controls and candidate passing controls distinguish the intended rule boundaries in unit tests and an actual Flutter analyzer replay.

## Baseline + execution

Result: Passed
Evidence: Published 0.12.12 source failed eight negative controls in the initial synthetic suite while retaining six positive cases. Final repair verification passes 21 focused tests, strict whole-package analysis and strict Dart Decimate with zero findings. The actual published analyzer replay reproduces 17 false-positive diagnostics and ten genuine controls on the same synthetic source.
Execution: Correct the existing semantic owners, verify positive and negative contracts, then review the final diff and run integrated gates.

## Risks + recovery

Identical expression spelling does not prove equal values or evaluation effects. Removing separator children can change alignment distribution. Narrow resolved-type checks must retain genuine Flutter widget builders and avoid changing arbitrary Dart collection policy.

## ux_reference

N/A — this package emits analyzer diagnostics; synthetic Flutter layout tests verify the effect of its spacing recommendation.

## Verification

Result: Passed
Evidence: All 21 focused regression tests pass, strict whole-package analysis is clean, and strict Dart Decimate reports zero findings. Independent review found a missed block-return cascade control and two overly complex rule functions; both were repaired and reverified. Final real Flutter plugin replay removes exactly 17 false-positive diagnostics and retains ten genuine controls with zero compiler errors. Final native Complete passed: 2,034 tests with one opt-in skip, 74.60% line coverage, strict whole-package analysis, strict Dart Decimate 0.0.47 with zero findings, formatting, security, dependency and workflow checks.
E2E: Passed — identical synthetic Flutter sources analyzed through the published and candidate plugins retain ten genuine diagnostics and remove the 17 reproduced false positives. Six real Flutter widget tests compare child positions across every MainAxisAlignment: start, end, center and spaceBetween remain equivalent; spaceAround and spaceEvenly change positions and are excluded from the suggestion.
Delivery target: Merge
Delivery: Pending — scoped PR, required CI, merge, published archive and hosted consumer verification.
