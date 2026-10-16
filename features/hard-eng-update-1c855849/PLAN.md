# Hard Eng 1c855849 update

Status: Complete

## Outcome + scope

The repo runs Hard Eng `1c855849` installed by the supported updater, and the docs-only secret scan step in CI receives the GitHub token that the release's workflow template gives it. Out of scope: lint rules and their behavior, package version, dependency updates.

## Repository context

Owners: `.hooks/hard-eng-source.json` and the updater commit (installed revision); `.hooks/`, `.agents/skills/` and the Hard Eng block of `AGENTS.md` (scaffold); `.github/workflows/dart.yml` (CI invocation of the check). `dart.yml` is a custom workflow, so the updater cannot migrate it; the template's `GITHUB_TOKEN` line for the docs-only scan step is applied by hand.

## Decisions + authorization

Blockers: None
Handoff: Approval
Authority: Agent-loop under the owner's Hard Eng flow: `update-pr` opens and merges the prepared update once checks pass.

## Acceptance + steps

- [x] Installed revision is `1c855849` → `.hooks/hard-eng-source.json` shows `1c855849c99b3c3dc3a4fa3fab1f20d0ce0b3911` after the supported updater.
- [x] The docs-only scan step sets `GITHUB_TOKEN` → `dart.yml` matches the release template for that step.
- [x] Repository checks pass on the updated scaffold → `python3 .hooks/hard-eng.py check` exits 0.

## Baseline + execution

Result: Passed
Evidence: Starting revision `8fa34e6` (Hard Eng `a1ec36b5`); the updater verified and committed `1c855849` locally on the first run.
Execution: Single builder; scaffold-only update plus one workflow line.

## Risks + recovery

New gate rules could flag existing code; a workflow fault would fail CI before merge. Recovery = revert the PR.

## ux_reference

N/A — tooling only; no rendered interface changes.

## Verification

Result: Passed
Evidence: Full `python3 .hooks/hard-eng.py check` passed on `1c855849` (12 checks passed, 0 failed: lockfile, performance, actionlint, vulnerabilities, secrets-history, format, zizmor, secrets-files, security, types-lint, tests, dead-code-duplicates).
E2E: N/A — the package ships lint rules only; the native analyzer tests cover them.

Delivery target: Merge
Delivery: Pending — PR merged into main with the required `Run Dart Tests` check passing.
