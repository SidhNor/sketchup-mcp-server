# Size: STI-02 Explicit Surface Interrogation via sample_surface_z

**Task ID**: STI-02  
**Title**: Explicit Surface Interrogation via sample_surface_z  
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
  - `sample_surface_z` MCP tool contract
  - explicit target resolution and geometry sampling
  - JSON-safe world-space meter serialization
- **Validation Class**: mixed
- **Likely Analog Class**: first explicit-host geometry interrogation tool

### Identity Notes
- Task-only evidence frames this as the first focused `sample_surface_z` deliverable for deterministic explicit-target surface sampling.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Introduces a public explicit surface interrogation tool with hit, miss, and ambiguous outcomes. |
| Technical Change Surface | 3 | Likely touches MCP registration/adapter, Ruby geometry resolution, target references, hit evaluation, ambiguity handling, serialization, and tests. |
| Hidden Complexity Suspicion | 3 | Explicit geometry sampling, visibility defaults, ignore-target behavior, ambiguity, and unit conversion can hide SketchUp-specific edge cases. |
| Validation Burden Suspicion | 3 | Geometry-heavy behavior needs contract checks plus geometry-backed validation or an explicit hosted gap. |
| Dependency / Coordination Suspicion | 2 | Depends on `PLAT-02`, `PLAT-03`, and `STI-01` targeting model. |
| Scope Volatility Suspicion | 2 | The slice is focused, but terrain-aware workflows could pull toward broader probing, bounds, or topology tools. |
| Confidence | 2 | `task.md` gives strong product direction, but this seed intentionally excludes technical planning evidence. |

### Early Signals
- The task explicitly requires Ruby-owned geometry behavior with Python remaining a thin MCP adapter.
- Acceptance criteria require explicit target sampling, structured point-by-point statuses, visibility/ignore-target behavior, meters, and geometry-backed verification.
- Non-goals keep edge-network analysis, bounds tooling, and workflow-specific helper tools out of scope.

### Early Estimate Notes
- Seed shape is a sizable geometry-backed public tool slice, with early risk concentrated in SketchUp geometry semantics and validation confidence.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

> Filled during task planning. This is the main pre-implementation estimate.

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Adds a new public `sample_surface_z` MCP tool with explicit target references, multiple sample points, and structured `hit`/`miss`/`ambiguous` outcomes. |
| Technical Change Surface | 4 | Plan spans Ruby command/sampling/serialization, target resolution, dispatcher, Python tool/schema bridge, shared contracts, docs, and manual SketchUp verification. |
| Implementation Friction Risk | 4 | Requires explicit target-bounded face sampling, transform-aware geometry, ambiguity clustering, visibility/ignore-target behavior, and avoiding generic `raytest` first-hit semantics. |
| Validation Burden Risk | 4 | Plan requires Ruby behavior tests, Python tool tests, shared contract suites, lint/test/package gates, and manual SketchUp verification. |
| Dependency / Coordination Risk | 3 | Depends on `PLAT-02`, `PLAT-03`, `PLAT-05`, `STI-01`, and live SketchUp runtime access for verification. |
| Discovery / Ambiguity Risk | 3 | Plan identifies uncertainty around SketchUp geometry primitives, unit conversion, transformed/nested targets, ambiguity behavior, and hosted runtime coverage. |
| Scope Volatility Risk | 2 | Scope is narrow around one tool, but broad discovery, bounds, topology, debug knobs, or workflow helpers could pull it wider. |
| Rework Risk | 3 | Wrong sampling primitive, unit serialization, ambiguity model, or Python/Ruby contract drift could force meaningful revision. |
| Confidence | 3 | Planning evidence is detailed and API research-backed, but live SketchUp geometry confidence remains unresolved until verification. |

### Top Assumptions
- `STI-01` target-reference direction is stable enough for `sample_surface_z` to consume.
- Ruby can own explicit face collection, vertical sampling, ambiguity clustering, and meter serialization without moving policy into Python.
- Python can remain a thin typed-schema and bridge adapter for the new public tool.
- Manual SketchUp verification can provide enough live geometry confidence until hosted automation arrives under `PLAT-06`.

### Estimate Breakers
- If `Model#raytest` or first-hit behavior becomes necessary, explicit target ambiguity semantics would need redesign.
- If transformed group/component sampling cannot be validated in Ruby tests or manual SketchUp checks, implementation friction and confidence risk increase.
- If public meter serialization cannot be separated from inspection serializer behavior, contract reliability is at risk.
- If Python begins owning semantic validation or geometry policy, runtime boundary and test surface widen materially.

### Predicted Signals
- The plan adds a new public Python tool and Ruby dispatch path while keeping geometry behavior in Ruby.
- Sampling must support face, group, and component-instance targets with visibility and ignore-target behavior.
- The plan rejects generic ray probing because first-hit semantics cannot expose explicit-target ambiguity.
- Contract work crosses shared bridge artifacts plus Ruby and Python invariant suites.

### Predicted Estimate Notes
- Predicted size is high because this is the first explicit-host geometry interrogation tool and spans both Ruby runtime behavior and Python MCP adapter exposure.
<!-- SIZE:PREDICTED:END -->

---

<!-- SIZE:CHALLENGE:START -->
## Challenge Review

> Filled when the estimate is pressure-tested through external review, premortem, or controlled consensus.

### Agreed Drivers
- Explicit-target geometry sampling is the primary complexity driver: the tool must not degrade into generic scene probing or first-hit behavior.
- Cross-runtime contract work is significant because the tool is exposed through Python while Ruby owns semantics.
- Unit and serialization correctness matter because public values must be world-space meters, not SketchUp internal units.
- Live SketchUp verification is necessary because fake-scene tests cannot fully prove transformed geometry, visibility, and ambiguity behavior.

### Contested Drivers
- Manual verification can provide near-term confidence, but lack of hosted automation leaves residual risk.
- V1 keeps non-hit metadata minimal, which reduces surface area but may limit diagnosability for downstream workflows.
- Supporting face, group, and component-instance targets is useful, but transform/nested behavior may be harder than local tests imply.

### Missing Evidence
- Live SketchUp verification for representative visible top-face hit, ignored occluder, unsupported target failure, and competing-surface ambiguity.
- Proof that the dedicated meter-space serializer avoids inspection-style model precision or internal unit leakage.
- End-to-end contract evidence across Ruby, Python, and the shared bridge artifact.

### Recommendation
- confirm estimate

### Challenge Notes
- Planning risks support the predicted high technical surface, implementation friction, and validation burden. No score revision is needed because the predicted profile already includes live-runtime and cross-runtime contract uncertainty.
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
| Functional Scope | 3 | Shipped public `sample_surface_z` bridge contract cases, Ruby-owned explicit surface interrogation, and Python MCP registration. |
| Technical Change Surface | 4 | Touched Ruby command/query/serializer, dispatcher, Python tool schema/bridge forwarding, shared bridge contracts, and test support. |
| Actual Implementation Friction | 3 | Implementation required a new `SampleSurfaceQuery`, custom test overlays, transform-aware traversal, occlusion filtering, clustering, and face-plane/classify-point evaluation. |
| Actual Validation Burden | 2 | Broad Ruby, Python, and contract coverage was added. Manual live SketchUp verification remained outstanding, which is a confidence gap rather than completed validation burden. |
| Actual Dependency Drag | 2 | Work depended on Ruby/Python bridge contracts and prior targeting/platform seams, but no external blocker is recorded. |
| Actual Discovery Encountered | 3 | Review/implementation replaced an unsafe bounds-center shortcut with runtime face-plane intersection plus `classify_point`, and test support had to model richer geometry. |
| Actual Scope Volatility | 1 | Scope stayed focused on `sample_surface_z`; no bounds, topology, broad discovery, or workflow helper tools were added. |
| Actual Rework | 3 | The Ruby sampling path was materially reworked to carry transformations and use live-compatible face-plane/classification behavior. |
| Final Confidence in Completeness | 3 | Automated and contract evidence is strong, but summary explicitly leaves manual SketchUp verification outstanding. |

### Actual Signals
- `summary.md` records shipped bridge contract cases for `hit`, `miss`, `ambiguous`, mixed multi-point results, ignore-target behavior, and unsupported-target failure.
- Ruby implementation added `SampleSurfaceQuery` for target resolution, face collection, occlusion filtering, ambiguity clustering, and compact result shaping.
- Dedicated meter-space sample serialization was added to keep `sample_surface_z` separate from broader inspection serializer output.
- Ruby sampling was reworked from an unsafe bounds-center fallback to transform-aware face-plane intersection plus `classify_point` for non-fixture SketchUp faces.

### Actual Notes
- Actual work matched the predicted high technical surface. The main shortfall is validation confidence, not feature scope: manual live SketchUp verification remained open after automated coverage.
<!-- SIZE:ACTUAL:END -->

---

<!-- SIZE:VALIDATION-EVIDENCE:START -->
## Validation Evidence Summary

> Fill only the sections that are relevant. Say `not applicable` where needed.

### Automated Validation
- Ruby command coverage added for request validation, face/group/component targets, `hit` / `miss` / `ambiguous` outcomes, visible-only interference, ignore-target behavior, point-order preservation, clustering tolerance, and meter-space serialization.
- Ruby command coverage added for transformed nested targets and sloped-face sampling.
- Ruby dispatcher coverage added for `sample_surface_z`.
- Python tool coverage added for registration order, nested schema visibility, passthrough request shaping, and request-id propagation.
- Ruby and Python contract coverage added for the shared bridge cases.

### Manual Validation
- Manual SketchUp verification is still required for representative geometry scenarios, especially live runtime face-plane/classification behavior beyond non-hosted fixtures.

### Performance Validation
- Not applicable; no performance-specific validation was recorded for this task.

### Migration / Compatibility Validation
- Shared bridge contract cases were added for representative success, uncertainty, ignore-target, mixed, and unsupported-target behavior.

### Operational / Rollout Validation
- Python MCP registration was added with typed nested models and thin bridge forwarding.

### Validation Notes
- Validation was broad across automated Ruby, Python, and contract layers, but final confidence is limited because live SketchUp verification was explicitly left outstanding.
<!-- SIZE:VALIDATION-EVIDENCE:END -->

---

<!-- SIZE:DELTA:START -->
## Estimation Delta Review

> Filled during final calibration. Compare prediction to actual behavior.

- **Most Underestimated Dimension**: Rework pressure. The plan anticipated geometry risk, but the final Ruby sampling path was materially reworked away from the earlier bounds-center fallback.
- **Most Overestimated Dimension**: Validation burden as completed effort. The plan expected manual SketchUp verification, but summary evidence shows that live layer remained a gap.
- **Signal Present Early But Underweighted**: Transform-aware live geometry behavior was known as a risk and ultimately drove implementation rework plus a remaining manual verification gap.
- **Genuinely Unknowable Factor**: The exact adequacy of the face-plane/classification path against live SketchUp entities remained unproven because manual verification was not completed.
- **Future Similar Tasks Should Assume**: First-generation geometry tools crossing Ruby and Python need explicit budget for live SketchUp verification and likely geometry-seam rework after review.

### Calibration Notes
- Prediction was accurate on high technical surface and implementation friction. Actual scope stayed contained, while confidence remained capped by the hosted/manual verification gap.
<!-- SIZE:DELTA:END -->

---

<!-- SIZE:TAGS:START -->
## Retrieval Tags

- `archetype:feature`
- `scope:scene-targeting-interrogation`
- `validation:contract`
- `host:not-run-gap`
- `systems:sample-surface-z`
- `systems:target-resolution`
- `systems:surface-sampling`
- `risk:transform-semantics`
- `volatility:medium`
- `friction:high`
- `rework:medium`
- `confidence:medium`
<!-- SIZE:TAGS:END -->
