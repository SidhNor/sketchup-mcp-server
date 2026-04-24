# Task: MTA-01 Establish Managed Terrain Domain And Research Reference Posture
**Task ID**: `MTA-01`
**Title**: `Establish Managed Terrain Domain And Research Reference Posture`
**Status**: `completed`
**Priority**: `P0`
**Date**: `2026-04-24`

## Linked HLD

- [Managed Terrain Surface Authoring](../../../hlds/hld-managed-terrain-surface-authoring.md)

## Problem Statement

Managed Terrain Surface Authoring is now defined by a PRD and HLD, but the shared domain model still does not name Managed Terrain Surface as a formal concept. The repository also contains a terrain reference guide with useful Unreal Engine research details, but its current root-level posture can make it look more authoritative than intended.

This task establishes the domain and research-reference posture needed before implementation tasks start depending on terrain terminology. It should make clear that Managed Terrain Surface is a terrain-specific managed scene concept, that semantic hardscape remains separate, and that UE references are non-normative research input rather than public tool or architecture guidance.

## Goals

- add Managed Terrain Surface to the domain vocabulary with the minimum lifecycle and ownership concepts needed for planning
- keep `path`, `pad`, and `retaining_edge` explicitly outside terrain state
- preserve the UE reference guide as research material without making it a public contract or architecture source of truth
- record when later MTA tasks should perform targeted UE source inspection so deep research happens with the relevant implementation questions
- keep HLD, PRD, and task references coherent after any reference-guide relocation or labeling

## Acceptance Criteria

```gherkin
Scenario: Managed Terrain Surface is represented in the domain model
  Given the domain analysis is reviewed after this task is complete
  When Managed Terrain Surface terminology is needed by later terrain tasks
  Then the domain analysis names Managed Terrain Surface as a terrain-specific managed scene concept
  And it describes its relationship to Managed Scene Object identity conventions
  And it keeps semantic hardscape outside terrain source state

Scenario: UE terrain material remains research-only
  Given the UE terrain reference guide is reviewed after this task is complete
  When a contributor follows links from the terrain HLD or task set
  Then the guide is clearly labeled or placed as non-normative research reference material
  And it does not appear to define public MCP tool names, Ruby class names, or repo architecture
  And it explains that deep UE source inspection is deferred to the relevant later MTA planning or implementation tasks
  And it identifies MTA-04, MTA-05, and MTA-06 as the first substantial UE inspection points for edit, transition, and fairing behavior

Scenario: terrain source documents remain linked coherently
  Given the terrain PRD, HLD, task README, and related reference material are reviewed
  When links are followed from the task set
  Then all terrain source links resolve within the repository
  And no local absolute paths are introduced
```

## Non-Goals

- implementing terrain runtime code
- defining public MCP terrain tool names or request schemas
- changing semantic hardscape behavior
- converting UE terminology into repo class names

## Business Constraints

- Managed terrain terminology must support later implementation without blurring terrain and hardscape ownership
- UE research details must remain available for later terrain kernel design
- Product and architecture source of truth remains the PRD, HLD, domain analysis, and task set

## Technical Constraints

- Documentation links must be repo-relative
- Domain updates must not imply that terrain state is stored in the existing `su_mcp` metadata dictionary
- The task must preserve the HLD decision that public tool shape is outside the HLD and outside this task

## Dependencies

- [Managed Terrain Surface Authoring HLD](../../../hlds/hld-managed-terrain-surface-authoring.md)
- [PRD: Managed Terrain Surface Authoring](../../../prds/prd-managed-terrain-surface-authoring.md)
- [SketchUp MCP Domain Analysis](../../../domain-analysis.md)

## Relationships

- unblocks `MTA-02`
- informs `MTA-03`, `MTA-04`, `MTA-05`, and `MTA-06`

## Related Technical Plan

- [Technical implementation plan](./plan.md)
- [Implementation summary](./summary.md)

## Success Metrics

- domain analysis can be used by later terrain tasks without redefining Managed Terrain Surface
- hardscape separation is explicit in the domain materials
- UE reference material is preserved but clearly non-normative
