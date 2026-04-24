# Signal: Partial Terrain Authoring Session Reveals A Stable Patch-Oriented Terrain Editing Contract

**Date**: `2026-04-24`
**Source**: Session notes distilled from a partial terrain authoring and exploration pass that repeatedly fell back to `eval_ruby`
**Related Signals**:
- [Greenfield Semantic Authoring Is Viable But Lifecycle Gaps Remain](./2026-04-15-greenfield-semantic-authoring-is-viable-but-lifecycle-gaps-remain.md)
- [Semantic Lifecycle Gaps Still Force Eval Ruby Fallbacks](./2026-04-15-semantic-lifecycle-and-eval-ruby-gap-signal.md)
**Related PRDs**:
- [Semantic Scene Modeling](../prds/prd-semantic-scene-modeling.md)
- [Scene Targeting and Interrogation](../prds/prd-scene-targeting-and-interrogation.md)
- [Scene Validation and Review](../prds/prd-scene-validation-and-review.md)
**Related HLDs**:
- [Semantic Scene Modeling](../hlds/hld-semantic-scene-modeling.md)
- [Scene Targeting and Interrogation](../hlds/hld-scene-targeting-and-interrogation.md)
**Related Tasks**:
- [SEM-13 Realize Horizontal Cross-Section Terrain Drape for Paths](../tasks/semantic-scene-modeling/SEM-13-realize-horizontal-cross-section-terrain-drape-for-paths/task.md)
- [STI-02 Explicit Surface Interrogation via Sample Surface Z](../tasks/scene-targeting-and-interrogation/STI-02-explicit-surface-interrogation-via-sample-surface-z/task.md)
- [SVR-03 Establish Measure Scene MVP With Structured Measurement Modes](../tasks/scene-validation-and-review/SVR-03-measure-scene-mvp-with-structured-measurement-modes/task.md)
**Related Guide**:
- current source-of-truth docs
**Status**: `actioned`
**Disposition**: `follow-up recommended across bounded terrain authoring, explicit host-target sampling, and terrain validation`

## Summary

A partial terrain-authoring session exposed a repeated workflow that the current MCP surface still does not make first-class:

- create a working terrain copy
- preserve fixed controls and protected zones
- sample the same terrain points before and after each edit
- rebuild only a bounded local patch
- shape that patch from simple grading rules and blend zones
- inspect the result visually as well as numerically
- discard and rebuild quickly when topology becomes dirty

The important signal is not only that `eval_ruby` was used. It is that the fallback usage was highly structured and repetitive.

The session did **not** behave like open-ended arbitrary Ruby experimentation. It repeatedly converged on a stable terrain-authoring loop with recurring inputs, recurring failure modes, recurring checks, and recurring desired outputs.

That means the current posture of:

- terrain relationships and interrogation are productized
- broad terrain authoring remains `eval_ruby`-first

is now under pressure from an actual repeated workflow rather than a speculative wishlist.

## Current Product Boundary Pressure

The current live and documented surface already covers adjacent terrain needs better than before:

- `sample_surface_z` provides explicit target-based surface interrogation
- `path + surface_drape` now covers one terrain-aware semantic creation case
- `validate_scene_update` has begun to absorb geometry-aware and terrain-relationship checks

But the terrain session still fell back to `eval_ruby` for the actual authoring loop because the current surface does not expose first-class terrain modification behavior such as:

- working-copy creation and disposal
- local terrain patch replacement
- constrained grading regions
- preserve-zone-aware grading
- rollback-friendly terrain edit boundaries
- terrain-specific topology and fairness validation

This is therefore not mainly a signal about weak generic mutation tools. It is a signal about a missing terrain-native authoring model.

## Repeated Working Loop Observed In The Session

The main loop was stable across several retries:

1. duplicate the baseline terrain
2. hide and lock the original
3. sample the working terrain at fixed XY probes
4. define a bounded grading zone
5. rebuild a local terrain patch inside that zone
6. shape the patch from piecewise grading rules
7. smooth internal edges
8. resample the same probes
9. visually inspect top and underside conditions
10. discard and rebuild from the hidden original whenever the method produced bad geometry

This loop matters because it is already close to a compact MCP authoring contract:

- create working copy
- sample
- apply grade constraints
- rebuild patch
- validate
- commit or discard

## What Repeated Reliably

Five ideas kept recurring throughout the session:

### 1. Fixed controls had to remain fixed

The terrain edit was not free-form sculpting. Several controls had to stay anchored:

- west edge and road side
- north side and fence side
- later south control
- cherry trunk preserve zone

The repeated question was not “can the terrain move?” It was “can the terrain move locally without violating these locked references?”

### 2. Local patch replacement was safer than live-TIN dragging

Broad mesh edits caused collateral damage. The safer method was:

- cut a bounded patch perimeter
- remove the interior faces
- rebuild a fresh triangulated patch
- stitch it back to the untouched outer terrain
- smooth internal edges

This was materially more reliable than dragging existing live terrain vertices around.

### 3. Sample first, edit second, sample again

Before-and-after probe comparisons drove most decisions:

- sample terrain `z` at the same fixed XY points
- compare path, threshold, lawn, shoulder, and preserve-zone behavior
- use the numeric change as a correction signal

The session consistently needed explicit host-target sampling rather than generic scene probing.

### 4. Piecewise grading logic was the real authoring model

The terrain was not edited with one global slope. It was shaped through several local behaviors:

- side shoulders
- path bands
- threshold hinge
- lawn plane
- island shelf
- east service shoulder
- cherry preserve zone

The effective authoring model was therefore region-based and constraint-based rather than primitive-only.

### 5. Fast reset mattered

When a terrain method produced bad topology, the productive move was to throw the patch away and rebuild from the hidden original.

That means transactionality was not a convenience. It was central to the workflow.

## What Repeatedly Failed

The bad method was:

- intersect the terrain with many temporary cut planes
- drag existing vertices around afterward

That repeatedly caused:

- stray edges ending nowhere
- underside tears or holes
- harsh triangulation artifacts
- accidental drift outside the intended edit zone

The session therefore produced a practical negative result:

- broad cut-plane-driven terrain editing is dangerous for this workflow
- local patch rebuild is materially safer than editing the live triangulation in place

## Recurring Calculations

The same calculations kept reappearing:

- raytest-style terrain sampling at fixed XY probes
- linear ramps for longitudinal path and threshold fall
- crossfall interpolation across the threshold hinge
- distance-based blending toward local target elevations
- preserve-zone gating around the cherry tree
- polyline-progress interpolation along a descending path
- shoulder interpolation from fixed terrain edges toward target path levels

This matters because these are not arbitrary one-off math tricks. They are recognizable terrain-authoring primitives that could be expressed declaratively.

## Recurring Checks

The same checks mattered every time:

- did fixed controls move
- did the cherry ground move
- did side paths become trench-like
- did the threshold read as a bump or berm
- did crossfall look believable
- did topology get corrupted
- did the edited patch visually read as circulation instead of just satisfying probe values

The strongest repeated lesson was that numeric sampling alone was not enough.

Visual underside or seam inspection caught issues that point probes did not catch.

## Important Gotchas Preserved By This Signal

### 1. Sampling can hit vegetation instead of terrain

The session had to hide `VEG-006` during raytests because a visibility-based probe could hit the tree instead of the intended terrain host.

This strengthens the need for:

- explicit target-based terrain sampling
- host-target semantics stronger than `visibleOnly`

### 2. Broad cut planes are dangerous

They create unintended intersections outside the intended grading zone and make topology cleanup too fragile.

### 3. Flat target bands create fake trenches

A path or shoulder can be numerically valid and still read like a trench if the longitudinal fall and shoulder blending are not solved together.

### 4. Meeting flat zones creates humps

Threshold strips, lawn planes, and path bands need explicit blend regions rather than simple adjacent flat surfaces.

### 5. Preserve zones must be first-class

Without explicit no-raise or damped-influence behavior, grading bleeds into protected tree areas.

### 6. Object ids changed after each rebuild

The repeated copy or rebuild loop changed persistent ids and made continuity brittle.

That increases the value of stable tool-side working-copy and patch handles.

### 7. Visual validation matters as much as sampled values

The final surface still needed to read like believable circulation, not just a legal grid of probe heights.

## Core Capability Gaps Surfaced

The session would have been materially faster and safer with first-class support for:

1. working-copy duplication for terrain targets
2. explicit hide and lock controls for baseline terrain
3. host-targeted terrain sampling against a named terrain object
4. replace-local-patch behavior instead of live-mesh dragging
5. declarative grade regions such as plane, ramp, shoulder blend, crossfall, path-following fall, and terrace bench
6. preserve or protect zones with no-raise, no-cut, or damped grading influence
7. terrain blend zones between adjacent grade intents
8. profile-oriented terrain checks for humps, trenches, and slope breaks
9. patch validation for holes, loose edges, non-manifold conditions, seam quality, and slope spikes
10. transactional terrain edits with commit or rollback semantics

These requests are notable because they cluster into one coherent authoring family rather than many unrelated tool ideas.

## Editing Primitives Alone Are Not Enough

Even after repeated retuning, the resulting terrain remained somewhat bumpy because the fallback method was still assembling a TIN from discrete control rows, sampled targets, piecewise ramps, and smoothed edges.

That was good enough to explore grading logic, but not good enough to author a convincing final terrain surface efficiently.

The deeper missing capability was not only more edit primitives. It was constrained fairing under terrain-specific rules.

The session therefore points toward a second-order need:

- solve or fair a local patch under constraints
- preserve locked controls
- respect no-raise or no-cut zones
- satisfy target slope regions
- reduce abrupt curvature changes

In other words, the desired terrain result is not only:

- topologically valid
- locally sampled correctly

It is also:

- continuous
- visually fair
- free of abrupt curvature spikes
- believable as circulation and graded ground

## What This Signal Directly Supports

- A bounded patch-oriented terrain workflow is now repeated enough to describe as a product pattern.
- Explicit target-based terrain sampling is necessary but insufficient on its own for terrain authoring.
- The most reliable terrain-editing posture observed so far is local patch rebuild, not broad live-mesh manipulation.
- Preserve zones, fixed controls, grade regions, and blend bands recur often enough to deserve first-class vocabulary.
- Terrain validation needs more than topology checks and point-hit checks; it also needs profile and fairness-oriented evidence.

## What This Signal Suggests But Does Not Yet Prove

- that broad terrain authoring should immediately move into the current semantic-scene-modeling capability rather than a separate later capability
- that one exact public tool split is already known
- that the first implementation needs a full terrain solver rather than a smaller bounded patch workflow first
- that all terrain editing should stop using `eval_ruby` immediately

## Why This Signal Matters

The current repo posture explicitly keeps broad terrain authoring out of scope while treating terrain interrogation, hosting, and validation as stronger early candidates.

This signal does not invalidate that caution. It does, however, preserve an important update:

- terrain authoring is no longer only a broad speculative area
- at least one recurring terrain-authoring workflow is now concrete enough to describe with repeated constraints, operations, validations, and failure modes

That makes it a candidate for bounded first-class productization rather than an indefinitely unstructured Ruby escape hatch.

## Follow-On Question Preserved By This Signal

If the platform productizes terrain modification, should the first terrain-native contract be a bounded patch-authoring workflow centered on:

- working-copy management
- explicit host-target sampling
- grade regions
- preserve zones
- local patch rebuild
- terrain-specific validation
- commit or discard

rather than a broad free-form terrain-editing surface?

## Expansion Context

### Ownership Posture

The strongest owning capability for this signal is still existing terrain-adjacent capability, not a new standalone terrain-authoring product slice.

- primary owner: `scene-targeting-and-interrogation`
- secondary owner: `scene-validation-and-review`
- tertiary dependent area: bounded future mutation or helper work, only if repeated terrain-edit pressure remains high after interrogation and validation gaps are addressed

The current evidence does not yet justify a new terrain-authoring PRD.

### Current Artifact Coverage

Already covered:

- explicit terrain sampling through `sample_surface_z`
- one terrain-aware semantic creation case through `path + surface_drape`
- initial terrain-relative geometry validation through `validate_scene_update`

Deferred or already constrained by source specs:

- broad terrain authoring remains `eval_ruby`-first in `specifications/prds/prd-semantic-scene-modeling.md`
- public structured measurement remains planned but unshipped through `measure_scene`
- the guide still preserves `terrain_patch` as a possible later surface, but not as an approved current product commitment

Missing in live implementation:

- `measure_scene`
- host-only terrain profile and section interrogation
- working-copy lifecycle for terrain targets
- bounded patch-rebuild helpers
- terrain-specific profile, fairness, and seam diagnostics

### Implementation Drift Worth Preserving

`specifications/hlds/hld-scene-validation-and-review.md` still says the repository does not yet implement `validate_scene_update`, but the runtime and README now show that `validate_scene_update` is live. That HLD drift should be corrected before terrain follow-on planning relies on it.

## Selected Analysis Findings

### Technical Feasibility

The main gap exposed by this signal is missing behavior, not merely missing trust.

- the runtime has terrain interrogation and one terrain-aware creation path
- the runtime does not have terrain measurement, terrain patch helpers, or terrain working-copy controls
- the most credible near-term quick wins are interrogation and measurement extensions, not a full terrain-editing surface

### Architecture Context

The signal does not justify pushing terrain logic into the wrong layer.

- target-based terrain interrogation belongs with `scene-targeting-and-interrogation`
- terrain profile, slope, trench, hump, and fairness evidence belongs with `scene-validation-and-review`
- any future patch-edit helper should remain a narrow Ruby command slice and should not be hidden inside semantic creation or bootstrap/runtime files

### Market Research

External patterns strengthen a conservative posture.

- SketchUp native terrain tools are basic TIN editing and placement tools, not a terrain solver
- stronger terrain workflows in the SketchUp ecosystem are specialized and paid
- Unreal is useful as a pattern source for layers, smoothing, and brush architecture, but not as a reason to promise a large terrain-authoring product commitment now

This external evidence weakens the case for broad first-class terrain authoring and strengthens the case for manual or plugin terrain editing plus MCP-owned terrain-aware automation.

## Evidence-Backed Hypothesis

### Strong Evidence

- the signal captures a repeated workflow rather than one-off fallback Ruby usage
- the repeated workflow depends on explicit host-target sampling, local patch reasoning, preserve zones, and visual plus numeric validation
- live implementation supports terrain-adjacent interrogation and hosting, but not terrain modification
- current product artifacts already favor terrain relationships, interrogation, and validation before broad terrain authoring

### Moderate Inference

- the next justified terrain-related slice is bounded terrain-aware automation rather than a new terrain-authoring PRD
- the highest-value quick wins are likely:
  - stronger host-only sampling and profile interrogation
  - `measure_scene`
  - richer terrain-aware validation
- a later bounded local patch helper may become justified, but only after the interrogation and measurement gaps are closed

### Remaining Assumptions

- that profile, slope, and fairness evidence will materially reduce `eval_ruby` usage before any patch helper exists
- that a bounded local patch helper would be sufficient if terrain-edit pressure persists
- that `terrain_patch` should remain a deferred helper surface rather than a semantic-family expansion

## Structured Expansion Plan

### Expansion Outcome

- owning capability: `scene-targeting-and-interrogation` as primary owner, with `scene-validation-and-review` as the main dependent owner for terrain evidence and diagnostics
- new capability needed: `no`; the current evidence supports bounded follow-ons inside existing capabilities rather than a standalone terrain-authoring capability
- new PRD needed: `no`; the signal does not yet justify separate product metrics, workflows, and roadmap ownership for terrain authoring
- planning posture: `patch specs` and `refine tasks`

### Required Specification Edits

#### 1. Terrain Interrogation Follow-On Posture

Target file:

- `specifications/prds/prd-scene-targeting-and-interrogation.md`
- `specifications/hlds/hld-scene-targeting-and-interrogation.md`

Required edits:

- clarify that bounded terrain follow-ons should first deepen explicit host-target interrogation through terrain profiles, sections, and related terrain-aware evidence rather than broadening immediately into terrain editing
- make room for host-only or profile-style surface interrogation as a compact follow-on to `sample_surface_z` without implying a new broad public terrain-authoring subsystem

Purpose:

- anchor the signal under the correct capability and make the intended next terrain-related quick wins explicit

#### 2. Terrain Measurement And Diagnostic Posture

Target file:

- `specifications/prds/prd-scene-validation-and-review.md`
- `specifications/hlds/hld-scene-validation-and-review.md`
- `specifications/tasks/scene-validation-and-review/SVR-03-measure-scene-mvp-with-structured-measurement-modes/task.md`

Required edits:

- preserve the `SVR-03` MVP boundary that terrain-shaped objects are valid generic measurement targets, while terrain profile, slope, clearance-to-terrain, grade-break, trench/hump, and fairness measurements remain deferred follow-ons
- clarify that terrain fairness, trench or hump, and seam-oriented diagnostics are evidence-producing follow-ons for validation rather than implicit terrain-editing commitments
- correct the HLD current-state drift so it no longer claims that `validate_scene_update` is unimplemented

Purpose:

- keep terrain diagnostics in the measurement and validation slice instead of leaking them into semantic creation or unstructured fallback usage

#### 3. Terrain Authoring Boundary Clarification

Target file:

- `specifications/prds/prd-semantic-scene-modeling.md`
- current source-of-truth docs

Required edits:

- clarify that broad terrain authoring still remains `eval_ruby`-first, but that a later bounded local-patch helper remains a possible follow-on if interrogation and validation improvements do not reduce the repeated workflow pressure enough
- align the guide's `terrain_patch` suggestion with the later PRD clarification so the repo records one consistent bounded posture rather than implying a broad Phase 2 commitment

Purpose:

- remove ambiguity about whether the signal is asking for a full terrain-authoring surface now

#### 4. Follow-On Task Planning

Target file:

- `specifications/tasks/scene-targeting-and-interrogation/README.md`
- `specifications/tasks/scene-validation-and-review/README.md`

Required edits:

- add or queue bounded follow-on task shells for terrain profile interrogation and terrain-oriented measurement or validation evidence
- keep any future local patch helper explicitly deferred until after those evidence-producing tasks are better defined

Purpose:

- convert the signal into task-sized planning without prematurely creating a new top-level capability

### Explicit No-Change Decisions

- do not create a new terrain-authoring PRD from this signal
- do not broaden semantic scene modeling into a general terrain-editing capability at this stage
- do not treat Unreal or plugin terrain tooling as a reason to copy large editor-style terrain systems into the current Ruby runtime
- do not treat `terrain_patch` as an approved immediate implementation commitment merely because it exists in the guide

### Planning Order

1. Patch the current PRD and HLD posture so terrain follow-ons are consistently described as interrogation, measurement, validation, and only later possibly bounded local patch helpers.
2. Prioritize the direct evidence surfaces: host-only terrain sampling or profile interrogation plus public `measure_scene`.
3. Broaden terrain-aware validation once measurement and interrogation evidence is available as a reusable source.
4. Reassess whether a bounded local terrain patch helper is still justified after those quicker wins land.

## Actioned Updates

The expansion plan was actioned into the existing specification set without creating a new terrain-authoring PRD.

Updated artifacts:

- `specifications/prds/prd-scene-targeting-and-interrogation.md`
- `specifications/hlds/hld-scene-targeting-and-interrogation.md`
- `specifications/prds/prd-scene-validation-and-review.md`
- `specifications/hlds/hld-scene-validation-and-review.md`
- `specifications/prds/prd-semantic-scene-modeling.md`
- `specifications/tasks/scene-targeting-and-interrogation/README.md`
- `specifications/tasks/scene-targeting-and-interrogation/STI-03-extend-sample-surface-z-with-profile-and-section-sampling/task.md`
- `specifications/tasks/scene-targeting-and-interrogation/STI-03-extend-sample-surface-z-with-profile-and-section-sampling/plan.md`
- `specifications/tasks/scene-validation-and-review/README.md`
- `specifications/tasks/scene-validation-and-review/SVR-04-add-terrain-aware-measurement-evidence/task.md`
- `specifications/tasks/scene-validation-and-review/SVR-04-add-terrain-aware-measurement-evidence/plan.md`
- current source-of-truth docs

What changed:

- targeting/interrogation now names bounded terrain profile or section interrogation as a follow-on to explicit surface sampling
- `STI-03` now defines the bounded `sample_surface_z` profile and section sampling follow-on
- validation/review now reflects the finalized `SVR-03` posture: `measure_scene` is terrain-compatible for generic measurement modes, but terrain profile, slope, clearance-to-terrain, grade-break, trench/hump, and fairness diagnostics remain deferred
- `SVR-04` now reserves terrain-aware measurement evidence as a dependency-gated follow-on after `SVR-03` and `STI-03`, without pre-committing exact mode/kind names
- semantic scene modeling now clarifies that near-term terrain work should deepen interrogation, measurement evidence, validation, and reconciliation before any bounded patch helper is promoted
- current source-of-truth docs no longer treat `terrain_patch` as the immediate next terrain milestone

What remains intentionally unchanged:

- no new terrain-authoring PRD was created
- broad terrain modeling, grading authoring, patch replacement, and fairing remain outside the current public capability commitments
- `SVR-03` remains a bounded generic `measure_scene` MVP rather than a terrain-diagnostic task

Remaining follow-on work:

- complete `SVR-03`, then plan and implement `STI-03` against the settled `sample_surface_z` internals
- refine `SVR-04` mode/kind names only after `SVR-03` and `STI-03` contracts are stable
- define later validation diagnostics for terrain slope, clearance-to-terrain, grade-break, trench/hump, and fairness evidence after measurement evidence proves useful
- reassess bounded local terrain patch helpers only after those evidence-producing surfaces reduce or fail to reduce fallback pressure
