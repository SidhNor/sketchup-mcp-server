# Scene Validation and Review Tasks

## Source Specifications

These tasks are derived from:

- [Scene Validation and Review HLD](../../hlds/hld-scene-validation-and-review.md)
- [PRD: Scene Validation and Review](../../prds/prd-scene-validation-and-review.md)

## Task Set Intent

This task set covers the first iteration for the scene validation and review capability.

The current iteration intentionally persists a compact set of follow-on tasks around the same primary validation surface:

- `validate_scene_update` MVP with initial generic geometry-aware checks
- measured dimension and tolerance checks inside `validate_scene_update` before a public measurement surface exists
- targeted interrogation-backed follow-ons that broaden `validate_scene_update` before introducing new public review tools

The wider capability remains acknowledged, but deferred work is not promoted into active task folders for this iteration.

## Current Task Order

1. [SVR-01 Establish `validate_scene_update` MVP With Initial Generic Geometry-Aware Checks](SVR-01-establish-validate-scene-update-mvp-with-initial-generic-geometry-aware-checks/task.md)
2. [SVR-03 Extend `validate_scene_update` With Measured Dimension And Tolerance Checks](SVR-03-extend-validate-scene-update-with-dimension-and-diagnostic-evidence-checks/task.md)
3. [SVR-02 Broaden `validate_scene_update` With Surface-Relationship And Reference-Point Validation](SVR-02-broaden-validate-scene-update-with-surface-relationship-and-reference-point-validation/task.md)

## Deferred Follow-Ons

The following follow-ons were explicitly deferred during iteration planning:

- expose public structured measurement through `measure_scene` once the reusable measurement contract, supported mode set, and selector-alignment posture are settled strongly enough for a standalone public surface
- add semantic property validation for persisted managed-object values when workflows need contract-state verification distinct from measured geometry
- add asset-integrity and asset-placement validation once asset-reuse lineage, protection, and placement-outcome semantics are mature enough to validate against as a product capability rather than ad hoc runtime detail
- add `capture_scene_snapshot` once the review-artifact contract, returned artifact-reference shape, and host-side snapshot behavior are stable enough to support a first-class review surface
- broaden `validate_scene_update` further with topology-backed geometry validation once reusable edge-network analysis and related topology evidence are available for validation consumers

## Deferred Capability Dependencies

The deferred follow-ons remain blocked or under-defined in these areas:

- agreement on the reusable public measurement contract beyond the internal validation seam, including which measurement families justify a standalone `measure_scene` surface
- bounded public contract design for semantic property validation so stored-value checks stay distinct from measured dimension checks
- asset-reuse maturity around lineage, protection, and placement outcomes so validation can check product semantics rather than low-level implementation side effects
- stable review-artifact contract and host-side snapshot viability, including how artifacts are named, referenced, and consumed by downstream review workflows
- reusable topology evidence suitable for validation reuse, especially where validation would otherwise need to infer edge-network correctness from bespoke tool-specific logic

## Notes

- The first iteration is intentionally expectation-scoped. It does not define whole-scene auditing or scene-health linting.
- The first task must align with the shared selector direction already present in the repository and must not invent a bespoke validation-only selector grammar.
- Selector extraction versus direct reuse is intentionally left for later task planning and implementation discovery. The iteration only commits to selector alignment and reuse discipline.
- The first task must provide value beyond `find_entities` and `get_entity_info`, so it includes one initial generic geometry-aware check family rather than stopping at metadata-only validation.
- Follow-on broadening should continue to deepen `validate_scene_update` where the missing capability is still part of structured validation, rather than introducing debug-oriented public micro-tools.
- `SVR-03` now owns measured dimension and tolerance checks inside `validate_scene_update`, using reusable internal measurement evidence without forcing early public `measure_scene` exposure.
- `SVR-02` follows with richer interrogation-backed geometry relationships that can be supported today through explicit surface-interrogation reuse; topology-backed validation remains deferred until the targeting/interrogation slice exposes that seam.
- Semantic stored-value validation remains acknowledged as a real consumer signal, but it is deferred so `dimension` checks keep their geometry-facing meaning.
