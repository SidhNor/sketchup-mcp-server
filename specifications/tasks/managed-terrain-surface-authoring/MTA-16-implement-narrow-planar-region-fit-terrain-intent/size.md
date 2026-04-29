# Size: MTA-16 Implement Narrow Planar Region Fit Terrain Intent

**Task ID**: `MTA-16`  
**Title**: Implement Narrow Planar Region Fit Terrain Intent  
**Status**: calibrated
**Created**: 2026-04-28  
**Last Updated**: 2026-04-29  

**Related Task**: [task.md](./task.md)  
**Related Plan**: [plan.md](./plan.md)
**Related Summary**: [summary.md](./summary.md)

---

<!-- SIZE:IDENTITY:START -->
## Identity

- **Task Archetype**: archetype:feature
- **Primary Scope Area**: scope:managed-terrain
- **Likely Systems Touched**:
  - systems:terrain-state
  - systems:terrain-kernel
  - systems:terrain-output
  - systems:loader-schema
  - systems:runtime-dispatch
  - systems:command-layer
  - systems:public-contract
  - systems:native-contract-fixtures
  - systems:test-support
  - systems:docs
- **Validation Modes**: validation:regression, validation:contract, validation:docs-check, validation:public-client-smoke, validation:hosted-matrix, validation:performance, validation:undo
- **Likely Analog Class**: narrow public terrain edit mode implementation

### Identity Notes
- This task implements a narrow explicit planar terrain edit intent. It is closer to MTA-13-style public edit-mode delivery than to an open-ended MTA-14-style evaluation, but simpler than MTA-13 because it adds one planar replacement mode rather than local plus regional survey-correction semantics.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Ships a new explicit terrain edit intent, but keeps the first slice narrow to bounded rectangle/circle regions and planar controls. |
| Technical Change Surface | 3 | Likely spans terrain-domain solver code, request validation, runtime schema, dispatcher path, native fixtures, docs, and tests. |
| Hidden Complexity Suspicion | 3 | Coplanarity, least-squares residuals, preserve-zone interaction, and grid spacing can hide real solver/contract ambiguity. |
| Validation Burden Suspicion | 4 | Needs terrain-domain fixtures, request/contract tests, docs parity, and hosted/public MCP proof for the new edit intent. |
| Dependency / Coordination Suspicion | 3 | Depends on MTA-13/MTA-14 terrain solver precedent, MTA-15 discoverability, and may expose MTA-11 grid-detail limits. |
| Scope Volatility Suspicion | 2 | Scope is intentionally narrowed to one explicit planar intent, with `planar_region_fit`, `constraints.planarControls`, and `evidence.planarFit` settled during task planning. |
| Confidence | 3 | User direction, prior solver work, current runtime patterns, and Step 05 consensus support the task shape; hosted behavior still needs implementation proof. |

### Early Signals
- The task explicitly preserves current regional correction semantics and adds planar intent separately.
- Analog MTA-13 shows public terrain edit modes require runtime schema, dispatcher, docs, contract fixtures, and hosted MCP validation to move together.
- Analog MTA-14 provides reusable plane/residual-style evaluation expectations, but this task must ship production behavior rather than only a recommendation.
- Current `heightmap_grid` spacing may make some planar-control expectations unsafe or impossible without localized detail.
- Task planning settled a new explicit `planar_region_fit` intent inside `edit_terrain_surface`, with `constraints.planarControls`, weighted planar replacement, and `evidence.planarFit`.

### Early Estimate Notes
- Seed was refreshed during planning after Step 05 resolved the public contract shape and confirmed command/evidence/output surfaces.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

> Filled during task planning. This is the main pre-implementation estimate.

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Adds a new public managed-terrain edit intent with user-visible request fields, residual evidence, refusals, and hosted proof, while keeping scope narrow to one bounded planar replacement mode. |
| Technical Change Surface | 4 | Touches request validation, native loader schema, runtime dispatch, command wiring, a new terrain-domain editor, fixed/preserve integration, evidence shaping, terrain output handoff, fixtures, docs, examples, and tests. |
| Implementation Friction Risk | 3 | Least-squares plane fitting is straightforward, but effective-control handling, degeneracy checks, size-aware tolerance, residual refusal evidence, blend mutation, preserve/fixed interaction, and grid warnings create real implementation resistance. |
| Validation Burden Risk | 3 | Requires contract tests, terrain-domain numeric tests, command/evidence/no-leak tests, docs parity, hosted MCP validation, undo/output sanity, and larger-terrain performance sanity. This is high, but predicted below MTA-13's actual burden because the planar solver is narrower and does not include local/regional correction-field semantics. |
| Dependency / Coordination Risk | 2 | Depends on completed MTA-13/MTA-14/MTA-15 behavior, existing terrain output flow, and hosted SketchUp access. No upstream redesign or external service is expected. |
| Discovery / Ambiguity Risk | 2 | Major contract and algorithm decisions are settled through Step 05 and consensus. Remaining discovery is mostly threshold calibration edge cases, grid-warning usefulness, and hosted transform/output behavior. |
| Scope Volatility Risk | 2 | The task is intentionally narrow, but representative cases could still expose a need for localized detail zones, stronger grid safety rules, or a follow-up rather than widening MTA-16. |
| Rework Risk | 3 | Prior MTA-13 hosted validation found regional planar boundary defects, and this task has similar public contract plus numeric terrain evidence risks. Rework is expected to be contained but plausible around residual policy, degeneracy handling, or hosted output/coordinate behavior. |
| Confidence | 3 | Draft plan, acceptance criteria, calibrated analogs, and model consensus support the estimate. Confidence is capped because no implementation or hosted planar validation exists yet. |

### Top Assumptions

- The current `heightmap_grid` v1 representation is sufficient for the representative bounded rectangle/circle planar replacement cases, with unsafe close-control/detail cases handled through warnings or refusals.
- Existing `RegionInfluence`, `FixedControlEvaluator`, `TerrainSurfaceCommands`, `TerrainEditEvidenceBuilder`, repository, and output regeneration seams can be reused without structural redesign.
- A single least-squares `z = ax + by + c` plane with explicit residual refusal is enough for the narrow v1 planar intent.
- Hosted validation can reuse the existing public MCP terrain edit path and does not require special model setup beyond representative terrain fixtures.
- Docs/schema/fixtures can evolve as one public contract update without provider schema compatibility issues.

### Estimate Breakers

- Representative planar fit cases require localized detail zones, freeform regions, or terrain representation changes to be useful.
- Least-squares residuals plus the size-aware tolerance policy prove too permissive or too strict in hosted/public MCP validation and require redesign rather than parameter tuning.
- Fixed controls, preserve zones, or close controls require a constrained optimizer instead of the planned fit-then-check behavior.
- Native schema/provider constraints reject the added `constraints.planarControls` shape or make conditional requiredness confusing enough to require a larger schema redesign.
- Hosted validation exposes transform, output marker/normal, undo, or performance defects outside the planar editor.

### Predicted Signals

- Public contract breadth is real: validator, native loader schema, dispatcher, fixtures, docs, examples, response evidence, and no-leak tests must move together.
- Calibrated `MTA-13` is the closest analog and showed high validation burden, repeated hosted fix loops, and a product-boundary decision around explicit planar replacement.
- Calibrated `MTA-12` shows rectangle/circle vocabulary extensions can remain moderate-friction when shared region math, schema requiredness, fixtures, docs, and hosted checks are explicit.
- Calibrated `MTA-06` shows narrow public terrain edit modes can implement cleanly when algorithm and evidence semantics are settled before coding.
- Step 05 consensus across `gpt-5.4`, `grok-4.20`, and `grok-4` found no blocking disagreement on the core shape, but all models emphasized residual/refusal detail and no-survey-regression proof.

### Predicted Estimate Notes

- Seed-owned sections were refreshed before prediction because Step 05 resolved `planar_region_fit`, `constraints.planarControls`, weighted planar replacement, `evidence.planarFit`, and size-aware default tolerance.
- The prediction treats `MTA-13`, `MTA-12`, `MTA-06`, `MTA-14`, and `MTA-04` as calibrated analogs with different weights. `MTA-13` informs numeric/hosted rework risk; `MTA-12` and `MTA-06` temper implementation-friction expectations; `MTA-14` informs residual evidence but is not a public-runtime analog; `MTA-04` informs host output/undo risks.
- Validation risk is scored high but not very high because hosted terrain matrices are routine in this repo unless they expose defects or require redeploy/retest loops.
<!-- SIZE:PREDICTED:END -->

---

<!-- SIZE:CHALLENGE:START -->
## Challenge Review

> Filled when the estimate is pressure-tested through external review, premortem, or controlled consensus.

### Agreed Drivers

- Public contract breadth remains the dominant size driver: validator constants, native loader schema, runtime dispatch, native fixtures, docs, examples, response evidence, and no-leak coverage must move together.
- Terrain-domain numerical behavior is bounded but non-trivial: least-squares plane fitting is straightforward, while degeneracy, contradictory controls, residual policy, blend mutation, fixed controls, preserve zones, and grid warnings drive implementation friction.
- Hosted validation is required because transformed or non-zero-origin terrain, output regeneration, undo, markers, normals, and performance can fail outside isolated Ruby tests.
- The task remains narrower than `MTA-13` because it adds one explicit planar replacement mode rather than local plus regional survey-correction semantics.

### Contested Drivers

- Validation burden is broad but not yet proven to be a blocker. The premortem added coordinate-frame parity, tolerance-doc parity, and full-weight/blend/preserve evidence checks, but those are incremental acceptance gates rather than evidence of special setup or repeated fix-loop cost.
- Rework risk remains materially present because hosted behavior may expose transform/output/undo defects, but the plan carries explicit hosted gates and does not yet justify resizing or splitting.
- Scope volatility remains medium-low. `heightmap_grid` v1 coarseness could create pressure for localized detail zones, but the accepted boundary is to warn or refuse rather than widen MTA-16.

### Missing Evidence

- No implementation evidence exists yet for residual thresholds on representative user terrains.
- No hosted MCP proof exists yet for transformed/non-zero-origin terrain coordinate frames, undo, output markers/normals, or larger-terrain performance.
- No proof exists yet that close-control/shared-grid warnings are useful enough without adding a larger grid-analysis helper.
- No provider-schema proof exists yet for the added optional `constraints.planarControls` shape plus runtime-owned conditional requiredness.

### Recommendation

Confirm the predicted profile without score changes. Proceed with MTA-16 as one implementation task, but treat hosted validation and public contract parity as hard acceptance gates. Do not split unless implementation proves that localized detail zones, terrain representation changes, constrained optimization, or provider-schema redesign are required.

### Challenge Notes

- Step 05 consensus reduced ambiguity around the core shape: `planar_region_fit`, `constraints.planarControls`, least-squares fit, weighted planar replacement, and `evidence.planarFit`.
- The Step 11 premortem added guardrails for planarity overclaim, coordinate-frame drift, and tolerance-doc drift. These increase validation specificity but do not change the predicted size scores.
- Hosted validation is challenged on likely retest-loop and host-behavior cost, not raw case count. Current evidence supports `Validation Burden Risk = 3`, not `4`, until a blocker, special setup, repeated host fix loop, or interpretation problem appears.
<!-- SIZE:CHALLENGE:END -->

---

<!-- SIZE:DRIFT:START -->
## Drift Log

> Append only. Log only material changes that affect estimate shape, risk, confidence, or validation burden.

| Date | Phase / Checkpoint | Event Type | Severity (1-3) | Dimension Affected | Predictable Earlier? | Notes |
|---|---|---|---:|---|---|---|
| 2026-04-29 | Hosted validation | validation-discovered-representation-gap | 2 | Validation Burden, Rework, Discovery | Partly | Live MCP off-grid boundary cases showed controls could be reported satisfied against the mathematical plane while public surface sampling disagreed because unchanged neighboring heightmap samples influenced interpolation. Follow-up added `planar_fit_unsafe` refusal and docs, then hosted validation passed. |

### Drift Notes
- One material validation-driven drift event occurred. It matched the predicted representation-limit breaker in class, but the exact off-grid boundary sampling mismatch required live host evidence.
<!-- SIZE:DRIFT:END -->

---

<!-- SIZE:ACTUAL:START -->
## Actual Profile

> Filled at the end of implementation. Do not overwrite predicted values.

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Shipped one new public terrain edit intent with request fields, refusals, evidence, docs, and hosted proof. Scope stayed within the planned rectangle/circle `heightmap_grid` v1 slice. |
| Technical Change Surface | 4 | Actual changes spanned validator constants/normalization, native schema, command dispatch, a new terrain editor, evidence shaping, native fixtures, docs, public contract tests, and terrain-domain tests. |
| Actual Implementation Friction | 3 | Core least-squares math and edit wiring were manageable, but preserving fixed/preserve semantics, refusal ordering, discrete-surface representability, and no-leak evidence required meaningful engineering work. |
| Actual Validation Burden | 3 | Automated validation was broad and green, and hosted validation found one material off-grid boundary defect that required a fix/docs/retest loop. This is above routine hosted matrix burden but did not become repeated-loop validation. |
| Actual Dependency Drag | 2 | Implementation depended on existing terrain output, region influence, fixed-control evaluation, native wrapper/schema refresh, and separate live SketchUp validation, but no upstream redesign was needed. |
| Actual Discovery Encountered | 3 | The off-grid boundary mismatch was a significant live-discovered representation nuance: mathematical plane residuals were not enough to guarantee public sampled-surface satisfaction. |
| Actual Scope Volatility | 2 | Scope stayed within the explicit planar intent, but the behavior grew a new safety refusal and docs requirement for discrete heightmap representability. |
| Actual Rework | 2 | Rework was contained to the planar editor, one regression test, docs, and validation reruns after the hosted issue. No broad redesign or split was required. |
| Final Confidence in Completeness | 3 | Confidence is strong after full automated validation and hosted matrix validation with post-fix retest. It is not scored 4 because the external PAL expert review was blocked by provider quota and native transport fixture tests still skip without staged vendor runtime. |

### Actual Notes
- Dominant actual failure mode: public evidence based only on fitted-plane residuals can overclaim satisfaction when the discrete heightmap surface cannot sample the accepted controls back within tolerance.
- Main implementation lesson: planar-control evidence for `heightmap_grid` edits must validate the edited sampled surface, not only the mathematical plane.
- Hosted validation cost was driven by one fix loop, not by raw case count.
<!-- SIZE:ACTUAL:END -->

---

<!-- SIZE:VALIDATION-EVIDENCE:START -->
## Validation Evidence Summary

> Fill only the sections that are relevant. Say `not applicable` where needed.

### Automated Validation
- Focused planar/runtime skeleton suite passed after off-grid follow-up: 154 runs, 948 assertions, 0 failures, 32 skips.
- Broader terrain/runtime suite passed after off-grid follow-up: 383 runs, 2593 assertions, 0 failures, 35 skips.
- Full Ruby test suite passed after off-grid follow-up: 826 runs, 4253 assertions, 0 failures, 37 skips.
- `bundle exec rake ruby:lint` passed: 206 files inspected, no offenses.
- `bundle exec rake package:verify` passed and produced `dist/su_mcp-1.0.0.rbz`.
- `git diff --check` passed.

### Hosted / Manual Validation
- Live SketchUp public MCP matrix passed after one validation-driven fix loop.
- Covered rectangle/circle planar fits, smooth blend, near-coplanar success, preserve-zone protection, fixed-control compatibility/conflict, non-zero origin, transformed owner evidence, non-uniform/fractional spacing, sample evidence caps, survey regression, refusal paths, close-control warning, no-leak checks, undo, mesh sanity, and crossfall/coplanarity/region-shape matrices.
- Hosted validation found the off-grid boundary representation issue before the follow-up fix; post-fix validation confirmed the matrix is complete.

### Performance Validation
- Hosted 100x100 terrain planar edit completed in about 2.07 seconds and regenerated 19602 faces.
- Mesh sanity checks across inspected terrain outputs found no down-facing faces, no flat/down faces, and no unmanaged child groups/components.

### Migration / Compatibility Validation
- No persisted terrain schema migration was introduced; terrain state remains `heightmap_grid` schema version 1.
- Existing `survey_point_constraint` behavior remained separate and continued to return `evidence.survey` without `evidence.planarFit`.
- Native wrapper/schema refresh exposed `planar_region_fit` and `constraints.planarControls`.

### Operational / Rollout Validation
- Public docs, native schema, runtime validation, dispatcher, evidence, contract fixtures, and tests were updated together.
- Package verification passed for the staged RBZ.
- External PAL expert code review was attempted but blocked by provider quota.

### Validation Notes
- Validation burden was high enough to score 3 because live validation discovered a defect and required one fix/retest loop.
- The large hosted matrix itself is not treated as high burden by case count alone; the burden came from the off-grid representation issue and follow-up.
<!-- SIZE:VALIDATION-EVIDENCE:END -->

---

<!-- SIZE:DELTA:START -->
## Estimation Delta Review

> Filled during final calibration. Compare prediction to actual behavior.

### Prediction Accuracy
- Functional scope matched prediction (`3 -> 3`): the task shipped the planned narrow public terrain edit intent.
- Technical change surface matched prediction (`4 -> 4`): public contract breadth drove changes across runtime, schema, dispatcher, evidence, docs, fixtures, and tests.
- Implementation friction matched high prediction (`3 -> 3`): core math was straightforward, but discrete heightmap representability and safety evidence created real resistance.
- Validation burden matched high prediction but for a concrete reason (`3 -> 3`): hosted validation found one defect and required a fix loop.
- Dependency drag matched prediction (`2 -> 2`): live SketchUp access and existing terrain seams mattered, but no upstream redesign was needed.
- Discovery was slightly higher in concrete impact (`2 -> 3`): the off-grid boundary evidence/sampling mismatch was not resolved by planning alone.
- Scope volatility stayed moderate (`2 -> 2`): the task did not widen into localized detail zones, but it added a safety refusal.
- Rework was lower than worst-risk prediction (`3 -> 2`): the live issue was contained and did not force redesign.
- Confidence improved from planning (`3 -> 3 actual, stronger evidence`): live validation and full local validation support completion, with remaining confidence held below 4 by the blocked external expert review.

### Underestimated
- The exact interaction between off-grid boundary controls, hard edit regions, and public surface sampling was underweighted. Planning anticipated grid-spacing limits, but not the evidence overclaim risk from satisfying the mathematical plane while the discrete mesh interpolation disagreed.

### Overestimated
- Broad solver rework and constrained optimization risk were overestimated. The final fix was a representability refusal, not a new optimizer or terrain representation.

### Early-Visible Signals
- The predicted estimate breaker about `heightmap_grid` spacing and representative planar-fit expectations was the right warning class.
- The challenge review correctly emphasized full-weight/blend/preserve evidence and not overclaiming planarity.

### Unknowable Until Validation
- The exact off-grid boundary mismatch required live public sampling against regenerated SketchUp output; unit tests and mathematical residual checks alone would not have exposed the host-facing evidence mismatch.

### Future Analog Guidance
- Treat future public terrain edit modes that claim sampled control satisfaction as `heightmap_grid` representability tasks, not only numerical solver tasks.
- Require hosted matrix cases that sample accepted controls back through the public MCP surface, especially off-grid and boundary cases.
- Retrieval facets: `scope:managed-terrain`, `systems:terrain-kernel`, `systems:terrain-output`, `contract:public-tool`, `validation:hosted-matrix`, `host:single-fix-loop`, and representation/sampling mismatch notes.
<!-- SIZE:DELTA:END -->

---

<!-- SIZE:TAGS:START -->
## Retrieval Tags

- `archetype:feature`
- `scope:managed-terrain`
- `systems:terrain-state`
- `systems:terrain-kernel`
- `systems:terrain-output`
- `systems:loader-schema`
- `systems:public-contract`
- `systems:surface-sampling`
- `validation:contract`
- `validation:hosted-matrix`
- `validation:performance`
- `host:single-fix-loop`
- `contract:public-tool`
- `contract:loader-schema`
- `contract:response-shape`
- `risk:contract-drift`
- `volatility:medium`
- `friction:medium`
- `rework:medium`
- `confidence:high`
<!-- SIZE:TAGS:END -->
