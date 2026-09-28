# Published analyzer regression boundaries

Status: Complete

## Outcome + scope

Repair demonstrated published 0.13.1 misclassification of inline callback captures across awaited operations while retaining genuine dead-write and shadowing diagnostics. Restore strict direct-router and null-fallback enforcement, and detect remote SDK integration outside the Crash class before allowing local global handlers. Preserve strict async/await and duplicate-assertion rules. Adopt the verified Hard Eng release through its supported installer and publish one corrective patch only after semantic review and native proof.

## Repository context

Owners: `avoid_unused_assignment`, the existing router/services/Crash source rules and their existing suites. All regression fixtures are synthetic; no consumer data or paths are published.

## Decisions + authorization

Blockers: None
Handoff: Clarification
Authority: The user requires enforcement of documented best practices; runtime-valid code alone does not justify a lint allowance. On 2026-09-29 the coordinator authorized withdrawing the unpublished async exception and broad assertion reset, restoring the entire pre-0.13.1 direct-router and null-fallback policy, and preparing inline-capture and unit-scoped SDK detection repairs. Local closure identity tracking and synchronous execution guesses were removed as unnecessary for the actual awaited-callback requirement. The canonical no-provider Crash applicability remains supported. Integrated delivery is authorized after final independent review and passing native proof.

## Acceptance + steps

- [x] Preserve `prefer_async_await`: the unpublished terminal `catchError` exception and its added tests are removed; canonical fire-and-forget guidance requires internal catching at the application owner.
- [x] Restore `avoid_duplicate_test_assertions` and its test file to the published baseline; no unrelated-call or blanket-await exemption remains.
- [x] Inline callback arguments and nonlocal storage record exact captured-variable reads across awaited operations; unread overwrites and shadowed callback variables still report.
- [x] Unescaped declarations and unrelated calls/awaits cannot consume their captures; adjacent assignments and assignments separated by const construction or `identical` retain their diagnostics.
- [x] Remove unpublished local closure/alias maps and synchronous execution guesses; preserve prior local-closure, nested-closure and synchronous-callback limitations without an effect engine.
- [x] Direct `GoRouter.go(typedRoute.location)` reports again; generated typed route helpers remain accepted and same-line coordinator controls retain their diagnostics.
- [x] Parser, editor and required wire-field sentinel fallbacks report again; the existing correction continues to require an explicit nullable branch, pattern or typed value.
- [x] SDK initialization in a helper outside Crash in the same resolved unit prevents a local-handler exemption; resolved local lookalikes and no-provider terminal diagnostics remain allowed, while recursion and unsafe continuations retain their existing diagnostics.
- [x] Reproduce the assignment and policy failures against 0.13.1, retain unsafe controls, and pass focused native rule suites plus strict affected analysis.
- [x] Independent review confirms the final diagnostic behavior follows the existing policy and does not replace meaningful strict checks with runtime-valid allowances.
- [x] Supported adoption installs the verified scaffold revision; all integrated native gates and existing coverage and performance requirements pass before delivery.

## Baseline + execution

Result: Passed
Evidence: The original failed baseline was a consumer candidate resolving published 0.13.1 and reporting assignments whose values a registered callback actually reads during awaited recovery phases; its other eleven gate owners passed. The producer started at clean main `a5c37f1`, and registry metadata confirmed 0.13.1. The final focused suite reproduced eight failures with the exact published rule bytes; edited bytes were restored in `finally` before the green run. After the repairs and supported scaffold update, all integrated gates passed. Earlier mounted-guard, expression and SDK-mock corrections remain unchanged.
Execution: One builder owns the existing rule and test files. Independent review of the final diff found no remaining semantic defect. The coordinator granted integrated verification and delivery through the existing native owners.

## Risks + recovery

Record exact reads only for inline callbacks passed or stored outside the analyzed block. An await can allow those registered callbacks to run; calls, constructors and local closure declarations do not consume captures. Prior local-closure, nested-closure and synchronous-callback limitations remain; no identity maps, setter index, pure-call classifier or effect engine is added. The async proposal was withdrawn because the existing canonical [fire-and-forget policy](../../.agents/skills/building-flutter-apps/references/services-and-singletons.md#3-fire-and-forget) requires internal catching. The assertion proposal was withdrawn instead of adding a general effect engine. Router and nullable-boundary allowances are removed because runtime equivalence is not policy compliance. Crash detection stays within the resolved unit; no project scanner or telemetry requirement is added. A passing fixture cannot authorize relaxing policy.

## ux_reference

N/A — analyzer diagnostics have no visual interface.

## Verification

Result: Passed
Evidence: Final focused native run passed 62 cases in 3.35 seconds: `AvoidUnusedAssignmentTest`, `ImplicitNullFallbackTest`, `RouterDirectRouteCallTest`, `CrashCustomGlobalErrorHandlerTest` and `CrashErrorRecursionTest`. The same suites against exact published rule bytes failed eight cases in 3.20 seconds. `dart analyze --fatal-infos` passed all nine changed Dart files; the final narrowed assignment owner and suite were checked again. Formatting and diff-whitespace checks passed. Both withdrawn async/duplicate rule-test pairs match the published baseline. Independent review of the final diff found no remaining semantic defect. Supported installation of Hard Eng `97cc783afd75c81b08a28f0ce392414aa50cef7e` passed its scaffold checks in 37.17 seconds. The subsequent complete native gate passed in 88.79 seconds with 2,704 tests, 79.43% line coverage against the retained 70% minimum, and all strict analysis, security, duplicate-code and performance checks. Earlier receipts for removed proposals do not certify this final scope.
E2E: Passed — the native analyzer harness proved inline captures across awaits, retained declaration/unrelated-call/overwrite/shadowing controls, restored policy diagnostics and the SDK-helper/local-only Crash boundary. The existing opt-in `RUN_FLUTTER_PLUGIN_SMOKE=1 dart test test/integration_plugin_smoke_test.dart --reporter expanded` also passed in 101.85 seconds, loading the canonical configuration alongside `riverpod_lint` in a real Flutter analysis-server run.
Delivery target: Merge
Delivery: Pending — coordinated review, exact-head CI, merged-main verification, trusted 0.13.2 publication and archive verification remain required. Consumer adoption and its full strict-profile verification follow publication in that consumer's own effort.
