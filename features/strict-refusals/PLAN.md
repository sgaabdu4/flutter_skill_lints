# Strict refusals: render object writes and next-frame deferral

Status: Complete

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

- [x] One widget passes both rules; a write to the context parameter of `updateRenderObject` and a write to the parameter of another method still report → N/A — the plan check matches quoted test names and reflective Dart tests have none; the proof is in `test/additional_lints_dcm_worker_t_mutation_test.dart`: `AvoidMutatingParametersTest` cases `test_updateRenderObjectWritesRenderObjectParameter_noLint`, `test_updateRenderObjectCascadeWritesRenderObjectParameter_noLint`, `test_updateRenderObjectWritesContextParameter_lint`, `test_otherMethodWritesRenderObjectParameter_lint` and `test_updateRenderObjectOutsideRenderObjectWidget_lint`, and `ConsistentUpdateRenderObjectSharedWidgetTest` case `test_widgetThatWritesRenderObjectParameter_noLint`.
- [x] `avoid_frame_deferral` reports the four deferral calls on any Flutter binding, ignores a user method with the same name, and skips test and generated files → `test/avoid_frame_deferral_test.dart::reportsAddPostFrameCallbackOnWidgetsBinding`, `reportsAddPostFrameCallbackOnSchedulerBinding`, `reportsAddPostFrameCallbackOnBindingVariable`, `reportsScheduleFrameCallback`, `reportsScheduleFrame`, `reportsAwaitedEndOfFrame`, `reportsEndOfFrameReadFromBindingVariable`, `allowsUserMethodsWithTheSameNames`, `allowsOtherSchedulerMembers`, `skipsTestFiles` and `skipsGeneratedFiles`.
- [x] No correction message names a deferral as the fix: `riverpod_read_init_state` (post-frame callback) and `avoid_sync_notifier_state_read` (`Future.microtask`) now name a fix with no wait → `test/plugin_registration_test.dart::no correction message names a deferral call as the fix`.
- [x] The rule is registered, counted and documented in README, `doc/`, CHANGELOG and the version → `test/plugin_registration_test.dart::registers every additional analyzer rule file` and the CI job Check Version Consistency.

## Baseline + execution

Result: Passed
Evidence: Starting code = origin/main 4a36b8a plus the plan file only; `dart test` with Dart 3.14.0: 2755 passed, 1 skipped, exit 0. Red first for the parameter write fix: 3 of 5 new cases in `AvoidMutatingParametersTest` failed on the old code; the message test failed with `riverpod_read_init_state` listed; the rule tests failed against a rule that reports nothing (7 of 11); the count test failed before the rule was registered (5 failures).
Execution: One builder; each change as its own commit, test first: shared render object helper, the parameter write fix, the `riverpod_read_init_state` message, one shared test suite helper, the new rule with counts and docs, version 0.14.0, comment cuts in touched files, the doc comment skip and the pins in README and example.

## Risks + recovery

Version: 0.14.0, not 0.13.8. Projects pin `^0.13.4`, so a 0.13.x release would reach every project on its next analyze, and the new rule would fail them before their fix PRs merge. A 0.14.0 release needs an explicit pin bump. The release job tags and publishes on the merge of the version bump, so this PR waits for the owner to merge it. No tag is pushed by hand.
The vendored `building-flutter-apps` skill still shows `addPostFrameCallback` in its post-frame section; its owner repo needs its own PR. Recovery = revert the commit of the rule.

## ux_reference

N/A — analyzer diagnostics have no visual interface.

## Verification

Result: Passed
Evidence: Dart 3.14.0. `python3 .hooks/hard-eng.py check` ran every gate of `hard-eng.gates.json`: security, vulnerabilities, freshness, lockfile, format, types-lint, tests (2780 tests with branch coverage), dead-code-duplicates, performance, secrets-files, secrets-history, actionlint and zizmor, all exit 0 (final run recorded in the PR). The real analyzer smoke test `RUN_FLUTTER_PLUGIN_SMOKE=1 dart test test/integration_plugin_smoke_test.dart` passed on a copy with a 40 minute limit in 9 min 56 s; the committed 5 minute limit is too short on this Mac and the CI job passes it. Limit: no real app was analysed.
E2E: N/A — no user journey; the rule tests run the real analyzer on an in-memory project.
Retro: (1) The comment check failed on multi-line comment blocks in touched files, first seen in the full check → fix the plan step: run `check --plan-stage Ready` after the last edit of a file, before commit. (2) The `pr text` check failed on the first PR body (no Undo line, no Mermaid diagrams, no Not checked line) → run `body_problem` from `.hooks/pr_text.py` on the body before `gh pr create`. (3) A doc comment reference to a frame API was reported, found in review → `test/avoid_frame_deferral_test.dart::ignoresDocCommentReferences`. (4) Escaped bug: the two render object rules disagreed on the base branch, so no widget passed both; the gate that should catch it is the rule tests → `test/additional_lints_dcm_worker_t_mutation_test.dart::test_updateRenderObjectWritesRenderObjectParameter_noLint`, which failed on the old code. (5) Two correction messages named a deferral as the fix → `test/plugin_registration_test.dart::no correction message names a deferral call as the fix`.

Delivery target: Merge
Delivery: Pending — the owner merges; the merge publishes 0.14.0 from CI.
