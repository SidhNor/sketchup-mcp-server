---
doc_type: prd
title: Semantic Scene Modeling
status: draft
last_updated: 2026-04-17
---

# PRD: Semantic Scene Modeling

## Problem statement

The current SketchUp MCP surface is still too primitive-first for site, garden, landscape, and small-structure workflows. Users and agents need to create and revise meaningful scene objects such as structures, pads, paths, retaining edges, planting masses, and tree proxies without dropping into arbitrary Ruby or assembling low-level geometry by hand.

Without a strong semantic modeling layer:

- routine modeling requests collapse into primitive construction or fallback Ruby
- created objects do not reliably carry the identity and metadata needed for later revision
- option updates recreate geometry instead of revising or replacing Managed Scene Objects in place
- mutation and composition steps stay brittle because business identity is not preserved through edits

The product needs a compact semantic creation and mutation surface that makes Managed Scene Objects the default unit of scene work.

## Goals

1. Introduce a compact semantic creation surface for site and structure-oriented scene objects.
2. Make Managed Scene Objects the default unit of creation, revision, and lifecycle tracking.
3. Ensure semantic objects carry stable metadata and business identity from the moment they are created.
4. Support common revision and composition workflows without forcing recreate-from-scratch behavior.
5. Introduce a narrow hierarchy-maintenance surface for managed-object organization and repair workflows.
6. Reduce the need for `eval_ruby` in normal modeling flows.

## Success Metrics & KPI

| Metric | Baseline | Target | Measurement Method | Timeline |
| --- | --- | --- | --- | --- |
| Baseline semantic scene modeling tasks completed without `eval_ruby` | No formal baseline; current workflow is primitive-first and Ruby-heavy | >= 80% of representative baseline modeling tasks | Scenario-based workflow test set measuring tool usage per task | Within first MVP release cycle |
| MCP-created semantic objects with required metadata keys | No enforced metadata completeness standard today | >= 95% of semantic objects created through MCP | Structured validation over created scene objects and metadata completeness reports | Within first MVP release cycle |
| Representative semantic creation requests completed through `create_site_element` without primitive-tool fallbacks | No semantic-constructor completion baseline today | >= 85% of representative requests | Scenario suite covering initial MVP element types and workflow outcomes | Within first MVP release cycle |
| Median time to create a representative baseline semantic scene | Current primitive-first workflow time to be measured during discovery | >= 40% reduction from measured baseline | Timed benchmark scenarios comparing old and new workflows | Within two releases after MVP launch |
| Scene revisions applied to existing Managed Scene Objects instead of recreate-from-scratch flows | No current revision-lineage baseline | >= 70% of target revisions reuse existing Managed Scene Objects | Workflow telemetry and scenario audits across revision tasks | Within two releases after MVP launch |

**Primary KPI**

- Baseline semantic scene modeling tasks completed without `eval_ruby`

**Secondary KPI**

- MCP-created semantic objects with required metadata keys
- Representative semantic creation requests completed through `create_site_element` without primitive-tool fallbacks
- Median time to create a representative baseline semantic scene
- Scene revisions applied to existing Managed Scene Objects instead of recreate-from-scratch flows

## Target Users

- AI agents executing structured design or modeling plans
- Landscape, garden, and residential site designers using SketchUp as an execution environment
- Technical operators revising or organizing managed scene objects
- Developers extending the semantic modeling surface for domain workflows

## User Flows & Scenarios

### Flow 1: Build a baseline semantic scene

1. The user or agent determines what semantic elements must be created.
2. The system creates objects such as structures, pads, paths, retaining edges, planting masses, and tree proxies through a constrained semantic constructor.
3. The system assigns required metadata, status, and workflow organization fields to each created object.
4. The resulting scene objects become Managed Scene Objects that can be revised later without losing business identity.

### Flow 2: Apply a design option update

1. The user supplies a new plan or scenario identifier.
2. The workflow selects existing Managed Scene Objects that should be revised, replaced, grouped, or removed.
3. The system applies semantic creation and mutation actions while preserving `sourceElementId`, required metadata rules, and intended parent placement in the scene hierarchy, including supported cases where an existing Managed Scene Object keeps its business identity while its representation is rebuilt or replaced.
4. The resulting scene reflects the new option without forcing wholesale scene reconstruction.

### Flow 3: Refine and compose a feature

1. The user or agent creates or selects one or more Managed Scene Objects that belong to the same feature.
2. The system applies transforms, materials, grouping, duplication, or metadata updates as needed, including cases where the managed objects live inside nested groups or components.
3. The feature remains semantically legible and revision-friendly after those edits.

## Functional Requirements

| Requirement | User Story | Acceptance Criteria | Priority |
| --- | --- | --- | --- |
| Support semantic scene creation through `create_site_element` | As an agent, I want one primary semantic constructor so that I can create site-relevant and structure-relevant objects without assembling primitive geometry manually | `create_site_element` accepts a documented semantic contract that can evolve without fragmenting into many overlapping creation tools, and returns a structured, JSON-serializable Managed Scene Object result or a structured error when the request is invalid | P0 |
| Support initial semantic element types of `structure`, `pad`, `path`, `retaining_edge`, `planting_mass`, and `tree_proxy` | As a designer or agent, I want the first semantic constructor vocabulary to cover the highest-value baseline workflows so that routine work stays semantic instead of primitive-first | Each listed element type accepts a documented payload shape and produces a valid Managed Scene Object or a structured error if the request is incomplete or contradictory | P0 |
| Support `structure` as a first-class semantic object for built-form scene work | As a designer or agent, I want to model houses, sheds, and house extensions as managed objects so that built forms are not forced into ambiguous pad-like or primitive-only representations | The `structure` element type supports a documented footprint-based contract for common built-form cases, includes polygon footprints as an explicit P0 capability for irregular house or extension outlines, and returns a valid Managed Scene Object or a structured error when the request is incomplete or contradictory | P0 |
| Require subtype or category semantics for `structure` | As a workflow client, I want built forms to stay semantically legible after creation so that later validation, revision, and reporting can distinguish major structure classes | A created `structure` includes a documented subtype or category field such as `main_building`, `outbuilding`, `extension`, or similar approved values; requests that omit the required subtype/category are rejected or surfaced as structured failures | P0 |
| Require minimum metadata for `structure` objects | As a workflow client, I want building-like objects to carry enough semantic identity from creation time so that they can be revised, validated, and reported on reliably | Every created `structure` includes at minimum `sourceElementId`, `status`, and the approved `structure` subtype/category field; requests that omit any of these required metadata fields are rejected or surfaced as structured failures | P0 |
| Define the product boundary between `structure` and `pad` clearly | As a workflow author, I want consistent semantic distinctions so that slabs, terraces, decks, platforms, and enclosed built forms are modeled with predictable types | The product documentation states that `pad` is used for surface-first hardscape or platform-like elements, including elevated pads expressed through height or thickness, while `structure` is used for enclosed or clearly building-like built forms; representative examples cover concrete surfaces, terraces, decks, raised platforms, houses, sheds, and extensions, and ambiguous cases return a structured refusal unless the input explicitly resolves the intended type | P0 |
| Require atomic and undo-safe semantic mutations | As a user, I want semantic creation and revision to succeed or fail as a single unit so that my model state and undo history stay clean and predictable | All semantic creation, metadata update, and identity-preserving rebuild flows execute inside one SketchUp operation boundary; failures result in a clean rollback | P0 |
| Standardize `pad` height and thickness semantics for raised hardscape and platforms | As a workflow author, I want decks, terraces, and raised platforms to use one consistent pad contract so that vertical interpretation does not vary by prompt wording | The documented `pad` contract defines elevation as the intended top-surface reference and thickness as optional downward body depth from that surface; when thickness is omitted the pad remains valid as a surface-first element without requiring volumetric body semantics | P0 |
| Validate the initial semantic vocabulary against representative built-form and hardscape examples | As a product owner, I want the MVP vocabulary to prove that it covers the most failure-prone real cases so that semantic modeling does not regress into primitive fallback | The documented MVP acceptance set includes at minimum a rectangular shed, a polygon-footprint house extension, a concrete terrace or slab, and at least one deck or raised platform modeled as a `pad` with documented height or thickness expectations | P0 |
| Support next-wave semantic element types of `tree_instance`, `seat`, `water_feature_proxy`, and `terrain_patch` | As a designer or agent, I want the semantic vocabulary to expand to additional site objects once the first-wave constructor is established | Each listed element type accepts a documented payload shape and produces a valid Managed Scene Object or a structured error if the request is incomplete or contradictory | P1 |
| Ensure each semantic creation produces a Managed Scene Object with required metadata | As a downstream workflow, I want created objects to be reliably revisable and validatable later | Every semantic object created through MCP includes the required metadata keys defined by the domain rules; objects missing required keys are rejected or surfaced as failed creation | P0 |
| Preserve stable business identity across revisions and representation changes | As a workflow orchestrator, I want replacements and revisions to keep lineage intact so that downstream automation stays reliable | `sourceElementId` and required managed-object identity survive supported revise, regroup, replace, and representation-rebuild flows in accordance with domain rules | P0 |
| Support first-class lifecycle workflows within semantic creation | As an agent, I want the semantic creation surface to support creation, adoption of retained objects, and identity-preserving replacement so that semantic scene work does not collapse into fallback Ruby or ad hoc special tools | The documented semantic contract supports at minimum `create_new`, `adopt_existing`, and identity-preserving replacement workflows for supported managed objects, or returns a structured refusal when the request is incomplete or violates product rules | P0 |
| Support hierarchy-aware maintenance of Managed Scene Objects | As an agent or operator, I want to maintain managed objects even when they live inside nested scene structure so that governed scene work does not depend on fallback Ruby for normal hierarchy-heavy workflows | Supported semantic lifecycle flows can target and update Managed Scene Objects inside nested groups or components while preserving business identity, intended parent placement, and structured downstream references, or else return a structured refusal when the requested change would violate product rules | P0 |
| Support a limited first-class hierarchy-maintenance surface | As an agent or operator, I want a small set of hierarchy-aware primitives so that normal managed-object organization and repair flows do not require fallback Ruby | The product exposes a documented limited surface for creating group containers for semantic work and explicitly reparenting supported entities through explicit target-based operations while preserving managed-object identity, parent intent, and structured outputs; unsupported hierarchy changes return structured refusals rather than silent fallback behavior | P1 |
| Support explicit metadata creation and updates through `set_entity_metadata` | As an agent, I want to update provenance and semantic identity without rebuilding geometry | Metadata can be added or updated on Managed Scene Objects while preserving required identity rules; removal of required keys is blocked or surfaced as a product-level failure | P0 |
| Support mutation of Managed Scene Objects through `transform_entities` and `set_material` | As an agent, I want to revise created objects without recreating them so that iteration stays efficient and traceable | Managed Scene Objects can be transformed and assigned materials while retaining identity, structured metadata, and serializable state | P1 |
| Support revision-safe replacement or rebuild of Managed Scene Objects where the workflow intent is to keep the same business object | As an agent or operator, I want to update the representation of an existing Managed Scene Object without breaking lineage so that revision workflows do not collapse into delete-and-recreate patterns | Supported semantic revision flows can replace or rebuild the representation of a Managed Scene Object while preserving required identity, metadata invariants, and structured downstream references, or else return a structured refusal when the requested revision would violate product rules | P1 |
| Support composition and scene organization through dedicated composition tools | As an operator, I want to compose larger features from semantic objects so that related scene work remains manageable and reusable without overloading atomic creation with multipart feature assembly | Grouping and duplication actions produce predictable structured outputs and preserve or derive managed-object identity according to documented product rules; composite features are not required to be expressed as one atomic `create_site_element` call, and multipart composition semantics are not part of the atomic-create scope by default | P1 |
| Support controlled deletion through `delete_component` for managed scene objects | As an agent, I want to remove obsolete managed objects safely so that option updates can clean up superseded work | Deletion can remove supported Managed Scene Objects while respecting product protections for restricted objects and returning a structured result | P1 |
| Support collection, tag, and status assignment as part of semantic scene workflows | As a workflow client, I want created and revised objects to remain organized in product-meaningful ways so that later automation can reason about them | Semantic creation and managed-object update flows can assign or preserve workflow-relevant collections, tags, and status fields without free-form interpretation | P1 |
| Ensure all semantic modeling outputs remain structured and JSON-serializable | As an MCP client, I want semantic modeling responses that I can consume programmatically without text scraping | All creation, metadata, mutation, grouping, duplication, and deletion outputs serialize cleanly and do not expose raw SketchUp objects | P0 |

Conflict flag: no functional requirements currently conflict with the business rules in [`domain-analysis.md`](../domain-analysis.md); the domain analysis has been updated to reflect `structure` as a first-wave semantic object and to keep raised platforms under `pad` semantics.

## Non Functional Requirements

- Tool contracts must remain compact enough for reliable model use.
- Semantic creation and mutation behavior must be deterministic for the same input and scene state.
- The semantic constructor must reject ambiguous or underspecified requests clearly rather than guessing silently.
- Output contracts must be consistent enough to support downstream asset reuse and validation.
- The semantic modeling surface must remain maintainable as new semantic types are added over time.
- Contract evolution must preserve one primary semantic creation surface rather than expanding into many overlapping creation tools for each lifecycle or hosting variant.
- Initial semantic structure support must cover common irregular footprints without requiring primitive fallback for non-rectangular house or extension outlines.
- Built-form classification rules must be explicit enough that agents do not have to infer `pad` versus `structure` from weak natural-language hints alone.
- Normal semantic maintenance workflows must remain reliable when Managed Scene Objects are nested inside grouped scene structure rather than living only at the top level.
- The first hierarchy-maintenance surface must stay intentionally narrow and managed-object-focused rather than turning into a broad scene-hierarchy control API.

## Constraints

- SketchUp is the execution environment and owns scene mutation logic.
- The Python layer must stay a thin MCP adapter.
- Raw SketchUp objects cannot cross the runtime boundary.
- The tool surface should stay small and parameterized rather than expanding into many overlapping constructors.
- Existing primitive tools may need to coexist during migration but should not remain the primary product surface.
- Composite feature assembly should remain a separate workflow layer rather than being forced into one oversized atomic-creation contract.

## Out of Scope

- Public asset marketplace search
- Full terrain modeling or grading-authoring systems beyond the semantic creation surface
- Photorealistic rendering workflows
- Complex water-feature generation beyond proxy-level support
- Rich geometry-repair or topology-diagnostics workflows
- Workflow-specific branch or canonical promotion helpers, scene-pass cleanup flows, or other orchestration concepts that are not yet stable product abstractions
- Broad scene-hierarchy orchestration, canonical pass-root management, or unrestricted hierarchy editing beyond the limited managed-object maintenance surface
- Replacing all legacy primitive tools in the first release

## Open Questions

- What exact geometry schema should each initial semantic element type use in version 1, especially for `structure` footprints, height semantics, and roof/profile simplifications?
- Which initial `structure` subcases are in scope for MVP: houses, sheds, house extensions, pergolas, or other small built forms?
- What approved subtype/category vocabulary should `structure` require in MVP?
- Should the MVP require any additional `structure` metadata beyond `sourceElementId`, `status`, and subtype/category for certain workflows such as retained existing buildings?
- How should roof or enclosure expectations be represented for `structure` without turning the PRD into a building-modeling spec?
- Should `terrain_patch` remain in the first semantic-modeling release or move to a later phase if terrain-authoring scope proves too broad?
- How strict should metadata validation be at creation time versus update time?
- What identity rules should apply when `duplicate_entity` creates a variant from an existing Managed Scene Object?
- Which representation-rebuild or replacement flows should be treated as first-class semantic revisions versus deferred to fallback execution until the product rules stabilize?
- Which current primitive tools should remain exposed during transition, and for how long?

## Risks and Mitigation

| Risk | Likelihood | Impact | Mitigation Strategy |
| --- | --- | --- | --- |
| Semantic commands become too broad and underspecified | Medium | High | Keep one constrained semantic command with explicit element schemas and reject ambiguous payloads |
| `create_site_element` absorbs composite feature assembly and loses clarity | Medium | High | Keep atomic semantic creation separate from grouping and composition workflows, and treat multipart features as composed structures unless they prove to require a true atomic semantic type |
| Built forms remain semantically under-modeled if `structure` is omitted or under-specified | High | High | Make `structure` a first-wave element type with clear scope examples and a documented boundary versus `pad` |
| `structure` becomes a catch-all type that erodes semantic precision | High | High | Require subtype/category semantics, define refusal behavior for ambiguous cases, and validate the vocabulary against representative built-form and hardscape examples |
| Objects are created without sufficient metadata | High | High | Enforce required metadata at semantic creation time and validate metadata completeness continuously |
| Revision flows recreate objects instead of preserving lineage | Medium | High | Preserve `sourceElementId` and managed-object rules across supported mutation, grouping, and replacement flows |
| Agents continue to prefer `eval_ruby` | Medium | High | Make semantic tools expressive for common tasks and track escape-hatch usage as a product signal |
| The semantic modeling slice absorbs targeting or validation responsibilities again | Medium | Medium | Keep scene targeting/interrogation and acceptance checking as explicit dependent slices rather than embedding them here |

## Dependencies

- [`domain-analysis.md`](../domain-analysis.md)
- [`prd-scene-targeting-and-interrogation.md`](./prd-scene-targeting-and-interrogation.md)
- Metadata storage and retrieval
- Managed Scene Object lifecycle and identity conventions
- Collection and Tag conventions
- Guide-defined semantic object vocabulary from [`sketchup_mcp_guide.md`](../../sketchup_mcp_guide.md)

## Revision History

| Date | Change |
| --- | --- |
| 2026-04-10 | Initial PRD created. |
| 2026-04-11 | Refined the PRD to focus on semantic creation, metadata, identity, and mutation after splitting scene targeting and interrogation into its own PRD, and added lightweight front matter plus revision history. |
| 2026-04-12 | Modestly clarified that semantic revision includes supported identity-preserving representation rebuild or replacement flows, while keeping workflow-specific branch/canonical lifecycle helpers out of scope. |
| 2026-04-12 | Rebalanced priorities to match the guide's first-wave semantic scope, keeping `create_site_element`, metadata, and first-wave element types in P0 while moving later element types and broader mutation helpers to P1. |
| 2026-04-14 | Expanded the PRD to treat `structure` as a first-wave semantic element, added product requirements for built-form coverage and the `structure` versus `pad` boundary, and called out polygon-footprint support for irregular house and extension outlines. |
| 2026-04-14 | Refined the `structure` update after external review by requiring subtype/category semantics, tightening the `pad` versus `structure` rule, adding representative acceptance examples, and explicitly classifying decks and raised platforms under `pad` using height or thickness semantics. |
| 2026-04-14 | Added explicit minimum metadata requirements for `structure` objects, standardized `pad` elevation and thickness semantics for raised hardscape and platform cases, and aligned the PRD conflict note with the updated domain analysis. |
| 2026-04-15 | Clarified that semantic lifecycle behavior must remain reliable for Managed Scene Objects inside nested scene hierarchy, and made parent-placement preservation explicit in revision-friendly workflows. |
| 2026-04-16 | Clarified that the primary semantic creation surface must support contract evolution for create, adopt, and identity-preserving replace workflows without fragmenting into many overlapping tools, and made composition a separate product layer from atomic semantic creation. |
| 2026-04-17 | Added a limited first-class hierarchy-maintenance surface for managed-object workflows, centered on explicit target-based group creation and explicit reparenting while keeping broader hierarchy orchestration out of scope. |
