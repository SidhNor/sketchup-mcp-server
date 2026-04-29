# Task: MTA-15 Harden Terrain Edit Contract Discoverability
**Task ID**: `MTA-15`
**Title**: `Harden Terrain Edit Contract Discoverability`
**Status**: `completed`
**Priority**: `P0`
**Date**: `2026-04-28`

## Linked HLD

- [Managed Terrain Surface Authoring](specifications/hlds/hld-managed-terrain-surface-authoring.md)

## Problem Statement

The current managed terrain tools expose useful edit behavior and evidence, but the public MCP contract still teaches request shape more clearly than terrain-edit semantics. A generic MCP client can discover `edit_terrain_surface`, `sample_surface_z`, and `measure_scene`, but it is not yet strongly guided toward the safe terrain recipe: choose the operation by intent, bound the support region, protect known-good terrain with `preserveZones`, inspect edit evidence, and verify terrain shape with profiles.

This matters because the server currently exposes tools with descriptions and schemas, but not MCP prompts or resources. Baseline-safe terrain semantics therefore need to be present in the discoverable tool definitions and field descriptions, with user-facing docs kept in sync.

## Goals

- Make terrain edit operation intent discoverable through MCP tool descriptions, field descriptions, review criteria, and docs.
- Clarify that `survey_point_constraint` with `correctionScope: regional` is a smooth correction field, not best-fit planar behavior.
- Document `preserveZones` as the primary way to protect known-good terrain during local and regional edits.
- Surface grid-spacing and close-control representational limits before callers repeatedly issue impossible edits.
- Make post-edit evidence review and profile sampling the normal QA guidance for non-trivial terrain edits.

## Acceptance Criteria

```gherkin
Scenario: terrain edit operation intent is discoverable
  Given a client reviews the MCP definition for edit_terrain_surface
  When the client reads the tool and field descriptions
  Then the contract distinguishes target_height, corridor_transition, local_fairing, and survey_point_constraint by terrain intent
  And the descriptions state that regional survey correction is a smooth correction field rather than implicit planar fitting

Scenario: preserve-zone guidance is visible in the contract
  Given a client plans a local or regional terrain edit near known-good terrain
  When the client reviews constraints.preserveZones guidance
  Then preserve zones are described as the primary protection mechanism for terrain that should not drift
  And the guidance recommends preserve zones near boundaries or known-good profiles outside the intended support area

Scenario: post-edit evidence expectations are discoverable
  Given a terrain edit completes successfully
  When the client reviews the tool contract and MCP reference docs
  Then changedRegion, maxSampleDelta, survey residuals, preserve-zone drift, slope/curvature proxy changes, and regional coherence are documented as review evidence where available
  And the contract does not imply command success is visual or grading acceptance

Scenario: profile sampling is described as terrain QA
  Given a client needs to verify terrain behavior after an edit
  When the client reviews sample_surface_z and measure_scene terrain_profile guidance
  Then point sampling is described as control verification
  And profile sampling is described as terrain-shape verification between controls
```

## Non-Goals

- adding a new terrain solver or changing survey correction behavior
- adding planar fit, monotonic profile, or boundary-preserving patch edit modes
- exposing MCP prompts or resources
- changing public tool names
- turning profile sampling into validation pass/fail policy

## Business Constraints

- The discoverable MCP contract must be sufficient for baseline-safe use by a generic competent MCP client.
- Richer examples and orchestration playbooks may live in docs or future prompts/resources, but core terrain safety semantics must not depend on client-side prompt stuffing.
- Terrain documentation must guide edit recipes without overstating unsupported planar, monotonic, or boundary-preserving behavior.

## Technical Constraints

- Ruby remains the canonical owner of native MCP tool registration and schema descriptions.
- Public contract updates must keep runtime schema descriptions, reference docs, and applicable structural contract checks in sync.
- Provider-compatible top-level schema constraints must remain intact.
- Outputs crossing the MCP boundary must remain JSON-serializable.

## Dependencies

- `MTA-13`
- `MTA-14`
- `STI-03`
- `SVR-04`
- [Terrain modelling signal](specifications/signals/2026-04-28-terrain-modelling-session-reveals-planar-intent-and-profile-qa-gaps.md)
- [MCP Tool Authoring Standard](specifications/guidelines/mcp-tool-authoring-sketchup.md)

## Relationships

- follows `MTA-13` and `MTA-14` by making the shipped survey correction semantics and evidence discoverable
- informs `MTA-16` so planar fit work starts from a clear current-contract baseline
- informs `PLAT-18` by identifying which guidance belongs in tools versus future prompts/resources

## Related Technical Plan

- [Technical Plan](./plan.md)

## Success Metrics

- implementation closeout records that changed runtime descriptions and docs were reviewed against the critical terrain edit semantics
- `docs/mcp-tool-reference.md` and the MCP runtime schema describe the same terrain operation boundaries
- a reviewer can identify from the public contract when to use point sampling versus profile sampling
- no public description implies regional survey correction is planar fitting unless an explicit future contract adds that behavior
