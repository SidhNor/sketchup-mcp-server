# Size: SAR-01 Curate And Discover Approved Asset Exemplars

**Task ID**: `SAR-01`  
**Title**: `Curate And Discover Approved Asset Exemplars`  
**Status**: `calibrated`  
**Created**: `2026-04-25`  
**Last Updated**: `2026-04-26`  

**Related Task**: [task.md](./task.md)  
**Related Plan**: [plan.md](./plan.md)  
**Related Summary**: [summary.md](./summary.md)  

---

<!-- SIZE:IDENTITY:START -->
## Identity

- **Task Archetype**: feature
- **Primary Scope Area**: staged asset reuse curation and discovery
- **Likely Systems Touched**:
  - Asset Exemplar metadata and approval policy
  - staged asset library organization
  - target resolution for in-model assets
  - `list_staged_assets` MCP command and runtime registration
  - JSON-safe asset summary serialization
  - initial approved-exemplar predicate
  - task-level tests and user-facing docs for the new tool surface
- **Validation Class**: mixed
- **Likely Analog Class**: metadata-backed domain discovery vertical slice

### Identity Notes
- First staged-asset slice combines curation metadata, approval policy, discovery, and initial guardrail posture because discovery needs a supported way to create approved exemplars.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Creates the first product-visible staged-asset workflow: register an in-model asset and discover it as approved. |
| Technical Change Surface | 3 | Likely touches metadata policy, target resolution, staging organization, command registration, serialization, tests, and docs. |
| Hidden Complexity Suspicion | 3 | Resolution by name or target, staging movement, approval semantics, and exemplar/instance distinction can hide edge cases. |
| Validation Burden Suspicion | 3 | Needs positive discovery, excluded unapproved assets, refusal cases, JSON-safe output, and likely hosted SketchUp checks. |
| Dependency / Coordination Suspicion | 2 | Depends on existing targeting and serialization foundations but introduces a new product namespace and public tool surface. |
| Scope Volatility Suspicion | 3 | Pressure may appear to absorb rich curation, Warehouse import, versioning, or deeper guardrails unless boundaries stay explicit. |
| Confidence | 2 | Direction is source-backed, but no asset implementation exists and final metadata shape is not technically planned yet. |

### Early Signals
- The task starts from a zero staged-asset implementation baseline.
- User-curated 3D Warehouse assets are in scope only after they are already present in the model.
- PAL/Grok review pushed curation, discovery, and initial protection into one demonstrable first slice.
- Prior metadata-backed and hosted-behavior analogs suggest validation burden can exceed apparent command count.

### Early Estimate Notes
- Seed reflects a moderate-to-large first feature slice because it establishes the asset metadata contract and proves it through a public discovery tool.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

> Filled during task planning. This is the main pre-implementation estimate.

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Adds the first staged-asset workflow with curation and approved discovery, but explicitly excludes instantiation, replacement, source-stability hardening, import, ranking, and versioning. |
| Technical Change Surface | 3 | Plan touches a new staged-asset command slice, metadata policy, query/serializer support, target resolution, scene-query classification, runtime loader, dispatcher, factory, contract fixtures, tests, and README. |
| Implementation Friction Risk | 3 | Main friction is hidden metadata coupling: exemplars need `sourceElementId` without becoming Managed Scene Objects, and curation must validate before writing to avoid partial approved metadata. |
| Validation Burden Risk | 4 | Two new public tools require metadata, query, serializer, command, dispatcher/factory, loader/schema, contract/docs, limit/filter, no-partial-write, and likely hosted/manual SketchUp smoke coverage. |
| Dependency / Coordination Risk | 2 | Depends on existing runtime, target resolver, model adapter, serializer, and response envelope seams, plus later reuse consumers, but no external system or upstream implementation is blocking. |
| Discovery / Ambiguity Risk | 2 | Major choices are now resolved, including metadata-only staging and no locking; remaining uncertainty is around live component-instance behavior, serializer isolation, and exact contract fixture breadth. |
| Scope Volatility Risk | 2 | Metadata-only staging and deferral of reuse-flow source-stability checks contain the slice, but pressure could still appear to add tags/layers, definition-level policy, locking, unapproved discovery, or richer curation validation. |
| Rework Risk | 3 | Incorrect metadata discrimination, public schema drift, or partial-write behavior would force revisiting multiple completed surfaces after initial implementation. |
| Confidence | 3 | Task, plan, linked specs, code seams, calibrated analogs, and Grok 4.20 review provide good evidence; confidence remains below very high until premortem and live-host assumptions are pressure-tested. |

### Top Assumptions

- Metadata-backed staging is accepted as the SAR-01 library convention and does not require tag/layer/reparent/lock behavior.
- `sourceElementId` can remain the exemplar identity once `SceneQuerySerializer` excludes `assetExemplar: true` from Managed Scene Object classification.
- Existing target resolution and recursive model traversal are sufficient for curation and listing.
- The curated entity instance is the correct metadata owner for SAR-01; definition-level policy remains deferred.
- Focused automated tests plus one manual or hosted smoke are enough to validate metadata-only behavior.

### Estimate Breakers

- If SAR-01 must create a visible staging tag/layer, reparent assets, or lock entities, host behavior and validation burden increase materially.
- If component definition-level metadata becomes required for SAR-02, data ownership and discovery semantics need redesign.
- If unapproved or incomplete asset discovery becomes required in SAR-01, the approval-gate contract and test matrix widen.
- If existing target traversal cannot reliably distinguish exemplar instances from shared component definitions, implementation friction and live validation burden increase.
- If native contract conventions require broad fixture coverage for both new tools and every refusal family, validation burden may dominate closeout.

### Predicted Signals

- The task adds two new public MCP tools, not just one internal metadata helper.
- Runtime contract artifacts must move together: loader schema, dispatcher, factory, command target, contract fixtures, README, and tests.
- Grok 4.20 review found a real hidden coupling in current `SceneQuerySerializer` managed-object classification.
- Calibrated public-tool analog `SVR-03` landed at high validation burden because tool-list/schema, command behavior, contract, docs, and hosted checks all mattered.
- Host-sensitive analogs such as `MTA-03` and `STI-02` show local doubles can miss SketchUp runtime details, even when scope is bounded.

### Predicted Estimate Notes

- No exact calibrated staged-asset analog exists. The closest useful analog class is a bounded public MCP tool plus metadata-backed domain classification.
- The planning refinement changed the seed shape by making staging explicitly metadata-only and adding `curate_staged_asset`; this is a pre-implementation planning baseline, not implementation drift.
- The main expected cost is validation and public-surface synchronization rather than complex geometry work.
<!-- SIZE:PREDICTED:END -->

---

<!-- SIZE:CHALLENGE:START -->
## Challenge Review

> Filled when the estimate is pressure-tested through external review, premortem, or controlled consensus.

### Agreed Drivers

- Public contract synchronization is a major size driver: both new tools require loader schema, annotations, dispatcher/factory wiring, command behavior, contract fixtures, README examples, and catalog tests to move together.
- Metadata discrimination is a real implementation and validation driver because Asset Exemplars need stable `sourceElementId` identity without becoming Managed Scene Objects in existing scene-query serialization.
- Validation burden remains high because correctness depends on no-partial-write refusals, approved-only discovery, metadata-backed staging evidence, serializer isolation, list caps, and representative MCP/host behavior.
- Keeping SAR-01 metadata-only, unlocked, and instance-level contains scope and avoids absorbing SAR-02 instantiation or later source-stability validation.

### Contested Drivers

- Staging convention visibility remains contested: metadata-only staging is accepted for SAR-01, but it must be made observable in serialized results and docs or users may reasonably see it as no library organization.
- Component definition metadata remains contested: definition-level metadata could help future instantiation, but it risks classifying all shared instances and is therefore deferred.
- Hosted validation depth is contested: metadata-only behavior is mock-friendly, but live SketchUp smoke is still useful for entity attributes, component instances, persistent identifiers, and MCP-visible tool behavior.

### Missing Evidence

- Live or hosted proof that a curated group/component instance can be listed through the MCP runtime with the intended summary shape.
- Proof that existing scene inspection/targeting behavior no longer misclassifies Asset Exemplars as Managed Scene Objects.
- Final native `tools/list` evidence that both tools expose provider-compatible schemas and clear descriptions.
- Confirmation during implementation that representative native contract fixtures cover enough of the new public surface without becoming excessive.

### Recommendation

- Confirm the predicted profile without score changes.
- Do not split the task before implementation.
- Treat hosted/manual smoke as a required closeout target where practical, and explicitly record the gap if it cannot run.

### Challenge Notes

- Grok 4.20 review found concrete hidden coupling in current serializer behavior but did not require a scope split; the finalized plan now carries serializer isolation as a test and implementation guardrail.
- The premortem converted metadata-only staging visibility and mutation-protection deferral into explicit validation and docs obligations.
- No evidence supports adding tags/layers, definition-level metadata, locking, unapproved listing, or full source-stability behavior to SAR-01.
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
| Functional Scope | 3 | Delivered the planned first staged-asset workflow: public curation, approved-only discovery, metadata-only staging, finite option refusals, and exemplar predicate support for later guardrails. Instantiation, replacement, locking, import, ranking, and versioning stayed out of scope. |
| Technical Change Surface | 3 | Touched new staged-asset metadata/query/serializer/command classes, scene-query managed-object classification, runtime dispatcher/factory/loader catalog, native contract fixtures, README, task docs, and focused test support. |
| Actual Implementation Friction | 3 | Implementation followed the planned layered route, but live SketchUp exposed a real hidden storage mismatch: Ruby hash `assetAttributes` did not survive entity-attribute persistence and broke discovery until JSON-backed storage/read normalization was added. |
| Actual Validation Burden | 3 | Required focused TDD skeletons, full Ruby tests, lint, package verification, public schema/fixture checks, Grok-4.20 review, and one live MCP smoke blocker followed by a storage fix, post-fix CI, and live rerun for curation/list/filter/side-effect behavior. |
| Actual Dependency Drag | 2 | Work depended on existing target resolution, model traversal, serializer, runtime catalog, response envelopes, and external live SketchUp verification, but no upstream code dependency blocked completion. |
| Actual Discovery Encountered | 3 | The main discovery was host-specific attribute persistence: local doubles accepted hash attributes, while live SketchUp did not. Component-instance verification and simplified user-led smoke guidance also refined the final validation posture. |
| Actual Scope Volatility | 1 | Scope stayed within SAR-01. The live fix changed storage representation for asset attributes but did not add tags/layers, physical staging, unapproved listing, locking, instantiation, or guardrail enforcement. |
| Actual Rework | 2 | Rework was targeted but real: the metadata storage/read path and regression tests were changed after live smoke, then focused tests, lint, full Ruby tests, CI, and live rerun were repeated. No broad public contract or architecture redesign was needed. |
| Final Confidence in Completeness | 4 | Confidence is high after automated validation, Grok-4.20 review, live MCP smoke finding, targeted fix, full CI, and post-fix live pass for group and component curation, listing, filters, refusals, managed-object isolation, and no side effects. |

### Actual Signals

- `curate_staged_asset` and `list_staged_assets` shipped together through runtime command, dispatcher, factory, loader schema, native fixture, README, and tests.
- `SceneQuerySerializer` now keeps Asset Exemplars with `sourceElementId` out of Managed Scene Object classification while preserving targetability.
- Live smoke found that curation metadata was written but discovery skipped curated assets because `assetAttributes` was not SketchUp-safe when stored as a Ruby hash.
- Post-fix live smoke proved approved-only listing, category/tag filters, attribute filters, uncurated exclusion, group and component handling, and no geometry side effects.

### Actual Notes

- The prediction was accurate that validation would dominate. The implementation friction was not geometry-related; it came from host persistence semantics for metadata.
<!-- SIZE:ACTUAL:END -->

---

<!-- SIZE:VALIDATION-EVIDENCE:START -->
## Validation Evidence Summary

> Fill only the sections that are relevant. Say `not applicable` where needed.

### Automated Validation
- Focused staged-asset regression set after the live fix: `23 runs, 61 assertions, 0 failures, 0 errors, 0 skips`.
- `bundle exec rake ruby:test`: `692 runs, 3205 assertions, 0 failures, 0 errors, 35 skips`.
- `bundle exec rake ruby:lint`: `185 files inspected, no offenses`.
- `bundle exec rake ci`: passed, including lint, Ruby tests, and package verification; package output `dist/su_mcp-0.22.0.rbz`.
- Runtime and contract tests cover staged-asset command behavior, metadata predicates, serializer output, query filtering, dispatcher/factory wiring, loader catalog/schema annotations, native contract fixtures, and scene-query managed-object isolation.
- `mcp__pal__.codereview` with `grok-4.20`: completed. Final review reported no required fixes; earlier sequencing concerns were incorporated before closeout.

### Manual Validation
- Live MCP smoke ran against `TestGround.skp`.
- Initial live pass confirmed tool discovery, target lookup, group/component curation success, refusal handling, managed-object isolation, and no geometry side effects, but found `list_staged_assets` returning zero after curation.
- Post-fix live rerun passed on the same existing assets: group and component curation preserved attributes, approved-only listing returned `count: 2`, category/tag filters returned the intended single asset, attribute filters returned the intended single asset, and an uncurated tag filter returned zero.
- Side-effect checks stayed clean: same persistent IDs, same bounds, same `Layer0`, unlocked, visible, model-root parent, and no move/reparent/tag/layer/lock/delete/duplicate behavior.

### Performance Validation
- Not applicable; SAR-01 discovery uses capped scene traversal and no performance benchmark was required or recorded.

### Migration / Compatibility Validation
- Package verification passed after the staged-asset classes were arranged so native loader package load does not require SketchUp-only query/serializer classes.
- `assetAttributes` storage changed to JSON text for SketchUp attribute compatibility while public responses still expose decoded JSON-safe hashes.

### Operational / Rollout Validation
- Public docs and live guide were updated for metadata-only staging, finite option sets, user-named asset workflow, and the compact live verification matrix.
- Later reuse consumers can rely on the approved-exemplar predicate and metadata contract; source-stability checks should reuse the predicate rather than duplicate it.

### Validation Notes
- The host validation gap was closed after the live discovery blocker was fixed and retested.
<!-- SIZE:VALIDATION-EVIDENCE:END -->

---

<!-- SIZE:DELTA:START -->
## Estimation Delta Review

- **Most Underestimated Dimension**: Discovery / ambiguity. The plan anticipated host-sensitive behavior, but the specific SketchUp attribute-persistence mismatch for Ruby hashes was only exposed by live MCP smoke after local tests and review were green.
- **Most Overestimated Dimension**: Scope volatility. The task did not expand into physical staging, locking, unapproved discovery, definition-level policy, import, or instantiation despite live issues and guide simplification.
- **Signal Present Early But Underweighted**: Metadata-backed staging depends on SketchUp attribute dictionary semantics, not only Ruby-side JSON safety. Future metadata-backed tasks should test live persistence of every non-scalar stored value early.
- **Genuinely Unknowable Factor**: Whether live SketchUp would preserve `Hash` values in entity attributes as local doubles did was not proven until hosted validation. The consequence was severe for discovery because completeness checks depended on the stored field.
- **Dominant Actual Failure Mode**: Local doubles were too permissive around SketchUp attribute storage, allowing the query/listing path to look complete while live persisted metadata made every curated asset undiscoverable.
- **Future Similar Tasks Should Assume**: Public metadata-backed tool slices need one live round trip that writes metadata, reads it through the normal query path, filters on it, and confirms no side effects before final closeout. Store structured metadata in SketchUp-safe scalar form, usually JSON text, unless live evidence proves otherwise.

### Calibration Notes

- Prediction was accurate on functional scope, technical surface, dependency drag, and elevated validation burden; actual validation lands at `3` under the retest-loop scale because there was one contained live blocker and rerun rather than repeated loops.
- Actual implementation friction and rework were driven by host persistence, not target resolution or component definition semantics.
- The final confidence is higher than the challenged estimate because the live blocker was reproduced, fixed, covered by regression tests, and validated through post-fix live smoke.
<!-- SIZE:DELTA:END -->

---

<!-- SIZE:TAGS:START -->
## Retrieval Tags

- `archetype:feature`
- `scope:staged-asset-reuse`
- `systems:asset-metadata`
- `systems:asset-query`
- `validation:hosted-smoke`
- `host:single-fix-loop`
- `risk:metadata-storage`
- `systems:target-resolution`
- `volatility:low`
- `friction:medium`
- `rework:medium`
- `confidence:high`
<!-- SIZE:TAGS:END -->
