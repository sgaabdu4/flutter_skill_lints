# Hard Eng docs-only CI steps

Status: Complete

## Outcome + scope

Bring `.github/workflows/hard-eng.yml` in line with the Hard Eng template. Docs-only changes then skip native tool setup and run only the secret scan, and full runs cache native tool downloads. Hard Eng setup stops warning "Docs-only CI steps not added: .github/workflows/hard-eng.yml is customised". Non-goals: the job timeout, which stays at 10 minutes (#17 raised it for this repo's test suite), and other workflows.

## Repository context

Owners: `.github/workflows/hard-eng.yml`. The workflow was generated before the template gained the tool cache step (hard-eng#93) and the docs-only `impact` step (hard-eng#133). It had no cache step, so `ci_setup.migrate_docs_path` treated it as customised and skipped the upgrade.

## Decisions + authorization

Blockers: None
Handoff: Approval
Authority: User asked to fix every item flagged after the 0.13.0 release chain, including the customised Hard Eng workflow warning.

## Acceptance + steps

- [x] Workflow matches the Hard Eng template except `timeout-minutes: 10` → `diff` against hard-eng `main` `.github/workflows/hard-eng.yml` shows only that line.
- [x] Impact detection classifies this change as not docs-only → `python3 .hooks/hard-eng.py impact --base origin/main` prints `docs_only=false`.
- [x] Full gate passes, including actionlint and zizmor → `python3 .hooks/hard-eng.py check --plan-stage Complete` exits 0.

## Baseline + execution

Result: Passed
Evidence: `python3 .hooks/hard-eng.py check --base origin/main --plan-stage Draft` on `fe96914` + this change → exit 0; 13/13 gates PASS.
Execution: One builder; copy the template steps.

## Risks + recovery

If the impact step misclassifies a code change as docs-only, CI would skip the gates. The step falls back to `docs_only=false` on error, and the classification logic is Hard Eng's, tested upstream. Recovery: revert this commit.

## ux_reference

N/A — CI workflow with no visual surface.

## Verification

Result: Passed
Evidence: `diff` against hard-eng `f0c5825` `.github/workflows/hard-eng.yml` → only `timeout-minutes` differs. `hard-eng.py impact --base origin/main` → `docs_only=false`. `ci_setup.migrate_docs_path` returns the workflow unchanged with no warning. `check --plan-stage Complete` → exit 0; 13/13 gates PASS, including actionlint and zizmor.
E2E: N/A — CI configuration; proof is the PR run's step outcomes.

Delivery target: Merge
Delivery: Pending — PR checks green with the full `Run required checks` step run and the docs-only scan skipped, merge to main, main CI green.
