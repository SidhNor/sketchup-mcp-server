# Scene Targeting and Interrogation Tasks

## Source Specifications

These tasks are derived from:

- [Scene Targeting and Interrogation HLD](../../hlds/hld-scene-targeting-and-interrogation.md)
- [PRD: Scene Targeting and Interrogation](../../prds/prd-scene-targeting-and-interrogation.md)

## Task Set Intent

This task set covers the first iteration and first terrain-evidence follow-on for the scene targeting and interrogation capability.

The current task order intentionally keeps targeting and interrogation bounded to evidence-producing surfaces:

- `find_entities` MVP
- `sample_surface_z`
- profile or section sampling as a host-targeted extension of `sample_surface_z`

The wider capability remains acknowledged, but deferred work is not promoted into active task folders for this iteration.

## Current Task Order

1. [STI-01 Targeting MVP and `find_entities`](STI-01-targeting-mvp-and-find-entities/task.md)
2. [STI-02 Explicit Surface Interrogation via `sample_surface_z`](STI-02-explicit-surface-interrogation-via-sample-surface-z/task.md)
3. [STI-03 Extend `sample_surface_z` With Profile and Section Sampling](STI-03-extend-sample-surface-z-with-profile-and-section-sampling/task.md)

## Deferred Follow-Ons

The following follow-ons were explicitly deferred during iteration planning:

- expand `find_entities` beyond MVP to add metadata-aware and collection-aware filtering once those conventions exist
- implement `analyze_edge_network`
- add `get_bounds`
- add `get_named_collections`

## Notes

- This iteration does not claim full delivery of the current PRD wording for `find_entities`; it defines a narrowed MVP that excludes metadata and collection filtering.
- `STI-01` establishes the shared targeting contract that `STI-02` depends on.
- Terrain profile or section interrogation remains evidence-producing and host-targeted; terrain patch replacement, grading, and fairing remain outside this task set unless a later bounded mutation capability is explicitly defined.
- Deferred work remains explicit here so it is visible without being treated as active iteration backlog.
