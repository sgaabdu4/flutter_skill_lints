# Flutter Skill Lints CI and native agent migration

Status: Draft

## Outcome + scope

Run shared quality verification once and use pnpm while updating the released Claude/Codex scaffold. Preserve analyzer plugin smoke, lint semantics, protected checks, PANA compatibility and publishing. Product behavior and SDK choices remain unchanged.

## Repository context

Owners: `.github/workflows/dart.yml`, `.github/workflows/publish.yml`, `hard-eng.gates.json`, `README.md`, native agent settings and the supported updater.

## Decisions + authorization

Blockers: None
Handoff: Approval
Authority: Autonomous — the user authorized released-source migration, pnpm wherever supported, Claude/Codex-only tooling, one combined pull request per repository, review, checks and merge.

## Acceptance + steps

- [ ] Released scaffold at `d2085f745de39214aaaf6b34192378c9d1094a3d` → supported updater succeeds; repeat changes nothing; repository CLAUDE aliases and retired tooling are absent while unique guidance remains.
- [ ] One Run Dart Tests owner performs the full Hard Eng suite; existing protected check names report its actual result. → native gates and workflow checks pass with the original assertions.
- [ ] The real Flutter analyzer-server smoke, package publish dry run and existing PANA analyzer compatibility allowance remain. → existing native tests and configured checks pass.
- [ ] Actual verification and runner timing → retain measured commands/results; make no unsupported percentage claim.

## Baseline + execution

Result: Passed
Evidence: Starting `9e94a75715b02f518dc07252f54bab6c5c328663` completed [native CI](https://github.com/sgaabdu4/flutter_skill_lints/actions/runs/36106840823) successfully before migration; local updater candidate verification is pending the shared test slot.
Execution: One builder at existing owners, followed by diff review and the native candidate, Ready and shipping checks. Heavy suites run only in the coordinated slot.

## Risks + recovery

Preserve custom settings and instruction tails before retirement. Stop on a conflicting updater plan; recover a known migration change through Git without overwriting unrelated work. Retain existing publishing and product safety guards.

## ux_reference

N/A — agent configuration and CI only; no app interface or appearance changes.

## Verification

Result: Pending
Evidence: Native candidate and final verification have not run yet.
E2E: N/A — no product journey changes; supported updater behavior and actual hosted workflow results are the relevant proof.

Delivery target: Merge
Delivery: Pending — exact pull request checks, guarded merge and merged-main results remain required.
