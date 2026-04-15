# Task: SEM-04 Align Tree Proxy Geometry With Accepted Volumetric Baseline
**Task ID**: `SEM-04`
**Title**: `Align Tree Proxy Geometry With Accepted Volumetric Baseline`
**Status**: `completed`
**Priority**: `P0`
**Date**: `2026-04-15`

## Linked HLD

- [Semantic Scene Modeling](../../../hlds/hld-semantic-scene-modeling.md)

## Problem Statement

`SEM-02` established `tree_proxy` as part of the first-wave semantic creation vocabulary, but the shipped proxy geometry still leaves an important fidelity gap. The accepted baseline tree proxy used for workflow validation is not a flat billboard, a single crowned extrusion, or a set of disconnected canopy blobs. It is a connected volumetric proxy with a 12-sided trunk and stepped canopy bands that read like one coherent specimen mass.

That gap matters because `tree_proxy` is meant to keep baseline planting and existing-tree workflows semantic rather than forcing primitive fallback or ad hoc manual cleanup. If the proxy silhouette or topology drifts too far from the accepted baseline, the semantic constructor technically supports `tree_proxy` while still producing geometry that is materially weaker than the workflow-approved reference.

This task captures the accepted geometry baseline and defines the follow-up requirements for aligning live `tree_proxy` output with that accepted volumetric reference while preserving a parameter-driven public size contract.

## Goals

- align live `tree_proxy` output with the accepted volumetric baseline rather than a simplified disconnected proxy shape
- preserve dynamic public sizing through `height`, `canopyDiameterX`, `canopyDiameterY`, and `trunkDiameter`
- keep the public `create_site_element(elementType: "tree_proxy")` contract stable while tightening geometry expectations in Ruby-owned builder behavior

## Acceptance Criteria

```gherkin
Scenario: tree_proxy matches the accepted volumetric baseline characteristics
  Given the semantic creation surface already supports `tree_proxy`
  When the delivered Ruby builder output is reviewed against the accepted baseline captured for this task
  Then the proxy is a connected volumetric mass rather than a flat, disconnected, or single-primitive canopy
  And the trunk is represented as a 12-sided prism connected into the canopy mass
  And the canopy reads as stepped ring bands and capped lobes rather than one smooth sphere or one simple extrusion

Scenario: tree_proxy remains parameter-driven in public dimensions
  Given `tree_proxy` accepts `height`, `canopyDiameterX`, `canopyDiameterY`, and `trunkDiameter` through the public semantic request
  When representative requests vary those public dimensions
  Then the resulting proxy scales coherently in height and canopy width without breaking the connected volumetric silhouette
  And the task does not redefine the public size fields into a fixed-size-only proxy

Scenario: accepted baseline evidence is captured in task-owned requirements
  Given the accepted tree proxy geometry was extracted from a reviewed SketchUp specimen on 2026-04-15
  When this task is reviewed later for planning or implementation
  Then the task contains the baseline geometric signature needed to evaluate conformance
  And reviewers do not need to reconstruct the acceptance target from chat history alone

Scenario: geometry refinement preserves semantic architecture boundaries
  Given `tree_proxy` behavior is Ruby-owned semantic geometry
  When this refinement task is implemented
  Then geometry ownership remains in Ruby
  And Python remains a thin MCP adapter without duplicated tree-shape logic or independent geometry rules

Scenario: refinement lands with builder-level and workflow-level verification
  Given this task changes shipped semantic geometry behavior without changing the public tool name
  When the task is completed
  Then Ruby-side tests cover deterministic tree_proxy geometry invariants and dynamic scaling expectations
  And manual or SketchUp-hosted verification confirms the refined silhouette against the accepted baseline
```

## Non-Goals

- redesigning the public `create_site_element` request shape for semantic creation
- introducing species-specific procedural generation or a broader tree-style taxonomy
- replacing `tree_proxy` with staged assets, curated assets, or `tree_instance`
- moving semantic geometry interpretation from Ruby into Python

## Business Constraints

- `tree_proxy` must remain useful for baseline site modeling and approximate existing-tree workflows rather than becoming a nominally supported but visually misleading placeholder
- the accepted geometry baseline must be durable enough for later planning, review, and implementation without depending on ephemeral discussion context
- the refinement must preserve the workflow value of fast semantic creation instead of turning proxy trees into asset-backed high-fidelity content

## Technical Constraints

- Ruby must continue to own `tree_proxy` geometry behavior, parameter interpretation, and deterministic output
- Python must remain limited to MCP tool definition, request validation, bridge forwarding, and result mapping
- the public `create_site_element` tool name and payload contract should remain stable unless a separate contract change is approved
- the task must preserve parameter-driven scaling for public size fields even while tightening topology and silhouette expectations
- verification should focus on builder-level structural invariants and SketchUp-hosted or manual geometry confirmation rather than Python-side geometry duplication

## Dependencies

- `SEM-02`

## Relationships

- informs deferred tree proxy replacement and staged-asset upgrade work
- informs future tree-style or species-specific proxy refinement work if those are later approved

## Related Technical Plan

- [Technical Plan](./plan.md)

## Success Metrics

- task reviewers can identify one stable accepted tree-proxy baseline from the task artifact alone
- follow-up implementation can be evaluated against explicit volumetric, connected-mass, and dynamic-scaling requirements instead of ad hoc visual preference
- the eventual refinement can be verified without changing the public semantic creation contract

## Reference Geometry Baseline

Accepted baseline extracted on `2026-04-15` from SketchUp model `TestGround.skp`:

- wrapper name: `PRJ-VEG-020-southeast-path-tree-baseline`
- wrapper persistent id: `53910`
- accepted proxy child type: `Group`
- accepted proxy child persistent id: `54192`
- units: raw geometry in SketchUp internal inches, semantic reference in meters

Selective accepted geometry signature:

- bounds size in meters: `[2.799994, 3.730549, 1.950491]`
- face / edge / vertex counts: `256 / 482 / 234`
- trunk begins at `z = 5.519461 m` and reaches a trunk-top cap at `z = 8.027479 m`
- canopy apex reaches `z = 9.250000 m`
- representative canopy tiers in meters: `[7.200000, 7.250000, 7.300000, 7.349031, 7.519461, 7.575000, 7.626510, 7.650000, 7.950000, 8.000000, 8.325000, 8.350000, 8.472521, 8.599519, 8.700000, 8.873490, 9.150969, 9.250000]`

Accepted qualitative notes:

- the proxy is not a flat billboard
- the proxy is a connected volumetric mesh with repeated ring tiers
- the trunk is a 12-sided prism
- the canopy builds through stepped ring bands and capped lobes
- the accepted mass reads like one connected specimen proxy rather than separated trunk and crown primitives
