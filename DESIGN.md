# Flutter Skill Lints Design

## Overview

Flutter Skill Lints is developer tooling with no visual application surface. Its user-facing output is analyzer diagnostics, quick fixes, assists, configuration examples, and package documentation.

## Components

- `lib/flutter_skill_lints.dart` exposes the package entry point.
- `lib/src/` owns plugin registration, diagnostics, fixes, assists, and rule implementations.
- `analysis_options.yaml` owns analysis of this package; `example/analysis_options.yaml` demonstrates consumer configuration.
- `test/` proves diagnostic locations, false-positive boundaries, fixes, assists, and plugin registration.
- `README.md` and `doc/` describe installation and the supported rule surface.

## Do's and Don'ts

Do keep diagnostics precise, fixes semantics-preserving, identifiers stable, and examples aligned with the published package. Do test both violations and important non-violations. Don't present repository or runtime checks as analyzer coverage, add framework-specific rules outside the documented profile, or silently enable opinionated style rules without an explicit contract.
