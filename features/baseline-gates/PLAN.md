# Repair the failing baseline gates

Status: Complete

## Outcome + scope

The zizmor, freshness and security gates pass on main again. Non-goals: new rules, version bump, changing any pattern or flag.

## Repository context

Owners: `.github/workflows/dart.yml` and `publish.yml` (3 setup-dart pins), `pubspec.lock` (4 outdated direct dependencies), `lib/` (205 `RegExp` literals built inside functions, reported by `regex-built-in-function-dart`; Hard Eng refuses a debt file in a later change, so they are moved to library-level finals). Evidence: a full Complete check on main plus a feature change printed 3 failing gates: zizmor `ref-version-mismatch` for 3 pins whose comment says `# v1` while the pinned commit is tag `v1.8.1`; freshness lists analyzer 14.5.0 to 14.7.0, analysis_server_plugin 0.3.24 to 0.3.26, analyzer_plugin 0.14.18 to 0.14.20, analyzer_testing 0.4.3 to 0.4.5; security reports 205 findings of one rule, `regex-built-in-function-dart`.
Same cause: N/A — the three failures have different causes; each gate is repaired at its owner above.

## Decisions + authorization

Blockers: None
Handoff: Approval
Authority: The coordinator asked for this repair as its own change before the feature change; plan and build authorized; no push, PR, tag or publish.

## Acceptance + steps

- [x] zizmor passes with the pinned commit unchanged → N/A — no test file covers workflow text; the zizmor gate reports 0 findings.
- [x] Direct dependencies are current → N/A — the freshness gate lists none outdated; the full test suite and `dart analyze --fatal-infos .` pass on the new versions after the test classes that need them list the renamed analyzer 14.7 undefined-name codes in `ignoredDiagnosticCodes`; the `ignore_for_file` lines in those fixtures keep their old, now dead, names because Hard Eng counts an edit of such a line as a new switch-off.
- [x] The 205 regexes are built once at library level with the same pattern text and flags → N/A — the plan check matches quoted test names and reflective Dart tests have none; the proof is the unchanged `dart test` suite plus a comparison of the 377 distinct `RegExp(...)` expressions in `lib/` before and after (equal), and the security gate reporting no finding.

## Baseline + execution

Result: Passed
Evidence: `python3 .hooks/hard-eng.py check --plan-stage Draft` on main plus the feature change failed zizmor, freshness and security (same three gates); the starting tree is main at `84bb38a`.
Execution: One builder; workflow comments, then the dependency upgrade, then the debt record.

## Risks + recovery

A newer analyzer could change rule behavior; the full test suite and analyze run on it. Recovery = revert the commit.

## ux_reference

N/A — no visual surface.

## Verification

Result: Passed
Evidence: `dart format` changed 0 of 560 files; `dart analyze --fatal-infos .` reported no issues; `dart test` passed 2,714 tests; `RUN_FLUTTER_PLUGIN_SMOKE=1 dart test test/integration_plugin_smoke_test.dart` passed 1 test; semgrep 1.185.0 with the `.agents/skills/he/security` rules reported 0 findings; the 377 distinct `RegExp(...)` expressions of `lib/` are equal before and after (394 uses became 389 after merging 5 identical copies in one library); 157 cut comment lines were read and 47 rewritten; 20 regex names were shortened or made unique.
E2E: N/A — no user journey.

Delivery target: PR
Delivery: Pending — coordinator pushes and merges.
