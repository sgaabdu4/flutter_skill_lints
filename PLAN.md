# Dart 3.13 Tooling Support

Status: Ready

## Outcome + scope

Make Dart 3.13 the supported baseline across `building-flutter-apps`,
`flutter_skill_lints`, and `dart-decimate`. Add first-party enforcement of dot
shorthands wherever Dart has an unambiguous context type, document the new
language and Flutter baseline without generic release-note noise, and make the
Rust parser understand Dart 3.13 constructor syntax safely. Preserve unrelated
working-tree changes. Keep repository-owned and generated CI action pins on
their latest verified releases.

## Repository context

`building-flutter-apps` owns concise engineering guidance and already tests
Flutter `>=3.47.0`. `flutter_skill_lints` owns analyzer diagnostics and fixes;
its fresh Hard Eng installation previously passed the complete local gate.
`dart-decimate` owns Rust-native parsing and analysis but its pinned Dart grammar
predates Dart 3.13. SmartMum and Repem are validation consumers, not edit targets.

## Decisions + authorization

Blockers: None

Task mode: Autonomous. The user approved all audited work, requires Dart 3.13
instead of legacy compatibility, wants shorthand syntax wherever it is valid,
requires real-codebase validation against SmartMum and Repem, and requires a
before/after report. They later authorized version bumps, publication, and
pushes. Their application working trees must not be changed; use isolated
temporary copies for consumer validation.

## Acceptance + steps

- [x] Refresh reviewed upstream Flutter-skill metadata and update concise Dart
      3.13 and Flutter 3.47 guidance in `building-flutter-apps`.
- [x] Require Dart 3.13 in `flutter_skill_lints`, add a default
      `prefer_dot_shorthands` diagnostic and safe quick fix, and update the
      existing public documentation/configuration.
- [x] Cover enum/static values, constructors, static methods, typed arguments,
      returns, assignments, collections, chains, constants, imports/prefixes,
      ambiguous contexts, and already-short syntax without false positives.
- [x] Add Dart 3.13 concise-constructor parsing to `dart-decimate`, make
      compatibility rewriting ignore comments and every Dart string form, and
      exercise affected CLI analysis surfaces with a representative corpus.
- [x] Recognize Flutter 3.47 standalone UI packages and document the parser's
      native-versus-normalized compatibility boundary.
- [x] Evaluate the current `tree-sitter-dart` release and upgrade only if its
      verified syntax support and node shapes are better than the local bridge.
- [x] Run focused tests, every repository's full native gate, negative controls,
      and isolated SmartMum/Repem analysis without modifying either application.
- [x] Review the final diffs for unnecessary additions and report before/after,
      proof, edge cases, and remaining delivery work before any push.
- [ ] Update every GitHub Actions checkout pin to v7.0.1 and the generated Hard
      Eng pnpm setup pin to v2.1.0, then pass the protected-branch checks.

## Baseline + execution

Result: Passed
Evidence: Before feature edits, `python3 .hooks/hard-eng.py check --plan-stage
Draft` passed every configured gate with exit 0 on Dart 3.13.3 and Flutter
3.47.3. This includes the existing 1,749-test suite, analysis, formatting,
coverage, performance, import-boundary, dependency, security, secret, and
workflow checks.

One builder owns the shared working trees. Implement in dependency order:
`flutter_skill_lints`, `building-flutter-apps`, then `dart-decimate`; finish with
combined consumer validation against isolated application copies.

## Risks + recovery

The shorthand fix must rely on resolved analyzer context rather than text shape.
The Rust compatibility bridge must not rewrite comments, raw strings,
triple-quoted strings, interpolation, or unrelated identifiers. Existing dirty
trees belong to the user and are preserved. All edits remain inspectable and
uncommitted.

## ux_reference

N/A — this task changes analyzer diagnostics, parser behavior, tests, and technical guidance, not product UI.

## Verification

Result: Passed
Evidence: Dart analysis and 1,757 unit tests passed; the real Flutter analysis
server smoke loaded `flutter_skill_lints` and `riverpod_lint`; the
`building-flutter-apps` gate passed 28 drift fixtures, 13 rules, and 44 smoke
checks; its local compatibility fixture resolved analyzer 14.4 and built the
generator family; Dart Decimate passed formatting, strict Clippy, every Rust
test, and an exact Rust 1.90 minimum-version compile after its dependency
update. Isolated SmartMum and
Repem copies resolved the new stack with no plugin errors; SmartMum ran 510
tests with only two Git-metadata-dependent archive checks failing because the
copy excludes `.git`, while Repem passed all 2,601 tests. Neither real app tree
was modified. The post-release Hard Eng repair uses a measured 600-second
cold-CI budget, and the maintenance workflow was refactored to satisfy the
current actionlint/ShellCheck diagnostics without suppressions.

Delivery target: Merge
Delivery: In progress — flutter_skill_lints 0.11.0 is published; merge the
latest-action maintenance PR after its protected-branch checks pass.
