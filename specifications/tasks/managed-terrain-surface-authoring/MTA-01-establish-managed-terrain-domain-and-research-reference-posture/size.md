# Size: MTA-01 Establish Managed Terrain Domain And Research Reference Posture

**Task ID**: `MTA-01`  
**Title**: Establish Managed Terrain Domain And Research Reference Posture  
**Status**: `calibrated`
**Created**: 2026-04-24  
**Last Updated**: 2026-04-25

**Related Task**: [task.md](./task.md)  
**Related Plan**: [plan.md](./plan.md)
**Related Summary**: [summary.md](./summary.md)

---

<!-- SIZE:IDENTITY:START -->
## Identity

- **Task Archetype**: platform
- **Primary Scope Area**: managed terrain domain and research reference posture
- **Likely Systems Touched**:
  - terrain specification language
  - research reference normalization
  - domain boundary naming
  - MCP public/internal contract guidance
- **Validation Class**: standard
- **Likely Analog Class**: capability domain grounding before implementation

### Identity Notes
- Early documentation and boundary-setting task that constrains later implementation without directly changing runtime behavior.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 1 | Sets terminology and constraints; no user-facing runtime capability by itself. |
| Technical Change Surface | 1 | Likely limited to specification artifacts and research posture. |
| Hidden Complexity Suspicion | 2 | Requires keeping Unreal references useful while preventing them from becoming public tool design. |
| Validation Burden Suspicion | 1 | Proven mainly through review against PRD/HLD and repo guidance. |
| Dependency / Coordination Suspicion | 1 | Depends on existing PRD/HLD agreement and source-reference interpretation. |
| Scope Volatility Suspicion | 2 | Domain language can shift if later implementation reveals naming or boundary issues. |
| Confidence | 3 | Task shape is relatively bounded, but some research normalization judgment remains. |

### Early Signals
- The task is intentionally pre-runtime and should not invent public MCP tool names.
- Existing hardscape and terrain boundaries must stay explicit.
- UE reference material is informative, not normative.

### Early Estimate Notes
- Seed reflects a bounded architecture/specification task with moderate ambiguity around reference posture.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

> Filled during task planning. This is the main pre-implementation estimate.

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | 2 | Establishes domain vocabulary and research posture for the MTA task line, but does not add runtime capability. |
| Technical Change Surface | 2 | Touches multiple specification/task artifacts and curates a research note, with no Ruby runtime surface. |
| Implementation Friction Risk | 2 | Main friction is editorial precision: trimming the UE guide without losing useful references or creating stale links. |
| Validation Burden Risk | 2 | Requires positive/negative text checks and link posture review, not runtime tests. |
| Dependency / Coordination Risk | 2 | Depends on PRD, HLD, domain analysis, task README, and existing public-contract guidance remaining aligned. |
| Discovery / Ambiguity Risk | 2 | Step 5 resolved the major ambiguity around guide curation and lifecycle scope, but wording still needs care. |
| Scope Volatility Risk | 2 | Could expand if the curated note starts preserving too much HLD/PRD content or if lifecycle wording grows. |
| Rework Risk | 2 | Rework likely if source-of-truth docs retain stale conflict/open-question language after domain updates. |
| Confidence | 3 | The plan is bounded and reviewed; remaining uncertainty is tactical documentation wording. |

### Top Assumptions
- The original UE guide contains enough useful research pointers to curate into a smaller note without preserving its blank-state HLD/PRD content.
- `domain-analysis.md` is the correct source for shared Managed Terrain Surface vocabulary.
- HLD and task README should be the primary links to the curated UE research note; PRD linkage can remain light.
- No runtime or public MCP contract files need to change for this task.

### Estimate Breakers
- The team decides to preserve the full original UE guide in active docs, requiring broader deconfliction with HLD/PRD content.
- Domain analysis needs a richer state model than lightweight lifecycle mapping before MTA-02.
- Link validation exposes more references to the root UE guide than the current search found.
- Review decides the PRD should own more UE reference posture than the plan currently assumes.

### Predicted Signals
- The task spans several documentation artifacts but has no code implementation surface.
- Grok 4.20 review reduced risk by narrowing lifecycle language and recommending guide curation over relocation.
- Public contract risk is controlled by explicit negative checks against UE-style public terrain tool names.
- The strongest validation evidence will be text/link checks plus manual review of source-of-truth hierarchy.

### Predicted Estimate Notes
- Predicted size is moderate for a docs/spec task because the primary challenge is preserving useful research while removing misleading authority. The absence of runtime changes keeps implementation friction below feature-task levels.
<!-- SIZE:PREDICTED:END -->

---

<!-- SIZE:CHALLENGE:START -->
## Challenge Review

> Filled when the estimate is pressure-tested through external review, premortem, or controlled consensus.

### Agreed Drivers
- The task remains documentation/specification-only with no runtime or public MCP contract surface.
- The main work driver is source-of-truth cleanup across domain analysis, HLD, PRD, task README, and the curated UE research note.
- Grok 4.20 review and the premortem agree that lifecycle wording and UE guide curation are the two main risk drivers.
- Validation is text/link/review based, not Ruby runtime or SketchUp-hosted behavior.

### Contested Drivers
- The original predicted profile may slightly understate rework risk if the old root guide has more hidden references than current searches found.
- The curation scope is sensitive: trimming too little keeps drift risk alive, while trimming too much could remove useful UE source pointers for MTA-04 through MTA-06.
- PRD update scope should remain light; over-editing product requirements to discuss UE research would increase documentation coupling.

### Missing Evidence
- Final repo-wide link check after the root guide is removed or replaced.
- Final manual review of the curated UE note to confirm it no longer reads as an HLD, PRD, repo layout, public MCP contract, or Ruby class/module design.
- Final source-of-truth review confirming PRD/HLD open-question language no longer says Managed Terrain Surface is missing from the domain model.

### Recommendation
- Keep the predicted scores unchanged. Implement as one bounded documentation task, but treat guide curation and negative public-tool-name checks as required acceptance evidence rather than optional cleanup.

### Challenge Notes
- The premortem did not justify resizing or splitting the task. It converted the main risks into concrete validation checks and reinforced that exact lifecycle state machine/storage details must remain deferred to `MTA-02`.
<!-- SIZE:CHALLENGE:END -->

---

<!-- SIZE:DRIFT:START -->
## Drift Log

> Append only. Log only material changes that affect estimate shape, risk, confidence, or validation burden.

No material drift recorded yet.
<!-- SIZE:DRIFT:END -->

---

<!-- SIZE:ACTUAL:START -->
## Actual Profile

> Filled at the end of implementation. Do not overwrite predicted values.

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | 2 | Shipped the planned domain vocabulary and research-posture change without adding runtime behavior. |
| Technical Change Surface | 2 | Touched domain analysis, HLD, PRD, task README, plan metadata, task status, summary, size calibration, and a new curated research note. |
| Actual Implementation Friction | 1 | Work stayed straightforward once the user confirmed docs checks should remain shell-based rather than Ruby unit tests. |
| Actual Validation Burden | 1 | Validation was focused docs-posture `rg`/`test` checks plus `git diff --check` and Grok codereview; no runtime, package, or hosted SketchUp validation was needed. |
| Actual Dependency Drag | 2 | Required alignment across PRD, HLD, domain analysis, task README, task metadata, and the research note. |
| Actual Discovery Encountered | 1 | Discovery confirmed the planned stale-link and missing-domain shape; no new architecture or runtime questions appeared. |
| Actual Scope Volatility | 1 | Scope stayed docs-only; the only process change was replacing proposed permanent docs tests with recorded shell checks. |
| Actual Rework | 1 | Minor closeout rewording was needed to keep the old guide filename out of final source docs; no implementation rework was required. |
| Final Confidence in Completeness | 4 | Validation and codereview confirmed the docs-only posture, source-of-truth hierarchy, and no-public-contract boundary. |

### Actual Notes
- The implementation matched the predicted documentation/specification-only scope.
- The only process adjustment was using shell validation commands for documentation posture instead of permanent Ruby unit tests, per user direction.
- No material estimate drift required a drift-log entry.
<!-- SIZE:ACTUAL:END -->

---

<!-- SIZE:VALIDATION-EVIDENCE:START -->
## Validation Evidence Summary

- Baseline checks before edits confirmed:
  - `Managed Terrain Surface` was absent from `specifications/domain-analysis.md`.
  - `specifications/research/managed-terrain/ue-reference-phase1.md` did not exist.
  - the HLD still linked to the former root-level UE guide.
  - PRD/HLD language still said the domain term was missing.
- Post-implementation docs checks passed:
  - `rg -n "Managed Terrain Surface" specifications/domain-analysis.md`
  - `rg -n "non-normative|research-only|UE Inspection Cadence|MTA-04|MTA-05|MTA-06" specifications/research/managed-terrain/ue-reference-phase1.md`
  - the former root-level UE terrain guide was absent.
  - repo-wide stale-reference search under `specifications/` returned no matches for the former root-level UE terrain guide.
  - `rg -n "not yet listed|currently lacks Managed Terrain Surface|Should the domain analysis add Managed Terrain Surface" specifications/prds/prd-managed-terrain-surface-authoring.md specifications/hlds/hld-managed-terrain-surface-authoring.md` returned no matches.
  - `rg -n "terrain\.create_surface|terrain\.flatten|terrain\.smooth|terrain\.ramp|src/su_mcp/terrain|TerrainRepository|TerrainEngine|TerrainGeometryAdapter|TerrainCommand" specifications/domain-analysis.md specifications/hlds/hld-managed-terrain-surface-authoring.md specifications/prds/prd-managed-terrain-surface-authoring.md specifications/tasks/managed-terrain-surface-authoring/README.md specifications/research/managed-terrain/ue-reference-phase1.md` returned no matches.
  - `git diff --check` passed.
- Grok 4.20 codereview found no critical, high, medium, or low issues.
- Ruby runtime tests, lint, package verification, and live SketchUp verification were not run because no Ruby runtime, public MCP contract, package, or SketchUp-hosted behavior changed.
<!-- SIZE:VALIDATION-EVIDENCE:END -->

---

<!-- SIZE:DELTA:START -->
## Estimation Delta Review

- Prediction was accurate: the task remained a bounded documentation/specification implementation with no runtime or public MCP contract surface.
- Validation burden was slightly lower than the original plan implied after the user clarified that permanent Ruby documentation tests were not desired.
- Coordination risk was correctly estimated: the main work was keeping domain analysis, HLD, PRD, task README, task metadata, and research note posture aligned.
- Future similar tasks should prefer recorded shell-based docs-posture checks over permanent Ruby tests unless the repository establishes a formal documentation contract suite.
<!-- SIZE:DELTA:END -->

---

<!-- SIZE:TAGS:START -->
## Retrieval Tags

- `archetype:docs-specs`
- `scope:managed-terrain`
- `scope:docs-specs`
- `systems:docs`
- `validation:docs-check`
- `host:not-needed`
- `volatility:low`
- `friction:low`
- `rework:low`
- `confidence:high`
<!-- SIZE:TAGS:END -->
