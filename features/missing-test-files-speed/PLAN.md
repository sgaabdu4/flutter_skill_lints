# Fast avoid_missing_test_files

Status: Complete

## Outcome + scope

`avoid_missing_test_files` builds the set of package URIs that test files reach one time for each analysis session and package root, then answers each library with one set lookup; findings stay the same. Released as 0.13.6. Non-goals: other rules, new skips for generated files, a changed meaning of cover.

## Repository context

Owners: `lib/src/additional_lints/rules/avoid_missing_test_files.dart` (`_hasTestImportCoverage` lists and reads every test file, then walks lib imports from disk with a new seen set for each import); `test/additional_lints_dcm_worker_w_test_structure_test.dart` (`AvoidMissingTestFilesTest`); cache form `Expando` keyed on `AnalysisSession` as in `_mapperExtensionTargets` in `lib/src/rules/architecture_extended_source_rules.dart`. Evidence: one real project with 601 lib files, 261 test files and 397 libraries with no mirror test needed about 956,000 file reads (23.5 GB) in one analysis; this rule took 254 s while the 507 other rules took about 16 s together. The rule reaches the session through `RuleContext.libraryElement.session`. `AnalysisRule.canUseParsedResult` is false by default (analyzer 14.5.0) and the rule keeps it; `analysis_server_plugin` builds a parsed context (whose `libraryElement` throws) only when every rule of the run allows it, so this rule gets a resolved context.
Same cause: N/A — searched `lib/` for `_dartFiles` and `readFileText`; the other users read `pubspec.yaml` once or scan the project for the one anchor file of a package, not once per library.
Single source: N/A — the change adds one session cache inside the one file that owns this rule and copies no constant, type or text; the search of `lib/` for a second walk of test imports (`_dartFiles`, `readFileText`) found none.

## Decisions + authorization

Blockers: None
Handoff: Approval
Authority: Owner approved this change; plan and build authorized. Delivery target Merge: the coordinator pushes, opens the PR and merges it with a rebase; the tag job of the repository then releases the version.

## Acceptance + steps

- [x] Reads by the rule stay near the test file count plus the lib file count, not their product → N/A — the plan check matches quoted test names and reflective Dart tests have none; the proof is `test/additional_lints_dcm_worker_w_test_structure_test.dart` `AvoidMissingTestFilesReadsTest.test_readsEachFileFewTimes` (in the rule's test file, which owns the analyzer test harness; `test/performance` holds only pure wall-time checks), failing on the old code and passing on the new.
- [x] A change of files between analyses is seen: finding, then none after a covering test is added, then the finding again after it is removed → N/A — the plan check matches quoted test names and reflective Dart tests have none; the proof is `test/additional_lints_dcm_worker_w_test_structure_test.dart` `AvoidMissingTestFilesTest.test_cacheFollowsFileChanges`.
- [x] Meaning is unchanged → N/A — the plan check matches quoted test names and reflective Dart tests have none; the proof is `test/additional_lints_dcm_worker_w_test_structure_test.dart` `AvoidMissingTestFilesTest` cases `test_relativeImportFromNestedTest_noLint`, `test_importCycleBetweenLibFiles_noLint`, `test_importCycleThatNeverReachesLibrary_lint`, `test_importOfOtherPackage_lint`, `test_reachedOnlyThroughReadableLibFile_noLint`, `test_behindMissingLibFile_lint`, plus `test_exportedByImportedBarrel_noLint`; all present cases pass unchanged.
- [x] Version 0.13.6 in `pubspec.yaml` and the first CHANGELOG entry → N/A — no test reads the version; the CI job Check Version Consistency compares the pubspec version with the first CHANGELOG heading.

## Baseline + execution

Result: Passed
Evidence: `python3 .hooks/hard-eng.py check --plan-stage Draft` on starting commit `84bb38a` (main, its CI passed) plus this plan → exit 0; secret scans pass, no package reads the change.
Execution: One builder; tests first (red on old code), then the cached set at its owner, then version and changelog.

## Risks + recovery

A stale set in a long-lived server: the cache lives on the `AnalysisSession`, which ends when a file changes, and is keyed by package root inside it. Recovery = revert the commit; the rule returns to the per-library walk.

## ux_reference

N/A — analyzer diagnostics have no visual interface.

## Verification

Result: Passed
Evidence: Red first: on the old rule `AvoidMissingTestFilesReadsTest::test_readsEachFileFewTimes` failed with 25,764 Dart file reads against a bound of 202 (41 test files, 50 lib files in one session). On the new rule it reads 182 package Dart files (one analyzer read of each file plus one rule read of each file; SDK files are not counted) and the 46 tests of the file pass. A root-only static key breaks `test_cacheFollowsFileChanges` and other cases. `dart analyze --fatal-infos .` → no issues. `test/plugin_registration_test.dart` passes. Limit: the 956,000 read and 254 s figures come from one real project and were not re-measured here.
E2E: N/A — no user journey; the rule tests run the real analyzer on an in-memory project.
Retro: (1) CI failed on a deprecated library in the new read-count test, because CI runs a newer Dart than the local one → None — an outside cause; the test now passes each member on by name and uses no deprecated library. (2) The ship check refused the merge stage, because this plan named PR as its delivery target → None — the plan now names Merge, and the ship check found it before the merge. (3) The first independent review found that five test base classes need analyzer 14.7 → None — a limit of the tests under an older analyzer, stated in the PR; the package code is not affected. (4) A builder made one commit that only recorded a plan result → None — the plan state is now set in a commit that changes code.

Delivery target: Merge
Delivery: Pending — coordinator pushes, opens the PR, merges and releases.
