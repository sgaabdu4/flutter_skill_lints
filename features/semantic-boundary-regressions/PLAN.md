# Semantic boundary regressions

Status: Complete

## Outcome + scope

Correct proven analyzer false positives without disabling rules, reducing severity, adding dependencies, or changing public APIs. Preserve unsafe recursion, held dependencies, arbitrary fallback values and raw navigation diagnostics.

## Repository context

Owners: the existing crash, notifier dependency, nullable fallback, router and storage-import rules and their regression suites. Current skill owners are `error-reporting.md`, `state-management/async-mutations.md`, `value-objects.md` and `architecture.md`.

## Decisions + authorization

Blockers: None. Guarded delivery remains pending below.
Handoff: Approval
Authority: The user authorized strict-profile adoption and correction of genuine producer defects. The coordinator approved the bounded repairs below and one corrective patch release. No profile suppressions or application-specific path exceptions.

## Acceptance + steps

- [x] Startup framework/dispatcher callbacks forwarding to the terminal Crash error method stay clean; send-failure recursion still reports.
- [x] A synchronous same-class helper containing only a resolved provider read can be called directly before suspension or after a mounted guard; held, nullable, asynchronous and mutable captures retain their existing checks.
- [x] Terminal local-only crash diagnostics do not require a remote provider; remote, arbitrary and recursive custom handlers still report.
- [x] Native numeric parsers, text editor setters and required wire fields in a data model's `fromEntity` factory accept nullable-string normalization; lookalike, domain, repository and unrelated factory cases still report.
- [x] Explicit `GoRouter.go(GoRouteData.location)` stays clean; raw strings and context-based direct navigation still report.
- [x] A resolved `dart:io` show-only import limited to HTTP constants and exception types stays clean; broad, hide, mixed and actual I/O imports still report.
- [x] Existing focused regressions, real analyzer safe/unsafe controls, strict analysis and every native gate owner pass for the final implementation.

## Baseline + execution

Result: Passed
Evidence: The starting behavior was faulty: published 0.13.0 reported recursion in nonrecursive startup callbacks and rejected synchronous provider helpers. Red regressions reproduced these findings against the original implementation at `cb1c9a5`. The repair retains the unsafe controls and uses the existing rule/test owners. Required comment preflight findings were repaired separately without changing executable lines. The first full native run passed 2,698 tests and every owner except one router complexity finding; flattening that existing branch then passed all 24 router cases, strict affected analysis and the unfiltered native complexity scan.
Execution: The canonical clarification merged at `432694be` and shipped in Hard Eng `96d5f9cb`. Supported adoption installed that exact release in commit `622b32d`. Registry API confirmed 0.13.0 is current and 0.13.1 is unpublished; the existing main workflow owns tagging and trusted publication.

## Risks + recovery

Only the bounded resolved APIs and owners qualify. Do not turn unrelated callbacks, cached dependencies, arbitrary helpers, domain sentinels or raw routes into safe cases. Preserve the original failing controls and revert a correction that weakens them.

## ux_reference

N/A — analyzer diagnostics have no visual interface.

## Verification

Result: Passed
Evidence: The 103-test combined regression run and 21 later crash/storage controls passed, including explicit post-await, throw/rethrow and same-line fallback negatives. Independent review cleared all bounded corrections. Full native coverage passed 2,698 tests with 79.46% line coverage; branch coverage was 67.38% informational, and the existing opt-in analyzer-server smoke awaits its required hosted job. Locking, formatting, whole-root strict analysis, security, vulnerability, performance, secret and workflow owners passed. After the one control-flow repair, all 24 router controls, strict affected analysis and the same unfiltered Dart Decimate 0.0.54 scan passed with zero findings. No rule severity, profile or threshold was reduced.
E2E: Passed — eight real installed-SDK import cases: allowed constants/exceptions, prefixed imports, and rejected broad/hide/File/Directory/Process/HttpClient imports. The matcher resolves actual `dart:io` exports, including HTTP types declared in private SDK libraries.
Delivery target: Merge
Delivery: Pending — normal committed-snapshot pre-push, all seven required exact-head hosted checks, guarded merge, merged-main verification and trusted patch publication.
