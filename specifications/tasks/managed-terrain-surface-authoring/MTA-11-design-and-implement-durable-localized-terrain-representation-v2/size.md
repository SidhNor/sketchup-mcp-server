# Size: MTA-11 Migrate To Tiled Heightmap V2 With Adaptive Output

**Task ID**: `MTA-11`
**Title**: Migrate To Tiled Heightmap V2 With Adaptive Output
**Status**: `calibrated`
**Created**: 2026-04-26
**Last Updated**: 2026-05-01

**Related Task**: [task.md](./task.md)
**Related Plan**: [plan.md](./plan.md)
**Related Summary**: [summary.md](./summary.md)

---

<!-- SIZE:IDENTITY:START -->
## Identity

- **Task Archetype**: `archetype:migration`
- **Primary Scope Area**: `scope:managed-terrain`
- **Likely Systems Touched**:
  - `systems:terrain-state`
  - `systems:serialization`
  - `systems:terrain-repository`
  - `systems:terrain-kernel`
  - `systems:terrain-output`
  - `systems:terrain-mesh-generator`
  - `systems:native-contract-fixtures`
  - `systems:docs`
- **Validation Modes**: `validation:migration`, `validation:contract`, `validation:hosted-smoke`, `validation:performance`, `validation:persistence`, `validation:undo`
- **Likely Analog Class**: terrain representation migration plus adaptive derived-output generation

### Identity Notes
- Planning rebaseline replaced localized survey detail zones with tiled heightmap v2 plus adaptive SketchUp TIN output. The task intentionally drops permanent v1 runtime compatibility and treats v1 handling as one-way migration into v2 state.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 4 | Migrates authoritative terrain representation and changes generated output behavior, while keeping public edit request shapes stable. |
| Technical Change Surface | 4 | Likely touches serializer, repository, v2 terrain state, edit-window adapter, existing kernels, output planning, mesh generation, evidence, docs, and contract fixtures. |
| Hidden Complexity Suspicion | 4 | One-way migration, tile/window math, cross-tile edits, adaptive simplification, seam safety, and host output replacement are all sensitive. |
| Validation Burden Suspicion | 4 | Requires migration fixtures, state integrity, kernel equivalence, adaptive-output error/seam checks, contract parity, hosted persistence, undo, and output validation. |
| Dependency / Coordination Suspicion | 3 | Depends on MTA-07/MTA-10/MTA-13/MTA-16 lessons, hosted SketchUp validation, and synchronized docs/fixture updates, but stays within owned terrain runtime. |
| Scope Volatility Suspicion | 3 | Dense source and adaptive output are intentionally coupled; volatility remains if storage size, edit-window caps, or adaptive generation force a split. |
| Confidence | 2 | The direction is now selected and planned, but implementation evidence for v2 migration plus adaptive output does not exist yet. |

### Early Signals
- MTA-02 showed terrain storage foundations have high validation and downstream rework sensitivity even without public tool changes.
- MTA-07 selected a heightmap-derived scalable direction but deliberately avoided persisted v2 representation work.
- MTA-10 showed derived output mutation and hosted SketchUp output behavior can dominate validation and discovery.
- MTA-13 and MTA-16 exposed v1 grid-fidelity limits around survey and planar edits.
- Planning rejected mixed-resolution localized detail zones because edit kernels would need coarse/detail/coarse math across one operation.

### Early Estimate Notes
- This reseed is a pre-implementation planning rebaseline after the task changed from localized detail zones to tiled heightmap v2 plus adaptive output. It is not implementation drift.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

> Filled during task planning. This is the main pre-implementation estimate.

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | 4 | Changes authoritative terrain representation and derived output behavior for all Managed Terrain Surfaces while keeping public edit request shapes stable. |
| Technical Change Surface | 4 | Spans v2 state, serializer migration, repository load/save, raster edit windows, existing edit kernels, output planning, adaptive mesh generation, evidence, docs, and native contract fixtures. |
| Implementation Friction Risk | 4 | Tile-backed raster windows, one-way migration, cross-tile kernel equivalence, adaptive simplification, seam validation, and atomic save/regenerate behavior are likely to resist a simple linear implementation. |
| Validation Burden Risk | 4 | Requires migration, corrupt/unsupported refusals, state integrity, kernel equivalence, adaptive error/seam checks, contract/docs parity, hosted persistence, undo, and SketchUp output validation. |
| Dependency / Coordination Risk | 3 | Depends on prior terrain foundations and hosted validation access, plus coordinated docs/fixture updates, but remains within the extension runtime and avoids new public request contracts. |
| Discovery / Ambiguity Risk | 3 | The architecture is selected, but exact tile size, memory caps, adaptive tolerance, simplifier edge behavior, and hosted output performance still require implementation evidence. |
| Scope Volatility Risk | 3 | Coupling v2 representation with first adaptive output is intentional, but storage limits or adaptive-output correctness could still force a task split or narrower first slice. |
| Rework Risk | 4 | A weak v2 schema, wrong edit-window abstraction, unsafe migration, or flawed adaptive output path would require revisiting state, kernels, output generation, and evidence together. |
| Confidence | 2 | Planning evidence is strong enough to estimate, but no exact completed analog combines v2 terrain migration, all-kernel adaptation, and adaptive SketchUp output generation. |

### Top Assumptions
- Existing `TerrainStateSerializer` migration harness can own one-way v1-to-v2 conversion without introducing a parallel repository-level migration workflow.
- A bounded `RasterEditWindow` can preserve current kernel math across tile boundaries without forcing kernels to understand tile storage.
- A deterministic quadtree/error-based simplifier is sufficient for the first adaptive output path, with stronger Delaunay or breakline work deferred.
- Full adaptive output regeneration is acceptable for the first v2 slice unless hosted performance evidence proves otherwise.
- Public terrain edit request schemas remain stable; response summaries, docs, and fixtures absorb the adaptive-output deltas.

### Estimate Breakers
- Model-embedded v2 payload size or save/reopen behavior requires chunking, compression, or sidecar storage in this task.
- Cross-tile raster-window behavior changes slope, planar, fairing, survey, fixed-control, or preserve-zone math compared with equivalent single-window edits.
- Adaptive output cannot prevent visible seams, T-junctions, or tolerance violations without a stronger mesh algorithm than the planned first-slice simplifier.
- Hosted SketchUp output regeneration, cleanup, undo, or persistence requires partial adaptive regeneration or broader entity-ownership changes.
- Response-shape changes become broader than output summaries and require new public request fields, loader schemas, or dispatcher routing.

### Predicted Signals
- Closest analogs are partial, not exact: MTA-02 for terrain state/storage risk, MTA-07 for representation direction, MTA-10 for host-sensitive output validation, and MTA-13/MTA-16 for kernel and fidelity pressure.
- MTA-10 actuals warn that SketchUp output mutation, save/reopen, undo, and performance can dominate closeout even when local tests pass.
- MTA-02 actuals show state schema mistakes become expensive because later terrain tasks build on the repository contract.
- MTA-07 is directionally useful but stale as an effort analog because it intentionally avoided persisted v2 schema migration and production adaptive output.
- Landscape-style terrain-engine patterns support bounded edit windows and dirty-region tracking, but host-specific internals are advisory only.

### Predicted Estimate Notes
- This prediction is the current planning baseline after replacing localized detail zones with tiled heightmap v2 and adaptive output.
- No useful calibrated analog covers the whole task shape. The estimate therefore keeps confidence at `2` despite a detailed plan.
- Validation burden is predicted very high because correctness spans data migration, numerical edit behavior, generated mesh error bounds, public response parity, and real SketchUp host behavior.
- Dependency risk is below technical risk because the work is broad but owned inside the SketchUp extension runtime.
<!-- SIZE:PREDICTED:END -->

---

<!-- SIZE:CHALLENGE:START -->
## Challenge Review

### Agreed Drivers

- The task is very large by shape: it combines durable terrain-state migration, all-kernel edit-window adaptation, and first adaptive SketchUp output generation.
- Validation burden remains `4` because correctness spans migration, corrupt/unsupported refusals, serialized payload limits, numerical kernel equivalence, adaptive mesh error/seam checks, public response compatibility, hosted undo, save/reopen, and output performance.
- Implementation friction remains `4` because the hard parts are coupled: a weak v2 schema, wrong raster-window abstraction, or unsafe adaptive output path would force changes across state, kernels, commands, and mesh generation.
- Prior analogs support high risk but are incomplete: MTA-02 covers state/storage sensitivity, MTA-10 covers host-sensitive output behavior, MTA-13/MTA-16 cover terrain edit math pressure, and MTA-07 covers direction only.
- The premortem strengthened the plan by pinning first-slice guardrails: `128x128` tiles, `262_144` edit-window sample cap, inherited `8 MiB` payload threshold, source-spacing preservation on migration, explicit quadtree/error simplifier behavior, and atomic hosted migration/output validation.

### Contested Drivers

- Whether Scope Volatility Risk should rise from `3` to `4`: the plan deliberately couples representation and adaptive output, and premortem found real split pressure. Keep `3` because the plan now has explicit refusal/drift guardrails against sidecar storage, Delaunay, chunked edit execution, and partial adaptive regeneration.
- Whether Confidence should rise from `2` to `3` after the premortem: the plan is now much more concrete, but no completed analog covers the combined migration/kernel/output shape and no implementation prototype exists. Keep `2`.
- Whether Validation Burden Risk should be interpreted as routine hosted breadth: keep `4` because the burden includes migration compatibility, save/reopen persistence, undo semantics, performance interpretation, and seam/error proof, not just a normal hosted smoke count.
- Whether Functional Scope should be `3` because public request shapes stay stable: keep `4` because authoritative state and derived output behavior change for the whole Managed Terrain Surface capability.

### Missing Evidence

- Representative v2 payload size and save/reopen behavior under the inherited model-embedded storage threshold.
- Cross-tile equivalence fixtures for each existing edit kernel against single-window reference behavior.
- Adaptive simplifier proof for planar reduction, high-error retention, max error, seam/gap behavior, and known T-junction avoidance.
- Hosted migration/edit/regenerate proof with undo, save/reopen, no re-migration, no orphan v1 output, owner metadata preservation, and output timing.
- Contract fixture proof that adaptive response-summary additions do not imply new public request-schema requirements or break existing compatible response parsing.

### Recommendation

- Confirm the predicted scores without revision.
- Proceed with the finalized plan; do not split before implementation.
- Record implementation drift if payload size forces sidecar/chunking, if adaptive output requires Delaunay/breaklines/partial regeneration, if public request schemas change, or if hosted migration/output cannot be made atomic.

### Challenge Notes

- Challenge evidence came from Step 11 premortem plus `grok-4.20` critique. The critique initially identified resource defaults, adaptive simplifier detail, and atomic hosted migration/reopen behavior as blocking Tigers.
- The plan was revised to mitigate those Tigers before finalization, so the challenged estimate does not need score changes.
- The final plan and challenged profile agree: this is a high-risk migration/platform task with stable public request shapes, broad internal technical surface, very high validation burden, and medium-low confidence until implementation evidence exists.
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
| Functional Scope | 4 | The task changed the authoritative managed terrain state format and derived output behavior, and added public row-major create elevations while keeping the core create/edit tool workflow stable. |
| Technical Change Surface | 4 | Actual changes touched v2 state, serializer migration, repository expectations, public create schema/validation, create/adopt state building, edit-kernel state preservation, raster windows, output planning, mesh generation, native fixtures, tests, and docs. |
| Actual Implementation Friction | 3 | The implementation stayed inside the planned architecture and avoided sidecars, Delaunay, chunked editing, and partial adaptive regeneration, but required coordinated state/migration/output/kernel changes plus post-review/live-verification fixes. |
| Actual Validation Burden | 4 | Proof required broad terrain tests, full Ruby suite, RuboCop, package verification, native contract fixture checks, PAL/local review, and a reset-scene live MCP matrix with one fix-and-reverify loop for payload vocabulary, public elevations, no-data, and planar evidence. |
| Actual Dependency Drag | 2 | Work depended on existing terrain foundations and prior edit kernels but did not require upstream code changes or new public dispatcher/schema routing. |
| Actual Discovery Encountered | 3 | Implementation confirmed the `with_elevations` preservation seam, the need to avoid adaptive partial ownership metadata, no-data ordering gaps, and a public-contract correction: v2 must remain `heightmap_grid` while public create elevations must be honored. |
| Actual Scope Volatility | 3 | The slice stayed inside the v2/adaptive-output boundary but expanded from response-only contract deltas to a small public create schema addition for `definition.grid.elevations` after live verification exposed ignored irregular create input. |
| Actual Rework | 3 | Rework included test-data correction, fixture/doc alignment, RuboCop cleanup, PAL-found no-data ordering fixes, removal of the alternate payload vocabulary, public elevation schema/validation/building fixes, and planar evidence status correction. |
| Final Confidence in Completeness | 4 | Local automated validation, code review, and reset-scene live MCP verification are strong. Confidence remains below maximum because save/reopen direct-v2 loading was not reverified in this pass. |

### Actual Notes
- The predicted broad migration shape was accurate, but the local implementation path was more linear than the worst-case estimate breakers suggested.
- The dominant actual failure mode was public-contract mismatch discovered through review/live verification: an alternate payload vocabulary leaked, public irregular create elevations were not honored, no-data create needed structured refusal, and planar refusal evidence overstated satisfaction.
- No material in-flight drift was recorded during the main implementation loop because sidecar storage, chunked edit execution, Delaunay/breakline output, and partial adaptive regeneration were avoided. Calibration records the post-review public schema expansion as actual scope volatility.
<!-- SIZE:ACTUAL:END -->

---

<!-- SIZE:VALIDATION-EVIDENCE:START -->
## Validation Evidence Summary

- Full Ruby suite passed: `844 runs`, `4338 assertions`, `0 failures`, `0 errors`, `37 skips`.
- RuboCop passed with project-local cache: `215 files inspected`, `no offenses detected`.
- `package:verify` passed and produced `dist/su_mcp-1.1.1.rbz`.
- Local CI-equivalent `RUBOCOP_CACHE_ROOT=tmp/.rubocop_cache bundle exec rake ci` passed after the final payload-kind and public-elevation fixes.
- PAL Step 05 queue review produced implementation controls that were incorporated before coding.
- PAL Step 10 final review found concrete no-data adaptive output ordering gaps; they were fixed and covered by generation/regeneration refusal tests.
- Native contract fixtures and user-facing docs were updated for `heightmap_grid` and `adaptive_tin` response-summary deltas, without introducing an alternate public payload kind.
- Live SketchUp MCP verification passed on a reset scene for tool schema, flat/minimum create, irregular create through public elevations, malformed/no-data non-mutating refusals, sloped/irregular adoption, public contract leak scan, planar refusal evidence, target-height bump, flattening regeneration, irregular flatten/fair/corridor, face normals, pure planar crossfall, irregular crossfall, crossfall planar fit, and crossfall non-coplanar refusal.
- Remaining live gap: save/reopen direct-v2 loading without duplicate migration was not reverified in this pass.
<!-- SIZE:VALIDATION-EVIDENCE:END -->

---

<!-- SIZE:DELTA:START -->
## Estimation Delta Review

### What The Estimate Got Right
- The task was correctly predicted as a broad migration touching terrain state, serialization, kernels, output, mesh generation, fixtures, and docs.
- Validation burden was correctly predicted as high because local correctness needed migration, state integrity, output summary, adaptive simplification, public contract checks, and live MCP verification.
- Estimate breakers were useful guardrails: no sidecar/chunking, Delaunay, or partial adaptive regeneration was introduced. Public request-shape expansion did occur, but stayed narrow and additive through optional `definition.grid.elevations`.

### What Was Overestimated
- Implementation friction landed at `3` rather than the predicted `4` because the existing flat state interface allowed kernels to preserve v2 state through a small `with_elevations` seam.
- Rework landed at `3` rather than `4`; review/live verification found multiple bounded contract/edge fixes, but no schema redesign, sidecar storage, output-architecture rework, or task split.

### What Was Underestimated
- Public irregular create via `grid.elevations` was underweighted. The plan assumed no public request-schema expansion, but live MCP verification showed irregular create needed first-class public elevation arrays rather than raw ignored inputs.
- Payload vocabulary risk was underweighted: v2 should have remained `heightmap_grid` from the start rather than introducing an alternate payload kind.
- The output-plan no-data ordering issue was not called out directly in planning. Future adaptive-output estimates should include pre-plan refusal ordering as a specific check.
- Native fixture updates were mechanically broader than the implementation risk suggested because every terrain response example needed v2/adaptive summary alignment.

### Dominant Actual Failure Mode
- Public-contract correction after review/live MCP verification: keep v2 payloads as `heightmap_grid`, expose and honor public row-major create elevations, refuse no-data/malformed elevation input before mutation, and report planar violating controls accurately.

### Future Retrieval Notes
- Similar tasks should retrieve this as a terrain representation migration with mostly stable public tool workflow, narrow additive public schema support, response-shape fixture updates, kernel-preservation seam work, adaptive-output first slice, and reset-scene live MCP verification with one fix-and-reverify loop.
<!-- SIZE:DELTA:END -->

---

<!-- SIZE:TAGS:START -->
## Retrieval Tags

- `archetype:migration`
- `scope:managed-terrain`
- `systems:serialization`
- `systems:terrain-state`
- `systems:terrain-repository`
- `systems:terrain-kernel`
- `systems:terrain-output`
- `systems:terrain-mesh-generator`
- `validation:migration`
- `validation:contract`
- `validation:hosted-matrix`
- `validation:public-client-smoke`
- `host:single-fix-loop`
- `host:save-reopen`
- `contract:public-tool`
- `contract:response-shape`
- `contract:docs-examples`
- `risk:contract-drift`
- `risk:performance-scaling`
- `risk:review-rework`
- `friction:medium`
- `rework:medium`
- `confidence:high`
<!-- SIZE:TAGS:END -->
