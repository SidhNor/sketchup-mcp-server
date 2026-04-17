# Task: PLAT-14 Establish Native MCP Tool Contract And Response Conventions
**Task ID**: `PLAT-14`
**Title**: `Establish Native MCP Tool Contract And Response Conventions`
**Status**: `draft`
**Priority**: `P1`
**Date**: `2026-04-17`

## Linked HLD

- [Platform Architecture and Repo Structure](../../../hlds/hld-platform-architecture-and-repo-structure.md)

## Problem Statement

The Ruby-native MCP runtime is now the canonical public tool host, but the current tool catalog still mixes two authoring postures. A small scene and semantic slice already carries clearer titles, bounded descriptions, and shaped request or response semantics, while much of the remaining catalog is still declared as lightly wrapped runtime inventory. Tool metadata is not enforced uniformly, success or refusal shapes vary by command family, and shared runtime ownership of result envelopes and error translation remains only partially realized. That drift makes the MCP surface harder to evolve coherently, increases the chance that future tools keep inventing local declaration or response patterns, and weakens adherence to the SketchUp tool-authoring guidance even where the underlying Ruby behavior is already correct.

## Goals

- define one Ruby-owned native tool declaration contract for the public MCP catalog so live tool metadata and runtime registration no longer rely on permissive ad hoc hashes
- establish shared success, refusal, and error-shaping conventions for the native runtime so command families do not keep returning incompatible envelopes by default
- improve future-tool authoring consistency without reopening broader selector redesign or catalog-wide schema reform in this task

## Acceptance Criteria

```gherkin
Scenario: Native MCP tools use one shared declaration contract
  Given the Ruby-native runtime currently assembles the public tool catalog from permissive per-tool hash entries
  When the native tool registration surface is reviewed after this task is complete
  Then the catalog is authored through one shared Ruby-owned declaration contract
  And each public native tool declares explicit client-facing metadata required by that contract
  And the runtime no longer relies on silent metadata omission as the default authoring posture

Scenario: Shared response conventions exist for representative native command families
  Given native tool results currently vary between scene, semantic, hierarchy, editing, and modeling command families
  When representative read, mutation, and refusal paths are exercised after this task is complete
  Then the runtime exposes one shared convention for successful structured results
  And the runtime exposes one shared convention for structured refusals where command behavior declines execution
  And command-level failures that cross the MCP boundary are translated through a shared runtime-owned error-shaping seam

Scenario: Shared conventions remain compatible with the current native public surface
  Given the Ruby-native runtime already exposes stable public tool names and current capability contracts
  When the completed task is reviewed
  Then the task does not require a broad redesign of public tool names or current workflow boundaries
  And tool registration, command ownership, and MCP-visible behavior remain rooted in the Ruby runtime rather than a second metadata owner
  And any contract tightening beyond the approved task boundary is left to follow-on work

Scenario: The task stays bounded to the highest-value platform seams
  Given broader tool-surface cleanup could also include selector redesign, field-level examples, and full-catalog guide conformance scoring
  When the completed task is reviewed
  Then shared tool declarations and shared response or refusal conventions are implemented as the primary platform outcome
  And selector-vocabulary redesign is not required for task completion
  And heavy catalog-wide conformance machinery is not required for task completion
```

## Non-Goals

- redesigning selector vocabulary across the current tool catalog
- performing a broad rewrite of existing tool boundaries or collapsing low-level modeling tools into semantic tools
- introducing a separate PRD or a new platform HLD for this bounded contract-hardening slice
- creating a heavy guide-lint or full-catalog conformance scoring system in this task

## Business Constraints

- the task must improve MCP surface consistency in a way that makes future public tools easier to author and review
- client-facing descriptions and response shapes must remain legible to agentic clients without overstating current delivered capability
- the task should target the highest-value shared platform seams first rather than expanding into a broad public-catalog redesign
- escape-hatch tools such as `eval_ruby` must remain clearly outside the normal first-class tool-authoring posture

## Technical Constraints

- Ruby remains the canonical owner of MCP tool registration, response shaping, and SketchUp-facing behavior
- shared runtime infrastructure should own result envelopes, error translation, and similar cross-cutting conventions in line with the platform HLD
- public outputs that cross the MCP boundary must remain JSON-serializable
- existing public tool names and current capability contracts should remain stable unless a separate intentional interface change is defined later
- the task must align the native runtime more closely with `specifications/guidelines/mcp-tool-authoring-sketchup.md` without taking ownership of every guide recommendation at once

## Dependencies

- `PLAT-10`
- `PLAT-13`

## Relationships

- follows `PLAT-13`
- narrows remaining native-runtime contract drift after `PLAT-10`
- informs later task-planning or implementation work for broader tool-surface cleanup
- informs future capability tasks that add or revise public MCP tools

## Related Technical Plan

- none yet

## Success Metrics

- the native runtime has one shared public tool declaration contract rather than permissive per-entry catalog authoring
- representative native read, mutation, and refusal flows expose consistent MCP-visible result or refusal shapes
- future native tool work can extend one shared contract seam without redefining metadata and response conventions locally
