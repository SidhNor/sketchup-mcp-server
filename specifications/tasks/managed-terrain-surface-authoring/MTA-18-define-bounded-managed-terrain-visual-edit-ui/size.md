# Size: MTA-18 Implement Minimal Bounded Managed Terrain Visual Edit UI

**Task ID**: `MTA-18`  
**Title**: Implement Minimal Bounded Managed Terrain Visual Edit UI  
**Status**: calibrated  
**Created**: 2026-05-07  
**Last Updated**: 2026-05-08  

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
  - `systems:scene-mutation`
  - `systems:terrain-state`
  - `systems:terrain-repository`
  - `systems:terrain-output`
  - `systems:target-resolution`
  - `systems:docs`
  - `systems:packaging`
  - `systems:test-support`
- **Validation Modes**: `validation:hosted-smoke`, `validation:undo`, `validation:docs-check`
- **Likely Analog Class**: SketchUp toolbar container plus toolbar-button/dialog/tool entrypoint over existing terrain command

### Identity Notes
- This task implements the initial `Managed Terrain` toolbar container and a minimal first SketchUp-facing toolbar-button/dialog/tool flow for one existing managed terrain edit mode. It should prove the UI-to-command boundary without adding new terrain math, custom region drawing, live preview overlays, a second terrain runtime, or raw generated-mesh source editing. `unclassified:sketchup-ui` is used because the repo taxonomy has no canonical system tag for native SketchUp toolbar, `HtmlDialog`, and `Sketchup::Tool` code.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 2 | Adds the initial `Managed Terrain` toolbar container plus a real user-facing SketchUp toolbar-button/dialog/tool workflow, but deliberately limits the first slice to one existing edit mode, one circular brush shape, and basic result/refusal feedback. |
| Technical Change Surface | 3 | Likely touches SketchUp toolbar/dialog/tool wiring, packaged SVG/dialog assets, selected-terrain resolution, command/use-case invocation, coordinate conversion, success/refusal presentation, docs, packaging checks, and focused tests without adding new terrain math. |
| Hidden Complexity Suspicion | 3 | The main risks are host UI callback lifecycle, toolbar active state, selected-entity assumptions, transformed owner coordinate conversion, undo coherence, and keeping UI apply behavior from bypassing managed terrain state. |
| Validation Burden Suspicion | 3 | Needs a local-first proof suite for controller/request/protocol/conversion/package behavior plus narrow SketchUp-hosted smoke for toolbar/dialog/tool lifecycle, real click/input-point integration, visible mutation/refusal, and undo. |
| Dependency / Coordination Suspicion | 2 | Depends on existing implemented circular `target_height` support, terrain selection/metadata seams, and access to a small SketchUp host smoke for UI lifecycle, but avoids new solver, representation, validation, or hardscape ownership. |
| Scope Volatility Suspicion | 2 | Scope is tighter than the original definition task, but host UI behavior and coordinate conversion may still force fallback or documented limits. |
| Confidence | 2 | HLD boundaries, chosen UI mechanism, and first edit mode are clear, but there is no completed repo analog for toolbar + `HtmlDialog` + `Sketchup::Tool` state and host API behavior still needs a narrow smoke check. |

### Early Signals
- The linked HLD explicitly allows bounded SketchUp UI controls but forbids a second terrain editor, raw TIN source mutation, and validation-policy ownership.
- The revised task requires the initial `Managed Terrain` toolbar container, one `Target Height Brush` toolbar button, one non-modal settings dialog, one click tool, and one existing managed terrain edit mode, not a broad visual grading workflow.
- Durable apply behavior must remain routed through managed terrain state and command/use-case behavior or an equivalent managed service path.
- Toolbar icons are packaged SVG assets, so package verification joins docs, local UI seam tests, and hosted smoke as a seed-level validation signal.
- The selected managed terrain owner remains authoritative for the first slice; click-to-region conversion must be proven locally against the owner-local public-meter coordinate frame before hosted smoke checks real InputPoint/view integration.
- Follow-up MCP sampling, profile measurement, validation, labels, redrape, and capture workflows remain separate handoff consumers rather than UI-owned responsibilities.
- The strongest analogs are prior terrain edit implementation tasks for command/evidence/hosted validation shape plus platform menu-control work for SketchUp UI entrypoints; no direct analog exists yet for a full toolbar/dialog/tool terrain UI flow.

### Early Estimate Notes
- Seed treats MTA-18 as a bounded feature implementation task over existing terrain edit behavior. Risk is concentrated in SketchUp UI lifecycle, selected-owner coordinate conversion, asset packaging, and command-boundary integration, not terrain math or public MCP request-shape expansion. Most proof should be local; hosted smoke remains a narrow host API integration check.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

> Filled during task planning. This is the main pre-implementation estimate.

| Dimension | Prediction (0-4) | Rationale |
|---|---:|---|
| Functional Scope | 2 | Adds a real SketchUp-facing workflow, but the plan holds scope to one toolbar container, one toolbar-button/menu entry, one non-modal dialog, one circular brush shape, and one existing `target_height` edit mode. |
| Technical Change Surface | 3 | Touches new SketchUp UI support code, packaged assets, dialog protocol, tool activation/click handling, selected-terrain resolution, coordinate conversion, command request construction, docs, package verification, and tests. It should not touch public MCP contracts or terrain edit math. |
| Implementation Friction Risk | 3 | Main friction is new host UI lifecycle code, dialog callback readiness/reopen handling, active toolbar validation state, and owner-local/public-meter click conversion. Local-first seams reduce but do not remove that risk. |
| Validation Burden Risk | 3 | Requires focused local proof across session, dialog protocol, resolver, coordinate math, command-boundary invocation, packaging, and a narrow SketchUp-hosted smoke for toolbar/dialog/tool lifecycle, visible mutation/refusal, and undo. |
| Dependency / Coordination Risk | 2 | Depends on existing circular `target_height`, managed terrain metadata, repository/output regeneration, package staging, and hosted smoke access. No new solver, public contract, or external service dependency is planned. |
| Discovery / Ambiguity Risk | 3 | No completed repo analog exists for toolbar + `HtmlDialog` + `Sketchup::Tool` state. Official API and local terrain-editor prior art clarify direction, but real SketchUp lifecycle behavior can still force implementation adjustment. |
| Scope Volatility Risk | 2 | User and plan narrowed the task substantially. Volatility remains around optional radius drawing, transformed-owner hosted proof, and whether derived-output selection can be normalized safely. |
| Rework Risk | 2 | Rework is plausible if host callbacks, toolbar checked state, or coordinate conversion assumptions are wrong, but the plan sequences adapters and local seams first to limit blast radius. |
| Confidence | 2 | Requirements, architecture, and validation boundaries are clear, but lack of a direct repo UI analog and pending hosted smoke keep confidence moderate. |

### Top Assumptions

- Existing circular `target_height` command behavior is sufficient; no public MCP contract change is needed.
- Selected managed terrain owner is an acceptable first-slice target model; click selects center only.
- Local fake/injectable seams can prove request shape, dialog protocol, resolver behavior, and coordinate math before hosted smoke.
- Packaged SVG/HTML/CSS/JS assets under the extension support tree are covered by existing package staging/verification.
- Hosted SketchUp smoke is available late enough to confirm host-owned toolbar/dialog/tool lifecycle behavior.

### Estimate Breakers

- `UI::HtmlDialog` callback lifecycle or `Sketchup::Tool` activation behaves in a way that cannot be hidden behind the planned wrappers.
- Click-to-owner-local conversion cannot be made reliable for transformed or non-zero-origin terrain without deeper terrain state or output metadata changes.
- The current `edit_terrain_surface` circular `target_height` request shape proves insufficient, forcing public contract/schema/docs/fixture updates.
- Users require continuous strokes, persistent preview geometry, multiple modes, or derived-output click targeting as acceptance blockers.
- Package verification does not stage dialog/icon assets cleanly and requires packaging infrastructure changes.

### Predicted Signals

- Strong scope controls: one mode, one brush shape, one click per apply, no public contract change, no terrain math change.
- New system surface: first repo-owned SketchUp toolbar/dialog/tool terrain UI loop.
- Host-sensitive lifecycle: toolbar checked state, non-modal dialog callbacks, real input-point click capture, and undo need hosted smoke.
- Transform-sensitive math: terrain state uses owner-local public-meter coordinates while SketchUp clicks arrive as host/world/internal points.
- Outside-view analogs: MTA-04/MTA-12 support command/region/host validation expectations, but no direct analog exists for this UI state loop.

### Predicted Estimate Notes

- This is not a large terrain-editing feature, but it is not a trivial UI wrapper. The work is bounded by reusing `TerrainSurfaceCommands#edit_terrain_surface`; risk concentrates in host UI lifecycle, target selection, coordinate conversion, and validation.
- Validation burden remains `3` despite local-first proof because the final acceptance path crosses real SketchUp UI/event/undo behavior. It should not expand into a broad hosted matrix unless host smoke exposes a blocker.
- Discovery risk remains `3` because official API research and local prior art give direction but cannot prove SketchUp callback/tool behavior in this repo until implementation.
<!-- SIZE:PREDICTED:END -->

---

<!-- SIZE:CHALLENGE:START -->
## Challenge Review

> Filled when the estimate is pressure-tested through external review, premortem, or controlled consensus.

### Agreed Drivers

- The task remains functionally bounded: one toolbar container, one toolbar-button/menu entry, one dialog, one click tool, one circular `target_height` mode.
- Technical surface remains `3` because new SketchUp UI support, dialog assets, coordinate conversion, selected-owner resolution, package verification, docs, and tests are all in scope.
- Validation burden remains `3`: most proof is local, but a narrow hosted smoke is still required for host-owned toolbar/dialog/tool lifecycle, real click/InputPoint behavior, visible success/refusal, and undo.
- No public MCP contract change is planned; contract drift is a risk control, not expected scope.
- Premortem changes tightened the plan but did not add a second workflow or new terrain math.

### Contested Drivers

- Whether hosted smoke should raise validation burden above `3`: rejected for now because the hosted work is narrow and not a broad matrix unless it exposes a blocker or fix loop.
- Whether discovery risk should drop after the premortem: rejected for now because there is still no completed repo analog for `UI::Toolbar` + `UI::HtmlDialog` + `Sketchup::Tool` session state.
- Whether rework risk should rise after adding apply-time selection refresh: rejected for now because this is a local seam/test addition, not a broad behavior expansion.

### Missing Evidence

- Real SketchUp behavior for checked toolbar state, dialog close/reopen callbacks, and `Sketchup::Tool` click/InputPoint integration.
- Hosted confirmation that non-zero-origin or transformed-owner click conversion feeds the locally tested conversion seam correctly.
- Package verification evidence for final SVG and dialog asset paths.

### Recommendation

- Confirm the predicted profile without score changes.
- Do not split the task before implementation.
- Treat optional radius drawing and derived-output normalization as non-blocking; skip or refuse visibly if they threaten the first slice.

### Challenge Notes

- Premortem added apply-time selection/status refresh and positive-blend/`none` falloff refusal. These reduce hidden failure paths without changing task size.
- The estimate should be revisited during implementation only if host UI behavior creates a repeated fix loop, contract drift becomes necessary, or asset packaging requires infrastructure work.
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

| Dimension | Actual (0-4) | Rationale |
|---|---:|---|
| Functional Scope | 2 | Shipped the planned first-slice workflow: one `Managed Terrain` toolbar container, one `Target Height Brush` button/menu entry, one dialog, one click tool, one circular `target_height` mode, and visible status/refusal feedback. No broad grading system, multi-mode workflow, preview, or validation dashboard was added. |
| Technical Change Surface | 3 | Added a new SketchUp UI support area, packaged HTML/CSS/JS/SVG assets, dialog protocol, toolbar/menu installer, tool adapter, selected-terrain resolver, coordinate converter, session/request builder, README update, package checks, and focused tests. Public MCP contracts and terrain math stayed unchanged. |
| Actual Implementation Friction | 3 | Core code followed the planned seams, but live SketchUp exposed several host-lifecycle issues: top-level `::UI` lookup, dialog setting changes stealing tool focus, stale/nil dialog callback capture, toolbar checked-state SVG behavior, and selected-terrain refresh timing. All fixes were localized, but they required multiple live patch/retest loops. |
| Actual Validation Burden | 3 | Required full local test/lint/package validation, external `grok-4.3` review, and live SketchUp smoke. Hosted validation was not blocked, but it required repeated live fix/deploy/retest loops for toolbar/dialog/tool lifecycle behavior. Formal hosted undo and transformed-owner smoke remain recorded gaps. |
| Actual Dependency Drag | 2 | Depended on existing circular `target_height` command behavior, managed terrain metadata, package staging, and live SketchUp access. No new solver, public contract, external service, or cross-team dependency was introduced. |
| Actual Discovery Encountered | 3 | The plan correctly anticipated missing repo analogs for `UI::Toolbar` + `HtmlDialog` + `Sketchup::Tool`. Live behavior revealed concrete host semantics around constant lookup, toolbar icon/checked rendering, command image caching, and dialog/tool focus that local seams alone could not prove. |
| Actual Scope Volatility | 2 | Scope stayed bounded to the first slice. Adjustments were lifecycle/status refinements rather than new modes or broader workflow expansion. Optional radius drawing and derived-output normalization stayed out of scope. |
| Actual Rework | 3 | Several completed paths were revisited after live testing: installer command creation, dialog update callbacks, tool factory lifetime, toolbar icon assets, menu mirror behavior, selected-terrain state, and activation-time dialog push. Rework was repeated but remained within the planned UI boundary. |
| Final Confidence in Completeness | 3 | Full automated validation, package verification, final `grok-4.3` review, and live SketchUp verification support completion. Confidence is high for the first slice, with explicit residual gaps for formal hosted undo inspection and transformed-owner hosted conversion. |
<!-- SIZE:ACTUAL:END -->

---

<!-- SIZE:VALIDATION-EVIDENCE:START -->
## Validation Evidence Summary

> Fill only the sections that are relevant. Say `not applicable` where needed.

- **Automated tests**: `bundle exec rake ruby:test` passed with `1044 runs, 8628 assertions, 0 failures, 0 errors, 37 skips`.
- **Lint/static checks**: `bundle exec rake ruby:lint` passed with `268 files inspected, no offenses detected`.
- **Package verification**: `bundle exec rake package:verify` passed and produced `dist/su_mcp-1.4.0.rbz`; staged managed terrain UI assets were verified.
- **External review**: final `mcp__pal__.codereview` using `grok-4.3` found no critical, high, medium, or low issues.
- **Hosted/live SketchUp smoke**: live SketchUp 2026 checks covered extension load, one `Managed Terrain` toolbar, toolbar checked highlight with one transparent SVG, dialog setting changes reselecting the brush, selected-terrain field refresh before apply, invalid/no-selection status, and successful selected-terrain brush apply.
- **Contract validation**: no public MCP tool/schema/dispatcher/fixture change was made; README documents the new SketchUp-facing workflow.
- **Remaining validation gaps**: formal hosted undo inspection was not separately recorded; transformed/non-zero-origin coordinate behavior is covered locally but not by a dedicated hosted transformed-owner smoke.
<!-- SIZE:VALIDATION-EVIDENCE:END -->

---

<!-- SIZE:DELTA:START -->
## Estimation Delta Review

> Filled during final calibration. Compare prediction to actual behavior.

### What The Estimate Got Right

- Functional scope and technical surface matched the prediction: one bounded SketchUp-facing workflow, hosted by the initial `Managed Terrain` toolbar container, over the existing `target_height` command path.
- The major risk concentration was correctly identified: host UI lifecycle, toolbar checked state, dialog callbacks, click tool behavior, selected-owner resolution, and coordinate conversion.
- The task did not drift into public MCP contract changes, terrain math changes, broad sculpting, preview geometry, or validation ownership.

### What Was Underestimated

- Host UI lifecycle rework was more concrete and iterative than the ledger captured. The task required multiple live monkey-patch/fix loops for loaded class state, toolbar icon rendering, command caching, dialog/tool focus, and selected-terrain status timing.
- Visibility semantics were underweighted. `MF_CHECKED` was technically correct, but the SVG had to be transparent and padded before the native checked highlight was visible enough.
- Dialog state freshness needed more attention. The selected-terrain row existed in the UI, but it was initially not refreshed at the right lifecycle points.

### What Was Overestimated

- No public contract or terrain-command insufficiency emerged. The existing `edit_terrain_surface` request shape handled the UI path without schema, dispatcher, fixture, or docs-contract expansion.
- Package staging did not require infrastructure changes; it was covered by existing package support plus focused assertions.

### Dominant Actual Failure Mode

The dominant failure mode was host-runtime lifecycle mismatch: local seams proved the intended design, but real SketchUp behavior around already-loaded Ruby classes, toolbar/menu command objects, `HtmlDialog` focus, and checked-state rendering required live validation and localized rework.

### Future Estimate Lessons

- Native SketchUp toolbar/dialog/tool tasks should retain at least `Implementation Friction Risk = 3` and `Validation Burden Risk = 3` unless there is a direct repo analog and hosted behavior has already been proven.
- For `UI::Command` checked state, icon transparency/padding and host rendering behavior should be treated as first-class validation concerns.
- Selection/status UI fields need explicit lifecycle tests for activation-time refresh, dialog ready/request-state refresh, and post-apply refresh.
- Hosted validation should be scored by retest-loop cost, not by the small number of manual cases. This task stayed bounded, but required repeated live fix loops.
<!-- SIZE:DELTA:END -->

---

<!-- SIZE:TAGS:START -->
## Retrieval Tags

- `archetype:feature`
- `scope:managed-terrain`
- `unclassified:sketchup-ui`
- `systems:command-layer`
- `systems:scene-mutation`
- `systems:terrain-state`
- `systems:target-resolution`
- `systems:packaging`
- `validation:hosted-smoke`
- `validation:undo`
- `contract:no-public-shape-change`
- `contract:finite-options`
- `host:repeated-fix-loop`
- `risk:host-api-mismatch`
- `risk:unit-conversion`
- `risk:transform-semantics`
- `risk:visibility-semantics`
- `risk:undo-semantics`
- `risk:wrong-live-runtime`
- `volatility:low`
- `friction:medium`
- `rework:medium`
- `confidence:high`
<!-- SIZE:TAGS:END -->
