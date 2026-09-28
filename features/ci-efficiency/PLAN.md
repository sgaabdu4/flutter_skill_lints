# Flutter Skill Lints CI and native agent migration

Status: Complete

## Outcome + scope

Run shared quality verification once and use pnpm while updating the released Claude/Codex scaffold. Preserve analyzer plugin smoke, lint semantics, protected checks, PANA compatibility and publishing. Product behavior and SDK choices remain unchanged.

## Repository context

Owners: `.github/workflows/dart.yml`, `.github/workflows/publish.yml`, `hard-eng.gates.json`, `README.md`, native agent settings and the supported updater.

## Decisions + authorization

Blockers: None
Handoff: Approval
Authority: Autonomous — the user authorized released-source migration, pnpm wherever supported, Claude/Codex-only tooling, one combined pull request per repository, review, checks and merge.

## Acceptance + steps

- [x] Released scaffold at `d2085f745de39214aaaf6b34192378c9d1094a3d` → supported updater succeeds; repeat changes nothing; repository CLAUDE aliases and retired tooling are absent while unique guidance remains.
- [x] One Run Dart Tests owner performs the full Hard Eng suite; existing protected check names report its actual result. → native gates and workflow checks pass with the original assertions.
- [x] The real Flutter analyzer-server smoke, package publish dry run and existing PANA analyzer compatibility allowance remain. → existing native tests and configured checks pass.
- [x] Actual verification and runner timing → retain measured commands/results; make no unsupported percentage claim.

## Baseline + execution

Result: Passed
Evidence: Starting `9e94a75715b02f518dc07252f54bab6c5c328663` completed [native CI](https://github.com/sgaabdu4/flutter_skill_lints/actions/runs/36106840823) successfully before migration; the released updater also passed all 12 native candidate gates; see Verification.
Execution: One builder at existing owners, followed by independent diff review, native candidate and shipping checks. Heavy suites run only in the coordinated slot.

## Risks + recovery

Preserve custom settings and instruction tails before retirement. Stop on a conflicting updater plan; recover a known migration change through Git without overwriting unrelated work. Retain existing publishing and product safety guards.

## ux_reference

N/A — agent configuration and CI only; no app interface or appearance changes.

## Verification

Result: Passed
Evidence: Fresh released setup.sh/native updater completed at d2085f745de39214aaaf6b34192378c9d1094a3d and created the isolated update commit. All 12 native candidate checks passed, including 2,682 tests with branch coverage (31.356s), the whole-package fatal-info analyzer (4.386s), unfiltered Dart Decimate (2.662s), performance (0.879s), security and workflow checks. One opt-in real Flutter analyzer smoke is retained in its separate required hosted job. Repeat updater exited 0 with no changed files or duplicate commit. Independent review found the required installed-skill lint-name compatibility assertion needs the full non-docs native check even for scaffold-only updates; that owner intentionally omits --base while docs-only secret checks remain. Actionlint and workflow structure checks passed after this correction. The final native pre-push checks and exact hosted results remain delivery proof. Starting Dart CI used 556 runner seconds plus 245 seconds for the duplicate Hard Eng workflow; no new hosted speedup claim is made before delivery.
E2E: N/A — no product journey changes; supported updater behavior and actual hosted workflow results are the relevant proof.

Delivery target: Merge
Delivery: Pending — exact pull request checks, guarded merge and merged-main results remain required.
