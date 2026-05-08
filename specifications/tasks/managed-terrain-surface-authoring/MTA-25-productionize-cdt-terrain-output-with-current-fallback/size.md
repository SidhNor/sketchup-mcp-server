# Size: MTA-25 Productionize CDT Terrain Output With Current Backend Fallback

**Task ID**: `MTA-25`
**Title**: Productionize CDT Terrain Output With Current Backend Fallback
**Status**: `challenged`
**Created**: 2026-05-07
**Last Updated**: 2026-05-08

**Related Task**: [task.md](./task.md)
**Related Plan**: [plan.md](./plan.md)
**Related Summary**: none yet

---

<!-- SIZE:IDENTITY:START -->
## Identity

- **Task Archetype**: `archetype:performance-sensitive`
- **Primary Scope Area**: `scope:managed-terrain`
- **Likely Systems Touched**:
  - `systems:terrain-output`
  - `systems:terrain-mesh-generator`
  - `systems:terrain-kernel`
  - `systems:public-contract`
  - `systems:scene-mutation`
- **Validation Modes**: `validation:performance`, `validation:hosted-matrix`, `validation:contract`, `validation:undo`, `validation:persistence`
- **Likely Analog Class**: production terrain backend promotion from comparison prototype with fallback gates

### Identity Notes
- MTA-25 turns the MTA-24 CDT direction into a production output path rather than another
  comparison-only bakeoff.
- Current production output remains a required fallback, so this is a gated productionization task,
  not a direct backend swap.
- MTA-24 calibration is the closest analog, especially its repeated hosted validation and
  evidence-harness cleanup lessons.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Makes CDT eligible for production terrain output while preserving current fallback and public contract stability. |
| Technical Change Surface | 4 | Likely spans production output routing, CDT backend hardening, fallback gates, harness cleanup, contract tests, hosted validation support, and packaging checks. |
| Hidden Complexity Suspicion | 4 | Runtime gates, topology validity, constraint recovery, fallback correctness, and separation of prototype harnesses from runtime ownership are high-risk. |
| Validation Burden Suspicion | 4 | Requires full local validation plus hosted production-path evidence, fallback cases, performance interpretation, undo, and save/reopen where practical. |
| Dependency / Coordination Suspicion | 3 | Depends on MTA-20 feature geometry, MTA-22 fixtures, MTA-24 CDT evidence, live SketchUp access, and user visual validation. |
| Scope Volatility Suspicion | 3 | The task is bounded by fallback-first productionization, but runtime or constraint failures may split native acceleration or contract work into separate tasks. |
| Confidence | 2 | MTA-24 gives strong direction, but production routing and fallback quality still need a technical plan and hosted proof. |

### Early Signals
- MTA-24 selected CDT directionally but explicitly did not claim production readiness.
- MTA-24 found that live validation and equivalence proof can dominate terrain backend work.
- Runtime pressure on high-relief and residual retriangulation cases is already known.
- Hard-geometry classifier precision and conservative protected-crossing metrics need production
  acceptance criteria before fallback can be narrowed.
- Task-specific MTA-24 bakeoff helpers must be isolated or removed before long-lived production
  wiring.

### Early Estimate Notes
- Seed scoring uses MTA-24 as a calibrated analog. The strongest risk is not whether CDT can emit
  candidate meshes; it is whether CDT can become a production path with deterministic fallback,
  stable contracts, and hosted acceptance.
- Native C++ remains a possible planning outcome but is not assumed in the seed.
- The technical plan should evaluate a native/C++ triangulation library adapter if pure Ruby CDT
  cannot satisfy production runtime gates, while avoiding premature native packaging scope in the
  task definition.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

> Filled during task planning. This is the main pre-implementation estimate.

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Makes CDT eligible for real production terrain output behind fallback, but keeps public controls and contracts unchanged. |
| Technical Change Surface | 4 | Spans production output routing, generator mutation ordering, CDT envelope/adapter/gates, command state handoff, contract tests, package checks, and hosted acceptance artifacts. |
| Implementation Friction Risk | 4 | Production CDT must harden prototype triangulation, normalize constraints, gate residual/topology/hard geometry, and preserve SketchUp mutation invariants before erase. |
| Validation Burden Risk | 4 | Requires local unit/integration/contract/package proof plus hosted accepted and forced-fallback matrices with timing, topology, undo, and persistence evidence. |
| Dependency / Coordination Risk | 3 | Depends on MTA-20/MTA-22/MTA-23/MTA-24 artifacts, live SketchUp MCP access, user visual acceptance, and possible native/poly2tri readiness decisions. |
| Discovery / Ambiguity Risk | 3 | Planning fixed the main boundaries, but Ruby runtime viability, exact thresholds, topology precision, and native compatibility remain material unknowns. |
| Scope Volatility Risk | 3 | Scope is bounded by fallback-first productionization, yet Ruby gate failure, native adapter need, hosted defects, or public contract pressure could force split/follow-up decisions. |
| Rework Risk | 4 | MTA-24 and MTA-19 analogs show terrain backend work can require repeated correction across residual logic, topology gates, hosted evidence, and output mutation assumptions. |
| Confidence | 2 | The plan is detailed and analog-backed, but confidence stays moderate-low until production CDT gates and hosted SketchUp acceptance run. |

### Top Assumptions
- The current production backend can remain a reliable fallback without changing public MCP
  request/response shape.
- MTA-24 CDT internals can be reused or wrapped without pulling MTA-24 comparison rows or hosted
  probe helpers into the production call graph.
- `TerrainFeatureGeometry` plus final terrain state are sufficient to normalize CDT primitive input
  and evaluate hard/firm/soft tolerances.
- Ruby CDT can satisfy at least a useful accepted-case subset under named gates; otherwise current
  fallback remains retained and native/poly2tri work is split or explicitly scoped.
- Hosted SketchUp access and user/live visual review will be available to close topology,
  hard-geometry, undo, and save-copy/save-reopen evidence.

### Estimate Breakers
- Pure Ruby CDT cannot pass runtime gates for representative accepted cases, requiring native/C++
  adapter work inside MTA-25 rather than as a deferred follow-up.
- `TerrainMeshGenerator` cannot compute/gate CDT before erasing old output without significant
  restructuring of current fallback and partial-regeneration behavior.
- Feature geometry normalization cannot map protected/reference/intersecting/hole-like cases into
  deterministic fallback reasons without losing required production intent.
- Hosted validation exposes invalid SketchUp topology, undo, persistence, or partial-state failures
  that force redesign of emission or operation ordering.
- A public contract change becomes unavoidable to expose necessary fallback or backend diagnostics,
  triggering native catalog, dispatcher, docs/example, and fixture scope.

### Predicted Signals
- MTA-24 is the closest analog: actual implementation friction, validation burden, discovery, and
  rework were all high, and it still stopped short of production mutation.
- MTA-23 showed that terrain backend candidates need feature-aware diagnostics and hosted evidence,
  while MTA-19 showed local residual/sample correctness does not prove SketchUp topology.
- The draft plan intentionally keeps CDT compute data-only and mutation under
  `TerrainMeshGenerator`, which reduces contract risk but increases generator integration and
  ordering test burden.
- The TDD minimum coverage inventory is broad by design: contract no-leak, envelope, adapter
  conformance, gates, generator mutation, command state, harness isolation, package verification,
  and hosted acceptance all remain required.
- Native/poly2tri is not mandatory in the plan, but adapter hardening and native-unavailable/input
  violation behavior are required because Ruby performance and robustness are not yet proven.

### Predicted Estimate Notes
- This prediction is the 2026-05-08 planning baseline after Step 10 created the draft technical
  plan and after refinement added the hardened triangulation adapter/native-readiness requirement.
- Functional scope is `3`, not `4`, because public tools and user controls stay unchanged and the
  current backend remains fallback. The behavior is still production-visible because accepted CDT
  can emit real derived terrain output.
- Technical surface is `4` because the task crosses production output mutation, computational
  geometry, fallback taxonomy, command/generator state handoff, packaging/no-leak checks, and hosted
  acceptance evidence.
- Validation and rework stay at `4` by outside-view calibration from MTA-24 and MTA-19: the risky
  part is not generating triangles, but proving the generated SketchUp scene is valid, reversible,
  persistent enough, and safe to fall back from.
<!-- SIZE:PREDICTED:END -->

---

<!-- SIZE:CHALLENGE:START -->
## Challenge Review

> Filled when the estimate is pressure-tested through external review, premortem, or controlled consensus.

### Agreed Drivers
- Functional scope remains `3`: CDT becomes eligible for real production terrain output, but public
  controls, MCP contracts, and current-backend fallback remain unchanged.
- Technical change surface remains `4`: the plan spans production mutation ordering,
  command/generator handoff, CDT result envelopes, adapter normalization, gates, package/no-leak
  checks, and hosted acceptance artifacts.
- Implementation friction remains `4`: the hard part is not triangle generation alone; it is making
  residual-driven CDT safe inside SketchUp mutation semantics with deterministic fallback.
- Validation burden remains `4`: this is high because of performance, topology, undo, persistence,
  public no-leak, forced-fallback, and hosted interpretation requirements, not merely because a
  hosted matrix exists.
- Dependency risk remains `3`: upstream MTA artifacts and live SketchUp/user visual access matter,
  but native/poly2tri remains optional unless Ruby evidence fails gates.
- Confidence remains `2`: the plan is concrete and externally reviewed, but production CDT and host
  evidence do not exist yet.

### Contested Drivers
- Technical change surface could be argued as `3` because work stays inside the terrain capability
  and avoids public schema changes. It remains `4` because the implementation crosses production
  output mutation, computational geometry, fallback routing, package/no-leak checks, and hosted
  acceptance proof.
- Validation burden could be argued as `3` if the hosted matrix runs cleanly. It remains `4` because
  MTA-24 and the premortem both point to likely interpretation/retest cost across topology,
  save-copy/save-reopen, undo, screenshots/entity counts, and forced fallback.
- Scope volatility could rise to `4` if Ruby CDT fails production gates and native/poly2tri packaging
  must be implemented inside MTA-25. It remains `3` because the plan explicitly allows fallback
  retention and native follow-up instead of forcing an in-task native bridge.
- Rework risk could be argued as `3` because the premortem added guardrails before implementation.
  It remains `4` by MTA-24/MTA-19 outside-view evidence: terrain backend proof often revisits
  residual logic, topology checks, and mutation assumptions after hosted evidence.

### Missing Evidence
- No production proof yet that Ruby CDT can satisfy accepted-case runtime, residual, hard-geometry,
  and topology gates.
- No hosted SketchUp proof yet for accepted CDT or forced fallback output, including undo,
  save-copy/save-reopen, screenshots/entity counts, and visible gap/hard-geometry acceptance.
- No implementation proof yet that current fallback refusal can remain byte-identical publicly when
  CDT is attempted versus disabled.
- No package proof yet that native-unavailable behavior works without a native binary and that
  MTA-24 harness symbols do not leak into packaged public behavior.
- No final threshold calibration yet for runtime, residual, topology, dense-ratio, hard-anchor, and
  visible-gap gates.

### Recommendation
- Confirm the predicted profile with no score revisions.
- Proceed with the finalized `WARN` premortem gate.
- Do not split native/poly2tri work now; split or explicitly scope it only if Ruby CDT fails the
  planned production gates.
- Do not narrow or retire current fallback unless hosted evidence closes accepted-CDT and
  forced-fallback behavior.
- During task implementation, convert the TDD minimum inventory into an ordered failing skeleton and
  preserve or expand the coverage surface.

### Challenge Notes
- Challenge evidence came from the Step 12 premortem, PAL challenge prompt, Grok 4.3 premortem
  review, MTA-24 calibrated actuals, and MTA-19 negative topology history.
- The challenge produced plan corrections rather than estimate revisions: byte-identical refusal
  checks, dirty-window/CDT non-mixing, packaged native-unavailable behavior, limitation prevalidation,
  and richer hosted evidence rows.
- The final plan and challenged estimate agree: this is a bounded no-public-contract production
  backend promotion with high technical/validation/rework risk, retained fallback, and explicit
  native readiness without mandatory native packaging.
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
| Functional Scope | <0-4> | <short note> |
| Technical Change Surface | <0-4> | <short note> |
| Actual Implementation Friction | <0-4> | <short note> |
| Actual Validation Burden | <0-4> | <short note> |
| Actual Dependency Drag | <0-4> | <short note> |
| Actual Discovery Encountered | <0-4> | <short note> |
| Actual Scope Volatility | <0-4> | <short note> |
| Actual Rework | <0-4> | <short note> |
| Final Confidence in Completeness | <0-4> | <short note> |

### Actual Signals
- Not filled yet.

### Actual Notes
- Not filled yet.
<!-- SIZE:ACTUAL:END -->

---

<!-- SIZE:VALIDATION-EVIDENCE:START -->
## Validation Evidence Summary

> Fill only the sections that are relevant. Say `not applicable` where needed.

### Automated Validation
- Not filled yet.

### Hosted / Manual Validation
- Not filled yet.

### Performance Validation
- Not filled yet.

### Migration / Compatibility Validation
- Not filled yet.

### Operational / Rollout Validation
- Not filled yet.

### Validation Notes
- Not filled yet.
<!-- SIZE:VALIDATION-EVIDENCE:END -->

---

<!-- SIZE:DELTA:START -->
## Estimation Delta Review

> Filled during final calibration. Compare prediction to actual behavior.

- **Most Underestimated Dimension**: <dimension + why>
- **Most Overestimated Dimension**: <dimension + why>
- **Signal Present Early But Underweighted**: <note>
- **Genuinely Unknowable Factor**: <note or `none identified`>
- **Future Similar Tasks Should Assume**: <note>

### Calibration Notes
- Not filled yet.
<!-- SIZE:DELTA:END -->

---

<!-- SIZE:TAGS:START -->
## Retrieval Tags

- `archetype:performance-sensitive`
- `scope:managed-terrain`
- `systems:terrain-output`
- `systems:terrain-mesh-generator`
- `systems:terrain-kernel`
- `validation:performance`
- `validation:hosted-matrix`
- `validation:contract`
- `validation:undo`
- `validation:persistence`
- `host:repeated-fix-loop`
- `contract:no-public-shape-change`
- `risk:performance-scaling`
- `risk:transform-semantics`
- `volatility:medium`
- `confidence:low`
<!-- SIZE:TAGS:END -->
