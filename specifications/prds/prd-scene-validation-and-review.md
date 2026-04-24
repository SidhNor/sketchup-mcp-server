---
doc_type: prd
title: Scene Validation and Review
status: draft
last_updated: 2026-04-24
---

# PRD: Scene Validation and Review

## Problem statement

Automated scene construction is not trustworthy unless the system can measure what changed, verify that required objects exist and preserved objects remain intact, and produce review artifacts for humans or downstream agents.

Today, success is too easy to infer from command completion alone. The product needs a structured validation and review layer that can answer whether a scene update is acceptable, what failed, what should be inspected next, and whether the scene still satisfies important geometry, metadata, and protection expectations.

Without a strong validation and review slice:

- command completion is mistaken for scene correctness
- geometry-aware failures such as bad surface relationships or broken edge networks pass unnoticed
- Asset Exemplar protection violations can slip into accepted workflows
- humans and downstream agents lack enough structured evidence to diagnose failures quickly

## Goals

1. Provide first-class structured measurement for common scene checks.
2. Provide a primary validation endpoint for scene updates.
3. Detect common failure modes including missing entities, metadata gaps, dimension mismatches, geometry relationship failures, topology issues, and Asset Exemplar protection violations.
4. Support iterative review loops with scene snapshots and structured findings.
5. Reduce silent failures in agent-driven modeling workflows.

## Success Metrics & KPI

| Metric | Baseline | Target | Measurement Method | Timeline |
| --- | --- | --- | --- | --- |
| Material scene updates followed by a validation run | No formal validation workflow baseline today | >= 90% of material updates | Workflow telemetry and scenario audit of update-to-validation sequencing | Within first validation MVP release cycle |
| Validation failures returning structured error categories | Current failures are often generic or tool-specific | >= 95% of failures produce structured categories | Automated validation test suite and error-shape contract checks | Within first validation MVP release cycle |
| Representative modeling regressions caught before human acceptance | No regression-catch benchmark today | >= 80% of representative regressions caught | Curated scenario suite comparing expected failures against validation output | Within two releases after validation MVP launch |
| Median time to diagnose a failed scene update | Current manual-inspection diagnosis time to be measured during discovery | >= 50% reduction from measured baseline | Timed troubleshooting scenarios with and without validation outputs | Within two releases after validation MVP launch |
| Review workflows attaching a snapshot when validation fails or warnings remain | No formal snapshot-review baseline today | >= 70% of qualifying review workflows | Workflow telemetry and review artifact audit | Within two releases after validation MVP launch |

**Primary KPI**

- Material scene updates followed by a validation run

**Secondary KPI**

- Validation failures returning structured error categories
- Representative modeling regressions caught before human acceptance
- Median time to diagnose a failed scene update
- Review workflows attaching a snapshot when validation fails or warnings remain

## Target Users

- AI agents executing and checking scene updates
- Designers reviewing proposed changes
- Technical operators verifying retained context, clearances, topology, and object integrity
- Developers building automation workflows on top of SketchUp MCP

## User Flows & Scenarios

### Flow 1: Validate a design option update

1. The agent applies a scene update.
2. The system runs `validate_scene_update` against expected entities, metadata, dimensions, geometry relationships, projection-aware expectations, and protected assets.
3. The system returns structured pass, fail, warning, and summary data.
4. The agent revises the scene or surfaces the result to a human reviewer.

### Flow 2: Measure a required clearance or surface condition

1. The user asks whether a retained tree conflicts with a proposed path or whether a point or feature relates correctly to terrain.
2. The system runs `measure_scene` in clearance, distance, bounds, slope hint, or another supported measurement mode.
3. The result is included in a decision or used as part of a validation rule.

### Flow 3: Capture a review artifact after warnings or failure

1. Validation fails or warnings remain.
2. The system captures a scene snapshot.
3. The snapshot is attached to the review flow or external workflow for inspection.
4. The reviewer uses the snapshot together with structured findings instead of treating the image as the correctness signal by itself.

## Functional Requirements

| Requirement | User Story | Acceptance Criteria | Priority |
| --- | --- | --- | --- |
| Support structured measurement through `measure_scene` | As an agent, I want to measure scene properties without arbitrary Ruby so that I can reason about fit and constraints programmatically | `measure_scene` accepts documented measurement modes and returns structured, JSON-serializable outputs | P1 |
| Support a bounded `measure_scene` MVP with `distance`, `area`, `height`, and `bounds` modes before broader measurement modes | As a designer or agent, I want the first public measurement surface to answer common size and fit questions without ambiguous measurement semantics | The MVP supports explicit `mode` and `kind` combinations for `bounds/world_bounds`, `height/bounds_z`, `distance/bounds_center_to_bounds_center`, `area/surface`, and `area/horizontal_bounds`, returns unit-bearing quantities and evidence, and refuses unsupported combinations explicitly | P1 |
| Support later terrain-aware measurement evidence without turning direct measurement into terrain editing | As a reviewer or agent, I want terrain-shaped objects and terrain-dependent checks to produce structured measurement evidence while keeping editing and validation verdicts separate | Terrain-shaped groups and components can be measured through generic supported modes where generic evidence exists, while terrain profile, slope, clearance-to-terrain, grade-break, trench/hump, and fairness measurements remain documented follow-ons that build on explicit surface interrogation and reusable measurement internals | P1 |
| Prefer workflow-facing identity conventions in measurement and validation references | As a workflow orchestrator, I want checks to reference the same identity model as upstream workflows so that validation stays stable across revisions | Measurement and validation contracts prefer `sourceElementId`, support `persistentId` where runtime-safe lookup is needed, and reserve `entityId` for compatibility-only use | P0 |
| Support structured scene validation through `validate_scene_update` | As a workflow orchestrator, I want a single primary validation endpoint for scene updates | Given a valid expectation payload, `validate_scene_update` returns structured pass or fail state with findings and summary data | P0 |
| Validate required entity existence, preserved entity presence, required metadata keys, tags when specified, material presence when specified, and dimension or tolerance checks | As an agent, I want to catch common scene-update failures before acceptance | Validation supports each listed check type and returns structured findings that map to the failing expectation | P0 |
| Validate geometry-aware expectations including expected surface relationships and topology expectations for edge networks | As a reviewer or agent, I want correctness checks that go beyond metadata so that geometry failures do not slip through acceptance | Validation can evaluate documented geometry checks such as named points on a target surface, named reference points against canonical XY expectations, and edge-network expectations for projected or reprojected linework, and returns structured findings when those checks fail | P1 |
| Validate terrain-dependent object relationships after terrain changes | As a reviewer or agent, I want to detect when hosted or terrain-dependent objects become unsupported, hanging, or unexpectedly intersecting terrain after terrain edits so that scene correctness does not depend on visual inspection alone | Validation can evaluate documented terrain-relationship checks for managed objects against an explicit host terrain target, including at minimum supported-on-terrain, clearance-to-terrain, or intersecting-terrain style outcomes where the workflow has supplied the required anchors, tolerances, or target references | P1 |
| Detect accidental edits to protected Asset Exemplars and asset-placement failures | As a library curator or workflow client, I want the validation layer to catch staged-asset violations before acceptance | Validation can report no accidental edits to library assets and detect when expected asset placement or replacement outcomes did not succeed | P1 |
| Return overall pass or fail state, structured errors, structured warnings, and validation summary data | As a downstream client, I want validation results I can consume programmatically | Validation responses include all listed fields in a stable structured schema | P0 |
| Support review artifact generation through `capture_scene_snapshot` | As a reviewer, I want a visual artifact when a scene needs inspection | The system can capture a named snapshot or review artifact without corrupting semantic scene state | P1 |
| Ensure validation and measurement outputs are serializable and usable without free-form parsing | As an MCP client, I want reliable automation-friendly outputs | Measurement, validation, and snapshot outputs do not require text scraping and contain no raw SketchUp objects | P0 |
| Support future safer scoped fallback execution while keeping validation independent from arbitrary Ruby | As a product owner, I want an escape hatch without making validation unstructured | Validation remains fully structured and does not require arbitrary Ruby to determine correctness; any future fallback integration must preserve this rule | P1 |

Conflict flag: no functional requirements currently conflict with the business rules in [`domain-analysis.md`](../domain-analysis.md); this PRD depends on the standalone targeting/interrogation slice for some geometry-aware checks, and that dependency is already reflected in the current domain model.

## Non Functional Requirements

- Validation behavior must be deterministic against the same scene state and expected contract.
- Error categories must be stable enough for downstream automation.
- Measurement and validation should complete fast enough for iterative design loops.
- Snapshot creation should not mutate semantic scene state beyond creation of the review artifact itself.
- The validation subsystem must remain extensible as new semantic object types and geometry checks are introduced.

## Constraints

- Validation must operate on JSON-serializable scene representations and metadata.
- The system must run inside SketchUp’s execution model and cannot depend on external geometry services.
- Validation must work with both Managed Scene Objects and protected Asset Exemplars.
- The product should prefer a few strong validators over many narrow, overlapping validation tools.
- Review artifacts support inspection and diagnosis but must not become the primary correctness signal.

## Out of Scope

- Full rule-engine authoring interfaces for non-technical users
- Advanced clash detection beyond the defined MVP checks
- Photoreal review pipelines
- General-purpose reporting dashboards
- Making `eval_ruby` a primary validation mechanism
- Terrain editing, terrain patch replacement, terrain sculpting, or terrain fairing as validation or measurement behavior

## Open Questions

- Which validation failures should be blocking versus warning-level by default?
- How much geometry-derived inference should validation perform versus relying on metadata and explicit expectations?
- Which terrain-relationship failures after terrain edits should be blocking by default versus warning-only for different object classes such as paths, pads, retaining edges, trees, and rigid structures?
- Which terrain-aware measurement modes should follow the generic `measure_scene` MVP, and which should remain validation-only checks rather than direct measurement outputs?
- What snapshot formats should be supported in the MVP?
- Should post-`eval_ruby` validation become mandatory once scoped fallback execution exists?
- Which overlap checks, if any, should be part of the MVP versus deferred to later validation phases?
- Should repeated projected-boundary verification patterns remain expressed through `validate_scene_update` geometry checks, or eventually justify a higher-level validation helper if the expectation payload becomes too cumbersome?

## Risks and Mitigation

| Risk | Likelihood | Impact | Mitigation Strategy |
| --- | --- | --- | --- |
| Command success is mistaken for scene correctness | High | High | Make validation an expected step in update workflows and track validation coverage |
| Validation output is too generic to be actionable | Medium | High | Define stable structured error categories, summaries, and finding shapes |
| Geometry-aware failures remain under-detected | Medium | High | Include explicit surface-relationship and topology expectation checks in the validation contract |
| Asset Exemplar corruption goes unnoticed | Medium | High | Include explicit Asset Exemplar protection checks in validation and run them consistently |
| Snapshots are treated as a substitute for validation | Medium | Medium | Keep snapshotting as a review aid and not as a correctness signal |

## Dependencies

- [`domain-analysis.md`](../domain-analysis.md)
- [`prd-scene-targeting-and-interrogation.md`](./prd-scene-targeting-and-interrogation.md)
- [`prd-semantic-scene-modeling.md`](./prd-semantic-scene-modeling.md)
- [`prd-staged-asset-reuse.md`](./prd-staged-asset-reuse.md)
- Managed Scene Object metadata and lookup model
- Structured serialization of bounds, materials, metadata, and geometry-check outputs
- Guide-defined validation direction from [`sketchup_mcp_guide.md`](../../sketchup_mcp_guide.md)

## Revision History

| Date | Change |
| --- | --- |
| 2026-04-10 | Initial PRD created. |
| 2026-04-11 | Refined the PRD against the updated guide, added lightweight front matter and revision history, and tightened the slice around structured measurement, validation, geometry-aware checks, and review artifacts. |
| 2026-04-11 | Modestly clarified that geometry-aware validation includes projection-oriented checks such as named reference points and projected linework verification, while deferring any decision on a dedicated higher-level helper. |
| 2026-04-12 | Rebalanced priorities to align with the guide's first-wave focus on `validate_scene_update`, moving `measure_scene`, richer geometry checks, and asset-protection validation work to P1. |
| 2026-04-22 | Added a narrow terrain-relationship validation requirement so post-terrain-edit failures such as hanging, unsupported, or unexpectedly intersecting managed objects can be checked through structured validation without promoting broad terrain authoring into this slice. |
| 2026-04-24 | Aligned the measurement posture with the bounded `SVR-03` `measure_scene` MVP, keeping terrain-shaped targets compatible with generic modes while deferring profile, slope, clearance-to-terrain, grade-break, trench/hump, and fairness diagnostics. |
