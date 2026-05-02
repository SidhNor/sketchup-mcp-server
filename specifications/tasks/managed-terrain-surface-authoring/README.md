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
- scalable terrain representation strategy for tiled terrain state and larger terrain extents
- production bulk output adoption and region-aware output planning
- partial terrain output regeneration
- circular local terrain regions and preserve zones
- survey point constraint terrain editing
- base/detail-preserving survey correction evaluation
- tiled heightmap v2 with adaptive SketchUp output when v1 heightmap fidelity is insufficient
- terrain edit contract discoverability after the April 28 terrain modelling signal
- narrow planar region fit implementation as an explicit terrain intent
- profile QA and monotonic terrain diagnostic ownership
- bounded visual terrain edit UI for SketchUp-facing selection and parameter control over managed terrain edits
- failed/reverted detail-preserving adaptive terrain output simplification attempt after tiled
  heightmap v2 output proof
- internal terrain feature constraints for derived output planning and diagnostics after the
  MTA-19 simplifier failure

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
11. [MTA-11 Migrate To Tiled Heightmap V2 With Adaptive Output](MTA-11-design-and-implement-durable-localized-terrain-representation-v2/task.md)
12. [MTA-12 Add Circular Terrain Regions And Preserve Zones](MTA-12-add-circular-terrain-regions-and-preserve-zones/task.md)
13. [MTA-13 Implement Survey Point Constraint Terrain Edit](MTA-13-implement-survey-point-constraint-terrain-edit/task.md)
14. [MTA-14 Evaluate Base Detail Preserving Survey Correction](MTA-14-evaluate-base-detail-preserving-survey-correction/task.md)
15. [MTA-15 Harden Terrain Edit Contract Discoverability](MTA-15-harden-terrain-edit-contract-discoverability/task.md)
16. [MTA-16 Implement Narrow Planar Region Fit Terrain Intent](MTA-16-implement-narrow-planar-region-fit-terrain-intent/task.md)
17. [MTA-17 Define Profile QA And Monotonic Terrain Diagnostics](MTA-17-define-profile-qa-and-monotonic-terrain-diagnostics/task.md)
18. [MTA-18 Define Bounded Managed Terrain Visual Edit UI](MTA-18-define-bounded-managed-terrain-visual-edit-ui/task.md)
19. [MTA-19 Implement Detail Preserving Adaptive Terrain Output Simplification](MTA-19-implement-detail-preserving-adaptive-terrain-output-simplification/task.md) - failed/reverted
20. [MTA-20 Define Terrain Feature Constraint Layer For Derived Output](MTA-20-define-terrain-feature-constraint-layer-for-derived-output/task.md)

## Deferred Follow-Ons

Deferred work is not promoted into active task folders in this iteration:

- broad terrain source compatibility beyond the supported adoption path
- sidecar terrain-state storage
- broad mesh repair or unrestricted TIN surgery
- broad freeform sculpting, continuous stroke replay, or pressure-sensitive brush systems
- erosion, weathering, or procedural terrain generation
- public Unreal-style terrain tools such as flatten, smooth, or ramp
- polygon/freeform terrain edit regions
- accepting `boundary_preserving_patch_edit` as a separate mode before current regional correction plus `preserveZones` recipes are evaluated

## Notes

- Each implementation task must carry its own TDD and live verification expectations. Recovery cases such as corrupt payloads, missing derived output, stale output, and unsupported versions belong in the task that introduces the relevant behavior.
- The UE research reference is non-normative research input only. It may inform internal terrain math and kernel design, but it does not define public MCP tool names or Ruby architecture names.
- Existing `STI-*`, `SVR-*`, `SEM-*`, and `PLAT-*` tasks remain dependency history and should not be rewritten by this task set.
- `MTA-11` is now the tiled heightmap v2 plus first adaptive output escalation path. It intentionally replaces the earlier localized detail-zone direction and does not preserve v1 as a permanent runtime format.
- After `MTA-11`, public terrain create requests still use the existing `heightmap_grid` definition shape, but repository-backed terrain state is persisted as `heightmap_grid` v2 and generated output summaries report `adaptive_tin`.
- `MTA-15` is the immediate P0 follow-on from the April 28 terrain modelling signal because baseline-safe semantics must be discoverable through tools and schemas before richer terrain intent modes are added.
- `MTA-16` must preserve the distinction between current regional survey correction and explicit planar fit behavior.
- Core iteration order after the April 28 terrain modelling signal is `MTA-15`, then `MTA-16`, with `PLAT-18` able to proceed alongside the terrain work once `MTA-15` prompt-worthy recipes are clear.
- `MTA-17` is deferred/late iteration work. It should not move profile sampling or validation verdict ownership into terrain mutation; it exists to clarify ownership before diagnostics or constraints are implemented, after planar fit and initial prompt guidance settle the new workflow baseline.
- `MTA-19` followed the successful MTA-11 live verification pass, but the attempted replacement
  simplifier failed hosted corridor-heavy verification and was reverted. Future advanced
  simplification work should start as a prototype against captured failure heightfields before
  touching production runtime.
- `MTA-20` reframes the next step away from corridor-specific mesh patches and toward a generic
  internal feature-constraint layer that output generation, diagnostics, and future simplifier
  backends can consume.
