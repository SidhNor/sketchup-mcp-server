---
doc_type: prd
title: Scene Targeting and Interrogation
status: draft
last_updated: 2026-04-24
---

# PRD: Scene Targeting and Interrogation

## Problem statement

Site, garden, and landscape workflows depend on more than object creation. Agents and operators also need a reliable way to identify the right scene targets, understand how existing geometry behaves in world space, and determine whether linework or surfaces are suitable for downstream modeling actions.

Today, targeting and interrogation are too weak and too implicit. That creates several product problems:

- agents fall back to broad scene inspection or arbitrary Ruby when they cannot target the intended object confidently
- terrain-aware placement and reprojection checks become brittle because workflows cannot reliably sample the intended surface
- projected boundaries, draped paths, and retaining edges are hard to validate because visual coincidence is mistaken for usable topology
- later modeling and validation steps inherit ambiguity from poor scene targeting

The product needs a compact, structured targeting and interrogation layer that makes existing scene state legible before creation, mutation, or validation happens.

## Goals

1. Provide a reliable product surface for identifying and targeting the correct scene objects and workflow collections.
2. Support terrain-aware, reprojection-aware, and geometry-aware workflows through structured surface interrogation.
3. Detect topology issues in edge networks before they propagate into modeling or validation failures.
4. Reduce the need for arbitrary Ruby and manual scene probing during inspection-heavy workflows.
5. Make targeting and interrogation outputs stable enough for downstream modeling, asset reuse, and validation flows.

## Success Metrics & KPI

| Metric | Baseline | Target | Measurement Method | Timeline |
| --- | --- | --- | --- | --- |
| Targeted scene lookups that resolve the intended entity or collection on the first query | No formal targeting baseline; current workflows rely on broad inspection and manual interpretation | >= 90% of representative targeting scenarios | Scenario replay using known `sourceElementId`, `persistentId`, collection, and metadata queries | Within first targeting MVP release cycle |
| Terrain-aware placement and reprojection-check workflows completed without arbitrary Ruby or manual probing | No formal baseline; current terrain-aware probing is ad hoc | >= 80% of representative workflows | Workflow scenario suite measuring tool usage during terrain-aware placement and reprojection-check tasks | Within first targeting MVP release cycle |
| Surface sampling requests that return an unambiguous intended hit or structured ambiguity/miss result | No stable surface-sampling contract today | >= 95% of requests return a structured outcome | Contract tests and scenario replay across targeted terrain and surface samples | Within first targeting MVP release cycle |
| Representative topology defects caught before downstream modeling acceptance | No topology-analysis benchmark today | >= 80% of representative defect cases caught | Curated edge-network scenarios with expected loose ends, disconnected segments, and coincident-but-unmerged endpoints | Within two releases after targeting MVP launch |
| Median time to diagnose why a placement or reprojection targeted the wrong geometry | Current diagnosis time to be measured during discovery | >= 50% reduction from measured baseline | Timed troubleshooting scenarios with and without structured targeting/interrogation outputs | Within two releases after targeting MVP launch |

**Primary KPI**

- Targeted scene lookups that resolve the intended entity or collection on the first query

**Secondary KPI**

- Terrain-aware placement and reprojection-check workflows completed without arbitrary Ruby or manual probing
- Surface sampling requests that return an unambiguous intended hit or structured ambiguity/miss result
- Representative topology defects caught before downstream modeling acceptance
- Median time to diagnose why a placement or reprojection targeted the wrong geometry

## Target Users

- AI agents executing structured site, garden, and landscape workflows
- Designers and operators inspecting scene state before edits or placements
- Technical reviewers diagnosing terrain, boundary, and connectivity issues
- Developers building reliable higher-level workflows on top of SketchUp MCP

## User Flows & Scenarios

### Flow 1: Target an existing object for revision

1. The user or agent needs to update a previously modeled object or workflow collection.
2. The system inspects the scene and queries by `sourceElementId`, `persistentId`, name, tag, collection, or metadata.
3. The system returns structured match results and placement summaries for the intended targets.
4. The agent uses that result to revise, replace, validate, or preserve the correct scene object.

### Flow 2: Sample terrain for a placement decision

1. The user or agent needs to place or align an object against existing terrain or another explicit surface.
2. The system samples one or more XY points against a targeted surface.
3. The system returns sampled coordinates plus structured hit, miss, or ambiguity information.
4. The placement workflow uses the result to proceed, adjust, or reject the action.

### Flow 3: Check a projected boundary or edge network

1. The user or agent needs to confirm whether projected or reprojected linework is usable for path, grading, retaining-edge, or boundary workflows.
2. The system samples or rechecks the relevant target surface and analyzes the target edge network for connectivity and topology issues.
3. The system returns a structured summary of sampled surface behavior, disconnected components, loose ends, and coincident-but-unmerged endpoints.
4. The workflow corrects the geometry, blocks downstream actions, or passes the result to validation once the network is usable.

## Functional Requirements

| Requirement | User Story | Acceptance Criteria | Priority |
| --- | --- | --- | --- |
| Support structured scene inspection through `get_scene_info`, `list_entities`, and `get_entity_info` | As an agent, I want a compact view of current scene state so I can identify what should be targeted next | Given a valid scene, each inspection tool returns structured, JSON-serializable scene or entity data with stable fields and no raw SketchUp objects | P1 |
| Support workflow-aware targeting through `find_entities` | As an agent, I want to target objects by workflow identity instead of manual geometry guessing so that I can reliably act on the intended scene object | `find_entities` accepts supported query criteria including ids, `persistentId`, names, tags, collections, materials, and metadata, and returns structured match results with both runtime and stable identifiers when available | P0 |
| Support placement and fit interrogation through `get_bounds` | As an operator, I want structured bounds and placement summaries so that I can confirm size, origin, and footprint before downstream actions | `get_bounds` returns bounding box, dimensions, centroid, origin, and placement summary data for supported targets in a structured response | P1 |
| Support workflow collection discovery through `get_named_collections` | As an agent, I want to discover workflow-relevant collections so that I can target the right scene area without scene-wide guessing | `get_named_collections` returns collection names or ids, member counts, metadata summaries, and child-structure summaries for workflow-relevant collections | P1 |
| Prefer workflow-facing identity conventions in targeting flows | As a workflow orchestrator, I want queries to favor business identity so that targeting remains stable across revisions | Targeting flows prefer `sourceElementId`, support `persistentId` for runtime-safe lookup, and only rely on `entityId` as a compatibility path rather than the primary workflow identity | P0 |
| Support explicit surface interrogation through `sample_surface_z` | As an agent, I want to sample explicitly targeted geometry so that terrain-aware placement and reprojection are reliable | `sample_surface_z` accepts an explicit target plus a canonical sampling request for XY point batches or ordered profiles, supports optional ignore references, and returns structured sampled coordinates and hit-status data, including miss or ambiguity when the intended surface cannot be resolved confidently | P0 |
| Support bounded terrain profile and section interrogation as a follow-on to explicit surface sampling | As a reviewer or agent, I want sampled terrain profiles and sections against a named host so that terrain-aware placement, grading review, and later validation evidence do not require arbitrary Ruby | Terrain profile and section requests build on explicit target surface sampling, return sampled evidence and uncertainty states, and do not modify terrain or imply broad terrain-authoring support | P1 |
| Support topology analysis through `analyze_edge_network` | As a reviewer or agent, I want to know whether linework is structurally connected so that I can trust it for downstream modeling and validation | `analyze_edge_network` returns a structured summary including component count, loose ends, isolated segments, coincident-but-unmerged endpoints, and related topology findings for supported edge-network targets | P0 |
| Support projection-aware interrogation results without requiring a dedicated workflow-specific public tool for each geometry pattern | As a workflow developer, I want targeting and interrogation outputs that can feed projected-boundary and named-reference verification flows so that reprojection checks stay compact and composable | The targeting and interrogation surface returns structured surface-sample and topology outputs that are sufficient inputs for higher-level validation or workflow logic covering projected boundaries, named anchors, and similar reference-driven checks | P1 |
| Ensure interrogation results are compact by default but sufficient for downstream automation | As an MCP client, I want responses that are easy to consume programmatically without excess payload or free-form interpretation | Inspection, targeting, and interrogation responses remain structured, concise by default, and expandable only where documented | P1 |
| Ensure scene targeting and interrogation can be used before creation, mutation, asset placement, and validation workflows | As a product owner, I want this slice to enable other workflows instead of behaving like a narrow debugging feature | The targeting and interrogation surface supports baseline modeling, revision, asset placement, and validation preparation workflows without requiring a separate manual inspection step outside the product surface | P0 |

Conflict flag: no functional requirements currently conflict with the business rules in [`domain-analysis.md`](../domain-analysis.md); the current domain model already reflects this capability as a standalone slice and supports the refined projection-aware interrogation scope.

## Non Functional Requirements

- Tool contracts must remain compact enough for reliable model use in multi-step workflows.
- Targeting and interrogation behavior must be deterministic for the same input and scene state.
- Responses must remain fully JSON-serializable and usable without text scraping.
- Surface interrogation and topology analysis should perform acceptably on representative SketchUp scenes used for iterative design work.
- The product should return structured miss and ambiguity states instead of forcing clients to infer uncertainty from missing fields.

## Constraints

- SketchUp remains the execution environment and source of scene truth for targeting and interrogation.
- The product must not depend on arbitrary Ruby as the normal path for inspection-heavy workflows.
- Surface interrogation must target explicit geometry rather than behaving like an unconstrained generic raytest.
- The tool surface should stay compact and avoid proliferating many narrow inspection tools with overlapping purpose.
- Outputs must remain compatible with downstream semantic modeling, asset reuse, and validation workflows.

## Out of Scope

- Full terrain editing or grading-authoring workflows
- Terrain patch replacement, terrain sculpting, terrain fairing, or working-copy commit/discard workflows; those remain outside this interrogation slice unless a later bounded mutation capability is explicitly defined
- General-purpose CAD diagnostics beyond the targeted interrogation and topology scope
- Full scene-repair automation for broken linework
- Specialized debugging micro-tools for every geometry investigation pattern, such as neighborhood probing or nearest-feature lookup, unless a broader recurring product need is demonstrated
- Replacing semantic modeling, asset reuse, or validation product slices
- Making low-level runtime identifiers the primary workflow-facing identity model

## Open Questions

- Which ambiguity cases in `find_entities` should block downstream workflows by default versus return ranked or grouped matches?
- What tolerance rules should govern surface-hit ambiguity and coincident-but-unmerged endpoint detection?
- Should `get_named_collections` expose only canonical workflow collections or also custom collections that satisfy product rules?
- How much detail should `sample_surface_z` expose by default about hit chains before payload size becomes counterproductive?
- Should topology analysis be allowed to gate downstream semantic creation automatically, or only return findings for higher-level workflows to decide on?
- Should recurring projected-boundary or named-reference verification patterns remain composed from interrogation plus validation, or eventually justify a higher-level helper once repeated workflows stabilize?
- Which terrain profile and section sampling patterns are broad enough to add as interrogation follow-ons without becoming terrain-editing or terrain-diagnostic validation tools?

## Risks and Mitigation

| Risk | Likelihood | Impact | Mitigation Strategy |
| --- | --- | --- | --- |
| Targeting results are too ambiguous for reliable automation | Medium | High | Prefer business identity and persistent identifiers, return structured ambiguity states, and keep query semantics explicit |
| Surface sampling behaves like generic scene probing instead of explicit target interrogation | Medium | High | Require explicit targets and clear hit, miss, and ambiguity reporting in the product contract |
| Topology analysis produces findings that are too shallow to guide correction | Medium | Medium | Return concrete defect categories such as loose ends and coincident-but-unmerged endpoints rather than generic “invalid” states |
| Inspection payloads become too large and noisy for model-driven workflows | Medium | Medium | Keep responses compact by default and expose optional detail only where needed |
| Product boundaries blur and this slice starts absorbing semantic modeling or validation responsibilities | Medium | High | Keep the PRD focused on scene targeting and interrogation as an enabling layer, with downstream slices owning creation, asset reuse, and acceptance checks |

## Dependencies

- [`domain-analysis.md`](../domain-analysis.md)
- Scene identity and metadata conventions shared across Managed Scene Objects and Asset Exemplars
- Workflow collection conventions and scene organization guidance from the domain analysis and capability HLDs
- Downstream semantic modeling, asset reuse, and validation workflows that consume targeting and interrogation outputs

## Revision History

| Date | Change |
| --- | --- |
| 2026-04-11 | Initial PRD created to separate scene targeting and interrogation from the other PRD slices after the guide update. |
| 2026-04-11 | Modestly refined the slice to make reprojection-oriented interrogation more explicit, clarified that projection-aware verification should stay compact and composable, and explicitly kept specialized debugging micro-tools out of current scope. |
| 2026-04-12 | Rebalanced priorities to match the guide's Phase 1 focus, keeping `find_entities`, `sample_surface_z`, and `analyze_edge_network` in P0 while moving general inspection helpers to P1. |
| 2026-04-24 | Clarified that bounded terrain profile and section interrogation are valid follow-ons to explicit surface sampling, while terrain editing, patch replacement, and fairing remain outside this capability. |
