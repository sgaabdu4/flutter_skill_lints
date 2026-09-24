# Resolved API boundaries

Status: Complete

## Outcome + scope

Repair reproduced diagnostic mistakes in issues #35–43, #45–53, and #55–57 using resolved API and semantic boundaries. Retain genuine problem diagnostics and release the corrected package. Public fixtures use synthetic examples only. Issues #44 and #54 are intentional-policy proposals and are excluded.

## Repository context

Owners: existing test naming rule, Riverpod source rules, value object source rules, architecture source rules, runtime bug source rules and corresponding tests. Reuse the existing analyzer smoke and package release workflow. No new dependencies or rule suppressions.

## Decisions + authorization

Blockers: None
Authority: Autonomous. The user requested multi-agent refactoring, tool defect reports, and repair/release of the lint prerequisite. A GPT-6 Sol builder repairs rules, a separate auditor reproduces reports, and the parent reviews and ships. Existing approval allows admin merge after required CI passes; repository protections remain intact.

## Acceptance + steps

- [x] #35: Resolved test APIs enforce test naming; unrelated RegExpMatch.group and local methods do not.
- [x] #36: Whole consumed provider collections and values stay allowed; unnecessary broad-state watches and identity selectors still report where projection is required.
- [x] #37: Proven synchronous copyWith updates and local validation stay allowed; asynchronous work and void forwarding to expensive work still report.
- [x] #38: Parameterless union variants stay allowed; primitive domain factories still report.
- [x] #39: Awaited startup wrappers initialize crash reporting before runApp; missing or late initialization still reports.
- [x] #40: Imported domain interfaces satisfy the architecture contract; unrelated classes and missing contracts still report.
- [x] #41: Resolved test helpers containing assertions satisfy test assertion requirements; helpers without assertions still report.
- [x] #42: Required value-object ArgumentError.value validation guards stay allowed; arbitrary throws still report.
- [x] #43: One null assertion produces the stronger diagnostic once; unsafe null assertions remain errors.
- [x] #45: Constructor-injected, nonnullable notifier dependencies need no lazy initialization guard; genuinely uninitialized dependencies still report, including in test sources.
- [x] #46: Integration-test-only projects need no unused Driver entrypoint; projects using Driver or runtime override wiring still require the documented device entrypoint.
- [x] #47: The documented Crash facade in crash_service.dart satisfies filename policy; unrelated mismatched declarations still report.
- [x] #48: Conditional-expression question marks do not make Map type tests nullable; genuinely nullable collection declarations still report.
- [x] #49: A nullable callback accepting a nonnullable collection remains allowed; an actually nullable collection parameter still reports.
- [x] #50: Riverpod AsyncValue.when remains allowed; legacy Freezed union matching still reports.
- [x] #51: Singleton classes with instance state or methods remain classes; purely static namespaces still report.
- [x] #52: One-off callback prose remains allowed; repeated protocol keys and actual identifier boundaries still report.
- [x] #53: Generated Freezed copyWith operations remain allowed after destructuring; repeated data-property reads still report.
- [x] #55: A resolved cardinality assertion proves a following collection access safe; missing or invalidated proofs still report.
- [x] #56: Awaited UI confirmation is distinct from an awaited notifier result; actual notifier-result coupling still reports.
- [x] #57: Debug-call masking scans the original text without repeated suffix copies and preserves nested calls, following code, and diagnostic offsets within the unchanged performance budget.
- [x] Independent diff review, focused regression tests, full native gates and real Flutter/Riverpod analyzer smoke pass without weakened checks.

## Baseline + execution

Result: Passed
Evidence: An isolated worktree at b788bce (published implementation plus required Hard Eng update) ran `python3 .hooks/hard-eng.py check --plan-stage Draft`. All gates except the full test suite passed. Its scanner benchmark took 2,386,151 microseconds against a 2,000,000 budget during concurrent work; 1,867 tests passed and one skipped. The unchanged benchmark passed alone. A full native rerun then passed all gates with 1,868 tests, one skip and 72.09% line coverage at the original performance budget. Preserve the original failure and budget. This is the unchanged starting implementation, separate from repair edits.
Execution: Reproduce each reported failure with a clean control, repair its existing owner, review the integrated diff, then verify and release. The baseline is verified on the starting implementation; the separately authorized repair edits remain subject to integrated checks.

## Risks + recovery

Overbroad exemptions can introduce false negatives. Preserve positive controls next to each accepted case and verify real framework APIs. API identity, imported declarations, asynchronous forwarding and local side effects need semantic evidence; method names or return type alone are insufficient. Do not suppress consumer warnings to obtain a clean report.

## ux_reference

N/A — analyzer diagnostics only; no product interface changes.

## Verification

Result: Passed
Evidence: Focused red/green regressions, real Flutter/Riverpod controls, default/opt-in plugin smoke, analysis and formatting pass. The first integrated native run passed all correctness tests but its unchanged scanner benchmark took 2,671,162 microseconds against the 2,000,000 budget; the dedicated performance gate passed. Decimate reported seven newly complex helpers and a duplicated annotation check. Those were refactored at their owners; the full strict Decimate check and analysis now pass. A retry was deliberately stopped when investigation found quadratic suffix copying in debug-call masking. A single-pass match iterator preserves offsets and nested-call behavior; the existing benchmark and added semantic regression pass unchanged. A synthetic 10,000-debug-call comparison improved from 2,047,929 to 94,221 microseconds on this machine. The fresh native Ready run passes all gates: 1,923 tests, one expected opt-in skip, 73.10% line coverage, zero Decimate findings, analysis/security/workflow checks, and the unchanged performance budget. The separate real Flutter plugin smoke passes after the final refactor. Publication dry-run reports only the expected dirty-checkout warning, to be rechecked on the clean committed source. Native Complete and remote delivery checks remain required before shipment.
E2E: Passed — the real Flutter/Riverpod fixture confirms accepted examples stay clean and genuine misuse controls retain diagnostics. The separate final Flutter plugin smoke passes for default registration and explicit opt-in rules after the final source refactor.
Delivery target: Merge
Delivery: Pending — pull request checks, merge, main CI, publisher success, published archive comparison and hosted-package regression proof.
