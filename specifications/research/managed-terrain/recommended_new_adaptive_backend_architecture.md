# Recommended Backend Architecture for Feature-Aware Adaptive Terrain Output

## Executive Recommendation

Do **not** replace the current adaptive TIN path.

The recommended backend is:

> **Feature-aware adaptive patch/cell terrain output, with optional sparse local detail state and optional bounded CDT islands.**

The current production path is already the right architectural spine:

```text
authoritative heightmap state
→ SketchUp-free edit kernels
→ dirty-window planning
→ PatchLifecycle
→ adaptive output
→ patch-owned SketchUp faces
→ registry/readback
```

The missing capability is not a new global triangulator. The missing capability is that feature intents should influence output topology, local density, simplification tolerance, protected boundaries, seam contracts, and validation.

The Landshape case study supports this framing: triangulation is necessary for SketchUp output, but it should not own the terrain model. The domain model should preserve terrain intent, control resolution locally, regenerate scoped regions, and emit triangles only as derived output.

---

## 1. Recommended Backend Architecture

Use a **feature-aware adaptive patch/cell backend**:

```text
authoritative terrain state
  - base heightmap grid
  - durable feature intents
  - optional sparse local detail tiles / feature overlays

        ↓

effective feature compiler
  - hard constraints
  - firm/soft pressure fields
  - protected masks
  - local tolerance/density fields
  - feature affected windows

        ↓

PatchLifecycle solve plan
  - dirty patches
  - replacement patches
  - conformance ring
  - retained neighbor spans
  - component promotion where needed

        ↓

feature-aware adaptive cell/TIN planner
  - height residual subdivision
  - feature-driven subdivision
  - protected-boundary handling
  - feature-aligned diagonal choice
  - seam-conforming edge splits

        ↓

optional local CDT islands
  - only for irregular hard geometry that cells cannot express well

        ↓

SketchUp-emittable derived mesh
  - triangles
  - patch-owned faces
  - registry/readback metadata
  - old output replaced only after validation
```

The current system already records feature intents and uses them for validation, selection, and
output-window planning, but the production adaptive mesher does not yet consume feature geometry to
preserve breaklines, insert feature-aligned edges, vary simplification tolerance, or enforce
protected-region topology. That is the next major upgrade.

---

## 2. Algorithm Choice and Rationale

### Primary Algorithm

Use:

> **Feature-aware adaptive quadtree/cell simplification over a composed height oracle, with patch-safe conformity and diagonal optimization.**

This is an evolution of the current adaptive TIN path:

```text
current:
height-error adaptive cells
+ fixed simplification tolerance
+ conformance pass
+ patch-owned triangle output

recommended:
height-error adaptive cells
+ feature-aware local tolerance
+ forced feature subdivision
+ protected masks
+ feature-aligned diagonals
+ deterministic seam contracts
+ optional local CDT islands
```

The current adaptive path already recursively subdivides grid cells, approximates cells with bilinear corner interpolation, measures max elevation error, stops within tolerance, emits triangles, and performs conformity handling when neighboring cells differ in size. This should remain the production base.

### Why Not Full CGAL CDT as the Default?

CGAL CDT is useful, but not as the main terrain model.

A global CDT/TIN backend would risk losing the advantages already proven in production:

- predictable patch ownership;
- cheap dirty replacement;
- stable grid-derived state;
- good SketchUp mutation behavior;
- sub-second representative edits;
- simple registry/readback;
- bounded conformance.

The recommended split is:

```text
default: feature-aware adaptive cells
fallback/special case: local CDT islands
not recommended: global arbitrary TIN/CDT backend
```

### Why This Solves the Resolution Problem

There are two different resolutions:

```text
state resolution  = base heightmap spacing
output resolution = density of emitted triangles
```

The current system can simplify output below the full grid, but its minimum output cell size is one source sample. So if a user needs true sub-grid detail in one area, increasing the whole source grid is currently the only path.

The recommended staged fix is:

1. **Feature-aware output resolution**  
   More triangles near corridors, pads, survey controls, protected boundaries, and hard/firm features without changing the source grid.

2. **Sparse local detail resolution**  
   Optional high-resolution local detail tiles or analytic feature overlays in selected regions, so one road, pad, corridor, or survey-controlled area can carry finer elevation detail without increasing the whole terrain grid.

The second step is the true answer to “higher resolution only where needed.”

---

## 3. Data Flow

### Existing Public Flow to Preserve

Keep the current public flow:

```text
create_terrain_surface / edit_terrain_surface
  → validate command
  → establish managed terrain owner
  → run SketchUp-free edit kernel
  → save terrain state
  → plan output
  → regenerate affected output
  → update patch registry/readback
```

The public command shape should remain stable.

### New Feature-Aware Backend Flow

Add an internal feature-aware output phase:

```text
1. Edit kernel returns:
   - new heightmap state
   - changed sample window
   - diagnostics/refusal
   - feature intent updates

2. Feature compiler builds EffectiveFeatureView:
   - output anchors
   - protected regions
   - pressure regions
   - reference segments
   - affected/relevance windows
   - local tolerances
   - hard/firm/soft roles

3. Output planner unions:
   - changed sample window
   - feature affected windows
   - protected-boundary windows
   - seam/conformance windows

4. PatchLifecycle resolves:
   - affected patches
   - replacement patches
   - conformance patches
   - retained-boundary spans
   - safety margins

5. Feature-aware adaptive planner builds:
   - local tolerance field
   - local target cell-size field
   - forced subdivision mask
   - protected mask
   - seam lattice
   - candidate diagonals / split edges

6. Mesh result returns:
   - vertices
   - faces
   - patch IDs
   - seam spans
   - feature residuals
   - validation summary
   - output policy fingerprint

7. PatchLifecycle-backed SketchUp mutation stages/replaces:
   - verify old ownership
   - validate replacement plan/output
   - erase only replacement faces
   - emit replacement faces
   - update registry/readback
```

The current dirty replacement behavior should remain: validate existing patch ownership and registry
state before replacement, refuse or safely fall back on active inconsistency, and erase only the
owned replacement faces after the replacement plan/output is available.

---

## 4. Incremental and Refinement Strategy

### V1: Feature-Aware Tolerance

Replace the single global simplification tolerance with a local function:

```text
tolerance(x, y) =
  base_tolerance
  modified by feature strength
  modified by feature role
  modified by slope/curvature
  modified by visual/diagnostic policy
```

Examples:

```text
normal terrain                 → coarse tolerance
near hard breakline             → strict tolerance
inside firm corridor support    → stricter tolerance
inside soft fairing region      → density pressure, not hard constraint
near survey anchor              → strict local residual
inside preserve region          → no topology or elevation violation
```

This is the lowest-risk upgrade because it keeps the current adaptive algorithm but makes it feature-aware.

### V2: Forced Subdivision and Feature Masks

Add subdivision rules that are independent of height residual:

```text
force subdivision if cell intersects:
- hard reference segment
- corridor centerline / side transition
- endpoint cap
- protected boundary
- target/planar boundary
- survey support radius
- local detail tile boundary
- seam lattice vertex
```

This prevents important design features from disappearing just because the height field happens to approximate well.

### V3: Diagonal Optimization

For each emitted cell or adaptive quad, choose the diagonal that best satisfies:

```text
- lower height interpolation error
- better slope continuity
- alignment with corridor or breakline direction
- avoidance of protected-boundary ambiguity
- better visual smoothness
```

This matches the Landshape insight that diagonals matter, but triangles should remain derived from a higher-level cell model.

### V4: Sparse Local Detail State

Add optional local detail tiles:

```text
base heightmap:
  spacing = global terrain spacing

local detail tile:
  patch/window-local
  finer spacing
  feature-owned or user-edit-owned
  participates in height oracle
  bounded by seam/conformance policy
```

The composed height oracle becomes:

```text
H(x, y) =
  hard fixed/control value if applicable
  preserve-region old value if applicable
  local detail tile value if present
  analytic feature surface if present
  base heightmap interpolation otherwise
```

This is how the system can provide high resolution only where needed without increasing the whole terrain.

### V5: Optional Local CDT Islands

Use CDT only where adaptive cells cannot cleanly represent the feature:

```text
- narrow road/pad boundaries
- complex hard breaklines
- circular protected regions
- dense survey-control clusters
- irregular transition bands
```

The CDT island must be clipped to a patch/component window and must return faces classifiable back to patch IDs.

---

## 5. Seam Strategy

Use:

> **deterministic seam contracts + retained neighbor spans + patch boundary anchors.**

### Retained Neighbor Spans

If only one side of a seam is regenerated, import the untouched neighbor’s boundary vertex chain as locked input. The replacement side must conform to it exactly.

If a new hard feature requires changing that seam, promote the neighbor patch into the replacement component. If promotion exceeds policy limits, refuse or full-rebuild rather than create a crack.

### Deterministic Seam Lattice

Each patch edge should have a stable seam key:

```text
seam_key = owner_id + patch_policy + patch_a + patch_b + edge_side
```

The seam lattice is generated from:

```text
- patch edge endpoints
- source-grid intersections
- adaptive split requirements
- hard feature crossings
- protected boundary crossings
- local detail tile boundaries
- retained neighbor spans
```

Both sides must get the same ordered boundary chain.

### No Stitch Strips as Default

Do not use mortar/stitch strips as the normal solution. They hide cracks but create ownership ambiguity and make patch readback/debugging worse.

Stitch strips are acceptable only as an internal debug visualization or emergency fallback, not as the production seam model.

---

## 6. Patch and Component Solve Strategy

Keep PatchLifecycle as the owner of patch identity and mutation. Add a **component planner** above the adaptive mesh planner.

Build a patch dependency graph:

```text
node = patch

edge exists when:
- dirty window touches both patches
- feature crosses patch boundary
- hard/protected region touches boundary
- seam lattice changes
- retained neighbor span cannot satisfy replacement patch
- local detail tile overlaps multiple patches
- conformance ring requires promotion
```

Then solve connected components independently.

Patch roles:

```text
affected          = touched by edit/feature relevance
replacement       = old faces will be replaced
conformance       = regenerated to maintain seams/transitions
retained-boundary = not replaced, but boundary span is locked input
safety-margin     = used for residual/feature evaluation, not emitted
```

This respects dirty-window performance while still allowing multi-patch solves when feature geometry or seams require it.

---

## 7. Native and Library Recommendation

### Do Not Add Native Code for V1/V2

Since representative edits are already sub-second, the first feature-aware versions should stay in the current production path. The risk is correctness and lifecycle integration, not raw triangulation performance.

### Add Native Only for Bounded Geometry Modules

Native code becomes reasonable for:

```text
- robust segment/primitive intersection
- polygon clipping
- local CDT islands
- expensive residual sampling over large components
- validation/fuzz geometry checks
```

SketchUp API calls must remain on the main thread. Native computation can run away from SketchUp only if it does not call SketchUp APIs.

### If CDT Is Needed: Use CGAL, Not Custom CDT

For local CDT islands, use CGAL privately behind the backend boundary.

Licensing needs explicit review. CGAL is distributed under GPL/LGPL open-source licenses and commercial licenses, so an AGPL extension should record exactly which CGAL packages/files are used and ship the required source/build/license materials.

Do not build a custom CDT as the first native geometry project.

---

## 8. Validation Gates

### Feature Validation

Before meshing:

```text
- unsupported hard/protected primitive → refuse
- conflicting hard features → refuse
- hard feature crossing protected region illegally → refuse
- feature derivation failureCategory present → refuse or fallback by policy
- firm/soft features cannot weaken hard topology
```

### Planning Validation

```text
- dirty window converted correctly to output/sample windows
- feature relevance windows included
- replacement/conformance/safety patches resolved
- retained neighbor spans available
- policy fingerprint computed
- state digest and feature-view digest attached
```

### Mesh Validation

```text
- no zero-area faces
- no inverted faces
- no patch-boundary-crossing faces
- every face has exactly one patch ID
- all hard patch boundaries respected
- adaptive conformance produces no cracks or T-junctions
- diagonals do not cross protected/forced boundaries
```

### Feature-Output Validation

```text
- hard anchors represented
- hard breaklines represented or explicitly refused
- protected regions preserved
- planar/target/survey residuals measured
- firm residuals reported when high
- local tolerance field actually satisfied
```

### Seam Validation

```text
- retained neighbor spans match exactly
- regenerated shared seams have identical vertex chains
- seam Z values match within tolerance
- no one-sided extra boundary splits
- seam lattice digest stored in patch metadata
```

### SketchUp Mutation Validation

```text
- old output remains until new component result validates
- existing patch ownership is complete before replacement
- staged face/vertex counts match result
- emitted faces are classifiable back to patches
- registry/readback updated atomically
```

---

## 9. Implementation Slices with Risk Ranking

The implementation order should distinguish between **capability slices** and **cross-cutting enablement slices**. Some slices, especially validation and default-enable evidence, should begin early and continue through later phases rather than being treated as final-only work.

### 9.1 Recommended Implementation Order

| Order | Slice | Work | Risk | Notes |
|---:|---:|---|---|---|
| 0 | **12. Baseline / default-enable harness starts** | Establish replay corpus, current performance baselines, rollback/fallback expectations, and acceptance metrics before changing mesh behavior. | Medium | Starts immediately, continues through all phases, and becomes the final default-enable gate. |
| 1 | **1. Feature-aware output policy** | Add feature-view digest, output policy fingerprint, local tolerance plumbing, feature diagnostics, and internal policy metadata. | Low | Should not materially change output yet. This creates traceability and safe rollout infrastructure. |
| 2 | **2. Local tolerance field** | Use feature strength, role, proximity, and terrain context to vary simplification tolerance spatially. | Low–Medium | First real feature-aware output behavior. Keeps the current adaptive TIN mechanics mostly intact. |
| 3 | **3. Feature pressure density field** | Add target cell-size pressure from corridors, survey controls, target regions, planar regions, fairing regions, and other feature supports. | Medium | Allows features to influence local output density without requiring hard topology changes yet. |
| 4 | **9. Hard/protected validation harness starts** | Add validation and fuzz coverage for feature overlaps, protected regions, dirty windows, seams, patch ownership, and residual gates. | Medium–High | Should begin before hard/protected features start changing topology. Expands throughout later phases. |
| 5 | **4. Forced subdivision masks** | Force adaptive cell subdivision around hard segments, protected boundaries, anchors, local detail boundaries, and feature-critical geometry. | Medium–High | First major topology-affecting slice. Requires strong validation and diagnostics. |
| 6 | **5. Diagonal optimization** | Choose cell diagonals using height residual, slope continuity, feature alignment, and deterministic tie-breakers. | Medium | Can improve visual quality without necessarily increasing face count, but must be deterministic. |
| 7 | **6. Seam contract upgrade** | Add deterministic seam lattice, retained neighbor spans, seam digests, and rules preventing one-sided extra boundary splits. | High | Required before serious local detail or cross-patch feature topology. Protects patch lifecycle reliability. |
| 8 | **7. Patch component planner** | Promote patches across features, seams, and local-detail boundaries while keeping dirty solves bounded by budgets. | High | Necessary for cross-patch correctness, but one of the largest threats to sub-second edit behavior. |
| 9 | **8. Sparse local detail tiles** | Add patch/window-local high-resolution state and a composed height oracle that combines base heightmap, feature surfaces, and local detail. | High | Strategic solution for local high detail without globally increasing terrain resolution. |
| 10 | **10. Optional local CDT islands** | Add CGAL-backed or equivalent local CDT only inside bounded irregular regions that cells/detail tiles cannot represent well. | High | Should remain an escape hatch, not the default terrain architecture. |
| 11 | **11. Native acceleration** | Move proven hotspots into native geometry kernels only after profiling and correctness evidence justify it. | Medium | Not necessarily sequential. Should be introduced only where Ruby implementation is demonstrably limiting. |
| 12 | **12. Final default-enable gate** | Run replay corpus, performance budgets, validation gates, rollback/fallback checks, and evidence review before enabling by default. | Medium | Same slice as Order 0, but used here as the final release gate. |

### 9.2 Suggested Groupings

#### Phase A — Safe Scaffolding

| Slice | Work | Risk |
|---:|---|---|
| **12** | Start baseline replay corpus, current performance measurements, rollback/fallback expectations, and default-enable criteria. | Medium |
| **1** | Add feature-aware output policy, feature-view digest, policy fingerprint, diagnostics, and local tolerance plumbing. | Low |
| **9** | Start validation harness for feature, patch, dirty-window, and output-policy invariants. | Medium–High |

This phase should not significantly change generated geometry. Its purpose is to make later behavior changes measurable, reversible, and explainable.

Expected gains:

```text
- safer rollout
- better diagnostics
- policy/version traceability
- baseline evidence before behavior changes
- clearer comparison against current production adaptive TIN
```

---

#### Phase B — Feature-Aware Output Without Major Topology Risk

| Slice | Work | Risk |
|---:|---|---|
| **2** | Add local tolerance field. | Low–Medium |
| **3** | Add feature pressure / target density field. | Medium |
| **5** | Add deterministic diagonal optimization. | Medium |

This phase keeps the current adaptive TIN path as the production spine. Features begin influencing density, tolerance, and diagonal choice, but the system avoids major hard-topology commitments at first.

Expected gains:

```text
- better triangle allocation
- denser output near important features
- potentially looser output away from important features
- improved visual quality from diagonal choice
- minimal disruption to PatchLifecycle
```

Main risks:

```text
- local face count may increase near features
- output may vary more visibly across regions
- diagonal choices must be deterministic to avoid topology flicker
```

---

#### Phase C — Hard / Protected Topology Correctness

| Slice | Work | Risk |
|---:|---|---|
| **4** | Add forced subdivision masks for hard segments, protected boundaries, anchors, and local-detail boundaries. | Medium–High |
| **6** | Upgrade seam contracts with deterministic seam lattice, retained spans, seam digests, and no one-sided extra splits. | High |
| **7** | Add patch component planner for feature/seam/local-detail promotion. | High |
| **9** | Expand validation harness for hard/protected features, seams, component promotion, and patch ownership. | Medium–High |

This phase is where features begin to materially affect topology. It is the transition from “features guide density” to “hard/protected features must be represented or refused.”

Expected gains:

```text
- hard features become real output constraints
- protected regions are safer
- cross-patch features are handled coherently
- seams remain valid under feature-driven splits
- local replacement remains trustworthy
```

Main risks:

```text
- more local faces
- larger dirty replacement components
- patch promotion can threaten sub-second edits
- seam bugs can create cracks or ownership ambiguity
- unsupported hard cases need clear refusal behavior
```

---

#### Phase D — True Local High Detail

| Slice | Work | Risk |
|---:|---|---|
| **8** | Add sparse local detail tiles and composed height oracle. | High |

This phase addresses the core scaling limitation: today, needing more geometric/elevation detail in one area can force higher resolution for the whole terrain. Sparse local detail tiles allow high-resolution local edits without globally increasing the base heightmap spacing.

Expected gains:

```text
- local high detail without global terrain refinement
- better roads, pads, swales, survey zones, and fine grading areas
- better long-term scaling for large terrains
- fewer total faces than an equivalent globally refined terrain
```

Main risks:

```text
- more complex terrain state
- harder edit kernels
- harder readback/debugging
- transition bands become important
- local detail boundaries must be seam-safe
```

---

#### Phase E — Irregular Geometry Escape Hatch

| Slice | Work | Risk |
|---:|---|---|
| **10** | Add optional local CDT islands for bounded irregular hard geometry. | High |
| **11** | Add native acceleration only for proven hotspots. | Medium |

This phase should not replace the adaptive patch/cell terrain architecture. CDT or native geometry should be used only where the cell/detail-tile model cannot cleanly represent specific irregular constraints or where profiling proves a bounded hotspot.

Expected gains:

```text
- cleaner handling of irregular hard boundaries
- better circular/curved protected regions
- better road/pad/corridor edge cases
- possible acceleration for isolated geometry kernels
```

Main risks:

```text
- native build and distribution complexity
- licensing review if using CGAL or similar libraries
- harder patch ownership classification
- harder validation
- risk of accidentally turning CDT into the main architecture
```

---

#### Phase F — Final Default-Enable Gate

| Slice | Work | Risk |
|---:|---|---|
| **12** | Final replay corpus, performance budgets, validation gates, fallback/rollback checks, and evidence review. | Medium |

This is the release-readiness gate. The backend should not become default merely because the implementation is complete. It should become default only after evidence shows that the new behavior preserves the strengths of the current production path.

Required evidence:

```text
- p95 local edit time remains within target
- dirty patch count remains bounded
- face count does not grow globally without reason
- hard/protected feature failures are caught before mutation
- seams have zero cracks / T-junction regressions
- patch ownership and registry readback remain reliable
- old output survives failed backend results
- local high-detail examples outperform equivalent global refinement
- fallback/refusal behavior is deterministic and explainable
```

### 9.3 Corrected Milestone View

```text
M0 — Baseline and scaffolding
  - Slice 12 starts
  - Slice 1
  - Slice 9 starts

M1 — Low-risk feature-aware output
  - Slice 2
  - Slice 3
  - Slice 5

M2 — Hard/protected topology
  - Slice 4
  - Slice 6
  - Slice 7
  - Slice 9 expands

M3 — Local high-detail state
  - Slice 8

M4 — Irregular fallback / acceleration
  - Slice 10
  - Slice 11 only if profiling justifies it

M5 — Default-enable evidence
  - Slice 12 final gate
```

### 9.4 Important Ordering Notes

Slice **12** appears at both the beginning and the end because it has two roles:

```text
early role:
  establish baseline, corpus, metrics, and rollback expectations

final role:
  decide whether the new backend behavior is safe to enable by default
```

Slice **9** should begin early and expand over time. It is not a final QA task. Once hard/protected features begin affecting topology, validation becomes part of the implementation itself.

Native acceleration and CDT islands should remain late-stage tools. The core architecture should stay:

```text
feature-aware adaptive patch/cell terrain output
+ deterministic seams
+ bounded patch/component solves
+ optional local detail
+ optional local CDT only where cells are insufficient
```


---

## 10. Explicit Non-Goals

Do **not**:

```text
- replace the production adaptive TIN path with a global CDT/TIN backend;
- make triangulation the terrain source of truth;
- recover feature intent from triangles after the fact;
- expose a public backend selector;
- expose raw CDT diagnostics publicly;
- change public command shape;
- solve local high-detail needs by globally increasing source grid spacing;
- delete old patch output before validation;
- use stitch/mortar strips as the normal seam strategy;
- silently approximate unsupported hard/protected features;
- let soft/fairing pressure override hard topology;
- depend on stable SketchUp face entity IDs;
- build a custom CDT as the first native geometry project.
```

---

## 11. Failure Modes

The backend should return structured refusal/failure and leave old output intact when:

```text
- unsupported hard/protected primitive is present;
- hard features conflict;
- hard feature violates preserve region;
- hard breakline cannot be represented under current cell/CDT policy;
- retained neighbor seam cannot satisfy new output without promoting neighbor;
- required component promotion exceeds patch/component budget;
- local detail tile boundary cannot be made seam-safe;
- residual/tolerance gates cannot pass within budget;
- patch registry or face ownership is inconsistent;
- emitted faces cannot be classified to patch IDs;
- SketchUp output contains unsupported child entities;
- native geometry module crashes or returns invalid topology;
- CGAL/CDT island cannot be clipped back into patch-owned output;
- performance budget is exceeded before hard validation passes.
```

---

## Final Position

The backend should be:

> **Feature-aware adaptive patch/cell terrain output, with optional sparse local detail state and optional bounded CDT islands.**

The production adaptive TIN path is already the right spine. The next backend should make feature intents operational.

Feature intents should affect:

```text
- dirty/relevance windows
- local simplification tolerance
- local output density
- forced subdivision
- protected boundaries
- hard/firm residual validation
- seam contracts
- diagonal choice
- eventually sparse local detail resolution
```

This gives Landshape-like architectural benefits without destabilizing the proven sub-second patch lifecycle.
