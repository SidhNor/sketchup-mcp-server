# Task: PLAT-19 Restructure Managed Terrain Support Tree
**Task ID**: `PLAT-19`
**Title**: `Restructure Managed Terrain Support Tree`
**Status**: `completed`
**Priority**: `P1`
**Date**: `2026-05-08`

## Linked HLD

- [Platform Architecture and Repo Structure](../../../hlds/hld-platform-architecture-and-repo-structure.md)
- [Managed Terrain Surface Authoring](../../../hlds/hld-managed-terrain-surface-authoring.md)

## Problem Statement

The managed terrain runtime has grown into a large flat capability folder under
`src/su_mcp/terrain/`. It now contains command entrypoints, public request
contracts, terrain state models, storage seams, adoption and sampling support,
edit kernels, region and constraint helpers, feature intent support, output
generation, evidence builders, and hosted/prototype probes as top-level peers.

That shape no longer reflects the platform HLD's capability-folder guidance or
the managed terrain HLD's internal ownership boundaries. It makes future terrain
work harder to place and review, and increases the risk that unrelated behavior
changes are hidden inside structural cleanup.

## Goals

- Reorganize `src/su_mcp/terrain/` into clear internal ownership folders.
- Preserve public terrain MCP contracts, command behavior, Ruby constants, and
  response shapes.
- Keep the cleanup reviewable as a mechanical support-tree restructuring.
- Keep terrain tests mirrored to the source folder structure, and keep normative
  docs and packaging aligned with the moved files.
- Establish a clearer terrain folder baseline for future managed terrain tasks.

## Acceptance Criteria

- `src/su_mcp/terrain/` no longer holds the main terrain implementation as a
  large flat peer set; command, contract, state, storage, adoption, edit,
  region, feature, output, evidence, probe, and UI concerns have explicit
  ownership homes.
- Public terrain behavior is unchanged: `create_terrain_surface` and
  `edit_terrain_surface` keep their public tool names, input schemas, command
  methods, Ruby constants, refusal payloads, and success response shapes.
- Native runtime integration still works: tool catalog loading, schema constant
  references, dispatcher routing, and command factory assembly continue to reach
  the terrain command target.
- The restructuring is mechanical: any behavior changes are absent, or clearly
  separated into follow-up work with a validation gap called out.
- Source-owned tests under `test/terrain/` mirror the moved terrain source
  ownership folders.
- Cross-cutting terrain tests live in explicit terrain test areas rather than an
  accidental flat root, such as contract, integration, fixture, or UI areas.
- Affected source, test, test-support, runtime, and package `require_relative`
  paths are updated to load the moved files.
- The smallest practical terrain test slice, relevant runtime contract/dispatch
  tests, and package verification pass, or any validation gaps are called out.
- Normative docs and specifications are reviewed for stale terrain path or
  ownership claims; drifted normative docs are updated in the same change, while
  historical completed task artifacts remain unchanged.

## Non-Goals

- changing public MCP tool names, arguments, descriptions, schemas, or response contracts
- renaming Ruby classes, modules, or public constants for aesthetic reasons
- redesigning terrain edit algorithms, output strategies, storage formats, or evidence semantics
- moving terrain capability behavior out of the SketchUp extension runtime
- restructuring other capability folders beyond changes needed to keep terrain integration valid
- adding new managed terrain features while moving files

## Business Constraints

- the change must improve maintainability and reviewability rather than produce folder churn for its own sake
- user-visible terrain behavior must remain stable
- the terrain capability should stay coherent as one runtime-owned product slice
- reviewers should be able to verify that the task is structural without revalidating terrain semantics from scratch

## Technical Constraints

- Ruby remains the source of truth for SketchUp-facing terrain behavior and MCP command execution
- `src/su_mcp/runtime/native/native_tool_catalog.rb` remains the home for public MCP tool entries and input schemas
- `src/su_mcp/runtime/runtime_command_factory.rb` and `src/su_mcp/runtime/tool_dispatcher.rb` must continue to assemble and route terrain commands
- moved files must preserve public constants and require/load behavior
- `test/terrain/` must mirror the moved terrain source folder structure for
  source-owned tests, with any cross-cutting tests placed in an explicitly named
  terrain test area rather than left in an accidental flat root
- package staging must continue to copy the terrain support tree into the RBZ support folder
- existing user or in-progress terrain changes must not be reverted as part of the cleanup

## Dependencies

- `PLAT-12`
- [Platform Architecture and Repo Structure](../../../hlds/hld-platform-architecture-and-repo-structure.md)
- [Managed Terrain Surface Authoring](../../../hlds/hld-managed-terrain-surface-authoring.md)

## Relationships

- follows `PLAT-12` by applying the support-tree layering posture inside the largest capability folder
- supports future managed terrain authoring tasks by giving terrain code clearer internal ownership homes
- informs later capability-internal structure cleanup for other large capability folders

## Related Technical Plan

- [Technical Plan](./plan.md)

## Success Metrics

- `src/su_mcp/terrain/` no longer contains the main terrain implementation as one large flat peer set
- moved terrain files are grouped by named ownership folders that align with the platform and managed terrain HLDs
- public terrain MCP contract tests and affected terrain unit tests continue to pass
- package verification still validates the staged runtime layout
- normative docs either reflect the new terrain support-tree shape or have an explicit no-change rationale
- the final diff is primarily file moves and require/test path updates rather than behavioral edits
