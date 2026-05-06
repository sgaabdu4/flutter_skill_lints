# flutter_skill_lints

`flutter_skill_lints` is the companion analyzer plugin for the
[`building-flutter-apps`](https://skills.sh/sgaabdu4/building-flutter-apps/building-flutter-apps)
skill. It is a new project inspired by `many_lints` and exposes Flutter skill
diagnostics through one public plugin.

Install the skill for agent guidance:

```bash
npx skills add https://github.com/sgaabdu4/building-flutter-apps --skill building-flutter-apps
```

## Install

Add the analyzer plugin to the top-level `plugins` section in
`analysis_options.yaml`:

```yaml
plugins:
  flutter_skill_lints:
    version: ^0.1.1
  riverpod_lint: 3.1.4-dev.3
```

Analyzer plugins are not added to `pubspec.yaml`. After changing the `plugins`
section, restart the Dart Analysis Server so IDE diagnostics pick up the new
plugin configuration.

## Rule Surface

The plugin registers:

- 80 additional Dart/Flutter warning rules, 61 fixes, and 1 assist.
- 66 Flutter skill rules, including project config and scanner-migrated checks
  registered under their exact diagnostic IDs.

Additional rule diagnostic IDs are preserved for compatibility with existing
`analysis_options.yaml` files. Off-profile BLoC/Cubit, Equatable, destructuring,
style-preference rules are not shipped in the default package surface, so app
repos do not need a diagnostics override block for the Flutter skill profile.

## Flutter Skill Rules

| Rule | What it catches |
| --- | --- |
| `use_ref_mounted_after_await` | `ref` or `state` use after `await` in Notifier methods without `if (!ref.mounted) return;` |
| `use_context_mounted_after_await` | `context` use after `await` without `if (!context.mounted) return;` |
| `avoid_legacy_riverpod_apis` | Legacy Riverpod provider/ref APIs instead of codegen/unified `Ref` |
| `avoid_dynamic_except_json_maps` | `dynamic` outside `Map<String, dynamic>` JSON boundaries |
| `avoid_null_bang` | Null assertion expressions |
| `avoid_widget_build_helpers` | Private `_buildXxx()` widget helper methods |
| `avoid_shrink_wrap` | `shrinkWrap: true` |
| `guard_context_pop` | `context.pop()` without a nearby `context.canPop()` guard |
| `use_ref_invalidate` | Ignored `ref.refresh(...)` return values |
| `use_sealed_freezed_classes` | `@freezed abstract class` declarations |
| `avoid_route_param_throw_in_build` | `firstWhere(... orElse: () => throw ...)` inside widget `build()` |
| `avoid_showcase_key_filtering` | `startShowCase()` calls that filter keys by `currentContext` |
| `avoid_silent_repository_null_return` | Mutation methods that return early when a repo field is null |
| `avoid_sync_notifier_state_read` | Sync `Notifier.build()` state reads or immediate loading/listening work |
| `flutter_skill_project_config` | Stale Flutter skill analyzer config and `build.yaml` JSON settings |
| `riverpod_read_init_state` | `ref.read` calls from `initState` |
| `riverpod_service_locator` | Service locator classes in Riverpod apps |
| `riverpod_watch_no_select` | Broad `ref.watch` calls without `select` |
| `riverpod_keepalive_family` | Keep-alive Riverpod family providers |
| `dart_static_namespace` | Static-only classes with private constructors |
| `freezed_per_class_explicit_to_json` | Per-class `JsonSerializable(explicitToJson: true)` |
| `freezed_to_json_with_from_json` | `@Freezed(toJson: true)` on classes with `fromJson` |
| `freezed_legacy_when_map` | Legacy Freezed `when`/`maybeWhen`/`maybeMap` calls |
| `arch_domain_import` | Flutter or package imports from domain files |
| `arch_domain_serialization` | JSON serialization members in domain files |
| `arch_interface_contract` | Repository/datasource files without `I*` interfaces |
| `arch_concrete_dependency` | Concrete repository/datasource dependencies |
| `arch_datasource_try_catch` | `try` blocks in datasource files |
| `arch_widget_path` | Feature widgets outside `presentation/widgets` |
| `atomic_provider_access` | Provider access from atomic design widgets |
| `typed_id_raw_id` | Domain entities with multiple raw `String` ID fields |
| `records_map_return` | Non-data helpers returning `Map<String, dynamic>` tuples |
| `style_raw_token` | Raw spacing, radius, size, or color tokens |
| `style_raw_text_style` | Raw `TextStyle` construction |
| `strings_hardcoded` | Hardcoded UI strings |
| `ui_snackbar_boundary` | Direct snackbar dispatch from UI widgets |
| `a11y_text_scale_clamp` | App-level text scaling clamps |
| `perf_build_work` | Expensive sorting/filtering/formatting/regex work in `build()` |
| `perf_listview_children` | `ListView(children: ...)` instead of builder/sliver variants |
| `state_raw_response` | Raw JSON/response values stored in UI state |
| `state_broad_invalidation` | Broad invalidation before navigation-critical route changes |
| `async_context_mounted_style` | Widget `mounted` checks after async gaps instead of `context.mounted` |
| `router_string_nav` | String-based GoRouter navigation |
| `router_pop_then_push` | Synchronous `context.pop()` followed by push navigation |
| `router_redirect_watch` | `ref.watch` calls inside router redirects |
| `router_redirect_loading_bounce` | Redirects to loading routes while auth/router state loads |
| `showcase_listen_manual_handle` | `ref.listenManual` calls whose subscription handle is not stored |
| `showcase_prev_null_guard` | `prev != null` showcase replay guards |
| `showcase_default_scope` | Default `ShowcaseView.register()` scope registration |
| `showcase_dispose_on_tap` | `disposeOnTap: true` without nearby `onTargetClick` |
| `notifier_ensure_deps` | Notifier mutation methods that write before dependency initialization |
| `notifier_watch_method` | `ref.watch` calls inside Notifier methods |
| `service_singleton` | Singleton instance fields in services |
| `mixin_mixin_class` | `mixin class` declarations for capability mixins |
| `mixin_name_suffix` | Capability mixins without the `Mixin` suffix |
| `mixin_mutable_state` | Mutable fields inside mixins |
| `data_log_rethrow` | Log-and-rethrow patterns in data layers |
| `crash_possible_pii` | Possible PII values sent to crash reporting |
| `test_provider_container` | Direct `ProviderContainer` construction in tests |
| `test_uncontrolled_scope` | `ProviderScope` usage in tests |
| `test_create_container` | `createContainer` test helpers |
| `test_mock_concrete` | Mocks that implement concrete classes |
| `test_pump_and_settle` | `pumpAndSettle` calls without explicit timeout |
| `test_tap_at` | Coordinate-based test taps |
| `test_inline_value_key` | Inline `ValueKey` string literals outside key registries |
| `test_first_match_finder` | First-match widget finder usage in tests |

## Version Line

This release supports the analyzer 12 line so it can co-resolve with
`riverpod_lint: 3.1.4-dev.3`. Current verified resolution is
`analysis_server_plugin 0.3.14`, `analyzer 12.1.0`, and
`analyzer_plugin 0.14.8`. Recheck `riverpod_lint`,
`analysis_server_plugin`, `analyzer`, and `analyzer_plugin` before publishing.

## Release

After a version bump is merged to `main`, `Dart CI` verifies the package and
creates the matching `v0.1.1` tag automatically. That tag push triggers the
publish workflow, which publishes to pub.dev and creates the GitHub Release.

The auto-tag job requires a `RELEASE_TOKEN` repository secret with contents
read/write access. GitHub's default `GITHUB_TOKEN` can create tags, but those
tag pushes do not trigger the separate pub.dev publish workflow.

## Attribution

Inspired by `many_lints`. See `THIRD_PARTY_NOTICES.md` for license notices.
