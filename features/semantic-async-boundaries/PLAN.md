# Semantic analyzer boundaries

Status: Complete

## Outcome + scope

Correct four existing diagnostics for resolved abstract mock contracts, effectful and post-await reads, mounted guards, and SDK future-record `.wait`. Keep genuine concrete mocks, pure duplicate expressions, unsafe async writes, and ordinary positional records reported. Other reported lint rules remain outside this release.

## Repository context

Owners: `lib/src/rules/test_source_rules.dart`, `lib/src/additional_lints/rules/use_existing_variable.dart`, `lib/src/ast_utils.dart`, `lib/src/mounted_guard_utils.dart`, `lib/src/rules/use_ref_mounted_after_await.dart`, `lib/src/additional_lints/rules/avoid_positional_record_fields.dart`; corresponding existing suites in `test/`. Starting revision `b8bc092` was the delivered 0.12.9 baseline.

## Decisions + authorization

Blockers: None
Authority: The user authorized diagnostic repairs, publication, and delivery through main. One coordinator owns Git and release operations.

## Acceptance + steps

- [x] Resolved abstract mock targets clear while concrete targets, including I-prefixed and local SDK-lookalikes, warn; existing external SDK exceptions remain exact-library scoped → focused scanner tests pass.
- [x] Fresh reads after `await` and repeated effectful calls clear while a pure duplicate expression warns → focused analyzer-rule tests pass.
- [x] A disjunctive mounted guard or resolved safe private helper clears, while conjunctive, incomplete-return, revision-only, and overridden guards warn → focused mounted-rule tests pass.
- [x] The resolved `dart:async` future-record `.wait` literal clears while ordinary and lookalike positional records warn → focused record-rule tests pass.
- [x] Static analysis, the affected suites, and the full native gate pass with no suppression or baseline.

## Baseline + execution

Result: Passed
Evidence: Version 0.12.9 at `b8bc092` passed main CI and native Hard Eng verification. Against that revision, the added contract tests reproduced the reported diagnostic gaps and the incomplete-return false negative before their repairs.
Execution: Source and regression changes received an independent review, including effectful getters/operators and unsafe guard fallthrough cases.

## Risks + recovery

Static analysis must not trust a helper by name or accept a guard whose early-return branch can fall through. Keep conservative diagnostics when resolution or helper purity is unknown. Revert only this isolated diff if a focused or native gate fails.

## ux_reference

N/A — analyzer diagnostics have no rendered product UI.

## Verification

Result: Passed
Evidence: Red/green resolved-analyzer controls cover mock contracts, SDK declaration origins, effectful and post-await reads, pure operators, incomplete returns, impure guard suffixes, lazy initialization, overridden getters, and SDK record waits. `dart analyze --fatal-infos lib test` passes. The final native Complete gate passed 1,995 tests with one skip, 73.73% line coverage, and zero Decimate findings; its real-plugin smoke retains genuine concrete-mock and unsafe-mounted diagnostics while clearing supported cases.
E2E: N/A — the analyzer-rule contract is exercised through resolved AST tests and the real plugin smoke in the native gate; no application UI journey changed.
Delivery target: Merge
Delivery: Pending — verify exact-head PR and main CI, publish 0.12.10, and compare the hosted archive with the merged revision.
