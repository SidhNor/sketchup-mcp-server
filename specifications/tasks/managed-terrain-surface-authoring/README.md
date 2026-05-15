# Managed Terrain Surface Authoring Tasks

## Source Specifications

These tasks are derived from:

- [Managed Terrain Surface Authoring HLD](../../hlds/hld-managed-terrain-surface-authoring.md)
- [PRD: Managed Terrain Surface Authoring](../../prds/prd-managed-terrain-surface-authoring.md)
- [Managed Terrain Phase 1 UE Research Reference](../../research/managed-terrain/ue-reference-phase1.md)
- [Recommended Backend Architecture for Feature-Aware Adaptive Terrain Output](../../research/managed-terrain/recommended_new_adaptive_backend_architecture.md)

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
- conforming adaptive terrain output so mixed-resolution derived terrain does not produce visible
  T-junction or gap seams
- adaptive-output benchmark fixtures and replay evidence before any future production
  simplification backend replacement
- intent-constrained adaptive output prototyping that uses MTA-20 feature intent before any
  production backend promotion
- CDT-oriented production terrain output with current-backend fallback and cleanup of prototype
  bakeoff harnesses before long-lived production wiring
- SketchUp-facing brush overlay feedback for the initial target-height visual edit tool
- a shared Managed Terrain tool panel proven by adding local fairing as a second round-brush tool
- corridor-transition UI over the existing managed corridor edit mode
- survey-point and planar-region UI tools over the existing control-point edit modes
- CDT terrain output enablement after the disabled MTA-25 scaffold, including large feature-history
  performance, geometry containment, module ownership cleanup, and Ruby-versus-native triangulation
  evidence
- patch-local incremental residual CDT proof after MTA-31 showed that feature selection is no
  longer the dominant blocker and repeated whole-point-set retriangulation remains too expensive
- patch-relevant feature constraints so local CDT solves do not carry unrelated hard, firm, or soft
  feature history
- CDT patch replacement and seam validation over existing partial-output ownership before any
  default CDT enablement decision
- cached CDT patch output lifecycle productization after MTA-34 exposed that replacement requires
  stable CDT-owned patch output to exist before local mutation can be proven
- windowed adaptive patch output lifecycle productization as the proven production spine for fast
  local terrain edits
- failed/reverted CDT residual-frontier batching work retained only as negative evidence for why
  production terrain output should not route through the current CDT backend
- feature-aware adaptive backend planning that keeps the adaptive patch/cell production path and
  makes feature intents operational through policy, local tolerance, density pressure, forced
  subdivision, seam contracts, bounded patch components, and sparse local detail

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
21. [MTA-21 Make Adaptive Terrain Output Conforming](MTA-21-make-adaptive-terrain-output-conforming/task.md)
22. [MTA-22 Capture Adaptive Simplification Benchmark Fixtures And Replay Framework](MTA-22-capture-adaptive-terrain-regression-fixture-pack/task.md)
23. [MTA-23 Prototype Intent-Constrained Adaptive Output Backend](MTA-23-prototype-adaptive-simplification-backend-with-grey-box-sketchup-probes/task.md)
24. [MTA-24 Prototype Constrained Delaunay/CDT Terrain Output Backend And Three-Way Bakeoff](MTA-24-prototype-constrained-delaunay-cdt-terrain-output-backend-and-three-way-bakeoff/task.md)
25. [MTA-25 Productionize CDT Terrain Output With Current Backend Fallback](MTA-25-productionize-cdt-terrain-output-with-current-fallback/task.md)
26. [MTA-26 Add Managed Terrain Brush Overlay Feedback](MTA-26-add-managed-terrain-brush-overlay-feedback/task.md)
27. [MTA-27 Generalize Managed Terrain Tool Panel And Add Local Fairing](MTA-27-generalize-managed-terrain-tool-panel-and-add-local-fairing/task.md)
28. [MTA-28 Add Managed Terrain Corridor Transition UI Tool](MTA-28-add-managed-terrain-corridor-transition-ui-tool/task.md)
29. [MTA-29 Add Managed Terrain Survey Point Constraint UI Tool](MTA-29-add-managed-terrain-survey-point-constraint-ui-tool/task.md)
30. [MTA-30 Add Managed Terrain Planar Region Fit UI Tool](MTA-30-add-managed-terrain-planar-region-fit-ui-tool/task.md)
31. [MTA-31 Enable CDT Terrain Output After Disabled Scaffold](MTA-31-enable-cdt-terrain-output-after-disabled-scaffold/task.md)
32. [MTA-32 Implement Patch-Local Incremental Residual CDT Proof](MTA-32-implement-patch-local-incremental-residual-cdt-proof/task.md)
33. [MTA-33 Implement Patch-Relevant Terrain Feature Constraints](MTA-33-implement-patch-relevant-terrain-feature-constraints/task.md)
34. [MTA-34 Implement CDT Patch Replacement And Seam Validation](MTA-34-implement-cdt-patch-replacement-and-seam-validation/task.md) - closed-blocked; partial replacement infrastructure retained for MTA-35 planning
35. [MTA-35 Productize Cached CDT Patch Output Lifecycle For Windowed Terrain Edits](MTA-35-productize-cached-cdt-patch-output-lifecycle-for-windowed-terrain-edits/task.md)
36. [MTA-36 Productize Windowed Adaptive Patch Output Lifecycle For Fast Local Terrain Edits](MTA-36-productize-windowed-adaptive-patch-output-lifecycle-for-fast-local-terrain-edits/task.md)
37. [MTA-37 Implement CDT Patch Residual Frontier Batching](MTA-37-implement-cdt-patch-residual-frontier-batching/task.md) - failed/reverted; code removed, drift retained as negative evidence
38. [MTA-38 Establish Feature-Aware Adaptive Baseline, Policy, And Validation Harness](MTA-38-establish-feature-aware-adaptive-baseline-policy-and-validation-harness/task.md)
39. [MTA-39 Add Feature-Aware Tolerance And Density Fields](MTA-39-add-feature-aware-tolerance-and-density-fields/task.md)
40. [MTA-40 Add Forced Subdivision Masks For Feature-Critical Geometry](MTA-40-add-forced-subdivision-masks-for-feature-critical-geometry/task.md)
41. [MTA-41 Add Optional Deterministic Feature-Aware Diagonal Optimization](MTA-41-add-optional-deterministic-feature-aware-diagonal-optimization/task.md) - optional; not a dependency for MTA-42 through MTA-44
42. [MTA-42 Upgrade Adaptive Seam Contracts For Feature-Driven Splits](MTA-42-upgrade-adaptive-seam-contracts-for-feature-driven-splits/task.md)
43. [MTA-43 Add Patch Component Planner For Cross-Patch Features](MTA-43-add-patch-component-planner-for-cross-patch-features/task.md)
44. [MTA-44 Add Sparse Local Detail Tiles And Composed Height Oracle](MTA-44-add-sparse-local-detail-tiles-and-composed-height-oracle/task.md)

## Deferred Follow-Ons

Deferred work is not promoted into active task folders in this iteration:

- broad terrain source compatibility beyond the supported adoption path
- sidecar terrain-state storage
- broad mesh repair or unrestricted TIN surgery
- broad freeform sculpting, continuous stroke replay, or pressure-sensitive brush systems
- erosion, weathering, or procedural terrain generation
- new public Unreal-style terrain tools beyond the existing managed edit modes
- polygon/freeform terrain edit regions
- accepting `boundary_preserving_patch_edit` as a separate mode before current regional correction plus `preserveZones` recipes are evaluated
- optional local CDT islands for bounded irregular hard geometry that adaptive cells and sparse
  local detail cannot represent cleanly. CDT islands must remain an escape hatch behind the
  adaptive backend boundary, not a global terrain architecture or public backend selector.
- native acceleration for proven geometry hotspots only after profiling shows Ruby implementation
  cost is the limiting factor. Native work should remain bounded to modules such as robust
  intersections, clipping, local CDT islands, residual sampling, or validation kernels.
- broad incremental/native bakeoffs across many terrain families. Future bakeoffs should compare
  bounded modules only after the feature-aware adaptive path has stable baseline, seam, component,
  and local-detail evidence.
- default CDT terrain output enablement. Global CDT should remain disabled by default and is no
  longer the planned production path for normal terrain output.
- public terrain output backend selectors, simplification knobs, or CDT diagnostics. Backend choice
  and solver metrics should remain internal until there is a stable product posture and a separate
  contract task justifies exposing controls or telemetry.
- background/global rebuild or export-quality CDT passes. The immediate iteration is about normal
  feature-aware adaptive local edits; explicit full-output rebuild/export behavior should be planned
  separately if product needs justify it.
- visual smoothing/fairing over derived output. Smoothing must remain deferred until hard
  constraints, protected boundaries, and patch seams are stable enough that smoothing cannot weaken
  them.

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
- `MTA-21` fixes the existing adaptive TIN output baseline before any future RTIN, Delaunay,
  DELATIN, or feature-aware backend comparison. It should preserve adaptive output rather than
  reverting detailed terrain to regular full-grid production output.
- `MTA-22` captures the MTA-21 adaptive-output baseline as a benchmark fixture and replay framework,
  including varied terrain/edit families, current face counts, quality metrics, hosted-sensitive
  provenance, and known residuals such as the off-grid adopted corridor endpoint mismatch. Its purpose
  is to make later prototype comparisons meaningful.
- `MTA-23` is the next simplification step: prototype an intent-constrained adaptive output backend
  that consumes MTA-20 feature intent, emits validation-only candidate geometry, compares against the
  MTA-22 baseline, and verifies promising rows with `eval_ruby` grey-box SketchUp probes. It must not
  swap the production backend.
- `MTA-24` is redefined from production implementation into a constrained Delaunay/CDT prototype
  and three-way bakeoff, because MTA-23 kept adaptive-grid as a serious upgrade candidate but did
  not prove an unconditional production swap. Productionization should move to a later task after
  current, MTA-23 adaptive-grid, and CDT behavior are compared on the same fixture and live SketchUp
  cases.
- `MTA-25` is the CDT productionization follow-up selected by MTA-24. It must keep current
  production output as fallback while CDT production behavior is gated, clean up or isolate
  MTA-24-specific comparison and hosted-probe harnesses from production runtime ownership, and prove
  production behavior through automated and hosted SketchUp acceptance.
- `MTA-26` through `MTA-30` are the next SketchUp-facing UI follow-ups after the initial MTA-18
  toolbar/dialog/tool slice. They deliberately reuse existing managed terrain edit commands rather
  than adding terrain math: first target-height overlay feedback, then a shared panel proven by local
  fairing, then corridor-transition UI, then survey-point and planar-region point-control UI in
  separate tasks.
- `MTA-31` captures the CDT enablement work deferred from MTA-25 after the disabled-default
  closeout. It should prove large feature-history performance, effective feature-intent selection,
  geometry containment, module ownership cleanup, and the Ruby-versus-native triangulation decision
  before CDT is considered for default production output.
- `MTA-32` follows MTA-31 with a narrower architectural proof: patch-local incremental residual CDT.
  It must materially change both locality and the residual refinement loop, because MTA-31 showed
  that accurate output requires residual point insertion but repeated full retriangulation of the
  growing point set is not interactive.
- `MTA-33` keeps feature selection separate from the MTA-32 cost/quality proof. It applies
  patch-relevance to hard, firm, and soft feature constraints so local CDT solves do not pay for
  unrelated global hard-feature history.
- `MTA-34` attempted to close the local-output loop by reusing partial-output ownership lessons from
  MTA-10 for CDT patch replacement, seam validation, fallback/refusal, and hosted undo evidence. It
  is closed-blocked rather than accepted: it produced useful replacement infrastructure, but hosted
  investigation exposed the missing production precondition that no stable CDT-owned patch output
  lifecycle exists for the replacement logic to operate on.
- `MTA-35` follows directly from MTA-34 and the external CDT review. It must productize cached
  CDT-owned patch output, stable patch identity, dirty-window-to-patch mapping, repeated-edit
  metadata lifecycle, and real command-path replacement through MTA-33, MTA-32, and retained/adapted
  MTA-34 infrastructure before any default CDT enablement decision.
- `MTA-36` is the primary positive production-path reference for the next backend sequence. It
  proves windowed adaptive patch output, stable logical patch ownership, no-delete replacement,
  repeated edit behavior, reload/readback, hosted timings, and the current adaptive PatchLifecycle
  spine.
- `MTA-37` is closed as failed/reverted CDT work. Its useful output is negative evidence: a heap or
  residual batching wrapper around the current CDT backend did not address backend-call count,
  scan/retriangulation economics, or production trust.
- `MTA-38` through `MTA-44` follow the recommended feature-aware adaptive architecture. The sequence
  is harness and policy scaffolding, feature-aware tolerance/density fields, forced subdivision
  masks, adaptive seam contracts, patch component planning, and sparse local detail state. Each task
  must end with hosted public-command replay evidence using the same baseline corpus, including
  timing, face count, dirty-window/patch scope, fallback/refusal checks where relevant, and a clear
  verdict.
- `MTA-41` is optional diagonal optimization. It may be implemented when evidence shows value, but
  no downstream feature-aware adaptive task depends on it.
- Local CDT islands and native acceleration remain deferred and evidence-triggered. They should be
  planned only as bounded modules after adaptive cells, seam contracts, component planning, and local
  detail prove where they are insufficient.
