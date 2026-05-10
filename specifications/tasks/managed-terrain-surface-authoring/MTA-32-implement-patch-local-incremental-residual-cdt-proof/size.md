# Size: MTA-32 Implement Patch-Local Incremental Residual CDT Proof

**Task ID**: `MTA-32`  
**Title**: `Implement Patch-Local Incremental Residual CDT Proof`  
**Status**: `calibrated`  
**Created**: `2026-05-09`  
**Last Updated**: `2026-05-10`  

**Related Task**: [task.md](./task.md)  
**Related Plan**: [plan.md](./plan.md)  
**Related Summary**: [summary.md](./summary.md)  

---

<!-- SIZE:IDENTITY:START -->
## Identity

- **Task Archetype**: `archetype:performance-sensitive`
- **Primary Scope Area**: `scope:managed-terrain`
- **Likely Systems Touched**:
  - `systems:terrain-output`
  - `systems:terrain-mesh-generator`
  - `systems:terrain-kernel`
  - `systems:test-support`
- **Validation Modes**:
  - `validation:performance`
  - `validation:regression`
  - `validation:contract`
- **Likely Analog Class**: patch-local incremental terrain output algorithm proof after disabled CDT scaffold

### Identity Notes
- Seeded from the external CDT terrain output review and calibrated MTA-31 closeout. This task is an algorithmic proof slice, not default production enablement.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Internally adds a materially different CDT proof path for patch-local terrain output quality and cost, while public behavior stays stable. |
| Technical Change Surface | 4 | Likely spans CDT output internals, residual refinement, triangulation update behavior, patch domain mapping, diagnostics, and comparison fixtures. |
| Hidden Complexity Suspicion | 4 | Incremental constrained triangulation, residual candidate invalidation, patch boundary constraints, and quality/runtime gates are high-risk. |
| Validation Burden Suspicion | 4 | Must prove both terrain accuracy and timing against MTA-31 evidence; local tests alone are unlikely to be enough. |
| Dependency / Coordination Suspicion | 3 | Depends on MTA-31 CDT seams/probes, MTA-10/MTA-11 window concepts, and external review direction, but not native binaries or public contracts. |
| Scope Volatility Suspicion | 4 | May split if incremental Ruby CDT is too large, patch quality cannot be preserved, or native support becomes unavoidable earlier than expected. |
| Confidence | 2 | Direction is clear, but algorithmic feasibility and patch quality/performance are unproven. |

### Early Signals
- MTA-31 proved feature selection and geometry planning are not the dominant bottleneck; residual refinement and repeated full retriangulation dominate.
- The task intentionally changes both locality and the residual insertion algorithm, rather than only shrinking the existing global loop.
- MTA-24, MTA-25, and MTA-31 all show terrain backend work carries high validation and rework pressure.
- Default CDT enablement and native/C++ packaging are explicitly out of scope.

### Early Estimate Notes
- Use MTA-31 as the closest calibrated analog for performance-sensitive CDT work, but do not import its actuals as certainty. This task has higher algorithmic uncertainty because it adds incremental refinement behavior.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

> Filled during task planning. This is the main pre-implementation estimate.

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Adds a substantial internal proof capability for patch-local residual CDT, including proof evidence, fallback behavior, and hosted validation, while public behavior remains unchanged. |
| Technical Change Surface | 4 | Spans new CDT patch collaborators, domain/window mapping, explicit constraints, residual metrics, affected-region triangulation updates, proof result evidence, tests, structure checks, and hosted validation seams. |
| Implementation Friction Risk | 4 | Current triangulator is batch-oriented and prototype-grade for constraints; affected-region insertion, candidate invalidation, and boundary preservation are likely to resist clean implementation. |
| Validation Burden Risk | 4 | Must prove locality, quality metrics, no public leak, boundary budgets, updater diagnostics, candidate invalidation, performance signal versus MTA-31, and hosted command-shaped behavior. |
| Dependency / Coordination Risk | 3 | Depends on MTA-31 CDT seams, dirty-window/output-plan behavior, feature geometry inputs, hosted SketchUp validation, and clean boundaries with MTA-33/MTA-34, but avoids public contracts and native binaries. |
| Discovery / Ambiguity Risk | 4 | Algorithm feasibility, Ruby cavity performance, constraint robustness, and final numeric hosted thresholds remain uncertain until Phase 0 and updater implementation evidence exist. |
| Scope Volatility Risk | 3 | Explicit non-goals and gates reduce drift, but the task may still split if affected-region updates cannot preserve constraints or hosted evidence shows Ruby proof is insufficient. |
| Rework Risk | 4 | Prior MTA-24/MTA-25/MTA-31 calibration shows CDT backend work often needs validation-driven correction; boundary/perimeter policy and updater semantics are especially rework-prone. |
| Confidence | 2 | Planning evidence is strong and decisions are explicit, but implementation feasibility and performance are unproven until Phase 0 and affected-region tests run. |

### Top Assumptions
- The runtime-owned `cdt/patches` seam can be introduced without public MCP contract changes.
- A bounded affected-region updater can be proven in Ruby well enough to produce useful internal evidence, even if it does not become production-ready.
- Hybrid boundary anchors will avoid the MTA-25 perimeter-seeding explosion while still producing useful seam evidence for MTA-34.
- Phase 0 hosted-shape evidence can freeze numeric thresholds before deep algorithm work without forcing a redesign.

### Estimate Breakers
- The current Ruby triangulator cannot support any reliable constrained affected-region update without effectively rebuilding the full patch.
- Hosted command-shaped proof invocation exposes state/window/feature-context shape mismatches that require reworking the proof seam.
- Boundary constraints or feature intersections produce frequent degeneracy/unsupported recovery failures that make the Ruby proof non-credible.
- Numeric hosted thresholds after Phase 0 imply much broader fixtures, native triangulation, or production replacement scope.

### Predicted Signals
- MTA-31 hosted evidence isolated residual refinement and repeated full retriangulation as the dominant scaling problem.
- MTA-25 recorded boundary-shape overcorrection from full perimeter seeding, which directly informed the hybrid anchor policy.
- The plan adds several new ownership seams and test boundaries under CDT output internals.
- No public contract change and no production replacement narrow runtime orchestration risk, but not algorithmic risk.
- Phase 0 threshold gating leaves performance confidence intentionally low until hosted proof shape is observed.

### Predicted Estimate Notes
- Closest analog is MTA-31, with MTA-25 and MTA-24 supplying rework and validation-burden calibration. MTA-32 is narrower than default CDT enablement, but riskier algorithmically because it must prove affected-region residual insertion and candidate invalidation.
- The estimate assumes MTA-32 remains an internal proof. If implementation absorbs MTA-33 feature relevance, MTA-34 replacement, native triangulation, or public tuning controls, the profile should be re-estimated before continuing.
<!-- SIZE:PREDICTED:END -->

---

<!-- SIZE:CHALLENGE:START -->
## Challenge Review

> Filled when the estimate is pressure-tested through external review, premortem, or controlled consensus.

### Agreed Drivers
- High implementation friction is confirmed by the premortem: the current Ruby CDT path is batch-oriented, constraint recovery is prototype-grade, and affected-region insertion needs explicit rebuild detection.
- High validation burden is confirmed, but the driver is not just hosted case count; it is proving locality, candidate invalidation, no public leak, failure classifications, and timing/scaling evidence.
- High rework risk is confirmed by MTA-24/MTA-25/MTA-31 analogs and by the premortem finding that broad `bounded_neighborhood` or silent rebuild behavior could falsely pass without extra instrumentation.
- Public contract and production replacement risks are bounded by the finalized plan's no-public-delta and no-production-replacement guardrails.

### Contested Drivers
- Validation burden could come down if Phase 0 hosted-shape evidence is clean and threshold freezing is straightforward, but prior hosted CDT work makes that optimistic.
- Scope volatility is contained by explicit gates and non-goals, but a hard failure of the affected-region updater could still force split/follow-up work.
- Dependency risk remains a 3 rather than 4 because MTA-33/MTA-34 are explicit boundaries, not prerequisites for completing the proof.

### Missing Evidence
- Phase 0 hosted-shape evidence and concrete numeric thresholds.
- Updater tests proving no full patch rebuild per residual insertion.
- Candidate recomputation evidence proving per-insertion recomputation stays affected-region or bounded-neighborhood limited.
- Hosted timing comparison against MTA-31 fixtures.

### Recommendation
- Keep the predicted scores unchanged. The premortem tightened implementation guardrails but did not reduce algorithmic uncertainty enough to lower friction, validation, discovery, or rework risk.
- Proceed with the finalized plan only as an internal proof; re-estimate if implementation absorbs durable feature relevance, SketchUp replacement, native triangulation, public controls, or broader validation matrices.

### Challenge Notes
- Premortem surfaced two concrete anti-gaming controls: rebuild detection and `recomputationScope` with a default `affected_triangle_count * 2` recomputation gate. These controls confirm the high-risk profile rather than resizing it.
- Hosted validation is scored high because it includes performance/scaling interpretation and Phase 0 threshold gating, not merely because several hosted fixtures are required.
<!-- SIZE:CHALLENGE:END -->

---

<!-- SIZE:DRIFT:START -->
## Drift Log

> Append only. Log only material changes that affect estimate shape, risk, confidence, or validation burden.

| Date | Phase / Checkpoint | Event Type | Severity (1-3) | Dimension Affected | Predictable Earlier? | Notes |
|---|---|---|---:|---|---|---|
| 2026-05-10 | Live proof validation | Validation-driven correction | 2 | Validation Burden, Rework | Partly | Live visual inspection showed height residual alone could accept visually poor topology. Added topology quality diagnostics/gates and reran focused, full, package, code-review, and live side-terrain validation. |

### Drift Notes
- Material validation drift occurred when live proof meshes exposed the need for topology acceptance,
  not only sample-height residual acceptance.
<!-- SIZE:DRIFT:END -->

---

<!-- SIZE:ACTUAL:START -->
## Actual Profile

> Filled at the end of implementation. Do not overwrite predicted values.

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Delivered a substantial internal proof capability with quality, topology, fallback, timing, and debug evidence while preserving public behavior. |
| Technical Change Surface | 4 | Added multiple CDT patch collaborators, dirty-window preservation, proof result evidence, topology diagnostics, debug rendering, cleanup markers, structure tests, unit tests, and live validation artifacts. |
| Actual Implementation Friction | 4 | Affected-region insertion, bounded recomputation, topology acceptance, and live SketchUp proof rendering all required implementation/revalidation loops. |
| Actual Validation Burden | 4 | Required focused patch suites, full Ruby validation, RuboCop, package verification, grok-4.3 review, deployed SketchUp verification, and a clean five-fixture live rerun. |
| Actual Dependency Drag | 2 | Relied on existing MTA-31 seams, terrain storage/output-plan behavior, and SketchUp deployment, but did not require native binaries, public contracts, MTA-33, or MTA-34. |
| Actual Discovery Encountered | 4 | Live proof exposed that height residual alone was insufficient because visually poor topology could still pass sample metrics. |
| Actual Scope Volatility | 3 | Scope stayed inside MTA-32, but validation added topology gating, debug proof rendering discipline, and explicit cleanup markers to avoid drifting into production replacement. |
| Actual Rework | 4 | Review/live feedback drove concrete rework: dirty-window preservation, multi-insertion loop, debug renderer identity, and topology quality gating. |
| Final Confidence in Completeness | 4 | High confidence for MTA-32 proof goals after automated validation, external review, and topology-gated live side-terrain matrix; production replacement remains explicitly out of scope. |

### Actual Signals
- Patch proof remains internal and CDT remains disabled by default.
- Accepted live fixtures passed both residual and topology gates with no rebuild detection.
- Forced budget fixture returned deterministic fallback instead of accepting sparse topology.
- Debug proof meshes were rendered only as separate evidence groups.
- Public MCP request/response shape did not change.
- Validation-only runtime surfaces are marked `MTA-32 VALIDATION-ONLY` for MTA-33/MTA-34 cleanup.

### Actual Notes
- MTA-32 proved a local incremental residual shape and produced the handoff evidence for later
  MTA-33/MTA-34 work. It did not implement feature relevance or production patch replacement.
<!-- SIZE:ACTUAL:END -->

---

<!-- SIZE:VALIDATION-EVIDENCE:START -->
## Validation Evidence Summary

> Fill only the sections that are relevant. Say `not applicable` where needed.

### Automated Validation
- Focused MTA-32 tests: `42 runs`, `660 assertions`, `0 failures`, `0 errors`.
- Full Ruby suite: `1215 runs`, `12045 assertions`, `0 failures`, `0 errors`, `37 skips`.
- RuboCop on touched surface: `22 files inspected`, `0 offenses`.
- Package verification: `bundle exec rake package:verify` produced `dist/su_mcp-1.6.0.rbz`.
- Post-marker focused tests: `9 runs`, `289 assertions`, `0 failures`, `0 errors`.
- Post-marker RuboCop on marked files: `3 files inspected`, `0 offenses`.
- Post-marker package verification again produced `dist/su_mcp-1.6.0.rbz`.

### Hosted / Manual Validation
- SketchUp-hosted live validation ran in `TestGround.skp` after code review follow-up and
  redeployment. It created clean side terrains and proof meshes for `flat_smooth`,
  `rough_high_relief`, `boundary_constraint`, `feature_intersection`, and `budget_exceeded`.
- Four accepted fixtures passed residual and topology gates; the forced low-budget fixture returned
  deterministic `topology_quality_failed` fallback evidence.

### Performance Validation
- Accepted live proof fixtures completed under the frozen `0.05s` patch threshold.
- Insertions ranged from `42` to `50` for accepted fixtures; accepted face counts were `72` or `80`.

### Migration / Compatibility Validation
- No state migration, public MCP schema change, or package-layout incompatibility was introduced.

### Operational / Rollout Validation
- Default terrain output remains the current backend.
- Debug meshes are validation artifacts only and do not route through production replacement.
- Cleanup markers identify proof-only debug mesh output, debug renderer, rebuild test hook, and
  proof-only candidate queue behavior for later removal, rehome, or hardening.

### Validation Notes
- Hosted validation required one meaningful fix loop after visual inspection exposed topology risk.
- Final clean live run id: `20260510165448`.
- Final recalibration includes the validation-only cleanup-marker pass requested after closeout.
<!-- SIZE:VALIDATION-EVIDENCE:END -->

---

<!-- SIZE:DELTA:START -->
## Estimation Delta Review

> Filled during final calibration. Compare prediction to actual behavior.

- **Most Underestimated Dimension**: Actual Rework. The estimate expected CDT rework, but live visual proof added a topology-quality gate after residual metrics appeared green.
- **Most Overestimated Dimension**: Dependency drag. MTA-33/MTA-34 boundaries held, and no native adapter or public contract coordination was needed.
- **Signal Present Early But Underweighted**: Prior CDT evidence already showed that residual numbers can hide visual/topological issues; MTA-32 needed topology gates earlier in the proof acceptance criteria.
- **Genuinely Unknowable Factor**: Whether affected-region Ruby cavity updates would produce visually credible local topology before a live scene proof.
- **Future Similar Tasks Should Assume**: Terrain output proof tasks need live visual topology checks, explicit topology metrics, and cleanup markers for validation-only scaffolding in the first proof loop.

### Calibration Notes
- Dominant actual failure mode: height residual success could mask invalid or visually poor proof
  topology. Future patch-local terrain work should treat topology/seam evidence as first-class
  proof acceptance from the start.
- Validation-only proof helpers should be marked at introduction time so later production tasks do
  not have to rediscover which code is proof scaffolding.
<!-- SIZE:DELTA:END -->

---

<!-- SIZE:TAGS:START -->
## Retrieval Tags

Use canonical values from the repo task-estimation taxonomy when present. Keep this as a compact analog-search index, not coverage. Target 8-14 tags.

- `archetype:performance-sensitive`
- `scope:managed-terrain`
- `systems:terrain-output`
- `systems:terrain-kernel`
- `systems:terrain-mesh-generator`
- `validation:performance`
- `validation:regression`
- `contract:no-public-shape-change`
- `host:performance`
- `risk:performance-scaling`
- `risk:topology-quality`
- `volatility:high`
- `friction:high`
- `confidence:high`
<!-- SIZE:TAGS:END -->
