# Explicit types over var

Status: Complete

## Outcome + scope

`prefer_type_over_var` ships again as a default-enabled rule and reports every `var` declaration; inferred `final` stays allowed. Ship as patch 0.13.4. Out of scope: `always_specify_types`, other rules, the `crash_init_before_run_app` change from 0.13.3.

## Repository context

Owners: `lib/src/additional_lints/rules/prefer_type_over_var.dart` and its registration in `lib/src/additional_lints/dcm_expansion_lints.dart`; tests in `test/additional_lints_dcm_worker_bg_local_variables_test.dart` and `test/plugin_registration_test.dart`. 0.13.3 removed the rule to match the skill text then in place; the owner reversed that decision and the skill text is being changed to require explicit types instead of `var`. The 0.13.3 rule missed `var` in `for`-in and `await for` loop variables (`DeclaredIdentifier`) and `for`-in patterns (`ForEachPartsWithPattern`). A `var` parameter is a compile error in current Dart, so parameters need no rule.

## Decisions + authorization

Blockers: None
Handoff: Approval
Authority: Owner's correction: ban `var` only, keep inferred `final`, restore the rule as default-enabled, failing test first, one PR, rebase-merge when green, push tag v0.13.4 (release approved).

## Acceptance + steps

- [x] `prefer_type_over_var` is registered by default and absent from the off-profile list.
- [x] Local, top-level, field, `for` loop, `for`-in, `await for`, pattern declaration, `for`-in pattern and `case var` declarations report at `var`.
- [x] Inferred `final` locals, top-level values, loop variables and patterns, and explicit types, do not report.
- [x] Version 0.13.4 in `pubspec.yaml` and the first CHANGELOG entry; full `python3 .hooks/hard-eng.py check` passes.

## Baseline + execution

Result: Passed
Evidence: Starting revision `e272e62` (0.13.3, published); its main CI passed.
Execution: Single builder; red tests first, then the rule at its owner.

## Risks + recovery

Apps that use `var` get new diagnostics after upgrading; that is the intended policy. Recovery = follow-up patch.

## ux_reference

N/A — analyzer diagnostics have no visual interface.

## Verification

Result: Passed
Evidence: Red first: with the rule absent, the restored test file failed to load and 4 registration cases failed; with the 0.13.3 rule restored, `for`-in, `await for` and `for`-in pattern cases failed. Green: registration + local-variable suites 65 passed; `dart analyze --fatal-infos` on changed Dart files clean. Codex adversarial review round 1 approved with no findings. Full `python3 .hooks/hard-eng.py check` passed 12 of 12 (2,714 tests, 79.44% line coverage against the 70% minimum).
E2E: Passed — `RUN_FLUTTER_PLUGIN_SMOKE=1 dart test test/integration_plugin_smoke_test.dart` passed in a real Flutter analysis-server run and reports `prefer_type_over_var`.

Delivery target: Merge
Delivery: Pending — PR merged into main with required checks passing, main CI green, 0.13.4 published.
