# Size: MTA-23 Prototype Intent-Constrained Adaptive Output Backend

**Task ID**: `MTA-23`
**Title**: Prototype Intent-Constrained Adaptive Output Backend
**Status**: `calibrated`
**Created**: 2026-05-06
**Last Updated**: 2026-05-07

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
| Functional Scope | 2 | Stayed validation-only: no production backend swap, no public MCP contract change, and no user-facing behavior change. |
| Technical Change Surface | 3 | Added feature geometry, policy, prototype backend, comparison/failure artifacts, hosted probe support, fixture integration, and no-leak tests. |
| Actual Implementation Friction | 3 | Real mesh emission, feature derivation, hard/firm/soft scoring, and policy fixes resisted a straight-line implementation, but did not force production architecture rework. |
| Actual Validation Burden | 4 | Closeout required local suites plus repeated live SketchUp sidecar matrices, post-deploy monkey patches, shared-state bakeoffs, hard-intent bakeoffs, and aggressive varied cases. |
| Actual Dependency Drag | 3 | Completion depended on MTA-22 fixtures, MTA-20 feature intent, MTA-21 current backend behavior, user deployment timing, and live SketchUp MCP access. |
| Actual Discovery Encountered | 4 | The evidence materially changed the verdict from candidate-failing to serious upgrade candidate, and revealed current backend hard-intent failures. |
| Actual Scope Volatility | 3 | Task stayed prototype-only, but evidence redirected MTA-24 from production promotion to CDT/bakeoff and expanded live validation scope. |
| Actual Rework | 2 | Follow-up fixes were contained to hard crossing classification, hard-anchor filtering, live monkey patches, and closeout artifact corrections. |
| Final Confidence in Completeness | 3 | Strong local and hosted evidence supports the prototype verdict; confidence is limited by unoptimized runtime and unresolved production backend selection. |

### Actual Signals
- Feature geometry was validated in focused Ruby tests and live SketchUp audit overlay.
- Current-vs-MTA-23 shared-state bakeoff showed MTA-23 was substantially more compact than current
  on adopted/stress scene cases while preserving clean topology.
- Hard preserve/fixed-anchor failures were shared with the current simplifier rather than unique to
  MTA-23.
- Aggressive varied bakeoff showed strong compactness but exposed runtime, height-error, and
  fixed-anchor tuning risks.
- MTA-23 remained validation-only and did not change public tool contracts or production terrain
  output behavior.

### Actual Notes
- The dominant actual failure mode was not feature-geometry derivation; it was proving whether the
  adaptive-grid backend was a production candidate versus a strong baseline for CDT comparison.
- The `mta23_*` filenames are accepted as temporary prototype identifiers and should be renamed or
  removed when a production backend is selected.
<!-- SIZE:ACTUAL:END -->

---

<!-- SIZE:VALIDATION-EVIDENCE:START -->
## Validation Evidence Summary

> Fill only the sections that are relevant. Say `not applicable` where needed.

### Automated Validation
- Focused MTA-23 feature/candidate suite passed: `25 runs, 148 assertions, 0 failures`.
- Terrain suite passed: `344 runs, 5495 assertions, 0 failures, 3 skips`.
- Full Ruby test sweep before live-check expansion passed: `941 runs, 7812 assertions, 0 failures`.
- RuboCop on affected MTA-23 files and earlier full RuboCop sweep reported no offenses.
- Package verification before live-check expansion produced `dist/su_mcp-1.2.0.rbz`.
- Final targeted closeout sweep passed: `63 runs, 2548 assertions, 0 failures`.
- `git diff --check` passed after closeout edits.

### Hosted / Manual Validation
- Live checks ran through MCP wrapper `eval_ruby` against SketchUp `26.1.189`, model `TestGround`.
- Hosted sidecars covered corrected MTA-22 created-corridor rows, expanded hard/firm/soft probes,
  single-terrain varied-intent matrix, feature-geometry audit overlay, scene-level MTA-22 fixture
  inspection, current-vs-MTA-23 shared-state bakeoff, hard-intent bakeoff, and aggressive varied
  bakeoff.
- Generated validation sidecars were explicitly separate from existing scene geometry and remained
  inspectable in the live scene.

### Performance Validation
- Runtime budgets were exercised at `8s`, `12s`, and `20s` prototype limits with `1024` and `4096`
  cell budgets.
- MTA-23 repeatedly hit runtime limits on adopted/stress and aggressive cases, so runtime remains an
  optimization risk rather than a production-ready result.
- Face-count evidence was strong: MTA-23 was materially more compact than current simplifier in
  shared-state adopted/stress and aggressive varied bakeoffs.

### Migration / Compatibility Validation
- Public MCP contracts, dispatcher routes, schemas, and production terrain output behavior were not
  changed.
- Contract stability/no-leak tests were expanded so MTA-23 candidate internals do not appear in
  public terrain evidence.

### Operational / Rollout Validation
- Production rollout was not applicable; MTA-23 was validation-only.
- User deployment was required for live SketchUp verification, and post-deploy monkey patches were
  used for live checks after code fixes.
- Save-copy and undo smoke evidence was collected for representative sidecar behavior; save/reopen
  was not treated as decisive production evidence.

### Validation Notes
- Hosted validation burden was high because evidence interpretation changed the recommendation and
  required multiple live comparison shapes, not because any one hosted check was inherently large.
- The final validation story supports a prototype recommendation, not production backend selection.
<!-- SIZE:VALIDATION-EVIDENCE:END -->

---

<!-- SIZE:DELTA:START -->
## Estimation Delta Review

> Filled during final calibration. Compare prediction to actual behavior.

- **Most Underestimated Dimension**: Validation burden. The prediction expected hosted proof, but
  actual closeout required repeated live scene-level bakeoffs, current-backend comparison,
  hard-intent comparison, aggressive varied cases, and interpretation of runtime/quality tradeoffs.
- **Most Overestimated Dimension**: Implementation friction. The prototype was technically
  substantial, but the bounded validation-only architecture avoided the MTA-19-style production
  rollback/rewrite.
- **Signal Present Early But Underweighted**: MTA-19's hosted-validation lesson was weighted, but
  the need to compare against current backend hard-intent behavior before judging MTA-23 was
  underweighted.
- **Genuinely Unknowable Factor**: Whether MTA-23 would be a failed backend, a production candidate,
  or a strong upgrade baseline was unknowable until live current-vs-MTA-23 and aggressive bakeoffs
  ran.
- **Future Similar Tasks Should Assume**: Validation-only terrain backend prototypes need a
  three-way evidence path early: candidate versus current, candidate versus hard-intent diagnostics,
  and candidate versus aggressive hosted terrain before production conclusions are credible.

### Calibration Notes
- Actual recommendation: keep MTA-23 adaptive-grid as a serious upgrade candidate, do not blindly
  production-swap, and prototype CDT/breakline output next using the same feature-geometry substrate.
- Future estimates should classify live SketchUp bakeoffs by retest and interpretation cost, not by
  raw case count.
- Temporary task-named prototype files are acceptable for validation slices only when cleanup is
  explicitly recorded for production promotion.
<!-- SIZE:DELTA:END -->

---

<!-- SIZE:TAGS:START -->
## Retrieval Tags

- `archetype:prototype-bakeoff`
- `scope:managed-terrain`
- `systems:terrain-feature-geometry`
- `systems:terrain-adaptive-grid`
- `validation:performance`
- `validation:hosted-matrix`
- `validation:bakeoff`
- `host:special-scene`
- `contract:no-public-shape-change`
- `risk:performance-scaling`
- `risk:hard-intent-enforcement`
- `backend:adaptive-grid`
- `volatility:high`
- `confidence:moderate`
<!-- SIZE:TAGS:END -->
