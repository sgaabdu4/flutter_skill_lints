# avoid_throw skill contract

Status: Complete

## Outcome + scope

Align `avoid_throw` with the building-flutter-apps skill for issues #42 and #95. The Value Object guard in `references/value-objects.md` (`final trimmed = input.trim(); if (trimmed.isEmpty) throw ArgumentError.value(input, ...)`) must not report. Resolved `dart:core` `Error.throwWithStackTrace` must follow the same typed-failure contract as direct throws ("Failures throw typed errors" in `references/networking.md`), while propagation of a caught error with its caught stack stays allowed. No other rule changes.

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
- [x] Coverage doc updated for both behaviours.

## Baseline + execution

Result: Passed
Evidence: Red tests committed first; three failed (final-local guard reported, untyped and presentation `Error.throwWithStackTrace` not reported).
Current baseline: `dart analyze` clean; 2,150 tests pass (1 skipped).
Execution: One builder; red tests, #42 fix, #95 fix, doc, probe, hard-eng.

## Risks + recovery

A saved error/stack pair passed through helper parameters is judged by the error's static type (an `Object` parameter reports), matching direct `throw error`; this limit is documented. Local provenance is bounded to `final` locals in the same factory body, so a looser alias cannot hide an unrelated guard.

## ux_reference

N/A — analyzer lint rule; no app surface.

## Verification

Result: Passed
Evidence: Six new focused tests in the existing avoid_throw test file pass alongside the existing ones; full suite 2,150 passed. `dart format` and `dart analyze` clean.
E2E: Passed — probe app (worktree path dependency) with the skill's Freezed `DisplayName` under `lib/features/profile/domain/values/` reports no `avoid_throw`; the `var`, reassigned, unrelated-local and `StateError` controls report; in `lib/features/profile/data/profile_api.dart` the untyped and mismatched-stack `Error.throwWithStackTrace` calls report while caught-pair propagation and typed translation do not.
Delivery target: Merge
Delivery: Pending — scoped PR, required CI, merge and main CI.
