# UI presentation contract

Status: Complete

## Outcome + scope

Make the atomic-design and presentation-widget lints match the building-flutter-apps skill exactly. Report token, text-style, organism provider, page-base-class, widget-state and widget-navigation violations the skill forbids, allow the local modal dismissal it permits, and report every touched MUST/NEVER rule as an error.

## Repository context

Owners: `lib/src/rules/ui_source_rules.dart` (`style_raw_token`, `style_raw_text_style`), `lib/src/rules/source_scanner_rule.dart` (`atomic_provider_access` layer paths), `lib/src/rules/presentation_widget_source_rules.dart` (`presentation_widget_navigation_forbidden`, `presentation_widget_controller_state`) and `lib/src/rules/architecture_source_rules.dart` (new `atomic_page_consumer_widget`). Skill sources: `references/atomic-design.md:18-21,418`, `references/presentation-widgets.md:19-23`, `references/common-patterns/modals-navigation.md:117`, `references/common-patterns/routing-app-shell.md:212`.

## Decisions + authorization

Blockers: None
Authority: Owner decision that every lint enforcing a skill MUST/NEVER rule is an error; coordinator scope excludes `riverpod_watch_no_select`.
Decisions: Detection uses resolved elements and types. Raw colors are `dart:ui` `Color` constructors and Flutter `Colors`/`CupertinoColors` members; raw sizes are non-zero numeric literals for `Icon(size:)`, Flutter `iconSize:`, `TextStyle.copyWith(fontSize:)` and `BorderSide(width:)`. Widget State reports fields typed with domain-layer types (including collection type arguments) or Riverpod `AsyncValue`, and bool fields assigned before an `await` in the same async function. Navigation reports Navigator/NavigatorState calls, go_router APIs and calls on go_router `RouteData`; `pop`/`maybePop` with no work after it is allowed. Feature organisms under `presentation/widgets/` stay owned by `presentation_widget_infrastructure_dependency`.

## Acceptance + steps

- [x] `style_raw_token` and `style_raw_text_style` report as errors.
- [x] `style_raw_token` reports `Colors.x`, `Color(...)`, `Color.fromARGB/fromRGBO`, raw icon sizes, `copyWith(fontSize:)` and `BorderSide(width:)`; tokens and unrelated `Colors`-like classes stay clean.
- [x] `atomic_provider_access` covers `core/widgets/organisms/`.
- [x] `presentation_widget_controller_state` reports domain records, domain collections, `AsyncValue` snapshots and async workflow bools under any name; UI lifecycle objects and sync UI toggles stay clean.
- [x] `presentation_widget_navigation_forbidden` reports generic `Navigator.push<T>`, typed-route `push<T>`/`go` and go_router context calls; terminal `Navigator.pop(result)`/`maybePop()` is allowed and pop followed by work is reported.
- [x] New `atomic_page_consumer_widget` requires public screen widgets to extend a Riverpod consumer widget; counts and docs updated.

## Baseline + execution

Result: Passed
Evidence: Audit rows in `ui-findings.json` and `testnav-uiA.json` reproduced the false negatives, the pop false positive and the missing page rule.
Current baseline: Each fix added red tests in the existing rule test files before the change; every step was committed green.
Execution: One builder, one commit per rule change.

## Risks + recovery

Type-based State detection cannot see workflow flags that are never set before an await, or navigation stacks of non-domain types; those stay review items rather than name heuristics. `routing-app-shell.md:156` shows a presentation widget calling a typed route, which `presentation-widgets.md:21` forbids; the lint follows the owning presentation-widgets rule and the skill conflict is reported for an owner decision.

## ux_reference

N/A — analyzer lint behavior only; no app surface.

## Verification

Result: Passed
Evidence: `dart format lib test`, `dart analyze` (no issues) and `dart test` (2,161 passed) after each step; the full native Draft gate passed all 13 checks; a real Flutter probe app analyzed with this worktree reports every reproduction and leaves every control clean.
E2E: Passed — probe app `probe-ui-presentation-contract` analyzed with the plugin from this worktree.
Delivery target: Merge
Delivery: Pending — coordinator review.
