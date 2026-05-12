# Changelog

## [0.5.5] - 2026-05-12

- Added `avoid_run_zoned_guarded` (AST rule) to flag `runZonedGuarded(...)`
  calls. Per Flutter 3.3+ guidance (docs.flutter.dev/testing/errors),
  replace with the three-hook pattern: `FlutterError.onError`,
  `PlatformDispatcher.instance.onError`, and
  `Isolate.current.addErrorListener`. `runZonedGuarded` misses
  platform-channel async errors. Catches direct calls and aliased
  `import 'dart:async' as a;` calls. Complements the existing
  `crash_run_zoned_guarded_legacy` scanner rule (which permits a "legacy"
  escape hatch); enable `avoid_run_zoned_guarded` for a hard ban.
- Registered a quick-fix that rewrites `runZonedGuarded(body, onError)`
  into the canonical three-hook scaffold + inlined body. The fix infers
  the reporter call from the original `onError` body (defaults to `print`
  when unknown). User customizes the reporter after applying.
- Added `require_main_error_hooks` rule. Any top-level function whose
  body calls `runApp(...)` must wire all three hooks. Covers `main()`
  AND bootstrap wrappers (e.g. `runRepem`, `bootstrap`, `mainCommon`).
  Escape hatch: add `// flutter_skill_lints:configure_error_hooks_elsewhere`
  inside the body to opt out when hooks live in an extracted helper.
- Bumped Flutter skill rule count to 110 and diagnostic count to 117.

## [0.5.4] - 2026-05-12

- Added `router_gorouter_of` to flag `GoRouter.of(context).{go,push,replace,
  pushReplacement,goNamed,pushNamed,replaceNamed}` calls. Typed routes
  (`const FooRoute(...).push<T>(context)` / `.go(context)`) are the SSOT
  for navigation — they survive route renames and stay refactor-safe.
- Added `router_untyped_navigator_push` to flag
  `Navigator.{push,pushReplacement,pushAndRemoveUntil}` (incl.
  `Navigator.of(context).…`) when paired with `MaterialPageRoute`,
  `CupertinoPageRoute`, or `PageRouteBuilder`. Use a typed `@TypedGoRoute`
  then `const FooRoute(...).push<T>(context)`.
- Bumped Flutter skill rule count to 108 and diagnostic count to 115.
- Refreshed README example, `doc/building-flutter-apps-lint-coverage.md`,
  and `references/common-patterns.md` Critical Rules + Navigation
  anti-pattern block.

## [0.5.3] - 2026-05-12

- Added `riverpod_feature_notifier_keepalive` to flag non-family feature
  presentation notifiers that auto-dispose without an explicit ephemeral-state
  rationale.
- Extended the gated plugin smoke to assert the new diagnostic in a temporary
  Flutter app loaded through the Dart analyzer plugin system.

## [0.5.2] - 2026-05-12

- Added `avoid_mounted_check_in_finally` to flag
  `if (!ref.mounted) return;` (and `context.mounted` / bare `mounted`)
  shapes inside `finally` blocks. `return;` in `finally` swallows
  in-flight exceptions from the `try` body. Ships a quick-fix that
  rewrites the early-return into an `if (mounted) { ... }` guard around
  the trailing statements.
- Bumped additional analyzer rule count to 81 and quick-fix count to 64.
- Refreshed README counts and `doc/building-flutter-apps-lint-coverage.md`
  to list the new rule.

## [0.5.1] - 2026-05-11

- Removed stale `flutter_skill_lints` version pins from README, example
  analysis options, and project-config test fixtures. The plugin block now
  matches the companion skill's unpinned `flutter_skill_lints` setup while
  keeping the documented `riverpod_lint` prerelease pin.
- Clarified that `dart analyze` is the analyzer/plugin gate and can report
  project-config drift through Dart analysis units, but does not replace
  `flutter pub get` or pub.dev package validation for complete `pubspec.yaml`
  checks.
- Refreshed coverage docs to the current registered surface: 105 Flutter-skill
  warning rules, 112 Flutter-skill diagnostic codes, 80 additional warning
  rules, 63 fixes, and 1 assist.
- Updated `flutter_skill_project_config` wording from validation language to
  drift-reporting language; behavior is unchanged.

## [0.5.0] - 2026-05-11

- Added `router_complex_extra` to flag GoRouter typed-route `$extra`,
  `GoRouterState.extra` reads, and direct `extra:` navigation payloads.
  Route state must survive serialization, redirects, reloads, and modal
  pops; pass stable IDs or configure an explicit `extraCodec` instead.
- Bumped Flutter skill warning rule count to 105 and diagnostic code
  count to 112, and refreshed README plus
  `doc/building-flutter-apps-lint-coverage.md` to list the new rule.

## [0.4.0] - 2026-05-10

- Added analyzer diagnostics for the remaining Dart-source drift checks:
  `riverpod_select_arrow_syntax`, `riverpod_mutation_experimental_warning`,
  `arch_repository_generated_extends`, `state_freezed_nullable_error`, and
  `crash_run_zoned_guarded_legacy`.
- Tightened `riverpod_keepalive_family` so codegen family providers with
  positional `Ref ref, value` parameters are reported, not only providers with
  `required` named parameters.
- Added `riverpod_auto_dispose_keepalive_dependencies` to flag computed
  auto-dispose providers whose same-file watched dependencies are all known
  `keepAlive`, matching the `building-flutter-apps` provider decision tree.
- Allowed documented `@Riverpod(keepAlive: true)` family workarounds for the
  open Riverpod TickerMode assertion issue `rrousselGit/riverpod#4709`.
- Added extra false-positive coverage for non-Riverpod `select` APIs,
  keep-alive providers without family arguments, generated notifier classes,
  Riverpod-generated provider classes named `*Repository`, Freezed DTOs with
  nullable error fields, non-notifier/qualified `Mutation<T>` usages,
  `Mutation<T>` declarations, and `runZonedGuarded` declarations/comments.
- Documented that non-Dart drift checks remain owned by `check_drift.sh`/CI
  because analyzer plugin diagnostics attach to Dart analysis units.

## [0.3.0] - 2026-05-10

- Expanded the Flutter skill analyzer surface with extended architecture,
  Freezed, routing, ShowcaseView, Flutter optimization, persistence, crash
  reporting, service, mixin, state, UI, and test diagnostics.
- Added `use_unawaited_for_fire_and_forget_futures` and broadened project
  configuration checks for analyzer plugins, strict analysis, generated-file
  excludes, Freezed annotation ignores, `explicit_to_json`, prohibited lint
  plugin dependencies, and deterministic Flutter Driver entrypoints.
- Tightened migrated `many_lints`-style coverage with additional false-positive
  tests, source scanner regression tests, and updated rule registration.
- Refreshed README rule counts, example configuration, and lint coverage
  documentation for the expanded diagnostic set.

## [0.2.0] - 2026-05-07

- Documentation pass: rewrote `README.md` for faster onboarding, added a Quick
  Start with copy-paste `analysis_options.yaml`, a tighter rule-group table,
  and a Troubleshooting section.
- Fixed the license badge link in the README.

## [0.1.1] - 2026-05-07

- Added `avoid_constant_switches`, a dead-logic warning for `switch`
  statements and expressions that switch on literals, const variables, or
  static const fields.
- Added automatic release tagging after successful `main` CI, followed by
  tag-based pub.dev publishing and GitHub Release creation.
- Split the migrated scanner surface into one registered analyzer rule per
  diagnostic ID, matching `many_lints`' specific rule-registration style.
- Re-ran the `many_lints 0.4.0` inventory audit, added the remaining allowed
  rules from `many_lints`, including `prefer_class_destructuring`, and kept the
  configured false-list diagnostics, including Cubit suffix checks, out of the
  default Flutter skill profile.

## [0.1.0] - 2026-05-06

- Initial analyzer plugin scaffold.
- Added Flutter skill rules for Riverpod async safety, mounted guards,
  legacy Riverpod APIs, dynamic/null-bang usage, widget helper methods,
  `shrinkWrap`, GoRouter pop guards, Freezed class shape, showcase key
  filtering, route-param throws, repository initialization, and synchronous
  notifier initialization.
- Added additional Dart/Flutter analyzer coverage inspired by `many_lints`: 79
  default warning rules, 61 fixes, and 1 assist.
- Added migrated Dart-source checks from the Flutter skill scanner.
- Added `flutter_skill_project_config` so stale analyzer configuration and
  `build.yaml` JSON settings report through analyzer diagnostics.
- Added a gated Flutter integration smoke with `riverpod_lint 3.1.4-dev.3`.
