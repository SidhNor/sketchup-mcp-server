# Size: MTA-24 Prototype Constrained Delaunay/CDT Terrain Output Backend And Three-Way Bakeoff

**Task ID**: `MTA-24`
**Title**: Prototype Constrained Delaunay/CDT Terrain Output Backend And Three-Way Bakeoff
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
  - `systems:terrain-state`
  - `systems:public-contract`
- **Validation Modes**: `validation:performance`, `validation:hosted-matrix`, `validation:contract`, `validation:regression`
- **Likely Analog Class**: real comparison-only terrain backend prototype and three-way bakeoff

### Identity Notes
- This task is no longer the production implementation slot. MTA-23 evidence redirected MTA-24 into
  a constrained Delaunay/CDT prototype and three-way bakeoff before production selection.
- `TerrainFeatureGeometry` is a material task substrate even though the taxonomy does not yet have a
  canonical system tag for it.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Adds a real comparison-only CDT/breakline candidate and requires a current/adaptive/CDT recommendation. |
| Technical Change Surface | 3 | Likely touches prototype terrain output, feature-geometry consumption, triangulation core, comparison rows, and hosted sidecar support. |
| Hidden Complexity Suspicion | 4 | CDT/breakline behavior, robust constraints, fixed anchors, topology, and runtime are high-risk. |
| Validation Burden Suspicion | 4 | Requires fixture replay, hosted matrix, three-way metrics, performance, contract, and sidecar evidence. |
| Dependency / Coordination Suspicion | 3 | Depends on MTA-20 feature intent, MTA-22 fixtures, and MTA-23 adaptive-grid evidence. |
| Scope Volatility Suspicion | 3 | Scope is prototype-only but can redirect production strategy to adaptive-grid, CDT, current fallback, or hybrid. |
| Confidence | 2 | MTA-23 narrowed the question, but CDT implementation and validation risk remain substantial. |

### Early Signals
- MTA-23 adaptive-grid materially beats current simplifier on face count but still has hard-intent,
  runtime, and rough-terrain accuracy gaps.
- MTA-24 must compare current, MTA-23 adaptive-grid, and CDT on shared states.
- Productionization should be deferred until this bakeoff selects a backend or hybrid.
- The CDT candidate must be real implementation evidence, not a mock or fake shell, while still
  avoiding production wiring.

### Early Estimate Notes
- Seed shape is now based on MTA-23 evidence. Produce a full predicted estimate during MTA-24
  planning after CDT algorithm/library strategy and hosted validation mechanics are selected.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

> Filled during task planning. This is the main pre-implementation estimate.

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Adds a real comparison-only CDT/breakline backend and a three-way production-direction recommendation, but no public or production behavior change. |
| Technical Change Surface | 3 | Spans CDT core, terrain feature geometry consumption, comparison rows, current/adaptive integration, no-leak tests, and hosted sidecar support. |
| Implementation Friction Risk | 4 | Bowyer-Watson triangulation, constraint recovery, predicates, hard/firm/soft residuals, and Ruby performance create high engineering resistance. |
| Validation Burden Risk | 4 | Requires local math tests, fixture bakeoff, no-leak coverage, performance evidence, and live SketchUp topology/sidecar proof across prior validation families. |
| Dependency / Coordination Risk | 3 | Depends on MTA-20/MTA-22/MTA-23 artifacts and live SketchUp MCP access, but avoids public-client, production rollout, and native dependency coordination by default. |
| Discovery / Ambiguity Risk | 4 | Planning resolved the architecture, but real CDT quality, degeneracy behavior, constraint coverage, and Ruby runtime credibility remain evidence-driven unknowns. |
| Scope Volatility Risk | 3 | Scope is bounded as comparison-only, yet evidence can redirect the production path to current, adaptive-grid, CDT, native bridge, or hybrid/fallback. |
| Rework Risk | 3 | Triangulation, failure precedence, row equivalence, and hosted findings may force contained revisions before the recommendation is credible. |
| Confidence | 2 | The plan is detailed and uses MTA-23 calibration plus Grok review, but confidence stays moderate-low until real CDT rows and hosted bakeoff evidence exist. |

### Top Assumptions
- Production `TerrainFeatureGeometry` exposes enough anchors, protected regions, pressure regions,
  reference segments, affected windows, tolerances, and digests to drive the CDT candidate without
  rebuilding feature intent.
- A pure Ruby constrained triangulator can produce credible comparison rows for enough local and
  hosted cases inside the MTA-23-like evidence envelope.
- Unsupported, intersecting, duplicate, or near-collinear constraints can be represented as
  limitations/residuals while still emitting a mesh row for every valid heightmap.
- Existing MTA-22 fixtures, MTA-23 adaptive-grid rows, and hosted sidecar patterns are reusable
  enough for equivalent three-way bakeoff evidence.
- Current, MTA-23 adaptive-grid, and CDT sidecars can be placed for joint live visual validation
  before the recommendation is accepted.
- Public terrain response paths can remain untouched, with CDT diagnostics confined to internal
  comparison artifacts and task summary evidence.

### Estimate Breakers
- Constraint recovery cannot reliably preserve even simple protected/reference segments or fixed
  anchors, making CDT diagnostics too weak for a meaningful bakeoff.
- Pure Ruby CDT runtime cannot produce enough local created-corridor or hosted/adopted/aggressive
  rows under budget to support a recommendation.
- Degenerate or intersecting constraints cause candidate generation failures instead of limitation
  rows with fallback mesh output for valid heightmaps.
- Three-way rows cannot be made equivalent because current, adaptive-grid, and CDT paths consume
  different sampled states or incomparable feature/reference digests.
- Hosted SketchUp sidecars expose topology, undo, save-copy, metadata, or scene-mutation failures
  that require production path changes or a broader sidecar abstraction.

### Predicted Signals
- MTA-23 actuals are the closest calibrated analog: functional scope `2`, technical surface `3`,
  implementation friction `3`, validation burden `4`, dependency drag `3`, discovery `4`, scope
  volatility `3`, rework `2`, and final confidence `3`.
- MTA-23 calibration explicitly says future terrain backend tasks should establish three-way
  evidence early: candidate versus current, candidate versus hard-intent diagnostics, and candidate
  versus aggressive hosted terrain.
- MTA-19 remains the strongest negative topology analog: locally plausible height samples can still
  produce bad SketchUp topology, long runtimes, and failed hosted evidence.
- External CDT references show real constrained triangulation depends on constraint/subconstraint
  tracking, robust orientation/incircle predicates, degeneracy handling, and explicit diagnostic
  boundaries.
- Native C/C++ acceleration is feasible in SketchUp, but defaulting to it would add packaging,
  embedded-Ruby ABI, licensing, load-test, and crash-risk scope outside the planned bakeoff.

### Predicted Estimate Notes
- This prediction is the 2026-05-07 planning baseline after replacing the earlier
  validation-only wording with a real comparison-only implementation boundary.
- Functional scope is higher than MTA-23 because MTA-24 adds a real CDT/breakline backend plus a
  three-way recommendation, while still avoiding production wiring and public contract changes.
- Implementation and discovery risk are higher than MTA-23 actual friction because MTA-24 owns new
  computational geometry math rather than only adaptive-grid policy over the production feature
  geometry substrate.
- Validation remains `4` by outside-view calibration: hosted SketchUp proof, topology checks,
  performance interpretation, and recommendation evidence dominated closeout for MTA-23 and are
  broader here due to the three-way bakeoff.
<!-- SIZE:PREDICTED:END -->

---

<!-- SIZE:CHALLENGE:START -->
## Challenge Review

> Filled when the estimate is pressure-tested through external review, premortem, or controlled consensus.

### Agreed Drivers
- Functional scope remains `3`: MTA-24 is still comparison-only and public-contract-neutral, but it
  adds a real CDT/breakline backend plus a three-way production-direction recommendation.
- Technical change surface remains `3`: the plan spans CDT core math, production
  `TerrainFeatureGeometry` consumption, comparison rows, no-leak checks, and hosted sidecar support
  without production wiring or native packaging.
- Implementation friction remains `4`: Bowyer-Watson triangulation, constraint recovery, predicate
  tolerances, hard/firm/soft residuals, and pure Ruby performance are the dominant risk drivers.
- Validation burden remains `4`: this is not high merely because hosted SketchUp is involved; it is
  high because correctness depends on local math proof, equivalent three-way bakeoff rows,
  performance interpretation, no-leak coverage, hosted topology, undo, save-copy, and recommendation
  gates.
- Dependency risk remains `3`: MTA-20/MTA-22/MTA-23 artifacts and live SketchUp access gate
  completion, while C++ bridge and production rollout are deliberately excluded.

### Contested Drivers
- Functional scope could be argued as `2` because production behavior and public contracts stay
  unchanged, but remains `3` because the task must implement a real new backend candidate and not
  only a validation shell.
- Technical change surface could be argued as `4` because CDT math, hosted sidecars, and comparison
  evidence span several layers, but remains `3` because changes stay inside terrain prototype,
  comparison, tests, and sidecar support.
- Scope volatility could be argued as `4` because the recommendation may redirect production to
  current, adaptive-grid, CDT, native bridge, or hybrid/fallback. It remains `3` because the task
  boundary is explicitly comparison-only and now requires measurable recommendation gates.
- Rework risk could be argued as `4` from MTA-19 topology failure history, but remains `3` because
  candidate failure is an accepted bakeoff outcome when rows, residuals, and native-bridge downgrade
  evidence are recorded.

### Missing Evidence
- No implementation proof yet that pure Ruby CDT can produce enough local and hosted rows under the
  MTA-23-like `20.0s` / `4096` planning envelope.
- No proof yet that constraint recovery preserves simple protected/reference/fixed-anchor cases well
  enough for CDT diagnostic claims.
- No hosted SketchUp proof yet for emitted CDT sidecar topology, metadata, undo, save-copy, or
  original-scene preservation.
- No joint live visual validation evidence yet comparing all three emitted methods side-by-side in
  SketchUp.
- No final evidence yet for which production direction wins; MTA-24 must preserve current,
  adaptive-grid, CDT, native-bridge, and hybrid/fallback as possible outcomes until bakeoff rows
  exist.

### Recommendation
- Confirm the predicted profile with no score revisions.
- Proceed with the finalized `WARN` premortem gate.
- Do not split native bridge work into MTA-24 unless Ruby CDT cannot produce credible bakeoff
  evidence; in that case, recommend a native bridge follow-up from measured budget/status rows.
- Treat a hybrid/fallback verdict as valid only when the summary names measurable routing predicates
  and downstream production task entry gates.

### Challenge Notes
- Challenge evidence came from the finalized premortem, Grok 4.3 review of the MTA-24 task/plan/size
  artifacts, MTA-23 calibrated actuals, and MTA-19 negative topology history.
- The main premortem change was adding falsifiable recommendation decision gates so
  hybrid/fallback cannot become an unbounded narrative outcome.
- No unresolved Tigers remain. Accepted residual risks are pure Ruby CDT performance and plain Ruby
  predicate robustness; both are assigned to implementation-time validation and recommendation
  downgrade gates.
- The challenged estimate agrees with the finalized plan: this is a real but comparison-only
  terrain backend bakeoff with very high implementation, validation, and discovery risk, bounded by
  no public contract change and no production wiring.
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
| Functional Scope | 3 | Delivered a real comparison-only CDT backend plus current/MTA-23/CDT recommendation evidence, with no production wiring or public workflow change. |
| Technical Change Surface | 3 | Touched terrain prototype output, triangulation, residual metering, comparison rows, hosted probe support, MTA-23 policy fixes, and contract tests. |
| Actual Implementation Friction | 4 | CDT required residual-driven redesign, topology cleanup, seed-planner cleanup, and related MTA-23 fixes before the bakeoff evidence was credible. |
| Actual Validation Burden | 4 | Hosted validation dominated closeout through repeated fix/reload/redeploy/restart/rerun loops and visual interpretation of invalid or misleading sidecars. |
| Actual Dependency Drag | 3 | Completion depended on MTA-20/MTA-22/MTA-23 artifacts, live SketchUp access, redeployment/reload cycles, and user visual inspection. |
| Actual Discovery Encountered | 4 | Major uncertainty was resolved during execution: CDT oversimplification cause, feature-coordinate translation, current/MTA-23 comparison validity, and MTA-23 subdivision behavior. |
| Actual Scope Volatility | 3 | The task stayed comparison-only, but evidence work materially expanded and the final recommendation required additional decision probes and corrected baselines. |
| Actual Rework | 4 | Completed slices were revisited repeatedly: CDT planner strategy, residual refinement ownership, triangulator topology handling, MTA-23 split policy, and live probe generation. |
| Final Confidence in Completeness | 3 | Strong enough to close MTA-24 as a prototype bakeoff and recommendation task; production readiness remains explicitly gated for a follow-up. |

### Actual Signals
- The original comparison-only boundary held: no public MCP contract or production output path was
  changed.
- The dominant resistance came from making the prototype evidence fair, not from adding public
  surfaces.
- Live validation uncovered invalid comparison setup, not just algorithmic quality questions.
- CDT ended as a real residual-driven prototype with an injectable triangulator seam, but Ruby
  runtime and constraint-classifier precision remain production follow-up gates.
- MTA-23 had to be fixed during the bakeoff before it could serve as a credible comparator.

### Actual Notes
- The predicted high validation/discovery risk was directionally correct. The main underprediction
  was how much Step 10 would be consumed by proving the live comparisons were equivalent and not
  misleading.
- The rough actual shape was inverted from the original implementation expectation: the initial
  code path was implemented quickly, while the Step 10/live-verification loop consumed about eight
  hours of repeated investigation, correction, rerun, and interpretation.
- The task did not drift into productionization or native C++ work.
- Calibration uses `summary.md` plus retained live H2H evidence artifacts. The earlier temporary
  progress artifact was removed and is not available for this calibration.
<!-- SIZE:ACTUAL:END -->

---

<!-- SIZE:VALIDATION-EVIDENCE:START -->
## Validation Evidence Summary

> Fill only the sections that are relevant. Say `not applicable` where needed.

### Automated Validation
- Passed after final Grok-requested cleanup:
  - focused CDT planner/backend tests
  - focused MTA-23 adaptive-policy regression tests
  - touched-file RuboCop checks with writable cache
  - full CI including lint, Ruby tests, and package verification
  - dead-code checks on new CDT runtime files

### Hosted / Manual Validation
- Hosted/live SketchUp validation covered:
  - a 16-case current/MTA-23/CDT matrix
  - an intersecting bounded-edit addendum
  - corrected decision probes after the MTA-23 adaptive subdivision fix
- User visual inspection accepted the latest checked current, MTA-23, and CDT sidecars for the
  retained evidence set.
- Invalid pre-fix sidecars were identified, removed, and regenerated before the recommendation was
  accepted.
- Hosted validation burden was high because it required repeated correction and interpretation
  loops, not because of case count alone.

### Performance Validation
- Live metrics recorded CDT runtime pressure, especially repeated residual retriangulation on
  higher-relief and bounded/intersecting cases.
- Performance was intentionally not treated as a production-ready bar for this prototype, but it is
  a mandatory production follow-up gate.

### Migration / Compatibility Validation
- Public contract stability was verified through no-leak contract coverage.
- No public MCP tools, schemas, dispatcher behavior, setup paths, or user-facing docs changed.
- CDT outputs remain internal comparison rows and disposable sidecar geometry.

### Operational / Rollout Validation
- Not applicable for production rollout. The CDT backend was intentionally not production-wired.
- Live SketchUp checks were validation sidecars only and did not replace existing production terrain
  output.

### Validation Notes
- Grok 4.3 review found no blocker; the one code cleanup finding was addressed.
- `$task-review` found no blocking structural issues and no scoped security/taint issues. A
  resource warning on MTA-23 instance variables was reviewed as a false positive.
<!-- SIZE:VALIDATION-EVIDENCE:END -->

---

<!-- SIZE:DELTA:START -->
## Estimation Delta Review

> Filled during final calibration. Compare prediction to actual behavior.

- **Most Underestimated Dimension**: Validation burden. The predicted score was already high, but
  actual closeout was dominated by repeated live comparison correction, not just a broad hosted
  matrix. The initial implementation was roughly a short implementation slice; the live Step 10
  loop became the real task cost center.
- **Most Overestimated Dimension**: Native/packaging dependency risk. The task stayed pure Ruby and
  comparison-only; native C++ remained a follow-up gate rather than entering MTA-24 scope.
- **Signal Present Early But Underweighted**: MTA-23 calibration warned that future terrain backend
  tasks need three-way evidence early. The estimate captured this, but did not fully price the cost
  of proving the three paths were equivalent and visually meaningful.
- **Genuinely Unknowable Factor**: The live probes exposed specific invalid assumptions only after
  sidecars were visible: wrong MTA-23 feature-coordinate projection, misleading current comparison
  setup, and MTA-23 early-stop behavior on unsplittable off-grid hard anchors.
- **Future Similar Tasks Should Assume**: Terrain backend bakeoffs need a dedicated evidence
  harness budget for equivalence checks, invalid-sidecar cleanup, live reload/redeploy churn, and
  performance interpretation before final recommendation work begins. They should also plan an
  explicit cleanup/isolation pass for task-specific comparison harnesses before any production
  wiring task.

### Calibration Notes
- Dominant actual failure mode: validation-driven discovery and rework in live hosted comparison
  evidence.
- Future analog retrieval should match on comparison-only terrain backend prototypes, hosted matrix
  with repeated fix loops, performance-sensitive mesh generation, public-contract no-leak checks,
  and production-direction recommendation tasks.
- The production follow-up should treat task-owned bakeoff and hosted-probe helpers as evidence
  harnesses to isolate or remove, not as ready long-lived runtime architecture.
- The final recommendation is credible for prototype direction, not production readiness. The
  production follow-up must explicitly gate runtime, constraint classifier precision, hosted
  acceptance, no-leak behavior after wiring, and fallback routing.
<!-- SIZE:DELTA:END -->

---

<!-- SIZE:TAGS:START -->
## Retrieval Tags

- `archetype:performance-sensitive`
- `scope:managed-terrain`
- `systems:terrain-output`
- `systems:terrain-mesh-generator`
- `systems:terrain-kernel`
- `validation:performance`
- `validation:hosted-matrix`
- `host:repeated-fix-loop`
- `host:redeploy-restart`
- `contract:no-public-shape-change`
- `risk:transform-semantics`
- `risk:performance-scaling`
- `rework:high`
- `confidence:medium`
<!-- SIZE:TAGS:END -->
