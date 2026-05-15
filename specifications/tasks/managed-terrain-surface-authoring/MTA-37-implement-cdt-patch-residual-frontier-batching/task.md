# Task: MTA-37 Implement CDT Patch Residual Frontier Batching
**Task ID**: `MTA-37`
**Title**: `Implement CDT Patch Residual Frontier Batching`
**Status**: `closed; failed-performance-gates; implementation-reverted; not-production-path`
**Priority**: `P1`
**Date**: `2026-05-14`

## Linked HLD

- [Managed Terrain Surface Authoring](../../../hlds/hld-managed-terrain-surface-authoring.md)

## Problem Statement

MTA-36 proved the reusable `PatchLifecycle` substrate for stable logical terrain patch identity,
single-mesh ownership, registry persistence, no-delete mutation, timing, and readback. MTA-35 then
implemented an internally gated CDT replacement provider on that lifecycle and proved the strict CDT
path through public SketchUp command validation.

The CDT path is now functionally credible but not performance-ready for default enablement. Live
MTA-35 evidence shows the remaining bottleneck is still solve-bound: strict CDT patch solves use the
current Ruby CDT backend, residual refinement repeatedly rebuilds patch triangulations, and seam-safe
boundary synchronization can raise face count. Recent local optimizations reduced solve time only
modestly.

MTA-37 closeout keeps this path out of the production/default terrain output route. The attempted
residual-frontier implementation was reverted after hosted evidence failed the performance gate. The
supported production path remains the existing adaptive terrain output unless a private internal
switch is explicitly enabled for research or validation.

The next slice must improve residual point selection and batching while preserving the current safe
PatchLifecycle handoff. This task does not change seam ownership, introduce native triangulation, or
default-enable CDT. It defines whether the current Ruby backend can become materially cheaper with a
better residual policy before a native CGAL-style backend is justified.

## Goals

- Add a backend-neutral residual frontier/batching policy for CDT patch solves.
- Reduce repeated patch CDT rebuild count, residual scan time, and retriangulation time on strict
  CDT rows without weakening hard topology, seam, ownership, or readback gates.
- Record enough per-patch diagnostics to decide whether Ruby CDT remains viable for one more
  optimization slice or whether native/incremental CDT must move next.
- Keep MTA-36 `PatchLifecycle` as the sole owner of patch identity, registry, face ownership,
  mutation sequencing, timing handoff, and readback.
- Keep CDT internally gated and disabled on the default production path.

## Acceptance Criteria

```gherkin
Scenario: Residual frontier batches candidates before CDT rebuild
  Given the internal `cdt_patch` output mode is enabled
  And a CDT patch solve has residual height error above the configured tolerance
  When residual refinement selects additional terrain samples
  Then residual candidates are scored by local weighted error before insertion
  And the first residual scan populates a broad patch candidate frontier whose candidate count can exceed the next insert batch size
  And the next rebuild inserts a bounded top-K batch from the retained frontier rather than blindly adding every scanned residual sample
  And the frontier can provide additional batches without requiring a full residual rescan before every rebuild
  And the batch applies deterministic spacing or duplicate rejection against the full current point set so clustered candidates do not recreate dense-grid behavior
  And incremental rescans are limited to dirty/invalidated residual blocks until the final full quality scan
  And the solver records candidate counts, inserted counts, rejected counts, scan timing, rebuild timing, and stop reason

Scenario: Existing CDT acceptance gates remain authoritative
  Given a CDT patch replacement is produced using residual frontier batching
  When provider acceptance runs
  Then missing production mesh, invalid topology, duplicate triangles, duplicate boundary edges, bad winding, out-of-domain geometry, stale retained evidence, and seam mismatch still block local CDT acceptance
  And valid local CDT replacement still mutates through `PatchLifecycle` ownership and registry writeback
  And local CDT failures still preserve old output before any unsafe erase

Scenario: Seam behavior is intentionally unchanged for this slice
  Given adjacent replacement patches need internal boundary synchronization
  When residual frontier batching changes patch interior point selection
  Then the existing seam-safe boundary synchronization behavior remains active
  And the task does not replace exact boundary synchronization with a parent-owned seam lattice
  And any seam-density or face-count issue is recorded as input to a later seam-lattice task

Scenario: Public contracts and production defaults do not change
  Given default terrain output mode is used
  When public terrain create or edit commands run
  Then CDT remains disabled on the production/default path
  And public MCP request and response shapes remain unchanged
  And public responses do not expose CDT patch IDs, registry internals, residual frontier diagnostics, fallback enums, timing buckets, raw vertices, or raw triangles

Scenario: Hosted strict-CDT performance evidence determines the next direction
  Given a representative strict-CDT broad-overlap row from MTA-35
  When the same edit family is run after residual frontier batching
  Then the evidence records engine build count, residual scan time, retriangulation time, lifecycle total time, face count, max height error, seam validation, topology validation, registry validity, and fallback outcome
  And the row is classified as `ruby_viable_next_slice` only if rebuild count and solve time materially improve without correctness regressions
  And the row is classified as `native_or_incremental_backend_needed` if rebuild count improves but total runtime remains dominated by Ruby triangulation
```

## Non-Goals

- Default-enabling CDT output.
- Adding a public CDT backend selector, public residual diagnostics, public patch controls, or public seam controls.
- Replacing MTA-36 `PatchLifecycle` ownership, registry, mutation sequencing, timing, or readback.
- Implementing a native CGAL, Triangle, poly2tri, or other C/C++ backend.
- Implementing full incremental CDT point insertion.
- Replacing current exact boundary synchronization with a parent-owned seam lattice.
- Solving connected-component patch solves or face splitting across multiple logical patches.
- Changing public terrain command request or response contracts.

## Business Constraints

- The supported user-facing terrain path must remain unchanged unless the private CDT switch is enabled.
- Valid public edits in default mode must continue to use the current safe output path.
- CDT validation must not mistake fallback geometry for accepted CDT output.
- Default-enable discussion remains blocked until CDT is materially faster and lower-face than adaptive at comparable tolerance, while still passing seam, topology, registry, and readback gates.
- The task must produce evidence that supports a concrete next decision: continue Ruby policy work, move to seam-lattice work, or begin native/incremental backend planning.

## Technical Constraints

- `PatchLifecycle` remains the sole owner of stable patch IDs, dirty-window resolution, conformance-ring expansion, registry persistence, face ownership, no-delete mutation sequencing, timing handoff, and readback.
- The CDT provider may change residual scoring, residual batching, point insertion policy, and diagnostics, but it must return the same private provider handoff shape expected by `TerrainMeshGenerator`.
- Residual frontier state is transient to a patch solve. It must not become durable terrain state, but
  it must survive residual refinement passes for the same patch solve.
- A heap over only the latest small `worst_samples(limit: K)` window is not sufficient; the
  implementation must populate and select from a broader patch candidate frontier.
- Minimum XY spacing must be enforced against seed points, mandatory/hard feature points, prior
  residual insertions, and the current selected batch.
- Main-loop residual rescans must target dirty/invalidated blocks; full scans are expected for
  initial frontier population and final quality evidence.
- Existing provider acceptance and seam validation gates must remain stricter than the residual policy.
- Residual height error above the target tolerance must drive refinement, diagnostics, and next-direction
  classification; it must not become a new residual-only edit rejection rule.
- Residual frontier diagnostics must stay internal and JSON-serializable.
- The existing exact internal boundary synchronization behavior remains in place for this slice so performance changes isolate residual policy effects.
- The implementation must preserve strict mode behavior: when `cdt_patch` is explicitly selected, selected-output CDT failures must not silently render adaptive fallback geometry.
- Tests must cover both accepted replacement and safe failure/no-delete behavior.

## Dependencies

- `MTA-35`
- `MTA-36`
- [CDT Terrain Output External Review](../../../research/managed-terrain/cdt-terrain-output-external-review.md)
- [CDT Terrain Output Path - Next Technical Direction For An AGPL SketchUp Extension](../../../research/managed-terrain/cdt_terrain_next_direction.md)

## Relationships

- follows `MTA-35` because it optimizes the internally gated stable-domain CDT provider after functional closeout
- follows `MTA-36` because it must preserve the reusable `PatchLifecycle` ownership and mutation substrate
- informs a later parent-owned seam-lattice task if seam-safe boundary synchronization remains a density blocker
- informs a later native or incremental CDT backend task if Ruby triangulation remains the bottleneck after residual batching

## Related Technical Plan

- [Technical Plan](./plan.md)

## Success Metrics

- Representative strict-CDT broad-overlap evidence records engine builds, scan time, retriangulation time, total lifecycle time, face count, max height error, seam status, topology status, registry status, and fallback outcome.
- On the representative MTA-35 broad-overlap row, engine builds move materially below the prior roughly 30-build baseline without increasing fallback rate.
- Retriangulation and residual scan timing materially improve while striving to keep max height error at or below the current 0.05m strict-CDT target for this slice.
- Existing strict-CDT topology, seam, ownership, no-delete, save/reopen/readback, and no-public-leak checks remain green.
- The closeout explicitly recommends one next direction: continue Ruby residual/seam policy, start parent-owned seam lattice, or begin native/incremental backend planning.

## Implementation Completeness Gates

- Unit tests fail if spacing is checked only against the same batch instead of the full current point
  set.
- Unit tests fail if the heap cannot pop multiple batches from retained candidate state.
- Unit tests fail if broad-overlap candidate count never exceeds the insert batch size.
- Unit tests fail if normal refinement requires a full residual scan before every rebuild.
- Unit tests fail if final max/RMS/p95 evidence is skipped.
- Hosted proof must use a representative broad-overlap public command path row, placed away from
  existing terrain at `x >= 50m`, and must compare old/current build count, scan time,
  retriangulation time, lifecycle time, face count, max error, fallback status, and seam/topology
  status.
