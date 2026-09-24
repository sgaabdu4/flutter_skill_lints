# Published analyzer regression boundaries

Status: Complete

## Outcome + scope

Repair four reproduced regressions in callback cleanup, mounted guards, repeated expressions, and SDK mock declarations. Preserve genuine diagnostics and the safe behavior added in recent releases. No policy changes to unrelated rules.

## Repository context

Owners: `avoid_local_functions`, `use_ref_mounted_after_await` and its guard utility, `use_existing_variable`, and the test mock scanner. Existing focused suites cover each owner. All examples are synthetic.

## Decisions + authorization

Blockers: None
Authority: Autonomous corrective repair requested by the user. One source owner per rule; the SDK mock boundary has a separate source owner. The user authorized a corrective patch release after review, CI and publication verification.

## Acceptance + steps

- [x] An identity cleanup comparison followed by an effectful condition warns; a side-effect-free guarded cleanup clears, while ordinary local functions still warn.
- [x] A real Riverpod mounted/revision guard clears; a shadowed `ref` and an absent guard warn, including direct and private-helper forms.
- [x] Repeated pure work evaluated before an effect reports even when a later expression calls a function. Repeated work evaluated after a state-changing call does not suggest stale reuse; plain duplicates report and repeated effectful work stays clear.
- [x] Actual allowed SDK mock declarations resolve by declaration source, including a `part of` service. Local lookalikes and concrete app contracts still report; abstract contracts clear.
- [x] Focused tests, real analyzer fixtures, strict analysis, and native checks pass on the integrated release diff.

## Baseline + execution

Result: Passed
Evidence: Published-version synthetic analyzer comparisons reproduced each reported regression. `python3 .hooks/hard-eng.py check --plan-stage Draft` passed the starting implementation: 1,995 tests (one opt-in skip), 73.73% line coverage, strict analysis, and zero Decimate findings.
Execution: Correct existing owners and focused tests; review the integrated SDK mock change; run package gates after source stabilization.

## Risks + recovery

Effect and evaluation order matter: a call after a duplicate differs from a call before it. Guards must prove the actual Riverpod reference and cannot trust arbitrary getters or operators. Retain each published release's genuine fixes and revert only an incorrect owner change if a control fails.

## ux_reference

N/A — analyzer diagnostics have no visual interface.

## Verification

Result: Passed
Evidence: Focused regression tests were red before correction and green after. The outgoing 0.12.11 local-plugin analyzer matched all 13 safe/unsafe callback, mounted-guard, and expression-order assertions with no non-configuration analyzer errors. The integrated native Complete gate passed 2,002 tests (one opt-in skip), 73.79% line coverage, strict analysis, security checks, and zero Decimate findings. Unchanged-source consumer diagnostic comparisons found only the intended SDK mock corrections.
E2E: Passed — the actual analyzer replayed safe and unsafe callback cleanup, mounted guards, and expression evaluation-order controls on a synthetic Flutter/Riverpod package.
Delivery target: Merge
Delivery: Pending — coordinated review, exact-head CI, merged-main verification, trusted package publication and archive verification remain required.
