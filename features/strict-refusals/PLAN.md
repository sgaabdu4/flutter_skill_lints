# Strict refusals: render object writes and next-frame deferral

Status: Ready

## Outcome + scope

1. A render widget can pass `avoid_mutating_parameters` and `consistent_update_render_object` together: inside an `updateRenderObject` override of a `RenderObjectWidget` subclass, writes to the render object parameter (the second one) are allowed. A write to any other parameter, and a write to that parameter in any other method, still reports.
2. A new rule `avoid_frame_deferral` refuses Flutter next-frame deferral calls in app code, old code too: `addPostFrameCallback`, `scheduleFrameCallback`, `scheduleFrame` and `endOfFrame`, resolved by element from `package:flutter/`. Test files and generated files are out of scope. Non-goals: Timer, `Future.delayed`, microtasks and other deferral that is not tied to a frame.

## Repository context

Owners: `lib/src/additional_lints/rules/avoid_mutating_parameters.dart`, `lib/src/additional_lints/rules/consistent_update_render_object.dart`, the new rule file in `lib/src/additional_lints/rules/`, `lib/src/additional_lints/additional_lints.dart` (registration), `test/plugin_registration_test.dart` (counts), README and `doc/` (counts and inventory), CHANGELOG, `pubspec.yaml` (version).
Same cause: N/A — no earlier fix of this cause; searched `lib/` for `addPostFrameCallback`, `scheduleFrame`, `endOfFrame` and `scheduleMicrotask`. `source_scanner_source.dart` (`_isDeferredReadCallback`) resolves `addPostFrameCallback`, `Timer`, `Future` and `scheduleMicrotask` only to decide where a ref read is deferred; it reports nothing about deferral, so it is not an owner of this rule and stays unchanged. A second conflict: the `riverpod_read_init_state` message says "Defer reads with a post-frame callback"; it changes in its own commit. The "updateRenderObject and second parameter" logic is in `consistent_update_render_object.dart`; it moves to one shared helper that both rules call. Test and generated file skips reuse `isTestSourceContext` and `isGeneratedRuleContext` in `lib/src/ast_utils.dart`.
Single source: the new rule file owns the list of frame deferral member names.

## Decisions + authorization

Blockers: None
Handoff: Approval
Authority: Owner asked for both changes, a draft PR first, and a ready PR when the local checks pass. Merge and release are not part of this task.

## Acceptance + steps

- [ ] One widget passes both rules; a write to the context parameter of `updateRenderObject` and a write to the parameter of another method still report → N/A — the plan check matches quoted test names and reflective Dart tests have none; the proof is `AvoidMutatingParametersTest` cases `test_updateRenderObjectWritesRenderObjectParameter_noLint`, `test_updateRenderObjectWritesContextParameter_lint` and `test_otherMethodWritesParameter_lint`.
- [ ] `avoid_frame_deferral` reports the four deferral calls on a Flutter binding, ignores a user method with the same name, and skips test and generated files → N/A — same reason; the proof is `AvoidFrameDeferralTest` in `test/additional_lints_avoid_frame_deferral_test.dart`.
- [ ] `riverpod_read_init_state` no longer tells the user to defer with a post-frame callback → N/A — no test reads the message text; the proof is the changed `correctionMessage` and the existing `riverpod_read_init_state` tests that still pass.
- [ ] The rule is registered, counted and documented in README, `doc/`, CHANGELOG and the version → `test/plugin_registration_test.dart::registers every additional analyzer rule file` and the CI job Check Version Consistency.

## Baseline + execution

Result: Passed
Evidence: Starting commit 113d91d on origin/main 4a36b8a; `dart test` with Dart 3.14.0: 2755 passed, 1 skipped, exit 0.
Execution: One builder; each change as its own commit, test first: shared render object helper, the parameter write fix, the `riverpod_read_init_state` message, the new rule, counts and docs, version.

## Risks + recovery

The vendored `building-flutter-apps` skill still shows `addPostFrameCallback` in its post-frame section; its owner repo needs its own PR. Recovery = revert the commit of the rule.

## ux_reference

N/A — analyzer diagnostics have no visual interface.

## Verification

Result: Pending
Evidence: Pending
E2E: N/A — no user journey; the rule tests run the real analyzer on an in-memory project.
Retro: Pending

Delivery target: Merge
Delivery: Pending — draft PR first; ready for review after the local checks pass; the coordinator merges.
