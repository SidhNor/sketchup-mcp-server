---
doc_type: prd
title: Staged Asset Reuse
status: draft
last_updated: 2026-05-15
---

# PRD: Staged Asset Reuse

## Problem statement

Landscape and site workflows need higher-fidelity objects such as trees, benches, rocks, and focal elements. Relying on arbitrary geometry generation or live public asset search produces inconsistent quality, unstable naming, unreliable scale and origin handling, and poor repeatability.

Project teams also curate coherent in-model asset sets for a specific design, such as a grouped low-poly vegetation library made from reusable component instances. Those asset sets carry practical design semantics that are not captured by SketchUp definition names alone. The exact fields vary by asset category: vegetation may use archetype, planting role, represented species, intended design height, height class, style, variant hints, and usage notes, while furniture, rocks, lighting, or focal objects will need different category-specific attributes. The product needs to support these project-scoped libraries without requiring one exact group name, scene hierarchy, SketchUp tag convention, or vegetation-specific metadata schema.

The product needs a curated, in-scene asset reuse model that lets agents discover approved Asset Exemplars, instantiate them safely into the editable design scene, and replace lower-fidelity proxies without damaging the library source objects or breaking business identity.

Without a clear staged-asset reuse slice:

- higher-fidelity placement stays inconsistent and hard to repeat
- library assets are at risk of accidental in-place edits
- proxy-to-asset upgrades lose lineage or semantic identity
- asset selection falls back to broad scene inspection or uncontrolled search

## Goals

1. Enable reliable reuse of human-curated Asset Exemplars inside SketchUp.
2. Protect Asset Exemplars from accidental in-place modification, movement, or deletion in normal workflows.
3. Support controlled upgrade paths from lower-fidelity proxies to higher-fidelity scene objects.
4. Preserve source asset lineage and workflow identity when assets are instantiated or used as replacements.
5. Avoid dependence on live public asset search for normal asset workflows.

## Success Metrics & KPI

| Metric | Baseline | Target | Measurement Method | Timeline |
| --- | --- | --- | --- | --- |
| High-fidelity placements using Asset Exemplar instancing instead of ad hoc generation | No formal baseline; current workflows do not have a mature Asset Exemplar product flow | >= 90% of target high-fidelity placements | Workflow telemetry and scenario review of placement method by task | Within first asset-reuse release cycle |
| Reuse workflows that implicitly modify approved Asset Exemplars in place | No protection guarantee today | 0 accepted reuse workflows | Source-stability checks in instantiation/replacement tests and library integrity review | Immediately on asset-reuse MVP release |
| Asset Instances retaining source asset lineage metadata | No current lineage standard | >= 95% of Asset Instances | Metadata completeness checks on instantiated assets | Within first asset-reuse release cycle |
| Median time to upgrade a Tree Proxy or similar low-fidelity object to higher fidelity | Current manual upgrade time to be measured during discovery | >= 50% reduction from measured baseline | Timed scenario benchmarks for proxy-to-asset upgrade workflows | Within two releases after asset-reuse MVP launch |
| Asset Exemplar discovery flows returning a usable candidate on first query | No current Asset Exemplar discovery metric | >= 80% first-query usefulness rate | Scenario replay and curated user testing on asset lookup tasks | Within two releases after asset-reuse MVP launch |

**Primary KPI**

- Reuse workflows that implicitly modify approved Asset Exemplars in place

**Secondary KPI**

- High-fidelity placements using Asset Exemplar instancing instead of ad hoc generation
- Asset Instances retaining source asset lineage metadata
- Median time to upgrade a Tree Proxy or similar low-fidelity object to higher fidelity
- Asset Exemplar discovery flows returning a usable candidate on first query

## Target Users

- AI agents placing curated trees, seating, rocks, and focal objects
- Designers building higher-fidelity option scenes
- Technical operators maintaining the Asset Exemplar library and approval state
- Developers implementing controlled asset workflows on top of SketchUp MCP

## User Flows & Scenarios

### Flow 1: Find and place a curated tree

1. The user or agent asks for a retained or proposed tree with specific characteristics.
2. The system lists approved Asset Exemplars matching category, species, style, detail level, or similar metadata.
3. The agent selects an Asset Exemplar from structured discovery results.
4. The system instantiates it into the editable design scene at the requested model-root position, optionally applying direct scale when requested, and carries source asset metadata such as intended design height as selection and lineage evidence rather than automatically fitting height.
5. The resulting Asset Instance becomes an editable Managed Scene Object linked back to its source asset.

### Flow 2: Upgrade a proxy to a curated asset

1. A `tree_proxy`, seat proxy, or other lower-fidelity object already exists in the scene.
2. The agent locates a better matching approved Asset Exemplar.
3. The system replaces the lower-fidelity object while preserving semantic role, `sourceElementId`, and placement intent.
4. The resulting object is treated as an Asset Instance and validated as a Managed Scene Object.

### Flow 3: Maintain a reusable asset library

1. A human imports or organizes reusable assets inside a dedicated staging area.
2. The system records asset metadata, approval state, asset-set identity, and library status for those Asset Exemplars.
3. Agents can discover only approved Asset Exemplars for normal reuse flows.
4. Reuse workflows do not mutate the library source objects in place as an implicit side effect.
5. Explicitly targeted editing commands may still be used for deliberate library maintenance.

### Flow 4: Use a project vegetation asset set

1. A designer creates a project-specific vegetation library in the model, for example a common group containing low-poly component instances for hedge blocks, shrub masses, grasses, perennials, vines, bamboo, and seasonal bulb markers.
2. The system curates each reusable component instance as an approved Asset Exemplar while preserving its project asset-set metadata.
3. An agent searches the asset set by category, archetype, represented species, planting role, height class, style, or tags.
4. The agent places or replaces editable scene objects with selected Asset Instances while the grouped library source exemplars remain intact.

## Functional Requirements

| Requirement | User Story | Acceptance Criteria | Priority |
| --- | --- | --- | --- |
| Support Asset Exemplar discovery through `list_staged_assets` | As an agent, I want to discover reusable approved Asset Exemplars without inspecting the whole scene manually | `list_staged_assets` returns structured results for approved Asset Exemplars without exposing raw SketchUp objects | P1 |
| Support Asset Exemplar filtering by asset category, species, style, season, detail level, approval state, and similar documented asset metadata | As an agent, I want to narrow asset choices to the right candidate quickly | Asset Exemplar discovery accepts supported metadata filters and returns only matching Asset Exemplars | P1 |
| Support project-scoped asset sets such as grouped vegetation component libraries | As a designer, I want to stage a coherent project library once and reuse it through agents without imposing a brittle scene hierarchy | The system can curate and discover approved component-instance exemplars that belong to the same project asset set, using metadata rather than requiring a fixed group name or SketchUp tag structure | P1 |
| Preserve category-specific asset metadata during discovery and reuse | As an agent, I want to choose assets by metadata that is meaningful for their category | Discovery and reuse workflows can expose and carry JSON-safe asset metadata without hard-coding vegetation-only fields; vegetation fields such as archetype, represented species, planting role, intended design height, height class, style, variant hints, and usage notes are supported as examples | P1 |
| Support creation of editable Asset Instances through `instantiate_staged_asset` | As a designer or agent, I want to place curated assets into the live scene safely | Given a valid approved Asset Exemplar and placement payload, `instantiate_staged_asset` creates a new editable Asset Instance in the design scene and returns a structured result | P1 |
| Support placement and initialization details during instantiation | As an agent, I want asset placement to fit the scene in one structured action | Instantiation supports position-only minimum placement at model root, optional direct scale for variation, and metadata fields, and the resulting Asset Instance reflects them in serialized output and metadata | P1 |
| Ensure Asset Instances retain lineage, stop being treated as Asset Exemplars, and become Managed Scene Objects | As a workflow orchestrator, I want placed assets to be both traceable and editable | Asset Instances include source asset lineage metadata, are marked as non-library scene objects, and satisfy Managed Scene Object rules after instantiation | P1 |
| Support replacement of a Tree Proxy or other lower-fidelity object through `replace_with_staged_asset` | As an agent, I want to upgrade fidelity without losing workflow identity | Replacement preserves `sourceElementId`, semantic role, and Managed Scene Object lineage in alignment with domain rules | P1 |
| Preserve approved Asset Exemplars during reuse workflows | As a library curator, I want source assets to remain pristine when agents reuse them | Instantiation and replacement workflows do not mutate selected source Asset Exemplars in place; explicit targeted edits remain available for deliberate library maintenance | P1 |
| Support an approval model for Asset Exemplars before normal reuse | As a curator, I want only vetted assets to be discoverable so that normal workflows stay reliable | Asset Exemplars require documented approval metadata before they are returned as normal discovery results | P1 |
| Ensure Asset Exemplar discovery responses include enough structured data for selection without raw scene inspection | As an agent, I want to choose assets from returned data instead of falling back to arbitrary inspection | Discovery responses include asset identity, asset category, metadata summary, component or display name, and placement-relevant summary data such as bounds | P1 |
| Support approved, human-curated in-scene Asset Exemplar libraries as the primary reuse mechanism | As a product owner, I want reliable asset quality and repeatability | Core asset workflows operate from in-scene curated libraries and do not require live public search services for normal use | P1 |

Conflict flag: no functional requirements currently conflict with the business rules in [`domain-analysis.md`](../domain-analysis.md); the current domain model already reflects the standalone targeting/interrogation slice that asset discovery depends on.

## Non Functional Requirements

- Asset Exemplar discovery should return consistent results for the same filters and library state.
- Asset instancing should perform acceptably in common scene sizes and not require network access.
- The library protection model must be resilient to normal modeling operations.
- Asset metadata and source lineage must be consistently serialized.
- The product should support future extension to more asset categories without redesigning the overall asset model.

## Constraints

- Asset reuse must work from Asset Exemplars already staged in the SketchUp model.
- The solution must not depend on live 3D Warehouse or other public search services for core workflows.
- Asset Exemplars and editable design-scene Managed Scene Objects must remain distinct.
- Asset workflows must remain compatible with the Managed Scene Object model and validation layer.
- Asset Exemplars should be organized in dedicated staging areas, collections, tags, or equivalent library conventions that keep them separate from the editable design scene.
- Project asset-set organization should be flexible. A common group containing component instances is a supported staging pattern, but product behavior should rely on explicit asset metadata and approval state rather than a single required group name, nesting pattern, or SketchUp tag/layer convention.

## Out of Scope

- Public asset marketplace integration as a primary source
- Automated external asset ingestion pipelines
- Advanced asset recommendation or ranking logic
- Full digital asset management product features
- Photoreal asset rendering workflows
- General-purpose library curation UI beyond the metadata and approval behaviors needed for MCP workflows

## Open Questions

- What is the minimum required metadata for an Asset Exemplar to become approved for reuse?
- What exact protections should block editing of Asset Exemplars in SketchUp?
- How should versioning and deprecation of Asset Exemplars be represented in normal discovery flows?
- Should the product support separate libraries for existing vegetation, proposed planting, furniture, rocks, and focal objects from the start?
- Which project asset-set metadata fields should become documented first-class filters after the low-poly vegetation workflow is validated?

## Risks and Mitigation

| Risk | Likelihood | Impact | Mitigation Strategy |
| --- | --- | --- | --- |
| Asset Exemplars are accidentally edited, moved, or deleted | Medium | High | Mark and protect Asset Exemplars, validate library integrity, and keep them in dedicated library collections or staging zones |
| Asset metadata quality is inconsistent | High | High | Define approval rules and require minimum metadata before Asset Exemplars become discoverable |
| Asset Instance creation loses source lineage | Medium | High | Write source asset lineage during instantiation and validate it as part of Managed Scene Object checks |
| Asset Exemplar search becomes noisy or unreliable | Medium | Medium | Constrain discovery to approved metadata and curated libraries rather than broad scene search |
| Replacement flows break object identity | Medium | High | Preserve `sourceElementId`, semantic role, and provenance through replacement workflows |
| Project asset-set semantics are lost during curation or instantiation | Medium | High | Treat category-specific fields as JSON-safe asset metadata carried through discovery and lineage without making vegetation-only fields mandatory or universal |

## Dependencies

- [`domain-analysis.md`](../domain-analysis.md)
- [`low_poly_garden_vegetation_inventory.md`](../research/asset-reuse/low_poly_garden_vegetation_inventory.md)
- [`prd-scene-targeting-and-interrogation.md`](./prd-scene-targeting-and-interrogation.md)
- [`prd-semantic-scene-modeling.md`](./prd-semantic-scene-modeling.md)
- Scene organization conventions for Asset Exemplar libraries and editable collections
- Managed Scene Object metadata model
- Validation rules that detect edits to Asset Exemplars
- Asset Exemplar conventions from the domain analysis and asset-reuse HLD

## Revision History

| Date | Change |
| --- | --- |
| 2026-04-10 | Initial PRD created. |
| 2026-04-11 | Refined the PRD against the updated guide, added lightweight front matter and revision history, and tightened the slice around Asset Exemplars, Asset Instances, approval, instancing, replacement, and protection rules. |
| 2026-04-12 | Rebalanced priorities to match the guide's sequencing, moving the staged-asset slice out of P0 and into the next implementation wave. |
| 2026-05-15 | Added explicit support for project-scoped grouped component asset sets, including the low-poly garden vegetation inventory as a concrete staged-asset scenario. |
