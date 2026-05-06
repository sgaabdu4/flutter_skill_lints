# Changelog

## [0.1.1] - 2026-05-07

- Added `avoid_constant_switches`, a dead-logic warning for `switch`
  statements and expressions that switch on literals, const variables, or
  static const fields.
- Added automatic release tagging after successful `main` CI, followed by
  tag-based pub.dev publishing and GitHub Release creation.
- Split the migrated scanner surface into one registered analyzer rule per
  diagnostic ID, matching `many_lints`' specific rule-registration style.
- Re-ran the `many_lints 0.4.0` inventory audit and kept BLoC/Cubit,
  Equatable, `gap`, shorthand, switch-expression, and destructuring preference
  rules out of the default Flutter skill profile.

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
