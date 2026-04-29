# Task: PLAT-18 Implement Initial MCP Prompts Guidance Surface
**Task ID**: `PLAT-18`
**Title**: `Implement Initial MCP Prompts Guidance Surface`
**Status**: `completed`
**Priority**: `P1`
**Date**: `2026-04-28`

## Linked HLD

- [Platform Architecture and Repo Structure](specifications/hlds/hld-platform-architecture-and-repo-structure.md)

## Problem Statement

The Ruby-native MCP runtime currently exposes tools with descriptions and schemas, but it does not expose MCP prompts as a server guidance surface. Recent terrain modelling feedback showed that baseline-safe semantics must remain in tool definitions, while richer reusable recipes, examples, and troubleshooting playbooks can become too large for concise tool descriptions.

This task implements an initial MCP prompts surface for server-owned workflow guidance, without weakening the rule that tool definitions must remain sufficient for generic clients to call tools safely. The main planning question is the minimal useful prompt catalog size, not whether prompts are worth exploring indefinitely.

## Goals

- Add native runtime support for exposing a small MCP prompt catalog if the packaged SDK/runtime path supports it.
- Define the minimal initial prompt set, with `managed_terrain_edit_workflow` and `terrain_profile_qa_workflow` as static no-argument prompts.
- Make reusable 3D scene workflow guidance discoverable through MCP prompts.
- Keep exposed prompts focused on client-facing terrain and scene workflows.
- Preserve existing tool catalog behavior and provider-compatible input schema rules.
- Cover prompt discovery and retrieval with focused runtime tests and docs.

## Acceptance Criteria

```gherkin
Scenario: initial prompts are discoverable
  Given the Ruby-native MCP runtime exposes tools today
  When an MCP client asks for the prompt catalog
  Then the runtime exposes the initial server-owned prompt set
  And existing tools/list behavior remains unchanged

Scenario: prompts remain workflow guidance
  Given clients can already discover and call first-class tools
  When prompt guidance is added
  Then prompts provide reusable scene workflow recipes
  And prompts do not become hidden required context for calling ordinary tools correctly

Scenario: terrain recipes seed the first prompt catalog
  Given managed terrain authoring has preserve-zone, profile-QA, and staged-correction recipes
  When the initial prompt catalog is defined
  Then the task ships managed_terrain_edit_workflow and terrain_profile_qa_workflow as the smallest useful prompt set for those reusable recipes
  And the task avoids turning client orchestration strategy into server contract requirements
```

## Non-Goals

- moving core tool safety semantics out of tool descriptions
- implementing terrain edit behavior
- redesigning the public MCP tool catalog
- creating client-specific prompt wrappers
- replacing user-facing reference docs
- implementing MCP resources unless they share the same low-risk runtime path and remain smaller than the prompt work
- exposing internal platform guidance as prompts for scene-manipulating clients

## Business Constraints

- Generic MCP clients must remain able to use first-class tools safely from `tools/list` alone.
- Server-owned prompts should improve reusable guidance, not become mandatory hidden context for correctness.
- The platform should avoid bloating every tool description with long examples when a richer server guidance surface is available.

## Technical Constraints

- Ruby remains the canonical owner of native MCP runtime behavior.
- Prompt implementation must be covered by focused runtime tests and packaged-runtime smoke expectations where practical.
- Tool schema provider-compatibility rules must remain unchanged.
- Prompt payloads must remain JSON-serializable or protocol-native text and should avoid raw SketchUp objects.

## Dependencies

- `PLAT-14`
- `PLAT-16`
- `PLAT-17`
- `MTA-15`
- [Platform Architecture and Repo Structure](specifications/hlds/hld-platform-architecture-and-repo-structure.md)
- [MCP Tool Authoring Standard](specifications/guidelines/mcp-tool-authoring-sketchup.md)

## Relationships

- follows the native contract hardening tasks by adding a complementary guidance surface
- informs future capability tasks that need richer examples without overloading tool descriptions
- supports managed terrain authoring recipes identified by `MTA-15`

## Related Technical Plan

- [Technical plan](./plan.md)

## Success Metrics

- the platform exposes an initial MCP prompt catalog through the native runtime
- the initial prompt catalog contains managed_terrain_edit_workflow and terrain_profile_qa_workflow with no required arguments
- exposed prompts are useful to clients manipulating 3D scenes
- representative terrain recipes are classified as tool-description, prompt, docs, or client-doc guidance
- no recommendation weakens baseline-safe tool discoverability through `tools/list`
