# Size: SAR-05 Orientation-Aware Asset Placement

**Task ID**: `SAR-05`
**Title**: `Orientation-Aware Asset Placement`
**Status**: `calibrated`
**Created**: `2026-05-15`
**Last Updated**: `2026-05-16`

**Related Task**: [task.md](./task.md)
**Related Plan**: [plan.md](./plan.md)
**Related Summary**: [summary.md](./summary.md)

---

<!-- SIZE:IDENTITY:START -->
## Identity

- **Task Archetype**: `archetype:feature`
- **Primary Scope Area**: `scope:staged-asset-reuse`
- **Likely Systems Touched**:
  - `systems:public-contract`
  - `systems:runtime-dispatch`
  - `systems:command-layer`
  - `systems:scene-mutation`
  - `systems:surface-sampling`
  - `systems:target-resolution`
  - `systems:serialization`
  - `systems:tool-response`
  - `systems:native-contract-fixtures`
  - `systems:docs`
- **Validation Modes**:
  - `validation:contract`
  - `validation:undo`
  - `validation:hosted-smoke`
  - `validation:compatibility`
- **Likely Analog Class**: orientation-aware staged asset instantiation

### Identity Notes
- This is a bounded follow-on to `SAR-02`: it extends staged asset instantiation with explicit heading control and request-driven surface-derived alignment for one rigid instance rather than adding scatter, replacement, arbitrary transforms, offsets, metadata gating, or area coverage workflows.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 2 | Adds orientation behavior to an existing instantiation workflow, but keeps scatter, replacement, and automatic terrain inference out of scope. |
| Technical Change Surface | 3 | Likely touches public schema, staged asset command behavior, transform construction, specific surface-reference frame derivation, compact response evidence, contract fixtures, docs, and tests. |
| Hidden Complexity Suspicion | 3 | Surface-derived transforms, SketchUp axis conventions, ambiguity handling, and interaction with existing source-instance transforms can hide host-specific issues. |
| Validation Burden Suspicion | 3 | Needs contract coverage, refusal paths, transform evidence, undo safety, backward compatibility, and likely live SketchUp smoke for actual orientation behavior. |
| Dependency / Coordination Suspicion | 2 | Depends on `SAR-01` metadata, `SAR-02` instantiation behavior, and a supported surface-reference path, but keeps broad area coverage and tiling in `SAR-06`. |
| Scope Volatility Suspicion | 2 | Public field shape, offset, replacement reuse, and metadata enforcement have been narrowed; transform order and surface ambiguity still need explicit planning gates. |
| Confidence | 2 | Requirements are clear at task-definition level, but no technical plan exists yet and transform semantics are known to be host-sensitive from `SAR-02`. |

### Early Signals
- `SAR-02` live validation exposed transform and group-copy host sensitivity, making orientation math a real risk rather than a trivial schema addition.
- External engine precedent supports separate yaw, surface alignment, slope limits, and offset concepts; this task intentionally keeps slope vetoes, offsets, random scatter, arbitrary transform contracts, and brush behavior out.
- Explicit normal-vector input is out of scope; surface alignment is derived from a specific referenced surface and placement point.
- Metadata is preserved only as JSON-safe property-bag information; explicit `placement.orientation` input drives SAR-05 behavior and metadata cannot veto placement.
- Backward compatibility matters because existing position/scale-only `instantiate_staged_asset` calls must keep working unchanged.

### Early Estimate Notes
- Seed uses `SAR-02` as the closest analog but scores functional scope lower because this is an extension to instantiation rather than the first mutating staged-asset workflow.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

> Filled during task planning. This is the main pre-implementation estimate.

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | 2 | Moderate behavior extension to one existing tool: upright yaw, surface-aligned single-instance placement, compact evidence, and refusals; scatter, offsets, replacement, and metadata gating are out. |
| Technical Change Surface | 3 | Touches native schema, staged-asset command orchestration, creator/serializer behavior, new orientation and surface-frame helpers, scene-query support reuse, fixtures, docs, and hosted smoke. |
| Implementation Friction Risk | 3 | Transform composition, source-heading preservation, surface-frame derivation, and group/component host behavior are known friction points from `SAR-02`, `STI-02`, and `STI-03`. |
| Validation Burden Risk | 4 | Correctness requires contract tests, command refusal/atomicity tests, transform-axis evidence, serializer checks, docs parity, and live SketchUp validation for axes, hit Z, undo, and no-mutation refusals. |
| Dependency / Coordination Risk | 2 | Depends on implemented `SAR-01`/`SAR-02`, direct target references, surface support internals, and hosted validation access, but no external service or separate team dependency dominates. |
| Discovery / Ambiguity Risk | 2 | Major contract choices are resolved; remaining uncertainty is numeric tolerances, exact transform multiplication order, and how much direct-reference target variety is supported in the first pass. |
| Scope Volatility Risk | 2 | User decisions narrowed metadata, offsets, replacement, and response verbosity; volatility remains if hosted proof forces target-support or transform evidence expansion. |
| Rework Risk | 3 | Similar geometry/host tasks needed rework after live or hosted evidence; this task deliberately carries hosted axis/surface/refusal checks that may force contained fixes. |
| Confidence | 2 | The plan is concrete, premortem-tested, and analog-informed, but host-sensitive transform and surface behavior keeps estimate confidence moderate until implementation produces hosted evidence. |

### Top Assumptions
- Existing SAR-02 creator paths can accept a resolved placement transform/evidence object without redesigning staged asset instantiation.
- `TargetReferenceResolver` and `SampleSurfaceSupport` can be reused for direct `surfaceReference` handling without duplicating the surface traversal stack.
- Metadata remains property-bag-only, so no normalized metadata migration or policy enforcement is required.
- Hosted validation is available for at least focused component/group, sloped-face, undo, and refusal checks.

### Estimate Breakers
- Surface-frame resolution cannot reuse existing target/surface support and needs a second geometry traversal stack.
- Group or component transform behavior in live SketchUp invalidates the planned transform-builder integration with `AssetInstanceCreator`.
- Contract review reopens top-level `hosting`, `surfaceOffset`, metadata policy, replacement, or slope-veto scope.
- Hosted validation reveals repeated transform/normal/ambiguity defects requiring broad target matrix expansion.

### Predicted Signals
- `SAR-02` actual validation burden was `4` and friction/rework were `3` due to source transform and group-copy host behavior.
- `STI-03` actual validation burden was `4` because hosted matrix uncovered nested target, hidden visibility, and ignore-target defects.
- `STI-02` actual implementation friction/rework were `3` around transform-aware face-plane/classification sampling.
- `SEM-15` stayed moderate when anchor resolution happened before mutation, supporting the planned preflight sequencing.
- The refined task removes metadata vetoes, slope limits, offsets, and replacement consumption, keeping functional scope moderate.

### Predicted Estimate Notes
- Predicted profile is rebaselined after Step 06 refinements: explicit `placement.orientation` drives behavior, metadata cannot veto placement, and compact response evidence replaces broader diagnostics. The outside-view risk remains high around validation and rework because this combines SAR-02-style host-sensitive instantiation with STI-style transformed surface handling.
<!-- SIZE:PREDICTED:END -->

---

<!-- SIZE:CHALLENGE:START -->
## Challenge Review

> Filled when the estimate is pressure-tested through external review, premortem, or controlled consensus.

### Agreed Drivers
- Public contract change is real but bounded to the existing `instantiate_staged_asset` tool and existing top-level sections.
- Implementation friction remains high because source-heading preservation, surface-frame derivation, and transform composition are host-sensitive.
- Metadata non-veto scope reduction is credible and keeps functional scope at `2`.
- Validation must include hosted SketchUp evidence for axes, hit Z, undo, and refusal atomicity; local doubles are insufficient.

### Contested Drivers
- Validation Burden `4` is the main challenged score: the hosted matrix is focused, but prior analogs show transform/surface hosted checks often trigger fix/reload/retest loops and interpretation cost.
- Rework Risk `3` is plausible but not certain; premortem guardrails may contain rework if transform and resolver helpers are implemented test-first.
- Discovery Risk `2` depends on tolerances and supported surface target breadth staying explicit rather than expanding into broad surface interrogation.

### Missing Evidence
- No live proof yet that the planned transform-builder integration preserves SAR-02 component/group behavior under yaw and surface alignment.
- No finalized numeric tolerances for same-hit clustering, normal equivalence, or degenerate frame detection.
- No confirmed hosted smoke fixture list for sloped face, ambiguous frame, and representative component/group exemplar.

### Recommendation
- Keep the predicted profile unchanged. Proceed with implementation using the finalized plan, but treat hosted axis/surface/refusal evidence as a closeout gate and do not downgrade validation burden until actual validation is completed.

### Challenge Notes
- Challenge input came from the Step 12 premortem plus calibrated analogs: `SAR-02` actual validation `4`, `STI-03` actual validation `4`, `STI-02` friction/rework `3`, and `SEM-15` showing preflight anchor resolution can contain mutation risk. No score change is justified before implementation.
<!-- SIZE:CHALLENGE:END -->

---

<!-- SIZE:DRIFT:START -->
## Drift Log

> Append only. Log only material changes that affect estimate shape, risk, confidence, or validation burden.

| Date | Phase / Checkpoint | Event Type | Severity (1-3) | Dimension Affected | Predictable Earlier? | Notes |
|---|---|---|---:|---|---|---|

### Drift Notes
- No material drift recorded yet.
<!-- SIZE:DRIFT:END -->

---

<!-- SIZE:ACTUAL:START -->
## Actual Profile

> Filled at the end of implementation. Do not overwrite predicted values.

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | 2 | Added bounded orientation behavior to one existing staged asset instantiation flow without scatter, offsets, replacement, or metadata policy. |
| Technical Change Surface | 3 | Touched native schema, command preflight, creator transform composition, surface-frame resolution, serializer evidence, contract fixtures, docs, and tests. |
| Actual Implementation Friction | 3 | Transform semantics required review-driven fixes for live-face sampling, surface-aligned source heading, source axis scale, and explicit upright model-vertical behavior. |
| Actual Validation Burden | 3 | Exceeded baseline because hosted visual smoke found one material surface-aligned groundcover defect that required a fix/reload/retest loop. |
| Actual Dependency Drag | 2 | Relied on existing SAR-01/SAR-02 staged asset seams and scene-query surface support; final hosted proof was blocked by lack of a live SketchUp host in this session. |
| Actual Discovery Encountered | 3 | Review exposed that fake-surface tests did not prove runtime face sampling and that source heading/scale semantics needed additional transform coverage. |
| Actual Scope Volatility | 1 | Public scope stayed stable; changes stayed within `placement.orientation` and did not reopen offsets, scatter, replacement, or metadata vetoes. |
| Actual Rework | 2 | Revisited the transform slice after review/live evidence, but the correction was localized and did not replace the approach or change the public contract. |
| Final Confidence in Completeness | 3 | Fixed surface-aligned behavior is live-verified, explicit upright behavior was accepted in live review, undo uses the shared operation wrapper, and post-fix CI is green. |

### Actual Signals
- `summary.md` records additive `placement.orientation` support with strict validation, compact response evidence, schema/docs/fixtures parity, and no metadata veto behavior.
- PAL review with `gpt-5.4` found real transform and runtime-sampling gaps that local first-pass tests missed.
- Hosted visual review found a further surface-aligned source-basis defect: asset `13` could stand perpendicular to terrain until the builder was changed to rotate the existing source transform from model up to surface up.
- Full CI passed before the hosted transform-basis fix: RuboCop 360 files clean, Ruby tests `1444 runs, 17386 assertions`, and package verification produced `dist/su_mcp-1.8.0.rbz`.
- Post-fix focused validation passed for the transform builder, staged-assets suite, and runtime suite; post-fix full CI is green.
- Hosted SketchUp fixed-surface smoke passed after the additional transform fix; explicit upright was accepted in live review, and undo is covered by the unchanged shared operation wrapper.

### Actual Notes
- Dominant actual failure mode: local doubles and fake surfaces did not fully exercise live SketchUp face sampling or source-transform composition semantics.
- The implementation is complete for local runtime, public contract, post-fix CI, and hosted orientation smoke.
<!-- SIZE:ACTUAL:END -->

---

<!-- SIZE:VALIDATION-EVIDENCE:START -->
## Validation Evidence Summary

> Fill only the sections that are relevant. Say `not applicable` where needed.

### Automated Validation
- Focused staged assets suite passed: `64 runs, 211 assertions, 0 failures, 0 errors, 0 skips`.
- Focused runtime suite passed: `167 runs, 750 assertions, 0 failures, 0 errors, 36 skips`.
- Focused scene-query plus staged-assets suite passed: `162 runs, 523 assertions, 0 failures, 0 errors, 1 skip`.
- Full `bundle exec rake ci` passed after final review follow-up:
  - RuboCop: 360 files inspected, no offenses.
  - Ruby tests: `1444 runs, 17386 assertions, 0 failures, 41 skips`.
  - Package verification produced `dist/su_mcp-1.8.0.rbz`.
- Post hosted-transform-fix focused validation passed:
  - Transform builder test: `7 runs, 30 assertions, 0 failures, 0 errors, 0 skips`.
  - Staged assets suite: `65 runs, 214 assertions, 0 failures, 0 errors, 0 skips`.
  - Runtime suite: `167 runs, 750 assertions, 0 failures, 0 errors, 36 skips`.
- Post-fix full `bundle exec rake ci` passed:
  - RuboCop: 360 files inspected, no offenses.
  - Ruby tests: `1445 runs, 17389 assertions, 0 failures, 0 errors, 41 skips`.
  - Package verification produced `dist/su_mcp-1.8.0.rbz`.
- PAL code review ran with `model: "gpt-5.4"` and review follow-up changes were incorporated before final CI.

### Hosted / Manual Validation
- Initial hosted smoke found invalid visual evidence: a broad/flat-enough terrain reference and clipped hedge probes placed at explicit `z: 1.0`.
- Hosted visual review also found a real `surface_aligned` transform bug where groundcover asset `13` could stand perpendicular to terrain.
- After deploying and reloading the transform fix, a first-class `su-ruby` smoke passed on `sar05-live-steep-surface-001`:
  - `sample_surface_z` confirmed a clear sloped test surface with center hit `z = 0.6`.
  - `instantiate_staged_asset` created `sar05-live-surface-aligned-fixed-001` with `placement.position = [33.0, 57.0, 0.6]` and `slopeDegrees = 30.963756532`.
  - `validate_scene_update` passed for the test surface, created instance, and instance metadata.
  - Missing `surfaceReference` refused with no created `sar05-live-surface-refusal-fixed-001` entity.
- Explicit upright visual behavior was accepted in live review.
- Undo is not a separate SAR-05 hosted gate because the command continues to use the shared SketchUp operation wrapper.

### Performance Validation
- Not applicable. SAR-05 adds one preflight surface-frame sample for one instance and no performance benchmark was required.

### Migration / Compatibility Validation
- Backward compatibility was covered by omitted-orientation tests and native contract fixtures proving SAR-02-style position/scale requests remain valid.

### Operational / Rollout Validation
- Package verification passed through post-fix `bundle exec rake ci`.
- The corrected transform builder and SAR-05 runtime files were copied into the SketchUp plugin tree and reloaded with `eval_ruby` for hosted validation.

### Validation Notes
- Inflation check: this is above baseline because of one material hosted visual fix loop, but it is not `4` because validation did not dominate delivery through repeated blockers, revert, or redesign.
- Hosted orientation evidence is accepted and post-fix CI is green.
<!-- SIZE:VALIDATION-EVIDENCE:END -->

---

<!-- SIZE:DELTA:START -->
## Estimation Delta Review

> Filled during final calibration. Compare prediction to actual behavior.

- **Most Underestimated Dimension**: Actual Rework. The plan correctly identified transform risk, but the first green local suite still missed runtime face sampling, source heading/scale edge cases, and source definition-axis correction until review and hosted visual checks.
- **Most Overestimated Dimension**: Scope Volatility. The public shape stayed bounded to `placement.orientation`; offsets, scatter, replacement, slope vetoes, and metadata policy did not re-enter the task.
- **Signal Present Early But Underweighted**: SAR-02 and STI analogs already showed host-sensitive transform and surface behavior; that signal should have driven earlier non-identity source-transform tests for every orientation mode.
- **Genuinely Unknowable Factor**: Whether all asset-library visual axes match transform assumptions was only knowable through hosted visual placement; asset `13` proved local stubs were insufficient.
- **Future Similar Tasks Should Assume**: Orientation or surface-aligned mutation work needs non-identity source transforms, scale preservation, fake and runtime face paths, and hosted validation with visually meaningful fixtures.

### Calibration Notes
- Inflation check disposition: Validation Burden is `3` for one material hosted fix loop, Rework is `2` for a localized transform correction, Scope Volatility is `1` because the task boundary did not change, and Confidence is `3` because hosted orientation evidence is accepted and post-fix CI is green.
<!-- SIZE:DELTA:END -->

---

<!-- SIZE:TAGS:START -->
## Retrieval Tags

- `archetype:feature`
- `scope:staged-asset-reuse`
- `systems:public-contract`
- `systems:command-layer`
- `systems:scene-mutation`
- `systems:surface-sampling`
- `systems:target-resolution`
- `systems:serialization`
- `validation:contract`
- `validation:hosted-smoke`
- `host:single-fix-loop`
- `contract:public-tool`
- `contract:finite-options`
- `risk:transform-semantics`
- `risk:review-rework`
- `volatility:low`
- `friction:high`
- `rework:medium`
- `confidence:medium`
<!-- SIZE:TAGS:END -->
