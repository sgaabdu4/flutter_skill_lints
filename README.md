# flutter_skill_lints

[![pub package](https://img.shields.io/pub/v/flutter_skill_lints.svg)](https://pub.dev/packages/flutter_skill_lints)
[![license](https://img.shields.io/github/license/sgaabdu4/flutter_skill_lints.svg)](https://github.com/sgaabdu4/flutter_skill_lints/blob/main/LICENSE)

Analyzer plugin that turns the
[`building-flutter-apps`](https://skills.sh/sgaabdu4/building-flutter-apps/building-flutter-apps)
skill's architecture and code-quality rules into Dart analyzer diagnostics,
plus a curated `many_lints`-inspired surface, so feedback shows up in your
IDE, `dart analyze`, and full-project Flutter analyzer runs.

Designed for Riverpod + codegen Flutter apps.

> **Highly opinionated by design:** This plugin enforces the accompanying
> `building-flutter-apps` skill's preferred architecture and code style. Treat
> it as a project policy package, not a neutral Dart/Flutter lint preset.
> Until v1.0.0, assume every release may include breaking changes as the lint
> surface is refined.

## Highlights

| Surface | Count |
| --- | ---: |
| Flutter skill warning rules | 183 |
| Flutter skill diagnostic codes | 193 |
| Additional Dart/Flutter warning rules | 238 |
| Additional Dart/Flutter diagnostic codes | 279 |
| Total unique diagnostic codes | 469 |
| Quick fixes | 63 |
| Assists | 1 |

## Quick Start

1. Add the plugin to the top-level `plugins` section of
   `analysis_options.yaml` (it is **not** a `pubspec.yaml` dependency):

   ```yaml
   include: package:flutter_lints/flutter.yaml

   plugins:
     # Stable Riverpod lint pin verified for Riverpod 3.3-era lint coverage.
     # Re-check pub.dev before release when Riverpod or analyzer versions move.
     riverpod_lint: 3.1.4
     flutter_skill_lints:

   analyzer:
     exclude:
       - ".dart_tool/**"
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
       # Effective Dart Design additions not covered by flutter_lints.
       - always_declare_return_types
       - type_annotate_public_apis
       - avoid_positional_boolean_parameters
       - avoid_equals_and_hash_code_on_mutable_classes
       - avoid_private_typedef_functions
       - avoid_returning_this
       - avoid_setters_without_getters
       - prefer_mixin
       - use_to_and_as_if_applicable
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

Exact inventory lives in [doc/building-flutter-apps-lint-inventory.md](doc/building-flutter-apps-lint-inventory.md). Do not duplicate diagnostic-ID tables here.

| Surface | Source |
| --- | --- |
| Flutter skill diagnostics | `lib/src/rules/**` |
| Additional diagnostics | `lib/src/additional_lints/rules/**` |
| Counts + coverage summary | `doc/building-flutter-apps-lint-coverage.md` |
| Full IDs | `doc/building-flutter-apps-lint-inventory.md` |

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

Also flagged: raw string or named route calls (`router_string_nav`), direct
`GoRouter.of(context)` usage (`router_gorouter_of`), injected router/context
route calls that bypass generated helpers (`router_direct_route_call`), raw
router or route definitions outside the router boundary or shared test router
helper (`router_raw_route_definition`), and direct page-route `Navigator` APIs
(`router_untyped_navigator_push`). Fix by
calling generated typed route helpers:

```dart
ProductDetailRoute(id: id).go(context);
await ProductCreateRoute(parentId: id).push<void>(context);
```

```dart
import 'dart:async';
import 'package:flutter/widgets.dart';

Future<void> saveLater<T>() async {}

void buildButton(VoidCallback onPressed) {}

void build() {
  buildButton(() {
    saveLater<void>(); // use_unawaited_for_fire_and_forget_futures
  });

  buildButton(() {
    unawaited(saveLater<void>());
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
    datetime_now_requires_timezone_intent: ignore
```

## Troubleshooting

**Diagnostics don't appear.** Restart the Dart Analysis Server after editing
`analysis_options.yaml`. The plugin loads only at server start.

**Plugin fails to load.** Check that your project resolves the analyzer
versions listed under [Compatibility](#compatibility). Analyzer plugin APIs
are not stable across major versions.

**Conflict with `riverpod_lint`.** Both plugins are designed to coexist; pin
`riverpod_lint` to stable `3.1.4` to match the version we test against.

## Compatibility

Targets the analyzer 12 line. Verified against:

- `analysis_server_plugin 0.3.14`
- `analyzer 12.1.0`
- `analyzer_plugin 0.14.8`
- `riverpod_lint 3.1.4`

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
