# HLD: Semantic Scene Modeling

## System Overview

### Purpose

This HLD covers the implementation approach for the capability defined in [`../prds/prd-semantic-scene-modeling.md`](../prds/prd-semantic-scene-modeling.md).

It focuses on:

- semantic creation through `create_site_element`
- Managed Scene Object identity and metadata invariants
- metadata mutation through `set_entity_metadata`
- revision-safe semantic lifecycle boundaries
- first-wave semantic builders for site and structure objects plus future semantic-family extension

This is a capability HLD, not a platform HLD. Shared runtime structure, bridge transport, packaging, and cross-cutting runtime conventions remain in [`hld-platform-architecture-and-repo-structure.md`](./hld-platform-architecture-and-repo-structure.md).

The architecture and contract for scene targeting, collection lookup, and geometry interrogation remain in [`hld-scene-targeting-and-interrogation.md`](./hld-scene-targeting-and-interrogation.md). This HLD consumes those capabilities where semantic workflows need lookup, but it does not redefine their internal design.

### Capability Intent

This capability replaces primitive-first modeling with a compact semantic surface for site and small-structure workflows that creates and updates Managed Scene Objects as durable workflow units. The key architectural job is not just to generate geometry. It is to ensure that created objects carry stable business identity, required metadata, and revision-safe lifecycle behavior from the moment they enter the SketchUp scene.

### Capability Scope

The architecture in this HLD is centered on:

- `create_site_element`
- `set_entity_metadata`
- Managed Scene Object metadata storage and invariant enforcement
- semantic serialization for Managed Scene Objects
- hierarchy-aware lifecycle behavior for Managed Scene Objects inside nested scene structure
- compatibility boundaries for existing mutation tools such as `transform_component` and `set_material`
- identity-preserving rebuild or replacement support for semantic revision flows

The current PRD first wave centers on these semantic element types:

- `structure`
- `pad`
- `path`
- `retaining_edge`
- `planting_mass`
- `tree_proxy`

The architecture should support those first-wave types directly without assuming they are the final durable semantic family set. `structure` is now a first-wave semantic type and should cover common built-form cases such as houses, sheds, and house extensions through a documented footprint-based contract. `pad` remains the semantic home for surface-first hardscape and platform-like cases, including raised platforms expressed through standardized elevation and thickness semantics, and it should not become the implicit catch-all for enclosed built structures.

### Out of Scope

This HLD does not define:

- bridge transport or repository structure policy
- the internal architecture of `find_entities`, `get_named_collections`, `sample_surface_z`, or `analyze_edge_network`
- Asset Exemplar protection, staging, or instancing policy
- validation pass or fail policy
- task sequencing or implementation milestones
- broad scene inspection helpers such as `get_scene_info`, `list_entities`, or `get_entity_info`

## Architecture Approach

### Core Approach

Implement semantic scene modeling as a focused Ruby command slice built around:

- public semantic commands
- a stateless Managed Scene Object metadata and invariant layer
- a registry-backed builder layer with strict per-element payload sub-schemas
- a serializer or decorator for Managed Scene Object output
- explicit SketchUp operation boundaries for undo-safe semantic mutation

The design should stay intentionally concrete:

- `create_site_element` remains one compact public semantic constructor
- element-specific geometry behavior lives behind internal builders, not separate public tools
- Managed Scene Object truth lives on SketchUp entities through capability-owned metadata, not in long-lived Ruby memory
- semantic lifecycle behavior must remain valid for managed objects nested inside grouped scene structure, not only for top-level objects
- semantic revision and replacement preserve business identity through explicit metadata handoff rules
- Python remains a thin MCP adapter over Ruby-owned semantic behavior

### Contract Evolution and Migration Posture

The semantic creation surface should evolve through one durable public constructor rather than through tool proliferation.

The current architecture should therefore treat `create_site_element` as one stable public entrypoint that may carry more than one contract generation over time, while keeping the migration burden inside Ruby.

This posture does not ratify the newer sectioned request shape as a final public contract. It only establishes that the direction is strong enough to guide architecture and migration planning.

Current implementation evidence from `SEM-05` strengthens this posture:

- bounded `contractVersion: 2` handling now survives the live Ruby semantic seam for representative hard cases
- Ruby can validate, normalize, resolve targets, and execute the chosen lifecycle flows without Python or bridge-contract changes
- the strongest current overlap remains the command-level translation from a sectioned `v2` request shape into the current builder-facing payload shape

That leads to an explicit migration rule for this capability:

- Python and the shared bridge contract should remain unchanged until builder-native `v2` support is justified
- the current `v2` Ruby seam should be treated as seeded migration infrastructure, not as throwaway spike code
- the next architectural step is builder-native acceptance of the sectioned `v2` shape one family at a time
- the command-level translation layer should be treated as transitional architecture, not the intended end state

### Atomic Creation Versus Composition Posture

This capability should keep atomic semantic creation separate from composite feature assembly.

- `create_site_element` should remain the home for atomic Managed Scene Object creation and lifecycle-safe adoption or replacement of supported atomic objects
- grouped or multipart site features should be composed through dedicated grouping, duplication, and hierarchy-editing flows rather than being forced into one oversized atomic creation contract
- this keeps the semantic creation contract durable while allowing larger features to be assembled from atomic managed objects

### Semantic Type Boundary Posture

The semantic boundary between `pad` and `structure` should be explicit in the architecture rather than left to builder-by-builder interpretation.

- `pad` should remain the semantic home for surface-first hardscape or slab-like objects where the workflow intent is primarily footprint, finish, and elevation treatment.
- `pad` should also remain the semantic home for platform-like elements, including decks and raised platforms, where the workflow intent is still surface-first and the vertical interpretation is expressed through documented height or thickness semantics.
- `structure` should be the semantic home for enclosed or clearly building-like built forms that need stronger built-object identity than a surface-only semantic type provides.
- Representative examples such as concrete terraces, decks, raised platforms, sheds, houses, and house extensions should be classified consistently by the documented semantic boundary rather than by whichever builder happens to accept the payload first.
- When an input remains semantically ambiguous between `pad` and `structure`, the capability should prefer a structured refusal over implicit type guessing unless the request explicitly resolves the intended type.

### Current-State Posture

The current repository already has the correct runtime split and several platform seams this capability should reuse:

- Ruby request handling, tool dispatch, and shared adapter or serializer support
- Python tool-module registration and shared bridge invocation
- contract-test foundations for the Python/Ruby boundary

The current repository now has a first implemented semantic slice, including the initial `create_site_element` and `set_entity_metadata` posture plus the bounded `SEM-05` contract-evolution spike.

What the repository still does not yet have is a fully migrated semantic architecture across all families and layers. Important parts of the current state remain transitional:

- `create_component`
- `transform_component`
- `set_material`
- `delete_component`

This HLD therefore describes how the capability should continue to evolve on the current platform seams. It should not encourage adding semantic behavior back into transport-adjacent files such as `socket_server.rb` as the long-term design.

### Boundary Posture

- Ruby owns semantic payload normalization, builder selection, metadata writes, identity preservation, operation bracketing, and SketchUp-facing serialization.
- Python owns MCP tool registration, argument-shape validation, bridge invocation, and MCP-facing error mapping.
- The targeting and interrogation slice owns generic lookup and scene-targeting mechanics. Semantic modeling owns semantic metadata conventions and may depend on targeting outputs, but it must not define a second lookup subsystem.
- Asset reuse owns exemplar-specific replacement, protection, and instancing rules. Semantic modeling may define identity-preserving replacement behavior for Managed Scene Objects without absorbing asset-library policy.
- The SketchUp model is the source of truth for managed-object state. Ruby helpers may interpret and enforce metadata rules, but they should not rely on long-lived in-memory registries of Managed Scene Objects.

### Managed Scene Object Posture

Managed Scene Objects should be defined by a dedicated capability-owned metadata namespace on the SketchUp entity or wrapper that represents the object. That metadata is the durable source of truth for:

- MCP management status
- `sourceElementId`
- semantic type and role
- required structure subtype or category where the managed object is a `structure`
- lifecycle or status fields
- provenance and replaceability fields that are part of the documented semantic contract

This HLD should treat semantic metadata in two categories:

- hard invariants that cannot be broken silently once the object is managed
- soft fields that may be updated through supported semantic metadata flows

Managed Scene Objects should also remain maintainable when they sit inside nested groups or components used for scene organization. That means semantic lifecycle behavior must preserve intended parent placement and scene context during supported metadata updates, regrouping, duplication, rebuild, or replacement flows rather than silently flattening or relocating managed objects.

### Hierarchy-Aware Lifecycle Posture

Nested scene structure is a normal organization mechanism in the product domain, not an edge case. The semantic capability should therefore assume that many Managed Scene Objects may live below the top level inside grouped scene hierarchy used for accepted-scene management.

This does not mean semantic modeling should absorb a second scene-query subsystem or broad workflow orchestration rules. It means supported semantic lifecycle flows must:

- resolve managed targets correctly when they are nested
- preserve existing parent placement when the operation is an in-place metadata or compatibility-safe mutation
- make parent reassignment explicit when a future lifecycle operation intentionally reparents or replaces an object
- return structured refusal when a requested hierarchy-affecting change would violate identity or managed-object invariants

The smallest planned first-class lifecycle primitives for this area are:

- inspect active edit context
- reparent
- duplicate into a target parent while preserving metadata and geometry
- replace with identity handoff

Those primitives remain follow-on semantic lifecycle work rather than being folded into metadata mutation by default.

### Undo and Atomicity Posture

Semantic create, metadata update, and identity-preserving rebuild flows should execute inside one SketchUp operation boundary so they appear as one undo step and can roll back coherently on failure.

This is a capability-level requirement, not an incidental implementation detail. If a semantic flow writes metadata, creates geometry, swaps representations, or hands off identity, those steps should succeed or fail as one operation from the model's perspective.

## Component Breakdown

### 1. Python MCP Tool Adapters

**Responsibilities**

- expose `create_site_element` and `set_entity_metadata`
- validate basic argument shape and type information at the MCP boundary
- forward semantic requests over the existing bridge with minimal transformation
- surface transport and bridge failures as structured MCP errors

**Must Not Own**

- semantic schema interpretation beyond boundary validation
- metadata invariant policy
- geometry creation behavior
- identity-preserving rebuild logic

### 2. Ruby Semantic Commands

**Responsibilities**

- provide Ruby execution entrypoints for `create_site_element` and `set_entity_metadata`
- normalize command input into capability-local execution paths
- route supported semantic contract generations through one capability-owned command seam
- open and close SketchUp operation boundaries for semantic mutations
- coordinate builders, metadata or invariant helpers, and serializers
- resolve lifecycle, hosting, and parent-context targets at the semantic seam during contract migration
- translate sectioned semantic requests into builder-native execution paths during migration where builders have not yet absorbed the newer contract shape
- preserve existing parent context for supported hierarchy-safe mutations and lifecycle operations
- keep public tool naming aligned with the Python MCP surface

**Must Not Own**

- socket lifecycle management
- MCP-specific concerns
- long-lived managed-object state tracking

### 3. Managed Scene Object Metadata and Invariant Layer

**Responsibilities**

- read and write the capability-owned metadata namespace on SketchUp entities
- determine whether an entity qualifies as a Managed Scene Object
- enforce hard invariants such as required management markers and protected identity fields
- explicitly enforce the PRD-mandated minimum metadata set (e.g., `sourceElementId`, `status`, and `subtype/category` for structures) at creation time
- support metadata handoff when a managed object is rebuilt or replaced while preserving business identity
- support lifecycle-safe maintenance for managed objects nested inside grouped scene structure without creating a parallel hierarchy-specific metadata system
- provide semantic metadata-key conventions to adjacent capabilities without making them semantic-aware

**Must Not Own**

- element-specific geometry creation
- transport or MCP concerns
- a separate lookup engine that duplicates targeting and interrogation behavior
- long-lived in-memory registries of managed objects

### 4. Builder Registry

**Responsibilities**

- map semantic element types to builder implementations and their payload sub-schemas
- master or reference the "Approved Semantic Vocabulary" (e.g., `main_building`, `outbuilding`, `extension`) to ensure subtypes are validated against a central source of truth
- keep `create_site_element` extensible without turning it into one large case-analysis blob
- make first-wave builders explicit while preserving a clean extension path for later semantic families
- support `structure` as a first-wave builder and preserve a clean extension path for later structure subfamilies without forcing a new public creation tool
- support incremental builder migration so families can move from older builder-facing payloads to builder-native sectioned `v2` input without changing the public tool surface

**Must Not Own**

- metadata policy
- identity protection rules
- bridge or transport behavior
- serialized result-envelope policy

### 5. Element Builders

**Responsibilities**

- implement element-specific geometry or wrapper creation for first-wave semantic types
- choose a managed-object wrapper form that supports stable metadata storage and identity handoff without treating the current wrapper choice as permanently fixed across all semantic types
- support a footprint-based `structure` contract for common built-form cases, including polygon footprints for irregular houses or extensions, explicit vertical semantics for baseline 3D representation, and a required approved subtype or category field
- support standardized `pad` elevation and optional thickness semantics so raised hardscape and platform-like cases do not require a separate built-form type
- return created entities or wrapper references in a form that the metadata and serialization layers can normalize
- keep geometry logic internal to Ruby and scoped to the semantic type being built
- converge over time toward builder-native acceptance of the sectioned semantic contract rather than relying permanently on command-level translation

**Must Not Own**

- cross-element metadata invariants
- generic lookup behavior
- final response serialization
- public MCP tool registration

### 6. Managed Scene Object Serializer or Decorator

**Responsibilities**

- convert a managed SketchUp entity plus semantic metadata into a JSON-serializable result
- expose identity, semantic type, status, and other documented fields consistently across semantic commands
- normalize geometry-adjacent output such as bounds or material summaries when those are part of the semantic response contract
- remain compatible with nested managed objects and expose parent-context or hierarchy-summary fields when the public semantic contract requires them

**Must Not Own**

- mutation behavior
- metadata writes
- semantic lookup policy

### 7. Revision and Identity-Handoff Helper

**Responsibilities**

- support identity-preserving rebuild or replacement flows for Managed Scene Objects
- transfer protected semantic metadata from an old representation to a new one within one operation boundary
- preserve business identity even when SketchUp runtime identifiers or representation types change
- preserve or intentionally reassign parent placement as part of supported hierarchy-aware lifecycle operations
- surface structured refusal when a requested rebuild would violate semantic invariants

**Must Not Own**

- asset-exemplar instancing or protection rules
- generic mutation tool registration
- validation acceptance policy

### 8. Generic Mutation Compatibility Boundary

**Responsibilities**

- define how existing generic mutation tools may interact with Managed Scene Objects
- ensure hard semantic invariants are not silently broken when generic tools are used on managed objects
- make the compatibility posture explicit for `transform_component`, `set_material`, and adjacent generic tools

**Must Not Own**

- semantic creation behavior
- a separate public revision workflow if that tool surface is deferred
- broad platform mutation policy outside managed objects

## Integration & Data Flows

### 1. Semantic Creation Flow

```text
Agent
-> Python MCP tool adapter
-> create_site_element
-> Ruby semantic command
-> SketchUp operation boundary
-> builder registry
-> selected element builder
-> Managed Scene Object metadata and invariant layer
-> serializer or decorator
-> response
```

### 1A. Sectioned Contract Migration Flow

```text
Agent
-> Python MCP tool adapter
-> create_site_element
-> Ruby semantic command
-> contract-version branch inside the semantic seam
-> request validation and normalization
-> target resolution for lifecycle, hosting, and parent context
-> transitional builder translation when needed
-> selected element builder
-> Managed Scene Object metadata and invariant layer
-> serializer or decorator
-> response
```

### 2. Metadata Update Flow

```text
Agent
-> Python MCP tool adapter
-> set_entity_metadata
-> Ruby semantic command
-> explicit target resolution through the established targeting dependency
-> SketchUp operation boundary
-> Managed Scene Object metadata and invariant layer
-> serializer or decorator
-> response
```

### 3. Identity-Preserving Rebuild Flow

```text
Semantic revision path
-> target resolution
-> Ruby semantic command or internal revision helper
-> SketchUp operation boundary
-> replacement builder or rebuild logic
-> metadata handoff from old representation to new representation
-> old representation retirement
-> serializer or decorator
-> response
```

### 4. Managed-Object Mutation Through Generic Tools

```text
Agent
-> transform_component or set_material
-> generic Ruby mutation command
-> Managed-object compatibility boundary
-> allowed mutation or structured refusal when hard invariants would break
-> response
```

### Architecture Diagram

```text
MCP Client
   |
   v
[Python Semantic Tool Adapters] ------------------ [Python bridge / error mapping]
   |                                                        |
   | contract tests                                         | transport tests
   v                                                        v
========================= Ruby / Python Bridge Boundary =========================
   |
   v
[Ruby Semantic Commands]
   |
   +--> [SketchUp Operation Boundary] ---------------- semantic integration tests
   |
   +--> [Builder Registry] --------------------------- Ruby behavior tests
   |         |
   |         +--> [Structure / Pad / Path / Retaining Edge / Planting Mass / Tree Proxy Builders]
   |
   +--> [Managed Scene Object Metadata & Invariant Layer] --- Ruby behavior tests
   |
   +--> [Revision & Identity-Handoff Helper] --------- SketchUp-hosted integration tests
   |
   +--> [Managed Scene Object Serializer / Decorator] - Ruby behavior tests
   |
   +--> [Generic Mutation Compatibility Boundary] ---- integration tests
   |
   v
JSON-serializable Managed Scene Object results
```

### Verification Plan

- Ruby-side tests should cover builder selection, per-element schema routing, metadata invariant enforcement, serializer determinism, and identity-handoff behavior where full SketchUp runtime behavior is not required.
- Ruby-side tests should also cover any supported contract-version branching at the semantic seam, including bounded proofs for lifecycle-heavy or hosting-heavy flows before the newer contract shape is promoted publicly.
- Python-side tests should cover MCP argument validation, bridge request shaping, and MCP-facing error mapping for `create_site_element` and `set_entity_metadata`.
- Contract tests should extend the shared Python/Ruby bridge contract foundation for the semantic tool surface and stable result-envelope expectations.
- SketchUp-hosted integration tests should cover geometry-heavy semantic creation, including `structure` creation with polygon footprints, representative cases such as a rectangular shed, a polygon-footprint house extension, a concrete terrace or slab, and at least one deck or raised platform modeled as `pad`, explicit `pad` versus `structure` refusal behavior for ambiguous cases, one-operation undo behavior, and identity-preserving rebuild or replacement flows where real SketchUp runtime behavior matters.
- Bounded Ruby-only spike evidence such as `SEM-05` is sufficient to justify architectural direction changes, but not to skip the later builder-native and SketchUp-hosted verification work required for broader rollout.
- If full hosted automation is not practical for some flows yet, the HLD should still require explicit manual-verification gaps to be called out rather than leaving undo or rebuild behavior implicit.

## Key Architectural Decisions

### 1. Keep One Public Semantic Creation Tool but Back It with a Registry

**Decision**

Keep `create_site_element` as the primary public semantic constructor, but implement it through a builder registry with strict per-element payload sub-schemas.

**Reason**

The PRD calls for a compact public surface, but a single public command only remains maintainable if element-specific payload and geometry behavior are kept behind explicit internal boundaries.

### 2. Managed Scene Object Truth Lives on the SketchUp Entity

**Decision**

Managed Scene Object state should be stored on the SketchUp entity through a dedicated capability-owned metadata namespace rather than in long-lived Ruby memory.

**Reason**

SketchUp remains the source of truth for scene state. A memory-owned managed-object registry would drift from user edits and other runtime changes.

### 3. Separate Hard and Soft Semantic Invariants

**Decision**

The capability should distinguish protected identity or management fields from mutable metadata fields.

**Reason**

Semantic modeling needs a clear rule for what generic or semantic mutation paths may change without making Managed Scene Object ownership meaningless.

### 4. Semantic Mutations Must Be Undo-Safe and Atomic

**Decision**

Semantic create, metadata update, and identity-preserving rebuild flows should execute inside one SketchUp operation boundary.

**Reason**

These flows are multi-step mutations. Without one operation boundary, the SketchUp undo stack and failure behavior become inconsistent and unsafe for semantic workflows.

### 5. Identity Preservation Requires Explicit Handoff Rules

**Decision**

Rebuild or replacement flows that keep the same business object must transfer protected semantic metadata to the replacement representation before retiring the old one.

**Reason**

SketchUp runtime identifiers may change during rebuilds or representation swaps. Business identity must survive those changes through an explicit handoff protocol rather than accidental carry-over.

### 6. Semantic Modeling Depends on Targeting and Interrogation Without Replacing It

**Decision**

Semantic modeling should reuse the targeting and interrogation capability for lookup behavior while retaining ownership of semantic metadata-key conventions and managed-object meaning.

**Reason**

This keeps lookup mechanics centralized while preventing semantic metadata knowledge from being duplicated or scattered into multiple capability slices.

### 7. Pad and Structure Must Have an Explicit Semantic Boundary

**Decision**

The capability should treat `pad` as the home for surface-first hardscape and platform-like elements, including elevated pads, decks, and raised platforms expressed through documented height or thickness semantics, while `structure` should remain the home for enclosed or clearly building-like built forms.

**Reason**

The PRD now makes the `pad` versus `structure` boundary a first-class product requirement. Without an explicit architectural boundary and refusal posture for ambiguous cases, semantic creation will drift back toward prompt-dependent type guessing.

### 8. First-Wave Element Types Must Not Freeze the Long-Term Family Model

**Decision**

The architecture should implement the current first-wave semantic types directly, including `structure`, while preserving a clean extension path for future semantic families and deeper structure subfamilies.

**Reason**

The current PRD first-wave list is broader than before, but it still should not be treated as the final semantic taxonomy. The architecture should be extensible without forcing a redesign when additional built-form or site-object families are promoted later.

### 9. Generic Mutation Tools May Coexist, but They Must Not Break Hard Invariants Silently

**Decision**

Existing generic mutation tools may remain visible during transition, but the capability should make explicit how they interact with Managed Scene Objects and when semantic-safe mutation paths are required.

**Reason**

Hybrid workflows are realistic in the current repository, but leaving the compatibility boundary vague would allow semantic rules to erode through side-effecting generic tools.

### 10. Evolve the Contract Through One Public Constructor and Incremental Builder Migration

**Decision**

Keep one public `create_site_element` surface while allowing internal contract evolution behind it, and migrate builders toward native acceptance of the sectioned `v2` semantic shape incrementally rather than through a one-shot rewrite.

**Reason**

`SEM-05` now provides implementation-backed evidence that the sectioned `v2` direction can survive the Ruby seam for hard cases without thickening Python. The remaining overlap sits mainly in command-level translation into current builder-facing payloads. That is strong enough to justify architectural migration posture, but not to claim that every builder already natively accepts the newer shape.

## Technology Stack

| Concern | Technology / Approach | Purpose |
| --- | --- | --- |
| MCP exposure | Python FastMCP tool adapters | external semantic command surface |
| bridge invocation | shared Python socket bridge client | Python-to-Ruby transport |
| semantic command execution | Ruby command methods inside the SketchUp extension | semantic orchestration |
| managed-object truth | SketchUp attribute dictionaries on managed entities or wrappers | durable identity and metadata state |
| semantic creation | Ruby builder registry plus element-specific builders | extensible semantic geometry creation |
| undo and rollback | SketchUp model operation boundaries | atomic semantic mutations and one-step undo behavior |
| identity preservation | metadata handoff helpers plus stable `sourceElementId` conventions | revision-safe rebuild and replacement |
| serialization | Ruby serializer or decorator helpers | consistent JSON-safe Managed Scene Object payloads |
| lookup dependency | scene targeting and interrogation capability contracts | stable target resolution without duplicate semantic query engines |

## Opened Questions

1. What approved subtype or category vocabulary should `structure` require in MVP, and which of those values are first-wave supported?
2. What wrapper form should Managed Scene Objects prefer in MVP when more than one representation is plausible: group, component instance, or a semantic-type-specific choice?
3. Which metadata fields should be treated as hard invariants versus soft mutable fields, especially when generic mutation tools touch Managed Scene Objects?
4. Should any workflows require additional mandatory `structure` metadata beyond `sourceElementId`, `status`, and subtype or category in the first release?
5. Which rebuild or replacement flows should be first-class semantic revision paths in the early releases, and which should return a structured refusal until the rules stabilize?
6. How should workflow collection assignment map to actual scene structure versus metadata-only representation for Managed Scene Objects, especially for structure-heavy features?
7. Which first-wave builders should move to builder-native sectioned `v2` input first, and what evidence should retire the transitional command-level translation layer?
8. Which composition primitives should be promoted first so multipart feature assembly stays out of `create_site_element` while remaining useful for semantic workflows?
