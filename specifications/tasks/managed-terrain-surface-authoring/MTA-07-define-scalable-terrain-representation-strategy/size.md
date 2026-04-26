# Size: MTA-07 Define Scalable Terrain Representation Strategy

**Task ID**: `MTA-07`  
**Title**: `Define Scalable Terrain Representation Strategy`  
**Status**: `calibrated`
**Created**: `2026-04-26`  
**Last Updated**: `2026-04-26`  

**Related Task**: [task.md](./task.md)  
**Related Plan**: [plan.md](./plan.md)
**Related Summary**: [summary.md](./summary.md)

---

<!-- SIZE:IDENTITY:START -->
## Identity

- **Task Archetype**: platform / performance-sensitive prep
- **Primary Scope Area**: managed terrain scalable representation and output-generation foundation
- **Likely Systems Touched**:
  - terrain representation strategy and future state boundaries
  - SketchUp-free terrain window / changed-region domain primitives
  - derived output generation seam and current regular-grid output behavior
  - terrain evidence vocabulary and public contract stability
  - terrain repository / serializer migration-baseline checks
  - hosted SketchUp bulk-mesh and regeneration validation
- **Validation Class**: mixed / performance-sensitive / manual-heavy
- **Likely Analog Class**: performance-sensitive terrain foundation with hosted output validation

### Identity Notes
- Planning refinement changed this from a strategy-only task into strategy plus a bounded preparatory implementation slice. The current shape keeps `heightmap_grid` / heightmap-derived managed state authoritative, keeps SketchUp TIN output disposable, adds internal terrain window / changed-region primitives, adds a behavior-preserving mesh output seam, and requires live SketchUp validation of a bulk mesh candidate.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Selects a long-term localized-detail direction and adds tangible prep work, but public terrain tool request shape is expected to remain stable. |
| Technical Change Surface | 3 | Likely touches terrain domain primitives, mesh generation seam, evidence stability checks, repository/serializer guardrails, and tests, but does not intentionally change persisted schema or public contracts. |
| Hidden Complexity Suspicion | 4 | Boundary conversion, changed-region semantics, mesh seam equivalence, SketchUp bulk mesh behavior, undo, and derived-output marking can all hide host-specific complexity. |
| Validation Burden Suspicion | 4 | Requires unit tests, contract/evidence stability checks, repository round-tripping, live SketchUp output/regeneration/undo validation, and performance timing for bulk mesh. |
| Dependency / Coordination Suspicion | 3 | Depends on MTA-02/MTA-03 foundations, MTA-04 edit direction, current MCP terrain vocabulary, SketchUp hosted test access, and informs MTA-05/MTA-06 sequencing. |
| Scope Volatility Suspicion | 3 | Scope has been narrowed to CC prep, but production bulk adoption, failed host validation, or evidence-shape drift could still force split or deferral decisions. |
| Confidence | 3 | Planning has stronger evidence after UE source review, PAL consensus, and Step 05 refinement, but hosted bulk-mesh behavior remains unproven. |

### Early Signals
- MTA-03 performance improved materially, but repeated near-cap full terrain regeneration remains expensive enough to justify output-path and localized-detail preparation.
- Step 05 refinement selected heightmap-derived managed state as the source of truth and explicitly rejected generated SketchUp TIN geometry as durable terrain state.
- User direction changed the task from research-only toward a more palpable CC prep slice: terrain window / changed-region primitives, mesh-generation seam, and live SketchUp bulk-mesh validation.
- PAL consensus supported the long-term base-plus-localized-detail direction while warning that mesh generation and public evidence vocabulary need strict boundaries.
- The current public terrain vocabulary uses owner-local meter `region.bounds` and result sections such as `operation`, `managedTerrain`, `terrainState`, `output`, and `evidence`; internal sample windows must not leak into the public contract accidentally.
- Current `TerrainMeshGenerator` produces regular-grid TIN output through per-face SketchUp calls, making bulk mesh validation useful but host-sensitive.
- UE source review supports rectangular read/write regions, componentized data, affected-region updates, and patch/layer concepts, but not renderer LOD or generated mesh identity as product architecture.

### Early Estimate Notes
- This reseed is a pre-prediction planning rebaseline, not implementation drift. The updated shape is no longer documentation-only, but it also intentionally avoids full localized-detail persistence, partial regeneration, new public tool fields, and persisted payload-kind/schema changes.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

> Filled during task planning. This is the main pre-implementation estimate.

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Selects the scalable representation direction and delivers tangible prep work, but avoids new public tool fields, persisted schema changes, partial regeneration, and full localized-detail implementation. |
| Technical Change Surface | 3 | Touches terrain domain primitives, mesh generation structure, evidence/contract stability tests, repository/serializer guardrails, and hosted validation, without intentionally widening runtime routing or public schemas. |
| Implementation Friction Risk | 3 | Window conversion, changed-region normalization, behavior-preserving mesh seam extraction, and bulk candidate isolation can expose coupling in current terrain generation and edit code. |
| Validation Burden Risk | 4 | Correctness depends on unit tests, public vocabulary stability, serializer/repository regression, mesh equivalence, and live SketchUp timing/undo/entity checks for per-face and bulk paths. |
| Dependency / Coordination Risk | 3 | Depends on MTA-02/MTA-03 foundations, MTA-04 edit direction, current MCP terrain vocabulary, available live SketchUp validation, and must inform MTA-05/MTA-06 sequencing. |
| Discovery / Ambiguity Risk | 3 | Step 05 resolved the architecture, but bulk mesh host behavior, exact seam shape, and whether production adoption is safe remain implementation-time discoveries. |
| Scope Volatility Risk | 3 | Scope is bounded as CC prep, but failed or surprisingly successful bulk validation could split, defer, or expand the output path decision. |
| Rework Risk | 3 | A weak mesh seam, leaked public evidence vocabulary, or incorrect bounds semantics would require revisiting early primitives and tests before downstream edit kernels consume them. |
| Confidence | 3 | Planning evidence is strong after UE source review, PAL consensus, reseeding, and draft plan creation; confidence is capped because the highest-risk output behavior must be proven live. |

### Top Assumptions

- Managed source state remains `heightmap_grid` / heightmap-derived; generated SketchUp TIN never becomes durable source state.
- The prep slice can keep public terrain request vocabulary and persisted payload schema unchanged.
- Internal terrain window / changed-region primitives can be introduced without forcing MTA-05/MTA-06 to wait for full localized-detail persistence.
- `TerrainMeshGenerator` can gain a behavior-preserving seam while keeping the current per-face output path as fallback.
- Live SketchUp validation access is available for near-cap per-face and bulk mesh output checks.

### Estimate Breakers

- Bulk mesh validation reveals SketchUp API behavior that requires broad output ownership, material/attribute propagation, undo, or cleanup redesign.
- The mesh seam cannot be extracted without changing current generated output summaries, derived-output marking, or regeneration refusal behavior.
- Public evidence needs new fields or renamed structures, forcing loader schema, contract fixtures, docs, and example updates into MTA-07.
- Existing `heightmap_grid` serializer/repository assumptions are insufficient for the prep primitives, forcing a payload schema or dispatch change.
- Live validation shows near-cap generation remains unacceptable even with the seam, creating pressure to implement partial regeneration or tiled output now.

### Predicted Signals

- Calibrated MTA-02 shows terrain state/storage foundations carry high validation and rework sensitivity even before public behavior.
- Calibrated MTA-03 shows live SketchUp can expose unit conversion, boundary sampling, performance, source replacement, and persistence issues that local tests miss.
- MTA-04 planning keeps full regeneration for bounded edit MVP but flags output cleanup/regeneration and hosted timing as high-risk validation surfaces.
- STI-03 and SVR-04 analogs show terrain/surface evidence features require hosted checks and performance evidence despite bounded functional scope.
- PAL consensus agreed with the long-term base-plus-localized-detail direction while contesting how much mesh generation work should be included, indicating real scope-volatility and validation pressure.

### Predicted Estimate Notes

- This prediction uses the post-reseed CC scope as the current planning baseline: strategy plus internal primitives, behavior-preserving mesh seam, and live bulk-mesh validation.
- Functional scope is high but not very high because the task deliberately avoids a new public tool contract and full localized-detail storage.
- Validation burden is the dominant driver because production readiness depends on hosted SketchUp behavior that cannot be proven by Ruby unit tests alone.
- Confidence is moderate-high for direction and moderate for delivery because bulk mesh behavior and seam extraction still need implementation evidence.
<!-- SIZE:PREDICTED:END -->

---

<!-- SIZE:CHALLENGE:START -->
## Challenge Review

> Filled when the estimate is pressure-tested through external review, premortem, or controlled consensus.

### Agreed Drivers
- The task is no longer strategy-only: it includes internal terrain window / changed-region primitives, a behavior-preserving mesh generation seam, and live SketchUp validation of a bulk mesh candidate.
- Public contract stability is central to the estimate. The plan intentionally avoids new public request fields, new persisted payload kind/schema, and new public evidence vocabulary unless explicitly revised.
- Validation burden is the dominant cost driver because mesh output behavior, undo, entity cleanup, and bulk mesh viability must be proven in live SketchUp.
- Calibrated MTA-02 and MTA-03 support the prediction that terrain state/output work has high validation and rework sensitivity even when the functional surface is bounded.
- MTA-04 implementation evidence reinforces the predicted validation burden: live SketchUp checks found face-winding inconsistencies in generated terrain output, and the fix made positive-Z face normals and derived face/edge marking part of the output seam invariants.
- MTA-04 also gives the changed-region primitive a concrete integration point in `BoundedGradeEdit`, reducing the risk that MTA-07 creates a standalone abstraction with no current consumer.
- The premortem correctly tightened the plan by requiring the new primitives to connect to a current integration seam, avoiding a speculative abstraction-only slice.

### Contested Drivers
- Bulk mesh adoption remains contested. `gpt-5.4` and `grok-4` supported making bulk generation a meaningful prep target, while `grok-4.20` warned that adopting or deeply reshaping the output path could become a hidden rewrite.
- The challenged plan resolves this by requiring live validation and keeping current per-face output as fallback; production bulk adoption is allowed only if equivalence is proven and recorded.
- The exact implementation shape of the mesh seam remains a friction risk. The premortem added the full-grid region descriptor guardrail so the seam is tangible without forcing partial regeneration.
- Scope volatility remains material but bounded: failed bulk validation should defer adoption, while successful validation may still require a deliberate production-switch decision.

### Missing Evidence
- Live SketchUp comparison of per-face output and bulk mesh candidate on small, non-square representative, and near-cap terrain cases.
- Evidence that the output seam preserves derived-output marking, face/vertex counts, digest linkage, regeneration refusal, and undo behavior.
- Evidence that the output seam preserves positive-Z terrain face-normal orientation and derived marking on both faces and edges.
- Evidence that internal terrain window / changed-region primitives integrate with the mesh seam, and with edit changed-region calculation if that path is present in the implementation baseline.
- Confirmation that no public response vocabulary or persisted payload schema change is needed after implementation starts.
- Save/reopen behavior if production output switches to bulk mesh.

### Recommendation
- Confirm the predicted profile without score changes.
- Proceed with the finalized plan, but treat live SketchUp validation as a hard implementation gate before any production bulk-output adoption.
- Do not split before implementation. Split or defer only if bulk mesh validation, public evidence shape, or persistence requirements force behavior beyond the finalized non-goals.

### Challenge Notes
- No predicted scores changed after premortem and challenge review. Validation burden was already `4`, and friction, discovery, volatility, and rework were already scored `3`.
- The premortem added guardrails and validation specificity rather than materially expanding the task: primitives must connect to the mesh seam, and live validation must cover small, non-square, and near-cap cases.
- Challenge evidence preserves the main disagreement from PAL consensus: how far to go on bulk mesh. The plan carries that disagreement as a gated validation/rollout decision instead of assuming success.
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
| Functional Scope | 3 | Delivered the planned representation direction and bounded prep foundation: sample windows, changed-region integration, output plan seam, and validation-only bulk candidate. No public tool or persisted schema expansion occurred. |
| Technical Change Surface | 3 | Touched terrain domain primitives, edit diagnostics, mesh generation summary seam, validation-only output path, terrain tests, and task metadata. Runtime routing, public schemas, repository dispatch, and persisted payload shape stayed unchanged. |
| Actual Implementation Friction | 1 | Implementation followed the corrected queue smoothly. The only friction was routine: queue ordering was clarified before edits, the bulk-candidate skeleton was added before implementation, and local RuboCop shape issues were cleaned up. No architectural redesign or behavioral fix was required. |
| Actual Validation Burden | 2 | Required focused TDD baselines, full Ruby tests, lint, package verification, contract/no-drift tests, `grok-4.20` codereview, public MCP hosted validation, greybox bulk-candidate comparison, high-variation terrain checks, undo checks, responsiveness checks, and performance timing, but the hosted matrix ran cleanly without fix/redeploy/retest loops. |
| Actual Dependency Drag | 2 | Work depended on MTA-02/MTA-03/MTA-04 terrain foundations and external review. Live SketchUp validation access remains a follow-up gap, but no upstream code dependency blocked the local implementation. |
| Actual Discovery Encountered | 1 | Discovery was low. The only meaningful clarification was that persisted v2/chunked state was intentionally out of scope and contract/no-drift skeletons should lead the queue. No hidden serializer, host API, or public contract requirement emerged. |
| Actual Scope Volatility | 1 | Scope stayed within the finalized prep slice. The queue changed order and gained an explicit bulk-candidate skeleton before implementation, but no split, production adoption, or persisted representation expansion was needed. |
| Actual Rework | 0 | No production slice required rework. `grok-4.20` code review found no required fixes; the only follow-up was an optional guardrail comment and routine lint cleanup. |
| Final Confidence in Completeness | 4 | Confidence is high for the prep slice and contract preservation, backed by tests, lint, package verification, codereview, public MCP hosted validation, greybox bulk-candidate comparison, high-relief checks, undo checks, and responsiveness checks. |
<!-- SIZE:ACTUAL:END -->

---

<!-- SIZE:VALIDATION-EVIDENCE:START -->
## Validation Evidence Summary

> Fill only the sections that are relevant. Say `not applicable` where needed.

### Automated Validation
- Focused MTA-07 terrain set: `26 runs, 83 assertions, 0 failures, 0 errors, 1 skip`.
- `bundle exec rake ruby:test`: `633 runs, 2419 assertions, 0 failures, 0 errors, 32 skips`.
- `bundle exec rake ruby:lint`: `170 files inspected, no offenses`.
- `bundle exec rake package:verify`: passed and produced `dist/su_mcp-0.21.0.rbz`.
- `mcp__pal__.codereview` with `grok-4.20`: completed with no required fixes.

### Manual Validation
- Live SketchUp production MCP path passed after scene reset for small 4x3, non-square 17x9, and near-cap 100x100 terrain.
- Public sampling confirmed edited regions changed and outside points stayed unchanged.
- `Sketchup.undo` restored revision 1, original digest, and original sampled elevations in the production MCP path.
- `ping` succeeded after each edit, including near-cap.
- An unmanaged top-level sentinel survived operations, confirming unrelated unmanaged scene content was not deleted.
- Public MCP high-variation 17x9 edit passed with coherent samples, all normals up, minimum normal Z about `0.2018`, and post-operation ping success.

### Performance Validation
- Production MCP path timings: small 4x3 create `0.055s`, edit/regenerate `0.338s`; non-square 17x9 create `0.128s`, edit/regenerate `0.388s`; near-cap 100x100 create `21.629s`, edit/regenerate `23.039s`.
- Internal high-variation greybox timings: 9x7 amplitude 8m per-face `0.2355s`, bulk candidate `0.0020s`; 100x100 amplitude 12m per-face `74.8048s`, bulk candidate `0.4239s`.
- High-relief near-cap normals stayed positive, with minimum normal Z about `0.0383`.

### Migration / Compatibility Validation
- Contract/no-drift tests prove persisted terrain remains `payloadKind: "heightmap_grid"` and `schemaVersion: 1`.
- Tests assert no `sampleWindows`, `outputRegions`, `chunks`, or `tiles` are serialized into v1 state.
- Public edit evidence remains `changedRegion`, `samples`, and `sampleSummary` without generated face or vertex identifiers.

### Operational / Rollout Validation
- Production `generate` / `regenerate` continue to use per-face output.
- `generate_bulk_candidate` is validation-only and not wired into production regeneration.
- Live validation shows the bulk candidate is materially faster in greybox tests, including high-variation near-cap terrain, but production bulk-output adoption remains gated on a follow-on task.

### Validation Notes
- Final validation covers local tests, lint, package verification, codereview, public MCP hosted behavior, greybox bulk-candidate behavior, high-variation terrain behavior, undo, responsiveness, derived markers, and positive-Z normals.
<!-- SIZE:VALIDATION-EVIDENCE:END -->

---

<!-- SIZE:DELTA:START -->
## Estimation Delta Review

> Filled during final calibration. Compare prediction to actual behavior.

- **Most Underestimated Dimension**: None materially under the retest-loop validation scale. The final evidence set was broad, but hosted checks ran cleanly and increased confidence rather than burden.
- **Most Overestimated Dimension**: Validation burden, implementation friction, and rework. The mesh seam and changed-region primitive integrated with less resistance than predicted, and hosted validation did not require fix loops. Code review required no fixes.
- **Signal Present Early But Underweighted**: The need to lock persistence no-drift before primitive work. User clarification and `grok-4.20` review showed this should be a first-class skeleton, not just a later regression check.
- **Genuinely Unknowable Factor**: The size of the bulk-candidate performance delta was unknowable from local tests. Live greybox evidence showed near-cap high-variation bulk candidate generation at `0.4239s` versus per-face generation at `74.8048s`.
- **Future Similar Tasks Should Assume**: For terrain representation prep that intentionally defers schema migration, start with contract/no-drift skeletons, then add domain primitives, then integrate them into one real seam before output refactoring. Include high-relief hosted cases early because they expose normals, markers, precision, and timing behavior that flat terrain can hide.

### Calibration Notes
- The prediction was directionally accurate on scope, but overestimated validation execution burden, implementation friction, and rework. Actual implementation stayed bounded because persisted v2/chunked state remained out of scope and the bulk path was isolated as validation-only.
- The major calibration lesson is that high-variation hosted terrain checks should be part of the default validation matrix for terrain output-path work, not an optional enhancement.
<!-- SIZE:DELTA:END -->

---

<!-- SIZE:TAGS:START -->
## Retrieval Tags

- `archetype:platform`
- `archetype:performance-sensitive`
- `scope:managed-terrain`
- `systems:terrain-state`
- `systems:terrain-output`
- `validation:hosted-matrix`
- `validation:performance`
- `host:routine-matrix`
- `risk:performance-scaling`
- `volatility:low`
- `friction:low`
- `rework:low`
- `confidence:high`
<!-- SIZE:TAGS:END -->
