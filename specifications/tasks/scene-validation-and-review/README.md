# Scene Validation and Review Tasks

## Source Specifications

These tasks are derived from:

- [Scene Validation and Review HLD](../../hlds/hld-scene-validation-and-review.md)
- [PRD: Scene Validation and Review](../../prds/prd-scene-validation-and-review.md)

## Task Set Intent

This task set covers the first iteration for the scene validation and review capability.

The current iteration intentionally persists only the one confirmed core task:

- `validate_scene_update` MVP with initial generic geometry-aware checks

The wider capability remains acknowledged, but deferred work is not promoted into active task folders for this iteration.

## Current Task Order

1. [SVR-01 Establish `validate_scene_update` MVP With Initial Generic Geometry-Aware Checks](SVR-01-establish-validate-scene-update-mvp-with-initial-generic-geometry-aware-checks/task.md)

## Deferred Follow-Ons

The following follow-ons were explicitly deferred during iteration planning:

- broaden `validate_scene_update` with richer geometry-aware validation once reusable interrogation evidence is available for validation consumers, including stable surface-relationship, reference-point, or topology-oriented inputs
- expose public structured measurement through `measure_scene` once the reusable measurement contract, supported mode set, and selector-alignment posture are settled strongly enough for a standalone public surface
- add asset-integrity and asset-placement validation once asset-reuse lineage, protection, and placement-outcome semantics are mature enough to validate against as a product capability rather than ad hoc runtime detail
- add `capture_scene_snapshot` once the review-artifact contract, returned artifact-reference shape, and host-side snapshot behavior are stable enough to support a first-class review surface

## Deferred Capability Dependencies

The deferred follow-ons remain blocked or under-defined in these areas:

- richer interrogation evidence suitable for validation reuse, especially where validation would otherwise need to infer geometry correctness from bespoke tool-specific logic
- agreement on the reusable measurement contract, including which measurement families belong inside validation first versus which justify a standalone `measure_scene` surface
- asset-reuse maturity around lineage, protection, and placement outcomes so validation can check product semantics rather than low-level implementation side effects
- stable review-artifact contract and host-side snapshot viability, including how artifacts are named, referenced, and consumed by downstream review workflows

## Notes

- The first iteration is intentionally expectation-scoped. It does not define whole-scene auditing or scene-health linting.
- The first task must align with the shared selector direction already present in the repository and must not invent a bespoke validation-only selector grammar.
- Selector extraction versus direct reuse is intentionally left for later task planning and implementation discovery. The iteration only commits to selector alignment and reuse discipline.
- The first task must provide value beyond `find_entities` and `get_entity_info`, so it includes one initial generic geometry-aware check family rather than stopping at metadata-only validation.
