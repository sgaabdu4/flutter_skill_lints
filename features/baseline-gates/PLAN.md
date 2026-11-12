# Repair the failing baseline gates

Status: Draft

## Outcome + scope

The zizmor, freshness and security gates pass on main again. Non-goals: editing the old regex findings, new rules, version bump.

## Repository context

Owners: `.github/workflows/dart.yml` and `publish.yml` (3 setup-dart pins), `pubspec.lock` (4 outdated direct dependencies), `hard-eng.debt.json` (old findings of the security gate, written by `python3 .hooks/hard-eng.py adopt`). Evidence: a full Complete check on main plus a feature change printed 3 failing gates: zizmor `ref-version-mismatch` for 3 pins whose comment says `# v1` while the pinned commit is tag `v1.8.1`; freshness lists analyzer 14.5.0 to 14.7.0, analysis_server_plugin 0.3.24 to 0.3.26, analyzer_plugin 0.14.18 to 0.14.20, analyzer_testing 0.4.3 to 0.4.5; security reports 205 findings of one rule, `regex-built-in-function-dart`.
Same cause: N/A — the three failures have different causes; each gate is repaired at its owner above.

## Decisions + authorization

Blockers: None
Handoff: Approval
Authority: The coordinator asked for this repair as its own change before the feature change; plan and build authorized; no push, PR, tag or publish.

## Acceptance + steps

- [ ] zizmor passes with the pinned commit unchanged → N/A — no test file covers workflow text; the zizmor gate reports 0 findings.
- [ ] Direct dependencies are current → N/A — the freshness gate lists none outdated; the full test suite and `dart analyze --fatal-infos .` pass on the new versions.
- [ ] The security gate passes with its old findings recorded and shrink-only → N/A — the security gate and HE-DEBT-SHRINK-ONLY check `hard-eng.debt.json`.

## Baseline + execution

Result: Pending
Evidence: Pending
Execution: One builder; workflow comments, then the dependency upgrade, then the debt record.

## Risks + recovery

A newer analyzer could change rule behavior; the full test suite and analyze run on it. Recovery = revert the commit.

## ux_reference

N/A — no visual surface.

## Verification

Result: Pending
Evidence: Pending
E2E: N/A — no user journey.

Delivery target: PR
Delivery: Pending — coordinator pushes and merges.
