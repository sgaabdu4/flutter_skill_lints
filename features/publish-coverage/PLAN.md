# Publish 0.15.1 with coverage before Dart Decimate

Status: Complete

## Outcome + scope

The tag publish job runs the tests with coverage before Dart Decimate, so the `max_crap` limit has coverage data, and the 0.15.0 changes ship as 0.15.1. Out of scope: package code, rules and other workflows.

## Repository context

Owners: `.github/workflows/publish.yml` (tag publish job), `pubspec.yaml` and `CHANGELOG.md` (version). Publish run 43988502191 for tag v0.15.0 stopped in "Run Dart Decimate" with "coverage data not found ... create coverage/lcov.info". The v0.15.0 tag is protected by a repository rule, so it cannot be deleted and made again.
Same cause: N/A — the `max_crap` limit is new in this release; `dart.yml` already builds coverage through the Hard Eng tests gate before Dart Decimate, so only the publish job lacked it.
Single source: N/A — no rule, value or type is copied by this change.

## Decisions + authorization

Blockers: None
Handoff: Approval
Authority: The owner asked for flutter_skill_lints to be fixed and released for the strict-rules effort (2026-11-15), and for releases of owned packages to go through their own PRs.

## Acceptance + steps

- [x] The publish job builds coverage before Dart Decimate -> `.github/workflows/publish.yml` runs `dart run coverage:test_with_coverage --branch-coverage` before `dart-decimate json .`.
- [x] The version is 0.15.1 and the changelog says 0.15.0 was not published -> `pubspec.yaml`, `CHANGELOG.md`; the publish job's version check compares them.

## Baseline + execution

Result: Passed
Evidence: On main e8722f72 the publish job failed with exit 2 in "Run Dart Decimate" (no coverage file).
Execution: One commit for the workflow order, one for the version.

## Risks + recovery

Risk: the tag publish job takes longer, because the tests now run with coverage. Recovery: revert this PR; the change has no package code.

## ux_reference

N/A — workflow and version change only; no rendered interface changes.

## Sources + coverage

Sources: N/A — the request is the only source.

## Verification

Result: Passed
Evidence: Local run in the publish order: `dart run coverage:test_with_coverage --branch-coverage` passed 3,450 tests and wrote `coverage/lcov.info`; then `dart-decimate json .` (0.0.75, the version the job resolved) gave verdict pass with 0 findings; `actionlint .github/workflows/publish.yml` reported no issues; `dart pub publish --dry-run` reported 0 warnings.
E2E: N/A — no user journey; the real publish runs on the release tag after merge.
Real service: N/A — pub.dev publish runs only on the tag after merge.
Retro: (1) the v0.15.0 publish stopped without coverage -> this plan's first Acceptance row; (2) the tag could not be made again -> None — the repository rule protects tags on purpose.

Delivery target: Merge
Delivery: Pending — PR merged into main, auto-tag v0.15.1, publish run, pub.dev shows 0.15.1.
