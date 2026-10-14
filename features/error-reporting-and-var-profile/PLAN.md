# Error-reporting applicability and var profile

Status: Complete

## Outcome + scope

Align two diagnostics with building-flutter-apps 5.12.1: `crash_init_before_run_app` reports only when the entrypoint's app has error reporting, and `prefer_type_over_var` no longer ships. Ship as patch 0.13.3. Out of scope: other crash rules, other lint profiles, dependency updates.

## Repository context

Owners: `lib/src/rules/persistence_crash_source_rules.dart` (crash rule) and its suite; `lib/src/additional_lints/dcm_expansion_lints.dart` + `rules/prefer_type_over_var.dart` (registration) and `test/plugin_registration_test.dart`. Skill text: [SKILL.md](../../.agents/skills/building-flutter-apps/SKILL.md) R24 and Pre-Flight; [error-reporting.md](../../.agents/skills/building-flutter-apps/references/error-reporting.md) checklist "No accepted/present provider → no SDK/facade/config change"; [analysis-options.md](../../.agents/skills/building-flutter-apps/references/analysis-options.md) "`prefer_type_over_var` is forbidden in this profile". Cause 1: the rule reports every `lib/main*.dart` `runApp` without an awaited `Crash.init`, whether or not reporting exists. Cause 2: `PreferTypeOverVar` is registered as a default-enabled warning rule; the skill's `analysis_options.yaml` never enables it, and `doc/building-flutter-apps-lint-coverage.md` already records it as removed.

## Decisions + authorization

Blockers: None
Handoff: Approval
Authority: Owner's request: fix both rules to match the skill text, failing tests first, patch bump + CHANGELOG, one PR, rebase-merge once required checks pass, confirm main CI. Release publication of the new version was approved by the owner.

## Acceptance + steps

- [x] An entrypoint whose same-package import graph has no `Crash` facade (class `Crash` with static `init`) and no provider import (`firebase_crashlytics`, `sentry`, `sentry_*`) → no `crash_init_before_run_app`.
- [x] A reachable `Crash` facade or a provider import without an awaited `Crash.init` before `runApp` → still reports; existing awaited/app-runner cases unchanged.
- [x] `prefer_type_over_var` is not registered, its source file is gone, and the off-profile file test forbids it.
- [x] Version 0.13.3 in `pubspec.yaml` and the first CHANGELOG entry; full `python3 .hooks/hard-eng.py check` passes.

## Baseline + execution

Result: Passed
Evidence: Starting revision `57b2679` (main after the Hard Eng a1ec36b5 update); its full check passed 12 of 12 on the same tree before this branch.
Execution: Single builder; red tests first per fix, then the fix at its owner.

## Risks + recovery

A provider used only outside the entrypoint's import graph does not trigger the rule; such code is unreachable from that entrypoint, so there is nothing to initialize. Recovery = revert the PR or publish a follow-up patch.

## ux_reference

N/A — analyzer diagnostics have no visual interface.

## Verification

Result: Passed
Evidence: Red first: `CrashInitBeforeRunAppTest` failed only `test_noErrorReporting_noDiagnostic`; `plugin_registration_test.dart` failed 5 registration cases. Green: crash suite 67 passed; registration + local-variable suites 54 passed; `dart analyze --fatal-infos` on changed Dart files clean. Codex adversarial review round 1 found sibling imports could reset detection; red test `test_crashFacadeBeforeUnrelatedSiblingImport_reports` failed, then passed after the fix. Round 2 approved with no findings. Full `python3 .hooks/hard-eng.py check` run on the final tree before push.
E2E: Passed — `RUN_FLUTTER_PLUGIN_SMOKE=1 dart test test/integration_plugin_smoke_test.dart` passed in a real Flutter analysis-server run and no longer reports `prefer_type_over_var`.

Delivery target: Merge
Delivery: Pending — PR merged into main with required checks passing, main CI green, 0.13.3 published.
