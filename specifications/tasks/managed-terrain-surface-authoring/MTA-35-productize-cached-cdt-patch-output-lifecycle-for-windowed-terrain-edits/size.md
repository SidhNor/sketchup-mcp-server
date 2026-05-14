# Size: MTA-35 Implement CDT Replacement Provider On PatchLifecycle For Windowed Terrain Edits

**Task ID**: `MTA-35`  
**Title**: `Implement CDT Replacement Provider On PatchLifecycle For Windowed Terrain Edits`  
**Status**: `calibrated-after-implementation`
**Created**: `2026-05-10`  
**Last Updated**: `2026-05-14`

**Related Task**: [task.md](./task.md)  
**Related Plan**: [plan.md](./plan.md)  
**Related Summary**: [summary.md](./summary.md)

---

<!-- SIZE:IDENTITY:START -->
## Identity

- **Task Archetype**: `archetype:integration`
- **Primary Scope Area**: `scope:managed-terrain`
- **Likely Systems Touched**:
  - `systems:command-layer`
  - `systems:terrain-output`
  - `systems:terrain-mesh-generator`
  - `systems:terrain-kernel`
  - `systems:terrain-state`
  - `systems:scene-mutation`
  - `systems:managed-object-metadata`
  - `systems:public-contract`
- **Validation Modes**:
  - `validation:hosted-matrix`
  - `validation:performance`
  - `validation:persistence`
  - `validation:contract`
  - `validation:undo`
- **Likely Analog Class**: internally gated CDT provider integration over reusable terrain patch lifecycle with hosted product-loop proof

### Identity Notes
- Re-seeded after Step 06 planning rebaseline. MTA-36 is now the positive lifecycle analog; MTA-34
  is a negative partial-proof analog, not the ownership baseline.
- The task no longer owns generic patch lifecycle productization. It owns CDT provider input,
  feature-intent relevance, retained-boundary topology/seam validation, fallback generation, and
  hosted proof on top of MTA-36.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Adds internally gated local CDT replacement behavior for create/edit/repeated-edit flows, fallback mesh generation, hosted proof, and timing while public workflows remain unchanged. |
| Technical Change Surface | 4 | Spans command/output planning, PatchLifecycle CDT wiring, feature relevance, CDT provider/input assembly, terrain mesh mutation, metadata, no-leak tests, and hosted probes. |
| Hidden Complexity Suspicion | 4 | Feature intent relevance, retained-boundary seams, production mesh handoff, repeated-edit metadata, fallback routing, and SketchUp geometry cleanup all remain high-risk. |
| Validation Burden Suspicion | 4 | Requires automated, integration, no-leak, hosted visual, save/reopen, undo, fallback/no-delete, structural geometry, and timing evidence. |
| Dependency / Coordination Suspicion | 3 | Depends on in-repo MTA-36 lifecycle, MTA-33 feature semantics, retained MTA-32/MTA-34 CDT code quality, and hosted SketchUp validation. |
| Scope Volatility Suspicion | 4 | Explicit split triggers remain for CDT solver/topology repair, full seam graph repair, spatial indexing, and default-enable blockers. |
| Confidence | 2 | The refined task and draft plan are concrete, but hosted geometry and timing evidence have not run. |

### Early Signals
- MTA-36 reduces lifecycle uncertainty but raises the bar: CDT must plug into the proven one-mesh
  PatchLifecycle rather than reusing old digest-domain proof paths.
- MTA-35 still must solve CDT-specific feature-intent selection, retained-boundary topology, ordered
  multi-span seams, surplus-face checks, and fallback mesh generation.
- MTA-32/MTA-34 are useful negative and implementation evidence because they exposed bad nesting,
  stitching, duplicate edges, debug mesh handoff, and one-span seam assumptions.
- Hosted visual proof, save/reopen, repeated edits, fallback/no-delete, and timing are acceptance
  gates, not optional polish.
- Public contract stability remains a hard constraint while internal evidence expands.

### Early Estimate Notes
- Use MTA-36 as the closest positive lifecycle analog and MTA-34 as the closest negative CDT
  replacement analog.
- The rebaseline lowers generic lifecycle ownership risk versus the old plan, but keeps validation,
  topology, feature relevance, and hosted rework suspicion high.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

> Filled during task planning. This is the main pre-implementation estimate.

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Adds internally gated CDT local replacement for create/edit/repeated-edit flows, feature-rich hosted cases, fallback mesh generation, and performance proof while public workflows remain unchanged. |
| Technical Change Surface | 4 | Touches command/output planning, PatchLifecycle CDT adapter wiring, TerrainFeaturePlanner batch relevance, CDT input/provider, mesh generator mutation, metadata/readback, no-leak tests, and hosted probes. |
| Implementation Friction Risk | 4 | High risk from removing proof-era digest/debugMesh assumptions, adapting feature selection to patch domains, enforcing ordered multi-span seams, and preserving no-delete mutation semantics. |
| Validation Burden Risk | 4 | Requires unit, integration, contract, hosted visual, save/reopen, undo, fallback/no-delete, structural geometry, and timing evidence; MTA-34 showed fake/simple rows can mislead. |
| Dependency / Coordination Risk | 3 | Depends on MTA-36 lifecycle, MTA-33 feature semantics, retained MTA-32/MTA-34 CDT code quality, current/adaptive fallback, and hosted SketchUp access, all within the repo/runtime boundary. |
| Discovery / Ambiguity Risk | 3 | Major architecture decisions are resolved, but retained CDT solver quality, ordered seam sufficiency, feature-relevance edge cases, and hosted timing remain evidence-gated. |
| Scope Volatility Risk | 4 | Split triggers for solver/topology repair, full seam graph repair, spatial indexing, and default-enable blockers can materially resize or split the task. |
| Rework Risk | 4 | Rework pressure is high because MTA-32/MTA-34 contain known bad assumptions and hosted rows may force provider, seam, or solver repair loops. |
| Confidence | 2 | Planning is concrete and consensus-backed, but confidence stays low until hosted feature-rich replacement, save/reopen, and timing evidence run. |

### Top Assumptions
- MTA-36 PatchLifecycle can be reused for CDT policy/resolution/registry/traversal without
  provider-specific lifecycle forking.
- MTA-33 feature primitives and geometry builder can be adapted to domain-aware batch selection
  without changing public feature intent contracts.
- Retained CDT solver/provider pieces can be mined behind a stable-domain provider without requiring
  a wholesale CDT rewrite.
- Safe full/adaptive/current fallback mesh generation remains available for valid edits when local
  CDT is declined.
- Hosted rows can prove ordered side-span seams without requiring full seam graph repair in MTA-35.

### Estimate Breakers
- Retained CDT output fails representative stable patches with bad nesting, duplicate edges, bad
  stitching, near-full-grid output, or topology defects that require solver repair.
- Ordered multi-span side evidence is insufficient for representative retained-boundary seams and a
  full seam graph/topology repair becomes necessary.
- Domain-aware feature selection either omits retained-boundary controls or includes too much global
  feature intent, requiring a deeper MTA-33 redesign.
- Hosted timing shows feature planning, retained snapshotting, registry lookup, CDT solve, or
  mutation cost erases locality benefit and forces index/cache/provider optimization.
- Save/reopen metadata cannot read back or safely invalidate without additional persistence work.

### Predicted Signals
- MTA-36 removed generic lifecycle work from MTA-35 but added a hard integration constraint: CDT must
  preserve the one-mesh PatchLifecycle model.
- The plan explicitly rejects elevation-only CDT input and requires patch-relevant feature intents as
  first-class provider constraints.
- The retained CDT path still contains stale signals: `PatchCdtDomain`, `cdtPatchDomainDigest`,
  `debugMesh`, and one-span seam assumptions.
- Valid edits must generate mesh even when local CDT fails, so fallback routing is command-critical.
- Hosted proof requires feature-rich seams, repeated edits, save/reopen, structural blockers, and
  timing comparison.

### Predicted Estimate Notes
- Closest analogs are MTA-36 for lifecycle/one-mesh mutation success, MTA-34 for negative CDT
  replacement and hosted artifact risk, MTA-33 for feature relevance, and MTA-32 for proof-only CDT
  solver risk.
- This is a planning rebaseline after MTA-36, not implementation drift. Generic lifecycle ownership
  is lower than the stale plan, but feature-intent CDT input, retained-boundary seams, topology
  validation, fallback mesh generation, and hosted proof keep the estimate high.
<!-- SIZE:PREDICTED:END -->

---

<!-- SIZE:CHALLENGE:START -->
## Challenge Review

> Filled when the estimate is pressure-tested through external review, premortem, or controlled consensus.

### Agreed Drivers
- Very high technical change surface is justified by the command/output-plan routing, CDT
  PatchLifecycle adapter, domain-aware feature planning, stable-domain provider, one-mesh mutation,
  metadata/readback, contract guards, and hosted probe work.
- Very high validation burden is justified by feature-rich hosted rows, ordered multi-span seams,
  save/reopen, undo, fallback/no-delete, structural blocker rows, no-leak coverage, and timing split.
- High implementation friction is justified by removing proof-era `PatchCdtDomain`,
  `cdtPatchDomainDigest`, `debugMesh`, and one-span seam assumptions while preserving MTA-36
  no-delete mutation behavior.
- High scope volatility is credible because CDT solver/topology repair, full seam graph repair,
  spatial indexing, and default-enable blockers remain explicit split triggers.
- The premortem reinforced the high rework score by adding concrete failure paths around
  `CdtPatchBatchPlan` lifecycle drift, retained-boundary snapshot cost, and nonplanar multi-span
  seam evidence.

### Contested Drivers
- Functional scope remains 3 rather than 4 because CDT remains internally gated, public workflows and
  public contracts stay unchanged, and default enablement is out of scope.
- Dependency risk remains 3 rather than 4 because all major dependencies are in-repo and within the
  same SketchUp extension runtime, despite hosted validation access being required.
- Discovery risk remains 3 rather than 4 because Step 06 resolved the major ownership, feature-flow,
  fallback, seam-scope, and public-contract decisions; the remaining unknowns are gated by tests,
  hosted rows, or split triggers.
- Validation burden could be argued as routine hosted breadth, but stays 4 because the matrix
  includes special geometry interpretation, persistence, undo, fallback/no-delete, structural
  blocker rows, timing interpretation, and likely fix/redeploy/rerun loops.

### Missing Evidence
- Hosted timing distribution after feature relevance, retained-boundary snapshot, registry lookup,
  topology, seam, and surplus-face checks are all active.
- Whether ordered multi-span side evidence is sufficient for representative nonplanar retained
  boundaries or full seam graph repair is needed.
- Whether retained CDT solver/provider code can pass feature-rich stable patch rows without solver
  repair.
- Whether owner-attribute registry readback survives save/reopen or safely invalidates without
  additional persistence machinery.
- Whether fallback mesh generation preserves freshness and no-delete behavior for valid edits when
  local CDT is declined.

### Recommendation
- Keep the predicted scores unchanged.
- Proceed with implementation only under the finalized plan guardrails: no second PatchLifecycle,
  first-class patch-relevant feature intent, invocation-scoped batch plan, production mesh handoff,
  ordered multi-span seam evidence, valid-edit fallback mesh generation, broad no-leak guards, hosted
  save/reopen, structural blocker rows, and timing comparison.
- Split follow-up work if retained CDT topology requires solver repair, representative seams require
  full graph repair, retained-boundary snapshot/registry lookup cost requires indexing, or timing
  fails to justify default-enable discussion.

### Challenge Notes
- Consensus and premortem did not leave unresolved Tigers after plan changes.
- Premortem caused concrete plan corrections: `CdtPatchBatchPlan` no-lifecycle guardrails,
  structural negative gates, nonplanar multi-span hosted row, registry invalidation hosted row,
  retained-boundary snapshot plus registry lookup timing, and tighter valid-edit fallback wording.
- Estimate confidence remains 2 because correctness depends on hosted geometry, persistence, and
  timing evidence that has not yet run.
<!-- SIZE:CHALLENGE:END -->

---

<!-- SIZE:DRIFT:START -->
## Drift Log

> Append only. Log only material changes that affect estimate shape, risk, confidence, or validation burden.

| Date | Phase / Checkpoint | Event Type | Severity (1-3) | Dimension Affected | Predictable Earlier? | Notes |
|---|---|---|---:|---|---|---|
| 2026-05-12 | Implementation attempt / Step 10 reread | Architecture drift caught and queue reopened | 3 | Implementation Friction, Rework Risk, Confidence | Yes | The local queue proved only a partial dirty-replacement seam while `summary.md` and `task.md` overstated completion. It removed proof-window digest identity from the accepted dirty path and added registry writeback, but did not complete initial CDT bootstrap, true domain-aware feature planning, retained-boundary provider input, full provider acceptance hardening, timing buckets, or repeated edit/readback proof. The task was reopened and the plan was corrected before live SketchUp verification. |

### Drift Notes
- Material drift is recorded because the implementation queue and closeout metadata under-covered the
  plan. The code surface is partially useful foundation work, but completion confidence is reduced
  until the corrected queue is implemented and reviewed.
- The next queue must treat MTA-32/MTA-34 as evidence or narrow utility code only. The accepted CDT
  replacement path must be built around MTA-36 `PatchLifecycle` identity and registry from the first
  failing tests.
- Required first red tests: provider input is a lifecycle `CdtPatchBatchPlan`; accepted replacement
  does not call `PatchCdtDomain.from_window`; accepted result exposes lifecycle `patchId` rather
  than proof digest; CDT face lookup/emission uses lifecycle patch IDs and registry face counts;
  mutation selects replacement faces by lifecycle `replacementPatchIds`.
<!-- SIZE:DRIFT:END -->

---

<!-- SIZE:ACTUAL:START -->
## Actual Profile

> Filled at the end of implementation. Do not overwrite predicted values.

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Internally gated CDT patch bootstrap, dirty replacement, repeated edits, retained seams, fallback/no-delete, hosted proof, and performance evidence shipped without public contract expansion or default enablement. |
| Technical Change Surface | 4 | Touched command/output routing, DI, feature planning, CDT provider/solver/result, lifecycle ownership, mesh mutation, registry, timing, tests, and task metadata. |
| Actual Implementation Friction | 4 | Corrective replanning was required after an optimistic partial queue; proof-era identity, retained-boundary input, provider gates, strict no-fallback mode, and seam synchronization all needed follow-up. |
| Actual Validation Burden | 4 | Required broad Ruby tests, focused suites, RuboCop, no-leak/source audit tests, task-review structural analysis, repeated `grok-4.3` review, live SketchUp rows, save/reopen/readback, A/B comparison, density/timing, and no-delete checks. |
| Actual Dependency Drag | 3 | MTA-36 PatchLifecycle reuse worked, but retained MTA-32/MTA-34 CDT proof code was mostly removed rather than reused; live SketchUp and `su-ruby` availability remained necessary. |
| Actual Discovery Encountered | 4 | Live verification exposed strict-output bypasses, fallback masking, protected-region clipping, retained-boundary endpoint gaps, patch-local feature filtering, density behavior, and internal boundary vertex synchronization needs. |
| Actual Scope Volatility | 4 | Scope stayed internally gated, but the implementation queue reopened and added corrective phases before closeout; default-enable and native/incremental backend optimization split out. |
| Actual Rework | 4 | Significant rework occurred: partial MTA-32/MTA-34 replacement was reverted/removed, task summary was corrected, CDT was rebuilt over PatchLifecycle, and live-found drifts were fixed. |
| Final Confidence in Completeness | 3 | MTA-35 is complete for the internally gated strict path with public contracts unchanged and CDT disabled by default; confidence is intentionally not 4 because default enablement/performance requires follow-up solver/backend work. |

### Actual Signals
- The corrected implementation now uses `PatchLifecycle` for CDT patch identity, registry,
  ownership lookup, mutation sequencing, and readback.
- Broad dead-code review found no dead or possibly dead functions under `src/su_mcp/terrain`,
  `src/su_mcp/terrain/output`, or `src/su_mcp/terrain/output/cdt`.
- Final reviews found no critical, high, or medium blockers after removing stale test-helper
  `patch_domain_digest` aliases.
- CDT remains disabled by default through `DEFAULT_CDT_ENABLED = false` and adaptive
  `TerrainOutputStackFactory` default mode.
- Runtime performance is still solve-bound in the pure Ruby CDT backend; follow-up backend or
  incremental triangulation work is the default-enable path.

### Actual Notes
- The task should be used as a high-risk analog for internally gated geometry-output integrations
  that require hosted SketchUp evidence and strict public-contract containment.
- MTA-32/MTA-34 proof code was more useful as negative evidence than as accepted implementation
  substrate.
<!-- SIZE:ACTUAL:END -->

---

<!-- SIZE:VALIDATION-EVIDENCE:START -->
## Validation Evidence Summary

> Fill only the sections that are relevant. Say `not applicable` where needed.

### Automated Validation
- Full available Ruby test glob: 482 runs, 1788 assertions, 0 failures, 0 errors, 2 skips.
- Focused MTA-35 regression suites ran repeatedly after live and review follow-up changes,
  including command routing, feature planning, CDT provider/solver/result, seam validation,
  residual refinement, terrain mesh generation, output-stack factory, runtime config, and no-leak
  source audit coverage.
- Final focused affected tests after review cleanup: 40 runs, 327 assertions, 0 failures, 0 errors.
- Focused changed-file RuboCop: 35 files inspected, no offenses.
- `git diff --check`: clean.

### Hosted / Manual Validation
- Live strict public-command verification ran in SketchUp with the private
  `SKETCHUP_MCP_TERRAIN_SIMPLIFIER=cdt_patch` switch.
- Hosted rows covered strict create/edit, repeated overlapping edits, multi-span retained boundary,
  target-height, corridor-transition, planar-region-fit, local-fairing, survey-point-constraint,
  save/reopen/readback, registry invalidation/no-delete, adaptive-vs-CDT A/B comparison, density
  reduction, and internal boundary synchronization.

### Performance Validation
- Timing buckets cover command prep, feature selection, CDT input build, retained-boundary snapshot,
  solve, topology validation, ownership lookup, seam validation, mutation, registry write, audit,
  fallback route, and total runtime.
- Latest optimization measurement improved broad-overlap solve from about 8.03s to 7.60s and total
  lifecycle from about 8.29s to 7.85s, but solve/retriangulation remains the main blocker to any
  default-enable recommendation.

### Migration / Compatibility Validation
- Public MCP request and response contracts remain unchanged.
- Public responses continue to hide CDT patch IDs, registry internals, feature bundle roles,
  topology/seam diagnostics, fallback enums, raw mesh data, and timing buckets.
- Default production output remains adaptive/current; strict CDT is private-switch only.

### Operational / Rollout Validation
- CDT patch output remains internally gated and disabled by default.
- Valid default-mode edits retain safe fallback behavior.
- Strict `cdt_patch` mode refuses selected-output failures instead of silently rendering adaptive
  fallback geometry, so validation cannot mistake fallback output for accepted CDT.

### Validation Notes
- Final `$task-review` included broad unchanged dead-code sweeps, not only changed files.
- Final `grok-4.3` review found no critical, high, or medium findings.
<!-- SIZE:VALIDATION-EVIDENCE:END -->

---

<!-- SIZE:DELTA:START -->
## Estimation Delta Review

> Filled during final calibration. Compare prediction to actual behavior.

- **Most Underestimated Dimension**: Discovery / ambiguity. Live validation exposed several
  command-path and geometry-input drifts even after local tests were green.
- **Most Overestimated Dimension**: Dependency drag. MTA-36 was a solid lifecycle substrate; the
  bigger issue was removing proof-era CDT assumptions, not cross-team or external dependency cost.
- **Signal Present Early But Underweighted**: MTA-32/MTA-34 proof code was explicitly partial, but
  the first queue still leaned too optimistically on proof-era shapes.
- **Genuinely Unknowable Factor**: Whether seam-safe boundary synchronization would offset density
  improvements and keep CDT solve time too high for default enablement.
- **Future Similar Tasks Should Assume**: Hosted geometry integrations need an explicit strict mode
  that prevents fallback masking before visual/performance evidence is trusted.

### Calibration Notes
- Predicted high validation/rework risk was accurate.
- The corrective-replan drift log was necessary and should remain part of the task record.
- Follow-up optimization should be estimated separately, likely around native/incremental CDT
  backend work rather than more Ruby residual-parameter tuning.
<!-- SIZE:DELTA:END -->

---

<!-- SIZE:TAGS:START -->
## Retrieval Tags

Use canonical values from the repo task-estimation taxonomy when present. Keep this as a compact analog-search index, not coverage. Target 8-14 tags.

- `archetype:integration`
- `scope:managed-terrain`
- `systems:terrain-output`
- `systems:terrain-mesh-generator`
- `systems:terrain-kernel`
- `systems:scene-mutation`
- `systems:managed-object-metadata`
- `validation:hosted-matrix`
- `validation:performance`
- `host:save-reopen`
- `contract:no-public-shape-change`
- `risk:performance-scaling`
- `risk:host-persistence-mismatch`
- `confidence:low`
<!-- SIZE:TAGS:END -->
