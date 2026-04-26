# Size: SVR-02 Broaden validate_scene_update With Object-Anchor Surface-Offset Validation

**Task ID**: SVR-02  
**Title**: Broaden validate_scene_update With Object-Anchor Surface-Offset Validation  
**Status**: calibrated  
**Created**: 2026-04-24  
**Last Updated**: 2026-04-24  

**Related Task**: [task.md](./task.md)  
**Related Plan**: [plan.md](./plan.md)  
**Related Summary**: [summary.md](./summary.md)  

---

<!-- SIZE:IDENTITY:START -->
## Identity

- **Task Archetype**: validation-heavy feature
- **Primary Scope Area**: scene validation and review geometry relationships
- **Likely Systems Touched**:
  - `validate_scene_update` request schema and expectation handling
  - target resolution and derived anchor selection
  - explicit surface interrogation and finding serialization
- **Validation Class**: mixed
- **Likely Analog Class**: interrogation-backed validation expectation

### Identity Notes
- Task-only evidence frames a compact but geometry-sensitive expansion of `validate_scene_update` with one explicit object-anchor-to-surface-offset relationship.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Adds a materially richer validation expectation beyond coarse mesh-health checks. |
| Technical Change Surface | 3 | Likely touches validation request normalization, target resolution, anchor derivation, surface sampling, findings, schemas, docs, and tests. |
| Hidden Complexity Suspicion | 3 | Geometry-derived anchors, surface ambiguity, offset tolerance, and expectation mapping can hide edge cases. |
| Validation Burden Suspicion | 3 | Requires focused runtime coverage plus geometry-sensitive SketchUp-hosted verification or explicit gaps. |
| Dependency / Coordination Suspicion | 2 | Depends on `SVR-01`, `STI-02`, and existing target/interrogation seams. |
| Scope Volatility Suspicion | 2 | The task is explicitly narrow, but could expand toward topology, terrain diagnostics, or broad relationship frameworks. |
| Confidence | 2 | `task.md` gives strong intent, but this seed intentionally excludes technical plan evidence. |

### Early Signals
- The task keeps the richer check inside `validate_scene_update` rather than creating new public micro-tools.
- Acceptance criteria require derived anchor points from modeled targets, explicit surface targets, offset/tolerance semantics, and structured findings.
- Non-goals defer `measure_scene`, topology-backed validation, broad terrain checks, arbitrary point lists, and a multi-relationship framework.

### Early Estimate Notes
- Seed shape is moderately large and validation-heavy, with early risk concentrated in geometry semantics and keeping the public contract narrow.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

> Filled during task planning. This is the main pre-implementation estimate.

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Adds one new validation expectation kind, `surfaceOffset`, with modeled-object anchors, explicit surface reference, offset constraints, and structured failures. |
| Technical Change Surface | 3 | Plan spans validation command normalization/evaluation, loader schema, shared surface sampling seam, target resolver, anchor derivation, docs, and runtime passthrough tests. |
| Implementation Friction Risk | 3 | Requires bounds-derived anchor extraction, self-occlusion ignore-target behavior, surface sampling reuse, ambiguity handling, and stable failed-anchor evidence. |
| Validation Burden Risk | 4 | Plan requires loader, command, scene-query seam, runtime passthrough, docs parity, and SketchUp-hosted validation for transforms, self-occlusion, and ambiguity. |
| Dependency / Coordination Risk | 2 | Depends on `SVR-01`, `STI-02`, runtime schema, target resolution, and sampling support, but these are identified existing seams. |
| Discovery / Ambiguity Risk | 3 | Plan explicitly flags coarse anchor truthfulness, irregular footprint limits, surface ambiguity, visible blocking, and schema discoverability risks. |
| Scope Volatility Risk | 3 | The MVP is narrow, but the plan requires an immediate stronger-anchor follow-up and must resist widening into broader relationship or topology validation. |
| Rework Risk | 3 | Incorrect anchor naming, duplicated probing logic, self-occlusion, or weak schema exposure could force contract and implementation revisions. |
| Confidence | 3 | Planning evidence is detailed and includes premortem controls, but hosted geometry and approximation limits remain meaningful uncertainty. |

### Top Assumptions
- Bounds-derived approximate anchors are acceptable for the MVP when the limitation is explicit in enum names, schema, docs, and examples.
- Existing scene-query sampling behavior can expose the needed ignore-target seam without duplicating probing inside validation.
- `surfaceOffset` remains the only new relationship meaning in this task.
- Hosted or manual SketchUp validation can cover transforms, self-occlusion, and ambiguity behavior.

### Estimate Breakers
- If the task tries to support true footprint/contact validation for irregular shapes, scope and discovery increase materially.
- If validation reimplements sampling instead of sharing the scene-query seam, friction and rework risk increase.
- If modeled objects cannot be ignored during blocker evaluation cleanly, the core terrain-under-object use case is at risk.
- If loader schema cannot expose branch fields clearly, MCP discoverability and docs work need more iteration.

### Predicted Signals
- The plan introduces `geometryRequirements.kind = "surfaceOffset"` plus `surfaceReference`, `anchorSelector`, and `constraints`.
- Failure evidence must include stable `failedAnchors` data with derived points, sample status, sampled surface point, actual offset, and offset delta.
- The premortem identifies false confidence from coarse anchors and false misses from self-occlusion as primary risks.
- Test strategy requires schema, command, scene-query, runtime passthrough, docs parity, and hosted validation coverage.

### Predicted Estimate Notes
- Predicted size is high for validation and moderate-high for implementation because one public expectation kind still crosses validation contracts, real SketchUp geometry, sampling visibility, schema discoverability, and docs.
<!-- SIZE:PREDICTED:END -->

---

<!-- SIZE:CHALLENGE:START -->
## Challenge Review

> Filled when the estimate is pressure-tested through external review, premortem, or controlled consensus.

### Agreed Drivers
- Coarse bounds-derived anchors are the central product and validation risk; they must be named and documented as approximate.
- Self-occlusion is a core implementation risk because the modeled object can block sampling of the terrain surface it should be checked against.
- Schema discoverability matters: clients need the `surfaceOffset` branch fields through the loader schema, not only prose documentation.
- Sampling behavior must be shared with scene-query code to avoid divergent hit, miss, ambiguity, transform, or visibility semantics.

### Contested Drivers
- The MVP is useful for simple rectangular or slab-like forms, but not trustworthy for irregular footprints without a stronger-anchor follow-up.
- Hosted validation is required for confidence, but plan-stage evidence cannot yet prove transformed, occluded, or ambiguous live SketchUp behavior.
- The compact single-kind approach limits scope, but it may invite premature expansion once the relationship shape exists.

### Missing Evidence
- Hosted validation for a transformed group/component on sloped sample terrain.
- Hosted validation that terrain under an occluding modeled object is sampled by ignoring that modeled object as a blocker.
- Evidence that docs, guide, and schema descriptions all preserve the approximate/simple-form limitation.

### Recommendation
- confirm estimate

### Challenge Notes
- The premortem confirms the high validation-burden prediction and the need to keep scope narrow. No predicted score revision is needed because the profile already accounts for coarse-anchor truthfulness, self-occlusion, shared-seam reuse, and hosted validation risk.
<!-- SIZE:CHALLENGE:END -->

---

<!-- SIZE:DRIFT:START -->
## Drift Log

> Append only. Log only material changes that affect estimate shape, risk, confidence, or validation burden.

| Date | Phase / Checkpoint | Event Type | Severity (1-3) | Dimension Affected | Predictable Earlier? | Notes |
|---|---|---|---:|---|---|---|
| n/a | n/a | n/a | n/a | n/a | n/a | No in-flight drift log existed before retroactive calibration. |

### Drift Notes
- No material drift entries were recorded during implementation.
<!-- SIZE:DRIFT:END -->

---

<!-- SIZE:ACTUAL:START -->
## Actual Profile

> Filled at the end of implementation. Do not overwrite predicted values.

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Shipped one new `surfaceOffset` geometry requirement kind with explicit surface, anchor, constraints, and failed-anchor evidence. |
| Technical Change Surface | 3 | Touched validation command behavior, MCP loader schema, runtime passthrough, native contracts, docs, and shared sampling use. |
| Actual Implementation Friction | 2 | Implementation stayed inside planned Ruby runtime surfaces and reused `SampleSurfaceQuery` without creating a second probing subsystem. |
| Actual Validation Burden | 2 | Broad automated checks ran. Hosted verification for transformed geometry, occlusion, and irregular terrain remained open, which is a confidence gap rather than completed validation burden. |
| Actual Dependency Drag | 1 | Existing `SVR-01` and `STI-02` seams were reused without recorded external blockage. |
| Actual Discovery Encountered | 2 | Completion confirmed the approximate-anchor limitation and left live geometry gaps rather than discovering a broader relationship design. |
| Actual Scope Volatility | 1 | Scope stayed within one `surfaceOffset` kind and one approximate bounds-derived anchor family. |
| Actual Rework | 1 | No material rework is recorded; the remaining stronger-anchor need is a follow-up, not in-task redesign. |
| Final Confidence in Completeness | 3 | Automated and contract validation are strong, but hosted geometry verification is explicitly still needed. |

### Actual Signals
- `summary.md` records the shipped `surfaceOffset` branch fields and finite `anchorSelector.anchor` enum.
- Command-side refusals cover missing and malformed `surfaceOffset` fields plus unsupported anchors with `allowedValues`.
- Implementation reused `SampleSurfaceQuery` / `SampleSurfaceSupport` and added ignore-target sampling to avoid modeled-object self-occlusion.
- Remaining gap records needed SketchUp-hosted verification for transformed geometry, occluding modeled objects, and irregular terrain cases.

### Actual Notes
- Actual delivery matched the planned narrow MVP. The main residual risk is not unbounded implementation work, but incomplete host-sensitive verification and the known need for stronger anchors in a follow-up.
<!-- SIZE:ACTUAL:END -->

---

<!-- SIZE:VALIDATION-EVIDENCE:START -->
## Validation Evidence Summary

> Fill only the sections that are relevant. Say `not applicable` where needed.

### Automated Validation
- `bundle exec ruby -Itest test/runtime/native/mcp_runtime_loader_test.rb` passed.
- `bundle exec ruby -Itest test/scene_validation/scene_validation_commands_test.rb` passed.
- `bundle exec ruby -Itest test/runtime/tool_dispatcher_test.rb` passed.
- `bundle exec ruby -Itest test/runtime/native/mcp_runtime_facade_test.rb` passed.
- `bundle exec ruby -Itest test/runtime/native/mcp_runtime_native_contract_test.rb` passed.
- `bundle exec rake ruby:test`, `bundle exec rake ruby:lint`, and `bundle exec rake package:verify` passed.

### Manual Validation
- SketchUp-hosted manual verification is still needed for transformed geometry, real-face sampling under occluding modeled objects, and irregular terrain cases outside the fake-geometry harness.

### Performance Validation
- Not applicable; no performance-specific validation was recorded for this task.

### Migration / Compatibility Validation
- Native contract coverage was updated for the changed public surface.

### Operational / Rollout Validation
- README and current source-of-truth docs were updated for the new public surface and approximate-anchor limitations.

### Validation Notes
- Automated validation was broad, but final confidence is capped below very strong because the summary explicitly leaves host-sensitive geometry verification open.
<!-- SIZE:VALIDATION-EVIDENCE:END -->

---

<!-- SIZE:DELTA:START -->
## Estimation Delta Review

> Filled during final calibration. Compare prediction to actual behavior.

- **Most Underestimated Dimension**: None materially. The plan predicted the key risks around approximation, self-occlusion, schema exposure, and sampling reuse.
- **Most Overestimated Dimension**: Validation burden as completed work. The plan called for hosted verification, but summary evidence shows that portion remained a gap rather than completed validation effort.
- **Signal Present Early But Underweighted**: Hosted geometry confidence was identified in planning and remained open at closeout, so future estimates should treat that as a completion gate or explicitly size the residual gap.
- **Genuinely Unknowable Factor**: None identified; the main residual uncertainty was known in planning and left unverified, not newly discovered.
- **Future Similar Tasks Should Assume**: Interrogation-backed validation expectations need separate sizing for fake-geometry automated coverage and real SketchUp hosted acceptance.

### Calibration Notes
- Prediction was directionally accurate on scope and technical surface. Actual implementation friction and rework were lower than risk scores, while final confidence is limited by the documented hosted-verification gap.
<!-- SIZE:DELTA:END -->

---

<!-- SIZE:TAGS:START -->
## Retrieval Tags

- `archetype:feature`
- `scope:scene-validation-review`
- `validation:contract`
- `host:not-run-gap`
- `systems:validate-scene-update`
- `systems:target-resolution`
- `systems:surface-interrogation`
- `systems:validation-service`
- `risk:visibility-semantics`
- `volatility:medium`
- `friction:high`
- `rework:low`
- `confidence:medium`
<!-- SIZE:TAGS:END -->

---

## Scoring Reference

Use the shared size playbook for all scoring.

- **0** = none / negligible
- **1** = low
- **2** = moderate
- **3** = high
- **4** = very high

Do not score from intuition alone. Every non-trivial score should be supported by concrete signals or evidence.
