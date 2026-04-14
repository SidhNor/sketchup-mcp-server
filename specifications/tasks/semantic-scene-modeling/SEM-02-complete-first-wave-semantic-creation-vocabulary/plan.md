# Technical Plan: SEM-02 Complete First-Wave Semantic Creation Vocabulary
**Task ID**: `SEM-02`
**Title**: `Complete First-Wave Semantic Creation Vocabulary`
**Status**: `planned`
**Date**: `2026-04-14`

## Source Task

- [Complete First-Wave Semantic Creation Vocabulary](./task.md)

## Problem Summary

`SEM-02` completes the remaining first-wave semantic creation surface on top of the `SEM-01` semantic core. The task must extend `create_site_element` to support `path`, `retaining_edge`, `planting_mass`, and `tree_proxy` without reopening the public command contract, fragmenting the public tool surface, or leaking semantic behavior into Python. The resulting slice must preserve the `SEM-01` managed-object envelope, Ruby-owned builder registry, metadata ownership, structured refusal posture, and shared Python/Ruby contract model.

## Goals

- Extend `create_site_element` to support `path`, `retaining_edge`, `planting_mass`, and `tree_proxy` through the existing semantic command path.
- Preserve the `SEM-01` public semantic envelope, one public tool surface, one managed-object contract, and one refusal/result shape.
- Keep Ruby as the owner of per-type normalization, geometry creation, metadata writes, refusal behavior, and JSON-safe serialization.
- Land the expansion with Ruby tests, Python tests, and shared contract coverage in the same change.
- Deliver a lightweight but visually meaningful `tree_proxy` with a deterministic low-poly clustered canopy rather than a box or single regular canopy primitive.

## Non-Goals

- Redesigning the public `create_site_element` contract into the guide-style nested `geometry` / `metadata` envelope.
- Redefining the `SEM-01` managed-object model, wrapper posture, or shared result envelope.
- Delivering `set_entity_metadata`, identity-preserving rebuild or replacement, or generic mutation compatibility policy.
- Adding terrain-aware placement, ground snapping, grading behavior, or `sample_surface_z` integration to semantic creation.
- Introducing species-specific procedural tree generation, asset instancing, or next-wave semantic families.

## Related Context

- [Semantic Scene Modeling HLD](specifications/hlds/hld-semantic-scene-modeling.md)
- [Semantic Scene Modeling PRD](specifications/prds/prd-semantic-scene-modeling.md)
- [Domain Analysis](specifications/domain-analysis.md)
- [SEM-01 Technical Plan](specifications/tasks/semantic-scene-modeling/SEM-01-establish-semantic-core-and-first-vertical-slice/plan.md)
- [Semantic Scene Modeling Task Set](specifications/tasks/semantic-scene-modeling/README.md)
- [Contract Artifact](contracts/bridge/bridge_contract.json)
- [Grok Contract-Change Signal](specifications/signals/2026-04-14-sem-02-grok-contract-change-signal.md)

## Research Summary

- The current repo has the right platform seams for this task: Python capability modules, a shared bridge client, Ruby request normalization, stable tool dispatch, and shared contract-test infrastructure.
- No landed semantic implementation was visible during planning, so `SEM-01` should be treated as the design baseline rather than assumed delivered code.
- The HLD supports one public semantic constructor backed by a registry with strict per-element sub-schemas; it does not require a public contract redesign in `SEM-02`.
- The guide contains useful shape examples for the four remaining first-wave types, but its richer nested contract should remain a deferred contract decision rather than part of this task.
- Existing bridge error handling still collapses remote errors into message-based Python exceptions, so semantic refusals should remain domain outcomes in the successful result envelope.
- The current targeting tests and fake SketchUp support already provide reusable patterns for metadata access, identifier normalization, contract testing, and Ruby-side scene behavior tests.

## Technical Decisions

### Data Model

- `SEM-02` preserves the `SEM-01` outer request envelope:
  - `elementType`
  - `sourceElementId`
  - `status`
  - optional `name`
  - optional `tag`
  - optional `material`
- `elementType` remains the public discriminator and uses the semantic type strings already established by the task and PRD:
  - `path`
  - `retaining_edge`
  - `planting_mass`
  - `tree_proxy`
- Each request must contain exactly one matching type payload section whose key is identical to `elementType`:
  - `path`
  - `retaining_edge`
  - `planting_mass`
  - `tree_proxy`
- Requests that omit the matching type payload section or include additional mismatched type payload sections must be refused with `missing_element_payload` or `contradictory_payload`.
- Ruby owns normalization from the outer request plus matching payload section into the internal builder input, including defaulting behavior.
- The normative MVP payloads for `SEM-02` are:

```json
{
  "elementType": "path",
  "sourceElementId": "main-walk-001",
  "status": "proposed",
  "name": "Main Walk",
  "material": "gravel_light",
  "path": {
    "centerline": [[0.0, 0.0], [4.0, 1.0], [8.0, 1.0]],
    "width": 1.6,
    "elevation": 0.0,
    "thickness": 0.1
  }
}
```

```json
{
  "elementType": "retaining_edge",
  "sourceElementId": "ret-edge-001",
  "status": "proposed",
  "retaining_edge": {
    "polyline": [[2.0, 0.0], [8.0, 0.0], [8.0, 4.0]],
    "height": 0.45,
    "thickness": 0.25,
    "elevation": 0.0
  }
}
```

```json
{
  "elementType": "planting_mass",
  "sourceElementId": "hedge-001",
  "status": "proposed",
  "planting_mass": {
    "boundary": [[0.0, 0.0], [4.0, 0.0], [4.0, 2.0], [0.0, 2.0]],
    "averageHeight": 1.8,
    "plantingCategory": "hedge",
    "elevation": 0.0
  }
}
```

```json
{
  "elementType": "tree_proxy",
  "sourceElementId": "tree-001",
  "status": "retained",
  "tree_proxy": {
    "position": {
      "x": 14.0,
      "y": 37.7,
      "z": 0.0
    },
    "canopyDiameterX": 6.0,
    "canopyDiameterY": 5.6,
    "height": 5.5,
    "trunkDiameter": 0.45,
    "speciesHint": "cherry"
  }
}
```

- Validation rules for `path`:
  - `centerline` must contain at least 2 distinct XY points after normalization
  - `width` must be finite and strictly greater than `0`
  - `thickness`, when present, must be finite and strictly greater than `0`
  - `elevation`, when present, must be finite
  - `elevation` means the top-surface Z reference
- Validation rules for `retaining_edge`:
  - `polyline` must contain at least 2 distinct XY points after normalization
  - `height` must be finite and strictly greater than `0`
  - `thickness` must be finite and strictly greater than `0`
  - `elevation`, when present, must be finite
  - `elevation` means the base Z reference
- Validation rules for `planting_mass`:
  - `boundary` must follow the same polygon rules established by `SEM-01` for `footprint`
  - at least 3 distinct points after normalization
  - no consecutive duplicate points after normalization
  - non-zero polygon area
  - no self-intersection
  - a repeated closing point may be normalized away
  - `averageHeight` must be finite and strictly greater than `0`
  - `elevation`, when present, must be finite
  - `elevation` means the base Z reference
- Validation rules for `tree_proxy`:
  - `position.x`, `position.y`, and optional `position.z` must be finite
  - `position.z`, when omitted, defaults in Ruby to `0.0`
  - `canopyDiameterX` must be finite and strictly greater than `0`
  - `canopyDiameterY`, when omitted, defaults in Ruby to `canopyDiameterX`
  - `canopyDiameterY`, when present, must be finite and strictly greater than `0`
  - `height` must be finite and strictly greater than `0`
  - `trunkDiameter` must be finite and strictly greater than `0`
  - `trunkDiameter` must be less than the effective minimum canopy diameter
- `planting_mass` stays polygon-only for `SEM-02`; ellipse or richer shape unions are deferred.
- All new types persist the shared minimum metadata established by `SEM-01`:
  - `managedSceneObject = true`
  - `sourceElementId`
  - `semanticType`
  - `status`
  - `state = Created`
  - `schemaVersion = 1`
- No additional hard metadata invariants are introduced for the new types in `SEM-02`; optional fields such as `speciesHint` and `plantingCategory` remain semantic attributes rather than required invariants.

### API and Interface Design

- Python exposes the same public tool, `create_site_element`, through a dedicated semantic tool module and keeps the MCP layer mechanical.
- Python uses a discriminated request shape keyed by `elementType` for type and shape validation only.
- Python must not interpret geometry semantics, choose builders, infer defaults beyond obvious optional field handling, or duplicate Ruby refusal policy.
- Python validates:
  - presence of the required outer-envelope fields
  - presence of the one matching type payload section
  - basic field types for the matching payload section
- Python does not validate semantic geometry rules such as polygon area, self-intersection, minimum distinct-point counts after normalization, or cross-field numeric relationships.
- Ruby extends the semantic command support tree established by `SEM-01`:
  - semantic command entrypoint
  - builder registry
  - one builder per new type
  - shared metadata helper
  - shared semantic serializer
  - shared normalization helpers for polygonal and linear payloads where useful
- The builder registry remains the only semantic extension point. `semantic_commands.rb` should not grow new ad hoc branching for each type.
- Each builder should conform to one explicit interface:
  - input: normalized semantic payload for its `elementType`
  - output: one top-level managed `Sketchup::Group`
  - responsibilities: geometry creation only for its type, delegation to shared metadata persistence, and no direct response-envelope shaping
- All new builders return one top-level managed `Sketchup::Group`.
- `tree_proxy` geometry is Ruby-owned and deterministic:
  - simple trunk prism
  - one primary low-poly canopy crown
  - two smaller offset canopy lobes to create a more tree-like silhouette
  - fixed canopy and lobe proportions defined in Ruby capability-local constants
  - fixed lobe offsets defined in Ruby capability-local constants
  - no randomness
  - no species-specific geometry logic in `SEM-02`
- The `managedObject` result envelope stays consistent with `SEM-01` and should expose only minimal type-specific fields:
  - `path`: `width`, `thickness` when present
  - `retaining_edge`: `height`, `thickness`
  - `planting_mass`: `averageHeight`, `plantingCategory` when present
  - `tree_proxy`: `height`, `canopyDiameterX`, `canopyDiameterY`, `trunkDiameter`, `speciesHint` when present
- The response should not echo full input geometry arrays such as `centerline`, `polyline`, or `boundary` in `SEM-02`.

### Error Handling

- Python boundary errors should be limited to malformed MCP argument types or missing required top-level tool arguments.
- Ruby returns structured semantic refusals in the successful result envelope for domain-invalid but well-formed requests.
- Use one shared refusal taxonomy across the semantic slice:
  - `unsupported_element_type`
  - `missing_element_payload`
  - `missing_required_field`
  - `invalid_geometry`
  - `invalid_numeric_value`
  - `contradictory_payload`
  - `unsupported_option`
- Refusals should cover at least:
  - unsupported `elementType`
  - missing payload section for the chosen semantic type
  - insufficient points in `centerline`, `polyline`, or `boundary`
  - invalid or non-finite numeric dimensions
  - negative or zero dimensions where prohibited
  - payload sections that do not match `elementType`
  - unsupported convenience inputs deferred from MVP
- `SEM-02` should align its refusal codes with the semantic refusal posture established by `SEM-01`; if `SEM-01` uses a narrower refusal code set when implemented, the shared contract artifact should be updated so the whole semantic slice exposes one coherent taxonomy.
- Transport failures, malformed bridge responses, and unexpected Ruby exceptions remain on the JSON-RPC error path and should not be repurposed for domain refusals.

### State Management

- The SketchUp model remains the source of truth for semantic object state.
- `SEM-02` extends only creation-time semantic state and does not introduce new lifecycle transitions.
- Each builder creates the geometry, delegates metadata persistence to the shared metadata helper, and returns the resulting wrapper group for serialization.
- Managed-object identity remains attached to the top-level wrapper group through the `su_mcp` attribute dictionary.

### Integration Points

- Python semantic tool -> shared `BridgeClient.call_tool(...)` -> Ruby request handler -> Ruby tool dispatcher -> Ruby semantic command.
- Ruby semantic command -> one SketchUp operation boundary -> semantic registry -> type-specific builder -> shared metadata helper -> shared semantic serializer.
- Contract alignment must remain explicit across:
  - Python MCP tool shape
  - Ruby dispatcher tool name
  - Ruby result envelope
  - shared contract artifact
  - Python contract suite
  - Ruby contract suite
- `SEM-02` depends on the `SEM-01` semantic core; if `SEM-01` is not yet implemented when work begins, implementation must first establish that missing baseline rather than building a parallel semantic path.

### Configuration

- `SEM-02` introduces no new runtime configuration.
- No user-configurable canopy complexity, planting style catalogs, or terrain-coupling modes are added in this task.
- Any constants needed for deterministic proxy geometry, such as canopy lobe offsets or trunk-height ratios, should live in Ruby capability-local code rather than external configuration.

## Architecture Context

```mermaid
flowchart TD
    Client[MCP Client]
    PySemantic[Python semantic tool adapter]
    PyBridge[Python BridgeClient]
    Boundary{{Python / Ruby bridge boundary}}
    RubyHandler[Ruby request handler and tool dispatcher]
    SemanticCmd[Ruby semantic command]
    Operation[SketchUp operation boundary]
    Registry[Semantic builder registry]
    PolygonHelpers[Shared polygon and linear normalization helpers]
    PathBuilder[Path builder]
    RetainingBuilder[Retaining edge builder]
    PlantingBuilder[Planting mass builder]
    TreeBuilder[Tree proxy builder]
    Metadata[Managed object metadata helper]
    Serializer[Semantic serializer]
    SketchUp[(SketchUp model)]

    Client --> PySemantic
    PySemantic --> PyBridge
    PyBridge --> Boundary
    Boundary --> RubyHandler
    RubyHandler --> SemanticCmd
    SemanticCmd --> Operation
    Operation --> Registry
    Registry --> PathBuilder
    Registry --> RetainingBuilder
    Registry --> PlantingBuilder
    Registry --> TreeBuilder
    PathBuilder --> PolygonHelpers
    RetainingBuilder --> PolygonHelpers
    PlantingBuilder --> PolygonHelpers
    TreeBuilder --> Metadata
    PathBuilder --> Metadata
    RetainingBuilder --> Metadata
    PlantingBuilder --> Metadata
    Metadata --> SketchUp
    Metadata --> Serializer
    Serializer --> Boundary

    PySemantic -. Python tool tests .- PySemantic
    PyBridge -. Python contract tests .- Boundary
    RubyHandler -. Ruby contract tests .- Boundary
    Registry -. Ruby behavior tests .- PathBuilder
    Registry -. Ruby behavior tests .- RetainingBuilder
    Registry -. Ruby behavior tests .- PlantingBuilder
    Registry -. Ruby behavior tests .- TreeBuilder
    Metadata -. Ruby behavior tests .- Metadata
    Serializer -. Ruby behavior tests .- Serializer
    Operation -. SketchUp-hosted or manual verification .- SketchUp
```

## Key Relationships

- Python stays responsible for MCP registration and shape validation only; Ruby owns all semantic interpretation and SketchUp-facing behavior.
- The builder registry remains the semantic extension seam, so new first-wave types do not force public tool sprawl or transport-adjacent branching.
- Metadata persistence and serialization remain centralized so builder geometry code does not accumulate cross-cutting managed-object rules.
- `tree_proxy` geometry complexity belongs in Ruby builder code, not in the public payload or Python adapter.
- Real integration must still be validated at the SketchUp operation boundary because undo behavior and geometry outcomes cannot be proven by mocks alone.

## Acceptance Criteria

- `create_site_element` accepts `path`, `retaining_edge`, `planting_mass`, and `tree_proxy` through the existing semantic command path without introducing new public creation tools.
- Each new semantic type accepts the documented `SEM-02` payload section for its MVP inputs and returns either a created managed-object result or a structured refusal.
- The Python MCP layer validates only boundary shape and type information for the expanded semantic request surface and continues to forward requests to Ruby without semantic branching.
- The Ruby semantic registry dispatches all four new types through dedicated builders without concentrating new per-type logic in transport-adjacent files or one large command-level case analysis.
- Successful creation for each new type writes the shared minimum semantic metadata keys to the wrapper group in the `su_mcp` dictionary.
- The shared semantic serializer returns one stable `managedObject` envelope for all new types with core identity fields and the agreed minimal type-specific fields.
- Requests with unsupported types, missing payload sections, invalid geometry, invalid numeric values, or contradictory payloads return structured refusals using the shared semantic refusal taxonomy.
- `tree_proxy` creates a lightweight deterministic proxy with a simple trunk and a low-poly clustered canopy consisting of one primary crown and two secondary lobes, rather than a box or single regular canopy primitive.
- The shared contract artifact and both native contract suites are updated together for the expanded semantic surface.
- Ruby tests, Python tests, and contract tests cover the delivered request and response behavior for the new types, and any remaining SketchUp-hosted verification gaps are explicitly documented.

## Test Strategy

### TDD Approach

Implement `SEM-02` contract-first and builder-by-builder:

1. Add failing shared contract cases for the four new semantic types and refusal outcomes.
2. Add failing Python schema and passthrough tests for the expanded `create_site_element` boundary.
3. Add failing Ruby dispatcher, registry-routing, metadata, and serializer tests for the new semantic surface.
4. Implement shared normalization helpers only where they clearly remove duplicated builder logic.
5. Implement one builder at a time in ascending coupling order:
   1. `planting_mass`
   2. `tree_proxy`
   3. `path`
   4. `retaining_edge`
6. Run contract suites, unit tests, and language-appropriate linting, then document any remaining SketchUp-hosted verification gaps.

### Required Test Coverage

- Python tool tests for:
  - semantic tool registration and ordering
  - discriminated request shape by `elementType`
  - request passthrough and `request_id` propagation
  - rejection of missing or wrongly typed matching payload sections
- Python contract tests for:
  - shared artifact parity for new created cases
  - refusal outcomes remaining in the successful result envelope
- Ruby tests for:
  - dispatcher mapping for `create_site_element`
  - registry dispatch for all four new types
  - payload normalization and required-field handling
  - geometry validation for `centerline`, `polyline`, and `boundary`
  - numeric validation for widths, heights, thicknesses, canopy diameters, and trunk diameters
  - metadata persistence to `su_mcp`
  - shared serializer output and identifier normalization
  - deterministic `tree_proxy` geometry shape expectations at the builder level, including stable structural invariants such as expected canopy sub-mass count or equivalent builder-owned geometry assertions
  - refusal outcomes for missing payloads, invalid geometry, invalid numeric values, and contradictory payloads
- Contract artifact updates for at least:
  - one created case per new semantic type
  - one refusal case using the shared taxonomy
- SketchUp-hosted or manual verification for:
  - one-operation undo behavior
  - representative geometry outcomes for each new type
  - visual confirmation that `tree_proxy` produces the intended clustered canopy silhouette

## Implementation Phases

1. Extend the semantic boundary shell.
   Add Python schema coverage, dispatcher mapping, registry routing, and shared contract cases for the four new semantic types.
2. Extend shared semantic support.
   Add or refine shared normalization helpers, metadata handling, and serializer support only where the new types need them.
3. Implement polygonal builders.
   Land `planting_mass` first, then `tree_proxy`, keeping both on the shared wrapper-group and metadata path.
4. Implement linear builders.
   Land `path`, then `retaining_edge`, reusing linear normalization helpers and the shared refusal model.
5. Tighten verification and close the task.
   Run Python and Ruby tests, both contract suites, Ruff, RuboCop, and record any remaining SketchUp-hosted verification gaps.

## Risks and Mitigations

- The semantic command regresses into a large per-type dispatcher: keep the registry as the only builder extension seam and cover routing in tests.
- Python starts accumulating semantic policy: keep Python validation limited to shape and type checks and verify passthrough behavior directly in tests.
- Linear geometry logic becomes duplicated across `path` and `retaining_edge`: isolate only clearly shared normalization and offset helpers instead of copying logic between builders.
- The `tree_proxy` canopy becomes visually weak or overly heavy: use deterministic clustered low-poly geometry with fixed ratios and test its builder output directly.
- Refusal behavior diverges between types: keep one shared refusal taxonomy and require shared contract cases to exercise it.
- `SEM-01` is not yet implemented when `SEM-02` starts: treat the semantic core as a prerequisite and do not build an alternate semantic surface.
- SketchUp operation behavior is assumed rather than proven: require explicit manual or SketchUp-hosted verification notes for undo and final geometry posture.

## Dependencies

- [SEM-01 Technical Plan](specifications/tasks/semantic-scene-modeling/SEM-01-establish-semantic-core-and-first-vertical-slice/plan.md)
- Implemented platform seams from [PLAT-02 Extract Ruby SketchUp Adapters and Serializers](specifications/tasks/platform/PLAT-02-extract-ruby-sketchup-adapters-and-serializers/task.md)
- Implemented Python decomposition from [PLAT-03 Decompose Python MCP Adapter](specifications/tasks/platform/PLAT-03-decompose-python-mcp-adapter/task.md)
- Targeting metadata precedent from [STI-01 Targeting MVP and `find_entities`](specifications/tasks/scene-targeting-and-interrogation/STI-01-targeting-mvp-and-find-entities/task.md)
- Semantic capability rules from [Semantic Scene Modeling HLD](specifications/hlds/hld-semantic-scene-modeling.md)
- Product contract from [Semantic Scene Modeling PRD](specifications/prds/prd-semantic-scene-modeling.md)
- Domain vocabulary and lifecycle terminology from [Domain Analysis](specifications/domain-analysis.md)
- Shared bridge contract artifact and native contract suites
- SketchUp runtime availability for geometry and undo verification

## Quality Checks

- [x] All required inputs validated
- [x] Problem statement documented
- [x] Goals and non-goals documented
- [x] Research summary documented
- [x] Technical decisions included
- [x] Architecture context included
- [x] Acceptance criteria included
- [x] Test requirements specified
- [x] Risks and dependencies documented
- [x] Small reversible phases defined
- [x] Plan created
