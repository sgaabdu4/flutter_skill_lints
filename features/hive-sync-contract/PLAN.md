# Hive, sync and batch skill contract

Status: Complete

## Outcome + scope

Make the Hive, sync and batch lints match references/hive-persistence.md, common-patterns/debounce-gate-batch.md and common-patterns/delta-sync.md exactly. Remove the audited false positives, cover the audited gaps with resolved types, and report every data-layer MUST/NEVER lint in scope as an error. Rules owned by other builders are out of scope.

## Repository context

Owners: `lib/src/rules/persistence_crash_source_rules.dart` (Hive typeId, HiveField, reservation, and the new Hive boundary rules), `lib/src/rules/freezed_source_rules.dart` (`freezed_required_value_class`), `lib/src/rules/runtime_bug_source_rules/` (`notifier_zero_value_save_no_guard` and the sync, batch, storage and webview rules). The only cross-file precedent in the repository is the resolved import-graph walk in `avoid_flutter_host_driver_imports`; the typeId checks reuse that approach.

## Decisions + authorization

Blockers: None
Authority: Owner decision in the builder brief: every lint that enforces a skill MUST/NEVER rule is an ERROR. Rule ownership follows the builder OWNERS list.

- `hive_duplicate_field_id` compares resolved `HiveField` indexes per class or enum, not per file.
- `hive_duplicate_type_id` and `hive_reserved_type_ids_missing` resolve hive_ce annotations and walk same-package imports through the resolved `LibraryElement` graph. A collision is reported where it first meets: on the local annotation, or on the import directive when no single imported library already contains both declarations. Generated libraries such as the Hive registrar are not analyzed, so their imports stand in for them. Libraries that never meet in any import graph are not compared.
- `hive_reserved_type_ids_missing` requires every `@HiveType` id in the registration scope to appear in `reservedTypeIds`, as the skill's `reservedTypeIds: {0}` example does.
- New rules: `hive_type_on_freezed_class`, `hive_adapter_spec_domain_type` (resolved `T` declared under `/domain/`), `notifier_hive_access` (hive_ce references inside a class whose resolved supertypes include a Riverpod Notifier).
- `freezed_required_value_class` skips classes with a resolved hive_ce `@HiveType`.
- `notifier_zero_value_save_no_guard` counts only named arguments whose resolved type is numeric and accepts the skill's `if (amount <= 0 && count <= 0) return;` guard.

## Acceptance + steps

- [x] Ten data-layer MUST/NEVER rules report as ERROR.
- [x] Separate `@HiveType` classes may reuse HiveField 0 and 1; duplicates in one class still report.
- [x] Duplicate typeIds and unreserved `@HiveType` ids report across files through the resolved import graph, including through a generated registrar; deeper joins report only once.
- [x] Plain `@HiveType` data models no longer require Freezed; a local `HiveType` lookalike still does.
- [x] `@HiveType` on Freezed, `AdapterSpec` of a domain type and Hive inside a Notifier report.
- [x] The skill's early-return zero guard and Value Object saves are allowed; a non-exiting zero check still reports.

## Baseline + execution

Result: Passed
Evidence: Baseline `dart test` passed 2,144 tests before changes. The audit rows in `data-hive-sync.json` reproduced in the probe project.
Current baseline: 2,164 tests pass; `dart analyze` reports no issues.
Execution: One builder, commits per green step: severities, resolved Hive rules, zero-value guard.

## Risks + recovery

The import-graph approach cannot compare two `@HiveType` classes that no library imports together. Registration always imports them, directly or through the generated registrar, so real collisions meet in an analyzed library. Revert the Hive commit to restore the previous same-file checks.

## ux_reference

N/A — analyzer lint package; no app surface.

## Verification

Result: Passed
Evidence: `dart format lib test`, `dart analyze` (no issues) and `dart test` (2,164 passed). New tests were red against the previous rule code where they cover a false positive or gap.
E2E: Passed — probe app copied from the audit probe and pointed at this worktree; `dart analyze` reports the cross-file typeId collision, the unreserved cross-file @HiveType, the domain AdapterSpec, Hive in a notifier and @HiveType on Freezed, and no longer reports the doc's separate @HiveType field indexes, plain @HiveType models, the early-return zero guard or the Value Object save.
Delivery target: Merge
Delivery: Pending — branch handed back to the coordinating agent; not pushed.
