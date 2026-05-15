# Size: MTA-37 Implement CDT Patch Residual Frontier Batching

**Task ID**: MTA-37  
**Title**: Implement CDT Patch Residual Frontier Batching  
**Status**: calibrated; closed; failed-performance-gates; implementation-reverted; not-production-path  
**Created**: 2026-05-14  
**Last Updated**: 2026-05-15  

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
  - `systems:terrain-kernel`
  - `systems:terrain-mesh-generator`
  - `systems:public-contract`
- **Validation Modes**: `validation:performance`, `validation:hosted-matrix`, `validation:contract`, `validation:regression`
- **Likely Analog Class**: private gated terrain output performance slice with hosted strict-path evidence

### Identity Notes
- Closest analogs are MTA-35 strict CDT productionization, MTA-36 PatchLifecycle, MTA-32 residual CDT proof, and MTA-34 hosted-evidence caution.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 2 | Private CDT behavior improves, but public terrain behavior and default output remain unchanged. |
| Technical Change Surface | 3 | Residual engine, CDT backend metrics, solver/provider integration, mesh-generator safety tests, and no-leak checks are in scope. |
| Hidden Complexity Suspicion | 3 | Existing batching already exists, so real gains depend on selection quality, stop policy, and diagnostics rather than simple constant tuning. |
| Validation Burden Suspicion | 3 | Performance, hosted strict-path evidence, and topology/seam/no-delete checks all matter. |
| Dependency / Coordination Suspicion | 2 | Depends on MTA-35/MTA-36 behavior and SketchUp-hosted eval access, but no new external system is planned. |
| Scope Volatility Suspicion | 2 | Native/seam-lattice pressure is explicit but intentionally gated to follow-up classification. |
| Confidence | 3 | Task is well researched and bounded, with remaining uncertainty mainly around performance outcome. |

### Early Signals
- Private/default-disabled CDT path keeps functional scope bounded.
- Multiple safety gates and hosted performance evidence keep validation non-trivial.
- Prior MTA-35/MTA-36 evidence gives strong analog grounding.
- Research pass gates can classify failure without expanding this task to native or seam-lattice work.

### Early Estimate Notes
- Seed reflects planning rebaseline after Step 06 resolved tolerance, hosted evidence, stop vocabulary, and rollout questions.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

> Filled during task planning. This is the main pre-implementation estimate.

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | 2 | User-visible public behavior does not change, but private strict CDT evidence and performance behavior materially change. |
| Technical Change Surface | 3 | Work spans residual policy, CDT backend metrics, provider/solver compatibility, mesh-generator safety, contract no-leak tests, and hosted eval evidence. |
| Implementation Friction Risk | 3 | Current engine already batches/thins; implementation must improve selection quality without over-extracting or changing provider handoff. |
| Validation Burden Risk | 3 | Correctness requires unit, integration, no-leak, and hosted performance evidence with interpretation against research gates. |
| Dependency / Coordination Risk | 2 | Depends on existing private CDT wiring, MTA-35/MTA-36 behavior, and SketchUp-hosted eval access, but no new public or external dependency is introduced. |
| Discovery / Ambiguity Risk | 2 | Major design decisions are resolved; uncertainty remains around whether Ruby rebuild batching can hit target gates. |
| Scope Volatility Risk | 2 | If gates fail, closeout classifies next work rather than expanding this task; volatility is controlled by explicit non-goals. |
| Rework Risk | 3 | Candidate policy may need revisiting if build count does not move or max error worsens while RMS/p95 look acceptable. |
| Confidence | 3 | Strong code/research review and consensus support the plan; confidence is capped by unproven hosted performance outcome. |

### Top Assumptions
- Existing `cdt_patch` private mode and MCP `eval_ruby` grey-box path are available for hosted validation.
- Residual policy changes can stay below `TerrainCdtBackend` without changing public request/response contracts.
- Existing exact boundary synchronization remains stable when interior residual selection changes.
- Local deterministic tests can isolate policy behavior before hosted performance evidence is meaningful.

### Estimate Breakers
- Current Ruby rebuild backend cannot materially reduce build count without true local invalidation.
- Hosted eval payload cannot reproduce the MTA-35 broad-overlap strict command path without bypassing public routing.
- Candidate batching lowers build count but causes topology/seam/fallback regressions.
- New internal diagnostics leak into public responses or require public contract changes.

### Predicted Signals
- Performance-sensitive private terrain output slice with no public shape change.
- Validation depends on accepted strict CDT output, not provider-only metrics.
- Hidden complexity is concentrated in residual selection quality and stop/diagnostic semantics.
- Prior terrain tasks repeatedly found hosted behavior that local doubles did not prove.

### Predicted Estimate Notes
- Prediction uses the draft `plan.md`, local code research, CDT direction note, MTA-35/MTA-36 analog evidence, and Step 06 consensus. Hosted validation is scored as high-risk routine-plus-performance evidence, not as repeated-fix burden unless implementation later proves that drift.
<!-- SIZE:PREDICTED:END -->

---

<!-- SIZE:CHALLENGE:START -->
## Challenge Review

> Filled when the estimate is pressure-tested through external review, premortem, or controlled consensus.

### Agreed Drivers
- Private/default-disabled CDT and no public contract change keep functional scope moderate.
- Residual policy, CDT backend metrics, provider/solver compatibility, mesh-generator safety, and hosted evidence justify high technical surface and friction risk.
- Hosted validation is necessary because accepted strict CDT output, registry/readback, no-delete behavior, and public command routing cannot be proven by provider-only tests.
- Current Ruby residual engine already batches/thins, so implementation risk is about selection quality and evidence, not just adding new code.

### Contested Drivers
- Whether deterministic batch-refinement over full Ruby rebuilds can materially reduce build count enough is contested; one external stance argued true heap/local invalidation may be needed sooner.
- Whether minimal extraction is enough is contested; the plan accepts minimal private collaborators but avoids the full research component set unless tests justify it.
- Hosted validation burden is contested: it is a performance and accepted-output proof requirement, but not scored as very high unless implementation hits fix/redeploy/retest loops.

### Missing Evidence
- No post-implementation hosted broad-overlap row exists yet.
- No implementation evidence yet proves candidate scoring can reduce build count below the MTA-35 baseline.
- No evidence yet proves max/RMS/p95 error remain acceptable after batching changes.

### Recommendation
- Keep the predicted profile unchanged. Treat performance and hosted evidence as estimate breakers rather than resizing before implementation.
- Reconsider validation burden or rework risk only if hosted proof requires a fix/redeploy/retest loop, candidate policy fails to move build count, or internal diagnostics leak into public responses.

### Challenge Notes
- Challenge evidence came from Step 06 consensus disagreement and Step 12 premortem. The final plan already carries the disputed items as guardrails, accepted residual risks, or closeout classifiers, so no predicted-score revision is justified before implementation.
<!-- SIZE:CHALLENGE:END -->

---

<!-- SIZE:DRIFT:START -->
## Drift Log

> Append only. Log only material changes that affect estimate shape, risk, confidence, or validation burden.

| Date | Phase / Checkpoint | Event Type | Severity (1-3) | Dimension Affected | Predictable Earlier? | Notes |
|---|---|---|---:|---|---|---|
| 2026-05-15 | First implementation review | Full rollback | 3 | Implementation Friction, Validation Burden, Rework, Final Confidence | Yes | Initial implementation skewed toward scoring/diagnostics and did not cover the critical per-patch heap/top-K batching mechanics strongly enough. User review forced rereading the task, plan, and CDT direction note, and that initial implementation was fully rolled back before starting a new TDD queue. |
| 2026-05-15 | Second implementation attempt | Reimplementation drift | 3 | Implementation Friction, Validation Burden, Rework, Final Confidence | Partially | A fuller reimplementation added `ResidualCandidateFrontier`, candidate counters, block-filtered rescans, and hosted timing evidence, but still behaved like the old residual loop with a heap wrapper. It did not establish broad retained frontier behavior, full-point-set spacing, or enough scan/rebuild reduction to test Slice 1 fairly. |
| 2026-05-15 | Implementation review / reopen | Implementation drift | 3 | Implementation Friction, Validation Burden, Rework, Final Confidence | Partially | The shipped heap/frontier wrapper did not implement the planned Slice 1 economics. It fed the heap from limited residual windows, enforced spacing only within the current batch, still scanned/rebuilt too often, and did not prove broad retained frontier behavior. Plan/task/summary were updated with non-negotiable mechanics and red-test gates before further implementation. |
| 2026-05-15 | Third implementation pass / hosted closeout | Corrected mechanics, failed performance | 3 | Validation Burden, Rework, Final Confidence | Partially | Third pass added red tests and corrected broad frontier load, retained multi-batch heap use, full-current-point spacing, dirty-block rescore, final full scan, and recovery after spacing stalls. Hosted public command path emitted valid CDT patch faces under 0.05m max error, but still took `59.89s` across create plus four edits with `539` engine builds and `29.82s` retriangulation, so Slice 1 performance failed after mechanics were finally proven. |
| 2026-05-15 | Post-closeout baseline | Stashed-code comparison | 2 | Validation Burden, Final Confidence | Yes | CDT frontier/runtime changes were manually stashed under `/tmp/mta37-frontier-stash` after `git stash push` failed. A hosted public CDT run without those runtime changes on a non-flat recovered 100x100 terrain produced `88.38s` across create plus four edits, `193` backend calls, computed `822` builds, `13.13s` scan, and `51.52s` retriangulation. The row is CDT-representative but not an exact replay of the original initial fixture, so it supports directionally judging the change but not a clean percentage claim. |
| 2026-05-15 | Step 10 closeout | Production-path guard | 2 | Final Confidence, Validation Burden | Yes | Task closeout now explicitly classifies the Slice 1 result as evidence-only and not a production/default output path. Added a default-stack regression proving `TerrainOutputStackFactory.new(env: {})` keeps CDT disabled so the supported production terrain path remains adaptive unless the private switch is explicitly selected. |
| 2026-05-15 | Final closeout decision | Implementation reverted | 3 | Rework, Final Confidence, Scope Volatility | Yes | User and implementation review concluded the MTA-37 code should not be retained on top of the already performance-failed private CDT backend. The residual-frontier class, residual engine changes, height-meter changes, mesh-generator CDT-path changes, and related tests were reverted/removed. The task keeps the evidence and default-production guard only, and closes as `failed-performance-gates; implementation-reverted; not-production-path`. |

### Drift Notes
- MTA-37 has already consumed two implementation rounds: an initial scoring/diagnostics-oriented pass
  that was fully rolled back, followed by a fuller frontier reimplementation attempt.
- The current reopen is therefore a third implementation pass, not a minor cleanup.
- The drift is not only missed timing. The larger issue is implementation-shape drift: current code can
  satisfy superficial acceptance language while failing the planned per-patch error-frontier behavior.
- Future effort must treat broad frontier population, retained multi-batch heap use, full-current-point
  spacing, dirty-block rescore, and final full quality scan as estimate-bearing implementation work.
- Third-pass hosted validation proved those mechanics but also showed the estimate breaker directly:
  Ruby full-patch retriangulation and patch/backend call count dominate after residual-loop policy
  correction.
- Final closeout removed the attempted residual-frontier implementation so future work does not
  inherit an unproven salvage layer as if it were a viable production foundation.
<!-- SIZE:DRIFT:END -->

---

<!-- SIZE:ACTUAL:START -->
## Actual Profile

> Filled at the end of implementation. Do not overwrite predicted values.

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | 1 | Final retained behavior is evidence and a default-path guard; public terrain behavior and default output did not change. |
| Technical Change Surface | 1 | The failed residual-frontier implementation was reverted. Only a focused default-stack guard remains from the code changes. |
| Actual Implementation Friction | 4 | Existing residual loop structure supported the heap/frontier implementation, but policy correctness required several control-flow fixes around incremental misses, recovery insertion, and stale cap/spacing state. Hosted evidence still missed the performance gates. |
| Actual Validation Burden | 3 | Required focused units, CDT/provider/mesh-generator regression, full tests/lint/package, deployed hosted strict-CDT validation, rollback validation, and performance interpretation. External review was skipped by explicit user instruction after the implementation was reverted. |
| Actual Dependency Drag | 2 | Relied on MTA-35/MTA-36 runtime shape and live SketchUp access; hosted validation required deploying changed runtime files and selecting private `cdt_patch` mode. |
| Actual Discovery Encountered | 3 | Hosted recording required switching from injected generator capture to backend method recording, fixing the rectangle fixture shape, deduplicating recorder output, and using the MTA-36-style head-to-head row to expose the performance regression. |
| Actual Scope Volatility | 2 | Scope stayed within residual policy and diagnostics until closeout, then intentionally changed from retained implementation to evidence-only/reverted implementation. Native, seam-lattice, and public contract work remained out of scope. |
| Actual Rework | 4 | Rework included multiple implementation passes, hosted retesting, baseline comparison, and final implementation removal after the performance evidence failed to justify carrying the code. |
| Final Confidence in Completeness | 3 | The task is complete as failed evidence: implementation was tried, measured, rejected, and reverted. Confidence is in the closeout decision, not in the failed Ruby backend direction. |

### Actual Signals
- Weighted residual scoring, bounded insertion, rejection counters, error summaries, and low-improvement stop were implemented and measured, then reverted.
- Provider handoff, PatchLifecycle ownership, exact seam synchronization, default output mode, and public MCP contracts are unchanged in the final code state.
- Hosted public command-path rows accepted with max height error under 0.05m, but performance stayed
  far outside the Slice 1 target shape.
- Final pre-revert hosted evidence still recorded `539` engine builds, `10.98s` residual scan, and
  `29.82s` retriangulation across create plus four edits.
- The implementation failed the Slice 1 pass gates: it did not collapse engine builds to `<= 6`, retriangulation to `<= 1.25s`, scan time to `<= 0.75s`, or lifecycle total to `<= 3.5s`.
- The retained behavior is not the residual frontier. The retained result is the evidence-backed decision that this Ruby residual-loop direction should not be kept as a production foundation.
- External `grok-4.3` review was skipped by explicit user instruction after the failed implementation
  was reverted; no retained production CDT implementation remained for that review.

### Actual Notes
- Actual technical surface was narrower than predicted because provider, solver, mesh-generator, and contract files only needed regression validation.
- Actual validation burden stayed high because the task needed hosted performance evidence, head-to-head legacy comparison, a correction pass, and failure classification against the Slice 1 gates.
<!-- SIZE:ACTUAL:END -->

---

<!-- SIZE:VALIDATION-EVIDENCE:START -->
## Validation Evidence Summary

> Fill only the sections that are relevant. Say `not applicable` where needed.

### Automated Validation
- Historical pre-revert focused CDT tests passed and are recorded in `summary.md`; those covered the
  failed implementation before removal and are evidence for the performance decision, not retained
  production behavior.
- Post-revert focused default-path guard:
  `bundle exec ruby -Itest test/terrain/output/terrain_output_stack_factory_test.rb`
  - `4 runs, 7 assertions, 0 failures, 0 errors, 0 skips`.
- Full Ruby tests after rollback:
  `1362 runs, 15227 assertions, 0 failures, 0 errors, 37 skips`.
- Full Ruby lint: `334 files inspected, no offenses detected`.
- Package verification produced `dist/su_mcp-1.7.0.rbz`.

### Hosted / Manual Validation
- Historical SketchUp hosted validation used public `create_terrain_surface` and
  `edit_terrain_surface` paths with representative `100x100`, `1m` terrain rows before the final
  rollback. That evidence failed Slice 1 performance gates and drove the revert decision.
- Post-revert installed-extension check reported
  `TerrainOutputStackFactory.new(env: {}).mesh_generator.cdt_enabled? == false`.
- Post-revert installed-extension check also confirmed
  `su_mcp/terrain/output/cdt/patches/residual_candidate_frontier.rb` is absent from the SketchUp
  plugin tree.
- Full hosted public edit replay was not rerun after rollback because the retained code change is a
  test-only default-path guard and the failed runtime implementation was removed.

### Performance Validation
- Pre-revert final public command-path row took `59.89s` across create plus four edits with `140`
  accepted backend calls, `539` engine builds, `10.98s` residual scan, `29.82s` retriangulation, and
  max error `0.04998m`.
- A later no-frontier hosted baseline, run after manually stashing the third-pass CDT runtime delta,
  emitted `10250` `cdt_patch_face` faces from a non-flat recovered 100x100 terrain state. It took
  `88.38s` across create plus four edits with `193` accepted backend calls, computed `822` builds,
  `13.13s` scan, and `51.52s` retriangulation. Because it reused elevations recovered from the prior
  final terrain rather than the exact initial fixture, it is not a clean head-to-head percentage row.
- Slice 1 pass gates failed:
  - engine builds target `30 -> <= 6`; final pre-revert evidence still showed `539` engine builds
    across create plus four edits;
  - retriangulation target `~4.31s -> <= 1.25s`; backend time remained multi-second per edit;
  - residual scan target `~1.71s -> <= 0.75s`; final aggregate scan remained `10.98s`;
  - lifecycle total target `~7.85s -> <= 3.5s`; final aggregate wall time remained `59.89s`.
- Closeout classified the row as `residual-policy-failed; native_or_incremental_backend_needed`
  because the weighted scoring path did not meet Slice 1 performance acceptance and Ruby full-patch
  rebuild cost remains dominant.

### Migration / Compatibility Validation
- Public request/response schemas, default output mode, PatchLifecycle ownership, registry
  persistence, exact seam synchronization, and provider handoff were unchanged.
- Save/reopen readback was not rerun because the implementation did not change persistence,
  ownership metadata, or registry readback.

### Operational / Rollout Validation
- CDT remains private/default-disabled.
- Package verification passed after rollback.

### Validation Notes
- Hosted evidence should be treated as representative decision evidence, not a statistical benchmark.
- The final retained code is a default-path guard plus task evidence; the failed CDT implementation
  was reverted.
<!-- SIZE:VALIDATION-EVIDENCE:END -->

---

<!-- SIZE:DELTA:START -->
## Estimation Delta Review

> Filled during final calibration. Compare prediction to actual behavior.

- **Most Underestimated Dimension**: Implementation friction; repeated implementation review and
  hosted timing exposed that superficial heap/scoring changes could satisfy local tests while still
  missing the planned error-frontier economics.
- **Most Overestimated Dimension**: Technical Change Surface; implementation stayed in residual engine and height-meter seams rather than needing provider, solver, mesh-generator, or public contract changes.
- **Signal Present Early But Underweighted**: The existing Ruby residual loop already batched and
  rescanned enough that a wrapper frontier would not necessarily change backend-call or rebuild
  economics.
- **Genuinely Unknowable Factor**: Whether corrected hosted strict-CDT mechanics would reduce enough
  rebuild/scan time to justify keeping the Ruby direction; they did not.
- **Future Similar Tasks Should Assume**: Private CDT performance slices must be judged against the
  explicit timing/build gates, not just valid output. A retained heap without incremental/local
  retriangulation is not a viable production foundation.

### Calibration Notes
- Prediction was directionally right on performance and validation risk. Actual implementation
  friction was higher because the work went through a full rollback, a fuller reimplementation that
  was still insufficient, a corrected mechanics pass, hosted performance failure, baseline
  comparison, and final code removal. The correct lesson is that valid CDT output and some residual
  batching are not enough; future work needs a backend design that directly reduces patch/backend
  calls and retriangulation cost.
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
- `validation:hosted-matrix`
- `host:performance`
- `contract:no-public-shape-change`
- `risk:performance-scaling`
- `risk:ruby-backend-limit`
- `volatility:implementation-reverted`
- `friction:high`
- `confidence:high`
<!-- SIZE:TAGS:END -->
