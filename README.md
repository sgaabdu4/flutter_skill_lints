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
- 16 Flutter skill rules, including project config and scanner compatibility
  rules.

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
| `flutter_skill_scanner_compat` | Migrated Dart-source scanner checks with analyzer diagnostic IDs |

## Version Line

This release supports the analyzer 12 line so it can co-resolve with
`riverpod_lint: 3.1.4-dev.3`. Current verified resolution is
`analysis_server_plugin 0.3.14`, `analyzer 12.1.0`, and
`analyzer_plugin 0.14.8`. Recheck `riverpod_lint`,
`analysis_server_plugin`, `analyzer`, and `analyzer_plugin` before publishing.

## Release

After merging a version bump to `main`, push the matching tag:

```bash
git tag v0.1.1
git push origin v0.1.1
```

The tag workflow verifies the package, publishes it to pub.dev, and creates the
matching GitHub Release after publishing succeeds.

## Attribution

Inspired by `many_lints`. See `THIRD_PARTY_NOTICES.md` for license notices.
