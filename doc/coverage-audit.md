# Coverage Audit

Status after the 2026-05-06 parity pass: the package now provides one public
analyzer plugin for the Flutter skill setup and owns the practical Dart-source
and installed-plugin config checks. The supplemental scanner has been narrowed
to bootstrap, agent-hook, and manual review catalog items outside the analysis
server boundary.

## Verified Inputs

- Flutter skill scanner:
  `building-flutter-apps/scripts/flutter_skill_scan.dart`
- Scanner fixture tests:
  `building-flutter-apps/test/flutter_skill_scan_test.dart`
- Current skill config:
  `building-flutter-apps/references/analysis_options.yaml`
- `many_lints` public package behavior used as inspiration/reference.

## Implemented Flutter Skill Rules

| Scope | Implemented rule |
| --- | --- |
| Riverpod async safety / `ref.mounted` after `await` | `use_ref_mounted_after_await` |
| `context.mounted` after `await` | `use_context_mounted_after_await` |
| No legacy Riverpod APIs | `avoid_legacy_riverpod_apis` |
| No `dynamic` except JSON maps | `avoid_dynamic_except_json_maps` |
| No null bang | `avoid_null_bang` |
| No `_buildXxx()` widget helpers | `avoid_widget_build_helpers` |
| No `shrinkWrap: true` | `avoid_shrink_wrap` |
| No unguarded `context.pop()` | `guard_context_pop` |
| No ignored `ref.refresh()` | `use_ref_invalidate` |
| No Freezed `abstract class` | `use_sealed_freezed_classes` |
| No widget build route-param throw | `avoid_route_param_throw_in_build` |
| No showcase key filtering | `avoid_showcase_key_filtering` |
| No silent mutation no-op before repository init | `avoid_silent_repository_null_return` |
| No sync `Notifier.build()` state read before initial state | `avoid_sync_notifier_state_read` |
| Flutter skill analyzer config, prohibited old/local lint plugin wiring, and `build.yaml` JSON settings | `flutter_skill_project_config` |
| Source checks inspired by the old supplemental scanner behavior | Exact diagnostic IDs such as `riverpod_read_init_state`, `router_string_nav`, `notifier_ensure_deps`, `data_log_rethrow`, and `test_provider_container` |

`flutter_skill_project_config` reports stale Flutter skill analyzer setup,
old lint plugin dependencies, local `git:`/`path:` plugin sources, and missing
`json_serializable` `explicit_to_json: true` through analyzer diagnostics
anchored to a Dart source file. This lets `flutter analyze` replace the scanner
for those installed-plugin config checks.

The scanner-migrated checks are registered as individual analyzer rules named
after their exact diagnostic IDs. They cover Riverpod init/watch/keepAlive and
service-locator checks, Freezed/model checks, architecture layer checks,
UI/style/performance/accessibility checks, notifier/router/showcase checks,
test hygiene checks, service/mixin/domain/data checks, and crash-reporting
checks.

The analyzer diagnostics use analyzer-friendly IDs, such as
`riverpod_read_init_state`. The supplemental scanner no longer publishes
Dart-source rule IDs; those checks are analyzer-owned.

## Implemented Additional Analyzer Coverage

The additional analyzer coverage is registered by `FlutterSkillLintsPlugin`.

- 80 additional warning rules registered by default.
- 61 quick fixes registered.
- 1 assist registered.
- Existing diagnostic IDs are preserved under the
  `flutter_skill_lints` plugin.

The current skill profile does not require app repos to carry a diagnostics
override block for off-profile additional rules. BLoC/Cubit-only, Equatable,
destructuring, and style-preference rules such as suffix, gap,
shorthand-expression, switch expression, and class-destructuring preferences are
excluded from the package source and default registration.

## Remaining Gaps

- Bootstrap checks: the analyzer cannot report a missing analyzer plugin before
  that plugin is installed and enabled.
- Agent hook freshness remains in hook/scanner tooling because analysis server
  diagnostics do not reliably own shell, TOML, JSON, or IDE hook files.
- Manual scanner review entries remain manual by design. The supplemental
  catalog currently contains 22 explicit manual review IDs for semantic checks
  that need architectural or runtime judgment.
- Analyzer compatibility rules are source-text/regex backed where AST matching
  is not practical, so they intentionally favor migration parity over precise
  semantic modeling.

## Testing Performed

- `dart format`: formatted the edited analyzer/scanner files.
- `dart analyze`: no issues.
- `dart test`: 106 passing tests, 1 gated integration test skipped by default.
- `RUN_FLUTTER_PLUGIN_SMOKE=1 dart test test/integration_plugin_smoke_test.dart --reporter expanded`: passed. The temp Flutter app loaded `flutter_skill_lints` and `riverpod_lint: 3.1.4-dev.3`, emitted `avoid_null_bang`, `avoid_ref_read_inside_build`, and `missing_provider_scope`, and did not emit `server.pluginError`.
- Flutter skill scanner/docs regression suite:
  `dart test/flutter_skill_scan_test.dart` passed from the skill repo.
- Scanner catalog count: 3 error rules, 0 warning rules, 22 manual review
  rules. The remaining scanner ERROR rules are `cfg.analysis_options`,
  `cfg.agent_hook_missing`, and `cfg.agent_hook_stale`; analyzer-backed
  Dart-source/config rules have been removed from the scanner catalog.
- `many_lints`-inspired reference inventory reviewed for compatible additional
  analyzer diagnostics.
- `pana --no-warning --exit-code-threshold 0 .`: 160/160.
- `dart pub publish --dry-run`: package validation completed. No
  dependency/path/custom-lint blocker was reported.
