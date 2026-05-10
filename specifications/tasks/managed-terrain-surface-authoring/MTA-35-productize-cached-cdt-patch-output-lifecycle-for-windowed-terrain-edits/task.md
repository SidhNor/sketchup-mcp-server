# Task: MTA-35 Productize Cached CDT Patch Output Lifecycle For Windowed Terrain Edits
**Task ID**: `MTA-35`
**Title**: `Productize Cached CDT Patch Output Lifecycle For Windowed Terrain Edits`
**Status**: `defined`
**Priority**: `P1`
**Date**: `2026-05-10`

## Linked HLD

- [Managed Terrain Surface Authoring](../../../hlds/hld-managed-terrain-surface-authoring.md)

## Problem Statement

MTA-32 proved that bounded local CDT patch solving can work as internal proof evidence. MTA-33
proved that local CDT input can exclude far feature constraints while preserving touched hard and
protected semantics. MTA-34 built replacement, seam-validation, ownership, and no-delete safety
infrastructure, but it exposed a missing production precondition: normal terrain output does not yet
create or maintain stable CDT-owned patch output for MTA-34 to replace.

The external CDT review recommended treating terrain output as cached local patches with stable
patch domains, patch-local constraints, dirty-window-to-patch mapping, seam ownership, and local
entity replacement. This task must productize that missing lifecycle for internally gated CDT
output, so a normal managed terrain edit can create, maintain, and replace affected CDT patches
through the real command path instead of relying on handcrafted fixtures or pre-seeded CDT faces.

## Goals

- Create and maintain internally gated CDT-owned patch output as disposable derived terrain
  geometry.
- Define stable patch identity and patch domains that are independent of each individual dirty edit
  window.
- Map edit dirty output windows to affected CDT patch domains.
- Run the real command path from terrain edit through MTA-33 feature planning, MTA-32 patch solve,
  and MTA-34 replacement/mutation.
- Preserve unaffected neighboring patch output and patch metadata across repeated local edits.
- Make CDT fallback, refusal, and current-output fallback internally unambiguous while preserving
  public MCP response contracts.
- Produce hosted SketchUp visual and timing evidence for the full product loop before any default
  CDT enablement decision.

## Acceptance Criteria

```gherkin
Scenario: Initial CDT patch output is bootstrapped with stable ownership
  Given an internal CDT patch output mode is enabled for a managed terrain surface
  When terrain derived output is created or rebuilt for the surface
  Then the emitted output is partitioned into stable CDT-owned patch domains
  And each patch face carries enough ownership metadata to identify its patch domain and revision
  And the patch identity does not depend on the exact dirty edit window that will later modify it
  And public terrain command responses do not expose patch identifiers or CDT internals

Scenario: Dirty edit maps to affected CDT patches
  Given a managed terrain surface with existing CDT-owned patch output
  When a valid terrain edit produces a dirty output window
  Then the dirty window maps to one or more affected stable patch domains
  And unaffected neighboring patch domains remain outside the replacement set
  And patch-relevant MTA-33 feature geometry is prepared for the affected patch domains

Scenario: Real command path replaces an affected patch
  Given a CDT-owned terrain surface with an affected patch and preserved neighboring patches
  When `edit_terrain_surface` runs through the normal command path
  Then MTA-33 reports eligible patch-relevant feature geometry for the affected patch
  And real MTA-32 `PatchLocalCdtProof` produces an accepted replacement-worthy patch result
  And MTA-34 validates ownership, topology, and seams before erasing old output
  And only the affected CDT patch output is replaced
  And preserved neighboring patch output remains present and unchanged

Scenario: Repeated edits reuse newly emitted CDT patch metadata
  Given a local CDT patch replacement has completed
  When a second valid edit affects the same or an adjacent stable patch domain
  Then the newly emitted patch ownership metadata is sufficient for the next replacement decision
  And the second replacement does not depend on stale pre-seeded fixture metadata
  And no duplicate layered terrain, inverted faces, or hidden stale faces remain under the patch

Scenario: CDT fallback and refusal remain safe and unambiguous
  Given CDT patch bootstrap, patch solve, topology validation, seam validation, ownership lookup, or
  mutation safety fails
  When the terrain command handles the failure
  Then old derived output is not erased before a safe path is available
  And internal evidence distinguishes local CDT replacement, current-output fallback, and public
  refusal
  And public responses remain free of patch ownership, seam diagnostics, raw triangles, fallback
  enums, and solver vocabulary

Scenario: Hosted visual proof covers representative terrain behavior
  Given hosted SketchUp validation fixtures with larger terrains, multi-feature intersections,
  repeated edits, preserved neighbors, and fallback/refusal cases
  When the internal CDT patch output lifecycle is exercised through public terrain commands
  Then accepted cases are visually inspectable as one complete terrain per use case
  And CDT replacement patches are clearly materialized in their true terrain position
  And hosted evidence records no near-full-grid over-densification, inverted faces, duplicate
  layered output, stale faces under seams, or redundant seam topology beyond documented tolerance

Scenario: Local CDT path has useful performance characteristics
  Given a representative hosted fixture can run both current output and internal CDT patch output
  When timing is captured for the same edit family
  Then command preparation, feature selection, patch solve, ownership lookup, seam validation,
  mutation, audit, and total runtime are recorded separately
  And local CDT replacement is materially cheaper than current/full-output replacement or a
  default-enable blocker is recorded
```

## Non-Goals

- Default-enabling CDT terrain output.
- Adding public backend selectors, public patch controls, public CDT diagnostics, or public seam
  diagnostics.
- Implementing native/C++ triangulation.
- Replacing the MTA-32 patch-local proof algorithm wholesale without failing evidence and explicit
  re-planning.
- Replacing the MTA-33 feature lifecycle or public feature-intent model.
- Adding broad background/global rebuild or export-quality CDT workflows.
- Adding visual smoothing/fairing over CDT output.
- Treating hosted save/reopen as a required acceptance gate for this task unless the technical plan
  introduces new persisted metadata that depends on reload semantics.

## Business Constraints

- Normal user-facing terrain workflows must remain on the current supported output path unless
  internal CDT patch output mode is explicitly enabled for validation.
- CDT patch output must not corrupt visible terrain when patch ownership, topology, seams, or
  mutation safety are uncertain.
- The task must produce user-confirmed hosted visual evidence before being considered complete.
- Fallback safety is required, but fallback-only evidence cannot satisfy this task.
- Public MCP contracts must remain stable and must not require users to understand CDT patch
  internals.

## Technical Constraints

- Terrain state remains authoritative; CDT patch output remains disposable derived geometry.
- Stable patch domains must be derived from terrain/source coordinates or patch-index policy, not
  from transient proof-result digests alone.
- Dirty-window mapping must account for edit influence, falloff/fairing margins, seam/stitch bands,
  and hard/protected feature safety margins as defined in the technical plan.
- MTA-35 must reuse MTA-33 through `TerrainFeaturePlanner` and must reuse real MTA-32
  `PatchLocalCdtProof`; handcrafted `TerrainFeatureGeometry` and fake proof providers are not
  acceptance evidence.
- MTA-34 replacement infrastructure may be retained and adapted, but any retained component must be
  audited against stable patch identity and repeated-edit lifecycle requirements.
- If real MTA-32 produces near-full-grid output, inverted topology, excessive redundant edges, or
  topology-quality failures on representative stable patches, the task must stop and record a
  blocker or repair MTA-32 from failing tests before proceeding.
- If ownership lookup, seam snapshotting, or SketchUp mutation cost erases locality benefits, the
  task must record a blocker or split a patch index/cache follow-up before any default-enable path.

## Dependencies

- `MTA-10`
- `MTA-31`
- `MTA-32`
- `MTA-33`
- `MTA-34`
- [CDT Terrain Output External Review](../../../research/managed-terrain/cdt-terrain-output-external-review.md)

## Relationships

- follows `MTA-34` because MTA-34 exposed that replacement requires pre-existing stable CDT-owned
  patch output
- consumes MTA-32 patch-local CDT proof output and MTA-33 patch-relevant feature geometry
- adapts retained MTA-34 replacement, seam-validation, ownership, fallback, and no-leak
  infrastructure where it fits stable patch lifecycle requirements
- informs any later default-CDT enablement, native triangulation, spatial-index, background rebuild,
  or smoothing task

## Carry-Forward Evidence From MTA-34

- Tiny rectangle, four-face, fake-provider-only, separated patch-only, fallback-only, and
  topology-relaxed monkey-patched hosted rows are rejected as acceptance evidence.
- UC01 and UC02 showed replacement mechanics but were too grid-like or topology-relaxed to prove
  product behavior.
- UC03 exposed overlap, gap, orientation, and material/layering problems in affected-neighbor seam
  evidence.
- UC04 is useful fallback/blocker evidence: real MTA-32 returned `topology_quality_failed` and the
  runtime correctly avoided claiming local CDT replacement.
- UC05 is useful ownership-refusal directionally, but must be rebuilt or repaired because inverted
  material orientation and extra edge artifacts made the hosted evidence unclear.
- MTA-32 over-insertion or near-full-grid output must be treated as a blocker to capture with tests,
  not fixed with live monkey patches.
- The seam snapshot model must support honest complex shared seams or define an alternate seam
  evidence carrier before hosted seam acceptance.

## Related Technical Plan

- none yet

## Success Metrics

- Hosted validation shows a normal command-path edit bootstrapping or using stable CDT-owned patch
  output and replacing only affected patch domains.
- Repeated hosted edits prove newly emitted CDT patch metadata is reusable for future replacement.
- At least one representative multi-feature hosted case completes through real MTA-33, real MTA-32,
  and retained/adapted MTA-34 mutation without fallback.
- Hosted visual inspection confirms no accepted case has duplicate layered output, inverted faces,
  stale faces under seams, or unacceptable redundant seam topology.
- Internal evidence distinguishes local CDT replacement, current-output fallback, and public refusal
  without leaking CDT internals into public responses.
- Timing evidence shows local CDT patch replacement has a credible performance advantage over the
  current/full-output path, or records a concrete blocker before any default-enable recommendation.
