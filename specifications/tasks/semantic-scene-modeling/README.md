# Semantic Scene Modeling Tasks

## Source Specifications

These tasks are derived from:

- [Semantic Scene Modeling HLD](../../hlds/hld-semantic-scene-modeling.md)
- [PRD: Semantic Scene Modeling](../../prds/prd-semantic-scene-modeling.md)

## Task Set Intent

This task set covers the first semantic capability slice, the contract-direction spike that followed it, and the current follow-on shells derived from the updated PRD, HLD, and the latest iteration-planning review.

The current task set persists the completed first-wave semantic work and the next chosen follow-on shells:

- semantic core plus the first `create_site_element` vertical slice
- completion of the remaining first-wave semantic creation vocabulary
- explicit metadata mutation for Managed Scene Objects
- alignment of shipped `tree_proxy` geometry with the accepted volumetric baseline captured during validation
- validation of the exploratory semantic `v2` contract direction through a minimal Ruby normalizer spike
- public `create_site_element` contract cutover to the sectioned create shape plus builder-native migration for `path` and `structure`
- limited hierarchy-maintenance primitives for managed-object organization and repair
- builder-native migration for the remaining first-wave semantic families
- lifecycle primitives needed to make richer built-form authoring materially real
- richer built-form and composed-feature authoring inside the current semantic product boundary
- managed-object maintenance alignment for post-create semantic revision behavior
- horizontal-cross-section terrain-drape realization for hosted semantic paths
- governed duplication and managed deletion policy

## Current Task Order

1. [SEM-01 Establish Semantic Core and First Vertical Slice](SEM-01-establish-semantic-core-and-first-vertical-slice/task.md)
2. [SEM-02 Complete First-Wave Semantic Creation Vocabulary](SEM-02-complete-first-wave-semantic-creation-vocabulary/task.md)
3. [SEM-03 Add Metadata Mutation for Managed Scene Objects](SEM-03-add-metadata-mutation-for-managed-scene-objects/task.md)
4. [SEM-04 Align Tree Proxy Geometry With Accepted Volumetric Baseline](SEM-04-align-tree-proxy-geometry-with-accepted-volumetric-baseline/task.md)
5. [SEM-05 Validate V2 Semantic Contract Via Ruby Normalizer Spike](SEM-05-validate-v2-semantic-contract-via-ruby-normalizer-spike/task.md)
6. [SEM-06 Cut Over Create Site Element To The Sectioned Contract And Adopt Builder-Native V2 Input For Path And Structure](SEM-06-adopt-builder-native-v2-input-for-path-and-structure/task.md)
7. [SEM-07 Add Limited Hierarchy Maintenance Primitives](SEM-07-add-minimal-composition-primitives/task.md)
8. [SEM-08 Adopt Builder-Native V2 Input for the Remaining First-Wave Families](SEM-08-adopt-builder-native-v2-input-for-pad-and-retaining-edge/task.md)
9. [SEM-09 Realize Lifecycle Primitives Needed for Richer Built-Form Authoring](SEM-09-realize-lifecycle-primitives-needed-for-richer-built-form-authoring/task.md)
10. [SEM-10 Add Richer Built-Form and Composed Feature Authoring](SEM-10-add-richer-built-form-and-composed-feature-authoring/task.md)
11. [SEM-11 Align Managed-Object Maintenance Surface](SEM-11-align-managed-object-maintenance-surface/task.md)
12. [SEM-12 Add Governed Duplication and Managed Deletion Policy](SEM-12-add-governed-duplication-and-managed-deletion-policy/task.md)
13. [SEM-13 Realize Horizontal Cross-Section Terrain Drape for Paths](SEM-13-realize-horizontal-cross-section-terrain-drape-for-paths/task.md)

## Deferred Follow-Ons

The following follow-ons remain intentionally deferred from the active task folders:

- promote next-wave semantic element types such as `tree_instance`, `seat`, `water_feature_proxy`, and possibly `terrain_patch`

## Notes

- `SEM-03` is explicitly blocked by `STI-01` because semantic metadata mutation must reuse the delivered targeting contract rather than introduce a semantic-side lookup subsystem.
- Contract updates are embedded into each active task that changes the public Python/Ruby tool surface. There is no standalone semantic contract task.
- The active set is intentionally narrower than the full PRD. It proves the semantic capability in three core slices before expanding into rebuild, compatibility, or next-wave semantic work.
- `SEM-04` is a refinement follow-up created after live geometry review. It preserves the existing semantic contract while capturing a stricter accepted baseline for `tree_proxy` output.
- `SEM-05` is a validation spike task. It does not adopt the exploratory `v2` contract direction by itself; it exists to prove or falsify that direction through the smallest practical Ruby-owned normalization slice before any future contract decision.
- `SEM-06` is the authoritative contract-cutover task for semantic creation. It removes the dual public create posture and makes the sectioned contract the single `create_site_element` baseline while migrating `path` and `structure` to builder-native sectioned input.
- `SEM-07` remains separate from contract migration. It carries only the limited hierarchy-maintenance posture introduced after the lifecycle gap review.
- `SEM-08` completes the remaining first-wave family migration under the sectioned create-contract baseline by covering `pad`, `retaining_edge`, `planting_mass`, and `tree_proxy`.
- `SEM-09` deliberately narrows the earlier lifecycle-hardening idea to the primitives needed for richer built-form authoring. It is not a full terrain or broad maintenance task.
- `SEM-10` captures the next richer authoring slice inside the current semantic PRD boundary. Terrain authoring remains out of scope for the active set.
- `SEM-11` and `SEM-12` move managed-object maintenance, duplication, and deletion policy after the richer built-form authoring slice instead of forcing all hardening work to land first.
- `SEM-10` and `SEM-11` are now completed and live-validated against SketchUp-hosted hierarchy and managed-maintenance flows.
- `SEM-12` remains the next draft follow-on for governed duplication and managed deletion policy.
- `SEM-13` is now completed and live-validated: `path + surface_drape` builds a smoothed terrain-following top ribbon with horizontal cross-sections, coherent downward thickness shell output, and structured refusals.
