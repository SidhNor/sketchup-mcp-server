# Task: MTA-36 Productize Windowed Adaptive Patch Output Lifecycle For Fast Local Terrain Edits
**Task ID**: `MTA-36`
**Title**: `Productize Windowed Adaptive Patch Output Lifecycle For Fast Local Terrain Edits`
**Status**: `completed`
**Priority**: `P1`
**Date**: `2026-05-11`

## Linked HLD

- [Managed Terrain Surface Authoring](../../../hlds/hld-managed-terrain-surface-authoring.md)

## Problem Statement

Current adaptive terrain output is the active compact production output path for detailed managed
terrain, but its edit regeneration path still behaves like a full-output rebuild: adaptive
regeneration erases all derived output and emits the complete adaptive mesh again. Regular-grid
output already has a narrow dirty-cell replacement path, but it is not the practical production
path for large terrain. MTA-35 is planned to make CDT patch edits fast, but it currently combines
two hard problems at once: the local patch/window output lifecycle and CDT-specific solver,
topology, and seam risk.

This task must productize the local patch/window lifecycle first using the existing adaptive
sampling/output behavior as the mesh emitter. The goal is to prove stable output ownership,
dirty-window-to-patch mapping, no-delete replacement, repeated metadata reuse, hosted timing, and
reload/readback on the active adaptive path. MTA-35 can then be replanned to use the proven
windowed patch lifecycle while swapping the per-patch mesh builder from adaptive output to CDT.

The first implementation pass proved the lifecycle using one SketchUp group per adaptive patch.
Hosted stress rows showed that this representation can be stitched numerically, but it is not the
right final geometry shape for CDT readiness: separate patch groups do not share topology, make
cross-patch simplification awkward, and risk teaching MTA-35 the wrong output abstraction. MTA-36
is therefore amended before acceptance: stable patches are logical ownership domains inside one
derived mesh output, not final separate geometry islands.

## Goals

- Add a production windowed replacement lifecycle for adaptive terrain output without changing
  public terrain command contracts.
- Define stable patch or supertile ownership for adaptive output that is independent of the
  adaptive cells that may split or merge after edits.
- Map edit dirty output windows to affected stable adaptive output patches.
- Add reusable stable patch/window lifecycle pieces that MTA-35 can later consume for CDT:
  dirty-window resolution, stable patch identity, registry/face metadata, batch prevalidation,
  no-delete mutation, fallback/refusal routing, timing buckets, and hosted reload/readback evidence.
- Rebuild adaptive mesh output only for affected stable patches plus required neighbor/conformance
  bands, while preserving unaffected output.
- Emit accepted production output as one derived terrain mesh container with logical patch
  ownership on faces and registry entries, not as one final SketchUp group per patch.
- Replace local patch output through validated face-cavity mutation inside the single mesh
  context, so retained neighbor faces can share topology with newly emitted replacement faces.
- Preserve old output until all affected adaptive patch output validates.
- Make newly emitted adaptive patch metadata usable for repeated same/adjacent local edits.
- Produce hosted visual, timing, fallback/no-delete, undo, and reload/readback evidence for the
  local adaptive patch lifecycle.
- Provide a concrete lifecycle substrate that MTA-35 can reuse for fast local CDT patch output.

## Acceptance Criteria

```gherkin
Scenario: Adaptive output is bootstrapped with stable patch ownership
  Given a managed terrain surface that uses adaptive terrain output
  When derived output is created or fully rebuilt
  Then the accepted production output is emitted under one derived terrain mesh container
  And logical patch or supertile ownership is stored in registry and face metadata
  And each emitted adaptive face can be traced to its stable patch ownership
  And the patch identity does not depend on transient adaptive cell splits or a later dirty edit window
  And adjacent logical patches are not separated into final independent SketchUp group islands
  And public terrain command responses do not expose patch identifiers or adaptive internals

Scenario: Single mesh local replacement performs bounded cavity mutation
  Given a managed terrain surface with one derived terrain mesh container and logical patch face ownership
  When `edit_terrain_surface` applies a valid local terrain edit
  Then the affected replacement domain is built and validated before accepted mesh mutation
  And only faces owned by affected logical patches and required conformance-band patches are deleted
  And replacement faces are emitted into the same derived mesh context
  And retained neighbor faces remain present and can share coincident boundary topology with replacement faces
  And orphan internal edges, duplicate seam edges, and duplicate layered terrain are removed or refused before success is reported

Scenario: Dirty edit maps to affected adaptive output patches
  Given a managed terrain surface with stable logical adaptive patch output ownership
  When a valid terrain edit produces a dirty output window
  Then the dirty window maps to one or more affected stable adaptive output patches
  And the mapping includes the required adaptive conformance or neighbor band
  And unaffected stable patches remain outside the replacement set

Scenario: Adaptive local replacement preserves unaffected terrain output
  Given a managed terrain surface with existing single-mesh adaptive output
  When `edit_terrain_surface` applies a valid local terrain edit
  Then all affected adaptive patches are rebuilt and validated before old output is erased
  And only affected logical patch faces and required conformance-band faces are replaced
  And unaffected adaptive faces remain present and unchanged
  And no duplicate layered terrain, hidden stale faces, orphan derived edges, or duplicate seam edges remain

Scenario: Repeated edits reuse newly emitted adaptive patch metadata
  Given a local adaptive patch replacement has completed
  When a second valid edit affects the same or an adjacent stable patch
  Then the newly emitted patch ownership metadata is sufficient for the next replacement decision
  And the second replacement does not depend on stale metadata from the original full rebuild
  And registry or face metadata remains consistent after the second edit

Scenario: Adaptive local replacement falls back safely
  Given adaptive patch ownership, local rebuild, conformance validation, metadata validation,
  unsupported child checks, or mutation safety fails
  When the terrain command handles the failure
  Then old derived output is not erased before a safe path is available
  And the command either regenerates current/full adaptive output, keeps old output with a sanitized refusal, or aborts the SketchUp operation
  And public responses remain free of patch ids, registry internals, raw triangles, fallback enums, and adaptive-cell diagnostics

Scenario: Hosted proof demonstrates fast local adaptive edits
  Given hosted SketchUp validation fixtures with medium terrain, repeated local edits, adjacent
  patch edits, preserved neighbors, and fallback/refusal cases
  When the adaptive patch lifecycle is exercised through normal terrain commands
  Then accepted cases are visually inspectable as complete terrain output in their true position
  And accepted cases use one derived adaptive mesh container with logical patch ownership
  And timing separates command preparation, dirty-window mapping, adaptive patch rebuild,
  ownership or face lookup, mutation, registry or attribute writes, audit, and total runtime
  And local adaptive replacement is materially cheaper than full adaptive regeneration or a blocker is recorded

Scenario: Registry metadata survives reload or invalidates safely
  Given a managed terrain surface with adaptive patch registry or face ownership metadata
  When hosted validation saves and reloads the scene or performs an equivalent reload/readback check
  Then registry and face ownership metadata can be read back and used safely
  Or the adaptive patch registry invalidates explicitly and routes future local edits to safe full regeneration or refusal
```

## Non-Goals

- Implementing CDT, constrained Delaunay, residual CDT solving, or MTA-35 patch-local CDT proof.
- Replacing the long-term CDT direction selected by MTA-24.
- Optimizing adaptive visual quality beyond what is necessary to preserve the current adaptive
  output behavior inside local patches.
- Creating public patch controls, backend selectors, adaptive diagnostics, or response-shape changes.
- Persisting adaptive cells, raw mesh vertices, raw triangles, or patch registry data as terrain
  source state.
- Implementing a full spatial index/store unless timing proves the lightweight patch ownership
  path cannot preserve locality.
- Solving arbitrary adaptive split/merge diffs by using transient adaptive cells as stable identity.
- Allowing CDT-quality cross-patch simplification to ignore local replacement boundaries; if
  simplification changes retained-boundary topology, the replacement domain must expand or refuse.

## Business Constraints

- The primary product goal remains fast local CDT output, not a new long-term adaptive backend
  strategy.
- MTA-36 should reduce MTA-35 delivery risk by proving the local output lifecycle separately from
  CDT solver/topology risk.
- Normal public terrain workflows must remain contract-compatible.
- Current full adaptive regeneration must remain a safe fallback until local adaptive replacement is
  proven in hosted validation.
- The task must produce hosted timing evidence that local patch replacement is actually faster than
  full adaptive regeneration, not just architecturally cleaner.

## Technical Constraints

- Terrain state remains authoritative; adaptive patch output and any registry are disposable
  derived output under the managed terrain owner.
- Stable patch identity must be based on owner-local terrain/sample coordinates or a fixed patch
  lattice, not on transient adaptive cells.
- Stable patch ownership must be logical. The final accepted terrain output must not depend on one
  persistent SketchUp group per patch as the topology boundary.
- Adaptive cells may split or merge after an edit; local replacement must account for conformance
  or neighbor bands so mixed-resolution seams remain valid.
- Single-mesh replacement must treat SketchUp as a face/edge entity graph, not an indexed mesh
  buffer. It must explicitly select affected faces, protect retained neighbor faces, handle shared
  boundary edges, and clean orphan internal edges.
- Temporary staging groups are allowed for no-delete validation, but successful accepted output
  must end as one derived terrain mesh container.
- Existing adaptive output conformance behavior from MTA-21 must remain intact.
- Current regular-grid partial replacement ownership can be used as an analog, but full-grid output
  is not an acceptable production replacement path for detailed adaptive terrain.
- Public MCP tool names, request schemas, dispatcher routes, and response shapes must remain
  unchanged.
- Hosted validation must cover real SketchUp face lifecycle, edge cleanup, metadata persistence,
  undo behavior, reload/readback or safe invalidation, and timing.
- Any lifecycle pieces intended for MTA-35 reuse must not depend on adaptive-cell-specific identity.
- Lifecycle interfaces should be named and shaped so CDT can later reuse them without depending on
  adaptive-specific mesh emission:
  - dirty-window-to-stable-patch resolver;
  - stable patch registry store;
  - stable face ownership metadata;
  - affected-patch batch prevalidation;
  - no-delete mutation/fallback sequencing;
  - hosted timing and reload/readback probe rows.

## Dependencies

- `MTA-21`
- `MTA-22`
- `MTA-23`
- `MTA-35`
- [Managed Terrain Surface Authoring HLD](../../../hlds/hld-managed-terrain-surface-authoring.md)

## Relationships

- follows `MTA-21` because adaptive output must remain conforming when local windows are replaced
- follows `MTA-23` because the existing adaptive sampling/output behavior and hosted fixture lessons inform the active path
- uses `MTA-35` planning decisions as lifecycle requirements while deliberately excluding CDT-specific solver work
- should trigger a replan of `MTA-35` so CDT can be implemented on top of the proven windowed patch lifecycle
- informs any later spatial-index, registry-store, or default-enable decision for fast local terrain output

## Carry-Forward From MTA-35 Planning

MTA-36 intentionally absorbs the non-CDT parts of the MTA-35 plan so they can be proven against the
active adaptive output path before CDT is reintroduced.

Shared lifecycle requirements to carry forward:

- Stable patch identity must be independent of dirty edit windows and transient emitted topology.
- Stable patch ownership/output domains must be separate from expanded solve/rebuild domains.
- Stable patch ownership/output domains must not require separate final SketchUp group/entity
  contexts per patch.
- Dirty-window mapping must account for edit influence, falloff/fairing, seam or conformance bands,
  and hard/protected feature safety margins where applicable.
- Owner-level patch registry metadata must remain derived output state, not terrain source state.
- Emitted faces must carry enough stable ownership metadata for repeated edits and integrity checks.
- Affected patches must be built and validated as a batch before old output is erased.
- Local replacement failure must not leave hidden pending retry state or claim fresh output when
  saved terrain state and derived output are out of sync.
- Public responses must not leak patch ids, raw triangles, registry internals, backend selection,
  fallback enums, or adaptive/CDT solver vocabulary.
- Hosted proof must include timing buckets, fallback/no-delete, repeated edits, undo, and
  reload/readback or safe invalidation.

CDT-specific MTA-35 items deliberately not carried into MTA-36:

- MTA-24 CDT substrate audit.
- `PatchLocalCdtProof` production mesh handoff.
- CDT topology, residual, constrained-edge, and seam validation.
- CDT patch replacement result adaptation.
- Arbitrary multi-span CDT seam evidence.

## Related Technical Plan

- [Technical implementation plan](./plan.md)

## Success Metrics

- Hosted validation shows a normal command-path edit replacing only affected adaptive patch output
  instead of erasing and rebuilding all adaptive output.
- Hosted validation shows accepted output as one derived terrain mesh container with logical
  patch ownership, not hundreds of final patch groups.
- Repeated hosted edits prove newly emitted adaptive patch metadata is reusable for future local
  replacement.
- Intersecting hosted edits across different edit modes prove single-mesh cavity replacement keeps
  stitch/topology audits valid after repeated overlapping mutations.
- Local adaptive replacement timing is materially cheaper than full adaptive regeneration on at
  least one representative medium fixture, or a concrete blocker is recorded.
- Hosted visual inspection confirms no accepted case has duplicate layered output, stale faces,
  orphan derived edges, visible adaptive seam gaps, or broken hidden-edge behavior.
- Reload/readback evidence proves patch registry and face ownership metadata can be used safely
  after reload or invalidates explicitly without public contract drift.
- Public contract tests remain green and no adaptive patch ids, raw triangles, registry internals,
  fallback enums, or adaptive-cell diagnostics leak into public responses.
- The final summary identifies which lifecycle pieces are ready for MTA-35 reuse and which require
  follow-up before CDT patch output can rely on them.
