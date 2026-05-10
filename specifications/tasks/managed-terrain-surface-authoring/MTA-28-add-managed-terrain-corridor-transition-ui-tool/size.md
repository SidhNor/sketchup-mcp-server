# Size: MTA-28 Add Managed Terrain Corridor Transition UI Tool

**Task ID**: `MTA-28`  
**Title**: `Add Managed Terrain Corridor Transition UI Tool`  
**Status**: `calibrated`
**Created**: `2026-05-08`  
**Last Updated**: `2026-05-10`  

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
  - `systems:scene-mutation`
  - `systems:surface-sampling`
  - `systems:terrain-state`
  - `systems:terrain-repository`
  - `systems:terrain-output`
  - `systems:packaging`
  - `systems:test-support`
  - `systems:docs`
- **Validation Modes**: `validation:hosted-smoke`, `validation:undo`
- **Likely Analog Class**: non-brush SketchUp terrain UI tool over existing corridor edit command

### Identity Notes
- This task adds the first distinct visual cue family after round brushes. Corridor transition UI should reuse the shared panel foundation while keeping corridor geometry separate from survey and planar point-list UX.
- Planning rebaseline: Step 06 and Step 10 made explicit 3D endpoint capture, manual Z editing, required corridor overlay roles, terrain sampling/reset, package coverage, and no-public-contract guard work part of the implementation baseline.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Adds a new user-facing tool with multi-point corridor controls and a corridor-specific overlay. |
| Technical Change Surface | 3 | Likely touches tool registry, panel inputs, point capture, corridor request construction, overlay drawing, docs, and tests. |
| Hidden Complexity Suspicion | 3 | Start/end capture, elevation entry, corridor width/shoulder visualization, transforms, and invalid corridor state are likely friction points. |
| Validation Burden Suspicion | 3 | Existing corridor math lowers kernel risk, but live SketchUp proof is needed for point capture, overlay, apply, and undo posture. |
| Dependency / Coordination Suspicion | 2 | Depends on MTA-27 and MTA-05; no public contract or terrain kernel change is expected. |
| Scope Volatility Suspicion | 2 | Scope is distinct and demonstrable, but could expand if point-list or hardscape-reference behavior is pulled in prematurely. |
| Confidence | 2 | Requirements are concrete, but no corridor UI analog exists yet in the repo. |

### Early Signals
- MTA-05 calibrated corridor math and hosted validation, but this task owns UI capture and overlay rather than solver behavior.
- Corridor cue geometry is not a round-brush variant and should be planned as its own visual family.
- The accepted boundary excludes survey and planar point-list UX.
- Hosted verification should focus on real control capture, visual cue behavior, command handoff, and undo posture.

### Early Estimate Notes
- Strong analogs are MTA-18 for SketchUp UI lifecycle and MTA-05 for corridor request semantics. Use MTA-05 as a contract/intent analog, not as evidence of new kernel scope.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

> Filled during task planning. This is the main pre-implementation estimate.

| Dimension | Prediction (0-4) | Rationale |
|---|---:|---|
| Functional Scope | 3 | Adds a new SketchUp-facing managed terrain tool with two-point capture, explicit X/Y/Z endpoint editing, width and side-blend controls, preview overlay, Reset/Apply workflow, and command-backed apply. Scope remains one corridor workflow and excludes survey, planar, point-list, hardscape, and validation-dashboard behavior. |
| Technical Change Surface | 3 | Touches installer/toolbar/menu wiring, shared dialog sizing, panel HTML/CSS/JS actions, corridor state/session, SketchUp tool callbacks, coordinate conversion, read-only terrain sampling, overlay drawing, request construction, package assets, docs if needed, UI tests, and contract guards. It avoids new terrain math and public MCP schemas. |
| Implementation Friction Risk | 3 | Main friction is first non-round multi-point UI state: endpoint capture and recapture, sampled/manual Z provenance, preserving manual Z, owner-local XYZ conversion, panel/JS state sync, explicit Apply gating, and overlay geometry at actual endpoint Z. |
| Validation Burden Risk | 3 | Local seams can cover state/request/panel/tool/overlay behavior, but real SketchUp smoke is required for `InputPoint#pick`, dialog focus/reselect, toolbar checked state, overlay readability, manual Z above/below terrain, undo posture, and transformed or non-zero-origin coordinates. |
| Dependency / Coordination Risk | 2 | Depends on implemented MTA-27, MTA-26, MTA-05, package staging, and hosted SketchUp access. No external service, new solver, migration, or public contract coordination is planned. |
| Discovery / Ambiguity Risk | 2 | Major design choices are resolved by planning and consensus. Remaining uncertainty is tactical defaults, slider ranges, visual styling, live marker hit testing if attempted, and hosted behavior. |
| Scope Volatility Risk | 2 | Boundaries are explicit and marker-select recapture is optional/smoke-gated. Volatility remains if 3D gizmo, point-list, or future survey/planar abstractions are pulled in during implementation. |
| Rework Risk | 3 | MTA-18/MTA-26/MTA-27 analogs show host UI and overlay features often require live tuning or lifecycle fixes. MTA-28 adds manual Z/provenance and transformed XYZ preview/apply alignment, making stale-state and visual rework likely enough to score high. |
| Confidence | 2 | Confidence is moderate: the plan is detailed, the command contract exists, and analogs are strong for pieces, but no exact prior corridor UI analog exists and the hardest behavior is live SketchUp interaction. |

### Top Assumptions

- Existing `edit_terrain_surface` `corridor_transition` request validation and command dispatch remain sufficient for UI apply.
- Corridor can be added as a distinct UI state/tool/overlay while preserving existing round-brush behavior.
- SketchUp click/inference capture plus numeric panel editing is enough for first-slice 3D endpoint definition without scene gizmos.
- Read-only terrain-state sampling can seed/reset endpoint Z, while manual Z above/below terrain remains valid.
- Hosted SketchUp access is available for temporary-fixture smoke of capture, overlay, apply, undo, and transformed/non-zero-origin behavior.

### Estimate Breakers

- Full owner-local XYZ conversion requires changing existing command/request semantics rather than only UI conversion.
- Real SketchUp interaction cannot provide reliable two-point capture or recapture without persistent helper geometry or a deeper tool lifecycle redesign.
- The required overlay roles cannot be made readable without persistent preview entities or a substantially different rendering approach.
- Manual Z preservation and terrain sampling create state divergence that cannot be covered by the planned corridor state/session object.
- The task expands into 3D gizmos, survey/planar point-list controls, or public MCP contract changes.

### Predicted Signals

- Strong analog MTA-27: shared Managed Terrain toolbar/panel and local-fairing UI showed command-backed UI addition, invalid-state handling, panel sizing, package coverage, and hosted smoke needs.
- Strong analog MTA-26: transient overlay work required transformed-owner proof, cache invalidation, invalid-settings proof, and live visual tuning.
- Strong analog MTA-18: native SketchUp toolbar/dialog/tool lifecycle produced host-only issues around command state, icon rendering, dialog focus, and selection status.
- MTA-05 removes corridor terrain-kernel risk but keeps corridor request-shape parity and adopted-coordinate validation relevant.
- No exact analog exists for a non-round two-point SketchUp terrain UI over an existing command, so confidence is capped.

### Predicted Estimate Notes

- This is a moderate-large SketchUp UI feature, not a terrain kernel or public
  MCP contract task.
- Validation burden is score `3` because hosted proof is required and prior UI
  analogs had real live tuning/fix loops. It is not score `4` because no
  migration, performance investigation, public schema rollout, or new terrain
  math is planned.
- Planning rebaseline before prediction reflects explicit endpoint Z editing,
  panel recapture, required overlay roles, and no-public-contract guard work.
  This is not implementation drift.
<!-- SIZE:PREDICTED:END -->

---

<!-- SIZE:CHALLENGE:START -->
## Challenge Review

### Agreed Drivers

- Functional scope remains score `3`: the task adds a new two-point
  SketchUp-facing terrain workflow with explicit endpoint Z editing and required
  overlay feedback, but stays bounded to one corridor mode.
- Technical change surface remains score `3`: installer, dialog, panel assets,
  corridor state/tool/overlay, XYZ conversion, terrain sampling, request
  construction, package coverage, and guards move together, while terrain math
  and public MCP schemas stay unchanged.
- Implementation friction remains score `3`: premortem and Grok 4.3 review both
  identify real resistance around inference-dependent capture, manual-Z
  provenance, transformed XYZ conversion, state lifecycle, and overlay geometry.
- Validation burden remains score `3`: the premortem added sharper hosted cases,
  but they are still a focused smoke/matrix over one UI feature rather than a
  migration, performance investigation, public-client matrix, or new solver
  proof.
- Rework risk remains score `3`: host UI lifecycle and overlay readability have
  calibrated live-tuning history in MTA-18, MTA-26, and MTA-27, and MTA-28 adds
  new state/provenance paths that are likely to require local or hosted
  correction.

### Contested Drivers

- Whether validation burden should rise to `4`: rejected for now. The added
  manual-Z, transformed/non-zero-origin, lifecycle, and overlay-readability
  checks are materially sharper than routine happy-path smoke, but there is not
  pre-implementation evidence of blockers, repeated redeploy/restart loops,
  performance work, persistence investigation, or validation-driven redesign.
- Whether marker-select recapture should increase scope or volatility: rejected
  because final plan makes panel Recapture Start/End the supported baseline and
  treats marker selection as optional only with explicit proof and fallback.
- Whether confidence should rise after consensus and premortem: rejected. The
  plan is clearer, but no exact prior non-round two-point corridor UI analog
  exists and the hardest evidence remains hosted.
- Whether the task should split before implementation: rejected. The premortem
  found no unresolved Tigers after adding manual-Z parity, transformed-owner
  parity, lifecycle, and contract-guard checks.

### Missing Evidence

- Hosted evidence that panel-authored endpoint Z values not supplied by
  inference visibly drive preview and Apply.
- Hosted transformed or non-zero-origin owner proof with endpoint Z offset more
  than 2 meters from sampled terrain.
- Hosted focus/reselect evidence that panel state, overlay state, and Apply
  state remain synchronized after dialog editing.
- Implementation evidence that UI-only metadata such as provenance, recapture
  mode, overlay cues, and marker state never leaks into public MCP requests,
  persisted terrain state, native fixtures, or schemas.
- Implementation evidence that effectively collapsed endpoint geometry is
  refused or warned before a misleading preview/apply.

### Recommendation

- Confirm the predicted scores with no revisions.
- Do not split MTA-28 before implementation.
- Treat the final `plan.md` Premortem Gate as required implementation closeout
  evidence, especially manual-Z preview/apply parity and transformed-owner
  coordinate parity.
- Raise validation burden or record drift only if hosted smoke produces a
  blocked matrix, repeated fix/redeploy loops, or a need for persistent preview
  geometry, 3D gizmos, or public contract changes.

### Challenge Notes

- Grok 4.3 premortem critique usefully challenged whether numeric Z editing was
  falsifiable enough. The plan was corrected to require a hosted manual-Z case
  where inference does not supply the intended elevation and panel values must
  drive preview and Apply.
- The critique also raised marker-select recapture and lifecycle divergence.
  Final plan keeps marker-select optional and adds a hosted focus/reselect
  lifecycle probe.
- No new evidence justifies revising the predicted score table after those plan
  corrections; the uncertainty is now carried as explicit validation evidence
  rather than unresolved scope.
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
| Functional Scope | 3 | Shipped one large behavior-visible SketchUp workflow: toolbar command, two endpoint capture/editing, corridor parameters, overlay, reset/apply, and command-backed durable edit. Survey, planar, point-list, hardscape, and public MCP workflows stayed out of scope. |
| Technical Change Surface | 3 | Touched layered UI surfaces: installer/tool selection, shared dialog callbacks, HTML/CSS/JS panel state, corridor session/tool/overlay classes, owner-local XYZ conversion, preview sampling, package assets, docs, and focused tests. Terrain math and public runtime contracts were not changed. |
| Actual Implementation Friction | 3 | Significant resistance came from Ruby/JS state synchronization, endpoint provenance, owned sub-session routing, overlay geometry/readability, and hover performance. The implementation stayed within the planned architecture without a deeper redesign. |
| Actual Validation Burden | 4 | Hosted validation dominated closeout through repeated fix/redeploy/restart/reload loops for hidden corridor controls, missing overlay visibility, slider recenter/flicker behavior, overlay persistence/readability, translucent side surfaces, and hover sluggishness. |
| Actual Dependency Drag | 2 | Delivery depended on MTA-26/MTA-27/MTA-05 behavior and live SketchUp deployment/reload access, but no external service, public client, migration, or cross-owner coordination blocked completion. |
| Actual Discovery Encountered | 3 | Live evidence exposed host-sensitive issues that local tests did not fully predict: HtmlDialog hover clearing, slider transient update feedback, round-brush control leakage, side-blend default ergonomics, overlay 3D legibility, and sampler-cache performance. |
| Actual Scope Volatility | 2 | The task shape stayed bounded to corridor UI, but details shifted inside the accepted workflow: no forced side blend, hidden brush radius/blend controls, nonlinear sliders, persistent overlay on dialog hover, translucent corridor side surfaces, and sampler caching. |
| Actual Rework | 3 | Completed UI and overlay slices were revisited several times after hosted feedback and review findings, including slider behavior, overlay visibility/persistence, session routing, unknown-tool routing, tolerance naming, and performance caching. |
| Final Confidence in Completeness | 4 | Full Ruby tests, lint, package verification, focused post-review checks, Grok 4.3 review disposition, and final hosted user verification all passed with no remaining public contract gap. |

### Actual Signals
- First non-round managed terrain tool required distinct Ruby-owned corridor session/tool/overlay behavior rather than a brush variant.
- The strongest actual resistance was host-visible feedback: controls shown/hidden correctly, transient slider updates, overlay persistence/readability, and hover redraw cost.
- The public contract boundary held: no MCP tool/schema/dispatcher/request-shape changes were needed.
- Side blend became optional by default, matching the product goal of minimal values that still let the corridor tool apply.

### Actual Notes
- Validation burden is scored higher than implementation friction because the expensive part was discovering and retesting live SketchUp behavior, not rewriting the core architecture.
- The drift log remains empty because the task did not materially change direction during implementation; the validation cost is captured in actual calibration.
<!-- SIZE:ACTUAL:END -->

---

<!-- SIZE:VALIDATION-EVIDENCE:START -->
## Validation Evidence Summary

> Fill only the sections that are relevant. Say `not applicable` where needed.

### Automated Validation
- `bundle exec rake ruby:test`: `1264 runs, 12371 assertions, 0 failures, 0 errors, 37 skips`.
- `bundle exec rake ruby:lint`: `313 files inspected, no offenses detected`.
- `bundle exec rake package:verify`: passed and produced `dist/su_mcp-1.6.1.rbz`.
- Focused post-review checks for installer, settings dialog, and corridor overlay preview: `39 runs, 241 assertions, 0 failures, 0 errors, 0 skips`.

### Hosted / Manual Validation
- Hosted SketchUp verification completed after repeated redeploy/restart/reload loops.
- User verified toolbar/panel workflow, endpoint capture/editing, corridor apply behavior, side-blend defaults, slider behavior, overlay persistence/readability, translucent side surfaces, and sampler-cache performance.
- Final user status recorded in `summary.md`: "I've verified all, happy with the tool now".

### Performance Validation
- Hosted feedback identified sluggish hover behavior.
- Corridor preview sampling now caches terrain sampler state during hover redraw; user verified the final behavior was acceptable.

### Migration / Compatibility Validation
- Not applicable: no migration, persisted state format change, public MCP schema change, dispatcher route, or native catalog change was introduced.

### Operational / Rollout Validation
- Package verification confirmed the RBZ staging includes the new corridor UI assets.
- Live reload/deployment was exercised in the SketchUp runtime; hosted evidence is intentionally recorded in `summary.md` rather than a separate mandatory artifact.

### Validation Notes
- Grok 4.3 final review found only low-severity maintainability issues; all were addressed before the final full validation run.
- Contract guard coverage confirms UI-only metadata and overlay concepts do not leak into public requests or native fixtures.
<!-- SIZE:VALIDATION-EVIDENCE:END -->

---

<!-- SIZE:DELTA:START -->
## Estimation Delta Review

- **Most Underestimated Dimension**: Actual Validation Burden. Prediction was `3`, but hosted closeout behaved like `4` because multiple independent live defects required fix/redeploy/restart/reload loops and final user retesting.
- **Most Overestimated Dimension**: None materially. Functional scope, technical surface, dependency drag, and scope volatility were close to the prediction.
- **Signal Present Early But Underweighted**: MTA-18/MTA-26/MTA-27 already showed that SketchUp UI and overlay work can fail only in live host feedback loops. The estimate named that risk, but did not weight slider state, dialog-hover overlay persistence, and overlay 3D readability strongly enough.
- **Genuinely Unknowable Factor**: The exact hosted interaction defects were not knowable from local fakes: invisible overlay after clean redeploy, high-frequency slider flicker/recentering, and hover redraw sluggishness needed the SketchUp runtime to expose them.
- **Future Similar Tasks Should Assume**: New SketchUp terrain UI tools with HtmlDialog controls plus transient 3D overlays should reserve capacity for at least one hosted retest loop, and should escalate to `4` validation burden once more than one live-only issue requires redeploy/restart/reload.

### Calibration Notes
- Dominant actual failure mode: host-visible state/overlay feedback mismatch, not public contract or terrain-kernel uncertainty.
- Future analog retrieval should find this task for non-brush SketchUp UI tools, transient overlay readability, HtmlDialog slider feedback loops, optional/default parameter ergonomics, and hosted performance tuning.
- No public contract drift occurred; the no-public-shape-change assumption was correct.
<!-- SIZE:DELTA:END -->

---

<!-- SIZE:TAGS:START -->
## Retrieval Tags

- `archetype:feature`
- `scope:managed-terrain`
- `unclassified:sketchup-ui`
- `systems:surface-sampling`
- `systems:terrain-state`
- `validation:hosted-smoke`
- `host:repeated-fix-loop`
- `contract:no-public-shape-change`
- `risk:visibility-semantics`
- `risk:performance-scaling`
- `risk:partial-state`
- `friction:high`
- `rework:high`
- `confidence:high`
<!-- SIZE:TAGS:END -->
