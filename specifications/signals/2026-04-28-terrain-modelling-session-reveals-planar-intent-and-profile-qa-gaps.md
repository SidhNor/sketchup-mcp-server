# Signal: Terrain Modelling Session Reveals Planar Intent And Profile QA Gaps

**Date**: `2026-04-28`
**Source**: MCP terrain modelling session retrospective and user feedback
**Related Signals**:
- [Partial Terrain Authoring Session Reveals A Stable Patch-Oriented Terrain Editing Contract](./2026-04-24-partial-terrain-authoring-session-reveals-stable-patch-editing-contract.md)
**Related PRDs**:
- [Managed Terrain Surface Authoring](../prds/prd-managed-terrain-surface-authoring.md)
- [Scene Targeting and Interrogation](../prds/prd-scene-targeting-and-interrogation.md)
- [Scene Validation and Review](../prds/prd-scene-validation-and-review.md)
**Related HLDs**:
- [Managed Terrain Surface Authoring](../hlds/hld-managed-terrain-surface-authoring.md)
- [Scene Targeting and Interrogation](../hlds/hld-scene-targeting-and-interrogation.md)
- [Scene Validation and Review](../hlds/hld-scene-validation-and-review.md)
**Related Tasks**:
- [MTA-05 Implement Corridor Transition Terrain Kernel](../tasks/managed-terrain-surface-authoring/MTA-05-implement-corridor-transition-terrain-kernel/task.md)
- [MTA-06 Implement Local Terrain Fairing Kernel](../tasks/managed-terrain-surface-authoring/MTA-06-implement-local-terrain-fairing-kernel/task.md)
- [MTA-13 Implement Survey Point Constraint Terrain Edit](../tasks/managed-terrain-surface-authoring/MTA-13-implement-survey-point-constraint-terrain-edit/task.md)
- [MTA-14 Evaluate Base Detail Preserving Survey Correction](../tasks/managed-terrain-surface-authoring/MTA-14-evaluate-base-detail-preserving-survey-correction/task.md)
- [STI-03 Extend Sample Surface Z With Profile and Section Sampling](../tasks/scene-targeting-and-interrogation/STI-03-extend-sample-surface-z-with-profile-and-section-sampling/task.md)
- [SVR-04 Add Terrain-Aware Measurement Evidence](../tasks/scene-validation-and-review/SVR-04-add-terrain-aware-measurement-evidence/task.md)
**Status**: `actioned`
**Disposition**: `actioned through managed terrain PRD/HLD refinements, task shells, and platform guidance follow-on`

## Summary

A recent MCP terrain modelling session exposed a gap between how the current terrain-editing tools behave and how grading intent is naturally expressed.

The core lesson was that the workflow was not primarily about pushing every survey point exactly into the mesh. It was closer to grading design:

- establish a coherent natural base plane
- identify real fall lines and breaklines
- use sparse regional controls to shape broad intent
- verify behavior along profiles, not only at points
- use fairing after the intended terrain logic is correct

The strongest product signal is that `survey_point_constraint` and related terrain tools expose low-level solver behavior more than user-facing surface intent. Documentation can reduce confusion, but the stronger product direction may be to let callers state geometric intent directly.

The latest feedback sharpened that into an authoring recipe:

1. define terrain intent
2. bound the support region
3. protect known-good areas with `preserveZones`
4. inspect solver evidence
5. verify the result with profiles

This signal captures the feedback only. It does not expand the signal, create a technical plan, or decide implementation scope.

## Core Signal

The current terrain surface is capable enough to support useful modelling, but the semantic contract around regional correction is under-specified.

The main expectation mismatch was:

- user intent: regional survey correction sounds like fitting a coherent regional surface to controls
- current behavior: regional correction behaves like a smooth correction field around controls unless enough boundary and intermediate controls force the intended plane

When controls were sparse or non-coplanar, the tool could produce ridges, valleys, bumps, or warped cloth-like patches. The best results came from creating a clean, broad, managed terrain base and then applying small, coherent regional edits.

The current tool descriptions should therefore make solver behavior and guardrails explicit. A successful edit means the command completed and the solver guardrails accepted the result. It does not mean the terrain is visually or geometrically good without profile-based review.

## Terrain Workflow Learnings

The session produced several practical terrain modelling lessons:

- Start with a broad coplanar base, not point fitting.
- Do not force all survey points exactly when the intended surface is planar.
- Check coplanarity before treating a group of survey controls as one coherent patch.
- Use regional constraints with sparse boundary and intermediate controls along intended planar lines.
- Treat fairing as a finishing operation, not as a way to express grade intent.
- Account for coarse grid spacing and interpolation when sampling readbacks near off-grid controls.
- Separate control types earlier: natural-ground controls, built-surface or pad controls, inferred-coordinate controls, and helper or intermediate line controls.
- Use survey constraints to express grade intent, then use fairing only for final texture or residual roughness.
- Avoid using uncertain or context-only levels as terrain controls.

The most reliable pattern was:

1. create or reset to a clean managed terrain
2. establish a broad base plane or coherent fall
3. apply regional controls only after checking whether they are coplanar
4. sample profiles before making further edits
5. fair residual roughness after the directional logic is correct

For each visible defect, the best practical edit recipe was:

1. name the defect, such as valley, bump, crossfall, or edge sag
2. sample a profile through it
3. decide the intended profile
4. apply a narrow managed edit
5. preserve adjacent known-good zones
6. verify the same profile plus nearby diagonals
7. undo immediately if the correction steals from a control point

## Preserve-Zone Signal

The later terrain passes showed that `preserveZones` are essential terrain-authoring guardrails, not optional polish.

The west patch worked because the edit region and preserve zones were cleanly separated:

- edit only the outside buffer
- preserve the exact plot boundary
- preserve a narrow strip just inside the plot
- verify the result with cross profiles

That pattern should be documented as the recommended recipe for an outside patch while maintaining an existing boundary.

The tool descriptions should guide callers toward this posture:

- use `preserveZones` as the primary way to protect already-good terrain during local and regional edits
- when a survey correction is near a boundary or known-good profile, add preserve zones outside the intended support area
- prefer preserve zones over fixed controls when the goal is to keep a region untouched rather than pin a small number of exact points
- inspect preserve-zone drift after every edit that is close to protected terrain

## Grid-Spacing Signal

The session also exposed a representational limit in the coarse heightmap model.

With 3 m spacing, close contradictory controls can be impossible to represent independently. The `RL-030` / `RL-028` and `RL-017` / southwest bump cases showed the same limit: if two desired features are inside one grid cell's influence, the solver may refuse the edit or move both nearby samples.

The documentation should make these grid effects explicit:

- terrain spacing limits the spatial detail that can be represented
- constraints closer than one grid cell can interact strongly
- local edits may move a shared grid vertex and affect nearby points
- close points with sharp height differences may be refused or may distort nearby samples
- if close points must both be honored, recreate or refine with smaller spacing, or accept relaxed targets

This is especially important because the tool can internally satisfy a constraint while later mesh or ray sampling still reads slightly differently.

## Profile Sampling Signal

The session made a clear distinction between point sampling and profile sampling:

> Point samples verify controls; profile samples verify terrain shape.

Single-point samples and solver satisfaction reports were useful for checking whether specific controls were hit. They did not reveal terrain behavior between controls.

Profile sampling exposed the problems that mattered visually and geometrically:

- a valley between `RL-018` and `RL-028`
- a high bow between `RL-019` and `RL-018`
- an artificial bump south of `RL-027`
- cross-fall coherence or loss of west-to-east fall
- whether the north-south site slope still looked believable

This suggests the documentation and examples for `sample_surface_z` and `measure_scene terrain_profile/elevation_summary` should make profile sampling feel like the normal QA path for terrain grading, not an optional advanced variant.

Profile sampling should be expected after:

- regional edits
- edge or boundary edits
- smoothing and fairing
- corrections near tight point clusters
- any edit meant to remove bumps, valleys, or crossfall

The `RL-025` to `RL-029` valley was an important example: it was not obvious as a single-point problem, but it became clear in a profile. The effective fix came from converting that profile into a simple intended grade line.

## Post-Edit Review Signal

The session repeatedly showed that edit acceptance needs review evidence beyond command success.

Critical post-edit review fields include:

- `changedRegion`
- `maxSampleDelta`
- `slopeMaxIncrease`
- `curvatureMaxIncrease`
- preserve-zone drift

The reliable review pattern was:

1. inspect `changedRegion`
2. check preserve-zone drift
3. sample profiles through the edited area
4. sample nearby diagonals
5. reject or undo if the correction moved a control point or created a new nearby bump

Tool descriptions should call these out as mandatory review evidence for non-trivial local or regional terrain edits.

## Tool Behavior Pain Points

The feedback identified these tool-use pain points:

- `survey_point_constraint` behavior was under-specified.
- Two survey points were easy to misread as defining a plane, but they behaved more like local attractors.
- `regional` sounded more planar than it is.
- Regional correction did not obviously mean smooth correction field unless the user had already learned the solver behavior.
- Safety refusal diagnostics were hard to interpret before the regional correction safety fix, especially around absolute versus normalized residual thresholds.
- Boundary semantics were surprising when points exactly on max terrain bounds were rejected as outside bounds.
- The coordinate frame for created and adopted terrain was not explicit enough.
- Constraint satisfaction and mesh sampling appeared inconsistent when stored terrain-state evaluation passed but `sample_surface_z` readbacks differed slightly.
- `local_fairing` behavior with fixed controls was not obvious.
- The distinction between `fixedControls` and `preserveZones` needs clearer guidance.
- `corridor_transition` can visually create a plane but may be the wrong semantic tool for general planar surface fitting.
- `target_height` examples do not yet communicate the common "point with radius and blend" mental model.
- Refusals need more actionable explanations, especially when grid spacing, tight control clusters, preserve-zone conflicts, or safety thresholds drive refusal.
- Built levels such as house, slab, well, and platform levels can be useful context or verification points, but should not drive natural terrain unless the workflow is explicitly modelling pads, cuts, or built surfaces.
- `RL-030` was not only a height-control issue; its XY uncertainty meant it could create wrong corrections if treated as a hard terrain control before position confirmation.

## Documentation Gaps

The biggest documentation gap is not request shape. It is terrain-edit semantics: what geometric behavior should a caller expect from each operation?

Useful documentation additions suggested by the session:

- an operation intent table:
  - `survey_point_constraint`: satisfy measured points through a smooth correction field
  - `target_height`: impose a pad or local area elevation
  - `corridor_transition`: create a linear path, ramp, or corridor grade
  - `local_fairing`: smooth existing terrain without target height
- an explicit note that regional survey constraints do not imply planar fitting
- examples for:
  - four-corner planar patches
  - best-fit plane patches
  - monotonic edge fall using intermediate controls
  - preserving controls while fairing
  - staged correction after creating a broad base plane
  - outside patch editing while preserving a real boundary and a narrow inside strip
  - point-with-radius local `target_height` edits with blend
- field definitions for terrain evidence such as `surveyResidualRange`, `supportFootprintLength`, `normalizedSurveyResidualRange`, `slopeProxy`, `curvatureProxy`, `detailPreservation.outsideInfluenceRatio`, and `changedBounds`
- explicit review guidance for `changedRegion`, `maxSampleDelta`, `slopeMaxIncrease`, `curvatureMaxIncrease`, and preserve-zone drift
- a warning that sample evidence is grid-sample evidence, not necessarily exact survey point evidence
- coarse-grid guidance for controls between grid vertices and expected readback differences from `sample_surface_z`
- clear documentation for whether preview or dry-run mode exists; if not, state that it is unsupported
- a stronger statement that managed terrain descriptions should guide edit recipes, not only list parameters

## Candidate Capability Pressures

The session suggested several possible future capabilities. These are captured as pressure signals, not accepted scope:

- managed fit planar patch from controls
- plane and coplanarity helper in the terrain API
- monotonic profile constraint
- bounded breakline or edge-fall edit
- residual diagnostics for each control
- profile roughness, bump, valley, and curvature-spike detector
- weighted regional controls
- preview-only terrain edit mode that predicts grid changes, max delta, curvature, and residuals before commit
- `planar_region_fit`: fit a region to a plane from three or more controls
- `remove_crossfall`: flatten one axis while preserving another boundary
- `boundary_preserving_patch_edit`: explicit mode for outside patches that must preserve a known-good boundary

The user-facing direction implied by the feedback is that callers should express terrain intent, not reverse-engineer solver mechanics.

Possible future semantic modes named during the session:

- `regional_smooth_field`
- `regional_best_fit_plane`
- `regional_piecewise_planar`
- `regional_monotonic_profile`
- `regional_exact_points_min_curvature`

These names are provisional signal material only.

## What This Signal Directly Supports

This signal directly supports improving terrain-tool discoverability and documentation around:

- `survey_point_constraint` regional behavior
- `sample_surface_z` profile usage
- `measure_scene terrain_profile/elevation_summary`
- fixed controls versus preserve zones
- regional correction safety diagnostics
- terrain coordinate frames and coarse-grid readback caveats
- post-edit review fields and refusal explanations
- recipes for boundary-preserving outside patch edits

It also supports using profile sampling earlier in terrain QA workflows.

## What This Signal Suggests But Does Not Yet Prove

This signal suggests that future terrain editing may need explicit geometric-intent modes beyond the current regional correction behavior.

It does not yet prove:

- that `survey_point_constraint` should change default behavior
- that best-fit plane mode belongs inside the existing operation rather than a new operation
- that monotonic profile constraints can be implemented safely in the current heightmap model
- that weighted controls are the right public abstraction
- that profile diagnostics should live in `measure_scene`, `validate_scene_update`, or a future terrain-specific review tool

## Follow-On Question Preserved By This Signal

Should managed terrain authoring add explicit surface-intent modes, starting with best-fit planar patches and monotonic profile QA, so callers can express grading intent directly instead of learning the current regional correction solver behavior through trial and error?

## Structured Expansion Plan

### Expansion Outcome

- owning capability: `Managed Terrain Surface Authoring`
- new capability needed: `no`; the signal refines bounded managed terrain edit semantics rather than introducing a separate product slice
- new PRD needed: `no`; the current Managed Terrain Surface Authoring PRD already owns bounded edits, preserve zones, evidence, and honest refusals
- planning posture: `patch specs, refine discoverable tool contracts, and create follow-on tasks inside existing capability boundaries`

The expansion conclusion is that managed terrain authoring needs an intent-and-QA sub-slice. The immediate gap is not mainly missing runtime evidence. The runtime already reports fields such as `changedRegion`, `maxSampleDelta`, preserve-zone drift, regional coherence, slope and curvature proxies, and detail-preservation evidence. The immediate gap is that solver semantics, guardrails, and edit recipes are not discoverable enough through the public MCP contract.

Because this server currently exposes MCP tools with descriptions and schemas, but does not expose MCP prompts or resources, baseline-safe semantics must be present in the discoverable tool definitions. MCP prompts or resources should still be evaluated as a quick-win platform follow-on for richer reusable recipes, but they must not replace concise tool-level safety and usage semantics.

### Required Specification Edits

#### 1. Managed terrain PRD refinement

Target file:

- `specifications/prds/prd-managed-terrain-surface-authoring.md`

Required edits:

- Add intent-aware terrain correction to the managed terrain authoring problem and requirements language.
- Clarify that regional survey correction is a smooth correction field unless an explicit future planar mode is added.
- Add profile sampling as the expected review path after non-trivial regional, boundary, fairing, tight-control, bump, valley, or crossfall edits.
- Add grid-spacing and tight-control representational limits to requirements, constraints, or risks.
- Add a discoverability requirement: tool descriptions and schemas must expose baseline-safe terrain edit semantics, not only parameter shapes.

Purpose:

- Keep product requirements aligned with the observed workflow: define terrain intent, bound the support region, protect known-good areas with `preserveZones`, inspect solver evidence, and verify with profiles.

#### 2. Managed terrain HLD clarification

Target file:

- `specifications/hlds/hld-managed-terrain-surface-authoring.md`

Required edits:

- Clarify that explicit terrain surface-intent modes, if added, belong in the terrain edit engine and terrain region/constraint model.
- Clarify that profile sampling remains owned by scene targeting and interrogation, while profile interpretation or acceptance remains owned by scene validation and review.
- Clarify that terrain evidence should remain coordinate, region, sample-index, and metric based rather than leaking solver internals or generated mesh identifiers.
- Add the MCP discoverability posture at the runtime boundary: tool descriptions and field descriptions must carry critical terrain safety semantics when no MCP prompt/resource surface is available.

Purpose:

- Keep future planar, monotonic, and boundary-preserving work inside existing terrain architecture without moving validation, sampling, or client orchestration into the edit engine.

#### 3. Public MCP tool discoverability hardening

Target files:

- `src/su_mcp/runtime/native/mcp_runtime_loader.rb`
- `docs/mcp-tool-reference.md`
- `test/runtime/native/mcp_runtime_loader_test.rb`

Required edits:

- Treat this as a P0 contract/discoverability task, not a docs-only cleanup.
- Update `edit_terrain_surface` descriptions to include an operation-intent table or equivalent concise contrastive guidance.
- Document `survey_point_constraint` with `correctionScope: regional` as a smooth correction field, not best-fit planar behavior.
- Make `preserveZones` the primary discoverable mechanism for protecting known-good terrain during local and regional edits.
- Surface grid-spacing limits and close-control interactions in field or operation descriptions where callers decide whether to proceed.
- Call out required post-edit review evidence: `changedRegion`, `maxSampleDelta`, `slopeMaxIncrease`, `curvatureMaxIncrease`, preserve-zone drift, and survey residuals.
- Update `sample_surface_z` and `measure_scene` descriptions to state that point samples verify controls while profile samples verify terrain shape.
- Keep examples micro-sized in tool/schema descriptions; place richer recipes in docs until MCP prompts/resources exist.
- Add or update runtime loader tests so discoverable descriptions preserve the critical semantics.

Purpose:

- Make a generic MCP client able to discover the right tool, avoid the most dangerous terrain misuse, and interpret terrain edit results without relying on client-specific prompt stuffing.

#### 4. Follow-on managed terrain task refinement

Target files:

- `specifications/tasks/managed-terrain-surface-authoring/README.md`
- new or refined task artifact under `specifications/tasks/managed-terrain-surface-authoring/`

Required edits:

- Add a P0 follow-on task for terrain edit semantic documentation and discoverability.
- Add a P1 follow-on task or planning shell for planar region fit feasibility and possible implementation under `edit_terrain_surface`.
- Add a P2 follow-on task or cross-capability planning note for profile QA, monotonic grade-line diagnostics, or bump/valley detection.
- Keep `boundary_preserving_patch_edit` provisional. First verify whether current `regional` correction plus `preserveZones` and better recipes are sufficient before adding a separate mode.

Purpose:

- Convert the signal into task-sized work while preserving the distinction between immediate discoverability hardening and future solver capability.

#### 5. MCP prompts/resources quick-win follow-up

Target files:

- `specifications/hlds/hld-platform-architecture-and-repo-structure.md`
- possible new platform task under `specifications/tasks/platform/`

Required edits:

- Record that the current runtime exposes tools with descriptions and schemas but does not expose MCP prompts/resources.
- Evaluate whether exposing MCP prompts or resources is a low-effort server-side quick win for richer recipes such as preserve-zone outside-patch editing, staged terrain correction, and profile QA playbooks.
- Keep the dependency direction explicit: prompts/resources may improve reuse and consistency, but core usage semantics still belong in discoverable tool definitions.

Purpose:

- Provide a server-accessible home for richer examples and workflow playbooks without bloating every tool description.

### Explicit No-Change Decisions

- Do not create a new top-level terrain intent PRD; this belongs inside Managed Terrain Surface Authoring.
- Do not create a new public tool for planar fitting by default; first evaluate it as an `edit_terrain_surface` operation or nested intent mode.
- Do not treat `survey_point_constraint` regional behavior as planar fitting without an explicit contract change.
- Do not move profile sampling ownership into terrain authoring; `sample_surface_z` and `measure_scene terrain_profile/elevation_summary` remain the evidence path.
- Do not treat `boundary_preserving_patch_edit` as accepted scope yet; current `regional` correction plus `preserveZones` may be sufficient with better recipes.
- Do not rely on MCP prompts/resources for baseline safety semantics; tool definitions must remain sufficient for generic clients.

### Planning Order

1. Patch the managed terrain PRD to capture intent-aware correction, profile QA, grid-spacing guardrails, and discoverable-contract expectations.
2. Patch the managed terrain HLD only where architecture boundaries need clarification.
3. Create the P0 discoverability task for `edit_terrain_surface`, `sample_surface_z`, and `measure_scene` tool-description/schema hardening.
4. Implement an initial MCP prompts surface as a quick platform follow-on for richer recipes and reusable playbooks.
5. Plan planar region fit as a separate P1 narrow implementation task under the existing terrain edit surface.
6. Defer monotonic profile diagnostics and bump/valley detection until the validation/review ownership path is explicit.

## Actioned Updates

### Updated Artifacts

- `specifications/prds/prd-managed-terrain-surface-authoring.md`: added intent-aware correction, profile QA, grid-spacing limits, and discoverable MCP contract expectations.
- `specifications/hlds/hld-managed-terrain-surface-authoring.md`: clarified that future terrain intent modes belong in the terrain domain, while profile sampling and validation interpretation stay in their owning slices.
- `specifications/hlds/hld-platform-architecture-and-repo-structure.md`: recorded that the runtime currently exposes tools/descriptions/schemas but not MCP prompts/resources, and added prompts/resources as an open platform question.
- `specifications/guidelines/mcp-tool-authoring-sketchup.md`: added guidance for splitting baseline-safe tool semantics, MCP prompts/resources, server docs, and client-only orchestration.
- `specifications/tasks/managed-terrain-surface-authoring/README.md`: added follow-on MTA tasks and notes.
- `specifications/tasks/platform/README.md`: added the initial MCP prompts guidance task.

### Created Task Shells

- `specifications/tasks/managed-terrain-surface-authoring/MTA-15-harden-terrain-edit-contract-discoverability/task.md`
- `specifications/tasks/managed-terrain-surface-authoring/MTA-16-implement-narrow-planar-region-fit-terrain-intent/task.md`
- `specifications/tasks/managed-terrain-surface-authoring/MTA-17-define-profile-qa-and-monotonic-terrain-diagnostics/task.md`
- `specifications/tasks/platform/PLAT-18-implement-initial-mcp-prompts-guidance-surface/task.md`

### Intentional Non-Changes

- No runtime tool descriptions or schemas were changed by this signal actioning pass; that work is now captured in `MTA-15`.
- Narrow planar terrain intent was accepted as implementation scope during task planning; `MTA-16` handles that separately from regional survey correction.
- No profile validation or monotonic edit constraint was accepted as implementation scope; `MTA-17` defines ownership first.
- No MCP prompts runtime support was implemented during signal actioning; `PLAT-18` implements the initial prompts surface.
