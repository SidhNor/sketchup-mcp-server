# Size: MTA-19 Implement Detail Preserving Adaptive Terrain Output Simplification

**Task ID**: `MTA-19`  
**Title**: Implement Detail Preserving Adaptive Terrain Output Simplification  
**Status**: `failed; implementation reverted`
**Created**: 2026-05-01  
**Last Updated**: 2026-05-02  

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
  - `systems:surface-sampling`
  - `systems:public-contract`
- **Validation Modes**: `validation:hosted-matrix`, `validation:performance`, `validation:contract`, `validation:regression`
- **Likely Analog Class**: adaptive terrain output quality and hosted artifact validation

### Identity Notes
- This task follows the proven MTA-11 tiled heightmap v2/adaptive-output path and focuses on better derived SketchUp output quality, face count, and artifact behavior without changing `heightmap_grid` as the authoritative public or persisted payload kind or adding bulky proof data to public responses.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Improves generated terrain output behavior across create, adopt, and edit flows, but does not introduce a new public edit mode. |
| Technical Change Surface | 3 | Likely touches terrain output planning, mesh generation, terrain-kernel evidence paths, sampling checks, and compact response summaries. |
| Hidden Complexity Suspicion | 4 | Detail preservation, seam safety, hard grade breaks, planar simplification, and algorithm selection can interact in non-obvious ways. |
| Validation Burden Suspicion | 4 | Requires automated quality checks plus hosted irregular/edited terrain matrices, artifact inspection, performance interpretation, and contract leak scans. |
| Dependency / Coordination Suspicion | 2 | Depends on MTA-11 and MTA-16 behavior and live SketchUp verification, but remains within the managed terrain runtime boundary. |
| Scope Volatility Suspicion | 3 | Candidate algorithms are not selected yet; Delaunay, breakline-aware, global optimization, or hybrid approaches could resize the first implementation slice. |
| Confidence | 2 | The desired outcome is clear from MTA-11 live evidence, but the technical plan has not chosen an algorithm or tolerance model yet. |

### Early Signals
- MTA-11 live verification proved flat, planar crossfall, irregular, and edited adaptive outputs, creating strong baseline evidence for follow-up comparison.
- The task explicitly preserves `heightmap_grid` as source of truth and keeps generated SketchUp mesh disposable.
- Acceptance criteria require artifact checks for holes, loose edges, down-facing faces, cracks, and seam gaps.
- The task asks for compact public status/tolerance evidence while keeping detailed simplification proof in tests and hosted verification.
- Algorithm choice is intentionally deferred to technical planning, so seed confidence should stay limited.

### Early Estimate Notes
- Seed treats MTA-19 as a bounded but validation-heavy improvement to derived terrain output quality, not as a broad terrain-engine rewrite.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

> Filled during task planning. This is the main pre-implementation estimate.

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Improves behavior-visible adaptive terrain output quality across create, adopt, and edit regeneration, but keeps public terrain tools, edit modes, and `heightmap_grid` source-of-truth semantics stable. |
| Technical Change Surface | 3 | Touches the adaptive simplifier seam, simplified mesh value, output planning, mesh generation, compact response evidence, and focused terrain tests, while preserving v1 regular-grid and MTA-10 partial-regeneration paths. |
| Implementation Friction Risk | 4 | RTIN-style integer bintree is simpler than Delaunay/CDT, but arbitrary rectangular grids, source-sample error measurement, restricted/forced splits for T-junction safety, and indexed mesh emission are likely to resist a straight-line implementation. |
| Validation Burden Risk | 4 | Requires simplifier math tests, mesh artifact checks, no-leak contract coverage, v1/partial-output regressions, performance interpretation, and hosted MCP verification for flat, crossfall, irregular, edited, refusal, undo, and save/reopen cases. |
| Dependency / Coordination Risk | 2 | Depends on landed MTA-11/MTA-16 behavior and hosted SketchUp verification access, but remains inside the owned Ruby extension runtime with no upstream task or public client coordination expected. |
| Discovery / Ambiguity Risk | 3 | The primary algorithm is selected and externally reviewed, but exact arbitrary-rectangle split behavior, tolerance satisfaction, crack prevention, and face-count/performance behavior need implementation evidence. |
| Scope Volatility Risk | 3 | Delaunay/CDT, breaklines, public algorithm options, and adaptive partial regeneration are explicitly deferred, but RTIN correctness or performance failure could force replan, fallback, or a narrower first slice. |
| Rework Risk | 3 | A weak simplifier seam or incorrect split/crack policy could force revisiting output planning, generator emission, and tests, but the generic mesh seam should contain most rework if Delaunay is considered later. |
| Confidence | 2 | Planning evidence is strong enough for a bounded estimate and includes calibrated analogs plus `grok-4.20` review, but no RTIN prototype exists in this codebase yet. |

### Top Assumptions

- An RTIN-style integer bintree can operate directly on the arbitrary rectangular grids produced by current create/adopt flows without padding output outside terrain bounds.
- Restricted-neighbor or forced-split behavior can prevent T-junction artifacts without causing near-dense output in common irregular fixtures.
- The existing adaptive tolerance remains usable, or any tolerance adjustment stays internal, deliberate, and covered by tests.
- Full v2 adaptive regeneration remains acceptable for this task; dirty-region and tile evidence do not have to map to stable adaptive face ownership.
- `TerrainMeshGenerator` can emit generic indexed simplified triangles while preserving upward normals, generated markers, undo behavior, and compact response summaries.

### Estimate Breakers

- Arbitrary-rectangle RTIN cannot satisfy tolerance without degenerate triangles, cracks, or excessive face counts.
- T-junction prevention requires a broader mesh repair or triangulation strategy than the planned restricted/forced split policy.
- Hosted performance shows full adaptive regeneration is not acceptable for representative or near-cap terrain output.
- Public contract needs expand beyond compact summary fields, or algorithm/mesh internals leak into responses.
- Delaunay/CDT, breakline preservation, public simplification controls, or adaptive partial regeneration become required for acceptance.

### Predicted Signals

- MTA-11 is the closest analog: it delivered v2 `heightmap_grid` state and adaptive output, but actual validation found public payload vocabulary, elevation input, no-data, and planar evidence issues that required a fix-and-reverify loop.
- MTA-10 warns that terrain output changes can be dominated by real SketchUp mutation, save/reopen, undo, seam, and performance validation even when local tests pass.
- MTA-07/MTA-08 show generated output seams and markers can validate cleanly when the emission path is bounded, but they did not prove stronger adaptive simplification.
- External research and `grok-4.20` review support RTIN/bintree as the best first production path, while Delaunay/CDT remains a higher-complexity future option.
- User planning corrections make compact public output and full-regeneration acceptance explicit: detailed proof belongs in tests and hosted verification, not response JSON.

### Predicted Estimate Notes

- This prediction is the planning baseline after algorithm selection: RTIN-style integer bintree is primary, Delaunay/CDT and breaklines are future options, and full adaptive regeneration is acceptable if it validates.
- Calibrated analogs are useful but incomplete. MTA-11 covers the source-state and first adaptive output baseline; MTA-10 covers host-sensitive output validation; neither covers detail-preserving RTIN implementation.
- Validation burden is scored high because correctness depends on tolerance proof, artifact safety, no-leak public contract checks, and hosted SketchUp evidence, not because the task intentionally expands public request contracts.
- Rework risk is kept below the highest score because the planned generic simplified-mesh seam should preserve tests, response summaries, and generator integration even if the first simplifier backend needs revision.
<!-- SIZE:PREDICTED:END -->

---

<!-- SIZE:CHALLENGE:START -->
## Challenge Review

### Agreed Drivers

- The task boundary is stable after premortem: RTIN-style integer bintree is the first production
  backend; Delaunay/CDT, breaklines, public algorithm selection, and adaptive partial regeneration
  stay out of scope.
- Implementation friction remains `4` because the hard work is algorithmic and structural:
  arbitrary rectangular grids, source-sample error measurement, forced split propagation, and
  indexed SketchUp emission must all work together.
- Validation burden remains `4` because acceptance depends on tolerance proof, crack/T-junction
  proof, compact contract no-leak checks, performance interpretation, and hosted output behavior.
- Dependency risk remains `2`: MTA-11/MTA-16 and hosted access matter, but no upstream ownership
  or public-client coordination is expected before implementation.
- Confidence remains `2` because the plan is now concrete and externally reviewed, but there is
  still no RTIN prototype or hosted evidence for the stronger simplifier.

### Contested Drivers

- Whether validation burden should be `3` instead of `4`: routine hosted matrices alone would not
  justify `4`, but this task also carries performance interpretation, seam/crack artifact proof,
  save/reopen/undo checks, and a likely fix/reverify loop if RTIN geometry fails in SketchUp.
  Keep `4`.
- Whether implementation friction should drop after adding the algorithm sketch: the sketch lowers
  ambiguity, but it also makes the hard parts explicit. Keep `4` until split propagation and
  tolerance satisfaction are proven.
- Whether scope volatility should drop because Delaunay/CDT are explicitly deferred: keep `3`
  because RTIN failure could still force a replan, fallback, or narrower first slice.
- Whether rework risk should rise to `4`: keep `3` because the simplified-mesh seam should isolate
  backend changes and preserve contract/generator tests even if the first split policy needs
  revision.

### Missing Evidence

- No implementation proof yet that arbitrary rectangular RTIN can satisfy tolerance without
  overproducing faces or producing degenerate triangles.
- No proof yet that canonical edge registration and forced neighboring splits eliminate T-junctions
  in emitted SketchUp geometry.
- No performance proof yet separating simplifier cost from SketchUp emission for representative
  flat, crossfall, irregular, and edited terrains.
- No hosted proof yet that stronger adaptive output preserves markers, normals, undo, save/reopen,
  and non-mutating refusal behavior.

### Recommendation

- Confirm the predicted scores without revision.
- Proceed with implementation using the finalized `WARN` premortem gate.
- Treat unsatisfied tolerance, face count above dense full-grid output, public contract leakage,
  or hosted performance failure as stop-and-replan conditions rather than reasons to broaden the
  task into Delaunay/CDT, breaklines, or adaptive partial regeneration.

### Challenge Notes

- Challenge evidence came from the finalized premortem gate, prior `grok-4.20` planning review,
  calibrated MTA-11/MTA-10 analogs, and the added algorithm sketch.
- Final `grok-4.20` review found no blockers and judged the plan implementation-ready; optional
  wording refinements were applied for split tie-breaking and internal test-visible helper data.
- The premortem improved the plan but did not change the estimate: it converted ambiguity into
  implementation guardrails and validation gates rather than lowering algorithmic risk.
- Final plan and challenged size profile agree: this is a bounded public-contract-stable terrain
  output improvement with high implementation friction, high validation burden, moderate scope
  volatility, and moderate confidence only after implementation evidence exists.
<!-- SIZE:CHALLENGE:END -->

---

<!-- SIZE:DRIFT:START -->
## Drift Log

> Append only. Log only material changes that affect estimate shape, risk, confidence, or validation burden.

| Date | Phase / Checkpoint | Event Type | Severity (1-3) | Dimension Affected | Predictable Earlier? | Notes |
|---|---|---|---:|---|---|---|
| 2026-05-02 | Step 09 restricted RTIN rewrite after live artifact regression | Approach / rework | 3 | Implementation Friction, Scope Volatility, Rework Pressure | Yes | Predicted breaker became real: arbitrary-rectangle edge-split RTIN can create above-tolerance primitive triangles or visible cross-boundary facets on edited crossfall, while rectangle-aligned fallback is safe but not plan-conformant. Requires replan or a narrower accepted backend choice before final closeout. |
| 2026-05-02 | Step 10 local review after restricted splitter corrections | Resolution / validation | 2 | Implementation Friction, Rework Pressure, Confidence | Yes | The blocker was resolved without reverting to rectangle fallback: degenerate boundary interior splits were fixed, dense fallback was removed, long-edge continuity refinement was restricted to refinable edges/triangles, and edited crossfall regression tests now pass under full CI. |
| 2026-05-02 | Live MCP hard-rectangle topology repro | Defect / fix | 3 | Implementation Friction, Validation Burden, Confidence | Yes | Hosted verification found correct terrain-state samples but folded generated TIN topology after a 41x41 crossfall hard rectangle edit. Local repro was added, then fixed by constraining initial adaptive triangulation along detected sharp feature lines before refinement. |
| 2026-05-02 | Restarted Step 09 after revised RTIN plan | Approach / rework | 3 | Implementation Friction, Rework Pressure, Confidence | Yes | Existing simplifier internals were judged plan-incompatible: arbitrary interior insertion, free-form split scoring, and post-hoc repair loops were removed instead of patched. A fresh restricted lattice-edge hierarchy with final-heightfield feature pressure now passes focused simplifier tests, terrain integration tests, and full local CI. |
| 2026-05-02 | Final live corridor-heavy reset pass | Failure / revert | 3 | Validation Burden, Rework Pressure, Confidence, Scope Volatility | Yes | Hosted MCP verification showed corridor-heavy terrain remained unreliable after three implementation attempts: valid-looking corridors refused, flat/steep/descending corridors produced suspicious topology, the sophisticated adopted terrain/corridor path exceeded the default MCP timeout, and the final implementation was reverted rather than committed. |

### Drift Notes
- Material drift occurred during implementation and ended in a failed implementation, not a
  shippable local code path.
- The restarted implementation confirmed the original estimate breaker around RTIN correctness and
  rework pressure. It stayed inside the planned public-contract-stable boundary, but it failed the
  hosted artifact and reliability gates badly enough to justify revert.
<!-- SIZE:DRIFT:END -->

---

<!-- SIZE:ACTUAL:START -->
## Actual Profile

> Filled at the end of implementation. Do not overwrite predicted values.

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | The behavior-visible task stayed at the planned level: improved adaptive output across create/adopt/edit regeneration while preserving public terrain tools and `heightmap_grid` source semantics. |
| Technical Change Surface | 3 | Actual changes touched the simplifier backend, simplified mesh value object, output planning, mesh generation, contract tests, and terrain regression coverage, but did not expand into public schemas or unrelated runtime layers. |
| Actual Implementation Friction | 4 | The first implementation was plan-incompatible and had to be replaced. Hidden topology invariants around lattice splitting, feature partitions, corridor endpoints, and overlapping edits dominated the implementation loop. |
| Actual Validation Burden | 4 | Validation exposed multiple artifact defects and forced repeated fix/review/retest cycles. Final hosted MCP checks failed and caused the implementation to be reverted. |
| Actual Dependency Drag | 2 | Work depended on MTA-11/MTA-16 terrain state behavior and external MCP live-recheck feedback, but remained within the owned Ruby extension runtime. |
| Actual Discovery Encountered | 4 | Execution required material algorithm discovery: the initial plan was clarified from MARTINI wording to generalized integer-grid RTIN, then corrected again when arbitrary insertion and repair-loop behavior proved unsuitable. |
| Actual Scope Volatility | 3 | The public task boundary stayed stable, but the internal backend approach materially shifted from the earlier wrong implementation to a fresh restricted lattice-edge hierarchy. |
| Actual Rework | 4 | Completed simplifier work was revisited and largely rewritten after live topology failures and plan-compliance review. Review follow-up changes were small only after the rewrite stabilized. |
| Final Confidence in Completeness | 1 | Confidence is high that the attempted implementation should not ship, but confidence in task completion is low because the runtime code was reverted and no replacement was accepted. |

### Actual Profile Notes
- The prediction correctly called high implementation friction and validation burden, but the
  actual failure mode was sharper than expected: correct height samples could still generate
  visually folded adaptive topology.
- The task did not broaden the public contract; compact response shape stayed stable.
- Confidence in the attempted implementation dropped after hosted MCP verification. The final
  artifact is a failure record and reverted codebase, not a completed runtime improvement.
<!-- SIZE:ACTUAL:END -->

---

<!-- SIZE:VALIDATION-EVIDENCE:START -->
## Validation Evidence Summary

> Fill only the sections that are relevant. Say `not applicable` where needed.

### Automated Validation
- Attempted implementation before revert passed focused adaptive simplifier tests after final
  review fixes: `17 runs`, `104 assertions`,
  `0 failures`, `0 errors`.
- Attempted implementation before revert passed nearby adaptive integration and contract slice
  after final review fixes: `46 runs`,
  `639 assertions`, `0 failures`, `0 errors`.
- Attempted implementation before revert passed full terrain suite after final review fixes:
  `269 runs`, `2279 assertions`, `0 failures`, `0 errors`, `3 skips`.
- Attempted implementation before revert passed aggregate local CI after final review fixes:
  RuboCop `219 files inspected`, Ruby tests `869 runs`, `4629 assertions`, `0 failures`,
  `0 errors`, `37 skips`, and package verification produced `dist/su_mcp-1.1.1.rbz`.
- Grok-4.20 final review reported no blocking correctness or contract issues; medium performance
  recommendations were addressed and CI was rerun.
- `$task-review` full mode completed; the only remaining L2 facts are internal signature-change
  facts, with no dead-code, security, taint/resource, or cognitive-complexity violations.

### Hosted / Manual Validation
- Failed. The final live MCP reset pass found that corridor-heavy terrain remained unreliable:
  crossfall and flat corridors produced suspicious sharp normal breaks, 61x61 crossfall corridor
  refused with `tolerance_not_satisfied`, steep/descending corridors looked visually high-risk, and
  adopted sophisticated terrain corridor attempts mostly refused or exceeded the default MCP
  timeout before later completing in SketchUp.
- Earlier hosted rechecks also found dense-output regressions, folded topology, and corridor
  endpoint artifacts that drove repeated implementation rewrites.

### Performance Validation
- Automated default CI did not include long-running performance tests.
- Hosted validation exposed timeout-envelope risk: sophisticated terrain adoption and one corridor
  attempt exceeded the default `120s` MCP timeout and later completed in SketchUp. Adoption is a
  rare one-time conversion path where multi-minute duration can be acceptable; repeated corridor
  edit regeneration has a much tighter practical latency bar.

### Migration / Compatibility Validation
- Public MCP payload vocabulary remains `heightmap_grid` plus compact `adaptive_tin` derived
  output summary. No public request schema or public payload kind changed.

### Operational / Rollout Validation
- Local package verification passed through `rake ci`, but rollout validation failed because the
  attempted implementation could refuse valid-looking edits and produce suspicious topology. The
  default MCP timeout mismatch is a secondary operations concern, not the primary rejection reason.
<!-- SIZE:VALIDATION-EVIDENCE:END -->

---

<!-- SIZE:DELTA:START -->
## Estimation Delta Review

> Filled during final calibration. Compare prediction to actual behavior.

### Prediction vs Actual
- Functional scope matched prediction (`3 -> 3`): the attempted behavior-visible change targeted
  create/adopt/edit output quality without public tool or request-contract expansion, even though
  the implementation failed and was reverted.
- Technical surface matched prediction (`3 -> 3`): changes stayed in terrain simplification,
  output planning, mesh generation, and tests.
- Implementation friction matched the high-risk prediction (`4 -> 4`), but the dominant friction
  was more severe than the first plan implied because a completed wrong backend had to be removed.
- Validation burden matched prediction (`4 -> 4`): live feedback found artifact failures that local
  sampling alone could not catch, and final hosted validation rejected the implementation.
- Dependency drag matched prediction (`2 -> 2`): dependencies mattered, but ownership remained
  local.
- Discovery exceeded the most optimistic interpretation (`3 -> 4`): algorithm semantics had to be
  clarified repeatedly, and plan compliance mattered as much as raw face count.
- Scope volatility matched prediction (`3 -> 3`): public scope stayed bounded, but the internal
  algorithmic approach shifted materially.
- Rework exceeded prediction (`3 -> 4`): the implementation required a fresh restricted
  lattice-edge hierarchy rather than incremental repair.
- Final confidence in task completion is low (`1`) because hosted verification rejected the
  implementation and runtime code was reverted.

### Underestimated
- The most underestimated driver was topology correctness after edits. Public samples and
  vertex residuals can pass while triangle connectivity still produces visible folded seams.
- Corridor longitudinal end caps were underweighted relative to side blends and rectangle/circle
  boundaries.
- Plan compliance risk was underweighted: additive fixes around arbitrary insertion and repair
  loops were worse than replacing the backend.

### Overestimated
- Public contract churn was overestimated. The task did not need new public algorithm selectors or
  bulky proof JSON.
- Dependency drag was contained; external live checks supplied evidence but did not require
  upstream code ownership changes.

### Early-Visible Signals
- MTA-11 already showed that adaptive output needs live geometry inspection, not only sample
  correctness.
- The plan's warning about arbitrary rectangular grids and forced splits was accurate and should
  be treated as a blocker signal for future terrain meshing tasks.

### Dominant Actual Failure Mode
- Correct heightfield state plus incorrect adaptive triangulation topology: long or incompatible
  triangles across edit boundaries, corridor end caps, or combined edits can create visible folds
  even when source elevations and public samples are correct.

### Future Analog Notes
- Future terrain simplification tasks should budget for at least one hosted artifact fix loop
  unless they reuse a proven topology validator.
- Treat edit-combined final heightfields as first-class fixtures; individual shape cases are not
  enough.
- Keep long performance tests out of default CI; use small deterministic topology fixtures in
  automation and reserve timing for hosted matrices.
- Do not promote an alternative triangulator directly into production runtime. First prove it in a
  standalone harness using captured live-failure heightfields.
<!-- SIZE:DELTA:END -->

---

<!-- SIZE:TAGS:START -->
## Retrieval Tags

- `archetype:performance-sensitive`
- `scope:managed-terrain`
- `systems:terrain-output`
- `systems:terrain-mesh-generator`
- `systems:terrain-kernel`
- `systems:surface-sampling`
- `validation:hosted-matrix`
- `validation:performance`
- `validation:contract`
- `host:special-scene`
- `contract:response-shape`
- `risk:performance-scaling`
- `risk:topology-artifacts`
- `rework:algorithm-rewrite`
- `volatility:high`
- `confidence:low`
- `outcome:failed-reverted`
<!-- SIZE:TAGS:END -->
