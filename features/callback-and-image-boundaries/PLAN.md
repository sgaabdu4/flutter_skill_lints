# Resolved analyzer diagnostic boundaries

Status: Complete

## Outcome + scope

Fix the reproduced diagnostics in #58, #61, #62, #63, #64 and #65, including the 0.12.8 startup regression. A named local callback needed for identity-guarded cleanup must work with Dart's preferred declaration syntax. Reading an existing Image must not be treated as constructing an unlabeled Image. Retain actual local-helper and inaccessible-image diagnostics. Public fixtures are synthetic.

## Repository context

Modify the existing callback, image accessibility, startup initialization, filename, and primitive-factory rule owners and their existing regression files. Reuse native gates, real Flutter analyzer fixtures and release workflows. No dependencies, suppressions or rule configuration changes.

## Decisions + authorization

Blockers: None
Release boundary: The one-shot persistence proposal (#66) was rejected as too broad and remains outside this release.
Handoff: Approval
Authority: Autonomous. The user authorized repairing and releasing reproduced lint defects with independent review and genuine-violation controls. Existing authorization permits admin merge only after current-head checks pass; branch protections remain unchanged.

## Acceptance + steps

- [x] #58: A resolved callback assigned to a slot and compared during guarded cleanup of that same slot is accepted; ordinary helpers, shadowed callbacks, different slots/receivers and comparisons without cleanup still report.
- [x] #61: Image lookup/getter calls stay clear; unlabeled Flutter Image constructors still report. Explicit labels and decorative-image opt-out remain valid, including supported constructor syntax.
- [x] #62: Awaited reachable top-level startup helpers with imported Crash appRunner initialization are accepted regardless of declaration order; unawaited, conditional, unreachable, cyclic and late initialization remain errors.
- [x] #63: The canonical DateTimeX helper path satisfies both current-date and filename rules; unrelated types and other mismatched paths still report.
- [x] #64: Only resolved core Exception/Error sealed Freezed union redirects with optional nullable diagnostic payloads are accepted; identity primitives, required/positional arguments, body conversions and shadowed error types still report.
- [x] #65: A provider result bound through conditional value branches and consumed whole is accepted; partial state reads still report.
- [x] Independent source review, paired regressions, native checks and real Flutter analyzer controls pass without weakening diagnostics or budgets.

## Baseline + execution

Result: Passed
Evidence: Merged source 57d76344a1d3fa1e850f53715611e489155be6f7 passed the main Dart CI and Hard Eng workflows. Its package implementation passed native Complete with 1,923 tests, 73.10% line coverage and zero Decimate findings; the later supported scaffold update passed its native pre-push verification. The callback regression was reproduced red on that starting implementation before its owner fix. The Image lookup defect was reproduced against the same implementation with real Flutter types.
Execution: Repair the existing owners, retain resolved positive and negative controls, review the combined diff, then run local and remote release checks.

## Risks + recovery

Overbroad callback exemptions could hide genuine helpers; compare resolved callback and storage identities and require guarded cleanup. Image return types alone cannot establish construction; inspect the actual constructor boundary. Preserve genuine violations next to accepted examples. Revert an incorrect repair at its owner instead of disabling a rule.

## ux_reference

N/A — analyzer diagnostics only; no product interface changes.

## Verification

Result: Passed
Evidence: Callback, Image, crash and filename focused suites passed 113 tests; the source-scanner suite passed 668 tests. Real plugin controls accept valid crash startup and exception diagnostics while retaining unsafe startup and primitive-identity findings. Independent actual-diff review passed. The explicit hosted 0.12.8 and local-patch analyzer matrix retains the prior genuine violations; the original 28-control fixture changes only the intended callback diagnostic (183 to 182 findings). Expanded controls change only the intended boundary findings (244 to 236) and verify the startup regression against the published version. The native Draft gate passed 1,963 tests and 73.43% line coverage with zero code-health findings. A subsequent independent adversarial review found an inverted equality cleanup exemption; a red regression reproduced it, the rule now requires positive equality, and all 27 callback tests pass including parenthesized/conjunctive safe guards and disjunctive/inverted unsafe controls. The final native Complete gate passed 1,966 tests (one opt-in smoke skipped), 73.44% line coverage, strict analysis, formatting, boundaries, performance, security/dependency checks and zero code-health findings. Remote publication checks remain required.
E2E: Passed — isolated real Flutter analyzer fixtures compare hosted 0.12.8 with the repaired plugin for callbacks, Image construction/lookup, imported startup chains, canonical filename paths and exception payloads. Unsafe near misses retain diagnostics; fixture configuration and published package provenance were verified.
Delivery target: Merge
Delivery: Pending — current-head PR checks, merge, main CI, publisher success, published archive comparison and hosted-package control verification.
