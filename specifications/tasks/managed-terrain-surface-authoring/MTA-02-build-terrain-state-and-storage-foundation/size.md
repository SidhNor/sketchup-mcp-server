# Size: MTA-02 Build Terrain State And Storage Foundation

**Task ID**: `MTA-02`  
**Title**: Build Terrain State And Storage Foundation  
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
- **Primary Scope Area**: managed terrain state, repository, and storage boundary
- **Likely Systems Touched**:
  - terrain domain model
  - terrain repository
  - SketchUp attribute storage adapter
  - serialization and stale-state validation
- **Validation Class**: regression-heavy
- **Likely Analog Class**: metadata-backed domain state foundation

### Identity Notes
- Foundation task for storing managed terrain state without leaking storage details into public MCP contracts.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 2 | Establishes managed terrain state behavior but does not yet author terrain geometry. |
| Technical Change Surface | 3 | Likely touches domain objects, repository, adapters, serialization, and tests. |
| Hidden Complexity Suspicion | 3 | Heightmap ownership, identity, stale detection, and attribute namespace choices are sensitive. |
| Validation Burden Suspicion | 3 | Needs isolated state tests plus adapter and compatibility coverage. |
| Dependency / Coordination Suspicion | 2 | Depends on domain posture and constrains adoption/edit tasks. |
| Scope Volatility Suspicion | 2 | Storage shape may resize when adoption and regeneration needs are made concrete. |
| Confidence | 2 | The direction is clear, but implementation details are not planned yet. |

### Early Signals
- The heightmap should not live in the existing `su_mcp` metadata dictionary.
- Runtime-facing outputs must stay JSON-serializable.
- Recovery and stale-state behavior should be accepted inside this foundation slice.

### Early Estimate Notes
- Seed reflects a medium platform slice with meaningful state and compatibility risk.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

> Filled during task planning. This is the main pre-implementation estimate.

| Dimension | Predicted (0-4) | Rationale |
|---|---:|---|
| Functional Scope | 2 | Establishes internal terrain state and storage behavior, but adds no public terrain tool, adoption flow, mesh output, or edit behavior. |
| Technical Change Surface | 3 | Adds a new terrain subtree spanning domain state, serializer, repository, attribute-storage adapter, and mirrored tests. |
| Implementation Friction Risk | 3 | Heightmap schema invariants, canonical digest behavior, byte-size limits, and storage failure paths are precise enough to implement but likely to expose edge-case friction. |
| Validation Burden Risk | 4 | Premortem added recoverability, migration, transform-signature, 512x512-equivalent payload, and hosted persistence-smoke expectations on top of isolated domain, serializer, repository, and host-like storage tests. |
| Dependency / Coordination Risk | 2 | Depends on MTA-01 domain posture and constrains MTA-03 through MTA-06, but does not require public MCP coordination or hosted SketchUp workflow verification. |
| Discovery / Ambiguity Risk | 3 | Consensus resolved the direction, but premortem exposed remaining evidence gaps around hosted persistence, representative payload size, transform signatures, and downstream adoption/edit schema needs. |
| Scope Volatility Risk | 2 | The slice remains internal and bounded; premortem expanded validation and schema guardrails but did not require adoption, edit behavior, chunking, sidecars, or public tools. |
| Rework Risk | 4 | A weak v1 schema, repository outcome taxonomy, or host-persistence assumption would force expensive changes after `MTA-03` and edit tasks build on the foundation. |
| Confidence | 2 | Planning evidence is broad, but confidence is moderated because the most important remaining evidence is implementation-time: hosted persistence, payload-size fixtures, and transform-signature behavior. |

### Top Assumptions

- The first persisted terrain-state format remains a heightmap/grid payload, not a mesh, point cloud, or sidecar-backed format.
- A single JSON-safe model-embedded attribute payload is acceptable for Phase 1 when protected by a serialized-size threshold.
- Host-like attribute doubles are sufficient for most `MTA-02` automation, but hosted persistence smoke should be run if practical or carried as a blocking `MTA-03` validation item.
- No public MCP surface is added in this task.

### Estimate Breakers

- SketchUp attribute storage proves unable to safely hold even small representative heightmap payloads.
- The implementation must add chunking, compression, sidecar files, or public terrain commands to satisfy acceptance criteria.
- Owner-local coordinate handling requires real SketchUp transform validation beyond host-like doubles.
- Downstream adoption requirements force mesh-output or source-surface behavior into this foundation slice.

### Predicted Signals

- New internal stateful domain slice with durable persistence and compatibility implications.
- Strong negative-path requirement set: missing, corrupt, unsupported version, invalid shape, digest mismatch, oversized payload, write failure, and owner-transform unsupported cases.
- Consensus agreed the direction is sound but tightened schema, digest, no-data, size, and test requirements.
- Public contract risk is low because no loader, dispatcher, schema, contract fixture, or README tool update is planned.

### Predicted Estimate Notes

- Shape is medium-to-large for an internal platform task: the user-visible surface is absent, but downstream terrain authoring depends heavily on getting the storage contract right.
- Validation burden was raised after premortem because the plan now requires migration, recoverability, transform-signature, representative-payload, and hosted-persistence evidence in addition to isolated Ruby coverage.
- Rework risk was raised because schema or persistence mistakes become expensive once `MTA-03`, `MTA-04`, `MTA-05`, and `MTA-06` consume this foundation.
- Confidence was lowered after challenge review because key risks are now better understood but not yet proven in implementation.
<!-- SIZE:PREDICTED:END -->

---

<!-- SIZE:CHALLENGE:START -->
## Challenge Review

> Filled when the estimate is pressure-tested through external review, premortem, or controlled consensus.

### Agreed Drivers

- Internal functional scope remains moderate: no public MCP tools, adoption, mesh regeneration, sidecars, or edit kernels.
- Technical surface remains broad enough for a platform slice: terrain domain state, canonical serializer, repository, storage adapter, and mirrored tests.
- Validation is the dominant cost driver because correctness depends on many negative paths and deterministic persistence behavior.
- Rework risk is unusually high for an internal task because downstream terrain authoring tasks will inherit the v1 schema and repository contract.

### Contested Drivers

- Hosted persistence validation: the draft estimate assumed host-like doubles were sufficient, while premortem argued real SketchUp attribute persistence can fail differently. The plan now prefers hosted smoke and treats absence of it as a blocking `MTA-03` validation item.
- Payload-size threshold: initial planning treated the byte limit as a guardrail; challenge evidence showed it can reject realistic terrain too early. The plan now uses an 8 MiB threshold and representative 512x512-equivalent fixture.
- Schema extensibility: initial planning was intentionally minimal; premortem found source and constraint extension slots are needed to prevent immediate downstream schema churn without implementing adoption/edit semantics.

### Missing Evidence

- Actual SketchUp save/reopen behavior for the terrain payload namespace.
- Empirical serialized byte size for representative heightmap payloads.
- Whether transform signatures can be detected consistently from the host entities available to the storage adapter.
- Whether downstream `MTA-03` adoption needs more source metadata than `sourceSummary` can safely reserve.

### Recommendation

- Confirm the task boundary, but treat the challenged profile as larger and riskier than the initial prediction.
- Do not split the task yet; the added work is foundation validation and schema hardening, not a new product behavior.
- Split or defer only if implementation discovers that chunking, compression, sidecars, public tools, or real adoption behavior are required.

### Challenge Notes

- Scores changed after Step 11 premortem: validation burden `3 -> 4`, discovery risk `2 -> 3`, rework risk `3 -> 4`, confidence `3 -> 2`.
- Functional scope, technical surface, dependency risk, and scope volatility remain unchanged because the plan did not expand into public or adoption/edit behavior.
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

| Dimension | Actual (0-4) | Rationale |
|---|---:|---|
| Functional Scope | 2 | Delivered the planned internal terrain state and storage foundation without adoption, mesh output, public tools, or edit behavior. |
| Technical Change Surface | 3 | Added a new terrain runtime subtree, serializer, storage adapter, repository seam, and terrain test suite. No runtime dispatcher, loader, packaging logic, or public contract code changed. |
| Actual Implementation Friction | 2 | Core implementation was straightforward after TDD skeletons; friction was limited to serializer refusal short-circuiting, constructor shape, and RuboCop-driven reshaping. |
| Actual Validation Burden | 4 | Required focused terrain tests, full Ruby tests, lint, package verification, PAL codereview, review follow-up, and an explicit hosted smoke marker for live persistence. |
| Actual Dependency Drag | 1 | MTA-01 and planning artifacts were sufficient; no upstream code blocker or cross-team coordination appeared during implementation. |
| Actual Discovery Encountered | 2 | Implementation confirmed the planned shape; discovery was limited to test harness order-independence, default migration coverage, and save-summary parsing overhead. |
| Actual Scope Volatility | 1 | Scope stayed internal and did not expand into public MCP tools, adoption, chunking, compression, sidecars, or mesh regeneration. |
| Actual Rework | 2 | PAL review produced targeted follow-up changes, but no architectural rewrite or contract change was needed. |
| Final Confidence in Completeness | 3 | Automated validation and review are strong; confidence remains below 4 until live SketchUp save/reopen persistence is reviewed. |
<!-- SIZE:ACTUAL:END -->

---

<!-- SIZE:VALIDATION-EVIDENCE:START -->
## Validation Evidence Summary

- Focused terrain suite: `bundle exec ruby -Itest -e 'Dir["test/terrain/*_test.rb"].sort.each { |path| load path }'` -> 22 runs, 80 assertions, 0 failures, 1 hosted smoke skip.
- Full Ruby suite: `bundle exec rake ruby:test` -> 561 runs, 2086 assertions, 0 failures, 29 skips.
- Lint: `bundle exec rake ruby:lint` -> 145 files inspected, no offenses.
- Package verification: `bundle exec rake package:verify` -> generated `dist/su_mcp-0.20.0.rbz`.
- PAL codereview: `grok-4.20` completed; one medium test gap and two low improvements were addressed.
- Live SketchUp in-session repository save/load was verified after the stable matrix-signature fix: saved outcome, loaded outcome, payload present under `su_mcp_terrain`, and no payload leak into `su_mcp`.
- Full save/reopen persistence across a SketchUp model restart was verified: owner found, repository loaded the persisted state, payload remained present under `su_mcp_terrain`, and no payload leaked into `su_mcp`.
<!-- SIZE:VALIDATION-EVIDENCE:END -->

---

<!-- SIZE:DELTA:START -->
## Estimation Delta Review

### What The Estimate Got Right

- The task behaved like a medium internal platform slice: no public tool drift, but multiple state/storage/serialization seams.
- Validation was the dominant cost driver because the acceptance criteria depended on many negative paths and deterministic persistence behavior.
- The predicted hosted persistence gap remained real and could not be fully resolved by plain Ruby tests.

### What Was Overestimated

- Dependency and coordination drag were lower than predicted because MTA-01 and the technical plan were sufficient to proceed without upstream rework.
- Scope volatility was lower than predicted; implementation did not pressure the task toward chunking, compression, sidecars, or public commands.

### What Was Underestimated

- Review-driven validation detail was slightly underestimated: the default older-schema migration path needed an explicit test beyond the forced custom-harness migration failure.
- Serializer/repository performance cleanup appeared only during PAL review, not planning, though the follow-up was small.

### Future Analog Notes

- Internal model-embedded storage foundations should be estimated with high validation burden even when functional scope is modest.
- A migration harness requirement should always include both forced-harness and default-harness negative tests.
- Hosted persistence should stay a first-class review gate for any SketchUp attribute-backed state before downstream product tasks claim support.
<!-- SIZE:DELTA:END -->

---

<!-- SIZE:TAGS:START -->
## Retrieval Tags

- `archetype:platform`
- `scope:terrain-state-storage`
- `validation:regression-heavy`
- `systems:domain-repository-adapter-serialization`
- `volatility:medium`
- `friction:medium`
- `rework:medium`
- `confidence:medium`
<!-- SIZE:TAGS:END -->
