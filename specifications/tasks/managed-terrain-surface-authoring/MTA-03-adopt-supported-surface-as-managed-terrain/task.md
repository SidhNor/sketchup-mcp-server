# Task: MTA-03 Adopt Supported Surface As Managed Terrain
**Task ID**: `MTA-03`
**Title**: `Adopt Supported Surface As Managed Terrain`
**Status**: `draft`
**Priority**: `P0`
**Date**: `2026-04-24`

## Linked HLD

- [Managed Terrain Surface Authoring](../../../hlds/hld-managed-terrain-surface-authoring.md)

## Problem Statement

The terrain state foundation is only useful once an existing SketchUp surface can become a targetable Managed Terrain Surface. Today, terrain-aware workflows can sample or measure terrain, and semantic paths can drape over terrain, but no supported workflow adopts a terrain surface as managed terrain state with owned derived output.

This task delivers the first product-visible managed terrain vertical slice. It should adopt a deliberately narrow supported source surface path, create or designate a stable terrain owner, recreate materialized terrain state from the source, persist that state through the terrain repository, generate derived terrain output, and return adoption evidence.

## Goals

- adopt one supported class of explicit source terrain surface into Managed Terrain Surface state
- write lightweight `su_mcp` identity metadata on the stable terrain owner
- store terrain state payload through the terrain-specific repository namespace
- generate derived terrain mesh output from materialized terrain state
- return JSON-safe adoption evidence and structured refusals
- validate undo, save/load, and live host behavior where practical

## Acceptance Criteria

```gherkin
Scenario: a supported source surface is adopted as managed terrain
  Given a supported explicit source surface can be resolved and sampled
  When the adoption use-case is executed
  Then a stable terrain owner exists for the Managed Terrain Surface
  And lightweight identity metadata is written through `su_mcp`
  And materialized terrain state is saved through the terrain repository
  And derived terrain output is generated from the saved state

Scenario: adoption evidence is returned
  Given a supported source surface has been adopted
  When the adoption result is reviewed
  Then the response includes JSON-safe evidence for source summary, terrain-state summary, output summary, and warnings where applicable
  And the evidence avoids raw SketchUp objects and generated face or vertex identity as durable references

Scenario: unsupported source surfaces refuse clearly
  Given an ambiguous, unsupported, unsampleable, or unsafe source surface is requested for adoption
  When the adoption use-case is executed
  Then it returns a structured refusal with actionable reason data
  And it does not create partial managed terrain as the expected outcome

Scenario: adoption preserves coherent host behavior
  Given adoption mutates the SketchUp model
  When the adoption succeeds, fails, is undone, or the model is reloaded
  Then terrain identity, terrain state storage, and derived output remain coherent
  And failures do not leave the expected state split between saved terrain payload and missing derived output
```

## Non-Goals

- supporting every possible SketchUp TIN or terrain source shape
- implementing bounded terrain edits
- implementing corridor transition or local fairing kernels
- mutating semantic hardscape objects
- defining public Unreal-style terrain tools

## Business Constraints

- adoption must reduce the need for arbitrary Ruby terrain setup workflows
- the first adoption slice should be narrow enough to prove lifecycle behavior before broad source compatibility
- hardscape objects remain separate and may only be referenced explicitly where supported

## Technical Constraints

- adoption must use the terrain state and storage foundation from `MTA-02`
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
- provides first terrain adoption evidence consumed by later validation and review work
- depends on existing targeting and surface sampling foundations without rewriting those task sets

## Related Technical Plan

- none yet

## Success Metrics

- a representative supported source surface can be adopted without `eval_ruby`
- terrain payload storage, lightweight metadata, and derived output are all present and coherent after adoption
- unsupported source cases refuse without expected partial terrain state
- adoption has a documented automated and live verification story
