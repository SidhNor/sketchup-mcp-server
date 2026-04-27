# Size: MTA-14 Evaluate Base Detail Preserving Survey Correction

**Task ID**: `MTA-14`  
**Title**: Evaluate Base Detail Preserving Survey Correction  
**Status**: `calibrated`
**Created**: 2026-04-27  
**Last Updated**: 2026-04-27  

**Related Task**: [task.md](./task.md)  
**Related Plan**: [plan.md](./plan.md)  
**Related Summary**: [summary.md](./summary.md)

---

<!-- SIZE:IDENTITY:START -->
## Identity

- **Task Archetype**: validation-heavy
- **Primary Scope Area**: managed terrain
- **Likely Systems Touched**:
  - terrain-state
  - terrain-kernel
  - test-support
  - docs
- **Validation Modes**: regression, docs-check
- **Likely Analog Class**: terrain-domain evaluation and solver-selection spike

### Identity Notes
- This task is not a public terrain edit mode. It is an evaluation/prototype task that must remove solver ambiguity for `MTA-13` through deterministic terrain-domain fixtures, metrics, and a recommendation artifact.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 2 | Produces decision evidence for a P0 survey workflow but does not ship public runtime behavior. |
| Technical Change Surface | 2 | Expected touch surface is test/support evaluation code, task artifacts, and possibly docs; no runtime schema, dispatcher, storage, or output changes. |
| Hidden Complexity Suspicion | 4 | Base/detail correction hides real math decisions around low-pass behavior, mask formulas, multi-point solves, thresholds, and repeated-edit drift. |
| Validation Burden Suspicion | 3 | The task must prove strategy behavior across representative fixtures and edge cases; hosted validation is conditional rather than default. |
| Dependency / Coordination Suspicion | 2 | Depends on prior terrain kernels and must hand off cleanly to `MTA-13`, but should not require runtime coordination. |
| Scope Volatility Suspicion | 3 | Scope can expand if base/detail proves underdefined, constrained optimization becomes necessary, or v1 heightmap fidelity is inadequate. |
| Confidence | 2 | Product need and boundaries are clear, but solver details required Step 05 refinement and external challenge. |

### Early Signals
- The source task is explicitly evaluation-oriented and excludes public survey-mode implementation.
- `MTA-13` should not inherit broad solver research, so `MTA-14` must be more concrete than an ordinary research note.
- Calibrated terrain analogs show public runtime terrain work is expensive, but this task avoids that surface unless hosted assumptions become necessary.
- Grok 4.20 challenged the initial base/detail sketch as under-specified, raising hidden complexity suspicion.

### Early Estimate Notes
- Seed reflects the refined planning baseline after confirming MTA-14 is planning-ready and should absorb base/detail math ambiguity before `MTA-13`.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

> Filled during task planning. This is the main pre-implementation estimate.

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | 2 | The task produces implementation-guiding evidence and a solver recommendation, but no user-facing tool behavior ships. |
| Technical Change Surface | 2 | Planned work stays in test/support evaluation code, metrics, fixture tests, `summary.md`, and task metadata; runtime, storage, loader schema, and public docs examples remain unchanged. |
| Implementation Friction Risk | 3 | The base/detail algorithm is now specified, but implementing low-pass, masks, least-squares correction, metric calculations, and repeated-edit evaluation can still resist simple coding. |
| Validation Burden Risk | 3 | Correctness depends on deterministic fixtures, metric assertions, strategy comparison, refusal/escalation scenarios, and recommendation logic rather than a routine unit test only. |
| Dependency / Coordination Risk | 2 | Depends on current terrain-domain helpers and must hand off to `MTA-13`; hosted validation is conditional, not a default blocking dependency. |
| Discovery / Ambiguity Risk | 3 | Step 05 and Grok challenge reduced ambiguity, but fixture results may still show v1 heightmap or base/detail assumptions are insufficient. |
| Scope Volatility Risk | 2 | The plan deliberately blocks public-contract expansion and broad optimization research, but scope could shift if constrained penalty solving must be defined or deferred explicitly. |
| Rework Risk | 2 | Rework is likely contained to algorithm parameters, metric definitions, and recommendation thresholds rather than runtime architecture. |
| Confidence | 3 | The draft plan is concrete and analog-backed; confidence is capped because the candidate strategy has not yet been exercised against fixtures. |

### Top Assumptions

- A SketchUp-free evaluation harness over `HeightmapState` is sufficient only for terrain-domain solver comparison; `MTA-13` still needs hosted/public MCP validation for the implemented edit mode.
- Cropped square neighborhood averaging is adequate for the low-pass base candidate; FFT-style UE filtering is unnecessary for MTA-14.
- Minimum-norm bilinear stencil and small least-squares correction are enough to evaluate v1 base/detail feasibility without broad constrained optimization.
- Fixture-derived threshold guidance is acceptable for `MTA-13`; hard-coded universal safety constants are not required at planning time.

### Estimate Breakers

- Base/detail correction cannot be evaluated without implementing a materially broader constrained optimization solver.
- The parameter matrix produces inconclusive results, forcing another research iteration instead of a recommendation package.
- Hosted SketchUp behavior becomes necessary to trust the evaluation, adding transform/persistence/output validation work.
- The evaluation discovers that current v1 `heightmap_grid` cannot support representative survey correction, requiring the task to pivot into a stronger `MTA-11` escalation design.
- Test/support prototype code needs to become production runtime code to be useful, expanding scope into `MTA-13`.

### Predicted Signals

- Calibrated `MTA-01` shows docs/spec/research tasks can stay low validation burden when no runtime changes occur.
- Calibrated `MTA-06` and `MTA-12` show terrain-domain kernels and metrics can be implemented cleanly when public contract boundaries are settled.
- Calibrated `MTA-04`, `MTA-05`, and `MTA-10` warn against underestimating hosted behavior, but their heavy burden came from public runtime mutation and output regeneration surfaces that MTA-14 excludes.
- The strongest current risk is solver/math specificity, not public contract drift.
- Step 05 external challenge directly improved plan specificity around low-pass, mask, base correction, metrics, and thresholds.

### Predicted Estimate Notes

- This prediction is based on the Step 09 draft plan before premortem changes.
- The estimate treats MTA-14 as a hard solver-selection gate for `MTA-13`, not as a production survey edit implementation.
- Validation burden is scored moderate-high because the task must generate convincing comparative evidence, not because hosted matrices or public contract changes are expected.
<!-- SIZE:PREDICTED:END -->

---

<!-- SIZE:CHALLENGE:START -->
## Challenge Review

> Filled when the estimate is pressure-tested through external review, premortem, or controlled consensus.

### Agreed Drivers
- The dominant task risk is solver/math specificity, not public contract drift.
- The plan correctly keeps `MTA-14` out of public runtime behavior, loader schema, dispatcher wiring, persisted terrain schema, and README tool examples.
- The Grok 4.20 planning challenge materially improved the plan by forcing exact low-pass, detail mask, base-correction, metric, and threshold decisions.
- The premortem correctly made `summary.md` mandatory because the business value is a solver recommendation package for `MTA-13`.
- Validation burden remains moderate-high because comparative fixture evidence and recommendation logic must be convincing enough to prevent `MTA-13` solver drift.

### Contested Drivers
- Whether hosted validation is needed remains conditional. The plan now distinguishes terrain-domain solver proof from SketchUp-hosted runtime proof, so hosted validation should not be assumed unless the evaluation depends on transforms, persistence, output regeneration, public MCP orchestration, performance, or visual/runtime quality.
- Functional scope remains `2` despite P0 importance because this task produces solver guidance, not shipped public behavior.
- Technical surface remains `2` only if prototype code stays in test/support and does not become runtime implementation.
- Discovery risk remains `3`: the base/detail candidate is much more concrete after challenge, but fixture results may still show v1 `heightmap_grid` is inadequate or that constrained optimization must be deferred.

### Missing Evidence
- No fixture results yet prove the base/detail candidate preserves detail while satisfying survey residuals.
- No parameter matrix has yet selected default low-pass, core/blend, or threshold guidance.
- No implementation evidence yet proves the small least-squares correction is enough for nearby or repeated survey points.
- No hosted evidence exists, but the finalized plan accepts that gap only for `MTA-14` solver evaluation and explicitly carries hosted validation to `MTA-13`.

### Recommendation
- Keep predicted scores unchanged.
- Proceed with implementation under the finalized plan.
- Treat `summary.md`, solver pseudocode, fixture result tables, threshold guidance, no-public-contract-drift checks, and the explicit SketchUp proof boundary as closeout gates.

### Challenge Notes
- No predicted score changes are justified after premortem. The plan corrections reduced ambiguity but did not materially shrink the implementation or validation burden because the task still must produce robust comparative solver evidence.
- The challenged estimate and finalized plan now agree: `MTA-14` can prove terrain-domain solver behavior, but `MTA-13` must still prove public SketchUp-hosted runtime behavior.
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
| Functional Scope | 2 | Delivered the intended solver-selection evidence, recommendation package, and task conclusion for `MTA-13`; no public terrain edit behavior shipped. |
| Technical Change Surface | 2 | Changes stayed in test/support evaluation code, terrain-focused tests, task artifacts, and summary documentation; runtime registration, storage, dispatcher, loader, and public tool contracts were untouched. |
| Actual Implementation Friction | 2 | The planned base/detail solver, metrics, refusals, repeated-workflow evaluation, and parameter matrix were implemented without needing broader constrained optimization or production promotion. |
| Actual Validation Burden | 3 | Closeout required focused terrain tests, neighboring regression coverage, full Ruby test suite, lint, code review, a fix loop, live SketchUp Ruby smoke validation, and special-scene visual proof on small and larger terrain surfaces. |
| Actual Dependency Drag | 1 | Existing `HeightmapState`, control evaluation, region influence, and sample-window helpers were sufficient; SketchUp connectivity enabled extra proof but did not block implementation. |
| Actual Discovery Encountered | 3 | Implementation and review exposed concrete preserve-zone overlap handling, threshold/refusal semantics, and large-surface metric nuance; these were resolved or carried explicitly into the `MTA-13` handoff. |
| Actual Scope Volatility | 2 | Scope grew from deterministic fixture proof into live Ruby and visual scene proof at user request, but it did not expand into public MCP implementation or production runtime changes. |
| Actual Rework | 2 | Rework was contained to plan specificity, RuboCop cleanup, test-shell-out removal, preserve-zone post-correction refusal logic, and summary/conclusion updates. |
| Final Confidence in Completeness | 4 | The task now has deterministic regression coverage, full-suite/lint proof, review findings addressed, hosted Ruby smoke evidence, visual terrain artifacts, and an explicit production handoff boundary for `MTA-13`. |

### Actual Notes
- The prediction correctly identified solver/math specificity and comparative validation as the dominant work.
- Actual implementation friction landed below prediction because the minimum-norm correction and base/detail decomposition were enough; no broader optimization engine was needed.
- Actual validation stayed at the predicted moderate-high level, but the proof mix expanded to include live SketchUp Ruby evaluation and visual inspection geometry.
<!-- SIZE:ACTUAL:END -->

---

<!-- SIZE:VALIDATION-EVIDENCE:START -->
## Validation Evidence Summary

| Mode | Evidence | Outcome |
|---|---|---|
| Focused terrain regression | `bundle exec ruby -Itest test/terrain/survey_correction_evaluation_test.rb` | 12 runs, 66 assertions, 0 failures, 0 errors, 0 skips. |
| Neighboring terrain/contract regression | Terrain and related contract suite | 45 runs, 258 assertions, 0 failures, 0 errors, 0 skips. |
| Full Ruby regression | `bundle exec rake ruby:test` | 768 runs, 3714 assertions, 0 failures, 0 errors, 36 skips. |
| Ruby lint | `RUBOCOP_CACHE_ROOT=tmp/.rubocop_cache bundle exec rake ruby:lint` | 195 files inspected, no offenses. |
| Code review | Grok/PAL review pass after implementation | One high finding and two lower findings addressed; final review found no remaining blockers. |
| Hosted SketchUp smoke | `ruby_eval` against connected SketchUp scene using the repository test harness | Solver ran in SketchUp Ruby 3.2.2 / SketchUp 26.1.189 and returned the same recommendation shape. |
| Visual scene proof | Ruby-created original, minimum-change, base/detail, and larger offset terrain groups left in-scene | Visual inspection artifacts were generated several hundred meters to the side, including a standalone original for comparison. |
| Package verification | Not run | No extension loader, packaging, public MCP contract, or runtime registration behavior changed. |

### Validation Burden Classification
- Observed burden was a moderate-high regression plus special-scene hosted smoke closeout.
- There was one meaningful review-driven fix loop for preserve-zone overlap handling; no repeated test-blocker loop or package/runtime deployment issue occurred.
- Live validation increased confidence in algorithm portability to SketchUp Ruby, but public MCP/persistence/undo/output validation remains intentionally owned by `MTA-13`.
<!-- SIZE:VALIDATION-EVIDENCE:END -->

---

<!-- SIZE:DELTA:START -->
## Estimation Delta Review

### Prediction vs Actual

| Dimension | Predicted | Actual | Delta |
|---|---:|---:|---|
| Functional Scope | 2 | 2 | As predicted: solver recommendation, not shipped user-facing behavior. |
| Technical Change Surface | 2 | 2 | As predicted: test/support and task artifacts only. |
| Implementation Friction | 3 | 2 | Slightly overestimated: no broad constrained optimization or production extraction was required. |
| Validation Burden | 3 | 3 | Accurate: comparative fixtures, full regression/lint, review, and hosted smoke made validation non-trivial. |
| Dependency / Coordination | 2 | 1 | Overestimated: existing terrain helpers were enough and SketchUp connectivity was available for extra proof. |
| Discovery / Ambiguity | 3 | 3 | Accurate: preserve-zone overlap, threshold semantics, and large-surface metric interpretation all required concrete decisions. |
| Scope Volatility | 2 | 2 | Accurate: live visual proof expanded validation shape but not implementation scope. |
| Rework | 2 | 2 | Accurate: review and lint/test refinements were contained. |
| Confidence | 3 | 4 | Higher than predicted after clean regression, lint, review closure, hosted Ruby proof, and visual terrain artifacts. |

### What The Estimate Got Right
- The strongest risk was solver behavior and evidence quality, not public MCP contract drift.
- Keeping the prototype in `test/support` was sufficient for MTA-14 and created a clear promotion path for `MTA-13`.
- `summary.md` was the correct closeout artifact because the business value was a solver recommendation with explicit proof boundaries.

### What Changed In Practice
- The largest validation addition was live SketchUp `ruby_eval` plus scene geometry for visual inspection. This was useful proof, but it did not make MTA-14 responsible for public command behavior.
- Code review found a real edge case: survey corrections that satisfy threshold checks can still violate preserve-zone overlap after solving. That became a post-correction refusal check and regression test.
- The larger terrain fixture showed that base/detail is selected for detail preservation and controlled spread, not because every proxy metric always strictly dominates minimum-change behavior.

### Future Retrieval Lesson
- Use this task as an analog for validation-heavy terrain-domain solver-selection spikes where production code is deferred but prototype logic should be promotable.
- Score hosted proof separately from implementation friction: live Ruby and visual artifacts can increase validation burden without expanding public runtime surface.
- For `MTA-13`, reuse as much algorithm structure as possible by promoting the harness logic into production terrain-domain services, while adding the public MCP, target resolution, persistence, undo, and output-regeneration proof that MTA-14 intentionally excluded.
<!-- SIZE:DELTA:END -->

---

<!-- SIZE:TAGS:START -->
## Retrieval Tags

- `archetype:validation-heavy`
- `scope:managed-terrain`
- `systems:terrain-state`
- `systems:terrain-kernel`
- `systems:test-support`
- `systems:docs`
- `validation:regression`
- `validation:docs-check`
- `validation:hosted-smoke`
- `host:routine-smoke`
- `host:special-scene`
- `contract:no-public-shape-change`
- `risk:performance-scaling`
- `risk:regression-breadth`
- `risk:review-rework`
- `volatility:medium`
- `friction:medium`
- `rework:medium`
- `confidence:high`
<!-- SIZE:TAGS:END -->
