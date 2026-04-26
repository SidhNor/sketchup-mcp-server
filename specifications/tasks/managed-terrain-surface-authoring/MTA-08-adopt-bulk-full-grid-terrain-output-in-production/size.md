# Size: MTA-08 Adopt Bulk Full-Grid Terrain Output In Production

**Task ID**: `MTA-08`
**Title**: Adopt Bulk Full-Grid Terrain Output In Production
**Status**: `challenged`
**Created**: 2026-04-26
**Last Updated**: 2026-04-26

**Related Task**: [task.md](./task.md)
**Related Plan**: [plan.md](./plan.md)
**Related Summary**: none yet

---

<!-- SIZE:IDENTITY:START -->
## Identity

- **Task Archetype**: platform / performance-sensitive
- **Primary Scope Area**: managed terrain derived output generation
- **Likely Systems Touched**:
  - terrain mesh generation
  - terrain output summaries
  - derived-output markers and normals
  - public create/edit hosted validation
  - fallback output path
- **Validation Class**: mixed / performance-sensitive / manual-heavy
- **Likely Analog Class**: terrain output-path production adoption

### Identity Notes
- Follow-on from MTA-07 that promotes the validated bulk full-grid candidate into production without changing persisted terrain state or public MCP request vocabulary.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 2 | User-visible performance and production behavior change, but the public tool shape and terrain state semantics should stay stable. |
| Technical Change Surface | 3 | Likely touches mesh generation, output summaries, tests, and hosted validation while avoiding repository or public schema changes. |
| Hidden Complexity Suspicion | 3 | Bulk output must preserve derived markers, normals, digest linkage, undo, cleanup, and fallback behavior exactly. |
| Validation Burden Suspicion | 4 | MTA-07 showed output-path work needs live timing, high-variation terrain, undo, responsiveness, markers, and normals checks. |
| Dependency / Coordination Suspicion | 2 | Depends on MTA-07 evidence and live SketchUp validation access, but not on schema v2 or partial regeneration. |
| Scope Volatility Suspicion | 2 | Scope is bounded if kept to full-grid output; volatility rises if partial output or public contract changes are pulled in. |
| Confidence | 3 | Direction is well supported by MTA-07, with confidence capped until production wiring is planned and hosted retested. |

### Early Signals
- MTA-07 proved equivalent full-grid bulk output in grey-box checks with a large near-cap performance delta.
- Production `generate` and `regenerate` still use the slower per-face path.
- Existing public evidence and persisted `heightmap_grid` v1 must remain stable.
- MTA-04 and MTA-07 both show live SketchUp validation is mandatory for terrain output changes.

### Early Estimate Notes
- Seed treats this as a focused production-output adoption task with high validation burden and controlled functional scope.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | 2 | Production behavior changes visibly through faster terrain create/edit output, but public tool shape, persisted state, and terrain semantics stay stable. |
| Technical Change Surface | 2 | Main code surface is `TerrainMeshGenerator` plus focused output, contract stability, and command-regression tests. Runtime loader, dispatcher, repository, serializer, and public schemas should not change. |
| Implementation Friction Risk | 2 | The output seam already exists and MTA-07 proved the bulk path, but production wiring must preserve markers, normals, cleanup, and diagnostic per-face behavior without leaking strategy upward. |
| Validation Burden Risk | 4 | Live SketchUp validation dominates: production create/edit must prove builder behavior, timings, mesh counts, markers, normals, undo, responsiveness, digest linkage, and unmanaged-scene safety. |
| Dependency / Coordination Risk | 2 | Depends on MTA-07 evidence and live SketchUp/MCP validation access. No schema v2, public contract coordination, or upstream implementation dependency is expected. |
| Discovery / Ambiguity Risk | 2 | Major design decisions are settled, but real `entities.build` marker/edge/normal behavior and hosted performance still need production-path proof. |
| Scope Volatility Risk | 1 | Scope is intentionally narrow: full-grid production adoption only. Volatility rises only if hosted validation reveals bulk output cannot preserve existing invariants. |
| Rework Risk | 2 | Rework should be contained to mesh generation and tests if assumptions fail, but host-only output defects could require revisiting marker or fallback internals. |
| Confidence | 3 | Confidence is moderate-high because MTA-07 and MTA-05 are strong analogs and the plan is narrow; confidence is capped until hosted production validation passes. |

### Top Assumptions

- `TerrainMeshGenerator` can switch production `generate` and `regenerate` to the builder-backed bulk full-grid path without changing command orchestration.
- `TerrainOutputPlan.full_grid` already preserves the public derived mesh summary shape needed by create/edit evidence builders.
- The per-face path can remain internal diagnostic code without becoming a public strategy option or automatic fallback.
- Live SketchUp validation access is available for production create/edit checks on representative terrain cases.
- No public response, loader schema, dispatcher, persisted schema, or README example change is required.

### Estimate Breakers

- Real SketchUp `entities.build` does not allow reliable derived face/edge marking, normal normalization, undo, or cleanup equivalent to the per-face path.
- Production bulk output failures require automatic fallback or user-facing strategy selection to keep workflows usable.
- Hosted validation finds that direct owner-child output is unsafe with the bulk path and requires a new output container or ownership model.
- Public `output.derivedMesh`, evidence vocabulary, or persisted `heightmap_grid` v1 stability cannot be preserved after production wiring.
- Near-cap/high-variation live validation reveals responsiveness or memory behavior that requires chunking, partial output, or region-aware planning in this task.

### Predicted Signals

- MTA-07 actuals show implementation friction can be low for output-seam work, but validation burden remains very high and performance-sensitive.
- MTA-07 already proved the bulk candidate has equivalent counts, markers, digest linkage, and normals in greybox validation, with a large near-cap performance delta.
- Calibrated MTA-03 and MTA-04 show terrain output work repeatedly needs hosted proof for host behavior that fakes do not catch.
- Calibrated MTA-05 shows prepared terrain seams can keep implementation friction moderate, while live validation still finds numeric/output edge cases after local tests pass.
- The draft plan explicitly avoids public contract, schema, command-routing, partial-regeneration, and persisted-state changes, lowering scope volatility and technical surface.

### Predicted Estimate Notes

- This prediction is based on the Step 09 draft plan before premortem changes.
- The main outside-view adjustment is to keep validation burden at `4` despite the narrow implementation surface.
- Technical change surface is lower than MTA-07 and MTA-05 because this task should not add new domain primitives, public edit modes, loader schema, docs examples, or persisted schema.
- Confidence is not `4` because the production bulk path still must be proven through live SketchUp rather than inferred from the validation-only candidate.
<!-- SIZE:PREDICTED:END -->

---

<!-- SIZE:CHALLENGE:START -->
## Challenge Review

### Agreed Drivers

- Validation Burden Risk remains `4`: the premortem confirms that live SketchUp production-path validation is the dominant closeout gate, not an optional confidence boost.
- Functional Scope remains `2`: the task changes production output behavior and performance for existing terrain workflows without adding new public tool shape or new edit capability.
- Technical Change Surface remains `2`: the plan keeps changes concentrated in `TerrainMeshGenerator`, output tests, contract no-drift tests, and hosted validation rather than touching loader schema, dispatcher, repository, serializer, or docs examples.
- Implementation Friction Risk remains `2`: MTA-07 already created the relevant output seam and MTA-05 shows prepared seams can keep implementation contained, but marker/normal/cleanup invariants still need careful preservation.
- Scope Volatility Risk remains `1`: the premortem explicitly rejects output containers, partial regeneration, schema changes, and public strategy options for this task.
- Confidence remains `3`: the analog evidence is strong, but live production validation is still missing.

### Contested Drivers

- Technical Change Surface could be argued as `3` because live validation is broad and performance-sensitive. The challenge keeps it at `2` because validation breadth is already captured separately and the planned code surface remains narrow.
- Dependency / Coordination Risk could be argued as `3` if live SketchUp access is unreliable. The challenge keeps it at `2` because live validation is a required gate but not an upstream design dependency or multi-owner coordination problem.
- Rework Risk could rise if `entities.build` cannot preserve derived edge markers or undo behavior. The challenge keeps it at `2` because that failure path is explicit, localized to output generation, and would be caught before production acceptance.
- The lack of a hard numeric speedup threshold was challenged in premortem. The plan accepts this as a Paper Tiger because timing is host-sensitive; required evidence is recorded per case against the MTA-07 baseline.

### Missing Evidence

- Live production-path evidence that `generate` and `regenerate` use the bulk path successfully in SketchUp.
- Hosted inspection of derived face and edge markers after builder-backed output.
- Hosted high-variation and near-cap normal checks, including minimum positive normal Z.
- Hosted undo evidence that terrain state, digest, output, and representative samples return coherently.
- Hosted responsiveness evidence after near-cap create/edit and unmanaged sentinel preservation after create/edit/refusal/undo.
- Performance comparison against MTA-07 per-face baseline for representative cases.

### Recommendation

- Confirm the predicted profile without score changes.
- Proceed to implementation with the finalized plan.
- Do not split or expand scope before implementation.
- Treat live SketchUp validation as a hard production-readiness gate; if it fails on marker, normal, undo, or unmanaged-scene safety, fix within `TerrainMeshGenerator` or stop and replan rather than pulling in MTA-09/MTA-10 scope.

### Challenge Notes

- Premortem did not surface unresolved Tigers.
- The strongest contested issue is whether production needs fallback. The finalized plan keeps fallback non-public and non-automatic to avoid hiding defects and complicating undo semantics.
- Challenge evidence reinforces the original predicted shape: narrow code change, high validation burden, moderate implementation friction, and confidence capped until hosted validation is complete.
<!-- SIZE:CHALLENGE:END -->

---

<!-- SIZE:DRIFT:START -->
## Drift Log

No material drift recorded yet.
<!-- SIZE:DRIFT:END -->

---

<!-- SIZE:ACTUAL:START -->
## Actual Profile

Not filled yet.
<!-- SIZE:ACTUAL:END -->

---

<!-- SIZE:VALIDATION-EVIDENCE:START -->
## Validation Evidence Summary

Not filled yet.
<!-- SIZE:VALIDATION-EVIDENCE:END -->

---

<!-- SIZE:DELTA:START -->
## Estimation Delta Review

Not filled yet.
<!-- SIZE:DELTA:END -->

---

<!-- SIZE:TAGS:START -->
## Retrieval Tags

- `archetype:platform`
- `archetype:performance-sensitive`
- `scope:managed-terrain-output-generation`
- `validation:mixed-performance-manual`
- `systems:terrain-mesh-generator-output-summary-hosted-validation`
- `host:sketchup-live-validation`
- `contract:public-vocabulary-stability`
- `volatility:medium`
- `friction:medium`
- `rework:medium`
- `confidence:medium`
<!-- SIZE:TAGS:END -->
