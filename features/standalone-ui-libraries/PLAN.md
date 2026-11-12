# Standalone Material and Cupertino libraries

Status: Complete

## Outcome + scope

The rules recognise Material and Cupertino API from the standalone `material_ui` and `cupertino_ui` packages of Flutter 3.50 in the same way as from `package:flutter/`; an app that only moves its imports gets the same findings. Released as 0.13.7. Non-goals: rules about the core framework libraries (widgets, foundation, services, scheduler), new rules, and a check of the package names in `pubspec.yaml`.

## Repository context

Owners: `lib/src/additional_lints/type_checker.dart` (`TypeChecker`, which every `packageName: 'flutter'` checker uses, and the new `isFlutterUiLibraryUri`); the nine places below; `test/standalone_ui_libraries_test.dart`. Evidence: the official page on the move of the Material and Cupertino libraries names `package:material_ui/material_ui.dart` and `package:cupertino_ui/cupertino_ui.dart` as the new libraries; the API names are the same. In one app, only the import move gave 19 new `fire_and_forget_missing_catch` errors.
Same cause: N/A — no earlier fix of this cause; searched `lib/` for `package:flutter/`, `material.dart`, `cupertino.dart`, `src/material`, `src/cupertino` and `packageName: 'flutter'`. Changed: `TypeChecker._isFromPackage` (148 checkers, among them `Colors`, `CupertinoColors`, `IconButton` owners and `TextField`), `_flutterModalFunctions` use in `_isFailureRecordingCall` (`persistence_crash_source_rules.dart`), `_isFlutterModalLauncherWithoutRouteSettings` (`dialog_source_rules.dart`), the `iconSize` case of `_RawStyleTokenVisitor` (`ui_source_rules.dart`), `_isFlutterLibrary` for `_isAppWidget` (`riverpod_source_rules_part_02.dart`), `_isFlutterWidgetCallbackArgument` (`avoid_throw.dart`), `_isSliverExpression` (`use_sliver_prefix.dart`), `_isFlutterSliverExpression` (`prefer_sliver_prefix.dart`), `_isForbidden` (`avoid_flutter_host_driver_imports.dart`). Not changed, because the API lives in the core framework: `addPostFrameCallback` (scheduler), `FlutterError` and `debugPrint` (foundation) in `source_scanner_source.dart` and `data_crash_source_rules.dart`; `State` in `state_source_rules.dart`; `Navigator` and `NavigatorState` in `persistence_crash_source_rules.dart`; `RouteSettings` in `avoid_magic_literals.dart`; the widget preview and platform channel libraries in `widget_preview_rules.dart`; the `foundation.dart` import of `prefer_async_callback_fix.dart`; the `flutter` key of `pubspec_ordering.dart`.
Single source: `isFlutterUiLibraryUri` in `lib/src/additional_lints/type_checker.dart` is the one list of the three library prefixes; searched `lib/` for `startsWith('package:flutter/')` and for `material_ui` and `cupertino_ui`; the eight places that meant the wide framework use it and `TypeChecker` calls it for the name `flutter`; no second list is left.

## Decisions + authorization

Blockers: None
Handoff: Approval
Authority: Owner approved this change; plan and build authorized. Delivery target Merge: the coordinator reviews the commits, pushes, opens the PR and merges it with a rebase; the release job of the repository then tags and publishes 0.13.7.

## Acceptance + steps

- [x] The helper accepts the three prefixes and rejects look-alike packages such as `flutter_riverpod`, `material_ui_kit` and `my_app/material_ui` → N/A — the plan check matches quoted test names and reflective Dart tests have none; the proof is `test/standalone_ui_libraries_test.dart` `FlutterUiLibraryUriTest` cases `test_acceptsFrameworkAndStandalonePackages` and `test_rejectsLookalikePackages`.
- [x] `unawaited` of a Material or Cupertino modal function stays silent for both import forms, and an app function with the same name still reports → N/A — the plan check matches quoted test names and reflective Dart tests have none; the proof is `FireAndForgetModalStandaloneTest` cases `test_materialModalIsTrusted_frameworkImport`, `test_materialModalIsTrusted_standaloneImport`, `test_cupertinoModalIsTrusted_frameworkImport`, `test_cupertinoModalIsTrusted_standaloneImport`, `test_appModalLookalikeStillReports_frameworkImport` and `test_appModalLookalikeStillReports_standaloneImport`.
- [x] `modal_helper_requires_route_settings` reports the same call for both import forms and stays silent with `routeSettings` → N/A — same reason; the proof is `ModalRouteSettingsStandaloneTest` cases `test_reportsMaterialModal_*`, `test_reportsCupertinoModal_*` and `test_allowsModalWithRouteSettings_*`.
- [x] `style_raw_token` reports a raw `iconSize`, `Colors` and `CupertinoColors` for both import forms → N/A — same reason; the proof is `StyleRawTokenStandaloneTest` cases `test_reportsRawIconButtonSize_*`, `test_reportsRawMaterialColor_*` and `test_reportsRawCupertinoColor_*`.
- [x] `riverpod_watch_no_select` stays silent for a whole value into `MaterialApp` and still reports it into an app widget, for both import forms → N/A — same reason; the proof is `WatchIntoFrameworkWidgetStandaloneTest` cases `test_allowsWholeValueIntoMaterialApp_*` and `test_reportsWholeValueIntoAppWidget_*`.
- [x] `avoid_throw`, `use_sliver_prefix`, `prefer_sliver_prefix` and `avoid_flutter_host_driver_imports` report for both import forms → N/A — same reason; the proof is `AvoidThrowModalBuilderStandaloneTest`, `UseSliverPrefixStandaloneTest`, `PreferSliverPrefixStandaloneTest` and `HostDriverImportsStandaloneTest` in the same file.
- [x] Version 0.13.7 in `pubspec.yaml` and the first CHANGELOG entry → N/A — no test reads the version; the CI job Check Version Consistency compares the pubspec version with the first CHANGELOG heading.

## Baseline + execution

Result: Passed
Evidence: Starting commit `41f083a` (origin/main); `dart test` with the stand-in packages and the helper stubbed to the old prefix: 14 of the new tests failed (the standalone import cases and the helper test), the framework import cases passed.
Execution: One builder; tests first (red on the old prefix), then the helper at its owner and its eight callers, then version and changelog.

## Risks + recovery

A package named `material_ui` that is not the Flutter package would be taken for Flutter; the prefix needs the exact package name and the slash, and pub.dev names the Flutter packages. Recovery = revert the commit; the rules return to `package:flutter/` only.

## ux_reference

N/A — analyzer diagnostics have no visual interface.

## Verification

Result: Passed
Evidence: Red first: with the helper set to the old prefix, 14 tests of `test/standalone_ui_libraries_test.dart` failed, all for the standalone imports, and the 19 framework import cases passed. With the helper: the file passes (33 tests), the full `dart test` passes (2755 tests, exit 0), `dart analyze --fatal-infos` has no findings and `dart format` leaves no change, all with Dart 3.14.0. Limit: the stand-in packages model the move, not the real `material_ui` and `cupertino_ui` packages; no real app was analysed.
E2E: N/A — no user journey; the rule tests run the real analyzer on an in-memory project.
Retro: (1) A loop over two imports inside one test read stale results of the first analysis → None — a limit of the test harness; each import has its own test. (2) The stand-in modal functions with an empty body made `fire_and_forget_missing_catch` stay silent for both import forms, which hid the fault → None — the stand-ins now throw, like a callee that cannot be proved safe.

Delivery target: Merge
Delivery: Pending — coordinator pushes, opens the PR, merges and releases.
