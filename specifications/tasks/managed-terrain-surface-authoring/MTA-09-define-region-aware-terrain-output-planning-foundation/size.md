# Size: MTA-09 Define Region-Aware Terrain Output Planning Foundation

**Task ID**: `MTA-09`
**Title**: Define Region-Aware Terrain Output Planning Foundation
**Status**: `calibrated`
**Created**: 2026-04-26
**Last Updated**: 2026-04-26

**Related Task**: [task.md](./task.md)
**Related Plan**: [plan.md](./plan.md)
**Related Summary**: [summary.md](./summary.md)

---

<!-- SIZE:IDENTITY:START -->
## Identity

- **Task Archetype**: platform
- **Primary Scope Area**: terrain output planning and dirty-window handoff
- **Likely Systems Touched**:
  - terrain output planning
  - `SampleWindow` integration
  - terrain edit diagnostics
  - output contract stability tests
  - terrain mesh generation fallback behavior
- **Validation Class**: regression-heavy / contract-sensitive
- **Likely Analog Class**: terrain output seam foundation

### Identity Notes
- Foundation task that makes dirty-window intent explicit without implementing partial SketchUp mesh replacement or persisted schema changes.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 2 | Mostly internal platform behavior, but it shapes how future edit kernels and output regeneration interact. |
| Technical Change Surface | 3 | Likely touches output planning, edit diagnostics, tests, and mesh generation boundaries. |
| Hidden Complexity Suspicion | 3 | Risk is creating fake partial regeneration or leaking internal windows into public evidence/persistence. |
| Validation Burden Suspicion | 3 | Needs contract/no-drift tests plus regression coverage for full-output fallback and kernel handoff behavior. |
| Dependency / Coordination Suspicion | 3 | Depends on MTA-07 primitives, benefits from MTA-08 output baseline, and informs MTA-05/MTA-06/MTA-10. |
| Scope Volatility Suspicion | 3 | Can expand if it starts owning partial output, chunk ownership, or public evidence evolution. |
| Confidence | 3 | The boundary is clear after MTA-07 and Grok review, but exact output-plan shape remains planning-time work. |

### Early Signals
- `SampleWindow` exists and is already integrated into bounded-grade changed-region diagnostics.
- MTA-05 planning expects `CorridorFrame` to compose with `SampleWindow`, not replace it.
- Public evidence vocabulary and persisted `heightmap_grid` v1 must remain stable.
- Grok review warned not to merge this foundation with partial regeneration.

### Early Estimate Notes
- Seed treats this as a deliberate output-planning seam task with moderate functional scope and high split-pressure risk if partial regeneration is pulled in.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | 2 | Adds an internal output-planning capability that shapes future terrain output behavior, but intentionally avoids public MCP changes, persisted schema changes, and actual partial regeneration. |
| Technical Change Surface | 2 | Planned code surface is several related terrain areas: `TerrainOutputPlan`, edit command orchestration, generator regeneration signature, diagnostics/evidence no-leak tests, and contract stability coverage. Loader, dispatcher, repository schema, and docs examples should not move. |
| Implementation Friction Risk | 2 | The core primitives already exist from MTA-07 and MTA-08 has now landed the production builder-backed full-grid generator shape. Remaining friction is adapting plan handoff without blurring diagnostics, planning, and output mutation ownership. |
| Validation Burden Risk | 3 | The task is contract-sensitive: it needs unit, command, generator regression, serializer/no-leak, and evidence stability checks. Hosted validation is conditional rather than dominant if output mutation remains unchanged. |
| Dependency / Coordination Risk | 1 | MTA-08 is now completed and validated, so the main sequencing dependency is resolved. Remaining dependency risk is limited to preserving the landed output seam and ordinary validation tooling. |
| Discovery / Ambiguity Risk | 1 | Major design choices are resolved and MTA-08 clarified the generator baseline. Remaining ambiguity is limited to whether existing diagnostics are sufficient to construct the internal plan cleanly. |
| Scope Volatility Risk | 2 | The plan has clear non-goals, but terrain output work has recurring split pressure toward partial regeneration, chunk ownership, or public strategy diagnostics. Tests and wording must keep this preparatory. |
| Rework Risk | 2 | Rework should be limited if public no-leak checks lead the implementation. Risk rises if `changedRegion`, optional `sampleWindow`, and output-plan intent diverge or if MTA-08 changes the regeneration seam unexpectedly. |
| Confidence | 4 | Confidence is very strong because MTA-07 landed the key primitives, MTA-05 shows `SampleWindow` reuse works, and MTA-08 has now validated the production full-grid bulk output baseline. |

### Top Assumptions

- MTA-08 has landed and provides production full-grid bulk regeneration behind the existing terrain output boundary.
- `TerrainOutputPlan` can be extended to carry dirty-window intent without changing the public `derivedMesh` summary.
- Existing edit diagnostics, or a private diagnostics addition, can supply affected-region intent without exposing `SampleWindow` publicly.
- `TerrainMeshGenerator` can accept an optional plan while keeping all SketchUp mutation behavior full-grid and internally owned.
- Evidence builders remain whitelist-shaped and do not serialize internal diagnostics wholesale.

### Estimate Breakers

- The landed MTA-08 generator interface makes plan handoff broader than a small optional keyword or equivalent seam.
- Dirty-window intent cannot be derived reliably from current edit diagnostics without changing edit-kernel behavior more broadly.
- Contract tests reveal internal diagnostics are already leaking through public responses or persisted state in a way that requires wider serializer/evidence refactoring.
- Implementation starts adding partial replacement, chunk ownership, or public strategy output to make the seam feel useful.
- Accepting an output plan changes SketchUp output mutation behavior enough to require hosted validation comparable to MTA-08.
- MTA-09 accidentally reintroduces public output strategy fields that MTA-08 removed.

### Predicted Signals

- MTA-07 actuals show terrain output seam work can be implemented cleanly when scoped, but validation burden stays high around public no-drift and output behavior.
- MTA-07 already provided `SampleWindow`, `TerrainOutputPlan.full_grid`, and no-leak contract tests, lowering implementation discovery.
- MTA-08 completed and validated production builder-backed full-grid output, removed public regeneration-strategy leakage, and preserved derived markers, normals, undo, unsupported-child refusal, and unmanaged-scene safety.
- MTA-05 actuals show `SampleWindow` composes well with edit kernels, while public contract expansion is the real surface multiplier; MTA-09 avoids that expansion.
- MTA-03 and MTA-04 actuals show hosted SketchUp behavior invalidates fakes when output mutation changes; MTA-09 avoids mutation changes and gates hosted smoke only on that condition.
- The finalized draft plan rejects public diagnostics, partial regeneration, persisted schema changes, loader/schema updates, and docs/example changes.

### Predicted Estimate Notes

- This prediction was updated after MTA-08 completed and validated the full-grid bulk output baseline.
- The predicted profile treats MTA-09 as a preparatory internal seam task, not as a user-visible output optimization or partial regeneration feature.
- Validation burden is the highest score because the work is mostly about proving boundaries did not leak or drift.
- The seed shape remains valid after refinement and MTA-08 completion; the main estimate change is lower dependency/discovery risk and higher confidence.
<!-- SIZE:PREDICTED:END -->

---

<!-- SIZE:CHALLENGE:START -->
## Challenge Review

### Agreed Drivers

- Functional Scope remains `2`: MTA-09 is an internal platform seam, not a public MCP feature, output optimization, or partial-regeneration implementation.
- Technical Change Surface remains `2`: the planned surface spans related terrain internals and tests, while loader schema, dispatcher, repository payloads, README examples, and public contract fixtures should not change except for no-drift assertions.
- Implementation Friction Risk remains `2`: MTA-07 reduced the unknowns by landing `SampleWindow` and `TerrainOutputPlan.full_grid`, and MTA-08 now provides the production builder-backed generator baseline. The remaining friction is preserving that seam while adding plan handoff.
- Validation Burden Risk remains `3`: public no-leak, persistence stability, command handoff, and generator-regression tests are mandatory even though hosted validation is conditional.
- Scope Volatility Risk remains `2`: the premortem reinforced the guardrail against partial regeneration, chunk ownership, and public diagnostics rather than revealing a need to split.
- Dependency / Coordination Risk drops from `2` to `1`: MTA-08 is now completed and validated, resolving the primary sequencing dependency.
- Discovery / Ambiguity Risk drops from `2` to `1`: MTA-08 clarified the generator baseline and public output vocabulary.
- Confidence rises from `3` to `4`: the major prior uncertainty, MTA-08 output baseline validity, is now validated through local and live checks.

### Contested Drivers

- Technical Change Surface could be argued as `3` because command orchestration, generator signature, diagnostics, and contract tests all move. The challenge keeps it at `2` because the surfaces are tightly related terrain internals and public/runtime registration layers are explicitly excluded.
- Validation Burden Risk could be argued as `2` because no public contract or hosted mutation change is intended. The challenge keeps it at `3` because the success condition is mostly no-drift/no-leak proof across state, evidence, command, and generator tests.
- Dependency / Coordination Risk could still rise if the MTA-09 implementation needs broader generator changes than planned. The challenge keeps the revised score at `1` because MTA-08 itself is no longer pending.
- Rework Risk could rise if implementation adds private `sampleWindow` diagnostics and evidence serialization is broader than expected. The challenge keeps it at `2` because no-leak tests are required before broad wiring.

### Missing Evidence

- Proof that command orchestration can construct the dirty-window plan from current diagnostics without broad kernel changes.
- Test evidence that internal planning vocabulary does not leak into public edit responses or persisted `heightmap_grid` v1 payloads.
- Confirmation during implementation that accepting an output plan does not alter SketchUp mutation behavior and therefore does not require full hosted validation.
- Test evidence that MTA-09 does not reintroduce the public regeneration/strategy vocabulary removed by MTA-08.

### Recommendation

- Confirm the predicted profile with revised dependency, discovery, and confidence scores after MTA-08 validation.
- Proceed to implementation on top of the completed MTA-08 builder-backed full-grid baseline.
- Do not split before implementation.
- Thread the optional plan through the shared `generate`/`regenerate` path so `regenerate` does not accept a plan that is ignored when it delegates to `generate`.
- Stop and replan only if the completed MTA-08 generator seam cannot accept the internal plan without changing output strategy, public contract, or SketchUp mutation behavior.

### Challenge Notes

- The premortem produced no unresolved Tigers.
- MTA-08 completion removed the primary sequencing uncertainty and added one concrete guardrail: do not reintroduce public regeneration/strategy output fields removed by MTA-08.
- No external model challenge was used; the user explicitly characterized this as straightforward preparatory work and the remaining risks are already bounded by plan guardrails and tests.
- Predicted Dependency / Coordination Risk changed `2 -> 1`, Discovery / Ambiguity Risk changed `2 -> 1`, and Confidence changed `3 -> 4` after MTA-08 validation evidence was reviewed.
<!-- SIZE:CHALLENGE:END -->

---

<!-- SIZE:DRIFT:START -->
## Drift Log

No material drift recorded yet.
<!-- SIZE:DRIFT:END -->

---

<!-- SIZE:ACTUAL:START -->
## Actual Profile

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | 2 | Delivered the planned internal output-planning seam: full-grid and dirty-window intent, command handoff, and generator plan threading. No public tool behavior or partial regeneration shipped. |
| Technical Change Surface | 2 | Touched several related terrain internals and tests: output plan, command orchestration, mesh generator seam, evidence/contract no-leak coverage, and test support. Loader, dispatcher, request schemas, repository schema, and docs examples did not move. |
| Actual Implementation Friction | 1 | Implementation followed the planned dependency order. Friction was limited to review-driven queue refinement, RuboCop cleanup, and making the public `operation.regeneration` distinction explicit. |
| Actual Validation Burden | 3 | Validation remained the main cost: focused terrain tests, full terrain and full Ruby suites, lint, package verification, `grok-4.20` review, hosted create/edit/undo checks, 100x100 performance baseline, and greybox tracing. The matrix was clean and did not require fix/redeploy/retest loops. |
| Actual Dependency Drag | 1 | MTA-08 was already deployed as the baseline. Live validation needed the user to deploy the initial MTA-09 functional changes once, but no additional redeploy was needed for later comment/test-support followups. |
| Actual Discovery Encountered | 1 | Discovery was small. The main clarification was that public `operation.regeneration: "full"` remains an operation recap while `output.*` strategy/planning fields stay forbidden. |
| Actual Scope Volatility | 1 | Scope stayed within the internal seam. A larger 100x100 performance check and greybox trace were added as validation evidence, not as feature scope expansion. |
| Actual Rework | 1 | Rework was limited to adding review-requested tests/comments/shared fixtures and lint cleanup. No production redesign or behavioral reversal occurred. |
| Final Confidence in Completeness | 4 | Confidence is high after local tests, lint, package verification, code review, hosted smoke, hosted performance baseline, undo check, and greybox proof that real edit orchestration passes a dirty-window plan into regeneration. |

### Actual Notes

- The deployed hosted validation used the initial functional implementation. Later review followups were comments, test-support sharing, and local test assertions only; those were not redeployed.
- The task did not implement partial regeneration. It intentionally confirmed that dirty-window intent reaches the output boundary while execution remains full-grid.
- The hosted 100x100 baseline showed why MTA-10 matters: a 9-sample dirty edit still regenerated 19,602 faces.
<!-- SIZE:ACTUAL:END -->

---

<!-- SIZE:VALIDATION-EVIDENCE:START -->
## Validation Evidence Summary

- Focused MTA-09 suite: `40 runs, 279 assertions, 0 failures, 0 errors, 0 skips`.
- Full terrain suite: `117 runs, 1101 assertions, 0 failures, 0 errors, 2 skips`.
- Full Ruby suite: `699 runs, 3255 assertions, 0 failures, 0 errors, 35 skips`.
- RuboCop: `186 files inspected, no offenses detected`.
- Package verification: `bundle exec rake package:verify` produced `dist/su_mcp-0.22.0.rbz`.
- `git diff --check`: passed.
- `mcp__pal__.codereview` with `grok-4.20`: completed with no critical or high findings; followups addressed through comments, shared private-diagnostics test support, and explicit no-leak/public-vocabulary assertions.
- Hosted small terrain smoke on `MTA-09-live-region-plan-20260426`: create 5x4, target-height edit, corridor edit, derived marker inspection, normals inspection, v1 persistence/no-leak inspection, undo check, and runtime pings passed.
- Hosted performance baseline on `MTA-09-live-perf-100x100-20260426`: create 100x100 produced 10,000 vertices / 19,602 faces in about `0.56s`; small bounded edit with 121 affected samples regenerated full-grid output in about `2.18s`; later 9-sample edit also regenerated 19,602 faces as expected.
- Hosted greybox seam check: a temporary tracer around `TerrainMeshGenerator#regenerate` captured a real MCP edit passing `TerrainOutputPlan` with `intent: :dirty_window`, `execution_strategy: :full_grid`, matching changed-region window `{ column: 40..42, row: 40..42 }`, dirty sample count `9`, and summary matching the regeneration result. Trace recording was disabled after evidence capture.
<!-- SIZE:VALIDATION-EVIDENCE:END -->

---

<!-- SIZE:DELTA:START -->
## Estimation Delta Review

### Prediction Accuracy

- Functional scope, technical change surface, dependency drag, discovery, scope volatility, and confidence were directionally accurate.
- Validation burden was correctly predicted as the dominant driver, even though hosted validation ran cleanly and required no fix/redeploy/retest loop.
- Implementation friction and rework were slightly overestimated; the seam integrated cleanly once tests led the work.

### Most Underestimated Dimension

- None materially by score. The main underweighted signal was not task difficulty but task granularity: this slice was so small and preparatory that it did not prove partial-regeneration value by itself.

### Most Overestimated Dimension

- Implementation friction and rework. The plan handoff, generator keyword threading, and changed-region-to-window construction were straightforward after MTA-07 and MTA-08.

### Dominant Actual Failure Mode

- Risk of over-slicing platform prep work. MTA-09 was valid as an internal seam, but its value is mostly realized only when paired with MTA-10 partial regeneration.

### Iteration-Planning Guidance

- The user strongly disliked this task shape: too small, too preparatory, and not materially proving enough on its own.
- The same concern was raised for MTA-08. In hindsight, MTA-08 and MTA-09 could likely have been bundled with MTA-10 into a single larger task or tightly coupled implementation packet.
- Future iteration planning should avoid splitting work into multiple thin preparatory tasks when the intermediate state does not prove material product or performance value independently.
- Prefer bundling the output execution change, internal planning seam, and performance proof when the preparatory seam is low-friction and the main value depends on the next task.

### Early Signals To Weight More Heavily Next Time

- If a task explicitly says “foundation,” “preparatory,” and “does not implement the performance behavior,” challenge whether it should be merged into the task that does implement the behavior.
- If acceptance depends on proving a boundary for a next task, require either a greybox proof that the next task can consume it or bundle the next task into the same iteration slice.
- Hosted performance evidence is useful, but it should support a material behavior change rather than only confirm why the next task matters.

### Future Retrieval Facets

- `scope:managed-terrain`
- `systems:terrain-output`
- `systems:terrain-mesh-generator`
- `systems:command-layer`
- `validation:contract`
- `validation:hosted-smoke`
- `validation:performance`
- `host:routine-smoke`
- `host:undo`
- `host:performance`
- `contract:no-public-shape-change`
- `risk:performance-scaling`
- `risk:contract-drift`
- `risk:review-rework`
<!-- SIZE:DELTA:END -->

---

<!-- SIZE:TAGS:START -->
## Retrieval Tags

- `archetype:platform`
- `scope:managed-terrain`
- `systems:command-layer`
- `systems:terrain-output`
- `systems:terrain-mesh-generator`
- `systems:test-support`
- `validation:contract`
- `validation:hosted-smoke`
- `validation:performance`
- `host:routine-smoke`
- `host:undo`
- `host:performance`
- `contract:no-public-shape-change`
- `risk:performance-scaling`
- `risk:contract-drift`
- `risk:review-rework`
- `volatility:low`
- `friction:low`
- `rework:low`
- `confidence:high`
<!-- SIZE:TAGS:END -->
