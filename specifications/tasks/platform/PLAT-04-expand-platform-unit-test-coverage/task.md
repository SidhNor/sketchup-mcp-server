# Task: PLAT-04 Expand Platform Unit Test Coverage
**Task ID**: `PLAT-04`
**Title**: `Expand Platform Unit Test Coverage`
**Status**: `defined`
**Date**: `2026-04-13`

## Linked HLD

- [Platform Architecture and Repo Structure](../../../hlds/hld-platform-architecture-and-repo-structure.md)

## Problem Statement

The repository already has Ruby and Python test entrypoints, but current automated coverage is still narrow compared with the revised platform architecture. As Ruby and Python boundaries are extracted from concentrated modules, the platform needs meaningful unit coverage for those extracted non-runtime-specific concerns so refactoring confidence does not depend mostly on manual verification. That coverage should grow with the decomposition work rather than wait until every extraction task is fully complete.

## Goals

- expand Ruby unit coverage for extracted non-SketchUp platform logic
- expand Python unit coverage for decomposed adapter boot, invocation, tool wiring, and error mapping
- grow coverage incrementally as reviewable platform boundaries are extracted
- make the unit-test layer the normal always-on protection for extracted platform behavior

## Acceptance Criteria

```gherkin
Scenario: Extracted Ruby platform logic has meaningful unit coverage
  Given shared runtime contracts and reusable non-SketchUp Ruby helpers are part of the platform
  When the Ruby test layer is reviewed
  Then extracted non-SketchUp platform logic is covered by Ruby unit tests
  And that coverage does not require a live SketchUp runtime

Scenario: Extracted Python platform logic has meaningful unit coverage
  Given the Python MCP adapter owns app boot, shared invocation, tool exposure, and boundary error handling
  When the Python test layer is reviewed
  Then those platform-owned behaviors have automated unit coverage
  And that coverage is distinct from live SketchUp integration testing

Scenario: Unit coverage reflects the modularized platform boundaries
  Given the Ruby and Python runtimes are being decomposed into clearer layers
  When automated coverage is reviewed
  Then unit tests map to those extracted platform boundaries
  And contributors do not rely solely on manual end-to-end testing for non-runtime-specific logic

Scenario: Coverage expansion tracks extraction work
  Given `PLAT-01`, `PLAT-02`, and `PLAT-03` expose reviewable platform-owned boundaries over time
  When `PLAT-04` is reviewed as part of the core delivery path
  Then unit coverage expands alongside those extracted boundaries where practical
  And the task is not treated as a purely end-loaded cleanup phase
```

## Non-Goals

- proving SketchUp-dependent behavior outside SketchUp
- replacing all manual verification with automated tests
- defining cross-runtime contract tests or SketchUp-hosted smoke coverage in this task

## Business Constraints

- fast contributor feedback is required for extracted platform logic
- test ownership should sit with the layer that owns the behavior
- the unit-test story must scale with the more modular runtime structure

## Technical Constraints

- the unit-test layer must align with the revised platform HLD
- behaviors that inherently require a live SketchUp runtime must remain out of the Ruby unit-test layer
- Python unit coverage must reflect the decomposed adapter boundaries from `PLAT-03`
- coverage may land incrementally alongside `PLAT-01`, `PLAT-02`, and `PLAT-03` rather than only after they are all fully complete

## Dependencies

- initial extraction work from `PLAT-01`
- extracted Ruby platform boundaries from `PLAT-02` as they become available
- extracted Python adapter boundaries from `PLAT-03` as they become available

## Relationships

- primary always-on automated verification task for the platform
- tracks `PLAT-01`, `PLAT-02`, and `PLAT-03` as reviewable boundaries become available
- complements `PLAT-05`
- complements `PLAT-06`

## Related Technical Plan

- none yet

## Success Metrics

- extracted non-runtime-specific Ruby and Python platform logic has meaningful automated coverage
- contributors can identify a clear always-on unit-test layer for platform refactors
- platform refactors can be validated without depending only on manual runtime verification
