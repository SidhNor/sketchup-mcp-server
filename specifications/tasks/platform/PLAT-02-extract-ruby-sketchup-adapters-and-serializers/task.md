# Task: PLAT-02 Extract Ruby SketchUp Adapters and Serializers
**Task ID**: `PLAT-02`
**Title**: `Extract Ruby SketchUp Adapters and Serializers`
**Status**: `planned`
**Priority**: `P0`
**Date**: `2026-04-13`

## Linked HLD

- [Platform Architecture and Repo Structure](../../../hlds/hld-platform-architecture-and-repo-structure.md)

## Problem Statement

Direct SketchUp API usage, entity lookup, export helpers, and serialization behavior currently live too close to the concentrated Ruby runtime implementation. That makes low-level SketchUp behavior harder to reuse and keeps higher-level execution concerns coupled to API-heavy code paths.

## Goals

- establish an explicit Ruby adapter boundary for direct SketchUp API access
- establish reusable serialization ownership for JSON-safe results derived from SketchUp state
- reduce the amount of low-level SketchUp logic owned directly by transport or orchestration code

## Acceptance Criteria

```gherkin
Scenario: Direct SketchUp API access has explicit adapter ownership
  Given the Ruby runtime performs entity lookup, mutation, inspection, and export behavior
  When the Ruby platform structure is reviewed
  Then direct SketchUp API interaction is owned by a dedicated adapter layer
  And higher-level execution code is not expected to implement raw API mechanics directly

Scenario: Serialization is reusable and JSON-safe
  Given Ruby returns structured SketchUp-derived results to Python
  When representative result paths are reviewed
  Then serialization behavior is handled by reusable platform-owned helpers or serializers
  And returned payloads consist only of JSON-serializable values

Scenario: Capability work can depend on shared adapter contracts
  Given future capability HLDs will need SketchUp-facing behavior
  When they are planned against the platform
  Then they can depend on shared adapter and serializer boundaries
  And they do not need to invent new low-level ownership patterns
```

## Non-Goals

- implementing new semantic, asset, or validation capabilities
- moving SketchUp-facing behavior into Python
- prescribing every future helper module before it is needed

## Business Constraints

- Ruby must remain the home of all SketchUp-facing behavior
- the adapter boundary must support growth across multiple capability areas
- the task must make future capability work safer to review and test

## Technical Constraints

- the extracted boundaries must align with the revised platform HLD
- serialization must preserve existing bridge compatibility where behavior is already exposed
- adapter ownership must remain compatible with later SketchUp-hosted verification

## Dependencies

- `PLAT-01`

## Relationships

- blocks capability work that depends on reusable SketchUp adapters
- blocks `PLAT-05`
- informs `PLAT-06`

## Related Technical Plan

- [Technical Plan](./plan.md)

## Success Metrics

- common SketchUp-facing concerns have an explicit adapter or serializer owner
- transport and command layers no longer own most reusable API-heavy helpers directly
- future capability planning can reference adapter contracts instead of ad hoc extraction work
