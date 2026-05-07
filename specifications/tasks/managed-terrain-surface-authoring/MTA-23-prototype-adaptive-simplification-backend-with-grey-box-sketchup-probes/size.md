# Size: MTA-23 Prototype Intent-Constrained Adaptive Output Backend

**Task ID**: `MTA-23`  
**Title**: Prototype Intent-Constrained Adaptive Output Backend  
**Status**: `challenged`  
**Created**: 2026-05-06  
**Last Updated**: 2026-05-06  

**Related Task**: [task.md](./task.md)  
**Related Plan**: [plan.md](./plan.md)  
**Related Summary**: none yet  

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
- **Validation Modes**: `validation:performance`, `validation:hosted-matrix`, `validation:regression`
- **Likely Analog Class**: validation-only intent-constrained adaptive output prototype

### Identity Notes
- This is prototype work, but it must produce real candidate geometry. The backend-neutral
  constraint layer is reusable only if it is proven through output behavior.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 2 | Produces prototype evidence and a backend recommendation without changing production behavior. |
| Technical Change Surface | 3 | Likely spans intent constraint expansion, candidate mesh generation, fixture comparison, and hosted probes. |
| Hidden Complexity Suspicion | 4 | MTA-19 showed terrain topology can fail despite correct height samples; backend choice remains uncertain. |
| Validation Burden Suspicion | 4 | Needs local comparisons plus hosted SketchUp proof before recommending production direction. |
| Dependency / Coordination Suspicion | 3 | Depends on revised MTA-22 quality, MTA-20 feature context, MTA-21 baseline, and live hosted access. |
| Scope Volatility Suspicion | 4 | Candidate may fail as a backend, as a constraint layer, or by proving CDT/Delaunay is needed next. |
| Confidence | 1 | The desired outcome is clear, but the candidate strategy is intentionally experimental. |

### Early Signals
- MTA-20 gives explicit feature intent that MTA-19 did not have.
- The first proof vehicle is intended-aware adaptive grid/quadtree, not an assumed final backend.
- A failed candidate can still be useful if it separates constraint-layer failure from backend-family failure.
- Hosted proof remains a hard gate because MTA-19 failed in live SketchUp despite local confidence.

### Early Estimate Notes
- Treat as high-discovery prototype work. Avoid planner-only completion and avoid jumping into full
  constrained Delaunay/CDT unless MTA-23 evidence justifies it.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

> Filled during task planning. This is the main pre-implementation estimate.

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | 2 | Produces validation-only backend evidence and a next-direction recommendation without changing public or production behavior. |
| Technical Change Surface | 3 | Adds feature-geometry derivation, a real candidate simplification kernel, candidate metrics/rows, fixture comparison, no-leak checks, and hosted probes. |
| Implementation Friction Risk | 4 | Real terrain simplification, hard/firm/soft geometry scoring, protected/anchor checks, deterministic splitting, and isolated emission all have known topology traps from MTA-19. |
| Validation Burden Risk | 4 | Requires pure Ruby proof, MTA-22 candidate comparison, public no-leak coverage, performance/budget interpretation, and hosted sidecar topology evidence. |
| Dependency / Coordination Risk | 3 | Depends on implemented MTA-20/MTA-21/MTA-22 artifacts plus hosted SketchUp access, but no public-client or upstream ownership change is planned. |
| Discovery / Ambiguity Risk | 4 | Step 05 resolved design ambiguity, but premortem found the decisive evidence question remains unproven: adaptive may still fail corridor/topology quality or become dense despite correct feature geometry. |
| Scope Volatility Risk | 3 | Scope is bounded against production/CDT work, but results may redirect MTA-24 toward productionization, CDT/Delaunay, feature-geometry repair, or stop/replan. |
| Rework Risk | 3 | Detailed predicates reduce drift, but candidate/backend evidence may force revisions inside feature derivation, split behavior, metrics, or hosted probe handling. |
| Confidence | 2 | Plan is externally reviewed and concrete, but confidence stays moderate-low until the real kernel and hosted candidate rows exist. |

### Top Assumptions
- MTA-20 `featureIntent` payloads are sufficient to derive the agreed simple `TerrainFeatureGeometry`
  primitives for representative MTA-22 cases.
- The enhanced adaptive grid/quadtree prototype can produce comparable candidate geometry without
  arbitrary insertion, breakline insertion, dense fallback, or production wiring.
- MTA-22 fixtures and baseline rows are adequate to evaluate candidate behavior and identify when
  CDT/Delaunay follow-up is justified.
- Hosted sidecar probes can be run for representative promising rows without mutating existing scene
  geometry or requiring disruptive active-model save/reopen.

### Estimate Breakers
- Feature geometry cannot derive stable protected regions, anchors, pressure regions, or reference
  segments from the existing MTA-20 intent payloads.
- The adaptive candidate cannot satisfy hard preserve/fixed requirements or firm corridor/survey/
  planar residuals without becoming effectively dense.
- Candidate topology or performance fails hosted sidecar probes despite acceptable local fixture
  metrics.
- Public response paths require schema or docs changes to expose enough evidence, violating the
  no-public-contract-change boundary.
- MTA-22 fixtures prove insufficient to support a credible productionize/CDT/repair/stop
  recommendation.

### Predicted Signals
- MTA-19 is a strong negative analog: real simplifier code passed local tests and still failed
  hosted corridor topology, latency, and reliability validation.
- MTA-20 provides durable feature intent, but intentionally leaves feature-aware output generation
  unimplemented.
- MTA-21 provides conforming adaptive output and emission patterns, but remains a baseline repair,
  not a feature-aware backend.
- MTA-22 provides the benchmark substrate; candidate rows and recommendation evidence are still
  wholly owned by MTA-23.
- Step 05 consensus reduced design ambiguity but added strict evidence obligations: role-specific
  firm residuals, deterministic digests, hard-first split reasons, hosted sidecar proof, and failure
  classification.

### Predicted Estimate Notes
- This prediction is based on the 2026-05-06 draft technical plan, the formal Step 05 decision
  record folded into that plan, calibrated MTA-19/MTA-20/MTA-21/MTA-22 lessons, and external
  Step 05 pressure testing.
- Functional scope is moderate because production behavior and public contracts remain unchanged.
  Technical and validation scores are higher because MTA-23 must still implement a real
  simplification kernel and prove it against fixtures and hosted SketchUp behavior.
- Discovery risk remains very high despite Step 05 clarity because the premortem surfaced an
  evidence-level uncertainty: the adaptive prototype may produce real rows yet still be unable to
  distinguish productionizable behavior from CDT/Delaunay need without hosted topology and
  role-specific residual proof.
<!-- SIZE:PREDICTED:END -->

---

<!-- SIZE:CHALLENGE:START -->
## Challenge Review

> Filled when the estimate is pressure-tested through external review, premortem, or controlled consensus.

### Agreed Drivers
- Functional scope remains `2`: MTA-23 produces validation-only backend evidence and a
  recommendation, with no public or production behavior change.
- Technical change surface remains `3`: the plan spans feature geometry, a real candidate kernel,
  candidate row metrics, fixture comparison, no-leak coverage, and hosted probes.
- Implementation friction remains `4`: the real simplification kernel, deterministic split policy,
  hard checks, topology residuals, and isolated emission carry MTA-19-class engineering resistance.
- Validation burden remains `4`: correctness depends on local unit coverage, MTA-22 comparison,
  public no-leak tests, performance/budget interpretation, hosted topology, save/reopen gating for
  productionization, and failure-capture artifacts.
- Dependency risk remains `3`: MTA-20/MTA-21/MTA-22 are implemented, but hosted SketchUp access and
  fixture evidence quality still gate completion.

### Contested Drivers
- Discovery / Ambiguity was revised from `3` to `4`. Step 05 removed design ambiguity, but the
  premortem showed the decisive unknown is implementation evidence: adaptive may satisfy the formal
  predicates yet still fail corridor endpoint/side-band topology, hosted normal-break checks, or
  useful face-count thresholds.
- Rework risk could be argued as `4` from MTA-19 history, but remains `3` because MTA-23 is
  explicitly validation-only, isolates prototype emission, and treats candidate failure as a useful
  outcome rather than production rework.
- Scope volatility could be argued as `4` because outcomes can redirect to CDT/Delaunay or feature
  repair, but remains `3` because the task boundary itself forbids productionization and CDT work in
  MTA-23.

### Missing Evidence
- No implementation proof that `TerrainFeatureGeometry` can be derived stably across representative
  explicit and adopted/irregular MTA-22 cases.
- No proof that the adaptive prototype can satisfy hard preserve/fixed checks and firm
  corridor/survey/planar residuals without becoming effectively dense.
- No hosted sidecar evidence for candidate topology, normal-break behavior, undo, save-copy, or
  save/reopen recheck.
- No candidate result rows proving the final recommendation gates can classify productionize,
  CDT/Delaunay follow-up, feature-geometry repair, and stop/replan cases without manual judgment.

### Recommendation
- Confirm the estimate with the single Discovery / Ambiguity revision to `4`.
- Proceed to implementation using the finalized `WARN` premortem gate.
- Treat missing topology residuals, absent failure-capture artifacts, public leakage, hard corridor
  scope creep, dense fallback, or production wiring as stop-and-correct violations.
- Do not reinterpret a local-only candidate win as productionizable; hosted topology and
  persistence evidence are required by the plan.

### Challenge Notes
- Challenge evidence came from the Step 05 consensus, isolated Grok 4.3 artifact review, and Step 11
  premortem failure analysis.
- The premortem produced plan changes rather than blockers: topology residuals, max normal-break
  thresholds, failure-capture artifacts, and save/reopen downgrade rules.
- No unresolved Tigers remain in the finalized plan. Accepted Elephants are adaptive corridor
  topology failure and adopted/irregular feature-geometry insufficiency; both have explicit
  validation and recommendation paths.
- The final plan and challenged size profile agree: this is a bounded no-public-contract prototype
  with very high implementation/validation/discovery risk because it must produce decisive terrain
  meshing evidence before downstream production or CDT decisions.
<!-- SIZE:CHALLENGE:END -->

---

<!-- SIZE:DRIFT:START -->
## Drift Log

> Append only. Log only material changes that affect estimate shape, risk, confidence, or validation burden.

| Date | Phase / Checkpoint | Event Type | Severity (1-3) | Dimension Affected | Predictable Earlier? | Notes |
|---|---|---|---:|---|---|---|

### Drift Notes
- No material drift recorded yet.
<!-- SIZE:DRIFT:END -->

---

<!-- SIZE:ACTUAL:START -->
## Actual Profile

> Filled at the end of implementation. Do not overwrite predicted values.

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | <0-4> | <short note> |
| Technical Change Surface | <0-4> | <short note> |
| Actual Implementation Friction | <0-4> | <short note> |
| Actual Validation Burden | <0-4> | <short note> |
| Actual Dependency Drag | <0-4> | <short note> |
| Actual Discovery Encountered | <0-4> | <short note> |
| Actual Scope Volatility | <0-4> | <short note> |
| Actual Rework | <0-4> | <short note> |
| Final Confidence in Completeness | <0-4> | <short note> |

### Actual Signals
- Not filled yet.

### Actual Notes
- Not filled yet.
<!-- SIZE:ACTUAL:END -->

---

<!-- SIZE:VALIDATION-EVIDENCE:START -->
## Validation Evidence Summary

> Fill only the sections that are relevant. Say `not applicable` where needed.

### Automated Validation
- Not filled yet.

### Hosted / Manual Validation
- Not filled yet.

### Performance Validation
- Not filled yet.

### Migration / Compatibility Validation
- Not filled yet.

### Operational / Rollout Validation
- Not filled yet.

### Validation Notes
- Not filled yet.
<!-- SIZE:VALIDATION-EVIDENCE:END -->

---

<!-- SIZE:DELTA:START -->
## Estimation Delta Review

> Filled during final calibration. Compare prediction to actual behavior.

- **Most Underestimated Dimension**: Not filled yet.
- **Most Overestimated Dimension**: Not filled yet.
- **Signal Present Early But Underweighted**: Not filled yet.
- **Genuinely Unknowable Factor**: Not filled yet.
- **Future Similar Tasks Should Assume**: Not filled yet.

### Calibration Notes
- Not filled yet.
<!-- SIZE:DELTA:END -->

---

<!-- SIZE:TAGS:START -->
## Retrieval Tags

- `archetype:performance-sensitive`
- `scope:managed-terrain`
- `systems:terrain-output`
- `systems:terrain-mesh-generator`
- `systems:terrain-kernel`
- `systems:test-support`
- `validation:performance`
- `validation:hosted-matrix`
- `validation:regression`
- `host:special-scene`
- `contract:no-public-shape-change`
- `risk:performance-scaling`
- `volatility:high`
- `friction:high`
- `rework:high`
- `confidence:low`
<!-- SIZE:TAGS:END -->
