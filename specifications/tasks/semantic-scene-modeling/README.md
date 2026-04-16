# Semantic Scene Modeling Tasks

## Source Specifications

These tasks are derived from:

- [Semantic Scene Modeling HLD](../../hlds/hld-semantic-scene-modeling.md)
- [PRD: Semantic Scene Modeling](../../prds/prd-semantic-scene-modeling.md)

## Task Set Intent

This task set covers the first semantic capability slice, the contract-direction spike that followed it, and the next chosen implementation shells derived from the updated PRD and HLD.

The current task set persists the three confirmed core tasks, one follow-up refinement task, one contract-validation spike task, and the next three implementation shells:

- semantic core plus the first `create_site_element` vertical slice
- completion of the remaining first-wave semantic creation vocabulary
- explicit metadata mutation for Managed Scene Objects
- alignment of shipped `tree_proxy` geometry with the accepted volumetric baseline captured during validation
- validation of the exploratory semantic `v2` contract direction through a minimal Ruby normalizer spike
- builder-native `v2` adoption for `path` and `structure`
- minimal composition primitives to keep multipart work out of atomic creation
- builder-native `v2` adoption for `pad` and `retaining_edge`

## Current Task Order

1. [SEM-01 Establish Semantic Core and First Vertical Slice](SEM-01-establish-semantic-core-and-first-vertical-slice/task.md)
2. [SEM-02 Complete First-Wave Semantic Creation Vocabulary](SEM-02-complete-first-wave-semantic-creation-vocabulary/task.md)
3. [SEM-03 Add Metadata Mutation for Managed Scene Objects](SEM-03-add-metadata-mutation-for-managed-scene-objects/task.md)
4. [SEM-04 Align Tree Proxy Geometry With Accepted Volumetric Baseline](SEM-04-align-tree-proxy-geometry-with-accepted-volumetric-baseline/task.md)
5. [SEM-05 Validate V2 Semantic Contract Via Ruby Normalizer Spike](SEM-05-validate-v2-semantic-contract-via-ruby-normalizer-spike/task.md)
6. [SEM-06 Adopt Builder-Native V2 Input for Path and Structure](SEM-06-adopt-builder-native-v2-input-for-path-and-structure/task.md)
7. [SEM-07 Add Minimal Composition Primitives](SEM-07-add-minimal-composition-primitives/task.md)
8. [SEM-08 Adopt Builder-Native V2 Input for Pad and Retaining Edge](SEM-08-adopt-builder-native-v2-input-for-pad-and-retaining-edge/task.md)

## Deferred Follow-Ons

The following follow-ons were intentionally kept out of the active task folders for this iteration:

- define managed-object compatibility behavior for generic mutation tools such as `transform_component` and `set_material`
- support identity-preserving rebuild and replacement flows for Managed Scene Objects
- define duplication and controlled deletion rules for managed objects beyond the minimal composition slice
- promote next-wave semantic element types such as `tree_instance`, `seat`, `water_feature_proxy`, and possibly `terrain_patch`

## Notes

- `SEM-03` is explicitly blocked by `STI-01` because semantic metadata mutation must reuse the delivered targeting contract rather than introduce a semantic-side lookup subsystem.
- Contract updates are embedded into each active task that changes the public Python/Ruby tool surface. There is no standalone semantic contract task.
- The active set is intentionally narrower than the full PRD. It proves the semantic capability in three core slices before expanding into rebuild, compatibility, or next-wave semantic work.
- `SEM-04` is a refinement follow-up created after live geometry review. It preserves the existing semantic contract while capturing a stricter accepted baseline for `tree_proxy` output.
- `SEM-05` is a validation spike task. It does not adopt the exploratory `v2` contract direction by itself; it exists to prove or falsify that direction through the smallest practical Ruby-owned normalization slice before any future contract decision.
- `SEM-06`, `SEM-07`, and `SEM-08` are draft task shells created after the PRD and HLD were updated to treat the sectioned `v2` direction as the chosen implementation posture. Each of these tasks still requires `task-planning` before implementation work starts.
