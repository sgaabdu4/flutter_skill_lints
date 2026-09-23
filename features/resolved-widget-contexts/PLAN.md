# Resolved literal and widget contexts

Status: Complete

## Outcome + scope

Correct false positives for cleanup-only try/finally, structural string keys, core error parameter names, inherited stateful lifecycle/state and Riverpod Consumer builder subscriptions. Release a patch without weakening diagnostics for genuinely suspicious text, stateless widgets or event callbacks.

## Repository context

Owners: the existing avoid_missing_interpolation, avoid_unnecessary_stateful_widgets and avoid_ref_watch_outside_build rules, the widget_try_catch_boundary scanner, existing analyzer regression suites, and the real Flutter integration smoke fixture. Stateful inheritance regressions reuse the existing Flutter safety suite.

## Decisions + authorization

Blockers: None
Authority: Autonomous. User approved fixing and releasing this lint package to unblock consumer upgrades. One builder; no delegation. Admin merge only after required checks pass; branch protections remain unchanged.

## Acceptance + steps

- [x] Cleanup-only try/finally is accepted; actual catch clauses remain errors, including nested handlers.

- [x] Map/index keys and core error parameter-name arguments are accepted; ordinary text and map values still warn.
- [x] Inherited mutable fields and implemented lifecycle methods preserve StatefulWidget; empty mixins still warn.
- [x] Resolved Consumer builder subscriptions are accepted; nested callbacks and unrelated builder APIs still warn.
- [x] Synthetic regression tests reproduce failures before fixes and pass afterward; real Flutter analyzer proof passes.
- [x] Patch version and changelog accurately describe the corrections.

## Baseline + execution

Result: Passed
Evidence: Reuse the unchanged main 3f18fdb production/configuration/environment proof from the preceding release: native Complete check passed all 1,784 tests with 70.68% coverage, main Dart CI 35888511447 and Hard Eng CI 35888511462 succeeded, and native delivered passed. Only this plan changes before the Ready check.
Execution: One builder adds synthetic regressions, repairs each existing owner, reviews the diff and verifies the integrated package.

## Risks + recovery

Overbroad exclusions could hide useful diagnostics. Match resolved API identities and inherited concrete members; retain negative controls for similarly named unrelated APIs and nested callbacks. Keep consumer data keys and lifecycle behavior unchanged.

## ux_reference

N/A — analyzer diagnostics only; no visual product changes.

## Verification

Result: Passed
Evidence: The first integrated native Complete check passed all 1,802 tests with 71.00% coverage before the additional cleanup-only regression. Six initial regression failures reproduced the false positives. All 55 focused tests now pass, including unrelated API, empty mixin, interface-only, outer-ref and nested-callback negative controls. Strict analysis reports no issues. Actual diff reviewed; changes stay at the four rule owners and existing test suites. The 615 scanner tests also pass, including the new cleanup-only and nested-catch regressions. Strict analysis is clean. The final native Complete check runs on this integrated tree.
E2E: Passed — the real Flutter analyzer accepts map keys, six core error constructor/helper uses, inherited lifecycle and Consumer build subscriptions; it reports exactly the nested event subscription. The existing scalar/broad/identity regression still passes. A real Flutter widget fixture accepts cleanup-only finally and reports exactly the actual catch handler.
Delivery target: Merge
Delivery: Pending — PR/main CI, automatic release and pub.dev archive verification.
