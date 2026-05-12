# flutter_skill_lints

[![pub package](https://img.shields.io/pub/v/flutter_skill_lints.svg)](https://pub.dev/packages/flutter_skill_lints)
[![license](https://img.shields.io/github/license/sgaabdu4/flutter_skill_lints.svg)](https://github.com/sgaabdu4/flutter_skill_lints/blob/main/LICENSE)

Analyzer plugin that turns the
[`building-flutter-apps`](https://skills.sh/sgaabdu4/building-flutter-apps/building-flutter-apps)
skill's architecture and code-quality rules into Dart analyzer diagnostics,
plus a curated `many_lints`-inspired surface, so feedback shows up in your
IDE, `dart analyze`, and full-project Flutter analyzer runs.

Designed for Riverpod + codegen Flutter apps.

## Highlights

| Surface | Count |
| --- | ---: |
| Flutter skill warning rules | 105 |
| Flutter skill diagnostic codes | 112 |
| Additional Dart/Flutter warning rules | 81 |
| Quick fixes | 64 |
| Assists | 1 |

## Quick Start

1. Add the plugin to the top-level `plugins` section of
   `analysis_options.yaml` (it is **not** a `pubspec.yaml` dependency):

   ```yaml
   include: package:flutter_lints/flutter.yaml

   plugins:
     flutter_skill_lints:
     # Pre-release pin: lift when riverpod_lint 3.2.0 stable lands.
     # Verify pub.dev before ship. Promote to latest stable when possible.
     # Pre-release silently adopts dev behavior - review.
     riverpod_lint: 3.1.4-dev.3

   analyzer:
     exclude:
       - "**/*.g.dart"
       - "**/*.freezed.dart"
       - "**/*.gr.dart"
       - "**/*.arb"
     language:
       strict-casts: true
       strict-inference: true
       strict-raw-types: true
     errors:
       missing_required_param: error
       missing_return: error
       invalid_annotation_target: ignore

   formatter:
     page_width: 100

   linter:
     rules:
       - always_use_package_imports
       - require_trailing_commas
       - prefer_single_quotes
       - directives_ordering
       - avoid_multiple_declarations_per_line
       - prefer_const_constructors
       - prefer_const_declarations
       - prefer_const_literals_to_create_immutables
       - prefer_final_locals
       - avoid_redundant_argument_values
       - avoid_dynamic_calls
       - avoid_print
       - avoid_void_async
       - cancel_subscriptions
       - close_sinks
       - discarded_futures
       - unawaited_futures
   ```

2. Restart the Dart Analysis Server (most editors expose
   "Dart: Restart Analysis Server"; otherwise restart the IDE).

3. Run analysis:

   ```bash
   dart analyze       # CLI/CI gate; do not path-scope analysis
   dart test
   ```

   Full-project `flutter analyze` can be useful locally, but the
   `building-flutter-apps` skill uses `dart analyze` for CLI/CI because
   path-scoped Flutter analysis can drop plugin diagnostics.
   `flutter_skill_lints` can read project files and report configuration drift
   through Dart-analysis diagnostics, but it does not replace `flutter pub get`
   or pub.dev publish validation.

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
| Async safety | `use_ref_mounted_after_await`, `use_context_mounted_after_await`, `use_unawaited_for_fire_and_forget_futures`, `async_context_mounted_style` |
| Riverpod | `avoid_legacy_riverpod_apis`, `riverpod_read_init_state`, `riverpod_service_locator`, `riverpod_watch_no_select`, `riverpod_select_arrow_syntax`, `riverpod_mutation_experimental_warning`, `riverpod_auto_dispose_keepalive_dependencies`, `riverpod_feature_notifier_keepalive`, `riverpod_keepalive_family`, `use_ref_invalidate` |
| Notifiers | `avoid_silent_repository_null_return`, `avoid_sync_notifier_state_read`, `notifier_ensure_deps`, `notifier_watch_method` |
| Freezed and serialization | `use_sealed_freezed_classes`, `freezed_per_class_explicit_to_json`, `freezed_to_json_with_from_json`, `freezed_legacy_when_map` |
| Architecture | `arch_domain_import`, `arch_domain_serialization`, `arch_interface_contract`, `arch_repository_generated_extends`, `arch_concrete_dependency`, `arch_datasource_try_catch`, `arch_widget_path`, `atomic_provider_access`, `typed_id_raw_id`, `records_map_return`, `avoid_object_map_cast` |
| Navigation | `guard_context_pop`, `avoid_route_param_throw_in_build`, `router_string_nav`, `router_gorouter_of`, `router_untyped_navigator_push`, `router_pop_then_push`, `router_redirect_watch`, `router_redirect_loading_bounce`, `router_complex_extra` |
| UI and accessibility | `avoid_widget_build_helpers`, `avoid_shrink_wrap`, `avoid_private_widget_classes`, `style_raw_token`, `style_raw_text_style`, `strings_hardcoded`, `ui_snackbar_boundary`, `a11y_text_scale_clamp` |
| Performance | `perf_build_work`, `perf_listview_children` |
| State | `state_raw_response`, `state_raw_error_to_string`, `state_freezed_nullable_error`, `state_broad_invalidation` |
| ShowcaseView | `avoid_showcase_key_filtering`, `showcase_listen_manual_handle`, `showcase_prev_null_guard`, `showcase_default_scope`, `showcase_dispose_on_tap` |
| Services and mixins | `service_singleton`, `mixin_mixin_class`, `mixin_name_suffix`, `mixin_mutable_state`, `dart_static_namespace` |
| Data and crash reporting | `data_log_rethrow`, `crash_possible_pii`, `crash_run_zoned_guarded_legacy`, `avoid_run_zoned_guarded`, `require_main_error_hooks` |
| Tests | `test_provider_container`, `test_uncontrolled_scope`, `test_create_container`, `test_mock_concrete`, `test_pump_and_settle`, `test_tap_at`, `test_inline_value_key`, `test_first_match_finder` |
| Project config | `flutter_skill_project_config` |
| Extended architecture and Freezed | `arch_model_missing_to_entity`, `arch_model_extends_entity`, `arch_domain_json_annotation`, `freezed_missing_private_constructor` |
| Extended navigation and ShowcaseView | `router_impure_redirect`, `router_shell_tab_push`, `showcase_v4_api`, `showcase_get_named_unhandled`, `showcase_scope_string_literal` |
| Extended Flutter optimization | `flutter_key_created_in_build`, `flutter_unique_or_global_key`, `flutter_opacity_widget`, `flutter_save_layer_filter`, `flutter_clip_save_layer`, `flutter_intrinsic_layout`, `flutter_animated_builder_child`, `flutter_widget_operator_equals` |
| Hive, Crash, and services | `hive_reserved_type_ids_missing`, `hive_duplicate_type_id`, `hive_duplicate_field_id`, `hive_test_close_missing`, `crash_direct_firebase_call`, `crash_init_before_run_app`, `fire_and_forget_missing_catch`, `service_static_side_effect`, `service_random_per_call`, `fire_forget_in_tests` |

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

Also flagged: `GoRouter.of(context).push|go|pushNamed|...` (`router_gorouter_of`) and `Navigator.of(context).push(MaterialPageRoute(...))` / `CupertinoPageRoute` / `PageRouteBuilder` (`router_untyped_navigator_push`). Fix in all three cases:

```dart
const DetailRoute().go(context);
const DetailRoute().push<void>(context);
```

```dart
import 'dart:async';
import 'package:flutter/widgets.dart';

Future<void> showDialogBottomSheet<T>() async {}

void buildButton(VoidCallback onPressed) {}

void build() {
  buildButton(() {
    showDialogBottomSheet<void>(); // use_unawaited_for_fire_and_forget_futures
  });

  buildButton(() {
    unawaited(showDialogBottomSheet<void>());
  });
}

Future<void> precacheCachedNetworkImages(
  Iterable<ImageProvider<Object>> images,
  BuildContext context,
) async {
  await Future.wait([
    for (final image in images) precacheImage(image, context),
  ]);
}

void setupImages(
  Iterable<ImageProvider<Object>> images,
  BuildContext context,
) {
  unawaited(precacheCachedNetworkImages(images, context));
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
versions listed under [Compatibility](#compatibility). Analyzer plugin APIs
are not stable across major versions.

**Conflict with `riverpod_lint`.** Both plugins are designed to coexist; pin
`riverpod_lint` to prerelease `3.1.4-dev.3` to match the version we test
against.

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
