# State and notifier structure contract

Status: Complete

## Outcome + scope

Make the Riverpod codegen and notifier-structure lints match `references/riverpod-codegen.md` and `references/state-management/notifier-structure.md` exactly. Legacy APIs, manual providers, generated-provider aliases, `WidgetRef` outside widgets, `ConsumerState` derived caches, stored `Ref` fields, notifier suffixes, sync state reads and unguarded async-init writes must report as errors through resolved elements. Guarded async-init writes must not report.

## Repository context

Owners: `avoid_legacy_riverpod_apis`, `riverpod_manual_provider`, `riverpod_consumer_state_derived_cache`, `notifier_async_init_stale_state_write`, `avoid_sync_notifier_state_read`, `use_notifier_suffix`, `riverpod_feature_notifier_keepalive` and `use_ref_invalidate`. The new rules are `riverpod_generated_provider_alias`, `riverpod_widget_ref_outside_widget` and `notifier_stored_ref_field`. The shared `hasRiverpodCodegenAnnotation` helper is in `lib/src/ast_utils.dart`.

## Decisions + authorization

Blockers: None
Authority: The rule owner instructed that every rule in this contract uses ERROR severity. `use_ref_invalidate` has no skill anchor, so it is raised to ERROR only on that instruction. The lint rules stay strict where the skill examples disagree. The skill repo is fixing those docs: `ProductEditor` becomes `ProductEditorNotifier`, `cartTotal` becomes keepAlive per `performance.md:161-169`, and the `Future.microtask` guidance will be settled.

## Acceptance + steps

- [x] Legacy `legacy.dart` imports, `StateNotifier`, Ref aliases and subtypes, and riverpod-owned manual providers are resolved and report as errors.
- [x] Typed or function-returned manual providers report, and generated-provider aliases report through a new rule.
- [x] `ConsumerState` fields assigned from `WidgetRef` watch or read results report. Constructor-argument uses stay allowed.
- [x] `WidgetRef` in non-widget classes, mixins and enums reports. Extensions and top-level functions stay allowed.
- [x] A resolved `if (!ref.mounted) return;` after the await clears `notifier_async_init_stale_state_write`.
- [x] Same-class sync helpers that read `state` before the first await report.
- [x] Notifier subclasses, generated notifiers and annotated notifier classes without the `Notifier` suffix report.
- [x] `Ref`-typed fields in notifiers report, including inferred ones. `Ref` fields outside notifiers and unrelated `Ref` types stay allowed.
- [x] `riverpod_feature_notifier_keepalive` and `use_ref_invalidate` are ERROR. The rule inventory, coverage doc and README counts (190 rules, 198 diagnostics, 474 unique) are updated.

## Baseline + execution

Result: Passed
Evidence: The audit rows in the state/notifier contract showed false negatives, gaps, one false positive (guarded async init) and non-error severities for these rules.
Current baseline: `origin/main` at `b0878e9` had 187 rules and 195 diagnostics, with these rules at INFO or WARNING.
Execution: One builder worked on one rule per commit, red test first, then the fix, then a full native check.

## Risks + recovery

Resolving through the analyzer element model could miss unresolved code before codegen runs. Annotated classes are therefore matched through the resolved `riverpod_annotation` element, not names. A bare `ProductRepository? _repo;` that is never assigned from `ref` cannot be tied to a provider without name heuristics, so it remains out of scope. Each rule has its own commit and can be reverted on its own.

## ux_reference

N/A — analyzer plugin rules; no app surface.

## Verification

Result: Passed
Evidence: `dart format`, `dart analyze` and the full `dart test` suite passed. Focused red/green tests and negative controls exist for every changed rule. The consumer probe (`probe-state-notifier-structure-contract`, pointed at this worktree, after `build_runner`) reports ERROR on the literal skill `class ProductEditor extends _$ProductEditor` (`use_notifier_suffix`), on explicit and inferred stored `Ref` fields, on the autoDispose feature notifier, on the ignored `ref.refresh`, and on the generated alias, `WidgetRef` field, legacy and manual providers. The keepAlive notifier that uses the inherited `ref` and the non-notifier `Ref` holder stay clean.
E2E: Passed — a real Flutter consumer app analyzed the generated code through the plugin.
Delivery target: Merge
Delivery: Pending — coordinator review and merge.
