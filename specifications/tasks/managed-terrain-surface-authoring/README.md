# Managed Terrain Surface Authoring Tasks

## Source Specifications

These tasks are derived from:

- [Managed Terrain Surface Authoring HLD](../../hlds/hld-managed-terrain-surface-authoring.md)
- [PRD: Managed Terrain Surface Authoring](../../prds/prd-managed-terrain-surface-authoring.md)
- [Managed Terrain Phase 1 UE Research Reference](../../research/managed-terrain/ue-reference-phase1.md)

## Task Set Intent

This task set covers the first managed terrain authoring iteration. It is intentionally separate from semantic hardscape creation: `path`, `pad`, and `retaining_edge` remain Managed Scene Objects outside terrain state.

The current task order proves terrain authoring through concrete, testable increments:

- domain and research reference grounding
- terrain state and storage foundation
- creation of a simple Managed Terrain Surface and adoption of a supported existing surface
- bounded grade edit MVP
- corridor transition kernel
- local terrain fairing kernel
- scalable terrain representation strategy for localized detail and larger terrain extents
- production bulk output adoption and region-aware output planning
- partial terrain output regeneration
- durable localized terrain representation v2

## Current Task Order

1. [MTA-01 Establish Managed Terrain Domain And Research Reference Posture](MTA-01-establish-managed-terrain-domain-and-research-reference-posture/task.md)
2. [MTA-02 Build Terrain State And Storage Foundation](MTA-02-build-terrain-state-and-storage-foundation/task.md)
3. [MTA-03 Create Or Adopt Managed Terrain Surface](MTA-03-adopt-supported-surface-as-managed-terrain/task.md)
4. [MTA-04 Implement Bounded Grade Edit MVP](MTA-04-implement-bounded-grade-edit-mvp/task.md)
5. [MTA-05 Implement Corridor Transition Terrain Kernel](MTA-05-implement-corridor-transition-terrain-kernel/task.md)
6. [MTA-06 Implement Local Terrain Fairing Kernel](MTA-06-implement-local-terrain-fairing-kernel/task.md)
7. [MTA-07 Define Scalable Terrain Representation Strategy](MTA-07-define-scalable-terrain-representation-strategy/task.md)
8. [MTA-08 Adopt Bulk Full-Grid Terrain Output In Production](MTA-08-adopt-bulk-full-grid-terrain-output-in-production/task.md)
9. [MTA-09 Define Region-Aware Terrain Output Planning Foundation](MTA-09-define-region-aware-terrain-output-planning-foundation/task.md)
10. [MTA-10 Implement Partial Terrain Output Regeneration](MTA-10-implement-partial-terrain-output-regeneration/task.md)
11. [MTA-11 Design And Implement Durable Localized Terrain Representation v2](MTA-11-design-and-implement-durable-localized-terrain-representation-v2/task.md)

## Deferred Follow-Ons

Deferred work is not promoted into active task folders in this iteration:

- broad terrain source compatibility beyond the supported adoption path
- sidecar terrain-state storage
- broad mesh repair or unrestricted TIN surgery
- interactive sculpt or brush UI
- erosion, weathering, or procedural terrain generation
- public Unreal-style terrain tools such as flatten, smooth, or ramp

## Notes

- Each implementation task must carry its own TDD and live verification expectations. Recovery cases such as corrupt payloads, missing derived output, stale output, and unsupported versions belong in the task that introduces the relevant behavior.
- The UE research reference is non-normative research input only. It may inform internal terrain math and kernel design, but it does not define public MCP tool names or Ruby architecture names.
- Existing `STI-*`, `SVR-*`, `SEM-*`, and `PLAT-*` tasks remain dependency history and should not be rewritten by this task set.
