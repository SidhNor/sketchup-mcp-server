# Size: MTA-07 Define Scalable Terrain Representation Strategy

**Task ID**: `MTA-07`  
**Title**: `Define Scalable Terrain Representation Strategy`  
**Status**: `seeded`  
**Created**: `2026-04-26`  
**Last Updated**: `2026-04-26`  

**Related Task**: [task.md](./task.md)  
**Related Plan**: none yet  
**Related Summary**: none yet  

---

<!-- SIZE:IDENTITY:START -->
## Identity

- **Task Archetype**: platform
- **Primary Scope Area**: managed terrain scalable representation
- **Likely Systems Touched**:
  - terrain state schema and representation model
  - terrain repository and storage strategy
  - derived output generation and regeneration granularity
  - edit kernel representation boundary
  - evidence and migration/refusal contracts
  - hosted SketchUp performance validation
- **Validation Class**: mixed
- **Likely Analog Class**: performance-sensitive terrain state architecture rebaseline

### Identity Notes
- This is currently a strategy and architecture task rather than a direct implementation slice. It may spawn follow-on implementation tasks for tiled state, local refinement, patch overlays, chunked output regeneration, storage migration, or sidecar-backed payloads.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Defines the next supported terrain representation direction beyond one uniform heightmap grid and affects future edit workflows, but does not yet require a new public MCP tool. |
| Technical Change Surface | 4 | Candidate directions touch state schema, repository storage, derived output regeneration, edit-kernel boundaries, evidence contracts, compatibility, and migration behavior. |
| Hidden Complexity Suspicion | 4 | Representation choices can create seams around resolution, chunk boundaries, blend behavior, payload size, undo, and existing `heightmap_grid` compatibility. |
| Validation Burden Suspicion | 4 | Any selected direction needs storage/migration checks, hosted SketchUp performance evidence, output regeneration verification, undo behavior, and JSON-safe refusal/evidence validation. |
| Dependency / Coordination Suspicion | 3 | Depends on MTA-03 and MTA-04 findings, informs MTA-05 and MTA-06, and may split into multiple follow-on implementation tasks. |
| Scope Volatility Suspicion | 4 | The task could remain a design decision, or expand into schema/storage/output implementation if planning narrows it too aggressively. |
| Confidence | 2 | Strong early signals exist, but the accepted representation direction and implementation boundary are not yet planned. |

### Early Signals
- MTA-03 performance improved materially, but near-cap terrain creation still costs about 17-18 seconds MCP time and about 26-27 seconds external wall time for roughly 10,000 samples.
- MTA-03 adoption is acceptable as a one-time workflow after improvements, with representative 80 m x 80 m wavy adoption at about 31 seconds MCP time and about 43 seconds external wall time.
- MTA-04 planning accepted full derived-output regeneration for the bounded grade edit MVP, but explicitly deferred tiled, chunked, localized refinement, and partial output regeneration decisions.
- The managed terrain HLD already preserves materialized terrain state as authoritative and generated SketchUp geometry as derived output, so representation work must extend that contract rather than replace it with live generated mesh edits.
- UE research suggests useful comparison concepts: componentized heightmap data, rectangular heightmap read/write regions, LOD, LOD blending, streaming proxies, World Partition, edit layers, and local patch systems.
- UE research also suggests the repo should not assume arbitrary adaptive per-small-area heightmap resolution is the default answer; UE Landscape appears to scale through componentization and related systems rather than making generated mesh geometry authoritative.
- Future bounded edits, corridor transitions, and terrain fairing kernels may depend on whether the uniform-grid substrate remains sufficient or whether localized detail, tiled state, overlays, or sidecar-backed payloads are required first.

### Early Estimate Notes
- This seed treats MTA-07 as a high-ambiguity platform strategy task. If later planning narrows it to documentation only, implementation friction may drop; if it includes schema, storage, output, or migration implementation, the high change-surface and validation scores should remain.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

> Filled during task planning. This is the main pre-implementation estimate.

Not filled yet.
<!-- SIZE:PREDICTED:END -->

---

<!-- SIZE:CHALLENGE:START -->
## Challenge Review

> Filled when the estimate is pressure-tested through external review, premortem, or controlled consensus.

### Agreed Drivers
- Not filled yet.

### Contested Drivers
- Not filled yet.

### Missing Evidence
- Not filled yet.

### Recommendation
- Not filled yet.

### Challenge Notes
- Not filled yet.
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

Not filled yet.
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

- **Most Underestimated Dimension**: Not filled yet.
- **Most Overestimated Dimension**: Not filled yet.
- **Signal Present Early But Underweighted**: Not filled yet.
- **Genuinely Unknowable Factor**: Not filled yet.
- **Future Similar Tasks Should Assume**: Not filled yet.

### Calibration Notes
- Not filled yet.
<!-- SIZE:DELTA:END -->

---

<!-- SIZE:TAGS:START -->
## Retrieval Tags

- `archetype:platform`
- `scope:managed-terrain-scalable-representation`
- `validation:mixed`
- `systems:terrain-state-storage-output-edit-kernels-evidence`
- `volatility:high`
- `friction:high`
- `rework:high`
- `confidence:medium`
<!-- SIZE:TAGS:END -->
