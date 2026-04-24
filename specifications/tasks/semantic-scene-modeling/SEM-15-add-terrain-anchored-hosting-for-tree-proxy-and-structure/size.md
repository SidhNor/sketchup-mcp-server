# Size: SEM-15 Add Terrain-Anchored Hosting for Tree Proxy and Structure

**Task ID**: SEM-15  
**Title**: Add Terrain-Anchored Hosting for Tree Proxy and Structure  
**Status**: challenged  
**Created**: 2026-04-24  
**Last Updated**: 2026-04-24  

**Related Task**: [task.md](./task.md)  
**Related Plan**: [plan.md](./plan.md)  
**Related Summary**: none yet  

---

<!-- SIZE:IDENTITY:START -->
## Identity

- **Task Archetype**: feature
- **Primary Scope Area**: semantic scene modeling hosted creation
- **Likely Systems Touched**:
  - `create_site_element` semantic runtime hosting matrix
  - `tree_proxy` builder terrain anchoring
  - `structure` builder terrain anchoring
  - semantic refusals, loader guidance, tests, and docs
- **Validation Class**: mixed
- **Likely Analog Class**: bounded hosted semantic behavior expansion

### Identity Notes
- Task-level evidence points to a bounded hosted-execution expansion for two existing semantic families, not a new creation tool or terrain-authoring surface.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 2 | Adds one hosting mode to two existing families while preserving the existing semantic creation surface. |
| Technical Change Surface | 3 | Likely touches runtime hosting support, two builders, terrain height resolution, refusals, tests, docs, and hosted verification. |
| Hidden Complexity Suspicion | 3 | Terrain height sampling, host target validity, planar structure anchoring semantics, and partial-creation safety can hide edge cases. |
| Validation Burden Suspicion | 3 | Requires automated success/refusal coverage plus live or hosted SketchUp checks proving geometry lands on terrain. |
| Dependency / Coordination Suspicion | 2 | Depends on existing hosted behavior, terrain-sensitive path work, and hardened create-site-element request boundaries. |
| Scope Volatility Suspicion | 2 | Clear non-goals bound the task, but pressure could expand toward draped structures or other terrain-hosted families. |
| Confidence | 2 | The task is well bounded, but seed evidence is limited to `task.md` and source context without a technical plan. |

### Early Signals
- Runtime currently advertises `terrain_anchored` in the schema-level enum but has no supported family in the execution matrix.
- The task explicitly limits structure behavior to one planar terrain-derived base elevation.
- Acceptance criteria require structured hosting refusals and live or hosted SketchUp verification.
- Non-goals exclude additional families and terrain authoring behavior.

### Early Estimate Notes
- Early shape is moderate functionally but higher in validation and hidden-complexity risk because terrain anchoring must be real, bounded, refusal-safe, and observable in SketchUp.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

> Filled during task planning. This is the main pre-implementation estimate.

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | 2 | Adds one existing hosting mode to two existing semantic families without adding a new public tool or new family. |
| Technical Change Surface | 3 | Touches hosting matrix enforcement, a new shared terrain-anchor helper, two builders, refusals, README/loader guidance, and tests. |
| Implementation Friction Risk | 2 | Existing `SurfaceHeightSampler` and `BuilderRefusal` patterns reduce novelty, but sampled elevation must be integrated without fallback or partial geometry. |
| Validation Burden Risk | 3 | Requires unit, command, native contract/guidance checks, and live or hosted SketchUp verification on real terrain behavior. |
| Dependency / Coordination Risk | 2 | Depends on shipped SEM-09/13/14 behavior and access to live or hosted SketchUp checks, but no external product dependency is unresolved. |
| Discovery / Ambiguity Risk | 2 | Main semantics are resolved, including centroid sampling and tree z replacement, but real host sampling and cleanup behavior remain to prove. |
| Scope Volatility Risk | 2 | Non-goals bound planting drape and richer terrain behavior, though related terrain-hosting pressure is visible. |
| Rework Risk | 2 | Rework is likely contained unless live SketchUp sampling exposes transform, face-classification, or cleanup issues. |
| Confidence | 3 | Draft plan is detailed and Grok review found no blockers, but confidence stays below very high until live host behavior is validated. |

### Top Assumptions
- `SurfaceHeightSampler` can be reused for single-point terrain anchoring without introducing a public `sample_surface_z` dependency.
- `tree_proxy` terrain anchoring should replace caller `position.z`, not add it as an offset.
- `structure` terrain anchoring can use the arithmetic mean of footprint vertices as the planar base sample point.
- Existing operation abort behavior prevents partial managed geometry when builder-owned terrain-anchor refusals are raised.

### Estimate Breakers
- Real SketchUp terrain sampling behaves differently from fake tests for nested transforms or face classification.
- Structure centroid sampling proves unacceptable for representative non-rectangular or concave footprints.
- Hosted failure paths leave empty wrapper groups or partial geometry despite operation abort handling.
- Contract/doc updates reveal broader public guidance drift around contextual hosting modes.

### Predicted Signals
- `SUPPORTED_HOSTING_MODES` must expand in a contextual way without widening all families.
- Two builders need the same sampled-elevation behavior, motivating a shared internal helper.
- Existing SEM-13 terrain sampling and refusal patterns are reusable but not identical to single-point anchoring.
- Validation must include live or hosted SketchUp checks after review findings are addressed.
- `planting_mass + surface_drape` was identified and intentionally deferred to avoid scope bleed.

### Predicted Estimate Notes
- Predicted size is moderate in functional scope and implementation friction, but high in technical surface and validation burden because the behavior changes a public hosted-creation matrix and must be proven in real SketchUp terrain conditions.
<!-- SIZE:PREDICTED:END -->

---

<!-- SIZE:CHALLENGE:START -->
## Challenge Review

> Filled when the estimate is pressure-tested through external review, premortem, or controlled consensus.

### Agreed Drivers
- Functional scope remains moderate because the task adds one existing hosting mode to two existing families without a new tool or family.
- Technical change surface remains high because runtime matrix behavior, a new helper, two builders, tests, loader guidance, and README guidance must move together.
- Validation burden remains high because fake tests are insufficient for terrain anchoring; live or hosted SketchUp checks are required.
- Scope volatility is contained by explicitly deferring `planting_mass + surface_drape` and per-vertex structure drape.

### Contested Drivers
- Whether arithmetic-mean centroid sampling is enough for all representative structure footprints remains a product/geometry semantics risk, especially for concave or irregular footprints.
- Whether operation abort behavior fully prevents empty wrapper groups on builder-owned terrain refusals must be proven rather than assumed.
- Whether `SurfaceHeightSampler` behavior under real nested/transformed SketchUp terrain matches fake-test behavior remains unproven until live validation.

### Missing Evidence
- Live or hosted SketchUp evidence for tree anchoring on sloped terrain.
- Live or hosted SketchUp evidence for structure centroid anchoring on sloped terrain.
- Failure-path evidence that unsampleable hosts and sample misses leave no partial geometry.
- Final README/loader/contract review evidence after implementation changes are made.

### Recommendation
- Confirm the predicted profile without score changes. Keep the task as one bounded implementation, but do not close it without live or hosted SketchUp verification and contract/docs parity evidence.

### Challenge Notes
- Grok-4.20 review found no blockers and recommended tightening the resolver API, centroid definition, builder params contract, test matrix, and docs/loader sync; those points were incorporated into the finalized plan.
- Premortem findings reinforced the predicted validation burden and host-behavior uncertainty rather than justifying a resize.
- No challenge evidence currently supports splitting the task or changing predicted scores before implementation.
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
| Functional Scope | <0-4> | <short note> |
| Technical Change Surface | <0-4> | <short note> |
| Actual Implementation Friction | <0-4> | <short note> |
| Actual Validation Burden | <0-4> | <short note> |
| Actual Dependency Drag | <0-4> | <short note> |
| Actual Discovery Encountered | <0-4> | <short note> |
| Actual Scope Volatility | <0-4> | <short note> |
| Actual Rework | <0-4> | <short note> |
| Final Confidence in Completeness | <0-4> | <short note> |

### Actual Signals
- Not filled yet.

### Actual Notes
- Not filled yet.
<!-- SIZE:ACTUAL:END -->

---

<!-- SIZE:VALIDATION-EVIDENCE:START -->
## Validation Evidence Summary

> Fill only the sections that are relevant. Say `not applicable` where needed.

### Automated Validation
- Not filled yet.

### Manual Validation
- Not filled yet.

### Performance Validation
- Not filled yet.

### Migration / Compatibility Validation
- Not filled yet.

### Operational / Rollout Validation
- Not filled yet.

### Validation Notes
- Not filled yet.
<!-- SIZE:VALIDATION-EVIDENCE:END -->

---

<!-- SIZE:DELTA:START -->
## Estimation Delta Review

> Filled during final calibration. Compare prediction to actual behavior.

- **Most Underestimated Dimension**: <dimension + why>
- **Most Overestimated Dimension**: <dimension + why>
- **Signal Present Early But Underweighted**: <note>
- **Genuinely Unknowable Factor**: <note or `none identified`>
- **Future Similar Tasks Should Assume**: <note>

### Calibration Notes
- <short note>
<!-- SIZE:DELTA:END -->

---

<!-- SIZE:TAGS:START -->
## Retrieval Tags

- `archetype:feature`
- `scope:semantic-scene-modeling`
- `validation:mixed`
- `systems:create-site-element`
- `systems:semantic-hosting`
- `systems:tree-proxy-builder`
- `systems:structure-builder`
- `volatility:medium`
- `friction:medium`
- `rework:unknown`
- `confidence:medium`
<!-- SIZE:TAGS:END -->
