# Size: MTA-08 Adopt Bulk Full-Grid Terrain Output In Production

**Task ID**: `MTA-08`
**Title**: Adopt Bulk Full-Grid Terrain Output In Production
**Status**: `calibrated`
**Created**: 2026-04-26
**Last Updated**: 2026-04-26

**Related Task**: [task.md](./task.md)
**Related Plan**: [plan.md](./plan.md)
**Related Summary**: [summary.md](./summary.md)

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

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | 2 | Production create/edit behavior changed visibly through faster full-grid terrain output, but no public request fields, edit modes, persisted schema, or response vocabulary were added. |
| Technical Change Surface | 1 | Production code changes were very small and localized to `TerrainMeshGenerator` plus removal of one output-strategy merge in `TerrainSurfaceCommands`; the rest was tests and task metadata. |
| Actual Implementation Friction | 1 | The planned output seam already existed, and the core implementation was a direct switch to the existing builder-backed emitter. Friction was limited to review-driven no-leak assertions and distinguishing permitted builder-unavailable compatibility from forbidden post-failure fallback. |
| Actual Validation Burden | 4 | Validation dominated the task: focused terrain tests, full Ruby suite, lint, package verification, `grok-4.20` review, loaded-code checks, public MCP create/edit calls, hosted geometry inspection, undo, responsiveness, unmanaged-scene safety, and unsupported-child refusal checks. |
| Actual Dependency Drag | 2 | Local work was unblocked, but final completion depended on deploying the updated extension into SketchUp before live MCP validation could be trusted. |
| Actual Discovery Encountered | 1 | Minor discoveries: empty SketchUp sentinel groups disappear, and existing `operation.regeneration: "full"` is public evidence while `output.regeneration.strategy` was not acceptable output vocabulary. |
| Actual Scope Volatility | 0 | Scope stayed exactly within full-grid production adoption; no schema v2, partial regeneration, output containers, public options, or command branching were pulled in. |
| Actual Rework | 1 | Rework was small: codereview follow-up removed command-level `output.regeneration.strategy` leakage and tightened tests. No architectural or algorithmic rework was needed. |
| Final Confidence in Completeness | 4 | Automated checks, package verification, expert review, and hosted SketchUp validation all passed against the updated extension. |

### Actual Notes

- Stakeholder calibration signal: the implementation felt subjectively like a micro task and may have been too small to stand alone; future similar one-seam production promotions should be considered for bundling with adjacent work when the only large component is validation.
- The actual task shape was "tiny implementation, heavyweight host validation." This should not be estimated as moderate implementation friction merely because the acceptance bar is high.
<!-- SIZE:ACTUAL:END -->

---

<!-- SIZE:VALIDATION-EVIDENCE:START -->
## Validation Evidence Summary

- Focused terrain integration passed: 29 runs, 197 assertions, 0 failures, 0 errors, 1 hosted-validation skip.
- Full Ruby suite passed: 688 runs, 3195 assertions, 0 failures, 0 errors, 35 skips.
- `bundle exec rake ruby:lint` passed: 185 files inspected, no offenses.
- `bundle exec rake package:verify` passed and produced `dist/su_mcp-0.22.0.rbz`.
- `mcp__pal__.codereview` with `grok-4.20` completed. Findings were addressed before rerunning focused checks, full tests, lint, and package verification.
- Hosted loaded-code check confirmed the deployed SketchUp extension was using the production builder emitter and no longer had command-level `output.regeneration.strategy` leakage.
- Hosted public MCP create validation passed:
  - 4x3 create: 0.097s, 12 vertices / 12 faces, `heightmap_grid` v1.
  - 17x9 create: 0.775s, 153 vertices / 256 faces, `heightmap_grid` v1.
  - 100x100 create: 0.622s, 10,000 vertices / 19,602 faces, `heightmap_grid` v1.
- Hosted geometry inspection passed after create: all generated faces and edges had derived-output markers; normals were positive; near-cap output had 19,602 faces and 29,601 marked edges.
- Hosted edit/regenerate passed on 17x9 terrain: 1.833s, revision 1 -> 2, digest changed, `derivedFromStateDigest` matched the after-state digest, 256 faces and 408 edges stayed marked, minimum normal Z was about 0.1741.
- Hosted undo passed: revision, digest, flat elevations, marked output, and positive normals returned coherently after `Sketchup.undo`.
- Hosted unsupported-child refusal passed: edit refused with `terrain_output_contains_unsupported_entities`, old derived output remained intact, and terrain state stayed revision 1.
- Hosted responsiveness passed with `ping` after terrain operations.
- Unmanaged-scene safety passed using existing scene geometry plus a solid unmanaged sentinel; earlier empty sentinel checks were discarded because empty SketchUp groups can disappear independently of terrain behavior.
<!-- SIZE:VALIDATION-EVIDENCE:END -->

---

<!-- SIZE:DELTA:START -->
## Estimation Delta Review

### What Was Estimated Well

- Validation Burden Risk `4` was correct. The live host matrix, response-shape checks, marker/normal inspection, undo, refusal, package verification, and review follow-up were the dominant closeout work.
- Scope Volatility Risk `1` was conservative; actual volatility was even lower. The task did not expand into schema, partial regeneration, command routing, or output ownership changes.
- Confidence was correctly capped before live validation; final confidence increased only after hosted checks passed against the deployed extension.

### What Was Overestimated

- Technical Change Surface predicted `2`, actual `1`. The production change was essentially a localized emitter promotion plus a small command output cleanup.
- Implementation Friction Risk predicted `2`, actual `1`. MTA-07 had already created the seam, so implementation did not encounter meaningful hidden coupling or algorithmic difficulty.
- Rework Risk predicted `2`, actual `1`. Review follow-up was useful but small and test/contract oriented.

### What Was Underestimated

- Dependency drag was slightly underweighted in practice because live MCP validation was initially attempted against an old deployed extension and had to wait for deployment alignment. This was not a design dependency, but it affected closeout sequencing.

### Dominant Actual Failure Mode

- The dominant risk was not implementation failure; it was false confidence from validating the wrong host/runtime or from mistaking local fake behavior for real SketchUp `Entities#build` behavior. The loaded-code check before live validation was essential.

### Future Estimation Lessons

- Similar "promote validated path into production" tasks should be treated as micro implementation tasks when the seam already exists and the public contract is stable.
- Keep validation burden separate from implementation friction. A task can be too small as a standalone implementation slice while still requiring heavyweight hosted proof.
- Consider bundling future one-seam production promotions with adjacent cleanup or follow-on work when stakeholder appetite favors larger implementation batches, as long as hosted validation remains explicit and not diluted.
- For live SketchUp checks, use solid sentinel geometry rather than empty groups, and always confirm the deployed extension contains the expected code before collecting acceptance evidence.

### Retrieval Facets For Future Analogs

- `analog:validated-candidate-promotion`
- `implementation:micro`
- `validation:hosted-heavy`
- `surface:terrain-mesh-generator`
- `contract:no-public-shape-change`
- `risk:wrong-live-runtime`
- `performance:near-cap-bulk-output`
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
