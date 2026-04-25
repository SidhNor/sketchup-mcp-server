# Task: MTA-03 Create Or Adopt Managed Terrain Surface
**Task ID**: `MTA-03`
**Title**: `Create Or Adopt Managed Terrain Surface`
**Status**: `completed`
**Priority**: `P0`
**Date**: `2026-04-24`

## Linked HLD

- [Managed Terrain Surface Authoring](../../../hlds/hld-managed-terrain-surface-authoring.md)

## Problem Statement

The terrain state foundation is only useful once workflows can create a targetable Managed Terrain Surface. Today, terrain-aware workflows can sample or measure terrain, and semantic paths can drape over terrain, but no supported workflow creates managed terrain state with owned derived output or adopts an existing terrain surface into that state.

This task delivers the first product-visible managed terrain vertical slice. It should provide one terrain creation surface that can create a deliberately simple grid-backed Managed Terrain Surface and adopt a deliberately narrow supported source surface path. Both paths should create or designate a stable terrain owner, materialize terrain state, persist that state through the terrain repository, generate derived terrain output, and return creation or adoption evidence.

## Goals

- expose a terrain creation workflow that supports a deliberately simple create path and one supported adoption path
- create a simple grid-backed Managed Terrain Surface from explicit terrain-state input
- adopt one supported class of explicit source terrain surface into Managed Terrain Surface state
- write lightweight `su_mcp` identity metadata on the stable terrain owner
- store terrain state payload through the terrain-specific repository namespace
- generate derived terrain mesh output from materialized terrain state
- return JSON-safe creation or adoption evidence and structured refusals
- validate undo, save/load, and live host behavior where practical

## Acceptance Criteria

```gherkin
Scenario: a simple managed terrain surface is created
  Given explicit supported grid terrain input is provided
  When the create-terrain use-case is executed
  Then a stable terrain owner exists for the Managed Terrain Surface
  And lightweight identity metadata is written through `su_mcp`
  And materialized terrain state is saved through the terrain repository
  And derived terrain output is generated from the saved state

Scenario: a supported source surface is adopted as managed terrain
  Given a supported explicit source surface can be resolved and sampled
  When the create-terrain use-case is executed in adoption mode
  Then a stable terrain owner exists for the Managed Terrain Surface
  And lightweight identity metadata is written through `su_mcp`
  And materialized terrain state is saved through the terrain repository
  And derived terrain output is generated from the saved state

Scenario: creation and adoption evidence is returned
  Given a supported managed terrain surface has been created or adopted
  When the result is reviewed
  Then the response includes JSON-safe evidence for input or source summary, terrain-state summary, output summary, and warnings where applicable
  And the evidence avoids raw SketchUp objects and generated face or vertex identity as durable references

Scenario: unsupported terrain creation requests refuse clearly
  Given unsupported grid input or an ambiguous, unsupported, unsampleable, or unsafe source surface is requested
  When the create-terrain use-case is executed
  Then it returns a structured refusal with actionable reason data
  And it does not create partial managed terrain as the expected outcome

Scenario: terrain creation preserves coherent host behavior
  Given terrain creation mutates the SketchUp model
  When creation succeeds, fails, is undone, or the model is reloaded
  Then terrain identity, terrain state storage, and derived output remain coherent
  And failures do not leave the expected state split between saved terrain payload and missing derived output
```

## Non-Goals

- supporting every possible SketchUp TIN or terrain source shape
- creating terrain from contours, procedural terrain generation, or naturalistic terrain synthesis
- implementing bounded terrain edits
- implementing corridor transition or local fairing kernels
- mutating semantic hardscape objects
- defining public Unreal-style terrain tools

## Business Constraints

- terrain creation must reduce the need for arbitrary Ruby terrain setup workflows
- the first create and adoption slices should be narrow enough to prove lifecycle behavior before broad source compatibility
- hardscape objects remain separate and may only be referenced explicitly where supported

## Technical Constraints

- terrain creation and adoption must use the terrain state and storage foundation from `MTA-02`
- terrain state must be owner-local and independent of raw SketchUp objects
- generated output is derived from terrain state and must not become the source of truth
- mutation must be one coherent SketchUp operation where practical
- any public MCP surface change must update runtime registration, dispatcher behavior, tests, and docs in the same implementation change

## Dependencies

- `MTA-02`
- `STI-02`
- `STI-03`
- [Managed Terrain Surface Authoring HLD](../../../hlds/hld-managed-terrain-surface-authoring.md)
- [PRD: Managed Terrain Surface Authoring](../../../prds/prd-managed-terrain-surface-authoring.md)

## Relationships

- unblocks `MTA-04`
- provides first terrain creation and adoption evidence consumed by later validation and review work
- depends on existing targeting and surface sampling foundations without rewriting those task sets

## Related Technical Plan

- [Technical Plan](./plan.md)

## Success Metrics

- a representative simple grid terrain can be created without `eval_ruby`
- a representative supported source surface can be adopted without `eval_ruby`
- terrain payload storage, lightweight metadata, and derived output are all present and coherent after creation or adoption
- unsupported grid and source cases refuse without expected partial terrain state
- terrain creation has a documented automated and live verification story
