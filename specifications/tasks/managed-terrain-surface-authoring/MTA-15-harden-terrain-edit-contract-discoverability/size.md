# Size: MTA-15 Harden Terrain Edit Contract Discoverability

**Task ID**: `MTA-15`
**Title**: Harden Terrain Edit Contract Discoverability
**Status**: calibrated
**Created**: 2026-04-28
**Last Updated**: 2026-04-29

**Related Task**: [task.md](./task.md)
**Related Plan**: [plan.md](./plan.md)
**Related Summary**: [summary.md](./summary.md)

---

<!-- SIZE:IDENTITY:START -->
## Identity

- **Task Archetype**: archetype:docs-specs
- **Primary Scope Area**: scope:managed-terrain
- **Likely Systems Touched**:
  - systems:loader-schema
  - systems:public-contract
  - systems:docs
  - systems:native-contract-fixtures
  - systems:surface-sampling
  - systems:measurement-service
- **Validation Modes**: validation:contract, validation:docs-check
- **Likely Analog Class**: terrain-public-contract-discoverability-hardening

### Identity Notes
- This task is a P0 public contract and docs hardening slice. It should not change terrain solver behavior, but it likely touches runtime tool descriptions, field descriptions, docs, and contract tests.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 2 | Improves baseline-safe public use of existing tools without adding new terrain behavior. |
| Technical Change Surface | 2 | Likely spans native loader descriptions, reference docs, and loader/contract tests, but not command execution or terrain state. |
| Hidden Complexity Suspicion | 2 | The main hidden risk is keeping concise tool descriptions accurate without overpromising unsupported planar or diagnostic behavior. |
| Validation Burden Suspicion | 2 | Needs contract and docs checks; no hosted terrain validation should be needed unless descriptions reveal runtime drift. |
| Dependency / Coordination Suspicion | 2 | Depends on shipped MTA/STI/SVR surfaces and now anchors MTA-16 plus the PLAT-18 terrain prompt recipes. |
| Scope Volatility Suspicion | 2 | Could expand if discoverability review finds runtime descriptions and docs diverge more broadly than the terrain signal identified. |
| Confidence | 3 | Task boundary is well supported by the signal, PRD/HLD updates, and existing public contract guidance. |

### Early Signals
- The task explicitly excludes solver changes, public tool renames, MCP prompts/resources implementation, and validation verdicts.
- The server currently exposes tools/descriptions/schemas, so baseline-safe semantics must be discoverable there.
- Existing evidence fields already exist; the gap is primarily interpretation and discoverability.
- Analog `PLAT-17` suggests public contract work can widen through docs/schema/runtime parity checks, but this task is terrain-scoped.

### Early Estimate Notes
- Seed treats MTA-15 as the core first iteration task for contract discoverability, not a terrain-kernel implementation.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

> Filled during task planning. This is the main pre-implementation estimate.

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | 1 | Public discoverability improves for existing terrain tools, but no user-facing runtime behavior, request shape, response shape, solver behavior, or new workflow is added. |
| Technical Change Surface | 2 | Expected changes span native loader descriptions, `docs/mcp-tool-reference.md`, README review, and existing tests/lint as applicable; command execution, terrain state, dispatcher, and SketchUp behavior stay untouched. |
| Implementation Friction Risk | 1 | Work should be straightforward prose and documentation hardening in established files; the main friction is concise wording that avoids unsupported planar or validation implications. |
| Validation Burden Risk | 1 | Validation is planned as focused existing schema/docs tests, Ruby lint for changed Ruby files, `git diff --check`, and review checklist confirmation; no hosted SketchUp, package, migration, or performance validation is expected. |
| Dependency / Coordination Risk | 1 | Relies on completed `MTA-13`, `MTA-14`, `STI-03`, and `SVR-04` behavior plus existing specs, but no external coordination or upstream implementation is needed. |
| Discovery / Ambiguity Risk | 1 | The signal, task, and Grok review align on scope; remaining ambiguity is tactical wording rather than architecture or behavior. |
| Scope Volatility Risk | 1 | Scope is explicitly bounded to descriptive contract hardening and docs; richer examples, refusal UX, prompts/resources, and planar/profile follow-ons are deferred. |
| Rework Risk | 1 | Review may revisit wording, but no structural rework is expected because tests will not lock exact prose and runtime behavior remains unchanged. |
| Confidence | 3 | Confidence is strong because related work is completed, the task has a draft plan, analogs were reviewed, and the user confirmed the test/docs posture; exact implementation wording remains intentionally unsettled. |

### Top Assumptions

- Implementation keeps the task descriptive only and does not touch request validation, refusal payloads, command behavior, terrain solvers, or response serialization.
- `README.md` does not contain stale terrain tool guidance requiring broader docs updates; if it does, edits remain minor.
- Existing loader/schema tests are sufficient for durable structure, and wording quality can be governed by review checklist rather than brittle prose assertions.
- `docs/mcp-tool-reference.md` can carry the compact safe recipe/review guidance without becoming a rich workflow playbook.

### Estimate Breakers

- Implementation discovers current descriptions are generated into fixtures or downstream contract artifacts that require broad fixture churn or exact text stabilization.
- Review decides actionable refusal text, richer examples, or future planar/monotonic recipes must be included in this task rather than deferred.
- Any runtime behavior changes are needed to make the descriptions truthful, triggering command tests or hosted validation.
- README or other public docs contain extensive stale terrain guidance requiring broader documentation cleanup.

### Predicted Signals

- The draft plan explicitly records no request, response, enum, dispatcher, command, terrain-state, or SketchUp behavior changes.
- User direction reduced automated wording checks to existing structural tests and review criteria, lowering validation and rework risk.
- `PLAT-17` is a useful outside-view warning for contract drift, but it is broader and behavior-changing compared with this terrain-scoped description hardening task.
- `MTA-01` shows docs/spec-only terrain work can remain low validation when public runtime behavior is unchanged.
- `SVR-04` is a caution that terrain profile behavior changes can become validation-heavy, but `MTA-15` avoids behavior changes.

### Predicted Estimate Notes

- Predicted profile is lower than the seed suspicion because Step 05 narrowed the validation strategy away from prose-locking tests and confirmed there are no structural public contract deltas.
- The dominant risk is not implementation complexity; it is review quality around wording that must teach the terrain signal without overclaiming unsupported behavior.
<!-- SIZE:PREDICTED:END -->

---

<!-- SIZE:CHALLENGE:START -->
## Challenge Review

> Filled when the estimate is pressure-tested through external review, premortem, or controlled consensus.

### Agreed Drivers

- Functional scope remains low because the task improves discoverability of existing tools without adding behavior, request/response shape, modes, or new workflows.
- Technical change surface remains moderate-low: native loader descriptions, MCP reference docs, README review, and existing tests/lint as applicable.
- Validation burden remains low because the finalized plan deliberately avoids prose-locking tests and hosted SketchUp validation unless behavior changes accidentally.
- The closest broad analog, `PLAT-17`, is useful mainly as a contract-drift warning; it does not justify a higher score because `MTA-15` avoids behavior removal, response shape changes, and external client matrices.
- Premortem found no unresolved Tigers.

### Contested Drivers

- Review quality replaces automated semantic assertion coverage. This keeps validation and rework low, but leaves wording quality dependent on disciplined implementation closeout.
- Docs/runtime drift is not prevented by exact parity tests. The plan accepts manual same-change review instead of brittle text matching.
- Actionable refusal UX remains a real product pressure from the signal, but it is outside this task because it would change runtime behavior or payload wording.

### Missing Evidence

- Final implementation wording is intentionally not fixed at planning time.
- README terrain guidance has only been searched at planning time; implementation should search again and either confirm no stale text exists or update it.
- No hosted/runtime validation evidence is expected or required unless implementation changes behavior.

### Recommendation

- Confirm the predicted profile. Do not resize, split, or add hosted validation.
- Preserve the low validation/rework estimate only if implementation follows the plan guardrails: no behavior changes, no refusal payload changes, no prose-locking tests, and recorded semantic review in closeout notes.

### Challenge Notes

- Premortem converted the main validation concern into a carried validation item: implementation closeout must state that changed descriptions and docs were reviewed against the semantic obligations and forbidden implications.
- No predicted-score changes are justified. The challenge reinforces the current boundary rather than expanding it.
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
| Functional Scope | 1 | Improved discoverability for existing terrain tools and docs without adding runtime behavior, request shape, response shape, modes, or workflow enforcement. |
| Technical Change Surface | 2 | Touched native loader descriptions and MCP reference docs, with README review and existing contract tests; no command, dispatcher, solver, storage, packaging, or hosted runtime surface changed. |
| Actual Implementation Friction | 0 | Implementation followed the finalized plan cleanly. No structural rework, hidden coupling, or runtime change was needed. |
| Actual Validation Burden | 1 | Validation stayed lightweight and non-hosted: focused loader/public-contract/native-contract tests, Ruby lint, diff whitespace check, README search, semantic review, and final PAL/Grok review. |
| Actual Dependency Drag | 1 | Required reading completed MTA/STI/SVR context and preserving existing ownership boundaries, but no upstream coordination or blocked dependency affected execution. |
| Actual Discovery Encountered | 1 | README review and contract-text investigation confirmed the expected scope; no unexpected docs/runtime drift was found. |
| Actual Scope Volatility | 0 | Scope stayed descriptive-only and did not expand into refusal UX, prompts/resources, planar fit behavior, or runtime validation. |
| Actual Rework | 0 | Final code review found no issues and no follow-up implementation changes were required. |
| Final Confidence in Completeness | 3 | Strong completion confidence from passing structural tests, lint, docs/runtime review, and external code review; confidence is not 4 because semantic wording quality remains review-governed rather than prose-locked by tests by design. |

### Actual Notes
- Dominant actual failure mode: none observed; the main accepted residual risk remains future docs/runtime contract drift from review-governed wording.
- No material implementation drift was recorded.
- Hosted SketchUp validation was not needed because this task changed static descriptions and docs only.
<!-- SIZE:ACTUAL:END -->

---

<!-- SIZE:VALIDATION-EVIDENCE:START -->
## Validation Evidence Summary

> Fill only the sections that are relevant. Say `not applicable` where needed.

### Automated Validation
- `bundle exec ruby -Itest test/runtime/native/mcp_runtime_loader_test.rb`
  - 46 runs, 396 assertions, 0 failures, 0 errors, 6 skips.
- `bundle exec ruby -Itest test/runtime/public_mcp_contract_posture_test.rb`
  - 5 runs, 36 assertions, 0 failures, 0 errors, 0 skips.
- `bundle exec ruby -Itest test/runtime/native/mcp_runtime_native_contract_test.rb`
  - 25 runs, 2 assertions, 0 failures, 0 errors, 24 skips.
- `bundle exec rubocop --cache false src/su_mcp/runtime/native/mcp_runtime_loader.rb`
  - 1 file inspected, no offenses detected.
- `git diff --check -- src/su_mcp/runtime/native/mcp_runtime_loader.rb docs/mcp-tool-reference.md specifications/tasks/managed-terrain-surface-authoring/MTA-15-harden-terrain-edit-contract-discoverability/{task.md,size.md,summary.md}`
  - clean for MTA-15 changed paths.

### Hosted / Manual Validation
- Hosted SketchUp validation was not run and was not required: no command behavior, solver, dispatcher, request/response shape, storage, generated geometry, undo behavior, or live runtime integration changed.
- Manual semantic review confirmed changed loader descriptions and docs satisfy the MTA-15 semantic obligations and avoid forbidden implications around planar fitting, best-fit replacement, monotonic correction, boundary-preserving patch behavior, preview/dry-run, and validation verdicts.
- README search found only broad terrain capability bullets and no stale terrain-edit guidance requiring update.

### Performance Validation
- Not applicable; no executable runtime path or algorithm changed.

### Migration / Compatibility Validation
- No migration required; public tool names, request schemas, response schemas, finite option sets, routing, and refusal payloads are unchanged.

### Operational / Rollout Validation
- Static contract/docs rollout only. Package verification was not run because extension registration, packaging, vendored runtime, and behavior surfaces were not changed.

### Validation Notes
- Final Step 10 `mcp__pal__codereview` with `model: "grok-4.20"` completed with no findings. The review confirmed the change is description/docs-only, keeps architecture boundaries intact, and introduces no security or performance surface.
- Full-worktree `git diff --check` is currently blocked by unrelated trailing whitespace in `specifications/tasks/platform/PLAT-18-implement-initial-mcp-prompts-guidance-surface/size.md`.
<!-- SIZE:VALIDATION-EVIDENCE:END -->

---

<!-- SIZE:DELTA:START -->
## Estimation Delta Review

> Filled during final calibration. Compare prediction to actual behavior.

### Prediction Accuracy
- The predicted profile was accurate: this stayed a low-friction, descriptive contract hardening task with moderate-low technical surface and lightweight validation.
- The planned avoidance of prose-locking tests held; existing structural tests were enough because no public shape changed.

### Underestimated
- Nothing material. The only extra cleanup was removal of a corrupted untracked local file before validation; it did not affect task scope or implementation shape.

### Overestimated
- Rework risk was slightly overestimated. The prediction allowed for wording review churn, but final code review found no required changes.

### Early-Visible Signals
- The task and plan explicitly excluded solver, request/response, routing, prompt/resource, and refusal payload changes.
- Existing structural tests already covered the durable contract shape and finite options.
- The accepted residual risk was wording quality by review rather than exact prose tests.

### Future Retrieval Notes
- Use this as an analog for docs/specs public contract hardening when the implementation changes loader descriptions and docs but intentionally keeps runtime behavior and schema shape unchanged.
- Retrieval facets: `archetype:docs-specs`, `scope:managed-terrain`, `systems:loader-schema`, `systems:public-contract`, `systems:docs`, `contract:no-public-shape-change`, `validation:contract`, `validation:docs-check`, `host:not-needed`, `risk:contract-drift`.
- Dominant actual failure mode: none during implementation; future risk is later contract drift if runtime descriptions and docs are edited separately.
<!-- SIZE:DELTA:END -->

---

<!-- SIZE:TAGS:START -->
## Retrieval Tags

- `archetype:docs-specs`
- `scope:managed-terrain`
- `scope:docs-specs`
- `systems:loader-schema`
- `systems:public-contract`
- `systems:docs`
- `systems:native-contract-fixtures`
- `systems:surface-sampling`
- `systems:measurement-service`
- `validation:contract`
- `validation:docs-check`
- `host:not-needed`
- `contract:public-tool`
- `contract:loader-schema`
- `contract:no-public-shape-change`
- `contract:docs-examples`
- `risk:contract-drift`
- `volatility:low`
- `friction:low`
- `rework:low`
- `confidence:high`
<!-- SIZE:TAGS:END -->
