# Testing and navigation skill contract

Status: Complete

## Outcome + scope

Make the testing, E2E and navigation lints match the building-flutter-apps skill exactly: report every testing.md, dart-mcp-e2e-testing.md, deep-linking.md, modals-navigation.md, routing-app-shell.md and lists-forms-workflows.md violation the audit found, stop reporting the skill's own compliant examples, and run every touched rule at error severity. Scope is the testnav rows in OWNERS.md: test_* and missing_test_assertion, finder and key rules, router_* except router_complex_extra, modal_* and PopScope rules, pop helpers, avoid_route_param_throw_in_build, the notifier Timer dispose gap and E2E sleeps. Issue #77 is included. Issue #71 (closed as not planned; a local test GoRouter fixture) is out of scope. The skill doc defects found by the audit (the routing-app-shell.md `@visibleForTesting` resolver, testing.md `pumpAndSettle(timeout:)` and the DraftNotifier Timer without onDispose, which the new rule reports as intended) are fixed in the skill repo, not here.

## Repository context

Owners: test_source_rules.dart, router_source_rules.dart and its part_01, router_extended_source_rules.dart, dialog_source_rules.dart, notifier_source_rules.dart, avoid_route_param_throw_in_build.dart, missing_test_assertion.dart, use_context_is_current_modal_route.dart, ast_utils.dart, source_scanner_rule.dart (the removed loading-bounce text heuristic) and riverpod_type_checkers.dart (new anyNotifierChecker, which also matches generated `_$X extends $Notifier` classes). Tests live in the existing rule suites: source_scanner_rules parts 09, 10, 12, 14 and 17, extended_source_rules_test.dart, flutter_skill_rules part_01 and plugin_registration_test.dart. Rules owned by other builders (presentation_widget_navigation_forbidden, implicit_null_fallback, the dialog_source_rules WARNING rules) are unchanged.

## Decisions + authorization

Blockers: None
Authority: Coordinator-assigned builder under the flutter_skill_lints fix brief. The skill text wins; CHANGELOG.md and the pubspec version are unchanged; no push.

## Acceptance + steps

- [x] Testing and navigation skill-contract lints owned by this row run at error severity, including the four new rules.
- [x] test_mock_concrete reports Fake doubles of concrete classes and mocks of concrete SDK and plugin classes (#77: the appwrite and youtube allowlist is removed); abstract contracts stay allowed.
- [x] test_inline_value_key covers Key(...) as well as ValueKey(...); test_first_match_finder ignores `.first` on a plain Iterable.
- [x] router_pop_then_push reports a Navigator pop followed by a typed route push; router_direct_route_call reports injected router navigation; router_container_navigation_escape reports navigator GlobalKey currentContext; dialog_button_pop_then_state_mutation reports a second pop or typed push after a sheet or dialog pop. The skill's pop-with-result, typed route, showAppSheet helper and build_context_extensions.dart owner examples stay clean.
- [x] router_context_navigation_extension reports raw-location GoRouter navigation inside `extension on BuildContext`; GoRouterPopX stays clean.
- [x] router_redirect_loading_bounce resolves loading branches (if, switch case, switch expression) that return a '/' path or a typed route `.location`; negated and other-case branches stay clean.
- [x] router_shell_tab_push reports typed route push/go in shell tab-bar callbacks and the methods they reference.
- [x] avoid_route_param_throw_in_build reports direct throws in build and `firstWhere` without orElse.
- [x] New rules: test_notifier_override, test_e2e_blind_sleep, test_text_label_selector and notifier_timer_without_on_dispose, with registration counts and docs updated.
- [x] Every fix has the reported case plus negative controls in the existing suite, and a real consumer probe proves it.

## Baseline + execution

Result: Passed
Evidence: Pre-fix probe (probe-testing-navigation-contract/baseline.log, 216 issues) missed the reported cases: no test_notifier_override, test_e2e_blind_sleep, test_text_label_selector or notifier_timer_without_on_dispose; 1 avoid_route_param_throw_in_build, 1 router_redirect_loading_bounce and 1 router_shell_tab_push report; and false positives from modal_helper_requires_route_settings (3) and test_first_match_finder (3). Session baseline on the branch: full `dart test` passed 2,206 tests (1 skipped). The first Draft check failed on a 1,013-line test part and on cognitive complexity in _reportRedirectLoadingBounces (20) and _scanUndisposedNotifierTimers (19); both were repaired.
Execution: One builder repairs each existing rule with red-first tests, adds the four rules in the existing rule files, commits after each green step, then runs the consumer probe and the Hard Eng Draft check.

## Risks + recovery

router_redirect_loading_bounce depends on the loading state being an enum constant named `loading` or a bool named `isLoading`; that name dependency is an accepted, documented limit, and other loading names are not reported. test_notifier_override uses the test-file check, so integration_test/*_test.dart is included; the skill's E2E override in lib/main_dev.dart stays allowed. test_e2e_blind_sleep's dart:io `sleep` arm has no unit test because the mock SDK has no `sleep`; the probe's test_driver/sleep_driver.dart proves it. Recovery: revert the single rule commit; each rule is independent.

## ux_reference

N/A — analyzer diagnostics only; no app surface.

## Verification

Result: Passed
Evidence: `python3 .hooks/hard-eng.py check --base origin/main --plan-stage Draft` passed every gate: lockfile, vulnerabilities, format, types-lint, security, import boundaries, 2,206 tests (1 skipped) with 75.83% line coverage, dead-code-duplicates (Dart Decimate PASS), performance, secrets, actionlint and zizmor. `dart analyze` reports no issues. The diff was reviewed; CHANGELOG.md and the pubspec version are unchanged.
E2E: Passed — real consumer probe (probe-testing-navigation-contract, `dart analyze` > reanalyze.log, 241 issues) reports every reproduction as an error: router_context_navigation_extension in pop_or_go_path_x.dart; router_redirect_loading_bounce in bad_redirect.dart and bad_router.dart with app_redirect.dart clean; router_shell_tab_push in the inline, mixed and scaffold shells with the ok shell clean; 2 avoid_route_param_throw_in_build in product_missing_screen.dart; test_notifier_override in notifier_override_test.dart; test_e2e_blind_sleep for Future.delayed in integration_test/app_flow_test.dart and dart:io sleep in test_driver/sleep_driver.dart; test_text_label_selector on tester.tap(find.text('Save')) in label_tap_test.dart with its expect(find.text) control clean; notifier_timer_without_on_dispose in product_search_controller.dart with product_search_ok_controller.dart clean; #77 with appwrite 26.2.0: MockAccount and MockTablesDB report test_mock_concrete and the abstract Client mock stays clean. Against baseline.log, modal_helper_requires_route_settings drops 3→1 and test_first_match_finder 3→2, which are the intended helper-declaration and Iterable `.first` false-positive fixes. No testnav-owned code reports below error.
Delivery target: Merge
Delivery: Pending — scoped PR, required CI, merge and main CI.
