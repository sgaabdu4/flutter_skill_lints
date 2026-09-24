# Reactive lint contract repairs

Status: Complete

## Outcome + scope

Repair demonstrated false positives and false negatives in eight rule surfaces: stable Riverpod
service factory classification, whole-value Riverpod watch use, guarded atomic
async state transitions, SDK configuration-builder parameter mutation, two
named Appwrite SDK mock boundaries, resolved notifier dependency capture,
direct typed recoverable throw-expression boundaries, and actual Mocktail/Mockito assertion getters.
Preserve findings for stable infrastructure dependencies, leaf reads, unsafe
async transitions, mutation outside the documented SDK builder, and other
concrete mock contracts.

## Repository context

The baseline is flutter_skill_lints 0.12.13, commit
`2d7bc8071c17b81971fe0bbc61b91416c858ed0c`. The provider-factory check now
resolves the declared return type; the watch check recognizes full iteration
and resolved Riverpod `AsyncValue.when` dispatch; the atomic-update check is
limited to a mounted, revision-guarded loading-to-result transition and
exclusive terminal branches; the SDK mutation exemption is tied to the
resolved configuration-builder callback contract; Appwrite mock exceptions
are tied to exact defining URIs and class names; notifier dependency capture
is tied to resolved operations and guarded mutation boundaries.

## Decisions + authorization

Blockers: None
Authority: The user authorized genuine rule repairs, regression verification, and package release after review.

The task authorizes focused package fixes and synthetic proof. The coordinator
owns versioning, Git, and publication after verification. Preserve diagnostics
where intent is not proven; no name-only, path-only, or whole-index exemption.

## Acceptance + steps

- [x] A computed `List<ItemService>` projection is not misclassified from its
      element name, while generic, qualified, and actual `dart:async` service
      factory return types remain diagnosed. A user-defined `Future` name is
      not unwrapped.
- [x] Iterating a watched list and complete resolved Riverpod async-state
      dispatch are accepted; selecting one indexed list element and selecting
      a custom same-named `when` remain diagnosed.
- [x] A mounted and revision-guarded loading-to-result transition through a
      generated Freezed `copyWith` is accepted. Later awaits, repeated data
      fields, unrelated comparisons, late or mutable tokens, and local fake
      state remain diagnosed. Mutually exclusive terminal branches are
      analyzed without path enumeration.
- [x] Mutation within the resolved SDK configuration builder is accepted;
      rebinding the parameter, writing through a captured closure, and
      mutation outside the builder remain diagnosed.
- [x] Appwrite `Functions` and `Storage` mocks declared through the SDK's part
      library topology are accepted. Same-named local concrete classes still
      report, and same-named abstract interfaces remain accepted.
- [x] A synthetic consumer using resolved Appwrite 26.2.0 has no
      mock-boundary finding under the candidate plugin configuration.
- [x] A resolved final repository/service local returned by a synchronous
      helper, by the first awaited `dart:async` resource acquisition, or by a
      typed named record field is accepted only when that same value is used
      for a non-null resource operation. A nullable value must be promoted at
      the operation. Discarded results, mutable/late/dynamic locals, capture
      after an unrelated await, a second late acquisition, nullable or forced
      nullable use, fake `Ref.read`, unused record captures, and late getters
      remain diagnosed.
- [x] The real pinned Riverpod, generated Freezed, and SDK smoke replay passes
      with the exact expected diagnostics.
- [x] Whole-package strict analysis and Dart Decimate 0.0.48 pass.
- [x] Typed direct throw expressions remain allowed outside resolved presentation
      and notifier contexts; programmer errors, untyped throws, and unsafe UI
      callback throws retain diagnostics (25 focused tests and actual Flutter probe).
- [x] Actual Mocktail and Mockito verification getters count as assertions by
      resolved declaration identity; shadowed and unrelated getters remain
      diagnosed (35 focused tests and actual Mockito 5.8.1 consumer probe).
- [x] Native checks, including coverage and security, pass after the final review fixes and verified Hard Eng update.
- [x] Diagnostic changes in consumer replays are classified and preserve real findings.

## Baseline + execution

Result: Passed
Evidence: Published 0.12.13 reproduced the synthetic rule defects. The current
candidate passed `python3 .hooks/hard-eng.py check --plan-stage Draft` on Hard
Eng `34b0703cba2815c1696b5859d472f02d77f5f2db`: 2,144 tests passed with one
intentional skip; line coverage 12,783/16,920 (75.55%) and branch coverage
63.70% (informational). Strict analysis, format, security, dependency, boundary,
complexity, duplicate, performance, secret, workflow, and Decimate 0.0.48 checks
passed.
Execution: The builder owns resolved rule repairs and isolated consumer
replays. The coordinator reviews the diff, runs integrated native checks,
and owns publication. No private consumer identifiers or evidence are
included in the public payload.

## Risks + recovery

Keep semantic exemptions narrow and retain unsafe controls at the resolved
contract boundary. If the real integration replay or a retained unsafe control
fails, revise the relevant fix or leave the diagnostic in place. Do not claim
release readiness until all listed gates are complete.

## ux_reference

N/A — analyzer behavior and tests change; no product UI or user flow changes.

## Verification

Result: Passed
Evidence: The current candidate's full native Draft gate passed with 2,144 tests
and one intentional skip; line coverage is 75.55%, branch coverage 63.70%
(informational). Fatal-info analysis, formatting, security, and Dart Decimate
0.0.48 passed with zero findings. Actual Riverpod 3.4.3, generated Freezed 4.0.2,
Sentry 9.30.1, and Appwrite 26.2.0 probes passed with retained unsafe controls.
The #89 capture amendment passes 46 focused capture tests and 5 existing
notifier tests; direct typed throw coverage passes 25 tests. The supported
installer updated Hard Eng to verified revision
`34b0703cba2815c1696b5859d472f02d77f5f2db`. Across five held consumer
snapshots, `AVOID_THROW` counts changed by 0, -52, -31, -55, and 0, with no
candidate-only diagnostics. All 138 removed findings were direct typed throw
expressions at the approved boundaries. Snapshot sources remained byte
identical to the saved manifest (2,913 files per side). Publication remains a delivery step after local acceptance.
E2E: N/A — no product runtime UI changes; real analyzer-plugin execution is
covered by the SDK smoke and consumer diagnostic replays above.
Delivery target: Merge
Delivery: Pending — exact-revision required CI, main merge verification, and
published package verification remain required after local checks pass.


### Integrated review amendment (25 September)

The dependency-capture repair includes method-wide readiness checks: a safe try
body cannot hide unsafe repository reads afterward, in catch, or in finally.
All three regression controls reproduced before the fix. The 46 focused capture
tests and strict analysis pass. The narrowed typed-error rule covers direct
throw expressions only; it does not add method-based error/stack propagation
analysis. The current combined native gate and candidate-only `AVOID_THROW`
replay have passed; no publication has occurred.

### Coordinator acceptance

Reviewed the resolved API boundaries, retained unsafe controls, real SDK probes,
final native results and held-source diagnostic comparisons. All native gates
passed with 2,144 tests and one intentional skip at 75.55% line coverage. Five
unchanged consumer snapshots preserve all 2,913 source files on each side. The
final direct-throw comparison removes exactly 138 typed boundary findings and
adds none; method-based error propagation is unchanged from the published baseline.

Other reviewed deltas retain diagnostics for actual late dependency reads and
parameter mutation outside SDK builders. Added regression tests cover a safe try
block followed by unsafe reads, capture in catch/finally, shadowed declarations,
unrelated APIs, and assertion lookalikes. Public payload review found no private
consumer identifiers, paths or operational artifacts. Known separate rule gaps
remain tracked upstream; this release makes no claim to solve all analyzer cases.
