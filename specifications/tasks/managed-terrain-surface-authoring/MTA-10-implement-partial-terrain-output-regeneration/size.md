# Size: MTA-10 Implement Partial Terrain Output Regeneration

**Task ID**: `MTA-10`
**Title**: Implement Partial Terrain Output Regeneration
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
- **Primary Scope Area**: partial terrain derived-output regeneration
- **Likely Systems Touched**:
  - terrain output ownership
  - mesh region replacement
  - dirty sample to affected cell-window planning
  - derived face ownership metadata
  - seam and adjacency handling
  - derived markers and normals
  - undo/save/reopen hosted validation
  - full-grid fallback and unsupported-child refusal behavior
- **Validation Class**: mixed / hosted-matrix / performance-sensitive
- **Likely Analog Class**: host-sensitive terrain output mutation

### Identity Notes
- Output-layer task with high hidden complexity because it changes from full disposable output replacement to selective face replacement while preserving full-grid fallback.
- Planning rebaseline: durable localized-detail terrain representation has been separated to MTA-11; MTA-10 owns only derived-output ownership metadata needed for local partial regeneration.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Substantial performance-visible behavior for localized edits, while public edit modes may remain unchanged. |
| Technical Change Surface | 3 | Likely touches output planning, mesh generation, derived-output metadata, cleanup, fallback, tests, and hosted validation, but not public schemas or terrain-state repository dispatch. |
| Hidden Complexity Suspicion | 4 | Dirty sample to cell-window conversion, seam coherence, derived metadata, normals, fallback/refusal, and output ownership are all high-risk. |
| Validation Burden Suspicion | 4 | Needs live SketchUp validation for partial edits, adjacency, undo, save/reopen, markers, normals, and performance. |
| Dependency / Coordination Suspicion | 2 | Depends on completed MTA-08 and MTA-09 plus hosted validation access; durable localized representation is now outside this task. |
| Scope Volatility Suspicion | 3 | Scope can still expand if edge ownership, seam validation, or hosted save/reopen behavior requires more output metadata than planned. |
| Confidence | 3 | Direction is clearer after planning, targeted UE research, and MTA-09 handoff evidence, but partial SketchUp mutation remains unproven. |

### Early Signals
- MTA-08 proved production full-grid bulk output and hosted output invariants, not partial replacement.
- MTA-09 proved dirty-window intent reaches the generator, but execution stayed full-grid.
- Targeted UE Landscape research supports overlap-based mapping from changed samples to owned update units.
- MTA-03 and MTA-04 show terrain output correctness depends on hosted checks for normals, markers, cleanup, undo, save/reopen, and responsiveness.
- Full bulk regeneration must remain the safe fallback if partial seams cannot be proven.

### Early Estimate Notes
- Seed was refreshed during planning after MTA-10 was scoped to local derived-output regeneration and MTA-11 was kept for durable localized-detail representation.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

| Dimension | Predicted (0-4) | Rationale |
|---|---:|---|
| Functional Scope | 3 | Delivers a behavior-visible performance improvement for localized terrain edits while keeping public edit modes and response shapes stable. |
| Technical Change Surface | 3 | Touches output planning, a new output cell-window value object, mesh generation, derived-output metadata, fallback logic, command integration assumptions, tests, and hosted validation, but avoids loader, dispatcher, public schema, repository dispatch, and v2 state migration. |
| Implementation Friction Risk | 3 | Partial SketchUp face replacement, metadata-based ownership checks, fallback correctness, deterministic cell emission, and seam preservation are likely to resist simple implementation more than MTA-08/MTA-09 did. |
| Validation Burden Risk | 4 | Acceptance depends on unit, generator, no-leak, persistence no-drift, and live SketchUp validation for partial replacement, legacy fallback, undo, save/reopen, seams, markers, normals, responsiveness, and performance. |
| Dependency / Coordination Risk | 2 | MTA-08 and MTA-09 are complete, and no public contract or v2 representation dependency remains, but hosted validation/deployment alignment is still required for closeout. |
| Discovery / Ambiguity Risk | 3 | The dirty sample to cell-window rule is now concrete, but real SketchUp behavior around partial face deletion, edge cleanup, attribute persistence, and seam inspection remains implementation-time evidence. |
| Scope Volatility Risk | 2 | The MTA-11 split is resolved and full fallback constrains scope, but volatility remains if edge ownership or save/reopen behavior requires additional output metadata. |
| Rework Risk | 3 | MTA-03/MTA-04 actuals show live host output behavior can force fixes around traversal, deletion safety, normals, and undo even when local tests pass. |
| Confidence | 3 | Planning evidence is solid, analogs are relevant, and the implementation boundary is explicit, but true partial output mutation has not yet been proven in SketchUp. |

### Top Assumptions

- Derived face metadata persists through SketchUp save/reopen reliably enough to identify affected cells.
- Face-owned replacement is sufficient; edge ownership metadata is not required for cleanup correctness.
- Dirty sample windows from existing edit diagnostics are accurate and can be converted to affected cell windows without edit-kernel changes.
- Full-grid regeneration remains a safe fallback for legacy marker-only output and ownership-uncertain states.
- Hosted validation access is available for loaded-code checks, partial/fallback cases, undo, save/reopen, and performance timing.

### Estimate Breakers

- SketchUp face or edge cleanup behavior prevents safe deletion of only affected faces.
- Save/reopen loses or mutates derived face ownership attributes.
- Seam inspection reveals that deterministic replacement cells still leave boundary defects.
- Edge ownership metadata becomes required for correctness, not just diagnostics.
- Partial regeneration needs persisted terrain source representation changes, which would violate the MTA-10/MTA-11 split.

### Predicted Signals

- Closest useful analogs: MTA-08 for output invariant validation, MTA-09 for dirty-window handoff, and MTA-04/MTA-03 for host-sensitive output rework risk.
- MTA-08/MTA-09 were low-friction only because they avoided partial face replacement; they should not lower MTA-10 friction too far.
- Targeted UE research supports overlap expansion from changed samples to affected output units, reducing ambiguity around dirty-region definition.
- The plan deliberately avoids public contract updates, which lowers coordination risk but does not lower hosted validation burden.
- Full fallback should reduce user-facing risk and scope volatility, but it increases test matrix breadth.

### Predicted Estimate Notes

- Planning rebaseline removed the broad v2 localized-representation dependency from MTA-10 and replaced it with narrower derived-output ownership metadata.
- Validation burden is predicted very high because correctness requires live SketchUp proof, not because public contracts change.
- Confidence is medium-high for the plan shape and medium for implementation completeness until hosted partial mutation evidence exists.
<!-- SIZE:PREDICTED:END -->

---

<!-- SIZE:CHALLENGE:START -->
## Challenge Review

### Agreed Drivers

- Validation burden remains the dominant task driver because trusted partial regeneration requires hosted proof for true partial replacement, legacy fallback, undo, save/reopen, seams, markers, normals, responsiveness, and performance.
- Implementation friction remains high because the task changes from whole-output replacement to exact face ownership, partial deletion, and targeted replacement.
- MTA-08 and MTA-09 are useful baselines but should not reduce the estimate too far; they intentionally avoided partial SketchUp face replacement.
- Public contract coordination remains low because the plan preserves request/response shapes, loader schemas, dispatcher behavior, and persisted terrain state.
- Scope boundary is clearer after premortem: MTA-10 owns derived-output metadata only; MTA-11 owns durable localized terrain source representation.

### Contested Drivers

- Whether validation burden should be treated as `3` instead of `4`: hosted matrices can be routine in this repo, but this task adds save/reopen metadata proof, numeric seam checks, true-partial-vs-fallback verification, and performance interpretation. Keep `4`.
- Whether scope volatility should rise above `2`: edge ownership or host persistence issues could expand metadata, but full fallback and the MTA-11 boundary keep this from becoming broad representation work. Keep `2`.
- Whether implementation friction should rise to `4`: partial mutation is risky, but the dirty-window handoff, full-grid generator, and fallback policy provide a bounded path. Keep `3`.

### Missing Evidence

- No hosted proof yet that face-level ownership metadata survives save/reopen and can drive a later partial edit.
- No hosted proof yet that deleting only affected faces leaves adjacent SketchUp geometry and edge markers coherent.
- No performance proof yet that representative localized edits take the partial path often enough to justify the feature.
- No implementation proof yet that edge ownership can remain marker-only.

### Recommendation

- Proceed with implementation as planned; do not split or merge with MTA-11.
- Keep the predicted profile unchanged.
- Treat hosted save/reopen, numeric seam validation, and true-partial path evidence as acceptance gates, not optional closeout notes.
- Record drift during implementation if edge ownership becomes required, partial fallback dominates supported cases, or source-state representation changes become necessary.

### Challenge Notes

- Premortem evidence strengthened the validation plan and implementation guardrails but did not materially change the task boundary.
- The challenged estimate and finalized plan agree: this is a host-sensitive output mutation task with no public contract change and no terrain-state v2 scope.
<!-- SIZE:CHALLENGE:END -->

---

<!-- SIZE:DRIFT:START -->
## Drift Log

No material drift recorded yet.
<!-- SIZE:DRIFT:END -->

---

<!-- SIZE:ACTUAL:START -->
## Actual Profile

| Dimension | Actual (0-4) | Rationale |
|---|---:|---|
| Functional Scope | 3 | Delivered behavior-visible partial terrain output regeneration for localized edits, while keeping public edit modes and response shapes stable. |
| Technical Change Surface | 3 | Touched output planning, a new cell-window value object, mesh generation, derived-output metadata, terrain command target resolution, README wording, contract tests, and terrain-focused suites without changing public schemas or persisted terrain state shape. |
| Actual Implementation Friction | 3 | Implementation stayed within the planned runtime boundary, but real SketchUp face recognition, affected-edge cleanup, builder partial emission, per-face digest removal, and the direct owner resolver required meaningful source adjustments. |
| Actual Validation Burden | 4 | Hosted validation drove repeated fix/redeploy/rerun loops, save/reopen and undo checks, unsupported-child refusal checks, near-cap terrain checks, and a performance investigation that separated generator cost from target-resolution cost. |
| Actual Dependency Drag | 2 | Work depended on hosted SketchUp deployment, scene save/reopen coordination, and MCP wrapper execution, but no upstream task or public-client coordination dominated delivery. |
| Actual Discovery Encountered | 4 | Significant host-time discovery changed the implementation: real `Sketchup::Face` behavior differed from fake tests, orphan edges required cleanup, global per-face digest linkage undercut partial performance, and recursive target resolution was the larger bottleneck. |
| Actual Scope Volatility | 2 | The task shape stayed within MTA-10 output regeneration and did not absorb MTA-11 durable representation work, but source scope expanded to include command-level owner resolution and removal of the digest ownership model. |
| Actual Rework | 3 | Completed slices were revisited several times: partial face detection, erase semantics, builder emission, digest/revision relinking, and target resolution all needed correction after review or hosted evidence. |
| Final Confidence in Completeness | 3 | Confidence is strong: focused and full suites, RuboCop, package verification, final `grok-4.20` review, hosted correctness matrix, save/reopen checks, undo checks, and performance timings all passed or were accepted as closeout evidence. |
<!-- SIZE:ACTUAL:END -->

---

<!-- SIZE:VALIDATION-EVIDENCE:START -->
## Validation Evidence Summary

- **Automated red/green evidence**: focused skeletons started red (`50 runs, 284 assertions, 3 failures, 15 errors`) and the focused MTA-10 suite later passed (`50 runs, 370 assertions, 0 failures`).
- **Final focused checks**: generator suite passed (`25 runs, 206 assertions`), terrain command suite passed (`17 runs, 71 assertions`), related contract and output-plan suites passed, and no internal ownership vocabulary leaked into public output or persisted state.
- **Final broad checks**: full terrain suite passed (`137 runs, 1253 assertions, 2 skips`), full Ruby suite passed (`719 runs, 3403 assertions, 35 skips`), full RuboCop passed (`188 files inspected, no offenses`), `git diff --check` passed, and `bundle exec rake package:verify` produced `dist/su_mcp-0.22.0.rbz`.
- **Code review evidence**: `mcp__pal__.codereview` with `grok-4.20` found one critical iterator-yield defect, medium digest/relink concerns, and low documentation/planning concerns during the first review; all accepted findings were addressed. Final post-performance review found no additional source findings.
- **Hosted correctness evidence**: 10 MCP client scenarios were accepted for partial replacement, non-square edge clipping, legacy fallback, duplicate/incomplete ownership fallback, unsupported-child refusal, undo, save/reopen public load/edit, and near-cap terrain behavior.
- **Hosted validation execution cost**: hosted proof required repeated fix-oriented loops, including real host face detection, partial erase/edge cleanup, orphan cleanup, builder restoration, digest model correction, and resolver shortcut validation.
- **Performance evidence**: 100x100 terrain scenarios showed corrected partial edits replacing 8 to 1,352 faces instead of 19,602 faces and running about 57-69% faster than forced full fallback in the accepted performance matrix.
<!-- SIZE:VALIDATION-EVIDENCE:END -->

---

<!-- SIZE:DELTA:START -->
## Estimation Delta Review

### What the Estimate Got Right

- Functional scope, technical surface, implementation friction, validation burden, dependency drag, scope volatility, and rework were directionally accurate.
- The prediction correctly treated hosted validation as the dominant closeout driver and called out edge cleanup, save/reopen, undo, seams, markers, normals, and performance as acceptance risks.
- The MTA-10/MTA-11 split held: durable localized terrain representation did not leak into this task.

### What Was Underestimated

- **Discovery / Ambiguity** was underestimated (`3` predicted, `4` actual). The plan anticipated SketchUp-hosted surprises, but not that performance proof would expose two separate bottlenecks: retained-face digest relinking and recursive target resolution before edit execution.
- The practical cost of proving partial-vs-full behavior was underweighted because the public contract intentionally does not expose strategy telemetry, forcing greybox inspection and temporary tracing during hosted validation.

### What Was Overestimated

- No major dimension was materially overestimated. Edge ownership did not need to become durable metadata, persisted terrain state stayed unchanged, and no public schema or dispatcher update was required.

### Early Signals That Should Have Been Weighted More

- MTA-08/MTA-09 proved full-output and dirty-window planning, but they did not exercise selective deletion in real SketchUp. That gap correctly predicted validation burden and should also have raised discovery risk.
- The target-reference path was not originally treated as performance-sensitive because the task focused on output regeneration. Large-scene performance tasks should include pre-edit target resolution in the measured path.
- Whole-state digest linkage was useful as a summary invariant, but per-face relinking conflicted with the purpose of partial regeneration. Future partial-output tasks should avoid global retained-entity rewrites unless they are proven cheap.

### Dominant Actual Failure Mode

Host-sensitive partial scene mutation and measurement: fake-local geometry did not fully model live SketchUp entity behavior, and initial performance measurements mixed output regeneration cost with unrelated scene traversal cost.

### Future Retrieval Facets

Use this task as an analog for:

- hosted partial scene mutation with conservative full fallback
- performance-sensitive terrain output work with no public contract drift
- internal metadata ownership that must not leak publicly
- repeated hosted fix loops around real SketchUp API behavior
- large-scene performance where command preparation and target resolution can dominate the intended optimized operation

Useful canonical facets: `scope:managed-terrain`, `systems:terrain-output`, `systems:terrain-mesh-generator`, `systems:target-resolution`, `validation:hosted-matrix`, `validation:performance`, `validation:persistence`, `validation:undo`, `host:repeated-fix-loop`, `host:save-reopen`, `host:performance`, `risk:host-api-mismatch`, `risk:performance-scaling`, `risk:partial-state`, `friction:high`, `rework:high`, `confidence:high`.
<!-- SIZE:DELTA:END -->

---

<!-- SIZE:TAGS:START -->
## Retrieval Tags

- `archetype:platform`
- `archetype:performance-sensitive`
- `scope:managed-terrain`
- `validation:hosted-matrix`
- `validation:contract`
- `validation:persistence`
- `validation:undo`
- `validation:performance`
- `host:save-reopen`
- `host:undo`
- `host:performance`
- `contract:no-public-shape-change`
- `systems:command-layer`
- `systems:target-resolution`
- `systems:terrain-output`
- `systems:terrain-mesh-generator`
- `host:repeated-fix-loop`
- `host:redeploy-restart`
- `risk:host-api-mismatch`
- `risk:host-persistence-mismatch`
- `risk:undo-semantics`
- `risk:performance-scaling`
- `risk:partial-state`
- `risk:contract-drift`
- `volatility:medium`
- `friction:high`
- `rework:high`
- `confidence:high`
<!-- SIZE:TAGS:END -->
