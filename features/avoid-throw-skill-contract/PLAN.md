# avoid_throw skill contract

Status: Complete

## Outcome + scope

Align `avoid_throw` with the building-flutter-apps skill for issues #42 and #95. The Value Object guard in `references/value-objects.md` (`final trimmed = input.trim(); if (trimmed.isEmpty) throw ArgumentError.value(input, ...)`) must not report. Resolved `dart:core` `Error.throwWithStackTrace` must follow the same typed-failure contract as direct throws ("Failures throw typed errors" in `references/networking.md`), while propagation of a caught error with its caught stack stays allowed. Per the coordinator, the scoped-provider stub in `references/riverpod-codegen.md` (`@Riverpod(dependencies: []) ... => throw UnimplementedError();`, which must be overridden) is allowed, and `avoid_throw` becomes error severity. No other rule changes.

## Repository context

Owner: `lib/src/additional_lints/rules/avoid_throw.dart`; tests in `test/additional_lints_dcm_worker_ap_try_throw_test.dart`; contract text in `doc/building-flutter-apps-lint-coverage.md`. The guard matched the parameter name against the condition's source text, so a final local lost the parameter's provenance. The rule only visited `ThrowExpression`, so `Error.throwWithStackTrace` was never checked.

## Decisions + authorization

Blockers: None
Authority: Autonomous package repair authorized by the user; confined to `avoid_throw`, its tests and its documented contract. No CHANGELOG or version change.

## Acceptance + steps

- [x] Guard conditions resolve identifiers: the `ArgumentError.value` parameter itself, or a `final` local whose initializer (transitively, same factory body) reads it. Source-text matching removed.
- [x] `var`, reassigned, and parameter-unrelated locals, plus unrelated throws in the factory, still report.
- [x] Resolved static `dart:core` `Error.throwWithStackTrace` applies the direct-throw contract to its error argument, including presentation contexts.
- [x] The caught error plus the stack trace of the same catch clause is allowed; a mismatched stack, a fresh `Error`, or an untyped value reports; a same-named non-core API is ignored.
- [x] The documented scoped-provider stub (resolved `riverpod_annotation` `@Riverpod` with `dependencies:`, top-level expression body `throw UnimplementedError()`) is allowed; `@riverpod`, block bodies, other thrown values, un-annotated functions and a same-named local annotation report.
- [x] `avoid_throw` reports at `DiagnosticSeverity.ERROR`, asserted by a test.
- [x] `_isValueObjectArgumentGuard` split into helpers to stay under the complexity gate.
- [x] Coverage doc updated for all behaviours and the severity.

## Baseline + execution

Result: Passed
Evidence: Red tests committed first; three failed (final-local guard reported, untyped and presentation `Error.throwWithStackTrace` not reported), then two more for the scoped stub and severity.
Current baseline: `dart analyze` clean; 2,153 tests pass (1 skipped).
Execution: One builder; red tests, #42 fix, #95 fix, scoped stub and severity, doc, probe, hard-eng.

## Risks + recovery

A saved error/stack pair passed through helper parameters is judged by the error's static type (an `Object` parameter reports), matching direct `throw error`; this limit is documented. Local provenance is bounded to `final` locals in the same factory body, so a looser alias cannot hide an unrelated guard.

## ux_reference

N/A — analyzer lint rule; no app surface.

## Verification

Result: Passed
Evidence: Nine new focused tests in the existing avoid_throw test file pass alongside the existing ones; full suite 2,153 passed. `dart format` and `dart analyze` clean. Hard-eng Draft gate passed after splitting the guard helper for the complexity check.
E2E: Passed — probe app (worktree path dependency) with the skill's Freezed `DisplayName` under `lib/features/profile/domain/values/` reports no `avoid_throw`; the `var`, reassigned, unrelated-local and `StateError` controls report; in `lib/features/profile/data/profile_api.dart` the untyped and mismatched-stack `Error.throwWithStackTrace` calls report while caught-pair propagation and typed translation do not; in `lib/features/profile/application/scoped_value.dart` the codegen `@Riverpod(dependencies: [])` stub is clean while the `@riverpod` stub and the untyped scoped throw report. All findings show at error severity.
Delivery target: Merge
Delivery: Pending — scoped PR, required CI, merge and main CI.
