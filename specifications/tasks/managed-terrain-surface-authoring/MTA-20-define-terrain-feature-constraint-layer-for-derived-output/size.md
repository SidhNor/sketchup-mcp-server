# Size: MTA-20 Define Terrain Feature Constraint Layer For Derived Output

**Task ID**: `MTA-20`
**Title**: Define Terrain Feature Constraint Layer For Derived Output
**Status**: `calibrated`
**Created**: 2026-05-02
**Last Updated**: 2026-05-03

**Related Task**: [task.md](./task.md)
**Related Plan**: [plan.md](./plan.md)
**Related Summary**: [summary.md](./summary.md)

---

<!-- SIZE:IDENTITY:START -->
## Identity

- **Task Archetype**: `archetype:feature`
- **Primary Scope Area**: `scope:managed-terrain`
- **Likely Systems Touched**:
  - `systems:command-layer`
  - `systems:terrain-kernel`
  - `systems:terrain-output`
  - `systems:terrain-mesh-generator`
  - `systems:terrain-state`
  - `systems:terrain-repository`
  - `systems:serialization`
  - `systems:tool-response`
- **Validation Modes**: `validation:contract`, `validation:migration`, `validation:hosted-matrix`, `validation:regression`
- **Likely Analog Class**: terrain-output feature-intent state and planning foundation after failed simplifier replacement

### Identity Notes
- This task is an internal foundation for feature-aware terrain output and diagnostics. It should
  not change the public `heightmap_grid` payload kind, MCP request/response shape, or introduce a
  public spline authoring tool.
- Planning rebaseline on 2026-05-03 narrowed the architecture to a hybrid internal layer:
  first-class `FeatureIntentSet`, `FeatureIntentMerger`, and `TerrainFeaturePlanner`, with
  lightweight deltas/emitters/runtime context.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Internal foundation spans all existing terrain edit families and output diagnostics, but still avoids a new public edit mode or public feature API. |
| Technical Change Surface | 4 | Refined plan touches state/schema, serializer/migration, repository round-trip, command flow, edit emitters, merge policy, output planning, mesh-regeneration preflight, and no-leak tests. |
| Hidden Complexity Suspicion | 4 | Feature identity, overlap retention, off-grid controls, pointification caps, and pre-save/post-save planning are all known complexity drivers. |
| Validation Burden Suspicion | 4 | Requires unit, repository/migration, command integration, no-leak, and hosted/manual validation for save/reopen, undo, corridor-heavy, adopted/off-grid scenes. |
| Dependency / Coordination Suspicion | 2 | Work remains in the owned Ruby terrain runtime, but depends on prior terrain edit and output-planning behavior staying stable. |
| Scope Volatility Suspicion | 2 | Scope is now constrained by the hybrid layer and tiered feature support; inferred heightfield and derived caches are deferred. |
| Confidence | 3 | Technical plan, local source reads, UE source research, and external review now support the seed shape, though hosted behavior remains unproven. |

### Early Signals
- MTA-19 failed because correct heightfield samples could still produce unreliable derived output,
  especially around corridors and adopted irregular terrain.
- UE Landscape source research corrected the first merge instinct: authored feature identity must
  not be retired by affected-window overlap.
- Local source shows concrete insertion points but also a host-sensitive save/regenerate order that
  requires a pre-save feature guard.
- The task avoids public contract expansion and a new triangulation backend, so risk concentrates
  in internal state, merge, planner, no-leak, and hosted validation behavior.

### Early Estimate Notes
- Rebaseline treats MTA-20 as a validation-heavy internal feature foundation with schema/migration
  sensitivity. The likely difficulty is keeping feature intent durable and deterministic without
  building a broad layer stack or leaking accidental public vocabulary.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

> Filled during task planning. This is the main pre-implementation estimate.

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Internal behavior foundation spans all current edit families and output diagnostics, but public clients see no new feature workflow. |
| Technical Change Surface | 4 | Plan touches schema/state, serializer/migration, repository, command orchestration, emitters, merge policy, planner, mesh preflight, evidence/no-leak tests, and hosted validation. |
| Implementation Friction Risk | 3 | Hybrid layer is bounded, but semantic IDs, merge family rules, two-phase planning, and state preservation introduce meaningful engineering resistance. |
| Validation Burden Risk | 3 | Requires broad automated coverage plus hosted/manual persistence, undo, output mutation, off-grid/adopted, and no-leak validation; burden is high but bounded if no hosted fix loop appears. |
| Dependency / Coordination Risk | 2 | Depends on prior terrain edit/output foundations and SketchUp-hosted validation access, but no external service or public cross-team API change is planned. |
| Discovery / Ambiguity Risk | 2 | Major architecture and contracts are resolved; remaining unknowns are hosted behavior, cap adequacy, and edge-case feature interactions. |
| Scope Volatility Risk | 2 | Tiered feature support and deferred inferred features reduce volatility, but planner/diagnostic behavior could still force a split if expansion grows. |
| Rework Risk | 3 | Wrong semantic IDs, digest ordering, or merge policy would force rework across state, emitters, tests, and planner integration. |
| Confidence | 3 | Estimate is backed by finalized plan, source reads, external review, and premortem challenge; implementation and hosted evidence are still pending. |

### Top Assumptions
- Public MCP request/response shape remains unchanged, with feature work proven through no-leak
  tests rather than public schema updates.
- First slice keeps inferred heightfield features out of durable state and limits them to minimal
  runtime-only diagnostic candidates; it does not add a derived-lane cache.
- Two-phase feature planning can refuse before repository save for known invalid/cap/conflict
  cases, then finalize planning after saved digest is available.
- Existing edit kernels can keep returning state/diagnostics while thin emitters derive feature
  deltas from request/context.

### Estimate Breakers
- Hosted SketchUp behavior shows repository save/abort or undo semantics cannot support the
  two-phase command flow as planned.
- Semantic ID or merge rules need richer user-facing handles or public contract fields to avoid
  duplicate/stale features.
- Feature planner must perform full pointification or broad topology diagnostics in the first slice
  instead of cheap projection, runtime context, and narrow diagnostic classification fixtures.
- Existing mesh regeneration cannot consume feature context without a broader output-generator
  redesign.
- No-leak tests reveal current evidence/refusal paths expose internal diagnostics too broadly.

### Predicted Signals
- `plan.md` introduces schema v3 state, semantic IDs, merge policy, planner guard, and hosted
  validation, expanding beyond the original seed's edit/output-only assumption.
- UE source and local source agree that authored identity, invalidation windows, and derived
  expansion must stay separate.
- The hybrid layer intentionally limits first-class new objects, but it still creates three new
  policy centers that must be tested independently and together.
- Validation spans migration, digest stability, command ordering, public no-leak, and hosted
  SketchUp behavior.

### Predicted Estimate Notes
- Predicted profile is based on the 2026-05-03 finalized technical plan, Step 05-08 planning
  findings, targeted terrain source research, external review, and Step 11 premortem. The estimate
  treats hosted validation as a confidence and risk driver, not as completed evidence. No predicted
  score was revised during challenge because the premortem added validation obligations that fit
  the existing high-but-bounded validation and rework scores.
<!-- SIZE:PREDICTED:END -->

---

<!-- SIZE:CHALLENGE:START -->
## Challenge Review

> Filled when the estimate is pressure-tested through external review, premortem, or controlled consensus.

### Agreed Drivers
- Technical change surface remains `4`: schema v3, serializer/migration, repository round trip,
  command orchestration, emitters, merge policy, planner/runtime context, no-leak, and hosted
  validation are all in scope.
- Implementation friction remains `3`: semantic IDs, overlap-retaining merge policy, two-phase
  planning, and feature/state preservation are the main resistance points, but the hybrid layer
  avoids a broad object stack or triangulation rewrite.
- Validation burden remains `3`: challenge added minimal inferred-candidate, diagnostic
  classification, partial-regeneration fallback, and public refusal no-leak obligations, but no
  evidence yet shows a hosted blocker or repeated fix/retest loop.
- Rework risk remains `3`: wrong ID normalization, merge rules, public no-leak boundary, or
  post-save host behavior would force cross-layer rework.

### Contested Drivers
- Inferred heightfield usefulness is contested. Premortem found a task/plan mismatch when inferred
  features were fully deferred; the finalized plan now requires minimal runtime-only inferred
  candidates, but implementation may still prove them too shallow for adopted terrain diagnostics.
- Diagnostic value is contested because output generation is not changed. The plan is only
  build-worthy if deterministic diagnostic fixtures prove feature context can classify cases the
  raw heightmap alone cannot.
- Hosted validation cost is contested. The case matrix is broad but still routine unless SketchUp
  save/undo/output-preflight behavior creates a fix-loop or reveals state/output incoherence.
- Public refusal details are contested. Internal diagnostics need feature IDs/kinds/windows, while
  public paths must hide them; current estimate assumes tests can enforce that boundary without
  requiring new public contract fields.

### Missing Evidence
- No implementation evidence yet that `TerrainFeaturePlanner` can prepare useful runtime context
  while remaining hash-based and non-persistent.
- No hosted evidence yet for pre-save feature refusal, post-save output-preflight refusal,
  save/reopen, undo, transformed owner, or partial-regeneration fallback behavior.
- No test evidence yet that minimal inferred candidates classify adopted/legacy hard-break or
  transition fixtures without becoming a broader inferred-feature detection task.
- No no-leak fixture evidence yet proving refusal paths hide feature IDs/kinds/windows while
  preserving enough public diagnostic value.

### Recommendation
- Confirm the challenged estimate without score changes. Proceed to implementation with TDD order
  from the finalized plan: schema/digest and merge first, then emitters, planner/runtime context,
  command integration, no-leak, and hosted validation. Split or defer only if hosted abort behavior,
  public refusal boundary, or inferred-candidate usefulness becomes a real implementation blocker.

### Challenge Notes
- Step 11 premortem classified the inferred-feature mismatch and public refusal/no-leak boundary as
  material risks and updated the plan before finalization.
- Accepted residual risks are diagnostic shallowness, hosted post-save/output-preflight behavior,
  and support-tier false completion. These do not justify pre-implementation resizing because each
  has a concrete implementation-time validation path.
- The estimate intentionally does not increase validation burden to `4`: the plan has many
  validation modes, but no current evidence of special hosted setup, repeated rerun loops, or
  unresolved compatibility blockers.
<!-- SIZE:CHALLENGE:END -->

---

<!-- SIZE:DRIFT:START -->
## Drift Log

> Append only. Log only material changes that affect estimate shape, risk, confidence, or validation burden.

| Date | Phase / Checkpoint | Event Type | Severity (1-3) | Dimension Affected | Predictable Earlier? | Notes |
|---|---|---|---:|---|---|---|
| 2026-05-03 | Post-implementation plan cross-check | Under-implementation found and corrected | 2 | Actual Rework, Actual Discovery Encountered, Final Confidence | Yes | Initial closeout missed part of the foundational plan: stronger planner diagnostics, fixed/preserve conflict evidence, tight corridor refusal, broader semantic ID edge cases, and local post-save output-preflight preservation coverage. Follow-up implementation closed the automated gaps; hosted validation remains unrun. |

### Drift Notes
- One material implementation drift was recorded during closeout: the first pass was too shallow
  against the finalized plan. The reopened pass added the missing foundational behavior and tests
  without expanding public contract scope or replacing terrain output generation.
<!-- SIZE:DRIFT:END -->

---

<!-- SIZE:ACTUAL:START -->
## Actual Profile

> Filled at the end of implementation. Do not overwrite predicted values.

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Internal behavior foundation spans schema v3 feature intent, all current edit-family emitters, runtime planning, diagnostics, and no-leak behavior without public workflow expansion. |
| Technical Change Surface | 4 | Touched state/schema, serializer/migration/digest, merge policy, emitters, planner, command orchestration, mesh-generator seam, contract tests, and package validation. |
| Actual Implementation Friction | 3 | The main architecture fit the planned seams, but closeout found under-implemented planner/conflict/semantic-ID coverage and required a reopened implementation pass. |
| Actual Validation Burden | 3 | Required broad unit/contract/CI/package checks plus PAL codereview, post-review focused checks, and hosted-smoke skip accounting; no hosted fix loop occurred because live SketchUp validation was not available. |
| Actual Dependency Drag | 2 | Work stayed inside Ruby terrain runtime; live SketchUp checks later covered create/edit/undo/transformed-owner refusal/adopted/off-grid/preflight paths, but active-model reopen remained intentionally unrun. |
| Actual Discovery Encountered | 3 | Codereview exposed a feature-window reconciliation gap, and plan cross-check exposed missing foundation evidence around planner conflicts, tight corridor refusal, semantic IDs, and post-save output-preflight preservation. |
| Actual Scope Volatility | 2 | Scope stayed within the original foundation task and avoided public contract/backend expansion, but completion required reopening the implementation for planned behavior that was initially missed. |
| Actual Rework | 3 | Follow-up changes addressed codereview findings, one output-strategy regression, and the reopened plan-gap implementation pass, but did not force redesign. |
| Final Confidence in Completeness | 3 | Automated validation, review, and live hosted checks are strong for the first-slice foundation; confidence is still capped by not replacing/reopening the user's active model. |

### Actual Signals
- Schema v3, migration, canonical digest ordering, semantic IDs, merge policy, emitters, planner,
  command integration, and no-leak behavior all landed with focused tests.
- PAL codereview found a feature-window reconciliation gap; the fix expanded dirty output planning
  from prepared feature windows and CI passed afterward.
- Post-implementation plan cross-check found missing foundational evidence; follow-up added
  internal cap diagnostics, fixed/preserve conflict diagnostics, conservative tight corridor
  refusal, semantic ID edge-case tests, post-save output-preflight preservation coverage, and nested
  evidence sanitization.
- Existing generated output remains the production baseline; feature-aware triangulation and full
  lane pointification stayed out of scope.
- Hosted smoke entrypoints ran locally but skipped by design. A later live SketchUp pass verified
  off-side create/edit/corridor/adopted/off-grid/undo/transformed-owner refusal/post-save
  preflight behavior and save-copy serialization; full active-model reopen was intentionally not
  run.

### Actual Notes
- Actual work matched the predicted high change surface and rework risk more closely after the
  reopened pass. The hybrid layer fit current seams, and live hosted evidence improved confidence;
  only disruptive active-model reopen remains unverified.
<!-- SIZE:ACTUAL:END -->

---

<!-- SIZE:VALIDATION-EVIDENCE:START -->
## Validation Evidence Summary

> Fill only the sections that are relevant. Say `not applicable` where needed.

### Automated Validation
- `bundle exec ruby -Itest -e 'Dir["test/terrain/**/*_test.rb"].sort.each { |path| load path }'`
  passed: `274 runs, 2169 assertions, 0 failures, 0 errors, 3 skips`.
- Focused post-review checks passed: `60 runs, 563 assertions, 0 failures, 0 errors, 0 skips`;
  focused RuboCop with cache disabled inspected `2 files` with no offenses.
- `bundle exec rake ci` passed after reopened follow-up: RuboCop clean across `223 files`; Ruby
  tests `874 runs, 4519 assertions, 0 failures, 0 errors, 37 skips`; package verification produced
  `dist/su_mcp-1.1.2.rbz`.

### Hosted / Manual Validation
- Hosted smoke entrypoints ran locally and skipped by design: `3 runs, 0 assertions, 0 failures,
  0 errors, 3 skips`.
- Live SketchUp validation ran on 2026-05-03 with off-side fixtures:
  `MTA20-LIVE-foundation-20260503` and `MTA20-LIVE-adopted-20260503`.
- Verified schema v3/default feature intent, target/preserve/fixed feature intent, corridor
  feature roles, transformed-owner refusal, undo restoring revision/digest, unsupported-child
  preflight refusal preserving existing output, adopted/off-grid terrain creation and edit, source
  replacement, and non-disruptive `save_copy` serialization.
- Full active-model reopen was intentionally not run because it would replace/reload the user's
  currently open scene.

### Performance Validation
- No dedicated performance benchmark was run. Planner pointification remains a cheap bounded
  projection with unit coverage for cap refusal, not full lane expansion.

### Migration / Compatibility Validation
- Serializer tests cover v1 and v2 migration to schema v3 with default empty `featureIntent`,
  digest participation, canonical ordering, corrupt payloads, unsupported versions, and
  `with_elevations` preservation.

### Operational / Rollout Validation
- Package verification ran through `bundle exec rake ci` and produced the RBZ artifact.
- No public MCP request/response schema or docs changed; contract stability tests cover no-leak
  posture for success and refusal paths.

### Validation Notes
- Validation burden stayed high but bounded: codereview-driven fixes, a reopened plan-gap pass,
  live hosted checks without a hosted fix loop, and one remaining disruptive reopen gap.
<!-- SIZE:VALIDATION-EVIDENCE:END -->

---

<!-- SIZE:DELTA:START -->
## Estimation Delta Review

> Filled during final calibration. Compare prediction to actual behavior.

- **Most Underestimated Dimension**: Actual rework. Partial-regeneration reconciliation and several
  foundation obligations were in the plan, but the first implementation pass still missed them.
- **Most Overestimated Dimension**: Scope volatility. Even after the reopened pass, the work did
  not require public contract expansion, a new backend, or a broader terrain feature object stack.
- **Signal Present Early But Underweighted**: Existing dirty-window partial regeneration made
  feature affected-window consumption a correctness path, and the tiered support plan required
  explicit evidence for planner conflict behavior rather than only emitter/merge tests.
- **Genuinely Unknowable Factor**: Full active-model reopen remains unverified because replacing
  the user's open scene was intentionally avoided; save-copy serialization did succeed.
- **Future Similar Tasks Should Assume**: Internal terrain-state foundations with no public MCP
  expansion can land cleanly when TDD starts at schema/merge seams, but partial-output ownership and
  hosted verification must be treated as first-class closeout risks.

### Calibration Notes
- Dominant actual failure modes were incomplete integration of prepared feature windows into output
  planning and an initially too-thin planner foundation against the finalized plan.
- Future estimates should separate implementation friction from validation confidence: automated
  unit/contract/package validation was routine after rework, and live checks were feasible once a
  hosted scene was available, but active-model reopen still needs explicit user approval.
<!-- SIZE:DELTA:END -->

---

<!-- SIZE:TAGS:START -->
## Retrieval Tags

- `archetype:feature`
- `scope:managed-terrain`
- `systems:command-layer`
- `systems:terrain-kernel`
- `systems:terrain-output`
- `systems:terrain-repository`
- `systems:terrain-state`
- `systems:serialization`
- `validation:contract`
- `validation:hosted-matrix`
- `validation:migration`
- `host:not-run-gap`
- `contract:no-public-shape-change`
- `risk:contract-drift`
- `risk:partial-state`
- `risk:review-rework`
- `friction:medium`
- `confidence:medium`
<!-- SIZE:TAGS:END -->
