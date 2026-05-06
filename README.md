# flutter_skill_lints

[![pub package](https://img.shields.io/pub/v/flutter_skill_lints.svg)](https://pub.dev/packages/flutter_skill_lints)
[![license](https://img.shields.io/github/license/sgaabdu4/flutter_skill_lints.svg)](https://github.com/sgaabdu4/flutter_skill_lints/blob/main/LICENSE)

Analyzer plugin that turns the
[`building-flutter-apps`](https://skills.sh/sgaabdu4/building-flutter-apps/building-flutter-apps)
skill's architecture and code-quality rules into Dart analyzer diagnostics —
plus a curated `many_lints`-inspired surface — so feedback shows up in your
IDE, `dart analyze`, and `flutter analyze`.

Designed for Riverpod + codegen Flutter apps.

## Highlights

| Surface | Count |
| --- | ---: |
| Flutter skill warning rules | 66 |
| Additional Dart/Flutter warning rules | 85 |
| Quick fixes | 66 |
| Assists | 1 |

## Quick Start

1. Add the plugin to the top-level `plugins` section of
   `analysis_options.yaml` (it is **not** a `pubspec.yaml` dependency):

   ```yaml
   include: package:flutter_lints/flutter.yaml

   plugins:
     flutter_skill_lints:
       version: ^0.2.0
     riverpod_lint: 3.1.4-dev.3
   ```

2. Restart the Dart Analysis Server (most editors expose
   "Dart: Restart Analysis Server"; otherwise restart the IDE).

3. Run analysis:

   ```bash
   flutter analyze    # or: dart analyze
   flutter test       # or: dart test
   ```

### Optional: install the companion skill

If you use Claude Code or another agent runtime that consumes
[skills.sh](https://skills.sh) skills, install the matching agent guidance:

```bash
npx skills add https://github.com/sgaabdu4/building-flutter-apps \
  --skill building-flutter-apps
```

## Rules

### Flutter Skill Diagnostics

Encode the architectural rules from `building-flutter-apps`.

| Area | Diagnostic IDs |
| --- | --- |
| Async safety | `use_ref_mounted_after_await`, `use_context_mounted_after_await`, `async_context_mounted_style` |
| Riverpod | `avoid_legacy_riverpod_apis`, `riverpod_read_init_state`, `riverpod_service_locator`, `riverpod_watch_no_select`, `riverpod_keepalive_family`, `use_ref_invalidate` |
| Notifiers | `avoid_silent_repository_null_return`, `avoid_sync_notifier_state_read`, `notifier_ensure_deps`, `notifier_watch_method` |
| Freezed and serialization | `use_sealed_freezed_classes`, `freezed_per_class_explicit_to_json`, `freezed_to_json_with_from_json`, `freezed_legacy_when_map` |
| Architecture | `arch_domain_import`, `arch_domain_serialization`, `arch_interface_contract`, `arch_concrete_dependency`, `arch_datasource_try_catch`, `arch_widget_path`, `atomic_provider_access`, `typed_id_raw_id`, `records_map_return` |
| Navigation | `guard_context_pop`, `avoid_route_param_throw_in_build`, `router_string_nav`, `router_pop_then_push`, `router_redirect_watch`, `router_redirect_loading_bounce` |
| UI and accessibility | `avoid_widget_build_helpers`, `avoid_shrink_wrap`, `style_raw_token`, `style_raw_text_style`, `strings_hardcoded`, `ui_snackbar_boundary`, `a11y_text_scale_clamp` |
| Performance | `perf_build_work`, `perf_listview_children` |
| State | `state_raw_response`, `state_broad_invalidation` |
| ShowcaseView | `avoid_showcase_key_filtering`, `showcase_listen_manual_handle`, `showcase_prev_null_guard`, `showcase_default_scope`, `showcase_dispose_on_tap` |
| Services and mixins | `service_singleton`, `mixin_mixin_class`, `mixin_name_suffix`, `mixin_mutable_state`, `dart_static_namespace` |
| Data and crash reporting | `data_log_rethrow`, `crash_possible_pii` |
| Tests | `test_provider_container`, `test_uncontrolled_scope`, `test_create_container`, `test_mock_concrete`, `test_pump_and_settle`, `test_tap_at`, `test_inline_value_key`, `test_first_match_finder` |
| Project config | `flutter_skill_project_config` |

### Additional Analyzer Coverage

Adapted from `many_lints`, original diagnostic IDs preserved where applicable.
Covers:

- Listener and disposal mistakes.
- Constant conditions, duplicate cascades, contradictory expressions.
- Collection misuse and unrelated-type checks.
- Widget composition issues.
- Riverpod and hook-specific mistakes.
- Test matcher hygiene.
- Naming and modern Dart style checks.
- Class destructuring guidance, including `prefer_class_destructuring`.

Implementations live under
[`lib/src/additional_lints/rules`](lib/src/additional_lints/rules).

## Examples

Each snippet shows the minimum context for the diagnostic to fire.

```dart
// lib/features/counter/presentation/counter_notifier.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'counter_notifier.g.dart';

@riverpod
class CounterNotifier extends _$CounterNotifier {
  @override
  int build() => 0;

  Future<void> incrementLater() async {
    await Future<void>.delayed(Duration.zero);
    state = state + 1; // use_ref_mounted_after_await
  }
}
```

```dart
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

void openDetails(BuildContext context) {
  context.go('/details'); // router_string_nav
}
```

```dart
// lib/features/users/domain/user.dart
class User {
  const User({required this.userId, required this.orgId});

  final String userId; // typed_id_raw_id
  final String orgId;
}
```

## Configuration

Suppress a single diagnostic with a line comment:

```dart
final raw = response.body!; // ignore: avoid_null_bang
```

Or scope to a file:

```dart
// ignore_for_file: avoid_null_bang, avoid_shrink_wrap
```

To disable a rule project-wide, add it to `analysis_options.yaml`:

```yaml
analyzer:
  errors:
    avoid_shrink_wrap: ignore
```

## Troubleshooting

**Diagnostics don't appear.** Restart the Dart Analysis Server after editing
`analysis_options.yaml`. The plugin loads only at server start.

**Plugin fails to load.** Check that your project resolves the analyzer
versions listed under [Compatibility](#compatibility) — analyzer plugin APIs
are not stable across major versions.

**Conflict with `riverpod_lint`.** Both plugins are designed to coexist; pin
`riverpod_lint: 3.1.4-dev.3` to match the version we test against.

## Compatibility

Targets the analyzer 12 line. Verified against:

- `analysis_server_plugin 0.3.14`
- `analyzer 12.1.0`
- `analyzer_plugin 0.14.8`
- `riverpod_lint 3.1.4-dev.3`

Recheck before publishing a new release.

## Development

```bash
dart format .
dart analyze
dart test
```

Integration smoke test (creates a temporary Flutter app, gated):

```bash
RUN_FLUTTER_PLUGIN_SMOKE=1 dart test test/integration_plugin_smoke_test.dart \
  --reporter expanded
```

## Release

A version bump merged to `main` triggers the release workflow, which tags
`vX.Y.Z`. The tag workflow publishes to pub.dev and creates the GitHub Release.

## Attribution

Inspired by [`many_lints`](https://pub.dev/packages/many_lints). Portions of
the internal analyzer rule implementation are distributed under the MIT
license. See [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md).
