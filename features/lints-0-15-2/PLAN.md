# Release 0.15.2: async rule follow-ups, hardcoded copy shapes and two UI rules

Status: Complete

## Outcome + scope

The `avoid_provider_turn_hop` follow-ups, more shapes of hardcoded user text, and two Flutter UI rules from the Hard Eng UI plan ship as 0.15.2. Out of scope: other rules, and code in other files for the helper follow.

## Repository context

Owners: `lib/src/rules/provider_turn_hop_visitor.dart` (turn hop checks), `lib/src/additional_lints/rules/avoid_hardcoded_strings.dart`, the new `avoid_small_font_size.dart` and `avoid_conflicting_filled_buttons.dart` in the same folder, `additional_lints.dart` (registration), `README.md` and `doc/` (counts, inventory, boundaries), `CHANGELOG.md` and `pubspec.yaml` (version). The 0.15.0 review found the async cases; a Hard Eng builder listed the text shapes; the UI plan names the two UI rules.
Same cause: N/A — each async case is its own gap in how a local value is tracked; the rows that cover them share one table.
Single source: N/A — no value or type is copied by this change. The two new rules do not repeat `style_raw_token`: that rule says where a raw size must live, and the new one says the size is below 14.

## Decisions + authorization

Blockers: None
Handoff: Approval
Authority: The owner asked for flutter_skill_lints fixes and new Flutter best-practice rules in this package (standing approval of 2026-11-15) and for 0.15.2 as one PR.

## Acceptance + steps

- [x] A `??=` fallback with `Future.value` stays clean, and a completed value kept by `??=` still reports → `test/provider_turn_hop_state_rows.dart::clean_null_coalescing_assign_future_value_fallback` and `test/provider_turn_hop_state_rows.dart::null_coalescing_assign_keeps_completed_value`
- [x] A completer reset before the await stays clean until the new one is completed → `test/provider_turn_hop_state_rows.dart::clean_completer_reset_before_await` and `test/provider_turn_hop_state_rows.dart::completer_reset_then_completed_before_await`
- [x] A completer completed in `finally`, a `late` completer and the `!` forms report; `complete` in a `try` body or in a later `finally` stays clean → `test/provider_turn_hop_state_rows.dart::completer_completed_in_finally_before_await`, `test/provider_turn_hop_state_rows.dart::late_completer_assigned_then_completed`, `test/provider_turn_hop_state_rows.dart::completer_future_through_bang`, `test/provider_turn_hop_state_rows.dart::clean_completer_completed_in_try_body_before_await`
- [x] A getter, a mixin method and a base class method in the same file are followed one level, and a real delay stays clean → `test/provider_turn_hop_state_rows.dart::notifier_build_reads_getter_that_hops`, `test/provider_turn_hop_state_rows.dart::notifier_build_calls_mixin_method_that_hops`, `test/provider_turn_hop_state_rows.dart::notifier_build_calls_base_class_method_that_hops`, `test/provider_turn_hop_state_rows.dart::clean_getter_with_real_delay`
- [x] The changelog names a static helper and `overrideWith` as the code does → `test/provider_turn_hop_state_rows.dart::notifier_build_calls_static_helper_that_hops` and `test/provider_turn_hop_state_rows.dart::tear_off_passed_to_provider_override_with`
- [x] Hardcoded text in conditional and switch branches, compound label names, widget defaults, initializers and fields, constant list lookups and label getters reports → `test/additional_lints_avoid_hardcoded_strings_shapes_test.dart::test_conditionalInText_lint`, `test/additional_lints_avoid_hardcoded_strings_shapes_test.dart::test_compoundLabelNameLiteral_lint`, `test/additional_lints_avoid_hardcoded_strings_shapes_test.dart::test_constructorDefaultLabel_lint`, `test/additional_lints_avoid_hardcoded_strings_shapes_test.dart::test_constantListLookupInText_lint` and `test/additional_lints_avoid_hardcoded_strings_shapes_test.dart::test_enumGetterLabelInFlutterFile_lint`
- [x] Literals passed to a model constructor, stored through `copyWith` or passed to a service that is not UI stay clean → `test/additional_lints_avoid_hardcoded_strings_shapes_test.dart::test_literalPassedToModelConstructor_noLint`, `test/additional_lints_avoid_hardcoded_strings_shapes_test.dart::test_literalStoredByCopyWith_noLint` and `test/additional_lints_avoid_hardcoded_strings_shapes_test.dart::test_literalPassedToNonUiService_noLint`
- [x] A literal `fontSize` under 14 in a `TextStyle`, a dot shorthand or `copyWith` reports; 14 and a non-literal do not → `test/avoid_small_font_size_test.dart::reportsIntegerLiteralUnderFourteen` and `test/avoid_small_font_size_test.dart::allowsNonLiteralSizes`
- [x] Filled buttons with different fills in one `Row` or `Wrap` report; equal fills do not → `test/avoid_conflicting_filled_buttons_test.dart::reportsExplicitColourBesideDefaultFill` and `test/avoid_conflicting_filled_buttons_test.dart::allowsSameExplicitColour`
- [x] The red card fails the four guidelines and the fixed card passes at 390, 768 and 1280 px, and the two rules report the red card only → `integration_test/ui_quality_fixture_test.dart::red card fails and fixed card passes`
- [x] The rule count, the inventory and the version agree → `test/plugin_registration_test.dart::registers every additional analyzer rule file` and the CI version check

## Baseline + execution

Result: Passed
Evidence: On main 8b05a79 the full `dart test` run passed (exit 0) before any edit.
Execution: One builder; one commit for each of the async rows, the text shapes, the two rules and the fixture.

## Risks + recovery

Risk: the wider text rule adds findings in projects that use label getters or compound label names. Recovery: those findings point at real user text; fix the project. Risk: the test job now needs Flutter and runs longer. Recovery: revert the workflow step and the fixture test.

## ux_reference

N/A — analyzer rules only; no rendered interface of this package changes.

## Sources + coverage

Sources: the 0.15.0 round six review list, the Hard Eng builder list of text shapes, and the Hard Eng UI plan rows for the font floor and filled buttons.

## Verification

Result: Passed
Evidence: `dart run coverage:test_with_coverage --branch-coverage` passed 3,515 tests (exit 0). `dart-decimate json .` (0.0.75) gave verdict pass with 0 findings. `dart analyze --fatal-infos .`, `dart format --set-exit-if-changed .` and `dart pub publish --dry-run` (0 warnings) were clean. The Flutter plugin smoke test passed on 0.15.1 and on 0.15.2. The analyzer output of its app has no changed result for any file that both versions analyze (0 removed, 0 added); the 19 new files are the new rows. Every new test was seen failing before its fix: 11 turn hop rows and 9 text cases failed on the old rules, and the card test failed on the first card.
E2E: N/A — no user journey; the real analyzer server run is the Flutter plugin smoke test and the fixture test.
Retro: (1) the 0.15.0 review found six async cases that no row covered -> the first four Acceptance rows; (2) the first gate run refused three complex functions and a test file over 1000 lines -> None — the gate caught both before the push, and each repair has its own commit.

Delivery target: PR
Delivery: Pending — PR checks pass.
