# Size: MTA-22 Capture Adaptive Simplification Benchmark Fixtures And Replay Framework

**Task ID**: `MTA-22`  
**Title**: Capture Adaptive Simplification Benchmark Fixtures And Replay Framework  
**Status**: `calibrated`  
**Created**: 2026-05-06  
**Last Updated**: 2026-05-06  

**Related Task**: [task.md](./task.md)  
**Related Plan**: [plan.md](./plan.md)  
**Related Summary**: [summary.md](./summary.md)  

---

<!-- SIZE:IDENTITY:START -->
## Identity

- **Task Archetype**: `archetype:test-infrastructure`
- **Primary Scope Area**: `scope:managed-terrain`
- **Likely Systems Touched**:
  - `systems:test-support`
  - `systems:terrain-output`
  - `systems:terrain-kernel`
- **Validation Modes**: `validation:regression`, `validation:hosted-smoke`
- **Likely Analog Class**: adaptive terrain benchmark fixture and replay framework

### Identity Notes
- This task is production-neutral fixture and replay infrastructure, but its coverage quality gates
  the usefulness of MTA-23 simplification evidence.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 1 | No production behavior changes; output is benchmark evidence and replay support. |
| Technical Change Surface | 2 | Likely spans fixture data, test support, local replay helpers, and terrain-output metric checks. |
| Hidden Complexity Suspicion | 3 | Under-represented fixtures would make MTA-23 evidence weak; hosted-sensitive cases need careful labeling. |
| Validation Burden Suspicion | 3 | Must prove fixture breadth, replayability, metric correctness, and hosted/provenance boundaries. |
| Dependency / Coordination Suspicion | 2 | Depends on MTA-21 evidence and live hosted checks where practical, but no public rollout. |
| Scope Volatility Suspicion | 2 | Existing uncommitted MTA-22 work may be salvageable but may need material fixture expansion. |
| Confidence | 2 | Direction is clear, but final fixture breadth is not yet replanned. |

### Early Signals
- MTA-19 failed after local confidence, so fixture breadth and hosted-sensitive classification matter.
- The previous MTA-22 implementation captured useful baseline cases, but the revised task requires
  broader benchmark relevance for MTA-23.
- MTA-21 is the accepted production baseline, not the target quality endpoint.

### Early Estimate Notes
- Treat this as fixture infrastructure with unusually high representativeness risk. The task should
  not grow into prototype selection or production backend work.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

> Filled during task planning. This is the main pre-implementation estimate.

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | 1 | No production behavior change; the outcome is fixture, baseline-result, and replay evidence for later MTA-23 comparison. |
| Technical Change Surface | 2 | Touches canonical fixture JSON, test-support loader, focused terrain tests, fixture docs, and contract-stability guards. |
| Implementation Friction Risk | 2 | Existing MTA-22 fixture work is reusable, but result-row extraction, coverage limitations, and local-vs-hosted authority need careful schema work. |
| Validation Burden Risk | 3 | Correctness depends on schema failure tests, coverage breadth, provenance boundaries, local replay labeling, contract stability, and production dependency guards. |
| Dependency / Coordination Risk | 2 | Depends on MTA-21 hosted/provenance evidence and MTA-20 edit-family context, but does not need public rollout or upstream code ownership changes. |
| Discovery / Ambiguity Risk | 2 | Major architecture choices are resolved; remaining uncertainty is fixture breadth and whether available evidence is enough for every named family. |
| Scope Volatility Risk | 2 | Coverage gaps may add cases or limitations, but the task is bounded away from candidate comparison and production backend work. |
| Rework Risk | 2 | Main rework risk is schema/data reshaping if baseline rows, fixture expectations, and local replay observations are initially conflated. |
| Confidence | 3 | Draft plan, existing fixture work, related analogs, and Grok review support the estimate; final breadth still depends on evidence quality. |

### Top Assumptions
- The existing uncommitted fixture pack is a valid base and can be evolved rather than replaced.
- MTA-21 summaries and hosted validation evidence are sufficient to populate baseline rows for
  current fixture cases, with provenance-backed limitations where needed.
- Missing practical edit-family evidence can be represented through machine-checkable
  `coverageLimitations` without invalidating MTA-22.
- No public MCP or production runtime contract changes are needed.

### Estimate Breakers
- Hosted/provenance evidence is insufficient to populate one credible baseline row per fixture case.
- Required edit-family coverage expands from limitations into new hosted capture requirements for
  many cases.
- Implementation discovers that local replay must become authoritative current-backend replay,
  pulling production command orchestration into the fixture framework.
- MTA-23 needs a materially richer result schema than compact metrics and named probes can support.

### Predicted Signals
- Existing fixture loader and tests already cover schema validation, provenance, local replay, and
  production dependency guards.
- Current local replay output diverges from hosted MTA-21 counts, so evidence-mode labeling is a
  real correctness boundary.
- MTA-19 and MTA-21 analogs show terrain simplification evidence is validation-heavy even when
  runtime behavior does not change.
- Grok-4.3 review supported compact result rows and coverage limitations while recommending one
  canonical JSON document to avoid fixture/result drift.

### Predicted Estimate Notes
- No exact calibrated analog exists for managed-terrain benchmark fixture/result infrastructure.
  Closest analogs are MTA-14 for validation-heavy test/support evaluation, MTA-21 for adaptive
  baseline evidence burden, MTA-19 for false-confidence failure modes, and MTA-10 for hosted
  output-validation risk.
- Validation is scored higher than implementation friction because the hard part is proving the
  benchmark is honest, compact, and reusable without overstating local replay evidence.
- This is a planning rebaseline of the earlier MTA-22 scope, not implementation drift.
<!-- SIZE:PREDICTED:END -->

---

<!-- SIZE:CHALLENGE:START -->
## Challenge Review

> Filled when the estimate is pressure-tested through external review, premortem, or controlled consensus.

### Agreed Drivers
- Functional scope remains low because the task is test/fixture infrastructure with no production
  behavior or public MCP contract change.
- Technical surface remains moderate: canonical fixture JSON, test-support loader, fixture tests,
  fixture docs, and contract/dependency guards.
- Validation burden remains the dominant driver because the benchmark must prove exact fixture/result
  coverage, compact source-truth boundaries, provenance/evidence-mode semantics, and coverage
  limitations.
- MTA-19/MTA-21 analogs support treating terrain simplification evidence as easy to overtrust when
  local replay diverges from hosted behavior.

### Contested Drivers
- Validation Burden Risk could become `2` if implementation only reshapes existing JSON and runs
  clean focused tests, but the premortem keeps it at `3` because coverage limitations and MTA-23 row
  reuse need non-routine interpretation.
- Discovery / Ambiguity Risk could rise if MTA-21 evidence cannot credibly populate a baseline row
  per case, but that is captured as an estimate breaker rather than a current score change.
- Scope Volatility Risk is bounded only if the team accepts structured coverage limitations instead
  of requiring hosted captures for every named edit family.

### Missing Evidence
- Exact final list of fixture cases and which named edit families are represented versus limitation-backed.
- Final baseline result row values and provenance details after moving MTA-21 evidence out of per-case
  expectations.
- Whether MTA-23 will later need additional compact metrics beyond the v1 result row shape.

### Recommendation
- Confirm the predicted profile without score changes.
- Keep implementation scoped to the finalized plan: one canonical JSON document, exact
  `cases`/`baselineResults` coverage, compact-only result rows, structured `coverageLimitations`,
  and no production runtime dependency.
- Revisit size only if estimate breakers occur, especially if hosted evidence must be newly captured
  for many cases or local replay must become authoritative current-backend replay.

### Challenge Notes
- Grok-4.3 challenged the initial separate-file result-set proposal and recommended one canonical
  JSON document with logical sections to avoid fixture/result drift; the plan adopted that.
- Premortem added guardrails for coverage limitations and result-row reuse but found no unresolved
  Tigers.
- No actual, drift, or challenge-driven score revisions were written.
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
| Functional Scope | 1 | Production-neutral fixture/result infrastructure; no user workflow or MCP runtime behavior changed. |
| Technical Change Surface | 2 | Touched canonical fixture JSON, test-support loader, fixture tests, fixture README, and task metadata. |
| Actual Implementation Friction | 2 | Schema reshaping and review-driven cleanup were contained, but required careful separation of recipe cases from result rows. |
| Actual Validation Burden | 2 | Validation followed normal repo closeout: focused fixture/contract tests, terrain slice, RuboCop, Grok review, and routine live SketchUp hosted smoke without repeated fix loops. |
| Actual Dependency Drag | 1 | Depended on accepted MTA-21 evidence and an existing SketchUp connection, but no upstream ownership or deployment blocked completion. |
| Actual Discovery Encountered | 2 | Implementation exposed stale case-level result paths and hosted path isolation, both handled without scope expansion. |
| Actual Scope Volatility | 1 | The finalized plan held; coverage gaps stayed as explicit limitations rather than new hosted capture scope. |
| Actual Rework | 2 | Grok found low-severity cleanup that required loader/test helper refactoring and one targeted validation consistency pass. |
| Final Confidence in Completeness | 4 | Automated validation, external review, and hosted smoke all passed with remaining limitations explicitly documented. |

### Actual Signals
- Canonical JSON ended with 9 recipe-first cases, 9 matching baseline rows, and 4 structured
  coverage limitations.
- Test helper and loader cleanup removed stale `expectations`, `residuals`, `expectedResiduals`,
  and `capturedBaseline` evidence paths from case documents.
- Hosted verification generated all 9 fixture cases in SketchUp to the side of existing geometry;
  all 32 original top-level entities remained present.
- Hosted verification reported `0` down faces and `0` non-manifold edges for every generated case.
- No production runtime, public MCP contract, dispatcher, schema catalog, or package behavior changed.

### Actual Notes
- The implementation matched the main predicted shape, but validation was baseline closeout rather
  than high burden. The largest real surprise was cleanup needed to keep the test loader from
  tolerating legacy case-level result evidence.
<!-- SIZE:ACTUAL:END -->

---

<!-- SIZE:VALIDATION-EVIDENCE:START -->
## Validation Evidence Summary

> Fill only the sections that are relevant. Say `not applicable` where needed.

### Automated Validation
- Focused fixture test:
  `bundle exec ruby -Itest test/terrain/adaptive_terrain_regression_fixture_test.rb`
  passed with `27 runs, 1768 assertions, 0 failures, 0 errors, 0 skips`.
- Terrain contract stability:
  `bundle exec ruby -Itest test/terrain/terrain_contract_stability_test.rb`
  passed with `7 runs, 389 assertions, 0 failures, 0 errors, 0 skips`.
- Full terrain slice:
  `bundle exec ruby -Itest -e 'Dir["test/terrain/**/*_test.rb"].sort.each { |path| load path }'`
  passed with `315 runs, 5104 assertions, 0 failures, 0 errors, 3 skips`.
- Targeted RuboCop:
  `bundle exec rubocop --cache false test/support test/terrain/adaptive_terrain_regression_fixture_test.rb`
  passed with `9 files inspected, no offenses detected`.
- JSON shape check confirmed 9 cases, 9 baseline result rows, 4 coverage limitation rows, and no
  case-level result evidence keys.

### Hosted / Manual Validation
- Live SketchUp hosted smoke ran after final Grok review follow-up.
- Generated parent group `MTA-22 fixture eval 20260506-094548` to the side of existing geometry.
- Original top-level preservation check passed: 32 original entities before, 32 still present after.
- All 9 fixture case groups generated through the production adaptive `TerrainMeshGenerator` path.
- All generated cases reported `0` down faces and `0` non-manifold edges.
- Hosted validation was a routine smoke with path-isolation adaptation, not a repeated
  fix/redeploy/restart loop.

### Performance Validation
- Not applicable. Result rows permit timing fields, but MTA-22 did not make timing a correctness
  or performance acceptance gate.

### Migration / Compatibility Validation
- Not applicable. No persisted terrain state migration, package metadata, or public runtime contract
  changed.

### Operational / Rollout Validation
- Not applicable. The change is test fixture infrastructure and requires no deployment or extension
  reinstall.

### Validation Notes
- Validation burden was high relative to functional scope because the task needed to prove evidence
  boundaries, not because hosted verification found runtime defects.
<!-- SIZE:VALIDATION-EVIDENCE:END -->

---

<!-- SIZE:DELTA:START -->
## Estimation Delta Review

> Filled during final calibration. Compare prediction to actual behavior.

- **Most Underestimated Dimension**: Actual Rework. The plan anticipated conflation risk, but Grok
  correctly found more stale case-level result-evidence paths than the final local pass had removed.
- **Most Overestimated Dimension**: Dependency / Coordination Drag. MTA-21 evidence and SketchUp
  access were available; no new external capture or deployment coordination was needed.
- **Signal Present Early But Underweighted**: Existing uncommitted fixture work came from a prior
  scope, so legacy helper behavior needed stricter cleanup than ordinary schema reshaping.
- **Genuinely Unknowable Factor**: The SketchUp Ruby process could not read WSL `/tmp` or repo paths,
  requiring in-process compact verifier chunks for hosted validation.
- **Future Similar Tasks Should Assume**: Benchmark fixture tasks with separate source recipes and
  result rows need explicit negative tests for stale evidence locations, plus hosted smoke that
  validates geometry can be generated without treating smoke counts as authoritative baseline rows.

### Calibration Notes
- Prediction was broadly accurate: functional scope low, technical surface moderate, validation
  burden high. The main calibration lesson is that validation-heavy fixture tasks can require
  review-driven data-shape cleanup even when production code is untouched.
<!-- SIZE:DELTA:END -->

---

<!-- SIZE:TAGS:START -->
## Retrieval Tags

- `archetype:test-infrastructure`
- `scope:managed-terrain`
- `systems:test-support`
- `systems:loader-schema`
- `systems:terrain-output`
- `systems:terrain-kernel`
- `validation:regression`
- `validation:contract`
- `validation:hosted-smoke`
- `host:routine-smoke`
- `contract:no-public-shape-change`
- `contract:loader-schema`
- `risk:schema-requiredness`
- `risk:regression-breadth`
- `risk:review-rework`
- `volatility:low`
- `friction:medium`
- `rework:medium`
- `confidence:high`
<!-- SIZE:TAGS:END -->
