# Signal: Greenfield Semantic Authoring Is Viable But Lifecycle Gaps Remain

**Date**: `2026-04-15`
**Source**: External feedback from a live MCP validation pass conducted prior to `SEM-03` implementation
**Related PRD**: [Semantic Scene Modeling](../prds/prd-semantic-scene-modeling.md)
**Related HLDs**:
- [Semantic Scene Modeling](../hlds/hld-semantic-scene-modeling.md)
- [Scene Targeting And Interrogation](../hlds/hld-scene-targeting-and-interrogation.md)
**Related Tasks**:
- [SEM-02 Complete First-Wave Semantic Creation Vocabulary](../tasks/semantic-scene-modeling/SEM-02-complete-first-wave-semantic-creation-vocabulary/task.md)
- [SEM-03 Add Metadata Mutation For Managed Scene Objects](../tasks/semantic-scene-modeling/SEM-03-add-metadata-mutation-for-managed-scene-objects/task.md)
- [STI-01 Targeting MVP And Find Entities](../tasks/scene-targeting-and-interrogation/STI-01-targeting-mvp-and-find-entities/task.md)
- [STI-02 Explicit Surface Interrogation Via Sample Surface Z](../tasks/scene-targeting-and-interrogation/STI-02-explicit-surface-interrogation-via-sample-surface-z/task.md)
**Status**: `captured`
**Disposition**: `follow-up recommended across semantic lifecycle, hierarchy control, and terrain-aware authoring`

## Summary

External validation confirmed that the new semantic MCP surface is now reliable enough for greenfield semantic object authoring.

The feedback materially changes the posture from:

- basic semantic creation is unreliable

to:

- basic semantic creation is viable for real use

The validated gap is no longer first-wave creation stability. The remaining operator pain is concentrated in:

- hierarchy control
- semantic lifecycle operations after creation
- adoption of existing acceptable geometry
- terrain-aware path authoring
- richer structure representations
- deeper structured inspection without `eval_ruby`

This signal is intentionally preserved as a point-in-time checkpoint gathered before `SEM-03` implementation. It should be read as evidence about the live surface under that boundary, not as a claim about every later repo state.

## Verified Greenfield Capability

The external pass verified live semantic creation, lookup, metadata presence, and cleanup for all currently exposed site-element types:

- `structure`
- `pad`
- `path`
- `retaining_edge`
- `planting_mass`
- `tree_proxy`

For all of these, the feedback reports that:

- `create_site_element` succeeded
- `find_entities` resolved the created object by `sourceElementId`
- `delete_component` cleaned the object up successfully
- the object carried expected `su_mcp` managed metadata

This means the current surface has crossed an important threshold:

- greenfield semantic object creation is reliable enough for probe workflows, early-stage modeling, and simple retained or proposed scene objects

## What The Feedback Says Works Well

- Top-level semantic object creation is working.
- Semantic lookup by `sourceElementId` works for MCP-authored objects.
- The basic create/query/delete workflow is stable.
- Tag or layer assignment and material assignment are supported.
- The current surface is viable for probe workflows and simple semantic scene authoring.

## What Still Forced Ruby Or Workarounds

### 1. No parented semantic creation

`create_site_element` appeared to create only top-level objects. The feedback found no MCP-level way to specify a parent group or component at creation time.

### 2. No reparent or move API

After creation, there was still no MCP-level way to move a managed semantic object under an existing container. This keeps scene organization and canonical-root workflows dependent on Ruby or manual restructuring.

### 3. No adoption flow for existing acceptable geometry

This was reported as the highest-value missing capability. If acceptable geometry already exists, there is no supported way to declare that existing group or component as the managed representation for a semantic object. That gap forced wrapper-and-transplant workarounds instead of direct semantic adoption.

### 4. Path creation is planar rather than terrain-hosted

The path contract supported centerline, width, thickness, and a single elevation, but did not appear to support:

- terrain hosting
- drape to target surface
- per-vertex `z`
- host-surface sampling during creation

The observed result was horizontal bands rather than grade-following paths.

### 5. Structure creation is still primitive-oriented

The feedback judged `structure` creation good enough for simple footprint masses, but not sufficient for more complex retained proxies or multipart forms unless simplification is acceptable. Without an adoption path, richer forms still require Ruby.

### 6. Deep inspection is still too limited

Top-level inspection was good enough for basic verification, but nested debugging, descendant inspection, and exact attribute-dictionary inspection still required `eval_ruby`. A structured descendant or metadata inspection tool would reduce that dependency.

### 7. Enum discoverability is weak

Refusal messages helped, but the feedback still identified a missing discoverable schema or supported-value query path for enums and approved values.

## Most Important Findings

- Greenfield semantic authoring is viable.
- The main remaining limitations are not basic creation reliability.
- The main remaining limitations are hierarchy control, terrain-aware geometry authoring, adoption of existing geometry, richer structure forms, and deeper inspection.
- Manual nested `su_mcp` metadata injection is not a substitute for true MCP-managed object creation.
- The biggest practical productivity win would come from eliminating rebuild or transplant work when acceptable geometry already exists.

## Why This Signal Matters

This feedback narrows the next planning question. The problem is no longer primarily:

- can the platform create semantic objects at all

It is now more specifically:

- can the platform manage semantic objects in realistic governed scene workflows without Ruby

That is an important shift because it suggests future semantic work should not be framed only as more first-wave creation breadth. The higher-value follow-on areas are lifecycle-safe management and authoring fidelity after the object already exists or must fit into a governed scene hierarchy.

## Highest-Value Improvements Preserved By This Signal

1. Add `parentEntityId` or `parentPersistentId` support to `create_site_element`.
2. Add reparent or move support for managed semantic objects.
3. Add support to adopt an existing group or component as a managed semantic object.
4. Add terrain-hosted path creation.
5. Add richer structure authoring or explicit semantic wrapper or container support.
6. Add nested inspection and attribute-dictionary inspection through MCP.
