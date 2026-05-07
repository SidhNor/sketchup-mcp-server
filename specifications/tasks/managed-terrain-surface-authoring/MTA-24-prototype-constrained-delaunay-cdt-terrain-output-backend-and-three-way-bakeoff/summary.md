# Summary: MTA-24 Prototype Constrained Delaunay/CDT Terrain Output Backend And Three-Way Bakeoff

**Task ID**: `MTA-24`
**Status**: `completed`
**Date**: `2026-05-07`

## Result

MTA-24 produced a real comparison-only CDT terrain backend, ran it against the current production
terrain output path and the MTA-23 adaptive-grid prototype, and closed with this production
direction:

Proceed with a CDT-oriented production follow-up, while retaining the current production output as
the safety fallback during implementation.

MTA-23 remains credible as a prototype baseline, especially after the fixes found during this task,
but it is not the recommended final production backend from this evidence. On harder
intersecting/bounded cases it often becomes near-dense. CDT produced materially sparser meshes at
comparable height tolerance, but it must pass explicit production gates for runtime, constraint
classifier precision, and hosted acceptance before any production swap.

## Shipped Behavior

- Added `CdtTerrainCandidateBackend` as an internal comparison-only backend.
- Added `CdtTerrainPointPlanner` as a seed-only planner:
  - terrain domain corners
  - hard output anchors
  - protected rectangle corners and minimal protected boundary support
  - reference segment support
  - unsupported feature reporting
- Added `CdtHeightErrorMeter` for residual measurement against the final edited heightmap with
  feature-aware local tolerance.
- Added `CdtTriangulator` as the triangulation seam:
  - pure Ruby Bowyer-Watson core
  - simple constraint recovery
  - topology diagnostics and non-manifold limitation reporting
  - injectable contract suitable for a future native/C++ triangulator adapter
- Added `Mta24ThreeWayTerrainComparison` for current/MTA-23/CDT rows over the same state and feature
  geometry.
- Added `Mta24HostedBakeoffProbe` for hosted sidecar evidence payloads.
- Kept CDT out of public MCP contracts and production terrain output routing.
- Added no-leak contract coverage so public terrain responses do not expose CDT, raw triangles,
  solver internals, candidate rows, or MTA-24 vocabulary.

## Important Fixes Found During Bakeoff

- Reworked CDT from feature-first/fixed-ratio simplification to residual-driven refinement:
  features seed mandatory geometry and influence tolerance, but final edited heightmap residuals
  decide additional points.
- Removed the dead private planner path from the older dense/policy-selected CDT approach after
  Grok review.
- Fixed MTA-23 hard-anchor handling so split-time hard-anchor checks only consider anchors inside
  the cell being evaluated, while output metrics still evaluate all anchors.
- Fixed MTA-23 adaptive subdivision so unsplittable off-grid anchors at minimum cell size do not
  block other height-error splits.
- Fixed live-probe generation mistakes discovered during manual review:
  - MTA-23 feature coordinates were regenerated correctly in grid space.
  - Current production comparison rows were not treated as feature-aware prototype rows.
  - Invalid pre-fix sidecars were removed and regenerated before decision evidence was accepted.

## Validation

Automated validation passed after the final Grok-requested cleanup:

- Focused CDT planner/backend tests.
- Focused MTA-23 adaptive-policy regression tests.
- Touched-file RuboCop checks with a writable cache path.
- Full `bundle exec rake ci`, including lint, Ruby tests, and package verification.
- `tldr dead` checks on the new CDT runtime files after cleanup.

Hosted/live SketchUp validation was run before the final code-review cleanup, after the runtime
behavior fixes that affected scene output. The final Grok cleanup only removed inactive private
planner code and did not change live geometry behavior, so no additional hosted geometry run was
required after that cleanup.

Live evidence summaries retained in this task folder:

- `live-h2h-metrics-2026-05-07.md`
- `live-h2h-intersecting-bounded-edits-2026-05-07.md`
- `live-h2h-decision-probes-2026-05-07.md`

Live validation covered broad head-to-head cases, intersecting/bounded edit probes, and corrected
decision probes after the MTA-23 fix. User visual inspection accepted the latest current, MTA-23,
and CDT sidecars for the checked cases, including bumpy corridor/reference cases, high-relief
preserve/corridor cases, and the intersecting bounded-edit case.

## Review Disposition

Grok 4.3 code review found no blocker and identified three low-severity items:

- Dead private methods remained in `CdtTerrainPointPlanner` from the earlier dense/policy-selected
  approach. Fixed by deleting that inactive path.
- Runtime budget handling in CDT is reporting-oriented rather than hard preemption before expensive
  retriangulation. Accepted as a prototype limitation and production follow-up gate.
- Protected crossing and constrained-edge coverage metrics are conservative and do not map perfectly
  to visual hard-geometry failure. Accepted as prototype evidence and production follow-up gate.

`$task-review` was run after Grok review and after addressing the code finding. Structural review
found no blocking L1/L2 issues. Security/taint checks found no scoped issues. Complexity/smell
checks reported expected prototype class size and parameter-shape warnings, but cognitive
complexity stayed within acceptable bounds for this comparison-only task. A resource warning on
MTA-23 instance variables was reviewed as a false positive, not a resource leak.

## Contract And Architecture Review

- No public MCP tool, schema, dispatcher, request, or response contract changed.
- No user-facing docs were required because the CDT backend remains internal comparison evidence and
  is not production-wired.
- Runtime outputs stay JSON-serializable.
- SketchUp sidecar helpers remain validation artifacts and do not overwrite production terrain.
- The production terrain state remains authoritative; CDT output is disposable derived geometry.

## Recommendation Evidence

Current production output remains the safety fallback because it is the production path and avoids
prototype runtime/constraint risk.

MTA-23 adaptive-grid is credible after the fixes, but hard/intersecting/bounded cases show that it
can become near-dense while still carrying many protected-crossing metric hits.

MTA-24 CDT is the better production-direction candidate because it:

- consumes the production `TerrainFeatureGeometry` substrate;
- preserves hard anchors and required protected/reference geometry through mandatory seeds;
- adds points from final-heightmap residual error rather than from a fixed sparse ratio;
- simplifies flattened final surfaces aggressively;
- preserves bumpy/high-relief detail when residuals justify more points;
- produces materially lower face counts than MTA-23 on harder decision probes.

The CDT verdict is not production-ready. It is a recommendation to create a production follow-up
with explicit gates.

## Follow-Up Gates

The production follow-up should keep current output as fallback and require CDT to pass:

- Runtime reduction for high-relief and repeated residual retriangulation cases.
- Stronger constraint recovery and hard-geometry classifier precision.
- Hosted acceptance across equivalent current/MTA-23/CDT cases without invalid sidecar generation.
- Cleanup or isolation of MTA-24 task-specific comparison and hosted-probe harnesses from
  production runtime code before production wiring. The prototype helpers were acceptable for
  evidence generation, but a production follow-up should not leave task/bakeoff harness ownership
  mixed into the long-lived terrain runtime surface.
- Public contract no-leak checks after any production wiring.
- Fallback routing criteria if CDT cannot satisfy runtime or topology gates for a terrain case.
