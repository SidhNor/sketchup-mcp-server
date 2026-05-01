# Signal: Terrain Session Exposes Local Detail, Hardscape, Sampling, And Identity Gaps

**Date**: `2026-04-30`
**Source**: Session retrospective and user feedback after terrain, hardscape, and validation work
**Related Signals**:
- [Terrain Modelling Session Reveals Planar Intent And Profile QA Gaps](./2026-04-28-terrain-modelling-session-reveals-planar-intent-and-profile-qa-gaps.md)
- [Partial Terrain Authoring Session Reveals A Stable Patch-Oriented Terrain Editing Contract](./2026-04-24-partial-terrain-authoring-session-reveals-stable-patch-editing-contract.md)
**Related PRDs**:
- [Managed Terrain Surface Authoring](../prds/prd-managed-terrain-surface-authoring.md)
- [Semantic Scene Modeling](../prds/prd-semantic-scene-modeling.md)
- [Scene Targeting and Interrogation](../prds/prd-scene-targeting-and-interrogation.md)
- [Scene Validation and Review](../prds/prd-scene-validation-and-review.md)
**Related HLDs**:
- [Managed Terrain Surface Authoring](../hlds/hld-managed-terrain-surface-authoring.md)
- [Semantic Scene Modeling](../hlds/hld-semantic-scene-modeling.md)
- [Scene Targeting and Interrogation](../hlds/hld-scene-targeting-and-interrogation.md)
- [Scene Validation and Review](../hlds/hld-scene-validation-and-review.md)
**Related Tasks**:
- [MTA-11 Migrate To Dense Tiled Heightfield V2 With Adaptive Output](../tasks/managed-terrain-surface-authoring/MTA-11-design-and-implement-durable-localized-terrain-representation-v2/task.md)
- [MTA-15 Harden Terrain Edit Contract Discoverability](../tasks/managed-terrain-surface-authoring/MTA-15-harden-terrain-edit-contract-discoverability/task.md)
- [MTA-16 Implement Narrow Planar Region Fit Terrain Intent](../tasks/managed-terrain-surface-authoring/MTA-16-implement-narrow-planar-region-fit-terrain-intent/task.md)
- [MTA-17 Define Profile QA And Monotonic Terrain Diagnostics](../tasks/managed-terrain-surface-authoring/MTA-17-define-profile-qa-and-monotonic-terrain-diagnostics/task.md)
- [MTA-18 Define Bounded Managed Terrain Visual Edit UI](../tasks/managed-terrain-surface-authoring/MTA-18-define-bounded-managed-terrain-visual-edit-ui/task.md)
- [SEM-11 Align Managed-Object Maintenance Surface](../tasks/semantic-scene-modeling/SEM-11-align-managed-object-maintenance-surface/task.md)
- [SEM-13 Realize Horizontal Cross-Section Terrain Drape for Paths](../tasks/semantic-scene-modeling/SEM-13-realize-horizontal-cross-section-terrain-drape-for-paths/task.md)
- [STI-03 Extend Sample Surface Z With Profile and Section Sampling](../tasks/scene-targeting-and-interrogation/STI-03-extend-sample-surface-z-with-profile-and-section-sampling/task.md)
- [SVR-04 Add Terrain-Aware Measurement Evidence](../tasks/scene-validation-and-review/SVR-04-add-terrain-aware-measurement-evidence/task.md)
**Status**: `actioned`
**Disposition**: `actioned for bounded managed terrain visual edit UI; earlier representation/hardscape/sampling findings remain expanded but not fully actioned`

## Summary

A terrain and hardscape correction session exposed several remaining gaps after the earlier managed terrain work:

- the current uniform heightmap can be too coarse for narrow features
- terrain drape behavior is not a substitute for true built-surface slab levels
- off-grid survey controls remain fragile even when the intended mathematical surface is correct
- managed replacement preserves workflow semantics but not necessarily SketchUp persistent IDs
- sampling results depend strongly on target choice and visibility
- adjacent terrain, hardscape, hosting, and validation corrections can stale each other

The strongest new pressure is that the current terrain representation may not be sufficient for narrow hardscape-adjacent grading work. This is related to `MTA-11`, but this capture does not plan or implement `MTA-11`.

## Captured Feedback

Main issues from the session:

- The 3 m terrain grid is too coarse for narrow features. The south-workshop strip is about 1.75 m wide, so terrain edits affected only a couple of grid samples and spread changes too far. That caused over-lift near the house.
- Managed path creation cannot model true sloped built slabs. The path tool supports flat elevation or terrain drape. It ignored 3D centerline Z values, so `HARD-006` could not be properly sloped through managed tools alone.
- Terrain draping is not a substitute for built hardscape levels. Drape is appropriate for terrain-following paths, but concrete slabs with surveyed top levels should not require forcing the terrain underneath to simulate the slab.
- Off-grid survey controls are fragile. Many `RL-*` points sit between heightmap samples. Even when a mathematical plane is correct, the discrete surface may fail residual checks or require larger bounds than visually appropriate.
- `replace_preserve_identity` preserves semantic intent but not persistent IDs. Managed replacements often minted new persistent IDs. Follow-up work must use new persistent IDs or stable `sourceElementId`, not old persistent IDs.
- Sampling can mislead depending on target and visibility. `sample_surface_z` missed points when using visible scene sampling under structures or slabs. Direct terrain-owner sampling was more reliable for terrain, while top-surface checks need separate geometry sampling.
- Some corrections were initially treated as per-object Z fixes when they were really terrain or survey-basis problems. Structure seating, extension level, path drape, and terrain controls interact; fixing one semantic element can make adjacent draped elements stale.

What could have been better:

- Before narrow terrain edits, check grid spacing against feature width. If feature width is less than two grid cells, warn first.
- Prefer stable `sourceElementId` tracking after managed replacements because persistent IDs change, or explicitly decide whether persistent IDs need a stronger preservation mechanism.
- Re-drape terrain-hosted paths immediately after terrain corrections in their area.

Lessons not obvious from tool descriptions:

- "Managed" does not necessarily mean identity-stable at the persistent ID level.
- A successful managed terrain edit can still be visually wrong if grid spacing is larger than the feature being modeled.
- `planar_region_fit` is good for broad grade intent, not narrow slab strips.
- `surface_drape` paths inherit terrain imperfections and should be used only for terrain-following paths, not surveyed concrete planes.
- Validation must be semantic plus geometric: tags and materials can pass while elevation intent is still wrong.
- The model needs a finer terrain representation before continuing small hardscape or threshold detail resolution.
- Recreating the whole terrain at smaller uniform spacing is not a free workaround, but it may still be manageable for some model sizes. Moving from a 3 m grid to a 1 m grid would increase grid patches by roughly 9x over the same area.

## Initial Capture Triage

This feedback appears to strengthen the case for planning `MTA-11`, because it identifies a concrete representation failure: a 3 m uniform grid cannot faithfully support a roughly 1.75 m hardscape-adjacent strip without excessive spillover. That is stronger evidence than a general desire for finer terrain.

It also shows why global re-gridding is a real tradeoff rather than an automatic answer. A smaller uniform grid may improve narrow-feature fidelity and might be acceptable for some terrains, but the area-based patch count grows quadratically as spacing shrinks. Local detail zones or another localized representation may still be preferable when only a few narrow areas need the extra fidelity.

This feedback also points to smaller possible improvements that may not require `MTA-11`:

- add or strengthen discoverable warnings when edit support width is less than two terrain grid cells
- document that `surface_drape` is terrain-following path geometry, not surveyed slab or built hardscape plane modeling
- clarify that `replace_preserve_identity` preserves workflow identity through `sourceElementId`, not SketchUp persistent ID continuity
- make sampling guidance distinguish terrain-owner sampling from visible/top-surface geometry sampling
- consider a terrain-dependent object staleness note after terrain edits, especially for draped paths

These are capture notes only. They do not update task scope, priorities, plans, docs, or runtime behavior. The later supplemental UI expansion below actions a separate bounded visual-edit finding from the same session; it does not action all representation, hardscape, identity, or sampling findings in this initial capture.

## Initial Expansion Boundary Decisions

These decisions apply to the initial representation, hardscape, identity, and sampling expansion. They are superseded only for the bounded visual terrain UI action recorded later in this signal.

- Do not mark the initial representation/hardscape/sampling expansion `actioned`.
- Do not create tasks as part of the initial representation/hardscape/sampling expansion.
- Do not modify `MTA-11`, `MTA-15`, `MTA-16`, `SEM-*`, `STI-*`, or `SVR-*` artifacts as part of the initial representation/hardscape/sampling expansion.
- Do not treat built slabs as terrain source state.
- Do not infer that `surface_drape` should become surveyed slab modeling without separate semantic hardscape planning.

## Structured Expansion Plan

### Expansion Outcome

- owning capability: `Managed Terrain Surface Authoring`
- adjacent capabilities: `Semantic Scene Modeling`, `Scene Targeting and Interrogation`, and `Scene Validation and Review`
- new capability needed: `no`; the core pressure fits existing managed terrain representation, hardscape semantics, sampling, and validation boundaries
- new PRD needed: `no`; current PRDs already separate terrain state, semantic hardscape, sampling, and validation responsibilities
- tasks created: `none`
- planning posture: `evaluate existing-task refinement and small contract/docs hardening later; do not action downstream artifacts in this pass`

### Context Baseline

The signal directly observes a practical representational failure: a roughly 1.75 m hardscape-adjacent strip was smaller than the current 3 m terrain grid spacing, so terrain edits had too few samples to localize the change and produced spillover near the house.

The signal also observes adjacent workflow problems:

- `surface_drape` worked as terrain-following path behavior, but not as surveyed sloped concrete slab behavior.
- off-grid `RL-*` controls are fragile against a discrete heightmap even when the intended mathematical plane is valid.
- `replace_preserve_identity` preserves workflow identity through metadata but does not guarantee SketchUp persistent ID continuity.
- terrain-owner sampling, visible-scene sampling, and top-surface geometry sampling answer different questions.
- terrain corrections can make existing draped or terrain-hosted objects stale.

Current source artifacts already cover some of this:

- `MTA-11` was the existing localized survey/detail-zone escalation path for cases where `heightmap_grid` v1 fidelity is insufficient. As of the May 1 task update, it has been refocused toward dense tiled heightfield v2 plus adaptive output.
- `MTA-16` already records that `planar_region_fit` can refuse discrete heightmap cases that cannot sample accepted controls back within tolerance.
- `MTA-15` already hardened terrain operation intent, grid-spacing caveats, preserve-zone guidance, and point/profile QA descriptions.
- `SEM-13` defines `surface_drape` as terrain-following path geometry, not terrain mutation or hardscape slab modeling.
- Domain analysis already says `sourceElementId` is the primary workflow identity and `persistentId` is supported where useful.

The remaining gap is not one single missing tool. It is a planning decision about when coarse uniform terrain state is still acceptable, when a globally finer grid is acceptable, and when localized detail is worth the extra representation complexity.

### Evidence Classification

Strong evidence:

- Feature width below terrain grid spacing can create visually wrong terrain changes even when the managed edit succeeds.
- Uniform grid refinement has a quadratic cost with spacing reduction; 3 m to 1 m means roughly 9x more patches over the same area.
- Built hardscape levels should not be simulated by forcing terrain underneath when the intended object is a surveyed slab or concrete plane.
- Persistent ID continuity is not guaranteed by current managed replacement behavior.

Moderate inference:

- `MTA-11` planning is warranted because the session provides concrete evidence for representation pressure, not just a speculative desire for finer terrain.
- The earlier localized-detail-vs-global-refinement decision has been superseded by the dense tiled heightfield v2 plus adaptive output posture.
- A smaller set of contract/docs improvements may reduce repeated misuse even before representation work.

Remaining assumptions:

- The actual model size, patch count, regeneration time, file size impact, and interactive performance at 1 m spacing have not been measured.
- It is not yet proven which first adaptive output simplification tolerance and tile/window sizing will balance face count, fidelity, and hosted SketchUp performance.
- It is not yet decided whether sloped built slabs belong in an existing semantic hardscape type, a new semantic hardscape mode, or improved docs/refusals only.
- It is not yet decided whether persistent ID continuity should be a product guarantee or whether `sourceElementId` guidance is sufficient.

### Potential Specification Edits If Actioned Later

#### 1. Managed terrain representation decision point

Target file:

- `specifications/tasks/managed-terrain-surface-authoring/MTA-11-design-and-implement-durable-localized-terrain-representation-v2/task.md`

Potential edits:

- Refine `MTA-11` planning around dense tiled heightfield v2, one-way migration, uniform edit windows, and first adaptive SketchUp output generation.
- Add a decision gate for tile sizing, source resolution, simplification tolerance, output regeneration cost, file size, and hosted interaction cost.
- Include the south-workshop strip as an example of feature-width pressure where a 3 m grid undersamples a narrow area.

Purpose:

- Keep `MTA-11` grounded in a real fidelity-vs-cost tradeoff instead of assuming dense source state or adaptive output settings are automatically acceptable at all model sizes.

#### 2. Terrain edit guardrail discoverability

Target files:

- `docs/mcp-tool-reference.md`
- `src/su_mcp/runtime/native/native_tool_catalog.rb`

Potential edits:

- State that terrain edits on features narrower than about two grid cells are high risk and should trigger warning or review behavior where available.
- Clarify that successful terrain edit completion does not prove narrow-feature visual correctness.

Purpose:

- Reduce repeated misuse of broad terrain edits for sub-grid features.

#### 3. Semantic hardscape surface posture

Target files:

- `specifications/prds/prd-semantic-scene-modeling.md`
- `specifications/hlds/hld-semantic-scene-modeling.md`
- `docs/mcp-tool-reference.md`

Potential edits:

- Clarify that `surface_drape` is for terrain-following paths.
- Clarify that surveyed sloped built slabs are not represented by `surface_drape` and should not require terrain distortion to fake top levels.
- Evaluate whether existing `path` or `pad` semantics need an explicit future built-surface slope posture.

Purpose:

- Keep hardscape authoring separate from terrain state while preserving the user need for surveyed built slab levels.

#### 4. Identity and replacement guidance

Target files:

- `docs/mcp-tool-reference.md`
- `specifications/domain-analysis.md`

Potential edits:

- Clarify that `replace_preserve_identity` preserves workflow identity and semantic intent, not necessarily SketchUp persistent ID continuity.
- Recommend `sourceElementId` for follow-up targeting after managed replacements unless the latest returned `persistentId` is explicitly used.
- Separately evaluate whether persistent ID continuity is feasible or desirable as a stronger guarantee.

Purpose:

- Prevent follow-up operations from targeting stale persistent IDs after managed replacement.

#### 5. Sampling target guidance

Target files:

- `docs/mcp-tool-reference.md`
- `specifications/prds/prd-scene-targeting-and-interrogation.md`

Potential edits:

- Distinguish terrain-owner sampling from visible-scene or top-surface geometry sampling.
- Clarify that terrain verification and built-slab top verification may require different explicit targets.

Purpose:

- Avoid treating one `sample_surface_z` result as authoritative for both terrain and hardscape top-surface checks.

### Explicit No-Change Decisions

- Do not create a new top-level capability.
- Do not create tasks during the initial representation/hardscape/sampling expansion.
- Do not action `MTA-11` yet.
- Do not assume a 1 m global grid is impractical without measuring representative terrain size and performance.
- Do not preserve localized detail zones as the current implementation direction after the dense tiled heightfield v2 task update.
- Do not redefine `planar_region_fit` as a narrow slab-strip tool.
- Do not redefine `surface_drape` as surveyed hardscape slab modeling.
- Do not make generated terrain mesh geometry the source of truth.
- Do not move profile or top-surface sampling ownership into terrain mutation.
- Do not make persistent ID preservation a product guarantee without a separate feasibility and compatibility check.

### Planning Order

1. Benchmark or estimate representative uniform grid refinement cost, especially 3 m to 1 m patch count, output regeneration time, model size, and hosted interaction behavior.
2. Reassess `MTA-11` through task planning around dense tiled heightfield v2, uniform edit windows, and first adaptive output generation.
3. If actioning is desired later, refine existing artifacts rather than creating new tasks by default.
4. Separately evaluate hardscape built-surface slope semantics; keep that out of terrain representation planning unless the request explicitly models cuts, pads, or terrain effects.
5. Patch docs or runtime descriptions only if the team wants immediate low-risk guidance improvements before representation work.

## Supplemental Expansion: Bounded Visual Terrain Editing

### Additional Context

Follow-up user feedback reframed the terrain pain as an interaction problem, not only a representation or MCP contract problem:

- terrain tools are too indirect for visual grading because the workflow requires inferring bounds and controls, applying an edit, sampling, and reacting
- the managed MCP contract is semantically safe but clumsy for small corrections because every adjustment needs explicit bounds, controls, preserve zones, tolerances, and validation
- 1 m grid spacing still constrains tight shoulder and concrete-strip edits when the support area is small
- point constraints were overused when the actual user intent was planar or visual grading
- the managed semantic layer is good for durable capture and validation, but weak as the primary sketching interface for terrain feel

The better workflow indicated by the feedback is:

1. Use direct SketchUp UI tools for visual terrain shaping where the job is to make a shoulder or local terrain read correctly.
2. Use MCP tools afterward to sample, validate, label, redrape, and capture the accepted managed state.
3. Keep managed terrain edits as the durable path for clearly bounded, survey-driven corrections.
4. Avoid live trial-and-error through MCP for fine terrain sculpting unless target plane and bounds are explicit.

### Supplemental Expansion Outcome

- owning capability: `Managed Terrain Surface Authoring`
- adjacent capabilities: `Scene Targeting and Interrogation`, `Scene Validation and Review`, `Semantic Scene Modeling`, and platform extension UI/menu wiring
- new capability needed: `no`; the work fits managed terrain as a bounded SketchUp-facing interaction surface over the existing terrain state and command model
- new PRD needed: `no`; the Managed Terrain Surface Authoring PRD needs a scope patch rather than a separate PRD
- tasks created: `MTA-18 Define Bounded Managed Terrain Visual Edit UI`
- planning posture: `patch PRD/HLD scope language and add a bounded UI task shell; preserve the no broad sculpting/no raw TIN surgery decisions`

### Context Baseline

Current artifacts already support terrain adoption, bounded edits, terrain state storage, derived output regeneration, edit evidence, and explicit MCP contracts. The live runtime has terrain edit modes for target height, corridor transition, local fairing, survey point correction, and planar region fit, routed through `TerrainSurfaceCommands`.

Current artifacts do not support a direct SketchUp terrain-editing UI. The extension menu currently focuses on MCP server control and Ruby console access. The Managed Terrain Surface Authoring PRD and HLD also explicitly excluded interactive sculpting, brush UI, and mouse-driven terrain editing. That exclusion is too broad if the desired surface is a bounded visual controller over managed terrain edits rather than an unrestricted sculpting system.

The source-of-truth and hardscape boundaries still hold:

- terrain state remains authoritative; generated SketchUp mesh remains derived output
- semantic hardscape remains separate from terrain state
- MCP remains the best layer for sampling, validation, labeling, redrape orchestration, and durable capture
- direct UI should not bypass managed terrain storage, evidence, refusals, or undo semantics

### Evidence Classification

Strong evidence:

- fine terrain feel is slow through MCP-only trial-and-error
- visual shoulder and local grading adjustments require faster feedback than numeric request/response loops provide
- current managed terrain internals already define bounded edit modes that a UI could parameterize and invoke
- current PRD/HLD scope language conflicts with any bounded visual terrain UI, so the conflict must be resolved before implementation planning

Moderate inference:

- a bounded SketchUp UI over existing managed terrain commands is the lowest-risk way to improve terrain feel without creating a second terrain runtime
- brush size/support-radius configuration and visual bounds selection are likely the first valuable controls
- direct preview or hover feedback may be needed for ergonomic use, but durable apply should still go through managed edit commands

Remaining assumptions:

- it is not yet proven which UI mechanism should be first: `Sketchup::Tool`, `UI::HtmlDialog`, toolbar commands, or a hybrid
- it is not yet proven that current full or partial regeneration latency is acceptable for visual interaction
- brush/stroke replay, continuous sculpting, and live drag preview may exceed the safe first slice
- MTA-11 dense tiled heightfield v2 may still be needed for tight terrain detail even if UI improves interaction speed

### Required Specification Edits

#### 1. Managed terrain product scope

Target file:

- `specifications/prds/prd-managed-terrain-surface-authoring.md`

Required edits:

- Add a bounded visual terrain edit flow that lets a SketchUp user select or preview local regions visually, configure support size or operation parameters, apply managed edits, and review evidence afterward.
- Add a P1 requirement for bounded visual terrain controls that reuse managed terrain state and do not bypass validation or evidence.
- Replace the broad out-of-scope ban on interactive terrain UI with a narrower ban on broad freeform sculpting, stroke replay, and unrestricted mouse-driven TIN surgery.

Purpose:

- Resolve the product-scope conflict while preserving the managed authoring boundary.

#### 2. Managed terrain architecture posture

Target file:

- `specifications/hlds/hld-managed-terrain-surface-authoring.md`

Required edits:

- Add bounded SketchUp terrain UI controls as in-scope architecture when they act as controllers over managed terrain commands and state.
- Add a UI/controller boundary that owns interaction, preview, and parameter collection but not terrain math, storage, validation policy, or raw TIN mutation.
- Keep broad sculpting and direct live-TIN editing out of scope.

Purpose:

- Ensure a UI implementation lands in the extension runtime without creating a second terrain model or bypassing command/use-case boundaries.

#### 3. Bounded UI task shell

Target file:

- `specifications/tasks/managed-terrain-surface-authoring/MTA-18-define-bounded-managed-terrain-visual-edit-ui/task.md`

Required edits:

- Create a draft task for defining the first bounded managed terrain visual edit UI slice.
- Scope it to visual selection/configuration/application of existing managed terrain edit modes, evidence review handoff, and safe undo/refusal behavior.
- Exclude broad freeform sculpting, direct TIN surgery, and replacement of MCP validation/sampling workflows.

Purpose:

- Convert the signal into a concrete planning artifact without prematurely implementing UI code.

### Explicit No-Change Decisions

- Do not create a new top-level product capability or PRD.
- Do not make UI-authored geometry or generated mesh faces the terrain source of truth.
- Do not redefine `edit_terrain_surface` public MCP behavior as a live sculpting protocol.
- Do not absorb `path`, `pad`, or `retaining_edge` into terrain state.
- Do not use direct UI as a substitute for MCP sampling, validation, identity capture, or redrape workflows.
- Do not treat `MTA-18` as a replacement for `MTA-11`; UI improves interaction speed, while dense heightfield representation still governs achievable local detail.

### Planning Order

1. Patch PRD and HLD scope language to permit bounded visual terrain controls while preserving managed-state boundaries.
2. Create `MTA-18` as a draft task for the first bounded UI slice.
3. Plan `MTA-18` separately before code changes, including UI mechanism selection, preview/apply semantics, latency checks, and evidence handoff.
4. Continue to evaluate `MTA-11` for representation fidelity where UI alone cannot solve grid-spacing artifacts.
5. Keep hardscape built-surface slope semantics separate unless a later semantic hardscape task explicitly models them.

### Actioned Updates

- Updated `specifications/prds/prd-managed-terrain-surface-authoring.md` to include bounded managed terrain visual edit controls and narrow the out-of-scope language.
- Updated `specifications/hlds/hld-managed-terrain-surface-authoring.md` to add a SketchUp terrain UI controller boundary over managed terrain commands.
- Created `specifications/tasks/managed-terrain-surface-authoring/MTA-18-define-bounded-managed-terrain-visual-edit-ui/task.md`.
- Updated `specifications/tasks/managed-terrain-surface-authoring/README.md` to include `MTA-18` and move broad sculpting, not bounded visual controls, into deferred/out-of-scope posture.

Remaining follow-on work:

- `MTA-18` still needs technical planning before implementation.
- `MTA-11` remains the representation-fidelity follow-on through dense tiled heightfield v2 and adaptive output.
- Semantic hardscape built-surface slope posture remains separate from this signal action.
