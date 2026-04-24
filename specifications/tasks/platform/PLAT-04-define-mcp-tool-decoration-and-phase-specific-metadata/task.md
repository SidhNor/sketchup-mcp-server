# Task: PLAT-04 Define MCP Tool Decoration and Phase-Specific Metadata
**Task ID**: `PLAT-04`
**Title**: `Define MCP Tool Decoration and Phase-Specific Metadata`
**Status**: `completed`
**Priority**: `P0`
**Date**: `2026-04-14`

## Linked HLD

- [Platform Architecture and Repo Structure](../../../hlds/hld-platform-architecture-and-repo-structure.md)

## Problem Statement

The repository now has the Python layering needed to own MCP-facing tool metadata cleanly, but it still lacks a platform-owned contract for how tool titles, descriptions, and behavior annotations should be exposed to clients as capability waves roll out. Public tool metadata is currently minimal and phase-agnostic, which makes it too easy for tools to under-explain their intended use, over-advertise deferred scope, or fail to distinguish read-only grounding tools from mutating scene-editing tools.

That gap matters because the current and next capability waves depend on first-class tools such as `find_entities`, `sample_surface_z`, and `create_site_element` displacing fallback `eval_ruby` for normal workflows. Without an explicit platform-owned decoration contract, already-exposed tools can remain under-described today, future capability tasks may each improvise client-facing metadata differently, and agentic clients may continue to prefer the broad escape hatch because narrower tools are not described clearly enough at the MCP boundary.

This task establishes MCP tool decoration as a platform-owned contract concern. It must define one shared project-owned decoration contract and the rules for how phased tool metadata is sourced and exposed so that capability tasks can adopt one consistent decoration posture without redefining it for each tool wave.

## Goals

- define one platform-owned decoration contract for MCP tool titles, descriptions, and behavior annotations
- apply the shared decoration contract to the already-exposed public tools that this platform slice can improve now
- require phase-specific metadata for staged public tools so current-phase descriptions do not advertise deferred capability when future tools are introduced
- provide a reusable decoration posture that capability tasks can apply to `find_entities`, `sample_surface_z`, `create_site_element`, and future public tools

## Acceptance Criteria

```gherkin
Scenario: The platform defines one shared MCP decoration contract
  Given the Python MCP adapter owns exposed tool metadata
  When the project metadata sources are inspected
  Then the project defines one shared decoration contract for decorated public tools
  And that contract includes the required client-facing metadata fields of title, description, and tool-behavior annotations
  And exposed tools implement that contract through explicit decorator metadata
  And capability tasks can reference the same contract instead of redefining those metadata rules independently

Scenario: Already-exposed public tools adopt the shared decoration contract
  Given the Python MCP adapter already exposes public tools today
  When the currently exposed targeting, interrogation, and semantic tools are inspected
  Then `find_entities`, `sample_surface_z`, and `create_site_element` use the shared decoration contract
  And their exposed metadata includes client-facing titles, descriptions, and behavior annotations
  And the platform does not require capability tasks to redefine those metadata rules independently

Scenario: Phase-specific descriptions remain aligned with delivered capability scope
  Given some public tools are already exposed and others are still planned in staged capability work
  When the phase-specific decoration definitions for current and future tools are inspected
  Then each already-exposed tool includes at least one current-phase client-facing description in its live decorator metadata
  And planned tools carry approved current-phase descriptions in their owning capability artifacts before exposure
  And tools with a documented later expansion stage also carry later-phase description guidance in those owning capability artifacts
  And no current-phase description claims deferred behavior that is not yet delivered in the owning capability task

Scenario: Current-phase decoration for targeted tools reflects their actual contract boundaries
  Given the current capability tasks define specific public boundaries for `find_entities`, `sample_surface_z`, and `create_site_element`
  When the current-phase decoration entries are inspected against their owning task definitions
  Then `find_entities` does not advertise metadata-aware or collection-aware filtering before those behaviors are delivered
  And `sample_surface_z` states that callers provide an explicit target and canonical points or profile sampling rather than broad scene discovery
  And `create_site_element` only advertises the semantic element types delivered in `SEM-01`
  And the later-phase `create_site_element` expansion guidance remains embedded in the owning semantic tasks rather than guessed during later implementation

Scenario: Decoration exposes read-only versus mutating posture consistently at the MCP boundary
  Given agentic clients benefit from distinguishing grounding tools from scene-mutation tools
  When the shared decoration contract and exposed MCP metadata are inspected for the targeted tools
  Then `find_entities` and `sample_surface_z` are marked as read-only tools
  And `create_site_element` is marked with a mutating non-destructive posture
  And the exposed metadata remains consistent with the shared decoration contract
```

## Non-Goals

- implementing the underlying Ruby or Python behavior for `find_entities`, `sample_surface_z`, or `create_site_element`
- expanding the functional input or output contracts of capability-owned tools beyond what their source tasks already define
- redesigning the full tool catalog or removing `eval_ruby` from the public surface in this task

## Business Constraints

- client-facing metadata must improve tool legibility for agentic clients without overstating current capability scope
- decoration must remain phase-aware so partially delivered capability waves are not presented as broader than they really are
- the platform contract should help first-class tools compete with fallback `eval_ruby` when those tools already cover the intended workflow

## Technical Constraints

- Python remains the owner of exposed MCP tool metadata, while Ruby remains the owner of runtime behavior and business logic
- the decoration contract must stay compatible with the Python tool-module layering established by `PLAT-03`
- phase-specific tool metadata must align with the owning capability tasks for `STI-01`, `STI-02`, `SEM-01`, and `SEM-02` rather than inventing unsupported scope
- exposed annotations remain metadata hints and must not replace runtime validation, safety checks, or authorization behavior

## Dependencies

- `PLAT-03`

## Relationships

- blocks `STI-02`
- blocks `SEM-01`
- blocks `SEM-02`
- informs future public MCP tool rollout tasks

## Related Technical Plan

- [Technical Plan](./plan.md)

## Success Metrics

- the project defines one shared project-owned decoration contract that capability tasks can adopt directly
- phase-specific metadata exists in live decorator metadata for already-exposed targeted tools and in owning capability artifacts for later-phase expansions such as `SEM-02`
- exposed tool metadata distinguishes read-only targeting or interrogation tools from mutating semantic-creation tools consistently at the MCP boundary
