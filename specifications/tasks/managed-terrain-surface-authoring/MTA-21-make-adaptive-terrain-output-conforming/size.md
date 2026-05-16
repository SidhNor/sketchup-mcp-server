# Size: MTA-21 Make Adaptive Terrain Output Conforming

**Task ID**: `MTA-21`  
**Title**: Make Adaptive Terrain Output Conforming  
**Status**: `calibrated`  
**Created**: 2026-05-04  
**Last Updated**: 2026-05-04  

**Related Task**: [task.md](./task.md)  
**Related Plan**: [plan.md](./plan.md)  
**Related Summary**: [summary.md](./summary.md)  

---

<!-- SIZE:IDENTITY:START -->
## Identity

- **Task Archetype**: `archetype:bugfix`
- **Primary Scope Area**: `scope:managed-terrain`
- **Likely Systems Touched**:
  - `systems:terrain-output`
  - `systems:terrain-mesh-generator`
  - `systems:public-contract`
  - `systems:test-support`
- **Validation Modes**: `validation:hosted-matrix`, `validation:performance`, `validation:contract`, `validation:regression`
- **Likely Analog Class**: adaptive-cell derived-output topology repair with hidden generated edges

### Identity Notes
- This task is a production output-quality bugfix for adaptive terrain geometry. It should keep
  heightmap state authoritative, repair the current adaptive-cell path rather than replacing the
  meshing backend, hide generated terrain edges, and preserve the public MCP terrain contract.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 2 | Fixes derived output quality for existing terrain workflows without adding a new public workflow. |
| Technical Change Surface | 2 | Planned work stays in adaptive output planning, mesh emission, contract/no-leak tests, and hosted validation. |
| Hidden Complexity Suspicion | 3 | The repair is narrowed to source-grid densification, but topology predicates, count ownership, hidden edges, and performance remain sensitive. |
| Validation Burden Suspicion | 4 | Requires deterministic topology tests plus live SketchUp checks on adopted irregular and aggressive/off-grid edited terrain, including hidden edge state and face-count ratios. |
| Dependency / Coordination Suspicion | 2 | Work stays inside terrain runtime but depends on MTA-11/MTA-20 baseline behavior and live SketchUp verification access. |
| Scope Volatility Suspicion | 2 | The plan explicitly excludes new meshing backends, but face-count inflation or hosted topology mismatch could still force rework or follow-up. |
| Confidence | 3 | Research reproduced the defect class and Grok 4.3 supported the repair strategy, but no implementation or hosted validation exists yet. |

### Early Signals
- Live inspection found internal one-face terrain edges on existing schema v2 adaptive terrain and
  fresh adopted adaptive fixtures, while clean flat created terrain stayed conforming through
  aggressive/off-grid edits.
- Full regular-grid output is explicitly unacceptable, so the fix must preserve adaptive output
  rather than relying on the known conforming fallback.
- The reproduced failure mode is mixed-resolution adaptive cell adjacency with hanging vertices on
  larger cell edges.
- The selected repair is source-grid subcell densification for hanging-boundary adaptive cells, not
  a new triangulation backend.
- Generated terrain edges should become SketchUp hidden geometry without changing public responses.
- The task must distinguish source heightmap correctness from disposable output mesh topology.

### Early Estimate Notes
- Seed shape is high-validation and performance-sensitive. The core behavior is a bugfix, but the
  mesh-topology proof burden is closer to a contained output-kernel task than a simple regression
  fix.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

> Filled during task planning. This is the main pre-implementation estimate.

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | 2 | Behavior-visible quality fix across existing create/adopt/edit terrain output, with no new public workflow. |
| Technical Change Surface | 2 | Touches related terrain output planning, mesh generation, fake test support, contract fixtures, and docs review if counts/wording shift. |
| Implementation Friction Risk | 3 | Topology classification, conforming count ownership, source-grid densified emission, and hidden edge behavior must line up without widening into a new backend. |
| Validation Burden Risk | 4 | Acceptance depends on topology predicates, count matching, no-leak contract checks, hidden-edge checks, performance ratios, and hosted SketchUp naked-edge evidence. |
| Dependency / Coordination Risk | 2 | Depends on existing MTA-11/MTA-20 terrain baseline and hosted SketchUp validation access, but no upstream code or public-client coordination is expected. |
| Discovery / Ambiguity Risk | 3 | The defect and repair strategy are concrete, but premortem found a non-obvious densification-closure issue; host edge merging, face-count ratios, and fixture behavior remain unproven. |
| Scope Volatility Risk | 2 | Scope is strongly bounded against RTIN/Delaunay/MTA-19 revival, but compactness loss or host topology mismatch could force a follow-up or implementation adjustment. |
| Rework Risk | 3 | Terrain output work has a history of hosted surprises; incorrect topology predicates or stale summary counts could require revisiting both plan and generator changes. |
| Confidence | 3 | Planning evidence is solid after local reproduction and Grok 4.3 review, but confidence remains below high until implementation and hosted validation prove the repair. |

### Top Assumptions
- Full source-grid subcell densification for hanging-boundary adaptive cells is enough to remove
  current T-junction-like seams without replacing the adaptive-cell path.
- `TerrainOutputPlan` can compute final conforming counts from adaptive cells before emission, and
  `TerrainMeshGenerator` can emit the same classification deterministically.
- Hidden generated edges can be applied through `edge.hidden = true` after face creation across
  builder-backed and compatibility emission paths.
- Representative repaired adaptive output remains materially below full-grid even though worst-case
  densification can approach full-grid.

### Estimate Breakers
- Hosted SketchUp still reports internal naked-edge or seam artifacts after local topology tests
  pass.
- Source-grid densification causes common representative terrain to become effectively full-grid,
  violating the compact adaptive production posture.
- Summary counts and emitted geometry cannot be kept aligned without introducing a larger internal
  mesh data structure.
- Hidden edge semantics require soft/smooth behavior or host-specific mutation outside the planned
  derived-edge marking seam.
- The repair starts needing a minimal local triangulator, RTIN, Delaunay, or feature-aware backend
  despite the scoped plan.

### Predicted Signals
- A local probe reproduced the suspected hanging-boundary condition in current adaptive cells.
- MTA-10 shows real SketchUp output mutation can diverge from fake tests and require hosted fix
  loops.
- MTA-11 proves the current `heightmap_grid`/`adaptive_tin` contract baseline but also shows adaptive
  output changes need contract and live verification.
- MTA-19 is a negative analog: broader adaptive triangulation work passed local checks but failed
  hosted topology/performance validation and was reverted.
- Grok 4.3 review supported full source-grid subcell densification as the lowest-risk scoped repair,
  while emphasizing count ownership and face-count inflation risk.

### Predicted Estimate Notes
- This is a contained terrain-output bugfix by public behavior, but validation burden is very high
  because correctness depends on real topology, hidden edge state, and performance/compactness
  evidence. The plan is intentionally narrower than MTA-19 and should not be resized into a new
  adaptive meshing backend without re-planning.
<!-- SIZE:PREDICTED:END -->

---

<!-- SIZE:CHALLENGE:START -->
## Challenge Review

> Filled when the estimate is pressure-tested through external review, premortem, or controlled consensus.

### Agreed Drivers
- Functional scope remains `2`: the task fixes derived output quality for existing terrain flows
  without adding a public workflow or request contract.
- Technical change surface remains `2`: implementation is concentrated in `TerrainOutputPlan`,
  `TerrainMeshGenerator`, test support, and contract/no-leak checks.
- Implementation friction remains high at `3`: source-grid densification is simpler than a new
  backend, but count ownership, closure classification, topology predicates, and hidden edge state
  must align.
- Validation burden remains `4`: hosted topology and hidden-edge evidence, performance ratios,
  no-leak contract checks, and undo/refusal safety are all required.
- Dependency risk remains `2`: live SketchUp access matters, but no upstream task or public-client
  coordination is expected.

### Contested Drivers
- Discovery / Ambiguity increased from `2` to `3`. The premortem found that single-pass
  densification can create new boundary vertices on neighboring cells, requiring iterative closure
  before emission.
- Scope volatility remains contested but unchanged at `2`: MTA-19 and the task guardrails strongly
  exclude backend replacement, but high face-count ratios could still force follow-up work.
- Rework risk remains `3`: hosted geometry surprises are plausible, but the finalized plan now has
  a falsifiable closure predicate and count-equality tests before generator integration.

### Missing Evidence
- No implementation proof yet that densification closure is compact enough on representative
  created, edited, and adopted terrains.
- No hosted proof yet that SketchUp output has no internal naked-edge seams after densification.
- No hosted proof yet that generated edges are hidden through the real builder-backed path.
- No evidence yet that public fixture count changes stay limited to expected natural
  `derivedMesh` count deltas.

### Recommendation
- Confirm the challenged estimate with only the Discovery / Ambiguity revision. Proceed to
  implementation with the finalized `WARN` premortem gate and do not broaden the task into a new
  terrain meshing backend unless an estimate breaker is triggered.

### Challenge Notes
- Challenge evidence came from Grok 4.3 review and the Step 11 premortem.
- Grok 4.3 confirmed source-grid subcell densification as the lowest-risk scoped repair and
  emphasized count ownership in `TerrainOutputPlan`.
- The premortem found a real plan flaw: densifying one cell can introduce new emitted boundary
  vertices that make neighboring cells non-conforming. The plan was corrected to require iterative
  densification closure before emission.
- Validation burden stays `4` because the risk is not routine hosted case count; it is topology,
  hidden-edge semantics, performance interpretation, and possible hosted mismatch.
<!-- SIZE:CHALLENGE:END -->

---

<!-- SIZE:DRIFT:START -->
## Drift Log

> Append only. Log only material changes that affect estimate shape, risk, confidence, or validation burden.

| Date | Phase / Checkpoint | Event Type | Severity (1-3) | Dimension Affected | Predictable Earlier? | Notes |
|---|---|---|---:|---|---|---|
| 2026-05-04 | Step 09 / plan-level conforming classification | estimate breaker | 2 | Implementation Friction Risk; Scope Volatility Risk; Confidence | partly | First implementation of planned full source-grid densification closure made the representative mixed-resolution fixture full-grid (`ratio = 1.0`), triggering the predicted compactness breaker and requiring strategy reassessment before generator work. |

### Drift Notes
- Material drift is now recorded because an estimate breaker became concrete during the first TDD implementation slice.
<!-- SIZE:DRIFT:END -->

---

<!-- SIZE:ACTUAL:START -->
## Actual Profile

> Filled at the end of implementation. Do not overwrite predicted values.

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | 2 | Existing create/adopt/edit derived-output quality changed without adding a public workflow. |
| Technical Change Surface | 2 | Implementation stayed in output planning, mesh generation, fake host support, and focused contract tests. |
| Actual Implementation Friction | 3 | Initial full source-grid densification hit the predicted compactness breaker and forced strategy reassessment. |
| Actual Validation Burden | 3 | Validation exceeded baseline through topology/count predicates, no-leak and hidden-edge checks, repeated hosted deploy/fix loops, and performance interpretation. The remaining live-host gap is reflected in confidence rather than burden. |
| Actual Dependency Drag | 2 | Hosted validation access became available, but representative validation is blocked by feature-planner caps and adopted compactness behavior. |
| Actual Discovery Encountered | 3 | Representative fixture probing showed the planned densification closure could become full-grid, changing the repair strategy. |
| Actual Scope Volatility | 2 | The task stayed inside the adaptive-cell path and public outcome; the repair strategy materially shifted from densification closure to boundary-line splitting, but the accepted task boundary did not change. |
| Actual Rework | 3 | First-slice strategy work was redirected, the plan was rewritten, and final review required two hardening edits. |
| Final Confidence in Completeness | 2 | Local tests, lint, package verification, and Grok review are green; hosted representative validation is blocked. |

### Actual Signals
- Global adaptive boundary-line splitting preserved the task's no-new-backend constraint while
  avoiding the full-grid collapse seen in the first densification implementation slice.
- Focused plan and generator tests prove no unsplit emitted axis edge has an interior emitted
  terrain vertex on the local fake-host topology.
- Public contract tests now reject both split-plan internals and old densification/stitch
  vocabulary.
- Final Grok 4.3 review produced bounded hardening work rather than architectural rework.
- Hosted validation found successful small cases but blocked representative cases before adaptive
  output generation.

### Actual Notes
- Actual implementation shape matched the predicted high-friction/high-validation profile, but the
  specific plan changed after compactness probing. The dominant actual failure mode was not host
  API mismatch; it was adaptive conformance repair that accidentally erased adaptive compactness.
<!-- SIZE:ACTUAL:END -->

---

<!-- SIZE:VALIDATION-EVIDENCE:START -->
## Validation Evidence Summary

> Fill only the sections that are relevant. Say `not applicable` where needed.

### Automated Validation
- `bundle exec ruby -Itest test/terrain/terrain_output_plan_test.rb`
  - `9 runs, 140 assertions, 0 failures, 0 errors, 0 skips`
- `bundle exec ruby -Itest test/terrain/terrain_mesh_generator_test.rb`
  - `35 runs, 1000 assertions, 0 failures, 0 errors, 0 skips`
- `bundle exec ruby -Itest test/terrain/terrain_contract_stability_test.rb`
  - `7 runs, 349 assertions, 0 failures, 0 errors, 0 skips`
- Feature-cap mask follow-up:
  - `bundle exec ruby -Itest test/terrain/terrain_feature_planner_test.rb`: `9 runs, 58 assertions, 0 failures, 0 errors, 0 skips`
  - `bundle exec ruby -Itest test/terrain/terrain_surface_commands_test.rb`: `28 runs, 169 assertions, 0 failures, 0 errors, 0 skips`
  - `bundle exec ruby -Itest test/terrain/terrain_contract_stability_test.rb`: `7 runs, 349 assertions, 0 failures, 0 errors, 0 skips`
  - terrain suite: `287 runs, 3187 assertions, 0 failures, 0 errors, 3 skips`
  - scoped terrain RuboCop: `71 files inspected, no offenses detected`
  - `bundle exec rake package:verify`: produced `dist/su_mcp-1.1.2.rbz`
- Boundary-fan compactness follow-up:
  - `bundle exec ruby -Itest test/terrain/terrain_output_plan_test.rb`: `9 runs, 138 assertions, 0 failures, 0 errors, 0 skips`
  - `bundle exec ruby -Itest test/terrain/terrain_mesh_generator_test.rb`: `35 runs, 1031 assertions, 0 failures, 0 errors, 0 skips`
  - `bundle exec ruby -Itest test/terrain/terrain_contract_stability_test.rb`: `7 runs, 381 assertions, 0 failures, 0 errors, 0 skips`
  - terrain suite: `288 runs, 3336 assertions, 0 failures, 0 errors, 3 skips`
  - full Ruby suite: `888 runs, 5686 assertions, 0 failures, 0 errors, 37 skips`
  - scoped terrain RuboCop: `72 files inspected, no offenses detected`
  - full RuboCop: `224 files inspected, no offenses detected`
  - `bundle exec rake package:verify`: produced `dist/su_mcp-1.1.2.rbz`
- Final broader terrain suite: `288 runs, 3336 assertions, 0 failures, 0 errors, 3 skips`
- Final broader Ruby suite: `888 runs, 5686 assertions, 0 failures, 0 errors, 37 skips`
- Final broader RuboCop: `224 files inspected, no offenses detected`
- Post-review focused RuboCop: `5 files inspected, no offenses detected`
- Final `git diff --check` passed.

### Hosted / Manual Validation
- Live SketchUp-hosted validation was attempted after the latest simplifier fix/deploy.
- Representative whole-terrain planar fits, created large/medium corridors, large-region target
  edits, and representative adopted-terrain corridors refused with
  `terrain_feature_pointification_limit_exceeded` before adaptive output generation.
- Follow-up code now makes affected-window pointification projections diagnostic-only unless a
  feature carries explicit `sampleEstimate`; redeploy validation is still required.
- Redeployed validation confirmed large edits now run, but global boundary-line splitting produced
  nearly dense corridor/adopted outputs.
- Boundary-fan compactness follow-up was redeployed and accepted for seam conformance. The T-rip/
  folded seam class was not reproduced in representative hosted cases.
- Off-grid adopted corridor endpoint correctness remains a separate failure from mesh conformance.
- Small created/adopted corridor sanity checks succeeded, sampled requested public profiles
  correctly, and had no down-facing faces or non-manifold edges.
- Successful aggressive stacked terrain still showed severe sharp-normal diagnostics, with worst
  break `94.12 deg`.

### Performance Validation
- Representative mixed-resolution automated fixtures assert repaired adaptive face-count ratios
  remain materially compact, below `0.5` of full-grid face count.
- Hosted adopted irregular terrain output was effectively dense: `19404` faces vs dense equivalent
  `19602`.
- Small flat corridor output was compact at `800` faces vs dense equivalent `3200`; final stacked
  simple terrain was `1856` faces vs dense equivalent `4800`.
- After the cap fix, representative hosted flat/crossfall/steep 41x41 corridors emitted
  `3042-3200 / 3200` faces, adopted corridors emitted `18430-19012 / 19602` faces, and the simple
  aggressive stack emitted `4640 / 4800` faces.
- After the boundary-fan follow-up, representative hosted corridors emitted `1378-1750` faces
  versus dense equivalents of `3200-4200`, adopted irregular terrain improved to `11044 / 19602`
  before corridor and `6824-7765 / 19602` after corridors, aggressive stacked output was
  `3578 / 4800`, and high-relief seam-stress output was `6667 / 9600`.

### Migration / Compatibility Validation
- No durable schema, repository, serializer, MCP tool name, request field, or response field changed.
- Contract stability tests cover compact public response shape and internal-vocabulary no-leak
  behavior.

### Operational / Rollout Validation
- Final `bundle exec rake package:verify` produced `dist/su_mcp-1.1.2.rbz`.

### Validation Notes
- Validation burden remains material because hosted validation required multiple fix/deploy loops.
  The final seam behavior is acceptable, but face counts remain materially higher than the
  pre-conformance simplifier in representative cases. Remaining hosted gaps reduce confidence
  rather than increasing completed validation burden.
<!-- SIZE:VALIDATION-EVIDENCE:END -->

---

<!-- SIZE:DELTA:START -->
## Estimation Delta Review

> Filled during final calibration. Compare prediction to actual behavior.

- **Most Underestimated Dimension**: Implementation Friction / Discovery. The predicted compactness
  breaker became concrete during the first TDD slice and required replacing the densification-closure
  plan with boundary-line splitting.
- **Most Overestimated Dimension**: Dependency / Coordination. Hosted access became available, and
  no upstream task sequencing or public-client coordination was needed for the local implementation.
- **Signal Present Early But Underweighted**: The representative-face-count risk was known, but the
  original plan did not require a compactness probe before committing to the densification skeleton.
- **Genuinely Unknowable Factor**: The exact cascade behavior of full source-grid densification on
  representative mixed-resolution adaptive fixtures was only observable after implementation-level
  probing.
- **Future Similar Tasks Should Assume**: Any adaptive terrain conformity repair must validate
  compactness before generator integration and must keep representative feature-planner refusals
  from masking the output topology being tested.

### Calibration Notes
- Actual task behavior supports a future analog of `adaptive-output topology repair with
  compactness breaker risk`: keep implementation bounded, but front-load representative ratio
  probes and hosted validation access.
- MTA-21 should not be used as evidence that the current adaptive-cell simplifier is sufficient for
  ideal face-count quality. It is evidence that seam conformance can be repaired, with simplifier
  quality left as a separate task.
<!-- SIZE:DELTA:END -->

---

<!-- SIZE:TAGS:START -->
## Retrieval Tags

- `archetype:bugfix`
- `scope:managed-terrain`
- `systems:terrain-output`
- `systems:terrain-mesh-generator`
- `systems:public-contract`
- `systems:test-support`
- `validation:contract`
- `validation:performance`
- `validation:regression`
- `host:validated-matrix`
- `contract:no-public-shape-change`
- `risk:visibility-semantics`
- `risk:performance-scaling`
- `volatility:medium`
- `friction:high`
- `rework:medium`
- `confidence:high`
<!-- SIZE:TAGS:END -->
