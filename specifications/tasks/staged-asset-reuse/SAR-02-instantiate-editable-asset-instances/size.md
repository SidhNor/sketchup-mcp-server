# Size: SAR-02 Instantiate Editable Asset Instances

**Task ID**: `SAR-02`
**Title**: `Instantiate Editable Asset Instances`
**Status**: `calibrated`
**Created**: `2026-04-25`
**Last Updated**: `2026-05-15`

**Related Task**: [task.md](./task.md)
**Related Plan**: [plan.md](./plan.md)
**Related Summary**: [summary.md](./summary.md)

---

<!-- SIZE:IDENTITY:START -->
## Identity

- **Task Archetype**: feature
- **Primary Scope Area**: staged asset reuse instantiation
- **Likely Systems Touched**:
  - `instantiate_staged_asset` MCP command and native tool registration
  - Asset Exemplar resolver and approval checks
  - Asset Instance creation behavior
  - model-root placement and scalar scale handling
  - lean source asset lineage metadata
  - Managed Scene Object metadata integration
  - asset result serialization and tests
  - native contract fixtures and tool docs
- **Validation Class**: mixed
- **Likely Analog Class**: hosted scene creation with metadata lineage

### Identity Notes
- Instantiation is the first mutating asset-reuse slice and must prove that Asset Instances are separate editable scene objects rather than mutated exemplars. Planning narrowed the slice to scalar scale, model-root creation, lean lineage, no `metadata.status`, and no broad source snapshot.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Adds a new mutating reuse workflow from approved exemplar to editable scene instance. |
| Technical Change Surface | 3 | Touches staged asset command behavior, metadata, creation, serialization, runtime schema/routing, native fixtures, tests, and docs. |
| Hidden Complexity Suspicion | 2 | Planning resolved scale, identity, lineage, and asset attribute policy; group-copy/root-placement remains the main hidden host seam. |
| Validation Burden Suspicion | 3 | Needs no-exemplar-mutation checks, lineage checks, placement evidence, refusal paths, schema-description coverage, native contracts, and normal SketchUp smoke. |
| Dependency / Coordination Suspicion | 2 | Depends on `SAR-01` metadata and approval semantics plus existing managed-object and targeting foundations. |
| Scope Volatility Suspicion | 2 | Replacement, target-height fitting, parent placement, vector scale, and status were explicitly excluded, lowering expansion pressure. |
| Confidence | 3 | Draft plan resolves the main product and contract decisions; confidence remains below very strong because group-copy behavior is host-sensitive. |

### Early Signals
- The PRD requires Asset Instances to retain source lineage and stop being treated as exemplars.
- Prior hosted semantic behavior analogs show live SketchUp proof is important for placement and no-partial-state confidence.
- Replacement is explicitly excluded to keep this slice focused.
- Refined task shape requires native schema descriptions, contract fixtures, docs, and normal component/group smoke in addition to command tests.

### Early Estimate Notes
- Seed was refreshed during planning after scope narrowed to model-root creation, scalar scale, lean lineage, category-specific `assetAttributes`, and no `metadata.status`.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

> Filled during task planning. This is the main pre-implementation estimate.

| Dimension | Score (0-4) | Rationale |
|---|---:|---|
| Functional Scope | 3 | Adds a new first-class mutating MCP workflow from approved Asset Exemplar to editable Asset Instance, with component and group source support. |
| Technical Change Surface | 3 | Requires staged asset metadata/creator/serializer/command changes plus native catalog, dispatcher, facade/factory checks, native fixtures, docs, and test support. |
| Implementation Friction Risk | 2 | Most policy decisions are resolved, but group-copy/root-placement, metadata cleanup, and unit conversion can create contained implementation resistance. |
| Validation Burden Risk | 3 | Validation spans command behavior, public schema descriptions, native contract preservation, no-exemplar-mutation checks, operation abort paths, and normal SketchUp smoke. |
| Dependency / Coordination Risk | 2 | Depends on SAR-01 metadata/listing, target resolution, managed-object metadata conventions, and runtime contract surfaces, but no external service dependency. |
| Discovery / Ambiguity Risk | 1 | Major product and contract ambiguities are resolved; only tactical group-copy placement mechanics remain. |
| Scope Volatility Risk | 2 | Explicit non-goals reduce expansion, but asset reuse can pull toward replacement, tagging, parent placement, and richer scale semantics if not held. |
| Rework Risk | 2 | Contract/schema/docs drift or copied exemplar metadata leakage could force revisiting completed slices, but planned phase ordering limits blast radius. |
| Confidence | 3 | Draft plan is concrete and analog-informed; confidence is not 4 because host group-copy behavior and operation rollback are not proven yet. |

### Top Assumptions

- `sourceAssetElementId` is sufficient persisted lineage for SAR-02 and SAR-04 can build on it without broad source snapshots.
- Scalar-only scale is enough for the first instantiation slice.
- `semanticType: "asset_instance"` is acceptable for editable managed instances and will not conflict with existing semantic validation.
- Group copy/root placement can be handled behind the staged-assets-owned creator without changing the public contract.
- Existing runtime routing patterns can absorb one new staged asset tool without structural runtime changes.

### Estimate Breakers

- If group exemplars cannot be copied/root-placed without a broader clone/rebuild path, implementation friction and validation burden increase.
- If validators or serializers reject `semanticType: "asset_instance"` unexpectedly, metadata integration and rework increase.
- If SAR-04 requires richer persisted lineage before SAR-02 lands, scope volatility increases.
- If native schema descriptions require wider contract harmonization beyond this tool, technical change surface increases.
- If operation abort does not clean partial instances in host smoke, validation and rework increase.

### Predicted Signals

- Public tool addition with schema, dispatcher, facade, fixture, docs, and example updates.
- Host-sensitive scene mutation with components, groups, placement, scale, metadata writes, and undo behavior.
- Existing SAR-01 JSON-backed `assetAttributes` reduces metadata unknowns but adds persistence discipline.
- Related analogs suggest public contract slices are often dominated by parity tests and live-host mismatch checks.
- User decisions narrowed the task away from target-height fitting, status, vector scale, parent placement, and broad source snapshots.

### Predicted Estimate Notes

- This is a high-surface but bounded feature slice. The main estimate pressure is not recommendation logic or asset search; it is public contract completeness plus safe host mutation.
- Validation burden is scored high because correctness must be proven across command behavior, schema descriptions, response shape, and component/group host behavior, not because a routine SketchUp smoke alone is expensive.
- Prediction reflects the Step 10 draft plan before premortem.
<!-- SIZE:PREDICTED:END -->

---

<!-- SIZE:CHALLENGE:START -->
## Challenge Review

> Filled when the estimate is pressure-tested through external review, premortem, or controlled consensus.

### Agreed Drivers

- Functional Scope remains `3`: SAR-02 is one bounded public workflow, but it must support both component-instance and group exemplars and produce editable managed Asset Instances.
- Technical Change Surface remains `3`: implementation touches staged asset metadata, creation, serialization, command orchestration, native catalog schema, dispatcher/facade/factory routing, public fixtures, docs, and test support.
- Validation Burden Risk remains `3`: the expensive part is not the number of smoke cases alone; it is proving no source mutation, no exemplar metadata leakage, correct identity semantics, public schema descriptions, operation failure behavior, and live component/group host behavior.
- Implementation Friction Risk remains `2`: group-copy/root-placement and metadata cleanup are real host-sensitive seams, but the public contract can stay stable while a staged-assets-owned creator absorbs the mechanics.
- Scope Volatility Risk remains `2`: premortem confirmed pressure toward replacement, parent placement, tagging, generated identity, target-height fitting, and richer scale, but the finalized plan explicitly excludes them.

### Contested Drivers

- Downstream lineage sufficiency is the main contested driver. The plan intentionally persists only `sourceAssetElementId`; this is acceptable for SAR-02, but SAR-04 must prove it can resolve needed replacement context from that key plus staged-asset listing/source evidence.
- Group copy rollback remains unproven in live SketchUp. This does not resize the prediction now, but a failed smoke could raise implementation friction or rework.
- `semanticType: "asset_instance"` compatibility with existing managed-object assumptions is plausible but not yet proven by implementation tests.

### Missing Evidence

- Live SketchUp smoke for approved component-instance instantiation and approved group exemplar instantiation.
- Evidence that copied groups are rewritten as Asset Instances and are not rediscovered by `list_staged_assets`.
- Evidence that component-instance metadata is written to the created wrapper and not to the shared definition or source wrapper.
- Evidence that operation abort prevents expected partial instance state on creation or metadata-write failure.
- SAR-04-facing check that lean persisted lineage is sufficient before replacement behavior starts.

### Recommendation

- Confirm the predicted scores. Do not split before implementation.
- Implement in the planned order: metadata/serializer first, creator/command second, runtime contract third, docs/smoke last.
- Treat failed group-copy/root-placement smoke, failed operation rollback, or SAR-04 lineage insufficiency as estimate breakers rather than broadening SAR-02 preemptively.

### Challenge Notes

- Premortem produced no unresolved Tigers. The plan was strengthened with targeted `missing_required_metadata` and `unapproved_exemplar` contract fixtures, explicit `metadata.sourceElementId` ownership guardrails, copied-group metadata rewrite smoke, and a SAR-04 lineage sufficiency gate.
- No predicted-score change is justified because the new controls clarify validation rather than expanding public behavior or implementation scope.
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

| Dimension | Score (0-4) | Rationale |
|---|---:|---|
| Functional Scope | 3 | Shipped a new mutating public MCP workflow for editable Asset Instance creation from approved exemplars, including identity, lineage, placement, scale, and source evidence. |
| Technical Change Surface | 3 | Touched staged asset command orchestration, new creator/metadata/serializer collaborators, native catalog schema, dispatcher/facade/factory wiring, fixtures, docs, and test support. |
| Actual Implementation Friction | 3 | Component instantiation initially lost curated instance transforms, group copying exposed host-sensitive behavior, and review found transient-copy cleanup needed stronger exception safety. |
| Actual Validation Burden | 3 | Validation exceeded baseline through live catalogue curation, component transform inspection, one unsafe group-copy host issue, and a follow-up safe group smoke. It was material, but not a validation-dominated closeout. |
| Actual Dependency Drag | 2 | Depended on SAR-01 metadata semantics, live SketchUp deployment, connector tool availability, and user-provided staged asset scene state. |
| Actual Discovery Encountered | 3 | Live validation revealed definition-versus-instance transform semantics, unsafe group exact-copy behavior, and corrected catalogue metadata expectations for represented species and usage hints. |
| Actual Scope Volatility | 1 | Public contract and accepted workflow stayed stable. The exact-copy group path was replaced by the planned safe creation posture, and complex group fidelity remained a follow-up validation gap rather than a task-boundary change. |
| Actual Rework | 1 | Follow-up was quick and contained: component transform preservation, safe group-copy mechanics, and transient cleanup were corrected during normal review/live-check closeout without broad slice revisiting. |
| Final Confidence in Completeness | 3 | Component path, public contract, metadata, docs, and simple group smoke are strong; confidence is capped by unexpanded complex group fidelity coverage. |

### Actual Notes

- Dominant actual failure mode: live SketchUp host semantics differed from fake expectations around instance transforms and group copy APIs.
- The implementation is complete for the public tool and live-verified for component-instance exemplars, including the low-poly vegetation library path.
- Group exemplar support is live-verified for a simple primitive group through the production explicit reconstruction path after an unsafe exact-copy approach was removed.
<!-- SIZE:ACTUAL:END -->

---

<!-- SIZE:VALIDATION-EVIDENCE:START -->
## Validation Evidence Summary

- `bundle exec rake ci` passed after final code-review fix:
  - RuboCop: 340 files inspected, no offenses.
  - Ruby tests: `1385 runs, 15328 assertions, 0 failures, 40 skips`.
  - Package verification produced `dist/su_mcp-1.8.0.rbz`.
- Focused creator regression passed after transient-copy cleanup: `6 runs, 18 assertions, 0 failures`.
- External code review via `mcp__pal__.codereview` using `grok-4.3` completed.
  - Fixed review finding: transient component copy cleanup now runs in `ensure`.
  - Dispositioned review finding: group-host live verification remains incomplete and is recorded as a follow-up.
- Live SketchUp validation:
  - 24 low-poly vegetation component exemplars curated with catalogue-backed `representedSpecies` and `usageHints`.
  - Component instantiation of bamboo succeeded with lineage, managed instance identity, source exemplar stability, exemplar-list exclusion, and transform/scale preservation.
  - Group exact-copy smoke using `add_group(existing_entities)` crashed SketchUp; that production path was removed.
  - Safe group instantiation through explicit reconstruction passed for a temporary group with 12 edges and 6 faces, lineage/managed metadata, `scale: 1.1`, source stability, and zero cleanup remnants.
- Validation classification: repeated fix/redeploy/rerun loops with one initially blocked hosted group matrix item that was narrowed to advanced group-fidelity follow-up.
<!-- SIZE:VALIDATION-EVIDENCE:END -->

---

<!-- SIZE:DELTA:START -->
## Estimation Delta Review

### What The Prediction Got Right

- Technical surface and functional scope were accurately high-surface but bounded.
- Validation burden was correctly predicted as high because public contract, metadata, source mutation safety, and live SketchUp behavior all had to align.
- Group copy/root placement was correctly identified as the main host-sensitive risk.

### What Was Underestimated

- Implementation friction was underestimated: component instantiation had to preserve curated instance transforms rather than only add the source definition at a new transform.
- Validation burden was accurately material but over-scored at the top end in the original calibration: live host checks required transform inspection, curation metadata correction, a group-copy crash investigation, and a safe group rerun, but did not dominate delivery.

### What Was Overestimated

- Public contract ambiguity stayed lower than feared. The final API shape held: model-root placement, scalar scale, caller-supplied instance identity, and lean lineage.
- Runtime wiring remained straightforward once the command behavior stabilized.
- Rework was over-scored in the original calibration: review and live smoke produced real but quick contained fixes, not meaningful revisiting of completed slices.

### Future Estimation Lessons

- For SketchUp instantiation tasks, distinguish definition-level creation from copying a curated instance wrapper; instance transforms may carry the real asset scale/orientation.
- Treat live group-copy validation as a separate risk class from component instantiation even when both share the same public tool; simple group smoke does not prove advanced material/UV/softening fidelity.
- Asset metadata examples in a task can become required live-library metadata when the scene uses a numbered catalogue; verify catalogue fields before curation.
- Hosted validation should be scored by retest-loop and blocker cost, not by the number of smoke cases.

### Final Calibration

- Actual task shape stayed inside the planned public workflow. The main lesson is to treat quick host-check corrections as contained follow-up unless they force meaningful slice rework.
- Final confidence is medium-high for SAR-02 component-instance workflows, simple group workflows, and public contract alignment, but lower for complex group exemplar fidelity until richer hosted smoke coverage is added.
<!-- SIZE:DELTA:END -->

---

<!-- SIZE:TAGS:START -->
## Retrieval Tags

- `archetype:feature`
- `scope:staged-asset-reuse`
- `systems:asset-metadata`
- `systems:scene-mutation`
- `systems:managed-object-metadata`
- `systems:serialization`
- `systems:loader-schema`
- `contract:public-tool`
- `contract:native-fixture`
- `validation:hosted-smoke`
- `risk:partial-state`
- `risk:metadata-storage`
- `risk:transform-semantics`
- `risk:hosted-group-copy`
- `risk:live-validation-loop`
- `confidence:medium`
<!-- SIZE:TAGS:END -->
