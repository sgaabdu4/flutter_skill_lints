# Neutral value-object fixture names

Status: Complete

## Outcome + scope

The 0.12.0 value-object rule tests and examples use a neutral `Product` entity instead of field names taken from a real app. Non-goals: rule behaviour, version bump, other test files.

## Repository context

Owners: `test/source_scanner_rules_test/source_scanner_rules_part_12.dart` (`DomainRawRequiredStringTest`, `DomainUnitPrimitiveTest`); the `domain_unit_primitive` doc comment in `lib/src/rules/value_object_source_rules.dart`; the 0.12.0 `CHANGELOG.md` entry; `features/value-object-lint-coverage/PLAN.md`.

## Decisions + authorization

Blockers: None
Handoff: Approval
Authority: User asked to neutralise the test names.

## Acceptance + steps

- [x] Fixtures and examples use `Product`, `ProductId`, `title`, `description`, `lengthCm`, `discountPercent` → grep finds none of the old names.
- [x] Rule tests still pass with the same assertions → `dart test test/source_scanner_rules_test.dart --name 'DomainRawRequiredString|DomainUnitPrimitive'` passes.
- [x] Full gate passes → `python3 .hooks/hard-eng.py check --plan-stage Complete` exits 0.

## Baseline + execution

Result: Passed
Evidence: `main` at `90e41e6` passed CI before this change; renames touch no rule logic.
Execution: One builder; text renames only.

## Risks + recovery

None beyond a missed rename; revert restores the prior names.

## ux_reference

N/A — no visual surface.

## Verification

Result: Passed
Evidence: Old-name grep on the four files → no matches. Rule tests → 8 passed. `check --plan-stage Complete` → exit 0.
E2E: N/A — test fixture names only.

Delivery target: Merge
Delivery: Pending — PR checks green, merge to main, main CI green.
