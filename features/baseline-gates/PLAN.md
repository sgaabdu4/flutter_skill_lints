# Repair the failing baseline gates

Status: Draft

## Outcome + scope

The zizmor, freshness and security gates pass on main again. Non-goals: editing the old regex findings, new rules, version bump.

## Repository context

Owners: `.github/workflows/dart.yml` and `publish.yml` (3 setup-dart pins), `pubspec.lock` (4 outdated direct dependencies), `hard-eng.debt.json` (old findings of the security gate, written by `python3 .hooks/hard-eng.py adopt`). Evidence: a full Complete check on main plus a feature change printed 3 failing gates: zizmor `ref-version-mismatch` for 3 pins whose comment says `# v1` while the pinned commit is tag `v1.8.1`; freshness lists analyzer 14.5.0 to 14.7.0, analysis_server_plugin 0.3.24 to 0.3.26, analyzer_plugin 0.14.18 to 0.14.20, analyzer_testing 0.4.3 to 0.4.5; security reports 205 findings of one rule, `regex-built-in-function-dart`.
Same cause: N/A — the three failures have different causes; each gate is repaired at its owner above.

## Decisions + authorization

Blockers: The security gate cannot take the 205 old regex findings as debt: `check` prints `HE-DEBT-SHRINK-ONLY: only the change that installs Hard Eng can add hard-eng.debt.json; repair the findings instead`. Decision needed: repair the 205 findings in code, or have the owner of Hard Eng allow a later debt record.
Handoff: Clarification
Authority: The coordinator asked for this repair as its own change before the feature change; plan and build authorized; no push, PR, tag or publish.

## Acceptance + steps

- [x] zizmor passes with the pinned commit unchanged → N/A — no test file covers workflow text; the zizmor gate reports 0 findings.
- [x] Direct dependencies are current → N/A — the freshness gate lists none outdated; the full test suite and `dart analyze --fatal-infos .` pass on the new versions after the fixture ignore lists name the renamed analyzer 14.7 diagnostics.
- [ ] The security gate passes with its old findings recorded and shrink-only → N/A — the security gate and HE-DEBT-SHRINK-ONLY check `hard-eng.debt.json`.

## Baseline + execution

Result: Passed
Evidence: `python3 .hooks/hard-eng.py check --plan-stage Draft` on main plus the feature change failed zizmor, freshness and security (same three gates); the starting tree is main at `84bb38a`.
Execution: One builder; workflow comments, then the dependency upgrade, then the debt record.

## Risks + recovery

A newer analyzer could change rule behavior; the full test suite and analyze run on it. Recovery = revert the commit.

## ux_reference

N/A — no visual surface.

## Verification

Result: Pending
Evidence: zizmor reports no findings; freshness passes; `dart test` passes (2,714 tests) and `dart analyze --fatal-infos .` reports no issues on analyzer 14.7.0; the security gate still reports 205 findings of one rule (see Blockers).
E2E: N/A — no user journey.

Delivery target: PR
Delivery: Pending — coordinator pushes and merges.
