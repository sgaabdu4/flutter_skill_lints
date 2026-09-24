# Architecture, services and mixins contract

Status: Complete

## Outcome + scope

Align the architecture, singleton, fire-and-forget, mixin and error-code lints with the building-flutter-apps skill (architecture.md, services-and-singletons.md, mixins.md, hive-persistence.md): report every documented MUST/NEVER shape as an error and allow the skill's own examples. Scope is the rules owned by this slice; other builders' rules are untouched.

## Repository context

Owners: `lib/src/rules/architecture_source_rules.dart`, `architecture_extended_source_rules.dart`, `services_mixins_source_rules.dart`, `services_extended_source_rules.dart`, `persistence_crash_source_rules.dart`, `source_scanner_rule.dart`, `use_unawaited_for_fire_and_forget_futures.dart`, `additional_lints/rules/avoid_inline_error_codes.dart` and `prefer_match_file_name.dart`, with their existing test files. The audit rows showed text-scanner false positives and false negatives: import strings, `=`-only field regexes, name-based singleton detection, keyword-only fire-and-forget checks and class-method-only Random scans.

## Decisions + authorization

Blockers: None
Authority: Coordinator brief for the lint audit fix; skill text wins over the previous lint behavior.
- Skill MUST/NEVER rules in this slice report as ERROR.
- `arch_domain_import` and new `arch_storage_sdk_import` read resolved import URIs.
- `arch_model_missing_to_entity` accepts `toEntity`/`toDomain` methods and mapper extensions; new `arch_repository_inline_entity_mapping` reports inline model-to-entity construction in repositories.
- `service_singleton` finds a singleton by its one non-const static field typed as the class itself, exposed through a public static field/getter or a public factory that returns it (#51). It reports public constructors (including the synthetic default), public fields/getters/setters other than the exposed instance, and public methods whose resolved return type is not `void`/`Future<void>`. Const and multi-instance registries are not singletons.
- `fire_and_forget_missing_catch` resolves the `unawaited(...)` callee (same unit, or the parsed declaring library) and reports when its body has no catch clause and no `catchError`/`onError`. An empty body is allowed, as in the skill's `refresh() async {}`. Callees without a body (SDK, abstract, external) keep the previous keyword heuristic. The name-based `_send`/`_runCrashOperation` exemption is removed.
- `use_unawaited_for_fire_and_forget_futures` reads the parameter from the enclosing named argument, so `onPressed: () { f(); }` reports.
- `mixin_mutable_state` checks `FieldDeclaration` members of mixins and `mixin class` through the AST, so uninitialized, `late` and static mutable fields report and `=>` members never do. Private fields in mixins `on State`/`ConsumerState`/`HookConsumerState` stay allowed.
- `service_random_per_call` reports dart:math `Random` construction inside any function body; module-level and static initializers stay allowed.
- `avoid_inline_error_codes` allows code comparisons whose receiver is a dart:core `Exception` (mixins.md retry predicate `e.code == 429`); `response.statusCode == 404` still reports.
- `prefer_match_file_name` accepts `i_<name>.dart` for resolved abstract interface classes named `I<Name>` (hive-persistence.md `i_order_repository.dart`).

## Acceptance + steps

- [x] Each audit row has a reported-case control and a still-reporting negative control in the rule's existing test file.
- [x] Skill examples (canonical and getter singleton, canonical fire-and-forget, stateless mixins, retry predicate, interface file names) produce no diagnostic.
- [x] Counts and coverage docs include the two new rules.
- [x] Format, analyze, full test suite, probe consumer and Hard Eng Draft check pass.

## Baseline + execution

Result: Passed
Evidence: The audit probe (`scratchpad/probe-arch`) against the published package reproduced each row: false negatives for both-constructor and token-getter singletons, uncaught `unawaited` callees, uninitialized mixin fields, top-level `Random()` and `onPressed` drops; false positives for catching callees, `=>` mixin members and the skill's retry example.
Current baseline: 2,175 tests pass (1 skipped); analyzer reports no issues.
Execution: One builder fixed each rule in its existing file, red test first, and committed after each green step.

## Risks + recovery

Resolved-shape singleton detection could catch value classes with one static self instance; const instances and multi-instance registries are excluded and covered by a control. Parsing the callee's library is limited to non-SDK libraries with a body and falls back to the old heuristic otherwise. Recovery is reverting the single rule commit.

## ux_reference

N/A — analyzer plugin rules; no app surface.

## Verification

Result: Passed
Evidence: `dart format` clean, `dart analyze` no issues, `dart test` 2,175 passed (1 skipped). Probe copy `scratchpad/probe-arch-services-mixins-contract` pointed at this worktree reports every VIOLATION file for the rows (mixin nullable/late fields, both-constructor, getter and #51 cache singletons, uncaught same-file and cross-file `unawaited` callees, `onPressed` drop, top-level and closure `Random`) and leaves every CONTROL clean (catching callees, canonical singletons, stateless mixins, `ap_retry.dart`, `i_probe_b_items_repository.dart`). `python3 .hooks/hard-eng.py check --base origin/main --plan-stage Draft` passed every gate (format, types-lint, security, import boundaries, 2,175 tests with 75.69% line coverage, dead-code-duplicates after splitting two complex functions, performance, secrets, actionlint, zizmor).
E2E: Passed — real consumer probe app analyzed with `dart analyze` through the plugin path.
Delivery target: Merge
Delivery: Pending — coordinator integrates the branch.
