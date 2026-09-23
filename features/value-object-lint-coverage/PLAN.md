# Value-object lint coverage

Status: Complete

## Outcome + scope

Make `dart analyze` report the Flutter skill's value-object rules (R5 required domain strings, R12 unit/currency numbers) on Freezed domain entity constructors, released as 0.12.0. Non-goals: semantic judgement of unit-free numbers (`steps`, `weekday`), plain non-Freezed domain classes, fixes in consumer apps.

## Repository context

Owners: `lib/src/rules/value_object_source_rules.dart` (existing VO rules only inspect `/domain/values/` and named entity factories); `test/source_scanner_rules_test/source_scanner_rules_part_12.dart`; `doc/building-flutter-apps-lint-*.md`; `README.md`; `CHANGELOG.md`; `pubspec.yaml`. Evidence: a Flutter consumer app shipped 54 raw `required String`/unit-named `int` fields in `/domain/` entities with `dart analyze --fatal-infos` clean; `typed_id_raw_id` only matches 2+ `final String xId;` fields.

## Decisions + authorization

Blockers: None
Handoff: Approval
Authority: User asked to fix the gap in the canonical skill + lints and push a new version out, and to keep building-flutter-apps current.

## Acceptance + steps

- [x] `domain_raw_required_string` reports each non-nullable, non-defaulted `String` parameter of an unnamed Freezed constructor in `/domain/` outside `/domain/values/`; allows VO types, `String?`, `List<String>`, named union factories, data models and value objects → `DomainRawRequiredStringTest` passes.
- [x] `domain_unit_primitive` reports unit/currency-named `int`/`double`/`num` parameters, including `@Default` and nullable ones; allows counts and `Duration` → `DomainUnitPrimitiveTest` passes.
- [x] Real analyzer server reports both diagnostics on the consumer app's domain entities with the plugin wired by path → `dart analyze` output lists `domain_raw_required_string` and `domain_unit_primitive`.
- [x] Version 0.12.0 is consistent in `pubspec.yaml`, `CHANGELOG.md` and README; rule counts and inventory match registration → `plugin_registration_test.dart` passes.
- [x] Full gate passes → `python3 .hooks/hard-eng.py check --plan-stage Complete` exits 0.

## Baseline + execution

Result: Passed
Evidence: `python3 .hooks/hard-eng.py check --plan-stage Draft` on starting commit `bd8ff56` (clean worktree + this plan) → exit 0; all 14 gates PASS.
Execution: One builder; rules + tests, then docs/version, then consumer validation.

## Risks + recovery

New ERROR diagnostics fail existing consumer analysis after upgrade; minor version bump (0.12.0) and CHANGELOG entry signal it. False positive on a unit word → narrow `_unitWords` and add an allow test.

## ux_reference

N/A — analyzer plugin with no visual surface.

## Verification

Result: Passed
Evidence: `dart test test/source_scanner_rules_test.dart --name 'DomainRawRequiredString|DomainUnitPrimitive|DomainEntityPrimitive|DomainEmptyString'` → 19 passed. Consumer app copy with the plugin by path: `dart analyze` → 39 `domain_raw_required_string` + 9 `domain_unit_primitive` on `/domain/entities/` files, no other diagnostics (previously "No issues found"). `check --plan-stage Ready` on the change → 14/14 gates PASS. `dart pub publish --dry-run` → only the uncommitted-files warning. Limit: unit-free numbers (`glassesTarget`, `steps`) stay a review judgement.
E2E: N/A — no user journey; real analyzer-server proof is the consumer `dart analyze` acceptance item.

Delivery target: Merge; Delivery: Pending — PR checks, merge to main, tag `v0.12.0`, pub.dev publish workflow success.
