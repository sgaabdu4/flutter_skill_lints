# Enforce avoid_null_bang by default

Status: Complete

## Outcome + scope

Restore `avoid_null_bang` as a default-enabled error. Release 0.12.8 registered it as an opt-in lint rule, so apps that followed the building-flutter-apps analysis options no longer received the skill's documented diagnostic. `avoid_non_null_assertion` stays enabled; an unsafe `!` reports both.

## Repository context

Owners: `lib/flutter_skill_lints.dart` (registration), `lib/src/rules/avoid_null_bang.dart` (severity), `test/plugin_registration_test.dart`, `test/integration_plugin_smoke_test.dart`. The companion skill's `core-stack.md` and `tool/run_compatibility_fixture.py` require an `avoid_null_bang` diagnostic from the hosted plugin, and that check fails against published 0.12.14.

## Decisions + authorization

Blockers: None
Authority: The user directed that `avoid_null_bang` be enforced by default and that the fix be pushed.

## Acceptance + steps

- [x] Default registration includes `avoid_null_bang` as a warning rule; no lint-only rules remain.
- [x] `avoid_null_bang` reports at error severity, matching `avoid_non_null_assertion`.
- [x] A consumer package using only the plugin block reports both diagnostics on `title!` and fails analysis.
- [x] Registration and Flutter smoke expectations assert the rule is enabled without extra configuration.

## Baseline + execution

Result: Passed
Evidence: On 0.12.14, a consumer probe with `final String? title = null; print(title!);` reported only `avoid_non_null_assertion`; on 0.11.2 it also reported `avoid_null_bang`.
Execution: One builder changes registration and severity, updates the two tests, bumps to 0.12.15 and runs the native checks.

## Risks + recovery

Consumers now see two diagnostics per null assertion. This duplication is intentional because the skill's documentation and compatibility fixture rely on `avoid_null_bang`. To recover, revert this commit.

## ux_reference

N/A — analyzer diagnostics have no rendered application UI.

## Verification

Result: Passed
Evidence: `dart format`, `dart analyze` and 2,144 tests passed with one intentional skip. The consumer probe reports `avoid_null_bang` and `avoid_non_null_assertion` as errors.
E2E: Passed — the consumer probe ran the real analysis server with the plugin loaded from a path.
Delivery target: Merge
Delivery: Pending — scoped PR, required CI, merge and main CI.
