---
doc_type: domain_analysis
title: SketchUp MCP Domain Analysis
status: draft
last_updated: 2026-04-11
---

# SketchUp MCP Domain Analysis

## Purpose

This document translates [`sketchup_mcp_guide.md`](../sketchup_mcp_guide.md) into a domain model that can drive both product decisions and implementation structure.

It is intended to feed the following PRDs:

- [`prd-scene-targeting-and-interrogation.md`](prds/prd-scene-targeting-and-interrogation.md)
- [`prd-semantic-scene-modeling.md`](prds/prd-semantic-scene-modeling.md)
- [`prd-staged-asset-reuse.md`](prds/prd-staged-asset-reuse.md)
- [`prd-scene-validation-and-review.md`](prds/prd-scene-validation-and-review.md)

## Domain Summary

The product domain is a semantic scene execution system for SketchUp. It is not a design-generation system. Design intent and planning happen outside SketchUp; the MCP server executes structured scene operations, preserves semantic identity, interrogates existing scene state, and validates outcomes.

The domain has seven capability groups:

1. Scene inspection and targeting
2. Surface interrogation and topology analysis
3. Semantic construction
4. Asset reuse and staging
5. Mutation and composition
6. Measurement and validation
7. Controlled fallback execution

The product slices align to those capabilities as follows:

- scene targeting and interrogation owns workflow-facing targeting, explicit surface sampling, and topology understanding
- semantic scene modeling owns semantic creation, managed-object identity, metadata, and core mutation/composition flows
- staged asset reuse owns Asset Exemplars, Asset Instances, approval, instancing, replacement, and protection rules
- scene validation and review owns structured measurement, validation, and review artifacts

## Terminology Conventions

The following conventions apply across this document and all PRDs in `specifications/prds/`:

- **Managed Scene Object** is the canonical term for an MCP-controlled object in the editable design scene.
- **Asset Exemplar** is the canonical term for a protected reusable object in the staging or library area.
- **Asset Instance** is the canonical term for an editable design-scene object created from an Asset Exemplar.
- **Collection** means a logical workflow bucket used for organization and lookup. It is not the same as a SketchUp Tag.
- **Tag** means a SketchUp visibility or classification label. Tags are useful for grouping and filtering, but they are not the primary identity mechanism.
- **State** means lifecycle phase, such as `Created`, `Classified`, `Validated`, or `Archived`.
- **Status** means business metadata describing intent or role in the workflow, such as `proposed`, `existing`, or `retained`.
- **Target Reference** means a structured workflow-facing way to refer to a scene entity during targeting, measurement, or validation.
- **Surface Sample** means the structured result of interrogating explicit geometry at one or more XY points.
- **Topology Finding** means a structured defect or summary result produced when checking linework connectivity or edge-network validity.
- The phrase **staged asset** is treated as a synonym for **Asset Exemplar**, not as a separate domain entity.
- The phrase **library asset** is treated as a synonym for **Asset Exemplar**, not as a separate domain entity.

### Identity Conventions

The domain uses three identity layers:

- **`sourceElementId`** is the primary workflow or business identity used by plans, expectations, validation, and managed-object lineage.
- **`persistentId`** is the SketchUp persistent identifier used when runtime-safe lookup and reconciliation are needed.
- **`entityId`** is the SketchUp runtime or internal identifier and should be treated as a compatibility-only reference rather than the primary workflow identity.

Product contracts should prefer `sourceElementId`, support `persistentId` where needed, and reserve `entityId` for compatibility or low-level cases.

## Domain Categories

### 1. Scene Objects

These are objects that exist in the modeled scene and can be targeted, created, transformed, validated, or replaced.

| Entity | Description | Why It Matters |
| --- | --- | --- |
| Managed Scene Object | Any top-level MCP-managed object in the editable design scene | Primary unit of identity, mutation, validation, and reporting |
| Site Element | A Managed Scene Object created through semantic tools such as `pad`, `path`, `planting_mass`, or `tree_proxy` | Replaces primitive-first geometry creation |
| Tree Proxy | Lightweight semantic representation of a tree | Supports early iteration and low-cost baseline modeling |
| Tree Instance | Higher-fidelity tree object, often created from an Asset Exemplar | Supports mature design options and retained-tree fidelity |
| Grouped Feature | Composite object containing related subparts | Supports feature-level mutation and validation |
| Asset Exemplar | Protected asset living in the Asset Exemplar library | Source object for safe reuse |
| Asset Instance | Editable scene instance derived from an Asset Exemplar | Connects curated assets to the live design scene |

### 2. Organizational and Identity Entities

These are entities used to make the scene automatable, searchable, and safe.

| Entity | Description | Why It Matters |
| --- | --- | --- |
| Collection | Logical scene bucket such as `existing_trees` or `proposed_hardscape` | Supports product workflows and high-level querying |
| Tag | SketchUp tag or layer used for broad classification | Useful for visibility, filtering, and scene hygiene |
| Metadata Record | Stable key or value identity attached to Managed Scene Objects or Asset Exemplars | Required for targeting, validation, replacement, and lineage |
| Material | Named material applied to a scene object or sub-geometry | Needed for design intent and validation |
| Target Reference | Structured reference using `sourceElementId`, `persistentId`, or compatible identifiers | Supports stable targeting, measurement, and validation contracts |

### 3. Interrogation and Analysis Entities

These are entities created or used while understanding existing scene state and geometry behavior.

| Entity | Description | Why It Matters |
| --- | --- | --- |
| Surface Sample Request | Structured request to interrogate explicit geometry at one or more XY points | Supports terrain-aware placement and reprojection workflows |
| Surface Sample Result | Structured hit, miss, ambiguity, and XYZ result for a surface interrogation | Lets downstream workflows reason about actual geometry rather than assumptions |
| Edge Network Analysis Request | Structured request to analyze connected linework or projected boundaries | Supports retaining-edge, path, grading, and validation workflows |
| Topology Finding | Structured result such as loose ends, disconnected components, or coincident-but-unmerged endpoints | Makes geometry defects actionable in automation workflows |

### 4. Execution and Review Entities

These are entities created or used during operation execution, validation, and review.

| Entity | Description | Why It Matters |
| --- | --- | --- |
| Measurement Request | Structured request to measure distance, area, bounds, clearance, slope, or related scene properties | Supports design checks without arbitrary Ruby |
| Validation Rule | Expected condition for a scene update | Turns design intent into checkable logic |
| Validation Result | Structured outcome of a validation run | Supports reliable automation and human review |
| Scene Snapshot | Captured scene view or artifact for inspection | Supports iterative review workflows |
| Scoped Ruby Execution | Explicit fallback operation applied to a narrow target | Escape hatch when typed tools are insufficient |

### 5. External Reference Entities

These represent workflow inputs or expectations defined outside SketchUp but applied to the scene system.

| Entity | Description | Why It Matters |
| --- | --- | --- |
| Source Plan | External plan, scenario, or workflow artifact referenced by scene objects | Supports provenance and revision tracking |
| Source Element | External business object referenced by `sourceElementId` | Lets the scene preserve workflow identity across revisions |
| Validation Expectation | Structured external expectation describing what must exist, be preserved, or satisfy tolerance checks | Drives acceptance decisions after scene updates |

## Core Domain Actions

| Action | Description | Typical Use | Example |
| --- | --- | --- | --- |
| Inspect | Summarize or retrieve current scene state | Before any create, mutate, or validate step | get scene info for the active model |
| Target | Locate the intended scene object or collection using workflow-facing identity | Before revision, placement, measurement, or validation | find a retained tree by `sourceElementId` |
| Interrogate Surface | Query explicit geometry for world-space behavior | Terrain-aware placement, reprojection, validation | sample Z values against `terrain-main` |
| Analyze Topology | Determine whether linework is structurally usable | Path, retaining-edge, grading, or validation workflows | check if plot boundaries form one connected network |
| Create | Build a semantic scene object in the editable scene | Baseline modeling, option generation | create `pad`, `path`, `planting_mass`, `tree_proxy` |
| Classify | Assign semantic role, collection, tags, or metadata to an object | Immediately after creation or curation | mark an object as `existing-tree`, assign collection `existing_trees` |
| Instantiate | Create a new scene object from an Asset Exemplar | Asset reuse, fidelity upgrade | place a curated apple tree into the live scene |
| Replace | Change the representation of an object while preserving business identity | Proxy-to-asset upgrade, fidelity increase | replace `tree_proxy` with curated cherry Asset Instance |
| Transform | Change placement, rotation, or scale of an object | Revision and layout adjustment | move a bench, rotate a tree instance |
| Group | Combine related objects into a single logical feature | Composite feature creation, organization | group path edge, planting, and terrace border objects |
| Materialize | Apply a material to a target entity or feature | Design refinement, semantic styling | assign gravel to a path, paving material to a terrace |
| Measure | Calculate distance, area, clearance, bounds, slope, or similar scene properties | Fit checks, design validation, review | measure clearance between tree and path |
| Validate | Evaluate whether the scene satisfies expected conditions | After updates, before acceptance, after fallback execution | validate required entities, metadata, and geometry relationships |
| Capture | Produce a review artifact representing current scene state | Review loops, debugging, approvals | capture snapshot after validation warnings |
| Curate | Organize and approve assets in the library or staging area | Asset-library maintenance | mark tree asset as approved for reuse |
| Protect | Prevent or detect changes to restricted objects | Library management, policy enforcement | block edits to an Asset Exemplar |
| Archive | Retain an object for record or future reference outside active workflows | Soft delete, historical preservation | mark superseded object as archived |
| Delete | Remove an object from active scene participation | Cleanup, option changes, correction | delete obsolete proxy or duplicate object |
| Fallback Execute | Run a bounded Ruby operation when typed tools cannot express the task | Rare escape-hatch cases | scoped Ruby cleanup on selected edges |

## Entity Categorization by Product Slice

| Product Slice | Primary Entities | Secondary Entities |
| --- | --- | --- |
| Scene targeting and interrogation | Target Reference, Surface Sample Request, Surface Sample Result, Edge Network Analysis Request, Topology Finding | Collection, Tag, Metadata Record, Managed Scene Object |
| Semantic scene modeling | Managed Scene Object, Site Element, Metadata Record, Collection | Material, Grouped Feature, Tag |
| Staged asset reuse | Asset Exemplar, Asset Instance, Metadata Record, Collection | Material, Tag, Managed Scene Object |
| Validation and review | Validation Rule, Validation Result, Measurement Request, Scene Snapshot | Managed Scene Object, Asset Exemplar, Topology Finding, Surface Sample Result |

## Entity Lifecycles

### Managed Scene Object Lifecycle

| State | Description | Typical Entry Action | Allowed Next States |
| --- | --- | --- | --- |
| Planned | Defined externally but not created in SketchUp | Plan import or workflow request | Created, Cancelled |
| Created | Wrapper entity exists in scene | `create_site_element`, instantiation, duplication | Classified, Deleted |
| Classified | Metadata, collection, and tags are assigned | `set_entity_metadata` or create-time assignment | Validated, Revised, Replaced, Deleted |
| Validated | Object passed required validation checks | `validate_scene_update` | Revised, Replaced, Archived, Deleted |
| Revised | Object was modified after initial validation | transform, regroup, material change, metadata update | Classified, Validated, Replaced, Deleted |
| Replaced | Object identity persists but representation changes | replace proxy with asset, upgrade fidelity | Classified, Validated, Archived |
| Archived | Object retained for record or hidden from active workflow | archival or soft-delete policy | Deleted |
| Deleted | Object no longer participates in the scene | delete action | None |
| Cancelled | Planned object never created | planning change | None |

### Asset Exemplar Lifecycle

| State | Description | Allowed Actions |
| --- | --- | --- |
| Imported | Asset added to library area | inspect, classify, reject, approve |
| Classified | Metadata and category assigned | approve, revise metadata |
| Approved | Safe for model reuse | list, instantiate |
| Deprecated | May remain in library but should not be chosen by default | inspect, phase out |
| Removed | No longer available in library | none |

Key rule: Asset Exemplars never transition into editable scene objects. Asset Instances are created from them instead.

### Validation Lifecycle

| State | Description | Allowed Actions |
| --- | --- | --- |
| Requested | Validation payload defined | execute, cancel |
| Running | Validation engine collecting checks | complete, fail |
| Passed | No blocking errors | snapshot, accept |
| Failed | One or more blocking errors | revise scene, rerun |
| Accepted with Warnings | Non-blocking warnings remain | snapshot, accept, revise |

## Revision History

| Date | Change |
| --- | --- |
| 2026-04-11 | Updated the domain analysis to match the four-PRD split, added the standalone targeting and interrogation slice, aligned capability groups to the updated guide, and added lightweight front matter plus revision history. |
