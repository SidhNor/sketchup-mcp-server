# Size: MTA-38 Establish Feature-Aware Adaptive Baseline, Policy, And Validation Harness

**Task ID**: MTA-38  
**Title**: Establish Feature-Aware Adaptive Baseline, Policy, And Validation Harness  
**Status**: calibrated  
**Created**: 2026-05-15  
**Last Updated**: 2026-05-16  

**Related Task**: [task.md](./task.md)  
**Related Plan**: [plan.md](./plan.md)  
**Related Summary**: [summary.md](./summary.md)  

---

<!-- SIZE:IDENTITY:START -->
## Identity

- **Task Archetype**: `archetype:test-infrastructure`
- **Primary Scope Area**: `scope:managed-terrain`
- **Likely Systems Touched**:
  - `systems:command-layer`
  - `systems:terrain-output`
  - `systems:terrain-mesh-generator`
  - `systems:test-support`
- **Validation Modes**:
  - `validation:hosted-matrix`
  - `validation:performance`
  - `validation:contract`
  - `validation:regression`
- **Likely Analog Class**: durable replay/evidence infrastructure with grey-box terrain output diagnostics

### Identity Notes
- Re-seeded after planning refinement removed fallback/refusal/reload/readback/no-leak goals and
  narrowed the task to accepted deterministic replay, compact output-policy diagnostics, timing, and
  hosted baseline evidence. MTA-22 is the closest test-infrastructure analog; MTA-36 remains the
  strongest production adaptive lifecycle/timing analog.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 2 | Establishes durable replay baseline and internal diagnostics without public behavior or geometry changes. |
| Technical Change Surface | 3 | Likely touches replay/test support, command/output planning, feature diagnostics, timing, and mesh-generator non-interference tests. |
| Hidden Complexity Suspicion | 2 | Exact replay durability and grey-box timing can expose gaps, but topology and public contract changes are excluded. |
| Validation Burden Suspicion | 3 | Hosted MCP replay, timing evidence, schema validation, contract guardrails, and generation non-interference proof are central. |
| Dependency / Coordination Suspicion | 2 | Depends on MTA-20 feature intent, MTA-36 adaptive lifecycle, and hosted MCP access, but no external public coordination. |
| Scope Volatility Suspicion | 2 | Scope can grow if compact diagnostics are insufficient or canonical replay timings are too small to be useful. |
| Confidence | 3 | Refined plan resolves row shape, diagnostics ownership, replay location, and non-goals, but implementation/hosted evidence is pending. |

### Early Signals
- Harness-first task with no intended geometry or public contract change.
- Durable replay spec is the reproducibility source, not a saved scene artifact.
- Hosted MCP replay and timing are required before later topology-affecting tasks.
- Compact diagnostics must be useful without pulling full CDT/feature-geometry behavior into the production adaptive path.

### Early Estimate Notes
- Rebaseline reflects Step 06/Step 09 scope corrections before predicted estimation.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

> Filled during task planning. This is the main pre-implementation estimate.

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | 2 | Adds durable replay infrastructure, internal diagnostics, timing evidence, and hosted baseline rows for future tasks, but no public workflow, geometry behavior, or backend selection change. |
| Technical Change Surface | 3 | Spans replay spec/loader, command/output planning diagnostics, `TerrainOutputPlan` attachment, timing capture, mesh-generator non-interference tests, hosted replay support, and evidence shaping. |
| Implementation Friction Risk | 2 | The design is bounded and avoids topology changes, CDT routing, public contracts, persistence, and reload behavior; friction is mainly in stable diagnostics and non-CDT timing capture. |
| Validation Burden Risk | 3 | Validation is central: schema tests, diagnostic tests, command/contract checks, generation A/B proof, hosted MCP replay, timing interpretation, and accepted intersecting rows. |
| Dependency / Coordination Risk | 2 | Depends on MTA-20 feature intent, MTA-36 adaptive lifecycle behavior, and live SketchUp/MCP access, but avoids public-client, packaging, and external dependency coordination. |
| Discovery / Ambiguity Risk | 2 | Major planning choices are resolved, but implementation still has to prove compact diagnostics are enough and that generic timing can be captured cleanly. |
| Scope Volatility Risk | 2 | Scope can expand if the 49x49 baseline produces unusably small timing signals, if compact diagnostics need full feature geometry, or if accepted intersecting rows unexpectedly refuse. |
| Rework Risk | 2 | Rework risk is moderate around replay schema completeness, diagnostic field shape, and evidence runner boundaries; no high-cost geometry rework is expected. |
| Confidence | 3 | The plan is concrete and analog-backed, with major ambiguities resolved; confidence remains below high until implementation and hosted replay evidence exist. |

### Top Assumptions
- Exact public payload replay in `test/terrain/replay/feature_aware_adaptive_baseline.json` will be durable enough for MTA-39 through MTA-44 without saved scene artifacts.
- Compact `FeatureOutputPolicyDiagnostics` can prove feature context reached output planning without requiring full `TerrainFeatureGeometry` on the production adaptive path.
- Optional diagnostics on `TerrainOutputPlan` can be kept out of face/vertex generation and public responses.
- The canonical 49x49 terrain is large enough to exercise patch scope and intersecting feature context; a larger timing-only row is a gate, not assumed scope.
- Hosted MCP access is available for final accepted replay rows.

### Estimate Breakers
- The compact feature-view summary is insufficient, forcing full feature geometry preparation or broader output-policy redesign.
- Generic timing cannot be captured without invasive changes to command/output/generator seams.
- The canonical replay rows refuse or fail in hosted SketchUp and require substantial edit-row redesign.
- Future-task reproducibility requires a richer replay runner/schema than exact public payloads plus metadata.
- Non-interference tests reveal diagnostics are already coupled to generation paths or require larger refactoring to isolate.

### Predicted Signals
- MTA-22 actuals show fixture/replay infrastructure can have low functional scope but meaningful validation burden when source recipes and results must be kept precise.
- MTA-36 actuals show adaptive output timing evidence can expose hidden performance and hosted runtime issues, but MTA-38 excludes MTA-36's heavy topology, reload/readback, and mutation-safety scope.
- MTA-23/MTA-24 show feature-context and intersecting-row evidence needs live comparison quality, but their backend prototypes and CDT behavior are not implementation analogs.
- The Step 10 plan intentionally uses no public contract change and no geometry behavior change, keeping implementation friction bounded.
- Hosted validation is expected to be a routine matrix unless replay rows refuse, timing is too noisy, or grey-box diagnostics require live-runtime fixes.

### Predicted Estimate Notes
- Closest calibrated analogs are MTA-22 for durable replay infrastructure and MTA-36 for hosted adaptive timing evidence. MTA-23/MTA-24 inform feature-context evidence but are rejected as production implementation analogs.
- Validation burden is scored `3` because evidence generation is the task's core output and includes hosted MCP replay plus timing/diagnostic interpretation, not because of persistence/undo/reload breadth.
- Technical surface is `3` despite no public contract change because the plan crosses test support, command orchestration, output planning, timing, and generator non-interference coverage.
- This prediction reflects the Step 10 draft plan after planning rebaseline; it does not include premortem or challenge findings.
<!-- SIZE:PREDICTED:END -->

---

<!-- SIZE:CHALLENGE:START -->
## Challenge Review

### Agreed Drivers

- Functional scope remains `2`: the task establishes reusable baseline infrastructure and internal
  diagnostics, but intentionally avoids public workflow changes and topology behavior changes.
- Technical change surface remains `3`: the plan crosses replay schema/loader, command/output
  planning diagnostics, timing capture, `TerrainOutputPlan`, mesh-generator tests, and hosted
  replay evidence.
- Validation burden remains `3`: proof is central to the task and includes hosted replay, timing
  interpretation, contract stability, non-interference checks, and accepted intersecting rows.
- Dependency risk remains `2`: MTA-20, MTA-36, and hosted MCP access are required, but there is no
  public-client, packaging, or external dependency coordination.

### Contested Drivers

- Timing evidence could be too noisy or too small on the canonical 49x49 terrain. This does not
  justify resizing now because the plan treats timing as contextual evidence, records environment
  summary, and adds a larger timing-only row only if the canonical rows are unusable.
- Compact diagnostics may be too coarse for future feature-aware comparison. This remains a known
  implementation risk, but MTA-38 only needs to prove feature context reached output planning before
  geometry changes.
- Hosted matrix breadth is not, by itself, evidence for a `4` validation score. No blocker,
  repeated fix/redeploy/rerun loop, persistence/undo burden, migration issue, or compatibility
  investigation is known before implementation.
- Feature-view digest and policy fingerprint are traceability signals, not reproducibility keys.
  The replay spec's exact public payloads and terrain metadata remain the durable reproduction
  source.

### Missing Evidence

- Hosted replay has not yet proven the canonical rows execute cleanly through SketchUp MCP.
- The compact diagnostic summary has not yet proven it can capture the required intersection
  evidence without full feature geometry.
- The diagnostics attached/detached non-interference proof has not yet run across the canonical row
  set.
- The 49x49 terrain timing signal has not yet been measured for usefulness.

### Recommendation

Keep the predicted profile unchanged and proceed to implementation with the plan's gates intact.
Do not split the task now. Reconsider scope only if compact diagnostics require full feature
geometry, the canonical rows cannot be made accepted without redesign, or hosted validation enters
repeated fix/redeploy/rerun loops.

### Challenge Notes

- Premortem status is `WARN` with no unresolved Tigers.
- The useful challenge output was folded into the finalized plan as guardrails rather than new
  score evidence.
- The estimate remains medium-confidence until hosted replay, timing usefulness, and diagnostic
  non-interference are proven.
<!-- SIZE:CHALLENGE:END -->

---

<!-- SIZE:DRIFT:START -->
## Drift Log

- No material functional-scope drift from the finalized plan: the durable replay spec, hosted MCP
  replay, timing buckets, grey-box diagnostics, accepted edit rows, and recorded baseline evidence
  were all planned deliverables.
- The plan's conditional timing gate fired. The canonical 49x49 rows were not sufficient as the
  only performance signal, so the baseline added larger hosted timing rows while keeping the replay
  mechanism generic and reusable.
- User review clarified that the baseline must be durable for later tasks and must create real
  live SketchUp geometry, not simulated runs. The implementation satisfied that through hosted
  capture artifacts and repeat result files rather than changing the public terrain contract.
- Terrain creation/adoption ceilings were raised to support the heavier baseline: 65,536 samples
  and 256 columns/rows, with contract/adoption tests updated.
- Hosted repeatability exposed two implementation defects in the new harness and capture path:
  missing `last_baseline_evidence` fallback handling and incomplete clearing of timing terrains.
  Both were fixed before final capture.
- Review-driven fixes stayed inside the planned surface: placement transform handling, timing
  terrain cleanup, and stricter adaptive-state checks.
<!-- SIZE:DRIFT:END -->

---

<!-- SIZE:ACTUAL:START -->
## Actual Profile

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | 2 | The implemented behavior matches the planned internal baseline/harness scope. No public terrain workflow, response shape, backend selector, or feature-aware geometry behavior was added. |
| Technical Change Surface | 3 | Touched the expected replay, command, output-plan, diagnostics, mesh-generator, contract, and test surfaces, plus cap-related contract/adoption guards. |
| Actual Implementation Friction | 3 | Higher than predicted because hosted repeatability surfaced real harness/capture bugs and the timing rows needed heavier live geometry. |
| Actual Validation Burden | 4 | Validation dominated closeout through hosted live capture, heavy performance interpretation, repeat captures, review follow-up, and fix/redeploy/rerun work. This is scored by blocker/retest cost, not by hosted case count. |
| Actual Dependency Drag | 2 | Stayed as predicted: hosted SketchUp/MCP access and existing terrain lifecycle behavior were required, but no external public-client coordination was introduced. |
| Actual Discovery Encountered | 3 | The main ambiguity was not what to build, but what was large and repeatable enough to be useful as future baseline evidence. |
| Actual Scope Volatility | 2 | User clarifications changed fixture scale and evidence expectations, but they reinforced the finalized plan rather than opening new public behavior. |
| Actual Rework | 3 | Moderate actual rework around hosted capture repeatability, result durability, cap/test alignment, and review-driven low findings. |
| Final Confidence in Completeness | 4 | High after repeated hosted capture and full validation. Residual risk is environment-sensitive performance comparison, not missing implementation scope. |
<!-- SIZE:ACTUAL:END -->

---

<!-- SIZE:VALIDATION-EVIDENCE:START -->
## Validation Evidence Summary

- Hosted capture produced durable real SketchUp geometry evidence in
  `test/terrain/replay/feature_aware_adaptive_baseline_results.json`.
- Three repeat captures were recorded:
  `feature_aware_adaptive_baseline_results_repeat_1.json`,
  `feature_aware_adaptive_baseline_results_repeat_2.json`, and
  `feature_aware_adaptive_baseline_results_repeat_3.json`.
- Repeat captures each produced 18 accepted rows and 0 refusals.
- Heavy timing rows were in the intended measurement range, including large create at about
  9.6-10.4 seconds and large intersecting edit rows around 12.7-14.0 seconds.
- Focused MTA-38 terrain test set: 176 runs, 8,926 assertions, 0 failures, 0 errors, 0 skips.
- Full Ruby test suite: 1,404 runs, 16,750 assertions, 0 failures, 0 errors, 40 skips.
- Ruby lint: 348 files inspected, no offenses detected.
- Package verification produced `dist/su_mcp-1.8.0.rbz`.
- Deterministic review found no blocking L1 issues; review-driven low findings were addressed.
<!-- SIZE:VALIDATION-EVIDENCE:END -->

---

<!-- SIZE:DELTA:START -->
## Estimation Delta Review

The finalized plan asked for the main implementation shape. The actual delta is mostly estimation,
not scope: the conditional larger-timing gate fired, hosted repeatability had to be proven with
multiple real runs, and durable result artifacts became essential closeout evidence rather than a
nice-to-have transcript.

The predicted `Functional Scope = 2` remains correct. The predicted validation burden was
under-called: this class of task should score `4` when future tasks depend on durable hosted
performance evidence, real SketchUp geometry, repeat recapture instructions, and preserved result
files. Implementation friction was also slightly under-called because live replay/capture harnesses
can fail for reasons unit tests do not expose.

Most underestimated: validation burden and implementation friction. Most overestimated: none
material; the planned technical surface and dependency drag were accurate. Early-visible but
underweighted signal: the plan already warned that 49x49 timing might be unusable and that hosted
evidence was the core deliverable. Genuinely unknowable before execution: the repeat capture bugs
in baseline evidence fallback and timing-terrain cleanup.

Dominant actual failure mode: hosted performance baseline capture is sensitive to fixture scale,
scene cleanup, and real SketchUp retest loops. Future analog retrieval should notice
`validation:performance`, `host:repeated-fix-loop`, and `risk:performance-scaling`, not just
terrain replay/harness similarity.

Future estimates for terrain baseline tasks should treat "repeatable hosted performance evidence"
as its own deliverable, including result serialization, recapture docs, deployment/reload steps,
and at least one repeatability pass after fixes.
<!-- SIZE:DELTA:END -->

---

<!-- SIZE:TAGS:START -->
## Retrieval Tags

- `archetype:test-infrastructure`
- `scope:managed-terrain`
- `systems:command-layer`
- `systems:terrain-output`
- `systems:terrain-mesh-generator`
- `systems:test-support`
- `validation:hosted-matrix`
- `validation:performance`
- `validation:contract`
- `host:repeated-fix-loop`
- `host:performance`
- `contract:no-public-shape-change`
- `risk:performance-scaling`
- `confidence:high`
<!-- SIZE:TAGS:END -->
