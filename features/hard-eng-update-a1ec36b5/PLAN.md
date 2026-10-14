# Hard Eng a1ec36b5 update

Status: Complete

## Outcome + scope

The repo runs Hard Eng `a1ec36b5` installed by the supported updater, and CI provisions Bun for the check as this release requires. Out of scope: lint rules and their behavior, package version, dependency updates.

## Repository context

Owners: `.hooks/hard-eng-source.json` and the updater commit (installed revision); `.hooks/`, `.agents/skills/` and the Hard Eng block of `AGENTS.md` (scaffold); `.github/workflows/dart.yml` (CI invocation of the check). The updater reported `dart.yml runs Hard Eng without setting up Bun`; `dart.yml` is a custom workflow, so the updater cannot migrate it and the template's Bun steps are applied by hand.

## Decisions + authorization

Blockers: None
Handoff: Approval
Authority: Agent-loop under the owner's Hard Eng flow: `update-pr` opens and merges the prepared update once checks pass.

## Acceptance + steps

- [x] Installed revision is `a1ec36b5` → `.hooks/hard-eng-source.json` shows `a1ec36b57391c0a46570c40f6e0466b77f4684e2` after the supported updater.
- [x] CI provisions Bun before the check → `dart.yml` uses `oven-sh/setup-bun` and the `bun x` mise launcher from the release's workflow template, without the pnpm bootstrap or tool cache.
- [x] Repository checks pass on the updated scaffold → `python3 .hooks/hard-eng.py check` exits 0.

## Baseline + execution

Result: Passed
Evidence: Starting revision `abe45ee` (Hard Eng `02f02959`); the updater verified and committed `a1ec36b5` locally on the first run.
Execution: Single builder; scaffold-only update plus the CI Bun migration.

## Risks + recovery

New gate rules could flag existing code; a Bun launcher fault would fail CI before merge. Recovery = revert the PR.

## ux_reference

N/A — tooling only; no rendered interface changes.

## Verification

Result: Passed
Evidence: Full `python3 .hooks/hard-eng.py check --plan-stage Ready` passed on `a1ec36b5` with the Bun workflow (12 checks passed, 0 failed: lockfile, performance, actionlint, secrets-history, vulnerabilities, format, secrets-files, zizmor, security, types-lint, tests, dead-code-duplicates).
E2E: N/A — the package ships lint rules only; the native analyzer tests cover them.

Delivery target: Merge
Delivery: Pending — PR merged into main with the required `Run Dart Tests` check passing.
