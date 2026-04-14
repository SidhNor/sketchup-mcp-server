# Semantic Scene Modeling Tasks

## Source Specifications

These tasks are derived from:

- [Semantic Scene Modeling HLD](../../hlds/hld-semantic-scene-modeling.md)
- [PRD: Semantic Scene Modeling](../../prds/prd-semantic-scene-modeling.md)

## Task Set Intent

This task set covers the first iteration for the semantic scene modeling capability.

The current iteration persists only the three confirmed core tasks:

- semantic core plus the first `create_site_element` vertical slice
- completion of the remaining first-wave semantic creation vocabulary
- explicit metadata mutation for Managed Scene Objects

## Current Task Order

1. [SEM-01 Establish Semantic Core and First Vertical Slice](SEM-01-establish-semantic-core-and-first-vertical-slice/task.md)
2. [SEM-02 Complete First-Wave Semantic Creation Vocabulary](SEM-02-complete-first-wave-semantic-creation-vocabulary/task.md)
3. [SEM-03 Add Metadata Mutation for Managed Scene Objects](SEM-03-add-metadata-mutation-for-managed-scene-objects/task.md)

## Deferred Follow-Ons

The following follow-ons were intentionally kept out of the active task folders for this iteration:

- define managed-object compatibility behavior for generic mutation tools such as `transform_component` and `set_material`
- support identity-preserving rebuild and replacement flows for Managed Scene Objects
- define grouping, duplication, and controlled deletion rules for managed objects
- promote next-wave semantic element types such as `tree_instance`, `seat`, `water_feature_proxy`, and possibly `terrain_patch`

## Notes

- `SEM-03` is explicitly blocked by `STI-01` because semantic metadata mutation must reuse the delivered targeting contract rather than introduce a semantic-side lookup subsystem.
- Contract updates are embedded into each active task that changes the public Python/Ruby tool surface. There is no standalone semantic contract task.
- The active set is intentionally narrower than the full PRD. It proves the semantic capability in three core slices before expanding into rebuild, compatibility, or next-wave semantic work.
