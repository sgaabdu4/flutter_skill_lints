# Coverage Audit

Status: 2026-08-15. The package provides one public analyzer plugin for the
Flutter skill setup and reports practical Dart-source and installed-plugin
project-config drift through diagnostics anchored to Dart analysis units. The
supplemental scanner has been narrowed to bootstrap, agent-hook, and runtime
proof records outside the analysis server boundary.

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
| `select()` callbacks use arrow syntax in Dart source | `riverpod_select_arrow_syntax` |
| `Mutation<T>` usage has nearby experimental context in Dart source | `riverpod_mutation_experimental_warning` |
| Computed auto-dispose providers whose watched dependencies are all known `keepAlive` become keepAlive too | `riverpod_auto_dispose_keepalive_dependencies` |
| Non-family feature presentation notifiers stay keepAlive unless documented as ephemeral | `riverpod_feature_notifier_keepalive` |
| No `dynamic` except JSON maps | `avoid_dynamic_except_json_maps` |
| No object-valued runtime map casts | `avoid_object_map_cast` |
| Repositories do not extend generated `_$*Repository` bases | `arch_repository_generated_extends` |
| No null bang | `avoid_null_bang` |
| No `_buildXxx()` widget helpers | `avoid_widget_build_helpers` |
| No private widget classes | `avoid_private_widget_classes` |
| No `shrinkWrap: true` | `avoid_shrink_wrap` |
| Typed fallback behavior for page pops | `guard_context_pop` |
| No ignored `ref.refresh()` | `use_ref_invalidate` |
| Intentional fire-and-forget Futures in void callbacks are marked; reusable utility contracts stay awaitable | `use_unawaited_for_fire_and_forget_futures` |
| No Freezed `abstract class` | `use_sealed_freezed_classes` |
| No manual `@immutable` value/state classes | `use_freezed_instead_of_immutable` |
| One Freezed declaration per Dart file | `freezed_one_class_per_file` |
| No widget build route-param throw | `avoid_route_param_throw_in_build` |
| No silent mutation no-op before repository init | `avoid_silent_repository_null_return` |
| No sync `Notifier.build()` state read before initial state | `avoid_sync_notifier_state_read` |
| No raw `e.toString()` state errors | `state_raw_error_to_string` |
| No boolean `"1"` / `"0"` string sentinels in state/selectors | `state_bool_string_sentinel` |
| No nullable `String? error` field in Freezed state | `state_freezed_nullable_error` |
| `runZonedGuarded` is forbidden for startup wiring | `avoid_run_zoned_guarded` |
| Flutter skill analyzer config, prohibited old/local lint plugin wiring, deterministic E2E entrypoint, and `build.yaml` JSON settings | `flutter_skill_project_config` reports project-config drift through a Dart analysis unit |
| Source checks inspired by the old supplemental scanner behavior | Exact diagnostic IDs such as `riverpod_read_init_state`, `router_string_nav`, `notifier_ensure_deps`, `data_log_rethrow`, and `test_provider_container` |

`flutter_skill_project_config` reads project files and reports stale Flutter
skill analyzer setup, old lint plugin dependencies, local `git:`/`path:` plugin
sources, missing `json_serializable` `explicit_to_json: true`, and missing
Flutter app `lib/main_dev.dart` driver entrypoints through analyzer diagnostics
anchored to Dart analysis units. This lets analyzer plugin diagnostics replace
the scanner for installed-plugin config drift that can be inferred from project
files. Use `dart analyze` for the CLI/CI gate; full-project `flutter analyze`
remains useful for local Flutter checks. This does not make `dart analyze` a
complete `pubspec.yaml` validator.

The former scanner checks are registered as individual analyzer rules named
after their exact diagnostic IDs. They cover Riverpod init/watch/keepAlive and
service-locator checks, Freezed/model checks, architecture layer checks,
UI/style/performance/accessibility checks, notifier/router checks,
test hygiene checks, service/mixin/domain/data checks, and crash-reporting
checks.

The analyzer diagnostics use analyzer-friendly IDs, such as
`riverpod_read_init_state`. The supplemental scanner no longer publishes
Dart-source rule IDs; those checks are analyzer-owned.

Non-Dart drift checks remain scanner/CI owned because the analyzer plugin can
only report diagnostics against Dart analysis units.

## Implemented Additional Analyzer Coverage

The additional analyzer coverage is registered by `FlutterSkillLintsPlugin`.

- 81 additional warning rules registered by default.
- 64 quick fixes registered.
- 1 assist registered.
- Existing diagnostic IDs are preserved under the
  `flutter_skill_lints` plugin.

The current skill profile ships the allowed `many_lints` surface and leaves out
the configured false-list diagnostics: BLoC/Cubit-only rules, `use_gap`, shorthand
preferences, `prefer_switch_expression`, and
`prefer_overriding_parent_equality`. It also leaves `prefer_contains` to
`package:flutter_lints/flutter.yaml`, and leaves
`avoid_public_notifier_properties` and `avoid_ref_inside_state_dispose` to
`riverpod_lint`. `prefer_class_destructuring` is included.

## Runtime And Bootstrap Boundaries

- Bootstrap checks: the analyzer cannot report a missing analyzer plugin before
  that plugin is installed and enabled.
- Agent hook freshness remains in hook/scanner tooling because analysis server
  diagnostics do not reliably own shell, TOML, JSON, or IDE hook files.
- Analyzer compatibility rules are source-text/regex backed where AST matching
  is not practical, so they intentionally favor scanner parity over precise
  semantic modeling.
- Runtime proof obligations from the Flutter skill remain recorded in
  `doc/building-flutter-apps-lint-coverage.md` because event sync,
  source-of-truth freshness, multi-actor E2E, CI symbol upload, and visual
  accessibility quality cannot be proven by a standalone Dart file diagnostic.

## Testing Performed

- `dart format`: formatted the edited analyzer/scanner files.
- `dart analyze`: no issues.
- `dart test`: 1748 passing tests, 1 gated integration test skipped by default.
- `RUN_FLUTTER_PLUGIN_SMOKE=1 dart test -t integration test/integration_plugin_smoke_test.dart`: passed. The temp Flutter app loaded `flutter_skill_lints` with stable `riverpod_lint 3.1.8`, emitted `avoid_null_bang`, `avoid_ref_read_inside_build`, and `missing_provider_scope`, and did not emit `server.pluginError`.
- Flutter skill scanner/docs regression suite:
  `dart test/flutter_skill_scan_test.dart` passed from the skill repo.
- Scanner catalog remains limited to bootstrap/agent-hook checks:
  `cfg.analysis_options`, `cfg.agent_hook_missing`, and
  `cfg.agent_hook_stale`; analyzer-backed Dart-source/config rules have been
  removed from the scanner catalog.
- `many_lints`-inspired reference inventory reviewed for compatible additional
  analyzer diagnostics; `prefer_contains` is left to `flutter_lints`, and
  `avoid_public_notifier_properties` / `avoid_ref_inside_state_dispose` are left
  to `riverpod_lint`.
- `pana --no-warning --exit-code-threshold 0 .`: 160/160.
- `dart pub publish --dry-run`: package validation completed. No
  dependency/path/custom-lint blocker was reported.
