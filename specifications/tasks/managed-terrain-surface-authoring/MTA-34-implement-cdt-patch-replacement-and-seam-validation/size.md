# Size: MTA-34 Implement CDT Patch Replacement And Seam Validation

**Task ID**: `MTA-34`
**Title**: `Implement CDT Patch Replacement And Seam Validation`
**Status**: `calibrated`
**Created**: `2026-05-09`
**Last Updated**: `2026-05-10`

**Related Task**: [task.md](./task.md)
**Related Plan**: [plan.md](./plan.md)
**Related Summary**: [summary.md](./summary.md)

---

<!-- SIZE:IDENTITY:START -->
## Identity

- **Task Archetype**: `archetype:integration`
- **Primary Scope Area**: `scope:managed-terrain`
- **Likely Systems Touched**:
  - `systems:terrain-output`
  - `systems:terrain-mesh-generator`
  - `systems:scene-mutation`
  - `systems:public-contract`
- **Validation Modes**:
  - `validation:hosted-matrix`
  - `validation:undo`
  - `validation:performance`
  - `validation:contract`
- **Likely Analog Class**: hosted partial derived-output replacement with CDT patch seams

### Identity Notes
- Seeded from MTA-10 partial output regeneration, MTA-31 CDT scaffold evidence, and the external review requirement to replace only affected patches while validating seams.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Adds local CDT patch replacement behavior while keeping public terrain workflows and default backend stable. |
| Technical Change Surface | 4 | Likely touches terrain mesh generation, derived-output ownership, scene mutation, seam checks, fallback/no-leak behavior, and hosted validation seams. |
| Hidden Complexity Suspicion | 4 | Patch ownership, seam compatibility, old-output preservation, undo semantics, and host entity behavior are all high-risk surfaces. |
| Validation Burden Suspicion | 4 | Requires hosted mutation, seam, fallback, no-leak, and undo evidence; local tests cannot prove the main acceptance criteria. |
| Dependency / Coordination Suspicion | 3 | Depends on MTA-32 patch result shape, MTA-33 patch feature constraints, MTA-10 ownership lessons, and hosted SketchUp access. |
| Scope Volatility Suspicion | 3 | Scope is bounded by reuse of MTA-10 concepts, but may grow if CDT patch ownership does not map cleanly to existing partial output metadata. |
| Confidence | 2 | The target behavior is clear, but host mutation and seam proof remain evidence-dependent. |

### Early Signals
- MTA-10 is a useful analog for partial replacement, but CDT patches add seam and topology risks beyond regular grid ownership.
- MTA-31 showed default CDT enablement is premature; this task must stay internally gated.
- Hosted SketchUp evidence is essential because undo, visible seams, and entity ownership cannot be proven by local doubles alone.
- Public no-leak behavior remains a mandatory constraint.

### Early Estimate Notes
- Use MTA-10 as the closest mutation/ownership analog and MTA-31 as the closest CDT/fallback/no-leak analog. Validation burden should stay high because this is a host-sensitive output mutation task.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

> Filled during task planning. This is the main pre-implementation estimate.

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Adds a substantial internally gated terrain-output behavior: local CDT patch replacement and seam validation. Public workflows remain unchanged, but the output capability is a major step in the CDT proof cycle. |
| Technical Change Surface | 4 | Touches patch CDT handoff, terrain mesh generation, derived-output metadata, SketchUp scene mutation, seam validation, fallback routing, no-leak contracts, and hosted validation. |
| Implementation Friction Risk | 3 | Adaptive face ownership, span-based seam validation, pre-erase gates, and real SketchUp entity lifecycle are likely to resist a straight-line implementation. |
| Validation Burden Risk | 3 | Requires unit/integration/contract coverage plus hosted positive-chain, seam failure, stale-neighbor, adjacent-edit, undo, save/reopen-if-needed, and timing evidence. This is beyond routine matrix breadth because stitching and persistence semantics are central. |
| Dependency / Coordination Risk | 3 | Depends on MTA-32 replacement-worthy patch proof output, MTA-33 feature geometry and `cdtParticipation`, MTA-10 mutation assumptions, and reliable hosted SketchUp validation. |
| Discovery / Ambiguity Risk | 2 | Major design decisions are settled by planning and consensus. Remaining ambiguity is bounded to exact tolerance alias/key names and hosted scan-cost evidence. |
| Scope Volatility Risk | 2 | Default-disabled gate, no public contract delta, and no native/incremental CDT keep scope contained. Volatility remains if face scans or seam tolerance force follow-up indexing/calibration work. |
| Rework Risk | 3 | MTA-10 analog shows partial output mutation can require hosted fix loops. Seam stitching, ownership freshness, and undo can drive rework if local tests miss host behavior. |
| Confidence | 2 | Moderate confidence. The plan is concrete and consensus-reviewed, but the estimate depends on hosted entity lifecycle, performance, and seam evidence not yet run. |

### Top Assumptions
- MTA-32 patch proof output can be adapted into `PatchCdtReplacementResult` without broad CDT
  algorithm rework.
- MTA-33 selected feature geometry and `cdtParticipation` gates are stable enough to consume as the
  input boundary.
- Existing derived-output metadata patterns can be extended with CDT face ownership without
  requiring a mandatory grouped patch hierarchy.
- Current-output fallback remains available for ordinary pre-erase CDT validation failures.

### Estimate Breakers
- MTA-32 proof output lacks enough mesh/border/topology data to build the replacement result
  without reworking the solver.
- Span-based seam validation cannot handle realistic adaptive border subdivision without broad
  patch expansion or solver changes.
- Per-face ownership lookup or seam snapshot collection dominates edit time and requires a new
  patch index/cache inside this task.
- Hosted undo/save-reopen behavior fails for persisted CDT ownership metadata and requires a
  different persistence model.

### Predicted Signals
- Closest analog MTA-10 required hosted partial scene mutation proof, undo/save-reopen evidence, and
  edge/orphan cleanup fixes.
- MTA-31 showed global CDT residual/retriangulation is the performance failure mode, so MTA-34 must
  prove local replacement without default-enabling CDT.
- MTA-32/MTA-33 provide strong upstream seams but explicitly defer production SketchUp replacement
  and seam mutation to this task.
- Consensus reviews converged on the same high-risk areas: positive proof-chain evidence, seam
  comparison semantics, metadata freshness, and fallback routing.

### Predicted Estimate Notes
- Prediction is high on change surface because the task crosses compute-result adaptation,
  metadata, mutation, validation, hosted evidence, and contract no-leak tests.
- Validation burden is high but not maxed: the matrix is broad and host-sensitive, but the plan is
  explicit and avoids public contract changes, native CDT, and default enablement.
- Confidence remains moderate until hosted proof confirms scan cost, seam tolerance behavior, and
  undo/save-reopen assumptions.
<!-- SIZE:PREDICTED:END -->

---

<!-- SIZE:CHALLENGE:START -->
## Challenge Review

> Filled when the estimate is pressure-tested through external review, premortem, or controlled consensus.

### Agreed Drivers
- Broad change surface is real: the task crosses the MTA-32 patch-result adapter,
  MTA-33 feature/participation handoff, derived-output metadata, SketchUp scene mutation, seam
  validation, fallback routing, no-leak contract checks, and hosted validation.
- Host-sensitive replacement remains the dominant complexity. MTA-10 showed that partial derived
  output mutation needs hosted proof for ownership, unsupported children, undo, save/reopen, and
  cleanup behavior.
- The positive proof-chain requirement is mandatory. A fallback-only implementation would be safe
  but would not satisfy MTA-34 because it would not prove local CDT patch solve plus
  patch-relevant constraints plus SketchUp replacement/stitching.
- Keeping public MCP contracts unchanged lowers functional scope but does not lower internal
  validation burden because no public CDT diagnostics may leak.

### Contested Drivers
- Validation burden could look like ordinary hosted matrix breadth, but the contested cost is in
  interpretation and rerun loops: positive replacement, seam-failure safety, stale-neighbor safety,
  undo, save/reopen when metadata persists, and timing must all be shown through the SketchUp
  runtime path. Score 3 remains justified.
- Performance/scanning risk is contested. The plan allows face-scan metadata lookup for the proof,
  but hosted timing must compare local replacement against the current/full-output baseline. If
  snapshot collection or ownership lookup dominates, that becomes a default-enable blocker or
  follow-up patch-index/cache task, not automatic MTA-34 scope expansion.
- Confidence is contested because consensus and premortem tightened the design, but no hosted
  positive-chain evidence exists yet. Confidence stays at 2 rather than rising.

### Missing Evidence
- Hosted positive case where MTA-33 constraints, MTA-32 local patch solve, and MTA-34 replacement
  all participate without falling back.
- Hosted timing evidence comparing local CDT patch replacement cost to the existing current/full
  output path for the same edit shape.
- Hosted undo and, if CDT ownership metadata is persisted, save/reopen evidence for the positive
  replacement path.
- Seam tolerance calibration on realistic adaptive border subdivisions, including reversed edge
  order and asymmetric subdivision cases.
- Actual scan/snapshot cost for derived face ownership and preserved-neighbor seam collection.

### Recommendation
- Keep the predicted profile unchanged after challenge. The consensus and premortem added stronger
  gates, but they did not justify resizing because the plan already treats hosted proof, seam
  validation, fallback/no-leak behavior, and performance evidence as in-scope.
- Revisit the estimate during implementation only if MTA-32 lacks replacement-ready border/topology
  data, MTA-33 feature handoff shape changes materially, seam validation requires solver/patch
  expansion changes, or hosted timing shows scan/index work must be implemented before the proof can
  close.

### Challenge Notes
- Challenge inputs included the finalized plan, task acceptance criteria, MTA-10/MTA-31/MTA-32/MTA-33
  research, two controlled consensus passes, and the premortem.
- The main challenge correction was already incorporated into the plan before this size pass:
  fallback-only safety is insufficient, so hosted positive proof-chain validation is required.
- No predicted score revisions were made. The remaining disagreement is preserved as evidence
  requirements and implementation breakers rather than averaged into a higher or lower estimate.
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
| Functional Scope | 3 | Implemented a significant internally gated local CDT replacement capability, but did not deliver accepted product-loop behavior. |
| Technical Change Surface | 4 | Crossed replacement result adaptation, provider wiring, seam validation, terrain mesh generation, ownership metadata, mutation safety, contract no-leak tests, and hosted diagnostics. |
| Actual Implementation Friction | 4 | Implementation hit hidden lifecycle assumptions: replacement required pre-existing CDT-owned patches, complex seams were under-modeled, and real hosted fixtures exposed topology/material/layering issues. |
| Actual Validation Burden | 4 | Hosted validation dominated closeout through rejected smoke evidence, rebuilt visual fixtures, interpretation loops, blocked complex seam evidence, and unresolved visual/topology quality questions. |
| Actual Dependency Drag | 4 | Completion depended on MTA-32 topology quality, MTA-33 feature handoff, MTA-10 ownership assumptions, and a missing cached patch lifecycle not owned by MTA-34. |
| Actual Discovery Encountered | 4 | The task discovered that the product precondition was absent: stable CDT patch output bootstrap, identity, and repeated-edit lifecycle were not implemented by MTA-32 through MTA-34. |
| Actual Scope Volatility | 4 | The intended closeout shifted from acceptance to blocked handoff, requiring MTA-35 to own the missing lifecycle rather than broadening MTA-34. |
| Actual Rework | 3 | Code review follow-up, hosted unit conversion fixes, border metadata correction, repeated hosted fixture rebuilds, and summary/task reframing revisited completed slices. |
| Final Confidence in Completeness | 1 | Confidence is low for product completion because MTA-34 is closed-blocked; confidence is moderate only for the retained infrastructure and identified blocker. |

### Actual Signals
- MTA-34 produced usable internal replacement infrastructure: `PatchCdtReplacementResult`,
  `PatchCdtReplacementProvider`, `PatchCdtSeamValidator`, ownership metadata, no-delete gates, and
  no-leak/fallback coverage.
- Hosted smoke using tiny rectangles and fake provider injection was rejected as insufficient.
- Larger hosted rows exposed grid-like output, topology-relaxed evidence, UC03 overlap/gap/material
  issues, UC05 inverted/material-bottom artifacts, and real MTA-32 `topology_quality_failed`
  blockers.
- A realistic complex seam could not be honestly represented by the current one-span neighbor
  snapshot model.
- The decisive missing layer is stable CDT-owned patch output lifecycle, now defined as MTA-35.

### Actual Notes
- Calibration is for the blocked closeout outcome, not accepted product behavior.
- Calibration was recorded after `task.md`, `plan.md`, `summary.md`, and the task index were updated
  for the blocked MTA-34 closeout and after `interim-handover.md` was removed.
- MTA-34 should be retrieved later as an analog for integration work that implemented useful
  infrastructure but exposed a missing lifecycle precondition during hosted validation.
<!-- SIZE:ACTUAL:END -->

---

<!-- SIZE:VALIDATION-EVIDENCE:START -->
## Validation Evidence Summary

> Fill only the sections that are relevant. Say `not applicable` where needed.

### Automated Validation
- Focused MTA-34 groups, command/generator/replacement/contract tests, terrain suite, full Ruby
  suite, RuboCop, package verification, and `git diff --check` were run during implementation at
  recorded checkpoints. Later local tweaks still require rerun before retained code is promoted by
  MTA-35.

### Hosted / Manual Validation
- Hosted SketchUp validation was attempted but not accepted as task completion evidence. Tiny
  rectangle/fake-provider smoke rows were rejected. Larger diagnostic rows were useful but exposed
  grid-like output, topology-relaxed evidence, affected-neighbor visual defects, and ownership
  refusal artifact issues.

### Performance Validation
- Hosted timing was partially observed for diagnostic rows, but accepted timing comparison against
  current/full-output replacement was not completed. MTA-35 must capture timing after stable patch
  lifecycle exists.

### Migration / Compatibility Validation
- No public MCP contract, schema, dispatcher, README, or user-facing workflow change was made.
  Save/reopen was removed from the required matrix by user direction.

### Operational / Rollout Validation
- CDT patch replacement stayed internally gated and disabled by default. No default-enable rollout
  recommendation is supported.

### Validation Notes
- Validation proved safety and wiring pieces, but did not prove accepted product behavior. The
  dominant validation result is a blocked matrix caused by missing stable CDT patch output
  lifecycle and unresolved hosted geometry quality issues.
<!-- SIZE:VALIDATION-EVIDENCE:END -->

---

<!-- SIZE:DELTA:START -->
## Estimation Delta Review

> Filled during final calibration. Compare prediction to actual behavior.

- **Most Underestimated Dimension**: Scope volatility. The predicted plan treated durable patch cache
  as a non-goal, but hosted validation showed stable patch lifecycle was a required precondition for
  accepted replacement proof.
- **Most Overestimated Dimension**: None materially. Technical surface and validation burden were
  high as predicted; if anything, both were constrained by closing blocked instead of expanding.
- **Signal Present Early But Underweighted**: The external CDT review explicitly centered cached
  local patches, patch store/index, stable seams, and patch emitter responsibilities. MTA-34 assumed
  existing owned CDT output instead of owning that lifecycle.
- **Genuinely Unknowable Factor**: The exact hosted visual failure shape: grid-like CDT output,
  UC03 overlap/gap/material artifacts, UC05 inverted faces, and SketchUp's nonplanar face rejection
  for realistic preserved seams.
- **Future Similar Tasks Should Assume**: Local replacement cannot be proven from mutation
  mechanics alone. It requires production-owned output bootstrap, stable identity, repeated-edit
  metadata lifecycle, hosted visual proof, and explicit timing evidence.

### Calibration Notes
- Dominant actual failure mode: missing lifecycle precondition for the replacement mechanism.
- Future task splitting should separate "can replace owned output safely" from "can create and
  maintain the owned output lifecycle" unless a stable patch store/index already exists.
- The MTA-35 task definition is the follow-up artifact for the missing lifecycle; this calibration
  should not be read as product acceptance for MTA-34.
<!-- SIZE:DELTA:END -->

---

<!-- SIZE:TAGS:START -->
## Retrieval Tags

Use canonical values from the repo task-estimation taxonomy when present. Keep this as a compact analog-search index, not coverage. Target 8-14 tags.

- `archetype:integration`
- `scope:managed-terrain`
- `systems:terrain-output`
- `systems:terrain-mesh-generator`
- `systems:scene-mutation`
- `systems:managed-object-metadata`
- `validation:hosted-matrix`
- `validation:undo`
- `validation:performance`
- `contract:no-public-shape-change`
- `host:special-scene`
- `host:blocked-matrix`
- `risk:undo-semantics`
- `risk:metadata-storage`
- `risk:performance-scaling`
- `volatility:high`
- `friction:high`
- `rework:medium`
- `confidence:low`
<!-- SIZE:TAGS:END -->
