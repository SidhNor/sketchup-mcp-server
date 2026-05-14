# Task: MTA-35 Implement CDT Replacement Provider On PatchLifecycle For Windowed Terrain Edits
**Task ID**: `MTA-35`
**Title**: `Implement CDT Replacement Provider On PatchLifecycle For Windowed Terrain Edits`
**Status**: `implementation-complete`
**Priority**: `P1`
**Date**: `2026-05-10`

## Linked HLD

- [Managed Terrain Surface Authoring](../../../hlds/hld-managed-terrain-surface-authoring.md)

## Problem Statement

MTA-36 completed the reusable patch lifecycle substrate that MTA-35 should now stand on: stable
logical patch IDs, dirty-window-to-patch mapping, conformance-ring expansion, registry persistence,
face ownership, no-delete mutation sequencing, timing evidence, reload/readback, and single-mesh
logical patch output. It proved that local replacement can cut and stitch terrain cleanly when the
output provider can regenerate from terrain elevations alone.

CDT output has a different input model. It cannot be implemented by copying the adaptive assumption
that elevations alone are enough. For MTA-35, feature intents are critical CDT constraints:
corridor transitions, target-height pads and pressure regions, planar-fit controls, survey point
constraints, fixed/protected/preserve zones, and retained boundary constraints must be selected by
patch relevance and carried into the CDT replacement provider as first-class input.

MTA-32 and MTA-34 remain useful CDT evidence, but they were partial proofs rather than accepted
product behavior. They exposed failure modes including bad nesting, poor stitching, duplicate
edges, surplus or unclear geometry, topology failures, and seam evidence gaps. MTA-35 must implement
the CDT replacement provider on top of the proven MTA-36 lifecycle and meet that geometry quality
bar through the real command path.

## Goals

- Implement an internally gated CDT replacement provider on the generic `PatchLifecycle` substrate
  proven by MTA-36.
- Use stable patch domains from `PatchLifecycle` and preserve the single-mesh logical patch output
  model.
- Adapt `TerrainFeaturePlanner` / MTA-33 as needed so feature intents are selected by
  `PatchLifecycle` patch relevance, not globally and not accidentally omitted.
- Build CDT replacement input from patch domains, patch-relevant feature intents, terrain state
  elevations, and retained neighbor/boundary context.
- Replace only affected CDT logical patches while preserving unaffected neighboring patch output and
  patch metadata across repeated local edits.
- Validate CDT-specific topology, retained-boundary seams, surplus-face shedding, ownership, and
  no-bad-edge behavior before accepting local replacement.
- Make local-CDT acceptance, warning, and fallback mesh generation internally unambiguous while
  preserving public MCP response contracts.
- Produce hosted SketchUp visual, reload/follow-up edit, and timing evidence before any default CDT
  enablement decision.

## Acceptance Criteria

```gherkin
Scenario: Initial CDT patch output uses the proven patch lifecycle
  Given an internal CDT patch output mode is enabled for a managed terrain surface
  When terrain derived output is created or rebuilt for the surface
  Then the emitted output uses stable `PatchLifecycle` patch domains
  And it is represented as one derived terrain mesh with logical patch ownership on faces
  And each patch face carries enough ownership metadata to support repeated local replacement
  And public terrain command responses do not expose patch identifiers or CDT internals

Scenario: Dirty edit maps to affected CDT patches and relevant feature intents
  Given a managed terrain surface with existing CDT-owned patch output
  When a valid terrain edit produces a dirty output window
  Then the dirty window maps to one or more affected stable patch domains
  And unaffected neighboring patch domains remain outside the replacement set
  And feature intents are selected by affected, replacement, and retained-boundary relevance
  And far unrelated feature intents do not bloat the local CDT replacement input
  And nearby protected, fixed, pressure, corridor, survey, planar, and preserve controls are included
  And those controls are included when they affect the replacement or retained boundary

Scenario: Real command path replaces an affected patch
  Given a CDT-owned terrain surface with an affected patch and preserved neighboring patches
  When `edit_terrain_surface` runs through the normal command path
  Then `TerrainFeaturePlanner` provides patch-relevant source-state feature intent and geometry
  And the CDT provider combines feature constraints, terrain elevations, patch domains, and retained
  boundary context
  And CDT topology, seam, surplus-face, and ownership validation pass before erasing old output
  And only the affected CDT patch output is replaced
  And preserved neighboring patch output remains present and unchanged

Scenario: Repeated edits reuse newly emitted CDT patch metadata
  Given a local CDT patch replacement has completed
  When a second valid edit affects the same or an adjacent stable patch domain
  Then the newly emitted patch ownership metadata and source-state feature intent are sufficient for
  the next replacement decision
  And the second replacement does not depend on stale pre-seeded fixture metadata or stale derived
  output assumptions
  And no duplicate layered terrain, inverted faces, duplicate edges, bad stitching, or hidden stale
  faces remain under the patch

Scenario: Local CDT fallback still generates mesh for valid edits
  Given a valid heightmap edit has been accepted by the terrain edit domain
  And CDT patch bootstrap, patch solve, topology validation, seam validation, ownership lookup, or
  mutation prevalidation cannot accept local CDT replacement for that edit
  When the terrain command handles the local CDT result
  Then old derived output is not erased before a safe path is available
  And a valid heightmap edit still produces fresh derived mesh output through a safe fallback path
  And simplification, solver, topology, seam, or tolerance problems are recorded as internal
  warning or fallback evidence
  And internal evidence distinguishes accepted local CDT replacement from safe fallback mesh
  generation
  And public responses remain free of patch ownership, feature-selection internals, CDT diagnostics,
  raw triangles, registry data, fallback enums, and solver vocabulary

Scenario: Hosted visual proof covers feature-rich CDT replacement behavior
  Given hosted SketchUp validation fixtures with larger terrains, feature-rich intersections,
  repeated edits, save/reopen, preserved neighbors, fallback/warning cases, and invalid-request
  refusal cases
  When the internal CDT replacement provider is exercised through public terrain commands
  Then accepted cases are visually inspectable as one complete terrain per use case
  And hosted rows cover corridor transitions crossing patch boundaries, target-height pads with
  smoothing or pressure regions, local fairing near prior feature intent, planar region fitting,
  survey correction near a retained boundary, and preserve/protected zones near the replacement
  domain
  And repeated overlapping edits plus save/reopen and follow-up edit prove feature relevance and
  patch metadata remain valid
  And hosted evidence records no near-full-grid over-densification, inverted faces, duplicate
  layered output, stale faces under seams, duplicate edges, bad stitching, or redundant seam
  topology beyond documented tolerance

Scenario: Local CDT path has useful performance characteristics
  Given a representative hosted fixture can run local CDT, full CDT, and adaptive/current fallback
  When timing is captured for the same edit family
  Then command preparation, feature selection, CDT input build, patch solve, ownership lookup, seam
  validation, mutation, audit, and total runtime are recorded separately
  And local CDT replacement is materially cheaper than full CDT or adaptive/current fallback, or a
  default-enable blocker is recorded
```

## Non-Goals

- Default-enabling CDT terrain output.
- Adding public backend selectors, public patch controls, public CDT diagnostics, or public seam
  diagnostics.
- Rebuilding the generic patch lifecycle already completed by MTA-36.
- Implementing native/C++ triangulation.
- Treating MTA-32 or MTA-34 proof geometry as accepted product behavior without revalidation.
- Replacing the MTA-33 feature lifecycle or public feature-intent model; MTA-35 may adapt internal
  patch-domain relevance APIs.
- Adding broad background/global rebuild or export-quality CDT workflows.
- Adding new public terrain edit modes or new public feature-intent contracts.
- Solving visual smoothing/fairing as a separate output polish layer beyond preserving existing
  feature intent semantics in CDT input.

## Business Constraints

- Normal user-facing terrain workflows must remain on the current supported output path unless
  internal CDT patch output mode is explicitly enabled for validation.
- CDT patch output must not corrupt visible terrain when patch ownership, topology, seams, or
  mutation safety are uncertain.
- Valid heightmap edits must still result in fresh generated terrain mesh output; local CDT failure
  is an internal fallback/warning condition, not a reason to reject the edit.
- Simplification, solver, topology, seam, and tolerance problems may block local CDT acceptance, but
  they must not block mesh generation for an otherwise valid terrain edit.
- The task must produce user-confirmed hosted visual evidence before being considered complete.
- Fallback safety is required, but fallback-only evidence cannot satisfy this task.
- Public MCP contracts must remain stable and must not require users to understand CDT patch
  internals.

## Technical Constraints

- Terrain state remains authoritative; CDT patch output remains disposable derived geometry.
- `PatchLifecycle` owns stable patch IDs, dirty-window mapping, conformance-ring expansion,
  registry persistence, face ownership, no-delete mutation sequencing, timing, and reload/readback
  evidence.
- `TerrainFeaturePlanner` owns patch-relevant feature intent selection for CDT input, including
  corridor transitions, target-height pads and pressure regions, planar-fit controls, survey point
  constraints, fixed/protected/preserve zones, and retained boundary constraints.
- The CDT provider owns triangulation input assembly, CDT topology validation, retained-boundary
  seam validation, surplus-face simplification, and replacement acceptance.
- Stable patch identity must come from `PatchLifecycle`, not from transient proof-result digests or
  dirty-window-derived CDT proof domains.
- Dirty-window and feature relevance must account for edit influence, falloff/fairing margins,
  seam/stitch bands, and hard/protected feature safety margins as defined in the technical plan.
- MTA-35 must use source-state feature intent and real command-path feature planning; handcrafted
  `TerrainFeatureGeometry`, fake proof providers, or fallback-only rows are not acceptance evidence.
- MTA-32 and MTA-34 components may be retained only after audit against MTA-36's single-mesh
  lifecycle, patch identity, topology quality, and repeated-edit requirements.
- If retained CDT code produces near-full-grid output, inverted topology, bad nesting, duplicate
  edges, poor stitching, excessive redundant edges, or topology-quality failures on representative
  stable patches, local CDT acceptance must be blocked and the CDT path must be repaired or split
  before claiming local CDT replacement; valid edits must still generate mesh via fallback.
- Simplification and tolerance violations are local-CDT warning or fallback conditions for valid
  edits, not public rejection conditions.
- If ownership lookup, seam snapshotting, or SketchUp mutation cost erases locality benefits, the
  task must record a blocker or split a patch index/cache follow-up before any default-enable path.

## Dependencies

- `MTA-10`
- `MTA-31`
- `MTA-32`
- `MTA-33`
- `MTA-34`
- `MTA-36`
- [CDT Terrain Output External Review](../../../research/managed-terrain/cdt-terrain-output-external-review.md)

## Relationships

- follows `MTA-36` because MTA-36 completed the reusable patch lifecycle and single-mesh mutation
  substrate MTA-35 must use
- adapts MTA-33 patch-relevant feature planning so it works against `PatchLifecycle` domains and
  retained-boundary relevance
- audits MTA-32 patch-local CDT proof concepts and MTA-34 replacement/seam/ownership infrastructure
  as partial evidence, not accepted product behavior
- informs any later default-CDT enablement, native triangulation, spatial-index, background rebuild,
  or smoothing task

## Carry-Forward Evidence

- MTA-36 proved stable logical patches, one derived mesh, correct local terrain cuts, clean
  stitching, no bad edge emission, reload/readback, save/reopen, repeated overlapping edits, timing,
  and public no-leak behavior for adaptive output.
- MTA-36 did not prove the CDT input model because adaptive output can regenerate from terrain
  elevations alone; CDT requires feature intents as first-class constraints.
- MTA-33 proved bounded feature relevance directionally, but MTA-35 may need to adapt it for
  `PatchLifecycle` affected, replacement, conformance, and retained-boundary domains.
- MTA-32 and MTA-34 are partial CDT proofs and retained infrastructure sources, not accepted
  behavior foundations.
- Tiny rectangle, four-face, fake-provider-only, separated patch-only, fallback-only, and
  topology-relaxed monkey-patched hosted rows are rejected as acceptance evidence.
- UC01 and UC02 showed replacement mechanics but were too grid-like or topology-relaxed to prove
  product behavior.
- UC03 exposed overlap, gap, orientation, and material/layering problems in affected-neighbor seam
  evidence.
- UC04 is useful fallback/blocker evidence: real MTA-32 returned `topology_quality_failed` and the
  runtime correctly avoided claiming local CDT replacement.
- UC05 is useful ownership-safety evidence directionally, but must be rebuilt or repaired because inverted
  material orientation and extra edge artifacts made the hosted evidence unclear.
- MTA-32 over-insertion or near-full-grid output must be treated as a blocker to capture with tests,
  not fixed with live monkey patches.
- The seam snapshot model must support honest complex shared seams or define an alternate seam
  evidence carrier before hosted seam acceptance.

## Related Technical Plan

- [Technical implementation plan](./plan.md)

## Success Metrics

- Hosted validation shows a normal command-path edit using the MTA-36 `PatchLifecycle` substrate and
  replacing only affected CDT logical patch domains inside one mesh.
- Repeated hosted edits prove newly emitted CDT patch metadata and source-state feature intent remain
  usable for future replacement.
- Representative feature-rich hosted cases complete through domain-aware `TerrainFeaturePlanner`
  selection and the CDT provider without fallback.
- Hosted fallback/blocker cases prove valid edits still generate fresh mesh output with internal
  warning or tolerance evidence when local CDT cannot be accepted.
- Hosted visual inspection confirms no accepted case has duplicate layered output, inverted faces,
  stale faces under seams, duplicate edges, bad stitching, or unacceptable redundant seam topology.
- Internal evidence distinguishes accepted local CDT replacement, safe fallback mesh generation,
  warning/tolerance evidence, and true invalid-request or unsafe-target refusal cases without
  leaking CDT internals into public responses.
- Timing evidence shows local CDT patch replacement has a credible performance advantage over full
  CDT or adaptive/current fallback, or records a concrete blocker before any default-enable
  recommendation.
