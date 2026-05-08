# CDT Terrain Output External Review

## Executive Verdict

The current hypothesis is correct:

> CDT is not the core mistake. The current residual policy is too global.

The current backend is doing something close to greedy terrain TIN simplification, but in an expensive form:

```text
sparse seed CDT
-> full-grid residual scan
-> add worst residual points
-> retriangulate the whole growing point set
-> repeat
```

That shape is unsuitable for interactive terrain editing when applied globally. The approach repeatedly discards locality, rebuilds the whole triangulation, and makes every edit pay for unrelated terrain and unrelated constraints.

The recommended direction is:

```text
Keep CDT as the constrained topology primitive.
Move terrain output to cached local patches.
Run residual refinement only inside dirty windows.
Spatially filter hard constraints instead of feeding all global hard constraints into every solve.
Bound refinement by quality, point budget, face budget, runtime, and improvement rate.
Only consider native triangulation after the residual policy is bounded.
```

Do **not** discard CDT yet. Also do **not** ship the current full-retriangulation residual loop as the normal interactive backend.

---

## Problem Framing

The terrain state is a dense/tiled heightmap. User edits are stored as durable semantic feature-intent records, including:

- target-height regions;
- preserve regions;
- fixed controls;
- survey controls;
- corridor transitions;
- planar regions;
- fairing regions.

The goal is to replace or supplement dense grid output with a lighter adaptive triangulated mesh that:

- preserves hard feature constraints;
- respects firm constraints where feasible;
- uses soft features as tolerance or pressure guidance;
- approximates the dense heightmap closely enough;
- emits materially fewer faces than the dense grid;
- regenerates fast enough for interactive edits.

The target expectation is sub-3-second regeneration for normal terrain edits.

The current implementation uses a Ruby CDT triangulator plus an application-specific residual refinement loop. CDT itself is only the triangulation primitive. The expensive part is the adaptive residual policy around it.

---

## Observed Failure Mode

The hosted probe results already identify the main issue.

A small controlled case showed:

- terrain size: `31x31` samples;
- feature records: roughly `26-31`;
- command with residual refinement: about `4-5.8s`;
- command with residual refinement disabled: about `136ms`;
- disabled refinement produced unacceptable height error.

Example pass timing:

```text
residual scans total: ~462ms
initial triangulation: ~54ms

retriangulations as points grew:
- 176ms
- 380ms
- 708ms
- 1215ms
- 1243ms

final mesh:
- 589 vertices
- 1116 faces
- max height error ~0.047
```

The residual scan cost is noticeable, but the dominant cost is repeated full CDT retriangulation as the point set grows.

On a larger hosted terrain, the CDT run took roughly 9 minutes, about 180x worse than the target.

This strongly suggests the failure is algorithmic/policy-level, not just implementation-level.

---

## Core Diagnosis

The current approach loses the most important optimization property of adaptive terrain simplification: locality.

Greedy residual insertion can be a valid terrain simplification strategy, but not when every refinement pass requires:

- scanning too much of the dense source;
- adding residual points globally;
- rebuilding the whole triangulation;
- carrying all globally active hard constraints;
- repeating this until a budget or tolerance limit is reached.

For interactive editing, the system should avoid making a small local edit pay for the entire terrain.

The current pipeline is closer to a global offline simplifier than an interactive terrain editor.

---

## Recommended Architecture

## 1. Treat Terrain Output as Cached Patches

The dense/tiled heightmap already gives you a natural partitioning strategy. Use that structure for output.

Instead of one global regenerated CDT mesh, maintain cached output patches.

Each patch should own:

- patch domain boundary;
- patch-local output vertices;
- patch-local output faces;
- seam/border vertices;
- local hard/firm/soft features;
- local error diagnostics;
- dirty/version metadata;
- source heightmap version;
- feature index version.

For an edit, compute:

```text
edit influence window
+ falloff / fairing margin
+ seam / stitch band
+ hard-feature safety margin
= dirty output window
```

Only patches intersecting the dirty output window should regenerate. Unchanged patches should keep their triangulation.

This converts the cost model from:

```text
every edit -> whole terrain solve
```

to:

```text
normal edit -> small bounded patch solve
```

That is the most important architectural shift.

---

## 2. Make Patch Boundaries Hard Constraints

Patch replacement only works if boundaries are stable.

Each regenerated patch should treat the following as hard topology:

```text
patch boundary vertices
neighbor seam vertices
protected-region boundaries intersecting the patch
hard anchors inside the patch
hard segments clipped into the patch
```

This allows the system to replace a local patch without invalidating neighboring terrain.

At minimum, the patch solver should guarantee:

- identical XY seam vertices along shared patch borders;
- compatible Z values along seams;
- no open cracks;
- no duplicate overlapping faces at patch borders;
- no protected-boundary crossing.

---

## 3. Run Residual Refinement Only Inside the Dirty Patch

Inside a dirty patch, the current residual approach can still be useful.

Recommended local flow:

```text
1. Build local patch domain.
2. Add patch boundary as hard constrained polygon.
3. Add hard anchors and clipped hard segments inside/intersecting patch.
4. Add firm support points/segments where relevant.
5. Add soft regions as tolerance/pressure modifiers only.
6. Run local CDT.
7. Measure height residual only inside the patch.
8. Add residual points inside the patch.
9. Retriangulate only the patch, or later insert points incrementally.
10. Stop by quality, face budget, point budget, runtime, or improvement slope.
```

Even if the first local-patch implementation still retriangulates each pass, the problem size becomes bounded.

That is a practical stepping stone before incremental CDT insertion.

---

## 4. Do Not Feed All Hard Constraints into Every Solve

The current hard feature behavior is likely too expensive.

Hard should mean:

> Must not be violated if the edit/output region touches it.

Hard should **not** mean:

> Must be included in every CDT solve, even if far outside the edited region.

Recommended rule:

```text
Hard constraints are globally durable,
but locally solved only when they intersect, constrain, or protect the dirty patch.
```

Examples:

| Constraint situation | Recommended behavior |
|---|---|
| Hard anchor inside dirty patch | Include as mandatory point |
| Hard anchor outside dirty patch | Do not include |
| Protected region intersects dirty patch | Include/clamp/refuse depending on edit |
| Protected region outside dirty patch | Do not include; existing output remains valid |
| Hard segment crosses dirty patch | Clip to patch and include clipped segment |
| Edit influence overlaps protected region | Refuse or fallback |
| Dirty window touches protected boundary | Include boundary segment and validate no crossing |

This preserves hard semantics without forcing every edit to carry all hard features.

The observed feature numbers show why this matters:

```text
total active features: 204
expected selected for one small edit after fix: 123
hard features alone: 122
```

That means relevance filtering helps, but hard constraints still dominate unless hard constraints become spatially owned.

---

# Answers to the 10 External Review Questions

## 1. Is repeated residual refinement with full retriangulation a known bad approach for interactive terrain editing?

Yes.

The general idea of residual-driven terrain simplification is valid, but the current implementation shape is poor for interactive editing.

The problem is not:

```text
residual refinement exists
```

The problem is:

```text
residual refinement is global
and each pass retriangulates the whole growing point set
```

That makes every local edit behave like a global terrain reconstruction.

For an interactive editor, residual refinement must be local, cached, budgeted, and ideally incremental.

---

## 2. Would incremental CDT insertion materially change the cost profile?

Yes, but only if paired with local residual invalidation.

Incremental insertion would avoid full retriangulation after every residual point or residual batch. Instead, inserting a point should update only the affected local region of the triangulation.

However, incremental CDT alone will not fix the system if the rest remains global.

The useful package is:

```text
local dirty patch
+ incremental point insertion
+ cached per-triangle residual/error candidate
+ priority queue keyed by weighted error
+ local invalidation after insertion
```

If the system still scans the full heightmap and considers all constraints globally, incremental insertion will only improve one part of the bottleneck.

---

## 3. Should residual refinement be local to the edit window instead of global?

Yes.

Residual refinement should normally be constrained to:

```text
dirty edit window
+ influence/falloff margin
+ fairing margin
+ seam/stitch band
+ relevant hard-feature safety margin
```

Global residual refinement should be reserved for:

- full export;
- explicit “rebuild terrain output” commands;
- background/offline quality passes;
- diagnostics;
- rare fallback paths.

It should not be the normal interactive edit path.

---

## 4. How should hard global constraints be handled without forcing every edit to carry all hard features?

Use spatial ownership and dirty-region relevance.

Hard constraints should be indexed spatially and included only when they are topologically relevant to the patch being regenerated.

Recommended categories:

```text
A. Inside dirty patch:
   include directly.

B. Intersecting dirty patch:
   clip and include.

C. Adjacent to dirty patch seam:
   include if needed for seam correctness or protected-boundary validation.

D. Outside dirty patch:
   do not include; preserve existing cached output.

E. Overlapped by edit influence:
   refuse, fallback, or expand dirty region depending on hard constraint type.
```

This keeps the semantic guarantee intact:

```text
Hard constraints must not silently degrade.
```

But it avoids the pathological interpretation:

```text
All hard constraints must participate in every local solve.
```

---

## 5. Is CDT the right primitive for heightmap-to-adaptive-terrain output, or should another simplification method happen first?

CDT is a reasonable topology primitive, but it should not be treated as the whole terrain simplification algorithm.

The better framing is:

```text
Feature-constrained topology generation
→ adaptive terrain point selection / simplification
→ constrained triangulation
→ validation
→ optional visual smoothing/fairing
```

CDT is useful for:

- preserving constrained segments;
- representing protected boundaries;
- incorporating mandatory anchors;
- keeping constrained topology explicit.

But CDT does not decide by itself which height samples matter. That is the job of the adaptive simplification policy.

So the answer is:

```text
Keep CDT, but place an error-bounded simplification policy before/around it.
Do not rely on raw CDT plus global residual passes as the whole design.
```

---

## 6. Are there known algorithms for error-bounded adaptive terrain TIN generation under hard/soft constraints that fit this use case?

Yes, the relevant family is:

- greedy insertion TIN simplification for heightfields;
- incremental Delaunay / constrained Delaunay insertion;
- constrained adaptive mesh refinement;
- quadtree/TIN hybrid terrain simplification;
- patch/tile-based terrain LOD;
- cached local mesh updates;
- priority-queue-driven residual refinement.

The closest conceptual match is:

```text
adaptive TIN generation from heightfield
using error-ranked candidate insertion
with constrained segments and local update regions
```

For your product constraints, the algorithm needs to be modified with feature semantics:

```text
hard features = mandatory topology / refusal boundary
firm features = strong support / diagnostic degradation
soft features = weighted tolerance / pressure, not topology
```

So this is not a pure textbook terrain simplification problem. Your MTA-20 feature-intent model is valuable because it gives the simplifier semantic information that a heightmap-only RTIN/quadtree approach lacks.

---

## 7. Should feature-constrained topology generation, height approximation, and visual smoothing be separated?

Yes. Strongly.

Recommended stages:

```text
A. Constraint topology
   - terrain domain
   - patch boundary
   - seam constraints
   - hard anchors
   - hard/protected boundaries
   - clipped firm segments

B. Height approximation
   - adaptive residual refinement
   - weighted local tolerance
   - point/face/runtime budget
   - error metrics

C. Visual smoothing/fairing
   - soft-region adjustment
   - normal smoothing
   - material/visual treatment
   - optional geometry smoothing only where allowed
```

This prevents soft visual goals from weakening hard topology.

Important rule:

```text
Smoothing must never move hard anchors,
cross protected boundaries,
or invalidate seam vertices.
```

---

## 8. Is native triangulation likely enough, or is the residual policy itself the main issue?

Native triangulation may help, but it is not enough.

The current issue is mostly policy-level:

```text
global residual scan
+ repeated full retriangulation
+ all hard constraints
+ growing point set
+ multiple passes
```

A native backend can improve constants. It cannot fully compensate for an interactive path that solves too much of the world.

Recommended order:

```text
1. Bound the problem with local patches.
2. Spatially filter hard constraints.
3. Add strict budgets and diagnostics.
4. Improve residual policy.
5. Then evaluate native triangulation.
```

Native triangulation should be an accelerator, not a rescue plan.

---

## 9. How should local edits update an existing triangulated terrain mesh without rebuilding the entire output?

Use patch replacement.

Recommended update flow:

```text
1. Receive edit.
2. Compute dirty output window.
3. Map dirty window to affected output patches.
4. Inflate for falloff/fairing/seams.
5. Collect relevant constraints for affected patches.
6. Regenerate affected patches only.
7. Validate hard constraints.
8. Validate seams.
9. Replace SketchUp entities/groups for affected patches.
10. Leave unaffected patches unchanged.
```

For SketchUp specifically, this implies that terrain output should be grouped or partitioned so local replacement is cheap and safe.

Avoid a single monolithic mesh entity that must be rebuilt after every edit.

---

## 10. What quality metrics should stop refinement without forcing near-dense reconstruction?

Use multiple stop criteria. Do not rely only on max height error.

Recommended hard gates:

```text
hard constraint violations = 0
protected-boundary crossings = 0
seam mismatch = 0 or within SketchUp-safe tolerance
invalid / non-manifold topology = 0
```

Recommended approximation metrics:

```text
local max height error
local RMS height error
p95 height error
weighted error near firm/soft features
slope or normal deviation where visually important
```

Recommended budget metrics:

```text
max points per patch
max faces per patch
max face ratio versus dense grid
max residual passes
max runtime per patch
max total runtime per edit
minimum improvement per pass
```

Recommended stop policy:

```text
Stop refinement when any of these is true:

1. hard validation fails -> fallback/refuse
2. target weighted tolerance is met
3. runtime budget is reached
4. point/face budget is reached
5. residual improvement per pass falls below threshold
6. added points no longer materially improve visual/geometric quality
```

This avoids turning adaptive output into near-dense reconstruction.

---

# Proposed Implementation Roadmap

## Slice 1: Patch-Local CDT Backend Using the Current Ruby Triangulator

Do not start by replacing the triangulator. First prove the policy change.

Add a feature-flagged output mode:

```text
cdt_output_mode = :local_patch
```

For one edit:

```text
1. Compute dirty sample window.
2. Inflate by configurable margin.
3. Resolve affected patches.
4. Collect only intersecting hard/firm/soft features.
5. Add patch boundary as hard constrained polygon.
6. Add seam vertices as hard boundary points.
7. Run current residual loop inside each affected patch only.
8. Emit diagnostics.
9. Replace only affected patch output.
```

Minimum diagnostics:

```json
{
  "patch_samples": [31, 31],
  "selected_features": {
    "hard": 0,
    "firm": 0,
    "soft": 0
  },
  "initial_triangulation_ms": 0,
  "residual_scan_ms": 0,
  "retriangulation_ms_total": 0,
  "passes": 0,
  "vertices": 0,
  "faces": 0,
  "max_error": 0,
  "rms_error": 0,
  "constraint_violations": [],
  "seam_violations": []
}
```

Suggested acceptance gates:

```text
31x31 controlled edit:
- backend < 500ms
- hard violations = 0
- seam violations = 0

normal hosted local edit:
- backend < 1500ms
- full SketchUp regeneration < 3000ms
- hard violations = 0
- seam violations = 0
```

---

## Slice 2: Add Bounded Residual Policy

Before incremental insertion, add strict residual controls:

```text
max_passes_per_patch
max_added_points_per_pass
max_added_points_per_patch
max_faces_per_patch
max_face_ratio_vs_grid
runtime_budget_ms
min_error_improvement_per_pass
```

Also add diagnostic reasons for stopping:

```text
:target_error_met
:point_budget_reached
:face_budget_reached
:runtime_budget_reached
:improvement_stalled
:hard_constraint_failure
:seam_validation_failure
:fallback_to_grid
```

This makes CDT behavior explainable and safe before it becomes more complex.

---

## Slice 3: Spatial Index for Feature Selection

Current relevance filtering helps firm/soft features, but hard features still dominate.

Add a spatial index over feature intent records.

Feature query should support:

```text
features.intersecting(window)
features.contained_by(window)
features.near_boundary(window, margin)
features.protecting(window)
```

Then selection becomes:

```text
hard:
  include only hard features intersecting/protecting/near dirty patch

firm:
  include if relevance window intersects dirty patch

soft:
  include as tolerance/pressure only if influence intersects dirty patch
```

Important behavior:

```text
A stale effective index should still be refused in normal output.
Do not silently rebuild and proceed if that hides correctness problems.
```

---

## Slice 4: Incremental / Heap-Based Residual Refinement

After patch-local output is stable, replace repeated patch retriangulation with an incremental strategy.

Target shape:

```text
1. Build local constrained triangulation.
2. For each triangle, find worst local residual candidate.
3. Push candidate into heap keyed by weighted error.
4. Pop worst candidate.
5. Insert point incrementally.
6. Recompute candidates only for affected triangles.
7. Repeat until stop condition.
```

This is the long-term fix for the repeated retriangulation cost.

---

## Slice 5: Native Triangulation Evaluation

Only after the above is working should native triangulation be evaluated.

Evaluate native triangulation against the bounded local-patch backend, not against the current global residual backend.

Useful comparison:

```text
Ruby CDT, current global policy
Ruby CDT, patch-local policy
Ruby CDT, patch-local + bounded residual
Native CDT, patch-local + bounded residual
Native CDT, patch-local + incremental residual
```

This will show whether native code solves the remaining constant-factor problem or whether policy is still dominating.

---

# Recommended Internal Architecture Shape

Suggested components:

```text
TerrainOutput::DirtyWindowResolver
TerrainOutput::PatchIndex
TerrainOutput::PatchStore
TerrainOutput::FeatureSpatialIndex
TerrainOutput::ConstraintCollector
TerrainOutput::PatchCdtBuilder
TerrainOutput::PatchResidualRefiner
TerrainOutput::PatchValidator
TerrainOutput::PatchEmitter
TerrainOutput::OutputDiagnostics
```

Responsibilities:

## `DirtyWindowResolver`

Owns:

- edit influence window;
- falloff expansion;
- fairing expansion;
- seam expansion;
- protected-feature safety expansion.

Does not know CDT internals.

## `PatchIndex`

Owns:

- mapping sample windows to output patches;
- patch adjacency;
- seam ownership;
- dirty patch expansion.

## `FeatureSpatialIndex`

Owns:

- spatial lookup for hard/firm/soft features;
- stale index detection;
- no fail-open behavior.

## `ConstraintCollector`

Owns:

- converting relevant feature intent into local constraints;
- clipping firm/hard segments to patch domain;
- preserving hard-vs-firm-vs-soft semantics.

## `PatchCdtBuilder`

Owns:

- local CDT input generation;
- patch boundary constraints;
- seam constraints;
- mandatory points;
- constrained segments.

## `PatchResidualRefiner`

Owns:

- local residual measurement;
- weighted tolerance;
- point insertion policy;
- stop conditions;
- refinement diagnostics.

## `PatchValidator`

Owns:

- hard constraint validation;
- protected-boundary validation;
- seam validation;
- topology validation;
- error validation.

## `PatchEmitter`

Owns:

- replacing SketchUp patch entities;
- preserving grouping/layer/material conventions;
- not exposing raw CDT internals through MCP responses.

---

# Fallback Policy

Fallback is acceptable and should be explicit.

Recommended fallback cases:

```text
hard constraint cannot be preserved
protected region would be crossed
patch seam cannot be made valid
runtime budget exceeded before usable mesh
triangle quality below minimum
face budget exceeded
residual error remains unacceptable
triangulator returns invalid topology
```

Fallback targets:

```text
1. local dense grid patch output
2. existing stable grid output
3. previous cached patch output, if edit can be refused safely
4. full grid regeneration for explicit rebuild/export path
```

Do not silently degrade hard constraints to make CDT succeed.

---

# Practical Recommendation

The next engineering move should be:

```text
Implement patch-local CDT output using the existing Ruby triangulator.
Keep residual refinement, but confine it to dirty patches.
Add strict budgets and diagnostics.
Spatially filter hard constraints.
Only then evaluate incremental insertion and native triangulation.
```

This gives a low-risk path that tests the key hypothesis:

```text
The concept is partially valid.
The current implementation is too global.
```

If patch-local bounded CDT still cannot meet quality/performance targets, then it is time to consider replacing the residual approach with a more specialized adaptive TIN/quadtree hybrid.

But based on the current evidence, the first fix should be locality, not a new triangulator.

---

# Final Direction

Recommended final architecture:

```text
CDT remains the constrained topology primitive.
Terrain output becomes patch-local and cached.
Residual refinement becomes local, budgeted, and feature-weighted.
Hard constraints become spatially relevant, not globally fed into every solve.
Native triangulation is deferred until the policy is bounded.
```

This is the most likely path to sub-3-second normal edit regeneration while preserving the semantic feature model and avoiding a return to heightmap-only simplification.
