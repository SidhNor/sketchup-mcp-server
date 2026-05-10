# Task: MTA-32 Implement Patch-Local Incremental Residual CDT Proof
**Task ID**: `MTA-32`
**Title**: `Implement Patch-Local Incremental Residual CDT Proof`
**Status**: `implemented`
**Priority**: `P1`
**Date**: `2026-05-09`

## Linked HLD

- [Managed Terrain Surface Authoring](../../../hlds/hld-managed-terrain-surface-authoring.md)

## Problem Statement

MTA-31 proved that the current CDT scaffold has useful production seams, feature-intent
selection, containment gates, and residual probes, but it also proved that the current residual
policy is not viable for interactive terrain editing. Accurate CDT output currently depends on a
residual loop that scans the source, adds worst residual points, and retriangulates the whole
growing point set repeatedly. On hosted evidence this produced acceptable small-terrain quality
only at roughly 4-5 seconds, and representative terrain histories still took minutes.

This task must prove a materially different CDT residual shape: solve only a dirty local patch and
refine it incrementally so added residual points update only the affected local triangulation
region. The task is an internal proof slice, not default production enablement.

## Goals

- Deliver an internally enabled patch-local CDT residual path that uses dirty edit windows as the
  basis for bounded patch domains.
- Preserve terrain detail by adding residual points inside the patch until quality, budget, or
  improvement gates stop refinement.
- Avoid full-terrain residual scans and full-terrain retriangulation in the patch-local proof path.
- Avoid repeated full retriangulation of the growing patch point set when residual points are added.
- Establish explicit patch-domain and patch-residual ownership seams that `MTA-33` and `MTA-34`
  can build on, instead of layering patch-local behavior as ad hoc exceptions in the global CDT
  path.
- Report timing, residual quality, point/face counts, stop reasons, and hard/seam validation
  diagnostics sufficient to compare against MTA-31 global CDT evidence.
- Keep CDT disabled by default and keep public MCP request/response shapes unchanged.

## Acceptance Criteria

```gherkin
Scenario: Patch-local residual CDT does not expand into a full-terrain solve
  Given a managed terrain edit with a non-empty dirty sample window
  When the internal patch-local CDT proof path prepares output
  Then it derives a bounded patch domain from the dirty window and configured margins
  And residual scanning is limited to the patch domain
  And residual points are selected only from inside the patch domain
  And the proof path does not invoke full-grid residual refinement or retriangulate outside the dirty patch boundaries

Scenario: Incremental residual refinement updates local triangulation only
  Given a patch CDT has seed points, patch boundary constraints, and residual candidates
  When a worst residual point is accepted during refinement
  Then the triangulation is updated through an incremental or affected-region update path
  And the implementation does not rebuild the whole growing patch point set for every residual insertion
  And residual candidates are recomputed only for affected local regions or documented bounded equivalents
  And diagnostics record insertion counts, affected-region update counts, timing, and stop reason

Scenario: Patch output meets quality or stops with deterministic fallback evidence
  Given flat, rough, and feature-influenced patch fixtures
  When patch-local incremental CDT output is generated
  Then accepted output reports local max height error, RMS error, p95 error, face count, dense ratio, and residual stop reason
  And rough or high-relief patches preserve terrain detail within the configured quality tolerance before acceptance
  And cases that cannot meet quality within point, face, runtime, or improvement budgets return deterministic internal fallback evidence

Scenario: Patch boundaries are treated as hard topology
  Given a patch domain derived from a dirty terrain window
  When patch-local CDT seed topology is prepared
  Then patch boundary vertices and required boundary segments are included as hard topology
  And generated patch vertices and faces stay inside the patch domain
  And seam or boundary violations are reported as internal diagnostics instead of leaking public solver details

Scenario: Existing public terrain behavior remains unchanged
  Given the extension is loaded with default terrain output behavior
  When managed terrain create or edit output is generated
  Then the current terrain output backend remains the default
  And patch-local CDT is not attempted unless explicitly enabled through an internal test or validation seam
  And public MCP responses do not expose patch CDT internals, residual candidate queues, raw triangles, or stop-policy details
```

## Non-Goals

- Default-enabling CDT terrain output.
- Replacing SketchUp derived output patch geometry in production workflows.
- Implementing broad patch-relevant hard-feature spatial ownership beyond the seed constraints needed for the proof path.
- Adding public backend selectors, public tuning controls, or public CDT diagnostics.
- Shipping native/C++ triangulation binaries.
- Rewriting unrelated terrain edit kernels or terrain state storage.

## Business Constraints

- Normal managed terrain editing must remain on the current supported backend unless CDT is
  internally enabled for proof or validation.
- The task must produce evidence about whether a local incremental CDT residual policy can preserve
  terrain quality inside an interactive budget.
- The task must not ask users to choose between terrain output backends or understand solver
  internals.

## Technical Constraints

- Terrain state remains authoritative; generated CDT patch output remains disposable derived output
  or validation evidence.
- The proof path must consume production terrain state, dirty windows, and MTA-31 CDT seams rather
  than raw SketchUp objects or MTA-24 candidate rows.
- Patch-local proof code must preserve a clear boundary between patch domain derivation, residual
  refinement policy, triangulation updates, diagnostics, and later SketchUp replacement ownership.
- Outputs crossing command or test seams must remain JSON-serializable.
- Patch-local residual work must preserve hard patch boundaries and avoid out-of-domain vertices.
- Runtime and residual diagnostics must stay internal and must not change public MCP response
  contracts.
- Native triangulation may remain a future adapter target, but this task must produce a Ruby-path
  proof or clear evidence that the Ruby path is still insufficient.

## Dependencies

- `MTA-10`
- `MTA-20`
- `MTA-24`
- `MTA-25`
- `MTA-31`
- [CDT Terrain Output External Review](../../../research/managed-terrain/cdt-terrain-output-external-review.md)

## Relationships

- follows `MTA-31` because MTA-31 proved the remaining bottleneck is residual policy and repeated
  retriangulation rather than feature selection or public contract shape
- informs `MTA-33` by defining the patch domain and residual result shape that patch-relevant
  feature selection will feed
- informs `MTA-34` by producing the patch output/result shape that later SketchUp replacement can
  consume
- may create a later native or incremental-hardening follow-up if the Ruby incremental proof remains
  outside interactive budgets

## Related Technical Plan

- [Technical implementation plan](./plan.md)

## Success Metrics

- Patch-local residual scans and residual point selection are limited to the dirty patch domain.
- Patch-domain and patch-residual result seams are explicit enough to feed `MTA-33` feature
  relevance and `MTA-34` replacement/seam validation without reworking the proof as a one-off
  branch of the global residual loop.
- Residual insertion avoids rebuilding the whole growing patch point set on every accepted point.
- Accepted patch fixtures report quality metrics within configured tolerance and materially lower
  runtime than the comparable MTA-31 global CDT evidence.
- Budget-exceeded cases return deterministic internal fallback evidence before runaway
  retriangulation.
- Public MCP terrain request and response shapes remain unchanged.
