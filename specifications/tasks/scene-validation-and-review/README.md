# Scene Validation and Review Tasks

## Source Specifications

These tasks are derived from:

- [Scene Validation and Review HLD](../../hlds/hld-scene-validation-and-review.md)
- [PRD: Scene Validation and Review](../../prds/prd-scene-validation-and-review.md)

## Task Set Intent

This task set covers the first iteration for the scene validation and review capability.

The current iteration intentionally persists a compact set of follow-on tasks around the same primary validation surface:

- `validate_scene_update` MVP with initial generic geometry-aware checks
- public structured measurement through `measure_scene`
- terrain-aware measurement evidence after generic measurement and explicit profile sampling settle
- targeted interrogation-backed follow-ons that broaden `validate_scene_update` while measurement and validation remain distinct workflow surfaces

The wider capability remains acknowledged, but deferred work is not promoted into active task folders for this iteration.

## Current Task Order

1. [SVR-01 Establish `validate_scene_update` MVP With Initial Generic Geometry-Aware Checks](SVR-01-establish-validate-scene-update-mvp-with-initial-generic-geometry-aware-checks/task.md)
2. [SVR-03 Establish `measure_scene` MVP With Structured Measurement Modes](SVR-03-measure-scene-mvp-with-structured-measurement-modes/task.md)
3. [SVR-04 Add Terrain-Aware Measurement Evidence](SVR-04-add-terrain-aware-measurement-evidence/task.md)
4. [SVR-02 Broaden `validate_scene_update` With Surface-Relationship And Reference-Point Validation](SVR-02-broaden-validate-scene-update-with-surface-relationship-and-reference-point-validation/task.md)

## Deferred Follow-Ons

The following follow-ons were explicitly deferred during iteration planning:

- extend `validate_scene_update` with measured dimension and tolerance verdicts once the reusable public measurement contract is established strongly enough to avoid validation-local measurement drift
- add semantic property validation for persisted managed-object values when workflows need contract-state verification distinct from measured geometry
- add asset-integrity and asset-placement validation once asset-reuse lineage, protection, and placement-outcome semantics are mature enough to validate against as a product capability rather than ad hoc runtime detail
- add `capture_scene_snapshot` once the review-artifact contract, returned artifact-reference shape, and host-side snapshot behavior are stable enough to support a first-class review surface
- broaden `validate_scene_update` further with topology-backed geometry validation once reusable edge-network analysis and related topology evidence are available for validation consumers
- add terrain-aware validation diagnostics after terrain-aware measurement evidence is stable, including slope, clearance-to-terrain, grade-break, trench/hump, or fairness checks where the contract can stay evidence-producing rather than terrain-editing

## Deferred Capability Dependencies

The deferred follow-ons remain blocked or under-defined in these areas:

- agreement on how later validation verdicts should consume the reusable `measure_scene` contract without duplicating measurement logic or overloading direct measurement outputs with acceptance semantics
- bounded public contract design for semantic property validation so stored-value checks stay distinct from measured dimension checks
- asset-reuse maturity around lineage, protection, and placement outcomes so validation can check product semantics rather than low-level implementation side effects
- stable review-artifact contract and host-side snapshot viability, including how artifacts are named, referenced, and consumed by downstream review workflows
- reusable topology evidence suitable for validation reuse, especially where validation would otherwise need to infer edge-network correctness from bespoke tool-specific logic
- explicit host-target terrain profile or section evidence from the targeting/interrogation slice for any terrain-aware measurement mode that needs sampled terrain rather than generic object bounds or face evidence

## Notes

- The first iteration is intentionally expectation-scoped. It does not define whole-scene auditing or scene-health linting.
- The first task must align with the shared selector direction already present in the repository and must not invent a bespoke validation-only selector grammar.
- Selector extraction versus direct reuse is intentionally left for later task planning and implementation discovery. The iteration only commits to selector alignment and reuse discipline.
- The first task must provide value beyond `find_entities` and `get_entity_info`, so it includes one initial generic geometry-aware check family rather than stopping at metadata-only validation.
- Follow-on broadening should continue to deepen `validate_scene_update` where the missing capability is still part of structured validation, while keeping direct measurement questions on the separate `measure_scene` boundary.
- `SVR-03` now owns the public `measure_scene` MVP so direct structured measurement does not have to hide inside `validate_scene_update`.
- `SVR-03` is terrain-compatible but not terrain-diagnostic: terrain-shaped targets may be measured by the shipped generic modes.
- `SVR-04` adds the bounded terrain-aware `measure_scene` branch `terrain_profile/elevation_summary`, built on `SVR-03` and `STI-03` internals. Slope, clearance-to-terrain, grade-break, trench/hump, and fairness measurements remain follow-ons.
- `SVR-02` follows with richer interrogation-backed geometry relationships that can be supported today through explicit surface-interrogation reuse; topology-backed validation remains deferred until the targeting/interrogation slice exposes that seam.
- Semantic stored-value validation remains acknowledged as a real consumer signal, but it is deferred so direct measurement and validation stay distinct from stored semantic-property inspection.
