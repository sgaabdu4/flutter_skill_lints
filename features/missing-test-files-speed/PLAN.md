# Fast avoid_missing_test_files

Status: Draft

## Outcome + scope

`avoid_missing_test_files` builds the set of package URIs that test files reach one time for each analysis session and package root, then answers each library with one set lookup; findings stay the same. Released as 0.13.6. Non-goals: other rules, new skips for generated files, a changed meaning of cover.

## Repository context

Owners: `lib/src/additional_lints/rules/avoid_missing_test_files.dart` (`_hasTestImportCoverage` lists and reads every test file, then walks lib imports from disk with a new seen set for each import); `test/additional_lints_dcm_worker_w_test_structure_test.dart` (`AvoidMissingTestFilesTest`); cache form `Expando` keyed on `AnalysisSession` as in `_mapperExtensionTargets` in `lib/src/rules/architecture_extended_source_rules.dart`. Evidence: one real project with 601 lib files, 261 test files and 397 libraries with no mirror test needed about 956,000 file reads (23.5 GB) in one analysis; this rule took 254 s while the 507 other rules took about 16 s together. The rule reaches the session through `RuleContext.libraryElement.session` (resolved context; the rule does not set `canUseParsedResult`).
Same cause: N/A — no other rule walks test files per library; searched `lib/` for `_dartFiles` and `readFileText` loops.

## Decisions + authorization

Blockers: None
Handoff: Approval
Authority: Owner approved this change; plan and build authorized. Delivery target PR; push, PR, tag and publish stay with the coordinator.

## Acceptance + steps

- [ ] Reads by the rule stay near the test file count plus the lib file count, not their product → `test/performance/avoid_missing_test_files_reads_test.dart::reads each file a bounded number of times` fails on the old code and passes on the new.
- [ ] A change of files between analyses is seen: finding, then none after a covering test is added, then the finding again after it is removed → `AvoidMissingTestFilesTest::test_cacheFollowsFileChanges`.
- [ ] Meaning is unchanged: direct import, relative import from a nested test, cover through export, import cycle, other package import, readable file edge, missing file behind an edge → named `AvoidMissingTestFilesTest` cases; all present cases pass unchanged.
- [ ] Version 0.13.6 in `pubspec.yaml` and the first CHANGELOG entry.
- [ ] Full gate passes → `python3 .hooks/hard-eng.py check --plan-stage Complete` exits 0.

## Baseline + execution

Result: Pending
Evidence: Pending — Draft check on the starting commit.
Execution: One builder; tests first (red on old code), then the cached set at its owner, then version and changelog.

## Risks + recovery

A stale set in a long-lived server: the cache lives on the `AnalysisSession`, which ends when a file changes, and is keyed by package root inside it. Recovery = revert the commit; the rule returns to the per-library walk.

## ux_reference

N/A — analyzer diagnostics have no visual interface.

## Verification

Result: Pending
Evidence: Pending
E2E: N/A — no user journey; the rule tests run the real analyzer on an in-memory project.

Delivery target: PR
Delivery: Pending — coordinator pushes, opens the PR, merges and releases.
