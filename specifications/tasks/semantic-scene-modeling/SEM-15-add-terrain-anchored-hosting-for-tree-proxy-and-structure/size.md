# Size: SEM-15 Add Terrain-Anchored Hosting for Tree Proxy and Structure

**Task ID**: SEM-15  
**Title**: Add Terrain-Anchored Hosting for Tree Proxy and Structure  
**Status**: calibrated
**Created**: 2026-04-24  
**Last Updated**: 2026-04-25

**Related Task**: [task.md](./task.md)  
**Related Plan**: [plan.md](./plan.md)  
**Related Summary**: [summary.md](./summary.md)

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
| 2026-04-25 | Pre-implementation Grok review | validation-scope refinement | 1 | Technical Change Surface / Validation Burden | Yes | Added explicit hosted `replace_preserve_identity` coverage and no-wrapper-created failure assertions before implementation. This refined the queue but did not materially change predicted scores. |

### Drift Notes
- No material score drift recorded; the implementation stayed within the predicted shape.
<!-- SIZE:DRIFT:END -->

---

<!-- SIZE:ACTUAL:START -->
## Actual Profile

> Filled at the end of implementation. Do not overwrite predicted values.

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | 2 | Delivered one existing hosting mode for two existing families plus hosted replacement parity. |
| Technical Change Surface | 3 | Touched resolver support, two builders, command matrix/replace context, loader guidance, README, and tests. |
| Actual Implementation Friction | 2 | Existing sampler/refusal patterns fit well; main friction was tightening no-partial-wrapper ordering and lint shape. |
| Actual Validation Burden | 3 | Focused unit/command/native/lint checks and live SketchUp verification passed. |
| Actual Dependency Drag | 1 | No upstream dependency blocked implementation; live SketchUp evidence was supplied at closeout. |
| Actual Discovery Encountered | 2 | Grok review identified hosted replacement and no-wrapper-created assertions before code changes. |
| Actual Scope Volatility | 1 | Scope stayed bounded to tree_proxy and structure; no additional terrain families were added. |
| Actual Rework | 1 | Minor refactoring for lint and clearer resolver keyword naming. |
| Final Confidence in Completeness | 4 | Automated coverage, review, package verification, and live SketchUp checks all passed. |

### Actual Signals
- Shared single-point resolver worked without adding a new public tool or schema enum.
- Builder-level sampling before wrapper creation is the cleanest way to satisfy no-partial-geometry behavior in automated tests.
- Hosted replacement needed explicit command-context parity once terrain anchoring became supported.

### Actual Notes
- Implementation is complete through automated validation, post-implementation review, and live SketchUp checks.
<!-- SIZE:ACTUAL:END -->

---

<!-- SIZE:VALIDATION-EVIDENCE:START -->
## Validation Evidence Summary

> Fill only the sections that are relevant. Say `not applicable` where needed.

### Automated Validation
- Focused semantic/native suite passed:
  - `bundle exec ruby -Itest -e 'ARGV.each { |path| load path }' test/semantic/terrain_anchor_resolver_test.rb test/semantic/tree_proxy_builder_test.rb test/semantic/structure_builder_test.rb test/semantic/semantic_commands_test.rb test/runtime/native/mcp_runtime_loader_test.rb`
- Focused RuboCop passed with repo-local cache:
  - `RUBOCOP_CACHE_ROOT=tmp/.rubocop_cache bundle exec rubocop src/su_mcp/semantic/terrain_anchor_resolver.rb src/su_mcp/semantic/tree_proxy_builder.rb src/su_mcp/semantic/structure_builder.rb src/su_mcp/semantic/semantic_commands.rb src/su_mcp/runtime/native/mcp_runtime_loader.rb test/semantic/terrain_anchor_resolver_test.rb test/semantic/tree_proxy_builder_test.rb test/semantic/structure_builder_test.rb test/semantic/semantic_commands_test.rb test/runtime/native/mcp_runtime_loader_test.rb`

### Manual Validation
- Live SketchUp checks passed:
  - P1 tree anchored on sloped terrain: lower Z 3.54m matched host sample at (56,76).
  - P2 structure centroid anchored: lower Z 3.94m matched centroid sample at (57.5,76.5).
  - N1 unsampleable host refusal: `invalid_hosting_target`.
  - N2 sample-miss refusal: `terrain_sample_miss`.
  - N3 unsupported-family refusal: `unsupported_hosting_mode`.
  - E1 partial footprint with centroid inside: lower Z 4.04m matched centroid sample at (58,76.5).
  - E2 explicit conflicting tree z: input z=50 was ignored; final lower Z 4.14m matched hosted sample.
  - E3 host target by `sourceElementId`: source-id host resolved and tree lower Z 3.74m matched sample.
  - Additional matrix checks passed for persistentId host targeting, missing/stale/ambiguous host refusals, hidden and locked explicit hosts, invalid tree and structure dimensions, invalid structure geometry, missing tree position, and refusal atomicity.
  - Minor API consistency observation: missing tree `definition.position` refused as `invalid_numeric_value` rather than `missing_required_field`.

### Performance Validation
- No dedicated performance benchmark. Resolver tests verify one prepared sampling context per single terrain anchor resolve.

### Migration / Compatibility Validation
- Public request and response shapes are unchanged. Schema enum is unchanged; contextual hosting matrix and guidance were updated.

### Operational / Rollout Validation
- Package verification passed. Live SketchUp checks passed.

### Validation Notes
- Automated validation, post-implementation Grok-4.20 review, and live SketchUp verification are complete for the changed Ruby surface.
<!-- SIZE:VALIDATION-EVIDENCE:END -->

---

<!-- SIZE:DELTA:START -->
## Estimation Delta Review

> Filled during final calibration. Compare prediction to actual behavior.

- **Most Underestimated Dimension**: Hosted lifecycle parity; `replace_preserve_identity` needed explicit hosting-context handling once the matrix expanded.
- **Most Overestimated Dimension**: Implementation friction; existing sampler/refusal seams kept the code path small.
- **Signal Present Early But Underweighted**: The public `create_site_element` surface includes lifecycle and hosting together, so hosted replace needed to be considered with hosted create.
- **Genuinely Unknowable Factor**: Real SketchUp terrain sampling and abort behavior on live terrain was the main unknowable factor; supplied live checks passed representative success, refusal, host-state, target-resolution, geometry, and atomicity cases.
- **Future Similar Tasks Should Assume**: Any hosting-matrix expansion should include create, replace, unsupported-family, no-partial-wrapper, docs, and loader discoverability checks in the first skeleton pass.

### Calibration Notes
- Actual profile matched the predicted moderate feature / high validation shape. Live SketchUp evidence is now recorded.
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
- `confidence:high-pending-live`
<!-- SIZE:TAGS:END -->
