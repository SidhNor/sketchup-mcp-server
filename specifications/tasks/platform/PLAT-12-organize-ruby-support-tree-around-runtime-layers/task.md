# Task: PLAT-12 Organize Ruby Support Tree Around Runtime Layers
**Task ID**: `PLAT-12`
**Title**: `Organize Ruby Support Tree Around Runtime Layers`
**Status**: `completed`
**Priority**: `P1`
**Date**: `2026-04-16`

## Linked HLD

- [Platform Architecture and Repo Structure](../../../hlds/hld-platform-architecture-and-repo-structure.md)

## Problem Statement

Recent platform cleanup tasks narrowed Ruby ownership hotspots and `PLAT-10` made Ruby-native MCP the canonical public tool host, but the Ruby support tree still remains flatter than the intended runtime layering. Transport, command, shared runtime, native MCP runtime, and support-oriented files are still mixed together at the top level of `src/su_mcp/` more often than the current HLD implies. That makes the repository harder to scan, weakens the visibility of the intended layering, and increases the chance that new files continue landing in the top-level namespace by default even after the runtime ownership model has become clearer.

## Goals

- make the Ruby support tree express the intended runtime layers more clearly once the current runtime migration seams have settled
- preserve the current SketchUp loader, packaging posture, and public behavior while improving internal file and folder ownership boundaries
- reduce the top-level `src/su_mcp/` default-home pressure for unrelated runtime concerns

## Acceptance Criteria

```gherkin
Scenario: Ruby support tree reflects the intended runtime layers
  Given the Ruby runtime currently keeps multiple transport, command, runtime, and support files as top-level peers under `src/su_mcp/`
  When the Ruby support tree is reviewed after this task is complete
  Then the file and folder layout expresses the intended runtime layers more clearly
  And transport, command, shared runtime, and native-runtime concerns no longer rely on the top-level namespace as their default long-term home

Scenario: Structural cleanup preserves runtime entrypoints and packaging behavior
  Given the SketchUp extension loader and packaging flow already depend on the current entrypoint posture
  When the runtime is exercised after the structural cleanup
  Then `src/su_mcp.rb` remains a registration entrypoint rather than absorbing runtime behavior
  And extension loading and packaging behavior remain valid after the support-tree reorganization

Scenario: Structural cleanup does not redefine migrated runtime ownership
  Given `PLAT-10` owns migration of the current MCP tool surface to Ruby-native MCP
  When this task is reviewed after completion
  Then the task outcome expresses the settled runtime ownership in the filesystem rather than re-litigating the migration boundary
  And Python remains outside the scope except where Ruby file moves require mechanical compatibility updates

Scenario: Structural cleanup remains reviewable and bounded
  Given folder churn can obscure whether a cleanup improved architecture or only moved files
  When the completed task is reviewed
  Then the moved or regrouped files are traceable to the HLD runtime layers and current Ruby ownership seams
  And unrelated behavior changes are either absent or explicitly scoped as follow-up work
```

## Non-Goals

- migrating the public MCP tool surface to Ruby-native MCP
- redesigning the Ruby command layer beyond the file and folder ownership needed to express settled runtime boundaries
- changing public tool names, bridge contracts, or Python adapter behavior except for mechanical path-alignment updates
- turning the cleanup into a broad cross-repo rewrite

## Business Constraints

- the task must improve maintainability and reviewability rather than produce folder churn for its own sake
- the resulting layout should make the intended Ruby runtime architecture easier for future contributors to follow
- user-visible behavior should remain stable unless a separate task intentionally changes it
- the task should complement ongoing platform migration work rather than compete with it for architectural ownership

## Technical Constraints

- the Ruby layer remains the source of truth for SketchUp-facing behavior and runtime ownership
- `src/su_mcp.rb` must remain a small registration entrypoint with runtime behavior living under the support tree
- extension packaging, load paths, and require behavior must remain valid after file moves
- Ruby-native MCP runtime files, transport files, command files, and shared support files should be organized according to the current HLD layers rather than ad hoc preferences
- the task should treat `PLAT-10` runtime migration seams as upstream structure to express, not as scope to reopen

## Dependencies

- `PLAT-10`
- `PLAT-08`
- `PLAT-11`

## Relationships

- follows `PLAT-10`
- consolidates the extracted Ruby ownership seams created during `PLAT-08` and `PLAT-11`
- informs later cleanup aimed at keeping new Ruby support code out of the top-level namespace by default

## Related Technical Plan

- [Technical Plan](./plan.md)

## Completion Notes

- Reorganized the Ruby support tree into explicit `transport/`, `runtime/`, `runtime/native/`, `scene_query/`, `editing/`, `modeling/`, `developer/`, and `semantic/` subtrees while keeping `src/su_mcp.rb` and `src/su_mcp/main.rb` as the stable entrypoints.
- Kept Ruby constants, tool names, bridge payload shapes, and Python contract behavior unchanged; the implementation was limited to file moves, `require_relative` rewiring, mirrored app-owned test moves, and packaging-path updates.
- Verified the reorganized tree with focused slice tests, full Ruby tests, Ruby and Python contract suites, full Ruby lint, and `package:verify:all`.
- Manual SketchUp-hosted smoke verification is still outstanding from this environment and remains the only explicit post-implementation gap.

## Success Metrics

- reviewers can identify the main Ruby runtime layers from the support-tree layout without treating `src/su_mcp/` as a flat catch-all
- the SketchUp loader and packaging posture remain stable after the reorganization
- the cleanup can be justified against HLD-defined runtime layers and settled ownership seams instead of subjective folder preferences
