# Summary: MTA-19 Implement Detail Preserving Adaptive Terrain Output Simplification

**Task ID**: `MTA-19`
**Status**: `failed; implementation reverted`
**Checkpoint Date**: `2026-05-02`

## Final Decision

MTA-19 implementation was reverted and should not be committed as runtime code.

The attempted adaptive TIN replacements were worse than the previous MTA-11 simplification path
for corridor-heavy terrain. Public terrain samples often matched the requested heightfield, but
generated SketchUp topology still showed refusals, long runtimes, and suspicious/folded-looking
normal discontinuities. The failure was not localized to one edit shape or one threshold.

The previous simplification path should remain production behavior until a replacement is proven
in a standalone benchmark and then in live SketchUp.

## What Was Attempted

### 1. Mesh-Oriented Adaptive TIN Output

The first implementation replaced the MTA-11 adaptive-cell output path with a mesh-oriented
adaptive TIN path:

- added `AdaptiveTerrainSimplifier`;
- added `SimplifiedTerrainMesh`;
- changed `TerrainOutputPlan` to plan `adaptive_tin` output from a simplified mesh;
- changed `TerrainMeshGenerator` to emit generic indexed triangles instead of adaptive cells;
- preserved public response vocabulary as `heightmap_grid` plus compact `adaptive_tin`;
- added contract tests to avoid leaking raw vertices, raw triangles, algorithm names, tile fields,
  Ruby class dumps, or SketchUp object dumps.

Local automated tests initially passed, but live MCP verification showed that local sample/error
checks were not enough to prove visible SketchUp topology.

### 2. Greedy / Patch-Accumulating Fixes

Early fixes tried to address visible failures by adding more refinement behavior around failing
triangles and topology checks.

This improved some simple cases, especially hard rectangular edits on crossfall terrain, but it
did not solve the general problem. Circle and corridor edits still produced suspicious topology,
and the implementation was drifting toward additive repairs rather than the planned restricted
hierarchy.

This phase was rejected because it was plan-incompatible:

- arbitrary interior point insertion;
- split candidate scoring not owned by a deterministic hierarchy;
- post-hoc T-junction repair;
- post-hoc normal-break repair;
- fallback behavior that effectively reverted to earlier dense/adaptive-cell output.

### 3. Restricted Integer-Grid RTIN-Style Rewrite

The implementation was restarted around the revised plan:

- final-heightfield feature pressure from cell curvature and neighboring slope breaks;
- deterministic feature-bounded root rectangles;
- balanced lattice edge bisection only;
- shared-edge split propagation;
- no arbitrary interior insertion;
- no free-form split scoring;
- no post-hoc mesh repair loops;
- no dense fallback;
- structured refusal when tolerance could not be satisfied.

This looked better in local tests and passed full local CI. It also improved several live cases:
hard rectangle and circle edits became much better than the earlier folded outputs.

However, corridor-heavy verification still failed at the product level.

## What Failed In Live Verification

The final reset pass showed the adaptive TIN path was still not reliable:

| Case | Result | Notes |
|---|---:|---|
| 41x41 crossfall corridor | Succeeded | 1148 faces; no down/non-manifold faces, but 14 sharp normal breaks, worst `37.57 deg`. |
| 41x41 flat corridor | Succeeded | 1402 faces; no down/non-manifold faces, but 31 sharp breaks, worst `70.25 deg`; suspicious for flat source terrain. |
| 61x61 crossfall corridor | Refused | `adaptive_output_generation_failed / tolerance_not_satisfied`; terrain effectively stayed at prior planar output. |
| Rectangle + circle + corridor sequence | Succeeded | 922 faces; only 5 sharp breaks, worst `36.68 deg`; best corridor-heavy result. |
| Steep crossfall corridor | Succeeded | 1504 faces; endpoints matched, but 78 sharp breaks, worst `81.69 deg`; visually high-risk. |
| Descending corridor | Succeeded | 1512 faces; endpoints matched, but 82 sharp breaks, worst `78.27 deg`; visually high-risk. |
| Nonsquare 71x31 corridor | Succeeded | 1361 faces; only 4 sharp breaks, worst `36.87 deg`, but included very long simplification edges. |

The strongest failure came from a sophisticated adopted terrain:

- unmanaged Ruby terrain source had ridges, mound, hollow, ripple, and base slope;
- source mesh had `1440` faces;
- adoption exceeded the default `120s` MCP timeout, but SketchUp continued and completed the
  one-time conversion successfully after roughly another minute;
- adopted output had about `14971` faces;
- multiple corridor variants refused;
- an exact existing-grade monotonic corridor exceeded the default `120s` MCP timeout, then later
  completed in SketchUp;
- output changed to about `14802` faces;
- profile became corridor-like and endpoints were plausible;
- generated topology still had 65 sharp normal breaks, worst `55.35 deg`.

## Why The Implementation Was Rejected

The implementation failed three critical product requirements:

1. **Reliability**: valid-looking corridor edits could refuse with `tolerance_not_satisfied`.
2. **Edit latency envelope**: corridor-heavy adaptive regeneration could exceed the default MCP
   timeout. Adoption latency is a lesser concern because it is a rare, one-time conversion path;
   corridor edit latency is more important because it is part of terrain authoring.
3. **Visual topology**: successful edits could produce suspicious sharp normal discontinuities
   even when public sampling and heightfield state looked correct.

The primary blocker is still topology and refusal reliability, not adoption duration. Long-running
host operations should eventually get clearer progress/timeout semantics, but the implementation
was rejected because corridor output remained unreliable even when operations completed.

## Main Technical Diagnosis

The failing class is:

> correct heightfield state plus unreliable generated adaptive triangulation topology.

Sampling and residual checks can pass while the emitted triangle connectivity still crosses terrain
features in visually bad ways. Corridors are especially demanding because they combine:

- longitudinal start and end caps;
- side transitions;
- rising or descending grade;
- hard or semi-hard drops back to existing terrain;
- overlap with pads, circles, fairing, or prior edits;
- irregular adopted terrain where the background surface is already complex.

The simplifier was able to satisfy point elevations in many cases, but it did not provide a robust
feature-aware triangulation model for these mixed discontinuities.

## Lessons Learned

- Public sample correctness is not sufficient for terrain output acceptance. Mesh topology needs
  explicit validation against visual artifact classes.
- Corridor start/end caps are at least as important as side blends. The implementation focused too
  much on side transition behavior before live feedback made endpoint drops obvious.
- Shape-specific fixes are a trap. Hard rectangle, circle, and corridor tests can pass while
  combined or adopted-terrain cases still fail.
- Local unit tests need captured final heightfields from live failures, not only hand-modeled
  approximations.
- A restricted RTIN-style hierarchy is not automatically safe for arbitrary edited heightfields.
  It can still refuse valid terrain or produce suspicious topology unless feature constraints are
  materially stronger.
- Full-regeneration acceptance does not remove performance risk. Rare adoption operations can
  tolerate multi-minute waits, but repeated edit regeneration needs a practical latency envelope
  or explicit long-running operation semantics.
- Review gates and green local CI did not predict hosted visual failure. For terrain meshing, live
  SketchUp artifact checks remain mandatory before calling an implementation viable.
- The previous MTA-11 simplification is more reliable in practice and should remain production
  until a replacement proves itself against the corridor/adopted-terrain matrix.

## Delaunay / CDT Follow-Up Guidance

Delaunay remains worth researching, but not as a quick patch to this failed implementation.

The useful future direction is likely not plain global Delaunay. It would need a prototype around:

- greedy heightfield TIN or DELATIN-style point insertion for vertical tolerance;
- constrained edges or breaklines for corridor sides, corridor end caps, pads, terraces, planar
  fit boundaries, and other feature transitions;
- hard face-count and runtime guardrails;
- topology validation before SketchUp mutation;
- clearer handling for long-running host operations that may exceed a default MCP client timeout.

That work should start as a separate research/prototype task using captured heightfields:

- flat corridor;
- steep and descending corridor;
- crossfall corridor;
- corridor over rectangle/circle;
- adopted sophisticated irregular terrain plus corridor.

Only after that standalone harness beats the current reliable simplifier should production runtime
integration be considered.

## Reverted Runtime Changes

The following implementation artifacts were reverted or deleted:

- `src/su_mcp/terrain/adaptive_terrain_simplifier.rb`;
- `src/su_mcp/terrain/simplified_terrain_mesh.rb`;
- adaptive mesh changes in `src/su_mcp/terrain/terrain_output_plan.rb`;
- adaptive indexed-triangle emission changes in `src/su_mcp/terrain/terrain_mesh_generator.rb`;
- MTA-19 simplifier, simplified mesh, output plan, mesh generator, and contract-stability tests.

MTA-19 documentation remains so the failed approach, evidence, and lessons are not lost.

## Final Recommendation

Do not revive this implementation branch.

Future work should either:

1. make a small, low-risk improvement to the previous reliable simplifier; or
2. create a new Delaunay/CDT/DELATIN prototype task with captured live failure heightfields and
   strict pre-mutation topology/performance gates.
