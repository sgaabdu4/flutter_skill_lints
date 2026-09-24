# Error-reporting and networking contract

Status: Complete

## Outcome + scope

Make the error-reporting and networking lints match `error-reporting.md`, `networking.md` and `common-patterns.md` rule 12. Raise the existing crash, Appwrite and destructive-failure rules to error. Add resolved rules for the Crash facade, Sentry ownership and options, single incident reporting, framework and dispatcher handlers, HTTP calls in widgets and notifiers, concrete datasource clients, null or empty network fallbacks, widget secrets, and raw HTTP failures in widgets and notifiers. Allow JSON-decoded map casts outside Hive.

## Repository context

Owners: `lib/src/rules/data_crash_source_rules.dart`, `lib/src/rules/hive_persistence_source_rules.dart` and `lib/src/rules/persistence_crash_source_rules.dart`. Tests are in `test/source_scanner_rules_test/source_scanner_rules_part_crash.dart` and `source_scanner_rules_part_network.dart` (split out of `source_scanner_rules_part_11.dart` to stay under the 1,000-line limit), `source_scanner_rules_part_13.dart` and `test/persistence_crash_source_rules_test.dart`. Registration counts are in `test/plugin_registration_test.dart`.

## Decisions + authorization

Blockers: None
Authority: Coordinator-assigned lint repair. Rows owned by other builders were skipped: `avoid_throw`, `arch_datasource_try_catch` and `prefer_compute_over_isolate_run`.
Decisions:
- `crash_custom_global_error_handler` exempts only a Crashlytics handler assigned inside the resolved `Crash` class that declares a static `init`. The file path does not matter. `lib/bootstrap.dart` and top-level helpers in `crash_service.dart` are reported.
- `network_http_call_in_widget_or_notifier` checks one hop only. It reports calls on a root-package class, or an interface implemented in that class's library, that directly holds an HTTP client field or constructor parameter. The skill's notifier → repository → datasource → `IHttpService` chain stays clean.
- `datasource_concrete_http_client` picks its classes by name: the class or one of its supertypes must end with `Datasource` or `DataSource`. This follows the skill's naming and the `arch_concrete_dependency` precedent. All type checks are resolved.
- `network_failure_null_fallback` reports only unconditional `return null` and empty-collection returns in catch blocks that are untyped, catch `Object`, `Exception` or `Error`, or catch a raw HTTP failure. A return behind a status check counts as a classified absence.
Heuristic limits: `crash_possible_pii` is a keyword heuristic, and `appwrite_blocking_function_execution_in_client` and `destructive_failure_logged_before_reconcile` are name heuristics. Only their severity changed.
Not covered, because it cannot be detected soundly: Sentry replay, performance and profile sampling, request bodies and headers, user identity, and base-URL constants in widget code. None of these can be told apart from ordinary values in source.
Other limits:
- `_reachesHttpClient` finds implementors only in the interface's own library and stops after four hops. As a result, `network_failure_null_fallback` covers datasource and repository catch blocks but not a notifier that wraps a repository call.
- `network_secret_in_widget` matches any widget string that starts with `Bearer ` or `Basic `.
- `network_raw_http_failure_in_widget_or_notifier` does not check `case DioException()` patterns.
- `crash_direct_sentry_call` and `crash_direct_firebase_call` still scope to `crash_service.dart` by path, as the skill text says.

## Acceptance + steps

- [x] Existing error-reporting, Appwrite and destructive-failure rules report at error severity.
- [x] Crash facade API, recursion, Sentry ownership, `sendDefaultPii`, capture opt-in and auth-token rules report violations and allow the skill facade.
- [x] Framework and dispatcher handlers are reported everywhere except for Crashlytics wiring inside `Crash`.
- [x] The five networking rules report the probe rows, and the skill's `IHttpService` datasource, repository chain, Hive recovery and typed-absence controls stay clean.
- [x] JSON-decoded map casts outside Hive stay clean.

## Baseline + execution

Result: Passed
Evidence: The baseline was 2,177 tests passed and 1 skipped. The audit recorded networking rows 9–11, 13, 14, 16 and 17 as silent gaps.
Current baseline: 2,197 tests passed and 1 skipped. Registration counts are 199 rules and 207 diagnostics.
Execution: Red test first for each rule, then the implementation and a full format, analyze and test run, with one commit per green step.

## Risks + recovery

Resolved HTTP-reach checks could spread to repositories. The one-hop limit in the widget and notifier rule, together with the repository-chain control tests, prevents this. If a false positive appears, disable only the specific rule in analysis_options.yaml. Every diagnostic is a separate code.

## ux_reference

N/A — analyzer diagnostics only; no app surface.

## Verification

Result: Passed
Evidence: `dart format lib test` made no changes. `dart analyze` reported no issues. `dart test` passed 2,197 tests with 1 skipped. Probe `probe-error-network-contract` (`dart analyze`) reported the new rules on `bootstrap.dart`, `crash_handlers_bad.dart`, `main_zone.dart`, `pd_concrete_remote_datasource.dart` (×2), `pd_null_fallback_repository.dart`, `pd_http_notifier.dart` (call and ×2 raw failure), `pd_wrapper_notifier.dart`, `pd_http_screen.dart`, `pd_http_widget.dart` and `pd_secret_widget.dart`. They stayed silent on `product_remote_datasource.dart`, `pd_classify_remote_datasource.dart`, `pd_catch_widget.dart`, `pd_repo_notifier.dart`, `core/network/http_service.dart`, `crash_service.dart` and `product_json_decoder.dart`. The Hard Eng Draft check passed every gate: lockfile, vulnerabilities, format, types-lint, security, import boundaries, tests, dead code and duplicates, performance, secrets and workflow checks.
E2E: Passed — a real consumer app (`probe-error-network-contract`) ran `dart analyze` against this worktree through the analyzer plugin.
Delivery target: Merge
Delivery: Pending — combined PR, required CI, merge and main CI.
