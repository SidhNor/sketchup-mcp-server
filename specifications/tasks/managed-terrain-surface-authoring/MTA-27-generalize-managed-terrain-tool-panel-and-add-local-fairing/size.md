# Size: MTA-27 Generalize Managed Terrain Tool Panel And Add Local Fairing

**Task ID**: `MTA-27`
**Title**: `Generalize Managed Terrain Tool Panel And Add Local Fairing`
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
  - `systems:scene-mutation`
  - `systems:terrain-state`
  - `systems:terrain-output`
  - `systems:packaging`
  - `systems:test-support`
  - `systems:docs`
- **Validation Modes**: `validation:hosted-smoke`, `validation:undo`
- **Likely Analog Class**: shared SketchUp terrain tool panel over existing command-backed edit modes

### Identity Notes
- This task proves the Managed Terrain toolbar/panel split with two round-brush tools: target height and local fairing. It should generalize only enough for those two existing command-backed modes.
- Planning rebaseline: Step 06 added the explicit UI-control requirement for slider plus adjacent numeric inputs, apply-blocking invalid state, shared brush settings, per-tool operation settings, and a distinct local-fairing icon.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Adds a second user-facing terrain tool, converts the dialog into a shared active-tool panel, and adds slider plus numeric input behavior for bounded controls. |
| Technical Change Surface | 3 | Likely touches toolbar command registry, panel protocol, tool activation, request construction, shared selection/status handling, assets, docs, and tests. |
| Hidden Complexity Suspicion | 3 | Risks center on focus/tool reactivation, active button state, panel state synchronization, apply-blocking invalid input, and avoiding overgeneralized abstractions. |
| Validation Burden Suspicion | 3 | Needs local tool/panel/request coverage plus hosted smoke for two toolbar buttons, panel switching, and local fairing apply. |
| Dependency / Coordination Suspicion | 2 | Depends on MTA-18, MTA-26, and MTA-06, but reuses existing command behavior and avoids public contract changes. |
| Scope Volatility Suspicion | 2 | Scope can expand if corridor/control-point abstractions leak into this task; the accepted boundary is two round-brush tools only. |
| Confidence | 2 | The product boundary is clear, but MTA-18 showed shared host UI state is live-sensitive. |

### Early Signals
- The task is the abstraction proof point: one toolbar, one shared panel, two concrete tools.
- Local fairing already exists as terrain command behavior, so terrain math should stay out of scope.
- User explicitly wanted toolbar wording and UI controls to distinguish the container from tool buttons.
- User refined the panel requirement to prefer UE-style shared brush settings, sliders with adjacent numeric inputs, UI-side invalid-value rejection, `100m` ergonomic slider max for radius/blend in meters, and numeric entry above slider range when valid.
- Hosted validation is likely needed for active-tool switching and dialog/tool focus behavior.

### Early Estimate Notes
- Strong analogs are MTA-18 for UI lifecycle and MTA-06 for existing local fairing behavior. Analog use should not imply new kernel risk.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

> Filled during task planning. This is the main pre-implementation estimate.

| Dimension | Prediction (0-4) | Rationale |
|---|---:|---|
| Functional Scope | 3 | Adds a second real SketchUp-facing terrain tool, a shared panel, active-tool switching, local-fairing apply, shared brush state, slider plus numeric controls, and invalid-value refusal. Scope remains limited to two round-brush tools and existing command behavior. |
| Technical Change Surface | 3 | Touches installer/toolbar commands, dialog wrapper and assets, settings/session state, round-brush tool plumbing, overlay reuse, request construction, package assets, README, UI tests, and guard tests. It avoids terrain math and public MCP schema changes. |
| Implementation Friction Risk | 3 | Main friction is host UI lifecycle and state synchronization: active checked state, dialog focus/reselect, suspend/resume, invalid update blocking, shared versus per-tool settings, and avoiding stale overlay/cache state. |
| Validation Burden Risk | 3 | Local seams can cover most behavior, but hosted SketchUp smoke is required for two-button toolbar behavior, checked-state icon visibility, dialog focus, panel switching, overlay cleanup, and real local-fairing apply/refusal. |
| Dependency / Coordination Risk | 2 | Depends on implemented MTA-18, MTA-26, MTA-06, current local-fairing circle support, package staging, and hosted smoke access. No new external service, solver, or public contract dependency is planned. |
| Discovery / Ambiguity Risk | 2 | Major design choices are resolved after Step 06 and Grok 4.3 review. Remaining uncertainty is tactical class naming, icon motif, fairing default strength, and live host behavior. |
| Scope Volatility Risk | 2 | Boundaries are explicit: no corridor, survey, planar, validation dashboard, or broad registry. Volatility remains if shared panel work tempts future-tool abstractions or hosted UI behavior requires lifecycle adjustments. |
| Rework Risk | 3 | Calibrated MTA-18/MTA-26 analogs showed repeated hosted UI fix loops and visual tuning. MTA-27 adds a second command and shared state, so rework risk remains meaningful even with local-first TDD. |
| Confidence | 3 | Confidence is moderate-high because command behavior and overlay support exist, circle fairing is verified in current contract tests, and decisions were reviewed with Grok 4.3. Confidence is capped by host-sensitive UI behavior. |

### Top Assumptions

- Existing `edit_terrain_surface` `local_fairing + circle` support remains valid and does not require public MCP schema changes.
- One shared round-brush tool/session foundation can preserve target-height behavior while adding local fairing without duplicating lifecycle callbacks.
- Shared brush settings with per-tool operation settings match user expectations and the desired UE-style UX.
- Local tests can prove state, request, invalid input, and package behavior before hosted smoke.
- Hosted SketchUp smoke access is available for toolbar/panel/tool lifecycle verification.

### Estimate Breakers

- Hosted SketchUp behavior makes two command checked states, dialog focus, or active tool reselect unreliable without restructuring the installer/dialog lifecycle.
- Invalid panel updates cannot be made apply-blocking without a deeper settings/session redesign.
- Numeric input above slider range creates confusing or unsafe overlay/apply behavior that requires a different UI model.
- Local-fairing UI apply exposes hidden assumptions in command output, evidence, or overlay cache dirtying.
- The task expands into corridor/control-point registry behavior or future-tool abstractions.

### Predicted Signals

- Strong analog MTA-18: toolbar/dialog/tool lifecycle produced live host fix loops and checked-state/icon work.
- Strong analog MTA-26: overlay preview required cache dirtying, transformed-owner proof, invalid-setting proof, and live visual tuning.
- Supporting analog MTA-06: local-fairing command behavior is implemented and calibrated, reducing terrain math risk.
- Current implementation already has most seams but they are target-height-specific, so shared state refactoring is the central implementation risk.
- No public contract delta materially reduces schema/dispatcher/native fixture risk.

### Predicted Estimate Notes

- This is a moderate-large UI feature over existing terrain command behavior, not a terrain kernel task.
- Validation burden is score `3` because hosted proof is necessary and prior native SketchUp UI tasks had real fix loops; it is not score `4` because no public MCP contract or new terrain math is planned.
- Planning rebaseline before prediction reflects the added slider/numeric control and apply-blocking invalid-state requirements; this is not implementation drift.
<!-- SIZE:PREDICTED:END -->

---

<!-- SIZE:CHALLENGE:START -->
## Challenge Review

### Agreed Drivers

- Functional scope remains score `3`: the task adds a second real SketchUp UI
  tool and a shared panel with slider/numeric controls, but stays limited to two
  existing round-brush command modes.
- Technical surface remains score `3`: installer, dialog assets, settings,
  session, tool lifecycle, overlay reuse, package assets, docs, and tests move
  together, while public MCP contracts and terrain math stay unchanged.
- Implementation friction remains score `3`: MTA-18 and MTA-26 calibrated
  analogs support host lifecycle, checked-state, focus/reselect, and visual
  tuning risk.
- Validation burden remains score `3`: hosted smoke is required, but no broad
  public contract matrix, new solver, migration, or performance proof is planned.
- Rework risk remains score `3`: premortem and Grok 4.3 review found likely
  stale-state, invalid-input, and overlay freshness pitfalls that should be
  caught by tests but may still force local/hosted fix loops.

### Contested Drivers

- Whether validation burden should rise above `3`: rejected for now because the
  required hosted checks are focused UI lifecycle smoke, not a large matrix with
  known blockers. Raise only if hosted smoke produces repeated fix/redeploy
  loops.
- Whether implementation friction should drop after decisions were clarified:
  rejected because clarified decisions do not remove SketchUp host lifecycle
  risk from the MTA-18/MTA-26 analogs.
- Whether scope volatility should rise after adding slider/numeric behavior:
  rejected because the task was updated before prediction and the plan now
  explicitly rejects corridor, survey, planar, and broad registry expansion.

### Missing Evidence

- Hosted confirmation of two-command checked-state visibility and icon clarity.
- Hosted confirmation of the focus/reselect sequence after numeric field input
  and tool switching.
- Implementation evidence that invalid numeric updates block apply and slider
  correction clears the invalid state.
- Implementation evidence that local-fairing apply dirties overlay state and the
  next hover samples fresh terrain.

### Recommendation

- Confirm the predicted profile with no score revisions.
- Do not split the task before implementation.
- Treat the premortem gates in `plan.md` as required closeout evidence,
  especially stale-state, invalid-input, overlay freshness, and hosted focus
  sequence checks.

### Challenge Notes

- Grok 4.3 review supported the small mode-aware round-brush foundation and the
  UE-style shared brush model, with added test gates for stale state and invalid
  updates.
- Premortem found no unresolved Tigers. The accepted residual risks are
  host-rendering/checked-state tuning and numeric-above-slider visual awkwardness,
  both covered by local and hosted validation gates.
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

| Dimension | Actual (0-4) | Rationale |
|---|---:|---|
| Functional Scope | 3 | Shipped a second real SketchUp-facing terrain tool, one shared panel, active-tool switching, local-fairing apply, invalid-value refusal, and slider plus numeric controls. Scope stayed limited to two round-brush tools and existing command-backed edit modes. |
| Technical Change Surface | 3 | Touched settings/session state, request construction, toolbar/menu installer, dialog wrapper, HTML/CSS/JS assets, toolbar icons, overlay-adjacent behavior, package coverage, README, contract guards, and task metadata. No public MCP schema, dispatcher, terrain math, or native fixture changes were needed. |
| Actual Implementation Friction | 2 | Core implementation followed the planned dependency order. Moderate friction came from preserving valid shared brush updates while unrelated fields were invalid, shaping apply-blocking state, and adjusting nonlinear/snap slider behavior after visual review. No architectural rewrite or public-contract redesign occurred. |
| Actual Validation Burden | 3 | Validation required focused UI/package tests, full Ruby tests, full RuboCop, package verification, Grok 4.3 review, hosted SketchUp smoke, and manual visual confirmation. Hosted validation needed one correction after an initial smoke touched an existing terrain; replacement smoke used an isolated temporary fixture and passed. |
| Actual Dependency Drag | 2 | The task depended on existing target-height UI, overlay preview, local-fairing command support, package staging, and SketchUp hosted access. Those dependencies were available and did not block implementation, but hosted smoke required care around fixture isolation. |
| Actual Discovery Encountered | 2 | Implementation surfaced practical UI-state details not fully captured in the first local pass: shared brush updates must survive unrelated invalid operation fields, radius/blend sliders needed nonlinear low-meter control, slider values should snap to `0.1m`, and the panel needed extra height. |
| Actual Scope Volatility | 2 | Scope remained inside the accepted two-tool round-brush boundary. Volatility was limited to ergonomic refinements and hosted-smoke fixture posture, not new tool families or terrain-kernel behavior. |
| Actual Rework | 2 | Rework was moderate and localized: user/review follow-up adjusted invalid partial-update behavior, slider scaling, slider snapping, panel height, summary metadata, and hosted smoke procedure. No repeated deploy/restart loops or broad refactors were required. |
| Final Confidence in Completeness | 4 | Confidence is high after focused and full automated validation, package verification, contract guards, Grok 4.3 implementation review, hosted smoke on a temporary managed terrain fixture, and manual visual confirmation that the panel/tool behavior works. |

### Actual Notes

- Dominant actual failure mode: partial UI state handling, specifically keeping
  valid shared brush fields while another active operation field remains
  apply-blocking invalid.
- Hosted validation class: special temporary fixture with one procedural
  correction after avoiding existing terrain; no repeated hosted fix loops.
- Public contract posture held: UI-only names and panel concepts stayed out of
  MCP native catalog/schema surfaces.
<!-- SIZE:ACTUAL:END -->

---

<!-- SIZE:VALIDATION-EVIDENCE:START -->
## Validation Evidence Summary

- Focused MTA-27 terrain UI/package suite:
  - `96 runs, 473 assertions, 0 failures, 0 errors, 0 skips`
- Focused post-closeout UI/package checks after panel height and slider snapping:
  - `20 runs, 211 assertions, 0 failures, 0 errors, 0 skips`
- Full Ruby test suite:
  - `1144 runs, 11424 assertions, 0 failures, 0 errors, 37 skips`
- Full Ruby lint:
  - `283 files inspected, no offenses detected`
- Package verification:
  - passed; produced `dist/su_mcp-1.5.0.rbz`
- `git diff --check`:
  - passed after MTA-27 metadata cleanup
- Code review:
  - Step 05 queue review and Step 10 implementation review both ran with
    `mcp__pal__.codereview` using `grok-4.3`
  - no critical, high, or medium implementation defects were found
- Hosted SketchUp validation:
  - initial smoke accidentally targeted an existing selected managed terrain and
    was immediately undone
  - replacement smoke created a temporary managed terrain fixture with
    sourceElementId `mta-27-hosted-smoke-1778262391`, selected only that fixture,
    verified toolbar/session/panel/refusal/local-fairing apply behavior, and
    erased the fixture afterward
  - manual visual verification confirmed the panel/tool behavior looked good and
    worked; follow-up panel height and slider snapping changes were validated
<!-- SIZE:VALIDATION-EVIDENCE:END -->

---

<!-- SIZE:DELTA:START -->
## Estimation Delta Review

### What The Prediction Got Right

- Functional scope and technical surface were correctly predicted at `3`: the
  task became a moderate-large SketchUp UI feature over existing terrain command
  behavior, touching state, session, installer, assets, package, docs, and tests.
- Validation burden was correctly predicted at `3`: local tests covered most
  behavior, but hosted SketchUp smoke and manual visual confirmation were still
  necessary for the host-sensitive UI workflow.
- No public MCP contract or terrain math change was needed, matching the plan's
  central assumption.

### What Was Overestimated

- Implementation friction was slightly overestimated. The planned seams were
  strong enough that mode-aware state, request construction, toolbar wiring, and
  panel conversion did not require a deeper lifecycle redesign.
- Rework risk was slightly overestimated relative to MTA-18/MTA-26 analogs. The
  task had several small local follow-ups, but not repeated live rendering or
  restart/redeploy loops.

### What Was Underestimated

- UI numeric ergonomics were underweighted. Nonlinear slider mapping, `0.1m`
  slider snapping, and preserving valid shared settings while another field was
  invalid were concrete product-quality details that emerged late.
- Hosted fixture posture should have been explicit before the first smoke run:
  existing site terrain must not be used for validation edits.

### Early-Visible Signals For Future Estimates

- Shared panels with hidden/inactive controls need tests for partial valid
  updates and inactive blank fields, not only whole-form validity.
- Slider plus exact numeric input requirements should be treated as a small UI
  mapping design problem, especially when direct numeric input can exceed slider
  range.
- Hosted terrain UI smoke should create an isolated temporary managed terrain
  fixture by default unless the task explicitly asks to validate existing model
  terrain.

### Future Retrieval Lesson

Use this task as an analog for SketchUp-hosted shared-tool panels over existing
command-backed terrain behavior. It is not a terrain-kernel analog; the dominant
actual complexity was UI state synchronization, partial invalid input, and
hosted smoke procedure.
<!-- SIZE:DELTA:END -->

---

<!-- SIZE:TAGS:START -->
## Retrieval Tags

- `archetype:feature`
- `scope:managed-terrain`
- `unclassified:sketchup-ui`
- `systems:command-layer`
- `systems:scene-mutation`
- `systems:packaging`
- `systems:docs`
- `validation:hosted-smoke`
- `host:special-scene`
- `host:single-fix-loop`
- `contract:no-public-shape-change`
- `contract:finite-options`
- `risk:partial-state`
- `risk:visibility-semantics`
- `volatility:medium`
- `friction:medium`
- `rework:medium`
- `confidence:high`
<!-- SIZE:TAGS:END -->
