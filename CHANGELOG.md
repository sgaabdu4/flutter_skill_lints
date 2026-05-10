# Changelog

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
