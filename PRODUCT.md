# Flutter Skill Lints

## Users

Dart and Flutter teams that use the `building-flutter-apps` guidance and want its safety and maintainability rules reported by the Dart analyzer.

## Problem

The standard Dart and Flutter lint sets do not cover every project rule in the companion guidance, and prose-only guidance can drift or be missed during implementation.

## Product Purpose

Provide an analyzer plugin with focused diagnostics, quick fixes, and assists for the reusable Flutter and Riverpod guardrails documented in this repository. The public setup and supported rule surface are described in [README.md](README.md).

## Boundaries

This package performs static analysis. It does not change application runtime behavior, replace tests or device verification, or claim coverage for rules that require build, shell, repository-history, or live-service evidence. Rules that are intentionally unsupported remain documented rather than silently approximated.

## Success

Supported violations are reported through normal Dart analyzer tooling with stable diagnostic identifiers, useful locations, and verified fixes where a safe mechanical correction exists.

## Evidence

The plugin registration under `lib/`, the rule tests under `test/`, and the coverage audits under `doc/` are the canonical evidence for shipped behavior.

## Unknowns

New Dart, Flutter, analyzer, and Riverpod releases can introduce syntax or APIs that require compatibility review before the package claims support.
