# Size: STI-03 Extend sample_surface_z With Profile and Section Sampling

**Task ID**: STI-03  
**Title**: Extend sample_surface_z With Profile and Section Sampling  
**Status**: calibrated  
**Created**: 2026-04-24  
**Last Updated**: 2026-04-24  

**Related Task**: [task.md](./task.md)  
**Related Plan**: [plan.md](./plan.md)  
**Related Summary**: [summary.md](./summary.md)  

---

<!-- SIZE:IDENTITY:START -->
## Identity

- **Task Archetype**: feature
- **Primary Scope Area**: scene targeting and interrogation surface sampling
- **Likely Systems Touched**:
  - `sample_surface_z` request contract and runtime validation
  - explicit host-target surface interrogation
  - ordered sampling evidence and JSON-safe serialization
- **Validation Class**: mixed
- **Likely Analog Class**: explicit host sampling contract expansion

### Identity Notes
- Task-only evidence frames this as an evidence-producing extension from point batches to ordered profile and section sampling, without terrain diagnostics or editing.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Extends a public evidence tool from point sampling to ordered profile and section sampling. |
| Technical Change Surface | 3 | Likely touches schema, request validation, sampling execution, summary shaping, serialization, docs, and tests. |
| Hidden Complexity Suspicion | 3 | Ordered paths, spacing strategies, explicit host disambiguation, occlusion, misses, and compact summaries can hide edge cases. |
| Validation Burden Suspicion | 3 | Requires deterministic ordered output, miss/ambiguity behavior, host isolation, and no-diagnostics boundary checks. |
| Dependency / Coordination Suspicion | 2 | Depends on `STI-02` explicit host-target sampling semantics. |
| Scope Volatility Suspicion | 2 | The task is bounded to evidence collection, but terrain workflows can pull toward diagnostics, measurement, or editing. |
| Confidence | 2 | `task.md` provides strong intent, but this seed intentionally excludes technical planning evidence. |

### Early Signals
- The task preserves `sample_surface_z` as the owning public tool and avoids adding terrain validation or editing responsibilities.
- Acceptance criteria require ordered JSON-safe samples with distance/progress, statuses, sampled coordinates, and compact summaries.
- Technical constraints require explicit host references, provider-compatible schema shape, Ruby-owned sampling, and reuse of existing seams.

### Early Estimate Notes
- Initial shape is a moderate-to-large interrogation contract expansion, with risk concentrated in sampling semantics and hosted geometry behavior.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

> Filled during task planning. This is the main pre-implementation estimate.

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Adds profile sampling while intentionally changing the public request contract to canonical `target + sampling` for points and profiles. |
| Technical Change Surface | 3 | Plan spans loader schema, runtime validation, query normalization, profile generation, support reuse, serialization, docs, fixtures, and dispatcher coverage. |
| Implementation Friction Risk | 3 | Requires deterministic profile generation, cap enforcement, internal evidence DTO, explicit-host reuse, compatibility recovery decisions, and no terrain diagnostics. |
| Validation Burden Risk | 4 | Plan requires schema, contract fixtures, profile generator tests, invalid-combination refusals, explicit-host query tests, hosted/manual verification, and profiling. |
| Dependency / Coordination Risk | 2 | Depends on `STI-02` sampling internals, schema registration, docs, and hosted SketchUp environment, but no external dependency is expected to dominate. |
| Discovery / Ambiguity Risk | 3 | Plan flags client confusion from nested `sampling`, arbitrary sample cap risk, DTO reuse shape, provider schema drift, and host-sensitive behavior. |
| Scope Volatility Risk | 2 | Scope is bounded to evidence collection, though contract-change feedback or cap profiling could require adjustment. |
| Rework Risk | 3 | Public request-shape mistakes, profile off-by-one errors, cap choice, or host-specific geometry failures could force revisions. |
| Confidence | 3 | Planning evidence is detailed, but profiling and hosted verification remain meaningful uncertainties. |

### Top Assumptions
- The canonical nested `sampling` object is acceptable for MCP clients and will replace advertised top-level `samplePoints`.
- Existing `SampleSurfaceQuery`, `SampleSurfaceSupport`, and `SceneQuerySerializer` can support points and generated profile samples without a second raytest stack.
- A `200` generated-sample cap is plausible, pending implementation profiling.
- Profile outputs can remain compact evidence and avoid slope, fairness, grade, or edit recommendations.

### Estimate Breakers
- If mocked client/schema readability shows persistent misuse of the nested `sampling` shape, the public contract needs redesign.
- If profiling shows the `200` sample cap is unsafe or too restrictive, tests, refusals, and docs must change.
- If hosted SketchUp behavior diverges from local sampling doubles for transforms, visibility, or overlapping geometry, implementation and validation effort increase.
- If internal consumers cannot reuse a narrow sampling-evidence DTO, downstream measurement work may inherit public JSON coupling.

### Predicted Signals
- The plan intentionally changes the public tool request shape while preserving provider-compatible root schema constraints.
- Profile generation must handle count spacing, interval spacing, endpoint inclusion, zero-length segments, multi-segment paths, deterministic ordering, and cap refusal.
- The premortem calls out client contract confusion, arbitrary caps, DTO coupling, host-sensitive behavior, and schema/runtime drift.
- Validation must prove explicit-host sampling remains isolated from overlapping scene objects and does not fall back to generic probing.

### Predicted Estimate Notes
- Predicted size is high for validation and moderate-high for implementation because this is both a public contract change and a geometry-sensitive sampling expansion.
<!-- SIZE:PREDICTED:END -->

---

<!-- SIZE:CHALLENGE:START -->
## Challenge Review

> Filled when the estimate is pressure-tested through external review, premortem, or controlled consensus.

### Agreed Drivers
- Public contract change is a major driver: loader schema, runtime validation, docs, and examples must all teach the canonical `sampling` shape.
- Profile generation correctness is a major driver: spacing, endpoint inclusion, zero-length handling, and cap refusal are easy to get subtly wrong.
- Host-sensitive explicit-host behavior is central to value and must be checked against overlapping geometry and transformed/nested terrain.
- Internal evidence shape matters because future `measure_scene` work must reuse internals without calling or parsing the public MCP tool.

### Contested Drivers
- The nested `sampling` object is the chosen contract, but the plan admits it may confuse clients if schema/examples are not clear enough.
- The `200` sample cap is an MVP default, not proven safe until implementation profiling.
- Hosted verification is required for confidence, but planning cannot yet prove the hosted harness or manual evidence will cover all transform and visibility cases.

### Missing Evidence
- Mocked client/schema-readability exercise for the canonical point and profile request shapes.
- Benchmark or profiling evidence supporting the generated profile sample cap.
- Hosted or documented manual SketchUp verification for nested/transformed terrain with overlapping non-terrain geometry.

### Recommendation
- confirm estimate

### Challenge Notes
- The premortem supports the high validation-burden prediction. No score revision is needed because predicted sizing already includes contract readability, profiling, internal DTO, schema/runtime drift, and hosted behavior risks.
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
| Functional Scope | 3 | Shipped canonical `target + sampling`, finite `points` and `profile` sampling, ordered profile evidence, summaries, and evidence-only boundaries. |
| Technical Change Surface | 3 | Updated runtime schema, query/validation callers, native contract fixtures, dispatcher coverage, HLD/PRD language, README guidance, and task metadata references. |
| Actual Implementation Friction | 3 | Hosted validation found and fixed unresolved `ignoreTargets`, nested sourceElementId resolution, hidden-layer visibility, nested target-ignore, and hidden-ancestor gaps. |
| Actual Validation Burden | 4 | Required live hosted matrix, focused hosted regression smoke, targeted Ruby suites, broad Ruby tests, lint, package verification, diff checks, and code review follow-up. |
| Actual Dependency Drag | 1 | Existing `STI-02` sampling seams and runtime paths were reused without recorded external blockage. |
| Actual Discovery Encountered | 3 | Real SketchUp checks exposed ancestry, hidden-parent, and nested ignore-target behavior that local planning could not fully prove. |
| Actual Scope Volatility | 2 | The public feature stayed evidence-only and within `sample_surface_z`, but implementation absorbed several host-behavior fixes. |
| Actual Rework | 2 | Rework was contained to fixing hosted matrix findings and adding contract/schema-description coverage, not redesigning the sampling contract. |
| Final Confidence in Completeness | 4 | Strong automated and hosted evidence plus code review cleanup support completion, with a remaining hosted automation/follow-up coverage gap. |

### Actual Signals
- `summary.md` records replacement of the public request shape with canonical `target` plus `sampling`.
- Profile support shipped with `sampleCount` or `intervalMeters`, ordered rows, distance/progress metadata, compact summaries, and a 200-sample cap.
- Hosted matrices found and fixed nested ignore-target, nested sourceElementId, hidden-layer, and hidden-ancestor visibility defects.
- Grok 4.20 code review found no critical or high blockers after cleanup, and recommendations were addressed with native profile-refusal contract cases and loader schema cap/refusal documentation.

### Actual Notes
- Actual size was driven by public contract migration plus host-sensitive visibility and ancestry behavior. The evidence-only boundary held: no terrain diagnostics, validation ownership, or editing behavior moved into interrogation.
<!-- SIZE:ACTUAL:END -->

---

<!-- SIZE:VALIDATION-EVIDENCE:START -->
## Validation Evidence Summary

> Fill only the sections that are relevant. Say `not applicable` where needed.

### Automated Validation
- `bundle exec ruby -Itest test/scene_query/sample_surface_profile_generator_test.rb` passed.
- `bundle exec ruby -Itest test/scene_query/sample_surface_evidence_test.rb` passed.
- `bundle exec ruby -Itest test/scene_query/sample_surface_z_scene_query_commands_test.rb` passed.
- `bundle exec ruby -Itest test/scene_validation/scene_validation_commands_test.rb` passed.
- `bundle exec ruby -Itest test/runtime/native/mcp_runtime_loader_test.rb` passed.
- `bundle exec ruby -Itest test/runtime/tool_dispatcher_test.rb` passed.
- `bundle exec ruby -Itest test/runtime/native/mcp_runtime_native_contract_test.rb` passed.
- `bundle exec rake ruby:test` passed with 501 runs, 1812 assertions, 0 failures, 0 errors, and 27 skips.
- `bundle exec rake ruby:lint`, `bundle exec rake package:verify`, and `git diff --check` passed.

### Manual Validation
- Live SketchUp-hosted matrix passed for flat, sloped, triangulated terrain, profile, component-instance, and explicit ID target sampling.
- Hosted checks covered ordered summaries, mixed hit/miss ordering, 200-sample cap behavior, structured refusals, nested terrain/occluder targets, combined target ambiguity, nested occluder ignore by multiple IDs, and hidden visibility behavior.
- A skipped hosted smoke marker remains as a reminder to automate or periodically rerun the hosted matrix.

### Performance Validation
- Cap-at-200 behavior was covered in hosted validation. No separate timing benchmark is recorded in `summary.md`.

### Migration / Compatibility Validation
- Internal validation callers were updated to use canonical point sampling instead of legacy `samplePoints`.
- Native contract fixtures were updated for the changed public shape.

### Operational / Rollout Validation
- Runtime schema, HLD/PRD language, README guidance, related task metadata references, and loader schema descriptions were updated.
- Package verification emitted `dist/su_mcp-0.18.0.rbz`.

### Validation Notes
- Validation burden was high because hosted testing materially changed the implementation by exposing nested target and visibility defects. Confidence is strong, but persistent hosted automation remains a follow-up gap.
<!-- SIZE:VALIDATION-EVIDENCE:END -->

---

<!-- SIZE:DELTA:START -->
## Estimation Delta Review

> Filled during final calibration. Compare prediction to actual behavior.

- **Most Underestimated Dimension**: Host-sensitive discovery. The plan predicted this risk, but actual hosted validation found multiple concrete nested-target, ignore-target, and hidden-ancestor defects.
- **Most Overestimated Dimension**: Scope volatility. The public contract stayed within `sample_surface_z` evidence collection and did not expand into diagnostics, validation, or editing.
- **Signal Present Early But Underweighted**: The need for nested/transformed terrain and overlapping non-terrain hosted checks was present in planning and proved essential to correctness.
- **Genuinely Unknowable Factor**: The exact ancestry-aware target and visibility defects required live SketchUp-hosted coverage to expose.
- **Future Similar Tasks Should Assume**: Explicit-host geometry features need budget for hosted matrix iteration, not just a final smoke pass after local tests.

### Calibration Notes
- Prediction was accurate on validation burden and technical surface. Actual implementation friction came mainly from hosted discovery and follow-up fixes rather than public contract redesign.
<!-- SIZE:DELTA:END -->

---

<!-- SIZE:TAGS:START -->
## Retrieval Tags

- `archetype:feature`
- `scope:scene-targeting-interrogation-surface-sampling`
- `validation:mixed`
- `systems:sample-surface-z`
- `systems:surface-interrogation`
- `systems:json-serialization`
- `volatility:medium`
- `friction:high`
- `rework:unknown`
- `confidence:medium`
<!-- SIZE:TAGS:END -->
