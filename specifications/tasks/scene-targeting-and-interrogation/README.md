# Scene Targeting and Interrogation Tasks

## Source Specifications

These tasks are derived from:

- [Scene Targeting and Interrogation HLD](../../hlds/hld-scene-targeting-and-interrogation.md)
- [PRD: Scene Targeting and Interrogation](../../prds/prd-scene-targeting-and-interrogation.md)

## Task Set Intent

This task set covers the first iteration for the scene targeting and interrogation capability.

The current iteration intentionally persists only the two confirmed core tasks:

- `find_entities` MVP
- `sample_surface_z`

The wider capability remains acknowledged, but deferred work is not promoted into active task folders for this iteration.

## Current Task Order

1. [STI-01 Targeting MVP and `find_entities`](STI-01-targeting-mvp-and-find-entities/task.md)
2. [STI-02 Explicit Surface Interrogation via `sample_surface_z`](STI-02-explicit-surface-interrogation-via-sample-surface-z/task.md)

## Deferred Follow-Ons

The following follow-ons were explicitly deferred during iteration planning:

- expand `find_entities` beyond MVP to add metadata-aware and collection-aware filtering once those conventions exist
- implement `analyze_edge_network`
- add bounded terrain profile or section interrogation as a follow-on to explicit host-target sampling when repeated terrain workflows need sampled evidence beyond point batches
- add `get_bounds`
- add `get_named_collections`

## Notes

- This iteration does not claim full delivery of the current PRD wording for `find_entities`; it defines a narrowed MVP that excludes metadata and collection filtering.
- `STI-01` establishes the shared targeting contract that `STI-02` depends on.
- Terrain profile or section interrogation should remain evidence-producing and host-targeted; terrain patch replacement, grading, and fairing remain outside this task set unless a later bounded mutation capability is explicitly defined.
- Deferred work remains explicit here so it is visible without being treated as active iteration backlog.
