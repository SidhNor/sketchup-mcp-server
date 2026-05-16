# Size: MTA-26 Add Managed Terrain Brush Overlay Feedback

**Task ID**: `MTA-26`  
**Title**: `Add Managed Terrain Brush Overlay Feedback`  
**Status**: `calibrated`  
**Created**: `2026-05-08`  
**Last Updated**: `2026-05-08`  

**Related Task**: [task.md](./task.md)  
**Related Plan**: [plan.md](./plan.md)  
**Related Summary**: [summary.md](./summary.md)  

---

<!-- SIZE:IDENTITY:START -->
## Identity

- **Task Archetype**: `archetype:feature`
- **Primary Scope Area**: `scope:managed-terrain`
- **Likely Systems Touched**:
  - `unclassified:sketchup-ui`
  - `systems:command-layer`
  - `systems:target-resolution`
  - `systems:terrain-state`
  - `systems:terrain-repository`
  - `systems:test-support`
- **Validation Modes**: `validation:hosted-smoke`, `validation:regression`
- **Likely Analog Class**: SketchUp terrain tool overlay refinement over existing managed edit command

### Identity Notes
- This task extends the MTA-18 toolbar/dialog/tool loop with transient viewport feedback for the existing target-height brush. It should not add terrain edit math, public contract changes, or new edit modes.
- Planning rebaseline: the overlay must follow varied terrain height using cached managed terrain state, so terrain-state/repository read behavior and performance risk are now material retrieval drivers.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 2 | Adds visible brush feedback to one existing UI tool without changing supported edit modes. |
| Technical Change Surface | 3 | Likely touches SketchUp tool draw/hover lifecycle, UI state, coordinate conversion, cached terrain-state preview, status feedback, and tests. |
| Hidden Complexity Suspicion | 3 | Host draw timing, view invalidation, transform semantics, terrain-following Z, cache invalidation, and valid/invalid hover targeting can hide live-only issues. |
| Validation Burden Suspicion | 3 | Local seams can check state, but real overlay behavior needs SketchUp-hosted smoke for visibility, pick behavior, z-fighting, cleanup, and non-mutation checks. |
| Dependency / Coordination Suspicion | 2 | Depends on MTA-18 and existing target-height command behavior; no new public contract or solver dependency is planned. |
| Scope Volatility Suspicion | 2 | Scope is narrow, but overlay foundation may attract future-tool abstraction pressure if not held to target height. |
| Confidence | 2 | Requirements are clear, but MTA-18 showed host UI behavior can require live fix loops. |

### Early Signals
- MTA-18 actuals showed toolbar/dialog/tool lifecycle risks and repeated live patching around SketchUp host behavior.
- The task deliberately keeps mutation behavior unchanged and adds only transient feedback.
- The overlay must prove the brush radius and falloff cue without creating persistent model geometry.
- The overlay must sample cached managed terrain state for varied-height Z without reloading or scanning faces on every mouse move.
- Transform, selected-terrain semantics, and real viewport visibility remain likely validation pressure points.

### Early Estimate Notes
- Strongest analog is calibrated MTA-18. Use it for host UI lifecycle and validation shape, not for terrain math or public contract risk.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

| Dimension | Predicted (0-4) | Notes |
|---|---:|---|
| Functional Scope | 2 | One existing SketchUp UI tool gains pre-apply viewport feedback, validity feedback, and settings redraw behavior without new edit modes or public contracts. |
| Technical Change Surface | 3 | Touches tool callbacks/draw/extents, dialog invalidation, selected-terrain/coordinate seams, read-only terrain-state cache/sampling, and focused UI tests. |
| Implementation Friction Risk | 3 | SketchUp host callbacks, cached repository state, terrain-following Z, transform/unit parity, and lifecycle cleanup are likely to resist a purely local implementation. |
| Validation Burden Risk | 3 | Local tests are straightforward, but real draw visibility, z-fighting, `InputPoint#pick`, cleanup, and settings redraw require hosted smoke and may repeat MTA-18-style fix loops. |
| Dependency / Coordination Risk | 2 | Depends on implemented MTA-18/MTA-12/MTA-04 seams and hosted SketchUp access, but no new public contract, solver, or cross-team dependency is planned. |
| Discovery / Ambiguity Risk | 2 | Major design choices are resolved, but visual constants, boundary rendering, real pick behavior, and selected-owner targeting remain live-host questions. |
| Scope Volatility Risk | 2 | Scope is narrow, but MTA-27 reuse pressure and possible hosted targeting surprises could expand the overlay helper or targeting model if not controlled. |
| Rework Risk | 3 | Viewport visibility, z-offset, invalid-state styling, settings invalidation, and cache refresh are likely areas for local rework after hosted smoke. |
| Confidence | 2 | Plan is concrete and analog-backed, but confidence stays moderate because the hardest behavior is SketchUp-hosted viewport feedback. |

### Top Assumptions

- Circular `target_height` apply semantics from MTA-12 remain unchanged and do not require command/schema edits.
- Cached `HeightmapState` bilinear sampling over a bounded ring segment count is cheap enough for interactive hover.
- Selected-owner targeting is acceptable for MTA-26; hovered-entity targeting can wait unless hosted smoke proves it misleading.
- SketchUp `Tool#draw`, `View#invalidate`, and `getExtents` are sufficient for readable transient rings without persistent geometry.
- Hosted SketchUp validation access is available before closeout.

### Estimate Breakers

- Repository state must be reloaded or generated mesh faces must be scanned on every mouse move to get usable Z placement.
- Real SketchUp draw behavior cannot make terrain-following rings visible without asset/material rendering or persistent geometry.
- Selection-only targeting proves misleading enough that hovered/nested entity resolution must be implemented in MTA-26.
- Terrain owner transforms expose coordinate assumptions that require changing command/request semantics.
- Settings dialog lifecycle cannot reliably refresh the active tool without restructuring the MTA-18 UI wiring.

### Predicted Signals

- Strong analog: MTA-18 showed SketchUp toolbar/dialog/tool lifecycle risk and repeated hosted fix loops.
- Supporting analogs: MTA-12 removes terrain-region math risk; MTA-04 confirms owner-local public-meter coordinate semantics.
- New planning driver: terrain-following Z turns the overlay into a read-only terrain-state sampling problem, not only a flat drawing problem.
- No public contract delta reduces schema/dispatcher/docs risk.
- Hosted smoke remains the dominant proof boundary because local fakes cannot prove viewport draw order, z-fighting, or real `InputPoint#pick`.

### Predicted Estimate Notes

- Prediction is rebaselined from the initial seed to include cached terrain-state/repository preview and performance risk discovered during refinement.
- Scores intentionally keep functional scope moderate while raising implementation, validation, and rework risk around host-sensitive drawing behavior.
<!-- SIZE:PREDICTED:END -->

---

<!-- SIZE:CHALLENGE:START -->
## Challenge Review

### Agreed Drivers

- Functional scope remains moderate: one existing SketchUp UI tool gains
  transient overlay feedback without new edit modes or public contract changes.
- Technical surface remains high enough for score `3`: the plan touches host
  tool callbacks, view drawing/extents, dialog invalidation, selected-terrain
  resolution, terrain-state/repository preview, and tests.
- Implementation and validation risk remain score `3` because real SketchUp
  viewport behavior, z-fighting, pick behavior, and lifecycle cleanup cannot be
  closed by local fakes.
- Rework risk remains score `3`: external review highlighted likely tuning and
  lifecycle/cache refresh loops, matching MTA-18 analog lessons.

### Contested Drivers

- Hover cache risk was refined, not resized. User review correctly noted that
  existing profile/path-drape sampling already uses a prepare-once/sample-many
  pattern. The plan now uses that as the model while keeping managed
  `HeightmapState` as the authoritative cache source.
- Hosted transformed-owner validation is still a possible burden driver. The
  finalized plan requires hosted non-zero-origin/transformed coverage or an
  explicit recorded validation gap with local transform parity.
- Invalid-hover UX remains intentionally bounded: status is mandatory, disabled
  ring drawing is limited to picked/settings-valid invalid states.

### Missing Evidence

- Hosted evidence that `Tool#draw`, visual offset, and `getExtents` produce
  readable rings without clipping or z-fighting.
- Hosted evidence that selected-owner targeting plus real `InputPoint#pick`
  stays aligned with generated terrain geometry.
- Implementation evidence that post-apply cache dirtying prevents stale overlay
  Z on the next hover.

### Recommendation

- Confirm the predicted profile with no score revisions.
- Do not split the task before implementation.
- Treat hosted viewport smoke and cache/lifecycle tests as required closeout
  gates; record transformed-hosted coverage as a gap if it cannot be run.

### Challenge Notes

- Grok 4.3 premortem review found material plan gaps around lifecycle cleanup,
  transformed/non-zero-origin validation, invalid-hover specificity, and
  post-apply cache refresh. These were incorporated into `plan.md`.
- Public-contract drift controls were judged sufficient; no estimate increase is
  needed for schema/dispatcher/docs work.
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

| Dimension | Actual (0-4) | Notes |
|---|---:|---|
| Functional Scope | 2 | Shipped the planned overlay refinement for one existing Target Height Brush workflow: support radius, falloff cue, validity/status handling, transient cleanup, and preserved click apply. No new edit modes or public contracts were added. |
| Technical Change Surface | 3 | Touched SketchUp tool callbacks, dialog/installer lifecycle, session preview context, coordinate conversion, terrain-state sampling, repository cache behavior, tests, package staging, and task artifacts. |
| Actual Implementation Friction | 3 | Core design followed the plan, but TDD/review exposed important details around granular skeletons, reverse coordinate conversion, explicit bounds checks, loaded-only cache semantics, no-view cleanup invalidation, and hosted color visibility. |
| Actual Validation Burden | 2 | Validation followed normal repo closeout: focused coverage, full Ruby regression, lint, package verification, external review, and live SketchUp smoke. The support-ring color tweak was a quick contained `eval_ruby` confirmation loop. |
| Actual Dependency Drag | 2 | Relied on MTA-18 UI/session seams, existing managed terrain state/repository behavior, SketchUp live validation access, and user live smoke. No external service, new solver, or public contract dependency appeared. |
| Actual Discovery Encountered | 2 | Main discoveries were local and bounded: existing bilinear stencil clamps out-of-bounds, reverse draw conversion was missing, invalid/refused loads should not be cached, no-view close cleanup needed last-view invalidation, and green was weak over terrain. |
| Actual Scope Volatility | 1 | Scope stayed target-height-only. The support-ring color changed from green to cyan for visibility, but no shared panel, new edit mode, or broader targeting model was pulled in. |
| Actual Rework | 1 | Follow-up was quick and contained: review/self-review tightened cache, cleanup, and contract guard details, and live smoke caused one tactical color patch. No completed slice needed meaningful rework. |
| Final Confidence in Completeness | 4 | Automated validation, package verification, review closure, live SketchUp confirmation, transformed-owner hosted smoke, and live invalid-settings verification support completion. |
<!-- SIZE:ACTUAL:END -->

---

<!-- SIZE:VALIDATION-EVIDENCE:START -->
## Validation Evidence Summary

- **Focused MTA-26 tests**: `70 runs, 212 assertions, 0 failures, 0 errors, 0 skips`.
- **Full Ruby regression**: `1123 runs, 11236 assertions, 0 failures, 0 errors, 37 skips`.
- **Ruby lint**: full lint passed with `283 files inspected, no offenses detected`; targeted changed-file lint also passed.
- **Package verification**: `bundle exec rake package:verify` passed and produced `dist/su_mcp-1.5.0.rbz`.
- **Code review**: Step 10 `grok-4.3` review completed. Review found no remaining implementation defects after self-review fixes; follow-up strengthened plan and contract guard artifacts.
- **Hosted/live SketchUp smoke**: user deployed and verified live in SketchUp. Overlay and edits worked; support ring color was changed from green to cyan after live visibility feedback and monkey-patched through `eval_ruby` for confirmation.
- **Transformed-owner hosted smoke**: passed after closeout follow-up. A separate managed terrain smoke object with a non-identity owner transform resolved preview center `(2.0, 2.0)`, generated support radius `1.0` and falloff radius `1.5`, and verified the first transformed support point with `0.0` internal-unit error.
- **Invalid-settings hosted smoke**: passed. Setting brush radius to `-1` in live SketchUp prevented terrain edit apply; no edit was received.
- **Validation gaps**: no remaining MTA-26 hosted validation gaps are recorded. Repository absent/refused and out-of-bounds branches remain local-test coverage because they are targeted state/setup failures rather than routine live editing paths.
<!-- SIZE:VALIDATION-EVIDENCE:END -->

---

<!-- SIZE:DELTA:START -->
## Estimation Delta Review

| Dimension | Predicted | Actual | Delta Notes |
|---|---:|---:|---|
| Functional Scope | 2 | 2 | Accurate. The task stayed scoped to one existing SketchUp brush tool and did not add edit modes or public contracts. |
| Technical Change Surface | 3 | 3 | Accurate. The implementation touched the planned tool/dialog/session/terrain-state/test surfaces. |
| Implementation Friction | 3 | 3 | Accurate. The hard parts were the predicted host-sensitive and cache/coordinate seams, plus a few concrete implementation details found by TDD/review. |
| Validation Burden | 3 | 2 | Overestimated. Review, package verification, live smoke, and the quick visual tuning loop are normal closeout under the current repo baseline. |
| Dependency / Coordination | 2 | 2 | Accurate. Existing seams and live SketchUp access were enough; no new external dependency appeared. |
| Discovery / Ambiguity | 2 | 2 | Accurate. Most uncertainty was resolved by planned TDD and hosted smoke rather than forcing major design change. |
| Scope Volatility | 2 | 1 | Overestimated. Cyan support-ring tuning changed presentation, not task scope. |
| Rework | 3 | 1 | Overestimated. Review and live smoke caused bounded follow-up, not meaningful revisiting of completed slices. |
| Confidence | 2 | 4 | Final confidence improved after regression, lint, package, review, live SketchUp confirmation, transformed-owner hosted smoke, and live invalid-settings verification. |

### Calibration Notes

- The prediction correctly weighted SketchUp viewport visibility and lifecycle
  cleanup as risk drivers, but over-scored normal closeout follow-up as rework/validation burden.
- The largest under-specified planning detail was not task size, but TDD queue
  granularity: sampler bounds, reverse draw conversion, repository absent/refused
  states, and no-view cleanup needed explicit skeletons.
- Hosted visual tuning was predictable as a risk class but not in the exact
  color choice: green support rings competed with terrain materials, cyan was
  clearer.
- Future analogs should retrieve this task for SketchUp `Tool#draw` overlays,
  read-only managed-state previews, loaded-only cache behavior, and live visual
  tuning over terrain materials.
<!-- SIZE:DELTA:END -->

---

<!-- SIZE:TAGS:START -->
## Retrieval Tags

- `archetype:feature`
- `scope:managed-terrain`
- `unclassified:sketchup-ui`
- `systems:command-layer`
- `systems:target-resolution`
- `systems:terrain-state`
- `systems:terrain-repository`
- `validation:hosted-smoke`
- `host:routine-smoke`
- `contract:no-public-shape-change`
- `risk:host-api-mismatch`
- `risk:transform-semantics`
- `risk:visibility-semantics`
- `risk:performance-scaling`
- `risk:cache-invalidation`
- `friction:medium`
- `rework:low`
- `confidence:high`
<!-- SIZE:TAGS:END -->
