# prefer_type_over_var at error severity

Status: Complete

## Outcome + scope

`prefer_type_over_var` reports at error severity, so `var` fails plain `dart analyze`, not only `--fatal-infos`. Ship as patch 0.13.5. Out of scope: the rule's coverage, other rules' severities.

## Repository context

Owners: `lib/src/additional_lints/rules/prefer_type_over_var.dart` (`LintCode` severity); `test/plugin_registration_test.dart` `_modelSkillErrorDiagnostics` (skill MUST/NEVER codes that must be errors). building-flutter-apps 5.12.2 says "Explicit types, never `var`", and its text names no severity, so the skill needs no change.

## Decisions + authorization

Blockers: None
Handoff: Approval
Authority: Owner approved raising the rule to error severity, a 0.13.5 patch, one PR, rebase-merge when green and the Auto-Tag Release publish.

## Acceptance + steps

- [x] `prefer_type_over_var` is listed with the skill MUST/NEVER diagnostics and every code it reports is `DiagnosticSeverity.ERROR`.
- [x] Version 0.13.5 in `pubspec.yaml` and the first CHANGELOG entry; full `python3 .hooks/hard-eng.py check` passes.

## Baseline + execution

Result: Passed
Evidence: Starting revision `a76e5ea` (0.13.4, published); its main CI passed.
Execution: Single builder; red test first, then the severity at its owner.

## Risks + recovery

Projects with `var` now fail analysis after upgrading; that is the intended policy. Recovery = follow-up patch.

## ux_reference

N/A — analyzer diagnostics have no visual interface.

## Verification

Result: Passed
Evidence: Red first: `model skill MUST and NEVER diagnostics report at error severity` failed with `DiagnosticSeverity:<INFO>`; it passes after the change, with the registration and local-variable suites at 65 passed. Codex adversarial review round 1 approved with no findings. Full `python3 .hooks/hard-eng.py check` passed 12 of 12 (2,714 tests, 79.44% line coverage).
E2E: Passed — `RUN_FLUTTER_PLUGIN_SMOKE=1 dart test test/integration_plugin_smoke_test.dart` passed in a real Flutter analysis-server run once the fixture's `build` resolution was held at 4.0.11 locally. Unpinned, it fails before analysis because `build` 4.1.0 (published 2026-10-14) breaks `build_runner` 2.16.2.

Delivery target: Merge
Delivery: Pending — PR merged into main with required checks passing, main CI green, 0.13.5 published.
