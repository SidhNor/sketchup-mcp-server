---
doc_type: prd
title: Managed Terrain Surface Authoring
status: draft
last_updated: 2026-04-30
---

# PRD: Managed Terrain Surface Authoring

## Problem statement

Terrain-aware SketchUp MCP workflows can currently inspect, sample, measure, and validate relationships to terrain, but they cannot safely author terrain as a first-class managed surface.

When a workflow needs to reshape ground, it falls back to `eval_ruby`. Those fallback scripts tend to modify the live triangulated terrain mesh directly by dragging vertices, cutting faces, intersecting temporary planes, deleting fragments, or trying to repair topology in place. For TIN-style terrain, that is fragile. It produces loose edges, holes, harsh triangulation artifacts, unintended drift outside the edit area, unstable references, and repeated manual reset loops.

The product needs a managed terrain-authoring capability that lets users adopt existing SketchUp terrain, apply bounded terrain edits, preserve controls and protected areas, and review terrain-edit evidence without treating live TIN surgery as the normal authoring path.

Recent terrain modelling feedback sharpened the authoring need beyond raw terrain mutation. Agents need the terrain edit surface to expose the intended geometric behavior of each operation: when an operation creates a smooth correction field, when it expresses a corridor grade, when it only fairs local roughness, and when planar or monotonic intent is not currently supported. Without that discoverable intent layer, a technically successful edit can still create a valley, ridge, crossfall error, or boundary drift that only appears after profile sampling.

This product slice is separate from semantic hardscape creation. Existing `path`, `pad`, and `retaining_edge` objects are Managed Scene Objects that may relate to terrain, but they are not part of terrain source state.

## Goals

1. Make recurring terrain-authoring workflows possible without `eval_ruby`.
2. Let users adopt existing SketchUp terrain as a Managed Terrain Surface with stable workflow identity.
3. Enable bounded terrain edits that avoid manual TIN cleanup and preserve intended terrain controls.
4. Support fixed controls, preserve zones, grade regions, and blend zones as first-class terrain-authoring concepts.
5. Return structured terrain-edit evidence that downstream validation and review workflows can use.
6. Keep semantic hardscape objects such as paths, pads, and retaining edges separate from terrain state.
7. Make operation intent, solver guardrails, and post-edit QA expectations discoverable through the public MCP contract.
8. Support bounded SketchUp-facing visual controls for managed terrain edits where visual region selection and parameter adjustment are faster than MCP-only trial-and-error.

## Success Metrics & KPI

| Metric | Baseline | Target | Measurement Method | Timeline |
| --- | --- | --- | --- | --- |
| Core terrain-authoring scenarios completed without `eval_ruby` | Current recurring terrain-authoring workflows fall back to `eval_ruby` | >= 80% of representative adopted-terrain, local grading, ramp or transition, and smoothing scenarios | Scenario suite based on the April 24 terrain-authoring signal and future curated terrain fixtures | Within first managed terrain authoring release cycle |
| Supported terrain edits requiring no manual TIN cleanup | Current fallback scripts often leave topology or visual artifacts that require manual reset or repair | >= 90% of supported terrain-edit scenarios | Scenario audit for loose edges, holes, obvious drift outside the edit area, and manual cleanup steps | Within first managed terrain authoring release cycle |
| Supported terrain edits preserving fixed controls and preserve zones | No first-class support for control or preserve-zone preservation during terrain modification | >= 95% pass within documented tolerance | Before/after sample and constraint checks over curated fixed-control and preserve-zone scenarios | Within first managed terrain authoring release cycle |
| Supported terrain edits returning usable before/after evidence | Current before/after terrain sampling is manual and inconsistent | >= 90% of supported terrain-edit workflows | Contract and scenario checks for structured before/after samples, changed-area evidence, and relevant warnings | Within first managed terrain authoring release cycle |
| Curated topology and fairness defect cases surfaced before acceptance | Current defect detection is visual, manual, and incomplete | >= 80% of curated defect cases surfaced through terrain evidence or downstream validation | Shared terrain defect scenario set covering holes, seam defects, slope spikes, humps, trenches, and abrupt transitions | Within two releases after managed terrain authoring MVP |
| Terrain edit intent and QA guidance discoverable in MCP contract | Current tool descriptions expose shape better than terrain-edit semantics | Representative generic MCP client can distinguish correction-field, corridor, target-height, and fairing intents without external prompt stuffing | Runtime tool schema/description review plus docs parity checks | Before adding further terrain edit modes |

**Primary KPI**

- Core terrain-authoring scenarios completed without `eval_ruby`

**Secondary KPI**

- Supported terrain edits requiring no manual TIN cleanup
- Supported terrain edits preserving fixed controls and preserve zones
- Supported terrain edits returning usable before/after evidence
- Curated topology and fairness defect cases surfaced before acceptance

## Target Users

- AI agents executing structured site, garden, and landscape terrain workflows
- Designers and operators adjusting existing SketchUp terrain around paths, thresholds, lawns, terraces, trees, and service areas
- Technical reviewers checking whether terrain edits preserve controls, avoid topology damage, and remain plausible
- Developers replacing repeated fallback Ruby terrain scripts with stable product behavior

## User Flows & Scenarios

### Flow 1: Adopt Existing Terrain

1. The user or agent identifies an existing SketchUp terrain surface that should become managed terrain.
2. The system adopts the source surface as a Managed Terrain Surface with stable workflow identity.
3. The system records enough source and reference information for later targeting, evidence, and validation.
4. The resulting terrain can be targeted by later managed terrain-authoring workflows.

### Flow 2: Apply A Bounded Grade Edit

1. The user or agent selects a Managed Terrain Surface.
2. The user defines a bounded grade region, fixed controls, preserve zones, and intended terrain outcome.
3. The system applies the supported terrain edit without requiring direct manual TIN cleanup.
4. The system returns structured evidence describing the changed area, preserved controls, and before/after terrain behavior.
5. The user or downstream validation workflow uses the evidence to accept, revise, or inspect the result.

### Flow 3: Create A Ramp Or Transition

1. The user or agent defines a corridor or transition area between terrain conditions.
2. The user supplies the relevant controls, constraints, and blend expectations.
3. The system applies a controlled terrain transition while respecting fixed controls and preserve zones.
4. The system returns evidence that helps identify unacceptable humps, trenches, slope spikes, or abrupt transitions.

### Flow 4: Smooth Or Fair A Local Terrain Region

1. The user or agent identifies a bounded terrain region with bumps, rough transitions, harsh triangulation artifacts, or local slope spikes.
2. The user defines preserve zones and fixed controls that must not drift.
3. The system improves the local terrain condition while preserving required controls.
4. The system returns before/after evidence and warnings when the result still needs review.

### Flow 5: Review Terrain Edit Evidence

1. A terrain edit completes and returns structured evidence.
2. The user, agent, or validation workflow reviews changed-region, sampling, control-preservation, and defect evidence.
3. The workflow accepts the result, performs another terrain edit, or requests further validation or visual review.
4. Review remains evidence-driven; command completion alone is not treated as correctness.

### Flow 6: Apply Intent-Aware Terrain Corrections

1. The user or agent names the visible terrain defect or intent, such as valley, bump, edge sag, crossfall, planar fall, or boundary-protected outside patch.
2. The user or agent chooses the supported terrain operation whose documented semantics match that intent.
3. The system refuses unsupported intent clearly instead of implying that regional correction is planar fitting or that fairing can express grade logic.
4. The edit result includes enough evidence to inspect changed region, survey residuals, preserve-zone drift, slope or curvature proxy changes, and maximum sample movement.
5. The user or downstream workflow samples profiles through the edited area and nearby diagonals before accepting the terrain shape.

### Flow 7: Apply A Bounded Visual Terrain Edit

1. The SketchUp user selects a Managed Terrain Surface and activates a bounded visual terrain edit control.
2. The user visually identifies a local support area, shoulder, plane, or fairing region and adjusts bounded parameters such as support size, blend distance, or operation mode.
3. The system previews or communicates the intended managed edit without treating raw mesh dragging as source state.
4. The user applies the edit as a managed terrain mutation that updates terrain state, regenerates derived output, and returns the same kind of structured evidence as command-driven edits.
5. The user, agent, or validation workflow uses MCP sampling, profile checks, labels, redrape, and capture workflows to validate and preserve the accepted result.

## Functional Requirements

| Requirement | User Story | Acceptance Criteria | Priority |
| --- | --- | --- | --- |
| Support adoption of existing SketchUp terrain as a Managed Terrain Surface | As an agent, I want to adopt existing terrain into a managed terrain object so that future terrain edits can target stable terrain identity instead of arbitrary mesh fragments | Given a supported source terrain target, the product can create a Managed Terrain Surface with stable workflow identity, source reference information, and structured success or refusal output | P0 |
| Preserve source terrain identity and reference information after adoption | As a workflow orchestrator, I want adopted terrain to remain targetable and auditable so that later edits and validation can refer to the same terrain object | Adopted terrain exposes stable workflow-facing identifiers and enough source/reference summary data for later targeting, evidence, and validation workflows | P0 |
| Support bounded terrain grade edits | As a user, I want to modify a bounded terrain area so that local grading can be performed without broad uncontrolled mesh changes | A supported grade edit can be applied to a bounded terrain region and returns structured evidence of affected area, preserved controls, and before/after behavior | P0 |
| Support fixed controls for terrain edits | As a designer or agent, I want terrain edits to preserve specified controls so that roads, boundaries, thresholds, or other anchors do not drift unexpectedly | Supported terrain edits can include fixed controls, and the result reports whether those controls remained within documented tolerance | P0 |
| Support preserve zones for terrain edits | As a designer or agent, I want terrain edits to protect areas such as retained trees or sensitive zones so that grading does not bleed into places that must remain stable | Supported terrain edits can include preserve zones, and the result reports whether protected areas remained within documented tolerance or returned a structured refusal or warning | P0 |
| Support blend zones between edited and unchanged terrain | As a user, I want terrain changes to transition plausibly into surrounding ground so that flat bands, humps, trenches, and abrupt edges are reduced | Supported terrain edits can express transition expectations and return evidence or warnings when blend quality remains questionable | P0 |
| Support ramp or transition terrain workflows | As a designer or agent, I want to create controlled terrain transitions between conditions so that access routes, thresholds, and grade changes do not require manual TIN editing | Supported terrain-transition workflows can be completed from explicit controls and constraints, return structured evidence, and avoid manual topology repair in representative cases | P0 |
| Support local smoothing or fairing workflows | As a designer or reviewer, I want to improve local terrain roughness and abrupt transitions so that terrain remains plausible after grade edits or adoption | Supported smoothing or fairing workflows can act on a bounded region, respect fixed controls and preserve zones, and return before/after evidence and warnings | P1 |
| Return terrain-edit evidence for downstream validation and review | As a reviewer or downstream agent, I want terrain edit results to include structured evidence so that acceptance is not inferred from command completion alone | Supported terrain edits return structured evidence such as changed-area summary, before/after samples, preserved-control results, warnings, and defect indicators where available | P0 |
| Make terrain operation intent discoverable | As an agent, I want each terrain edit mode to state its geometric behavior so that I do not infer planar, monotonic, or boundary-preserving semantics from a generic mode name | Public tool descriptions, field descriptions, and reference docs distinguish target-height, corridor, fairing, and survey correction behavior, including that regional survey correction is a smooth correction field unless an explicit planar mode exists | P0 |
| Support profile-based terrain QA guidance | As a reviewer, I want terrain workflows to treat profile samples as the normal way to verify shape between controls so that point satisfaction does not hide bumps, valleys, or crossfall errors | Public guidance and task acceptance criteria require profile checks after non-trivial regional edits, boundary edits, smoothing/fairing, tight control clusters, and bump/valley/crossfall corrections | P0 |
| Surface heightmap spacing limits | As an agent, I want tight or contradictory control sets to report representational limits so that I can refine terrain spacing or relax targets instead of repeatedly issuing impossible edits | Supported terrain edit documentation and refusals explain when grid spacing, shared sample influence, or close controls make independent constraints unsafe or impossible | P0 |
| Surface topology and fairness concerns as structured warnings or evidence | As a technical reviewer, I want topology or fairness concerns to be visible before acceptance so that terrain failures do not depend only on manual inspection | Representative terrain defect scenarios such as holes, loose edges, seam defects, slope spikes, humps, trenches, or abrupt transitions produce structured warnings, evidence, or downstream validation findings | P1 |
| Keep semantic hardscape objects separate from terrain state | As a workflow author, I want paths, pads, and retaining edges to remain independent managed objects so that terrain editing does not silently absorb or corrupt hardscape semantics | Terrain authoring does not create, absorb, or mutate `path`, `pad`, or `retaining_edge` managed-object state as part of terrain source state; any use of those objects as references or constraints remains explicit and non-destructive | P0 |
| Support terrain edits that can reference existing managed objects as constraints where product rules allow | As an agent, I want to use existing scene objects as controls or preserve references so that terrain edits can respect the modeled context without changing those objects | Supported terrain edits can reference eligible existing objects as controls or constraints and return structured refusal when a referenced object cannot safely be used for that purpose | P1 |
| Support bounded visual terrain edit controls | As a SketchUp user, I want to select local terrain regions and adjust bounded terrain-edit parameters visually so that small shoulders and local grading corrections can be made faster than MCP-only trial-and-error | A bounded visual control can target a Managed Terrain Surface, collect or preview a supported managed edit, apply it through terrain state and command boundaries, and expose structured evidence or refusal results for later review | P1 |
| Preserve undo-safe terrain edit behavior | As a SketchUp user, I want terrain edits to behave as coherent undoable actions so that failed or undesired edits do not require manual scene cleanup | Supported terrain-authoring mutations appear as one coherent SketchUp undo step where practical, and failures do not leave partial product-managed terrain state as the expected outcome | P0 |
| Refuse unsupported or unsafe terrain requests clearly | As an agent, I want unsupported terrain edits to fail explicitly so that the workflow does not fall back to unsafe mesh mutation | Unsupported source surfaces, ambiguous targets, unsafe constraints, or out-of-scope edit intents return structured refusals with actionable reason data rather than silently proceeding | P0 |

Domain alignment: Managed Terrain Surface is represented in [`domain-analysis.md`](../domain-analysis.md) as a terrain-specific Managed Scene Object concept. No functional requirements conflict with current hardscape rules as long as `path`, `pad`, and `retaining_edge` remain separate Managed Scene Objects and are not absorbed into terrain state.

## Non Functional Requirements

- Terrain-authoring behavior must be deterministic for the same terrain state, edit intent, and constraints.
- Terrain-authoring outputs must remain JSON-serializable and must not expose raw SketchUp objects.
- Terrain edit results must be concise by default while including enough evidence for downstream validation and review.
- Supported terrain edits should complete quickly enough for iterative design workflows on representative site models.
- Terrain requests must refuse ambiguous or unsafe inputs rather than guessing silently.
- Terrain authoring must remain compatible with existing scene targeting, interrogation, semantic modeling, and validation workflows.
- Discoverable MCP tool definitions must expose baseline-safe operation semantics, guardrails, and output expectations; richer examples may live in docs or future MCP prompts/resources.
- SketchUp-facing visual controls should improve selection, preview, and parameter adjustment ergonomics while preserving managed terrain state, evidence, refusals, and undo semantics.

## Constraints

- SketchUp remains the execution environment and source of scene truth.
- Terrain authoring must use workflow-facing identity conventions, preferring `sourceElementId`, supporting `persistentId` where useful, and treating `entityId` as compatibility-only.
- Semantic hardscape elements such as `path`, `pad`, and `retaining_edge` remain outside terrain source state.
- Existing terrain interrogation and validation capabilities remain separate slices; terrain authoring consumes or produces evidence for them rather than redefining all targeting or validation behavior.
- Terrain mutation must not depend on `eval_ruby` as the normal path for supported workflows.
- Undo-safe mutation behavior is required for supported terrain authoring workflows where SketchUp supports it.
- Visual terrain edit UI must act as a controller over managed terrain commands, state, and evidence rather than creating an independent terrain source of truth.
- Current `heightmap_grid` spacing limits the spatial detail that can be represented. Tight point clusters or contradictory controls inside one grid cell may need structured refusal, smaller spacing, localized detail, or relaxed targets.
- Built levels such as slabs, platforms, wells, or house floors are verification context unless the request explicitly models pads, cuts, or built-surface terrain effects.

## Out of Scope

- Creating or modifying semantic hardscape objects such as paths, pads, retaining edges, decks, or platform-like pads
- Making `path`, `pad`, or `retaining_edge` part of terrain source state
- Public Unreal-style terrain tools such as flatten, smooth, or ramp as separate MCP tool commitments
- Treating regional survey correction as implicit planar fitting before an explicit planar contract is designed
- Treating fairing as a grade-intent operation rather than a finishing/smoothing operation
- Broad freeform sculpting, continuous stroke replay, pressure-sensitive brush systems, or mouse-driven raw TIN editing outside managed terrain state
- Erosion, weathering, procedural terrain generation, or broad terrain simulation
- General-purpose mesh repair or unrestricted TIN surgery
- Photorealistic terrain rendering or material-authoring workflows
- Replacing scene targeting, surface interrogation, measurement, or validation product slices

## Opened Questions

- What minimum metadata should define a Managed Terrain Surface?
- What lifecycle states should exist for source terrain, adopted managed terrain, and edited terrain?
- Should adopted terrain retain a separate source reference for reset or comparison, or is SketchUp undo sufficient for first release recovery?
- Which terrain evidence categories should be owned by terrain authoring versus the scene validation and review slice?
- Which terrain defect categories are required for MVP: holes, loose edges, seam quality, slope spikes, humps, trenches, or abrupt curvature?
- Which existing managed object types may be referenced as fixed controls or preserve constraints in the first release?
- How should terrain edits report possible impacts on terrain-dependent hardscape without mutating that hardscape state?
- What tolerance defaults should govern fixed controls, preserve zones, and before/after terrain evidence?
- Should planar region fitting be added as a new `edit_terrain_surface` operation or as an explicit nested intent under survey correction?
- Which profile diagnostics belong in scene validation and review rather than terrain mutation?
- Should MCP prompts/resources be exposed so richer server-owned terrain recipes can be discovered without bloating tool descriptions?
- Which SketchUp UI mechanism should first host bounded visual terrain edits: native tool, toolbar/menu command, HtmlDialog, or a hybrid?

## Risks and Mitigation

| Risk | Likelihood | Impact | Mitigation Strategy |
| --- | --- | --- | --- |
| Terrain authoring becomes a broad sculpting system rather than a bounded managed workflow | Medium | High | Keep first release scope centered on adoption, bounded edits, controls, preserve zones, evidence, and refusals |
| Bounded visual terrain controls bypass managed state and evidence | Medium | High | Require UI-authored edits to apply through managed terrain commands or equivalent use-case boundaries and return structured evidence/refusals |
| Terrain authoring reintroduces direct live-TIN mutation under a new name | Medium | High | Measure manual cleanup rates, require structured evidence, and make unsafe requests refuse rather than proceed silently |
| Hardscape semantics blur into terrain state | Medium | High | Keep `path`, `pad`, and `retaining_edge` as separate Managed Scene Objects and require any use as terrain constraints to be explicit and non-destructive |
| Terrain evidence duplicates validation and interrogation responsibilities | Medium | Medium | Treat terrain authoring as producer of terrain-edit evidence and depend on targeting/interrogation and validation slices for shared lookup and acceptance semantics |
| Fairness and visual plausibility are too subjective to validate consistently | High | Medium | Use curated defect cases and measurable proxies such as slope spikes, humps, trenches, seam quality, and before/after samples |
| Tool descriptions teach parameter shape but not terrain-edit semantics | High | High | Treat discoverable tool descriptions and field descriptions as part of the public contract, and verify them against runtime behavior and docs |
| Regional correction is mistaken for planar fitting | High | Medium | Explicitly document regional correction as a smooth correction field and add a separate planar-fit task before changing behavior |
| Coarse grid spacing creates misleading control expectations | Medium | Medium | Document spacing limits, refuse impossible tight-control sets clearly, and use localized detail or finer spacing as escalation paths |
| Existing SketchUp terrain sources vary too widely for reliable adoption | Medium | High | Define supported source-surface expectations, return structured refusals for unsupported cases, and track adoption failure reasons |
| Users still prefer `eval_ruby` for complex terrain work | Medium | Medium | Keep first-class scope focused on the repeated workflows that caused the strongest fallback pressure and track unsupported-request patterns |

## Dependencies

- [`domain-analysis.md`](../domain-analysis.md)
- [`prd-scene-targeting-and-interrogation.md`](./prd-scene-targeting-and-interrogation.md)
- [`prd-scene-validation-and-review.md`](./prd-scene-validation-and-review.md)
- [`prd-semantic-scene-modeling.md`](./prd-semantic-scene-modeling.md)
- [`../signals/2026-04-24-partial-terrain-authoring-session-reveals-stable-patch-editing-contract.md`](../signals/2026-04-24-partial-terrain-authoring-session-reveals-stable-patch-editing-contract.md)
- [`../signals/2026-04-28-terrain-modelling-session-reveals-planar-intent-and-profile-qa-gaps.md`](../signals/2026-04-28-terrain-modelling-session-reveals-planar-intent-and-profile-qa-gaps.md)
- Shared workflow identity conventions for `sourceElementId`, `persistentId`, and compatibility `entityId`
- Existing explicit surface sampling and terrain profile evidence capabilities
- Existing Managed Scene Object boundaries for hardscape and semantic site elements

## Revision History

| Date | Change |
| --- | --- |
| 2026-04-24 | Initial draft created for managed terrain adoption and bounded terrain authoring after reviewing the terrain guide, current terrain-adjacent product slices, and the April 24 terrain-authoring signal. |
| 2026-04-25 | Updated domain-alignment language after Managed Terrain Surface was added to the shared domain analysis. |
| 2026-04-28 | Added intent-aware terrain correction, profile QA, grid-spacing guardrails, and discoverable MCP contract expectations from the April 28 terrain modelling signal expansion. |
| 2026-04-30 | Added bounded SketchUp-facing visual edit controls as an in-scope managed terrain interaction surface after the terrain session showed MCP-only trial-and-error is too indirect for visual grading. |
