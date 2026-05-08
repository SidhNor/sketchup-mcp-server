# Size: PLAT-19 Restructure Managed Terrain Support Tree

**Task ID**: `PLAT-19`  
**Title**: Restructure Managed Terrain Support Tree  
**Status**: calibrated  
**Created**: 2026-05-08  
**Last Updated**: 2026-05-08  

**Related Task**: [task.md](./task.md)  
**Related Plan**: [plan.md](./plan.md)  
**Related Summary**: [summary.md](./summary.md)  

---

<!-- SIZE:IDENTITY:START -->
## Identity

- **Task Archetype**: `archetype:refactor`
- **Primary Scope Area**: `scope:managed-terrain`
- **Likely Systems Touched**:
  - `systems:command-layer`
  - `systems:runtime-dispatch`
  - `systems:public-contract`
  - `systems:terrain-state`
  - `systems:terrain-storage`
  - `systems:terrain-repository`
  - `systems:terrain-kernel`
  - `systems:terrain-output`
  - `systems:terrain-mesh-generator`
  - `systems:test-support`
  - `systems:packaging`
- **Validation Modes**: `validation:contract`, `validation:compatibility`, `validation:regression`
- **Likely Analog Class**: mechanical capability-internal support-tree restructuring

### Identity Notes
- This is a platform-scoped structural task applied to the managed terrain capability. The
  intended implementation shape is mechanical file movement and load-path/test alignment, not
  terrain behavior redesign.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 0 | No user-visible terrain behavior or public MCP contract change is intended. |
| Technical Change Surface | 3 | Likely touches many terrain files plus runtime requires, tests, and package loadability. |
| Hidden Complexity Suspicion | 3 | Load-order, relative require paths, test mirrors, and in-progress terrain work may hide coupling. |
| Validation Burden Suspicion | 3 | Needs terrain slice regression, public contract/load proof, and package verification despite no behavior change. |
| Dependency / Coordination Suspicion | 2 | Depends on PLAT-12 posture and must avoid disrupting active terrain/MTA work in the worktree. |
| Scope Volatility Suspicion | 2 | Scope is bounded as mechanical, but folder-boundary decisions may reveal a need to split follow-up cleanup. |
| Confidence | 2 | Task boundary is clear, but exact touch count and active terrain changes reduce early confidence. |

### Early Signals
- The task explicitly excludes public MCP contract changes, class/module renames for aesthetics, and terrain behavior redesign.
- `src/su_mcp/terrain/` currently mixes command, contract, state, storage, edit, output, evidence, and probe concerns in one flat folder.
- Runtime integration points are known: native tool catalog requires, command factory assembly, tool dispatcher routing, terrain tests, and package staging.
- The worktree already contains active terrain-related changes, so the restructuring must preserve unrelated edits and avoid broad semantic cleanup.

### Early Estimate Notes
- Treat this as a broad mechanical refactor with low functional scope but moderate technical and validation surface. A later technical plan should decide move batches and the exact validation slice before producing a predicted estimate.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

> Filled during task planning. This is the main pre-implementation estimate.

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | 0 | No public MCP, terrain behavior, UI behavior, storage, or output semantics change is intended. |
| Technical Change Surface | 3 | Broad terrain source/test movement plus runtime catalog/factory requires, test support, package tests, and normative docs. |
| Implementation Friction Risk | 2 | Mostly mechanical, but relative path churn and active terrain files create moderate load-order/path risk. |
| Validation Burden Risk | 3 | Needs recursive terrain tests, focused command/contract checks, runtime catalog/dispatch/factory tests, package verification, and lint. |
| Dependency / Coordination Risk | 2 | Depends on platform/HLD guidance and must avoid disrupting active worktree changes; no external team dependency. |
| Discovery / Ambiguity Risk | 1 | Folder taxonomy, test placement, docs scope, and require strategy are resolved; only tactical file-placement checks remain. |
| Scope Volatility Risk | 1 | Scope is bounded as mechanical; volatility mainly comes from newly present terrain files or discovered stale normative docs. |
| Rework Risk | 2 | Missed require paths or misplaced cross-cutting tests may require rebatching moves, but no semantic redesign is expected. |
| Confidence | 3 | Draft plan is concrete and risks are known; confidence is not 4 because there is no exact calibrated analog and the terrain tree is active. |

### Top Assumptions
- Implementation remains a structural move plus direct `require_relative` rewrites.
- Public contracts, command response shapes, Ruby constants, storage behavior, output behavior, and UI behavior remain unchanged.
- Existing terrain/runtime/package tests cover the load and contract seams well enough for a mechanical move.
- Historical completed task artifacts are intentionally left unchanged; only normative docs are swept.

### Estimate Breakers
- A real external consumer requires old terrain root file paths and cannot be updated directly.
- Implementation discovers load-order coupling that requires compatibility shims or behavior changes.
- Package or UI asset path behavior changes beyond direct require/path updates.
- Active terrain files change materially during implementation and invalidate the frozen move map.

### Predicted Signals
- Terrain has many top-level files spanning multiple ownership categories.
- Runtime integration points are narrow and known.
- Test tree must move with source and includes cross-cutting tests needing explicit homes.
- Package staging copies the support tree recursively, reducing packaging-code risk.
- No direct calibrated size analog exists; `PLAT-12` is useful only as a support-tree restructuring analog.

### Predicted Estimate Notes
- Predict this as low functional scope, high technical surface, and high validation burden. The
  hard part is proving nothing changed after broad file movement, not designing new behavior.
- Planning rebaseline after refinement confirmed the task shape: terrain-specific folders,
  mirrored source-owned tests, explicit cross-cutting test areas, direct require rewrites, zero
  public contract delta, and normative-doc-only drift updates.
<!-- SIZE:PREDICTED:END -->

---

<!-- SIZE:CHALLENGE:START -->
## Challenge Review

> Filled when the estimate is pressure-tested through external review, premortem, or controlled consensus.

### Agreed Drivers
- Low functional scope is agreed: the task remains a mechanical restructuring with no intended
  public contract or behavior delta.
- Broad technical surface is agreed: many terrain source/test files move, plus runtime requires,
  test support, package tests, and normative docs may be touched.
- High validation burden is agreed: the proof is that broad movement did not change behavior,
  runtime contracts, package loadability, or UI asset paths.
- Moderate implementation/rework risk is agreed: missed `require_relative` paths, active terrain
  files, and cross-cutting test placement are the main likely sources of iteration.

### Contested Drivers
- Hosted SketchUp validation is not part of the expected validation path for the in-scope
  mechanical refactor. It becomes relevant only if implementation escapes scope into host-facing
  behavior such as UI install, package asset behavior, generated output, undo, storage, or command
  semantics.
- The premortem raised whether validation burden should exceed 3 because of load-path breadth. The
  score stays 3 because the added pre-move require audit, root file count check, UI asset audit, and
  package/runtime tests make the burden high but bounded.

### Missing Evidence
- No exact calibrated analog exists for a capability-internal terrain folder split of this size.
- The final live move map and full require audit cannot be known until implementation starts.
- Hosted SketchUp smoke evidence is not expected for the in-scope refactor; any need for it would
  signal scope escape or a separate behavior change.

### Recommendation
- Confirm the predicted profile without score changes. Do not split the task before
  implementation; instead, enforce the premortem guardrails and split only if implementation
  discovers behavior changes, compatibility shims, or host-facing behavior changes beyond the
  mechanical move.

### Challenge Notes
- External premortem critique identified real guardrail gaps rather than a different task shape.
  The plan was updated with a pre-move require audit, explicit terrain-root top-level Ruby check,
  UI asset path audit, scope-escape handling for host-facing changes, and batch load checks. Those
  additions support the current validation burden and rework scores rather than requiring a resize.
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
| Functional Scope | 0 | No behavior-visible, public MCP, storage, output, UI, or response-shape change shipped. |
| Technical Change Surface | 3 | Moved the broad terrain source and test tree plus runtime catalog/factory, UI require handoff, test support, and fixture path references. |
| Actual Implementation Friction | 1 | The mechanical move followed the plan; friction was limited to path recalculation, one failed `rg` pattern, and path-only cleanup. |
| Actual Validation Burden | 3 | Correctness required a broad terrain/runtime/package/lint matrix despite clean execution and no hosted smoke. |
| Actual Dependency Drag | 1 | No external dependency or upstream blocker appeared; only existing dirty worktree awareness had to be preserved. |
| Actual Discovery Encountered | 1 | Discovery was limited to stale fixture/test path references and review-requested checklist explicitness. |
| Actual Scope Volatility | 0 | Scope stayed a mechanical support-tree restructure with no behavior or public contract expansion. |
| Actual Rework | 1 | Minor cleanup after the first move updated path-only references; no rebatching, compatibility shim, or semantic rework was needed. |
| Final Confidence in Completeness | 4 | Structural, terrain, runtime, package, lint, stale-path, and external codereview evidence all passed with no remaining findings. |

### Actual Signals
- 100 terrain source/test files were moved into explicit ownership folders.
- A temporary structural guard failed before the move and passed after the move,
  then was removed so folder taxonomy checks do not become permanent policy.
- Recursive terrain tests, focused command/contract tests, runtime integration tests, package verification, and RuboCop passed.
- `mcp__pal__codereview` with `grok-4.3` found no issues on the completed change set.
- Hosted SketchUp validation was not needed for the in-scope mechanical move.

### Actual Notes
- The prediction was directionally accurate: low functional scope, broad technical touch surface, and high validation burden. Actual implementation friction and rework were lower than the risk profile because the move map and direct require rewrite strategy held.
<!-- SIZE:ACTUAL:END -->

---

<!-- SIZE:VALIDATION-EVIDENCE:START -->
## Validation Evidence Summary

> Fill only the sections that are relevant. Say `not applicable` where needed.

### Automated Validation
- Passed structural guard, recursive terrain suite, focused terrain contract and command tests, runtime dispatcher/factory/native contract tests, package stage builder test, `bundle exec rake package:verify`, RuboCop over the touched Ruby surface, and stale flat-path sweeps.

### Hosted / Manual Validation
- Not applicable. Hosted SketchUp smoke was skipped because the task stayed within mechanical file moves and `require_relative` rewrites, with no command, UI, storage, output, undo, package layout, or public contract behavior changed.

### Performance Validation
- Not applicable.

### Migration / Compatibility Validation
- Passed through runtime load/contract tests, command factory and dispatcher tests, package verification, and stale-path sweeps. No compatibility root loaders were required.

### Operational / Rollout Validation
- Package verification passed and produced `dist/su_mcp-1.4.0.rbz`.

### Validation Notes
- Validation was a clean routine matrix with no fix/redeploy/restart/rerun loop. The only post-move cleanup was updating path-only fixture/test references caught by the stale-path sweep.
<!-- SIZE:VALIDATION-EVIDENCE:END -->

---

<!-- SIZE:DELTA:START -->
## Estimation Delta Review

> Filled during final calibration. Compare prediction to actual behavior.

- **Most Underestimated Dimension**: none; validation breadth and technical surface were predicted accurately.
- **Most Overestimated Dimension**: implementation friction and rework; direct require rewriting and the live move map avoided the expected load-order and rebatching problems.
- **Signal Present Early But Underweighted**: path-like metadata outside Ruby requires, such as fixture validation command strings, can drift during structural moves even when code loads cleanly.
- **Genuinely Unknowable Factor**: none identified; the final live move map was unknown before implementation, but it stayed within predicted shape.
- **Future Similar Tasks Should Assume**: add a structural guard before moving files, run a stale-path sweep for code and non-code path references, and keep hosted smoke out of scope when behavior remains mechanically unchanged and package/runtime validation passes.

### Calibration Notes
- Dominant actual failure mode was stale path/reference risk, not behavior coupling. Future capability-internal support-tree restructures should predict high validation burden but only low-to-moderate implementation friction when public constants remain stable and direct consumers can be updated in one change.
<!-- SIZE:DELTA:END -->

---

<!-- SIZE:TAGS:START -->
## Retrieval Tags

Use canonical values from the repo task-estimation taxonomy when present. Keep this as a compact analog-search index, not coverage. Target 8-14 tags.

- `archetype:refactor`
- `scope:platform`
- `scope:managed-terrain`
- `systems:runtime-dispatch`
- `systems:terrain-output`
- `systems:test-support`
- `systems:packaging`
- `validation:contract`
- `validation:compatibility`
- `validation:regression`
- `host:not-needed`
- `contract:no-public-shape-change`
- `risk:regression-breadth`
- `confidence:high`
<!-- SIZE:TAGS:END -->
