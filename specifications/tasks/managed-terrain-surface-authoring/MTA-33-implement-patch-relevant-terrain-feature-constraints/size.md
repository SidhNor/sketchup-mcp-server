# Size: MTA-33 Implement Patch-Relevant Terrain Feature Constraints

**Task ID**: `MTA-33`
**Title**: `Implement Patch-Relevant Terrain Feature Constraints`
**Status**: `calibrated`
**Created**: `2026-05-09`
**Last Updated**: `2026-05-10`

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
  - `systems:terrain-state`
  - `systems:terrain-kernel`
  - `systems:public-contract`
- **Validation Modes**:
  - `validation:performance`
  - `validation:contract`
  - `validation:regression`
- **Likely Analog Class**: patch-relevant feature selection for local CDT terrain output

### Identity Notes
- Seeded from MTA-31 effective feature view closeout and the external review finding that hard constraints should be spatially owned rather than globally included in every local solve.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 2 | Internally changes CDT input relevance for local patch solves without public tool or response changes. |
| Technical Change Surface | 3 | Likely touches effective feature selection, feature geometry preparation, CDT input diagnostics, and no-leak tests. |
| Hidden Complexity Suspicion | 4 | Hard-feature semantics are subtle: far hard features must be excluded without silently weakening touched or protecting constraints. |
| Validation Burden Suspicion | 3 | Needs cardinality, hard/protected behavior, stale-index, and public no-leak proof; hosted evidence may be needed for representative feature-heavy cases. |
| Dependency / Coordination Suspicion | 3 | Depends on MTA-31 feature lifecycle/effective state and MTA-32 patch-domain shape. |
| Scope Volatility Suspicion | 3 | May grow if patch relevance requires a durable spatial index or protected-region expansion policy broader than expected. |
| Confidence | 3 | The task boundary is narrower than MTA-31, but hard constraint relevance rules still need careful proof. |

### Early Signals
- MTA-31 fixed active/effective feature state but still showed hard-feature pressure can dominate local CDT inputs.
- External review explicitly recommends including hard constraints only when they intersect, protect, constrain, or neighbor the local patch.
- This task intentionally avoids rewriting feature lifecycle/indexing and focuses on CDT patch input selection.
- Public contract stability remains a hard constraint.

### Early Estimate Notes
- Use MTA-31 as the closest analog for feature-intent and no-leak behavior, but this task has a narrower scope and a sharper semantic risk around hard-feature exclusion.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

> Filled during task planning. This is the main pre-implementation estimate.

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | 2 | Moderate internal behavior change for local CDT feature relevance; public workflows and contracts stay unchanged. |
| Technical Change Surface | 3 | Touches effective feature selection integration, feature geometry preparation, CDT participation/fallback wiring, diagnostics, and contract tests. |
| Implementation Friction Risk | 3 | Hard/protected geometry semantics, primitive normalization, `SampleWindow` shape handling, and fallback propagation can resist a naive selector. |
| Validation Burden Risk | 3 | Requires selector unit tests, planner/command integration, no-leak contracts, cardinality/performance fixture evidence, and possible hosted validation gate. |
| Dependency / Coordination Risk | 2 | Depends on MTA-31 and MTA-32 semantics but does not require new external service, public schema, or SketchUp packaging coordination. |
| Discovery / Ambiguity Risk | 2 | Major Step 06 ambiguities are resolved; tactical unknowns remain around helper shape and exact fixture thresholds. |
| Scope Volatility Risk | 2 | Scope is bounded by no public contract delta and no MTA-34 seam work; volatility rises if a persistent spatial index or public fallback surface becomes necessary. |
| Rework Risk | 3 | Prior MTA-31/MTA-32 analogs suggest review-driven hardening is likely around no-leak behavior, stale windows, and feature-cardinality evidence. |
| Confidence | 3 | Evidence is strong enough for a bounded plan, with calibrated analogs and local code seams identified; confidence remains medium-high until fixtures prove margin and fallback behavior. |

### Top Assumptions
- `EffectiveFeatureView` can remain the active/lifecycle owner while a downstream selector handles patch relevance.
- Lightweight owner-local primitive normalization is sufficient for point, rectangle/circle, segment, and corridor relevance without a persistent spatial index.
- Existing non-CDT terrain output remains the correct fallback path for otherwise valid edits when CDT participation is skipped.
- Public responses are already sanitized enough that additional internal diagnostics can be attached without response-shape drift when covered by tests.

### Estimate Breakers
- Selector relevance cannot be made consistent with `TerrainFeatureGeometryBuilder` without a broader geometry refactor.
- Local cardinality fixtures show the two-sample margin misses seam-relevant hard/protected geometry, requiring wider-margin policy or patch expansion work.
- Budget overflow cannot be represented as internal missed-locality diagnostics without changing public fallback vocabulary.
- Command integration reveals valid-edit CDT skip currently routes through public refusal semantics.
- Hosted evidence exposes SketchUp-specific coordinate or persistence behavior that local Ruby fixtures cannot model.

### Predicted Signals
- MTA-31 actuals showed feature-heavy local edits can still select most active hard features after effective lifecycle filtering.
- MTA-32 actuals showed patch-local CDT work needs topology/fallback/no-leak evidence and must keep validation-only surfaces out of production behavior.
- The plan touches multiple related runtime seams but avoids public schema, dispatcher, README, packaging, and default-enable changes.
- User clarification removed public refusal as an acceptable output for valid edits, increasing fallback-path specificity.
- The selected approach leaves MTA-34 replacement seams out of scope, reducing volatility.

### Predicted Estimate Notes
- Closest analog is MTA-31 for feature lifecycle, effective selection, no-leak, and hosted/cardinality proof. MTA-33 is narrower but semantically sharper around hard/protected exclusion.
- MTA-32 is the secondary analog for patch-domain, fallback, and internal proof boundaries. This task consumes its patch concepts without taking on production patch replacement.
- Validation burden is scored high-moderate because correctness requires proving both exclusion of far features and non-weakening of touched/protected features, plus public no-leak stability.
- Dependency risk is moderate rather than high because upstream tasks are implemented and no new external runtime or public contract coordination is planned.
<!-- SIZE:PREDICTED:END -->

---

<!-- SIZE:CHALLENGE:START -->
## Challenge Review

> Filled when the estimate is pressure-tested through external review, premortem, or controlled consensus.

### Agreed Drivers
- Functional scope remains moderate because behavior changes are internal to local CDT feature
  relevance and public terrain workflows stay unchanged.
- Technical surface remains high-moderate because the implementation crosses selector,
  planner, geometry, CDT participation, diagnostics, command, and contract-test seams.
- Validation burden remains high-moderate because success requires both locality proof and
  hard/protected non-weakening proof, not just ordinary unit coverage.
- Dependency risk remains moderate because MTA-31/MTA-32 are implemented and no public schema or
  external runtime coordination is planned.

### Contested Drivers
- Cardinality success was too qualitative in the draft plan; premortem added a representative
  fixture threshold of at least 40% hard-feature count reduction while preserving touched hard
  features.
- Window normalization was underweighted because `SampleWindow`/hash/patch-domain mismatch caused
  prior selection drift; premortem added a pre-selector normalization contract test.
- Repeated CDT skip behavior was not explicitly tested for cache or dirty-region growth; premortem
  added a multi-edit sequence validation.
- On-demand O(n) selection remains an accepted scaling risk; evidence must show it reduces CDT
  input without becoming the dominant local-edit cost.
- Explicit hard-feature mutual dependencies are not evidenced in current research, but if found
  during implementation they become selector inclusion or internal CDT-skip input.

### Missing Evidence
- Local fixture evidence for the 40% hard-feature reduction threshold.
- Runtime evidence that the two-sample margin captures seam-relevant touched/protected hard
  geometry.
- Evidence that repeated CDT skips do not grow dirty/cache scope beyond existing non-CDT behavior.
- Hosted validation remains conditional on local fixtures failing to prove representative
  exclusion, no-leak behavior, and public edit success.

### Recommendation
- Confirm the predicted scores. The premortem sharpened validation requirements but did not change
  the task boundary or introduce a public contract delta. Resize or split only if implementation
  proves a persistent spatial index, public fallback surface, or MTA-34 seam behavior is required.

### Challenge Notes
- Challenge inputs used: Step 06 model consensus, draft plan review, premortem challenge, and
  `grok-4.3` failure-analysis critique.
- No predicted score changes were made. The added tests and threshold fit the existing
  Validation Burden Risk `3`, Rework Risk `3`, and Confidence `3` profile.
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
| Functional Scope | 2 | Delivered the planned internal behavior change: patch-relevant CDT feature selection, internal CDT participation gating, and full-grid preservation. Public tools, schemas, and workflows stayed unchanged. |
| Technical Change Surface | 3 | Crossed multiple related runtime layers: selector, feature planner, feature geometry input, mesh-generator CDT eligibility, command integration tests, contract tests, and task metadata. |
| Actual Implementation Friction | 2 | The planned seams held, but implementation still had contained resistance around unsupported/touched hard geometry, selected-budget fallback, feature-geometry failure gating, and no-leak propagation. No redesign or persistent index was needed. |
| Actual Validation Burden | 3 | Validation required a special hosted side-scene matrix, owner-local visual overlays, cardinality proof, public no-leak checks, full suite, lint, and package verification. This is scored high because of special setup and interpretation, not because there were six hosted cases. |
| Actual Dependency Drag | 2 | Delivery depended on MTA-31 effective lifecycle semantics, MTA-32 patch-domain/debug proof concepts, and a live SketchUp host for acceptance evidence, but no upstream API, public schema, or external team blocked the work. |
| Actual Discovery Encountered | 2 | Discovery was moderate and bounded: hosted fixtures exposed setup realities around unsupported preserve polygons, x=50m owner-local placement, and visual CDT overlay placement, without changing core requirements. |
| Actual Scope Volatility | 1 | The task shape stayed stable. Hosted visual proof expanded closeout evidence, but the implementation did not absorb MTA-34 patch replacement, public controls, default CDT enablement, or a spatial index. |
| Actual Rework | 1 | Post-review rework was small and local: one survey-window selector regression plus a private helper rename. The broader hosted fixture work was validation evidence, not rework of completed implementation. |
| Final Confidence in Completeness | 3 | Strong evidence supports completion: final automated validation passed, public no-leak behavior is covered, hosted fixtures exercised the matrix, and MTA-34 handoff is explicitly bounded. Confidence is not `4` because production-scale spatial indexing remains an accepted future risk and hosted checks were not rerun after non-behavioral review follow-up. |

### Actual Signals
- `PatchRelevantFeatureSelector` filters active effective features by dirty-window/patch relevance
  with the planned two-sample margin and full-grid all-active behavior.
- A command-level regression proves the CDT feature context receives selected feature geometry
  after MTA-33 filtering, which is the MTA-34 handoff path.
- The final review-requested survey-control regression proves features without payload geometry
  still use `relevanceWindow` for patch selection rather than silently falling through to global
  inclusion.
- Planner diagnostics include selected/excluded counts by strength and reason plus internal CDT
  fallback triggers.
- Unsupported or degenerate patch-relevant hard/protected geometry sets internal
  `cdtParticipation: skip`; valid public edits continue through existing terrain output.
- Hosted FX-04 reduced hard participation from 21 active hard features to 5 selected hard features
  for the local patch while preserving touched local hard features.
- Hosted FX-05 selected the touched unsupported hard polygon, excluded the far unsupported hard
  polygon, and skipped CDT internally without public edit refusal.

### Actual Notes
- No persistent feature spatial index was introduced; on-demand selection is accepted for MTA-33.
- No public MCP tool schema, response shape, or user-facing option set changed.
- Visual debug meshes rendered during hosted verification are inspection-only overlays and do not
  replace production terrain output.
- Hosted verification ran before the final PAL review follow-up. It was not rerun afterward because
  the follow-up changed only a selector regression test and a private helper name, not selector
  runtime behavior or SketchUp output semantics.
<!-- SIZE:ACTUAL:END -->

---

<!-- SIZE:VALIDATION-EVIDENCE:START -->
## Validation Evidence Summary

> Fill only the sections that are relevant. Say `not applicable` where needed.

### Automated Validation
- `bundle exec rake ruby:test`: 1280 runs, 12844 assertions, 0 failures, 0 errors, 37 skips.
- `RUBOCOP_CACHE_ROOT=tmp/.rubocop_cache bundle exec rake ruby:lint`: 315 files inspected, no offenses.
- `bundle exec rake package:verify`: produced `dist/su_mcp-1.6.1.rbz`.
- `git diff --check`: clean after closeout metadata update.

### Hosted / Manual Validation
- Six side fixtures were created in SketchUp at world `x = 50.0m` without touching existing terrain:
  `MTA-33-FX-01-hard-locality`, `MTA-33-FX-02-touched-protected`,
  `MTA-33-FX-03-firm-soft-locality`, `MTA-33-FX-04-cardinality`,
  `MTA-33-FX-05-unsupported-hard`, and `MTA-33-FX-06-full-grid-control`.
- Hosted planner diagnostics matched the matrix:
  FX-01 excluded far hard features; FX-02 selected touched protected geometry; FX-03 selected
  local/crossing firm-soft features and excluded far soft; FX-04 selected 5 of 21 active hard
  features; FX-05 selected touched unsupported hard, excluded far unsupported hard, and skipped CDT;
  FX-06 full-grid selected all active features.
- MTA-32-style visual debug overlays were rendered above the fixtures: magenta accepted CDT proof
  meshes for FX-01 through FX-04, orange skip marker for FX-05, and orange fallback proof mesh for
  FX-06 full-grid stress inspection.

### Performance Validation
- Local cardinality test and hosted FX-04 prove at least 40% hard-feature participation reduction
  for a small patch. Hosted FX-04 observed about 76% hard reduction, from 21 active hard features
  to 5 selected hard features.

### Migration / Compatibility Validation
- Public contract/no-leak tests cover feature-selection diagnostics, CDT participation, fallback
  trigger vocabulary, raw feature IDs, patch windows, and CDT internals.
- Existing stale effective-index and active-only lifecycle behavior remains covered by planner and
  effective-view tests.

### Operational / Rollout Validation
- CDT remains disabled by default. MTA-33 only narrows internal CDT input participation when a CDT
  feature context is prepared.
- Existing non-CDT output remains the fallback path for valid edits when CDT participation is
  skipped.

### Validation Notes
- Validation burden classification: special hosted side-scene matrix with interpretation, not a
  clean routine smoke. There was no repeated fix/redeploy/restart/rerun loop.
- The final post-review verification was automated because the review follow-up did not alter
  hosted runtime behavior. Commands rerun after the follow-up were the selector/planner/command
  tests, full Ruby suite, lint, package verification, and `git diff --check`.
- Hosted validation exceeded the plan's conditional minimum because the user requested explicit
  SketchUp fixtures and visual inspection geometry.
<!-- SIZE:VALIDATION-EVIDENCE:END -->

---

<!-- SIZE:DELTA:START -->
## Estimation Delta Review

> Filled during final calibration. Compare prediction to actual behavior.

- **Most Underestimated Dimension**: Hosted/manual validation detail, not core implementation.
  The plan anticipated possible hosted evidence, but final acceptance required a deliberate
  six-fixture side-scene matrix, x=50m meter placement, and MTA-32-style visual overlays.
- **Most Overestimated Dimension**: Rework and scope volatility. Predicted rework risk was `3`
  and volatility risk was `2`; actual rework was local review hardening, and the task did not need
  a spatial index, public fallback field, wider patch-margin policy, or MTA-34 replacement work.
- **Signal Present Early But Underweighted**: MTA-32 had already shown that patch-local CDT work
  benefits from visual proof geometry. That became directly reusable once the user asked to see
  CDT geometry rather than relying only on internal diagnostics.
- **Genuinely Unknowable Factor**: Hosted fixture construction exposed scene-level setup details:
  unsupported hard polygons needed internal injection, preserve-zone placement could make public
  edits non-representative, and proof meshes had to be owner-local overlays to be inspectable.
- **Future Similar Tasks Should Assume**: Patch-local terrain work with selector or CDT semantics
  should budget for three evidence layers: deterministic selector/planner tests, command-level
  proof that the selected context reaches CDT, and a hosted side-scene matrix when user acceptance
  depends on visual geometry.
- **Dominant Actual Failure Mode**: Under-evidenced locality and handoff. The highest risk was not
  that the selector could not be implemented; it was proving that far features were excluded,
  touched/protected features were retained or skipped safely, and selected feature geometry really
  reached the CDT feature context without leaking public diagnostics.
- **Future Retrieval Facets**: Retrieve this as a `scope:managed-terrain`,
  `archetype:performance-sensitive`, `validation:hosted-matrix`,
  `host:special-scene`, `contract:no-public-shape-change`, and
  `risk:performance-scaling` analog.

### Calibration Notes
- Functional scope and technical surface matched prediction. The planned behavior shipped at the
  intended internal boundary, but still crossed enough runtime layers to justify surface `3`.
- Implementation friction calibrated below prediction (`2` actual versus `3` predicted) because
  the existing planner, feature geometry, and CDT fallback seams supported the design without
  redesign.
- Validation burden stayed at `3`, but for a more precise reason than the prediction: special
  hosted setup and interpretation were required, while automated checks and review follow-up were
  clean after the final small fixes.
- Dependency drag matched prediction at `2`: MTA-31/MTA-32 were real semantic dependencies but did
  not block delivery.
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
- `validation:contract`
- `validation:hosted-matrix`
- `host:special-scene`
- `contract:no-public-shape-change`
- `risk:performance-scaling`
- `risk:unit-conversion`
- `friction:medium`
<!-- SIZE:TAGS:END -->
