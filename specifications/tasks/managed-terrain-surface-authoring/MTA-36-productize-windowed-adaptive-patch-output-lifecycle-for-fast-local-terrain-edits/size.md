# Size: MTA-36 Productize Windowed Adaptive Patch Output Lifecycle For Fast Local Terrain Edits

**Task ID**: `MTA-36`  
**Title**: `Productize Windowed Adaptive Patch Output Lifecycle For Fast Local Terrain Edits`  
**Status**: `calibrated`  
**Created**: `2026-05-11`  
**Last Updated**: `2026-05-12`  

**Related Task**: [task.md](./task.md)  
**Related Plan**: [plan.md](./plan.md)  
**Related Summary**: [summary.md](./summary.md)  

---

<!-- SIZE:IDENTITY:START -->
## Identity

- **Task Archetype**: `archetype:integration`
- **Primary Scope Area**: `scope:managed-terrain`
- **Likely Systems Touched**:
  - `systems:terrain-output`
  - `systems:terrain-mesh-generator`
  - `systems:scene-mutation`
  - `systems:managed-object-metadata`
  - `systems:public-contract`
- **Validation Modes**:
  - `validation:hosted-matrix`
  - `validation:performance`
  - `validation:contract`
  - `validation:persistence`
  - `validation:undo`
- **Likely Analog Class**: adaptive local-output replacement lifecycle with hosted performance proof

### Identity Notes
- Seeded from the MTA-36 task definition, MTA-35 lifecycle carry-forward, existing adaptive output
  direction, and user clarification that stable ownership itself should be treated as simple
  contract-preserving metadata, not as a major complexity driver.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Adds a production local adaptive patch edit path for normal terrain workflows, repeated edits, fallback, hosted proof, and performance evidence while keeping public contracts unchanged. |
| Technical Change Surface | 3 | Likely spans adaptive output generation, patch/window routing, scene mutation sequencing, metadata writes/readback, audits, timing probes, and no-leak contract checks, but excludes CDT solver/topology work. |
| Hidden Complexity Suspicion | 2 | Stable ownership is expected to be straightforward metadata/bookkeeping; remaining risk is mostly conformance-band replacement, no-delete sequencing, repeated metadata freshness, and SketchUp cleanup behavior. |
| Validation Burden Suspicion | 4 | Hosted proof must cover visual correctness, timing versus full adaptive regeneration, repeated edits, fallback/no-delete, undo, reload/readback or safe invalidation, and public contract no-leak behavior. |
| Dependency / Coordination Suspicion | 2 | Depends on prior adaptive output and replacement lessons plus later MTA-35 replan, but avoids CDT substrate dependency and stays inside the same runtime ownership boundary. |
| Scope Volatility Suspicion | 2 | Scope should stay bounded if the lightweight patch lifecycle is enough; volatility mainly comes from measured performance failures, conformance edge cases, or a need for heavier registry/index machinery. |
| Confidence | 3 | The task shape is explicit and stable ownership has been clarified as low complexity, though confidence should stay below high until a technical plan and hosted timing evidence exist. |

### Early Signals
- The task intentionally separates the patch/window lifecycle from CDT, reducing MTA-35's combined
  solver-plus-lifecycle risk.
- Stable ownership should be owner-local metadata that does not touch public terrain contracts and
  should not be treated as a hard design problem.
- Production safety still requires building and validating affected output before erasing old output.
- Timing evidence is a first-class success metric because the task exists to avoid full adaptive
  rebuild cost.
- Reload/readback and repeated-edit behavior matter because newly emitted output must be usable for
  the next local edit decision.

### Early Estimate Notes
- Size is lower than MTA-35 because CDT, MTA-24 substrate audit, `PatchLocalCdtProof` handoff, and
  CDT seam/topology validation are explicit non-goals.
- The dominant burden is validation and production mutation safety, not stable patch ownership.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

> Filled during task planning. This is the main pre-implementation estimate.

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Adds a behavior-visible local adaptive replacement lifecycle across create/rebuild, edit, repeated edit, fallback, reload, undo, and hosted performance proof while preserving public workflows. |
| Technical Change Surface | 4 | Spans stable patch policy/resolver, registry storage, adaptive hard-boundary splitting, conformance integration, derived patch containers, face metadata, generator mutation, command integration, contract no-leak tests, and hosted probes. |
| Implementation Friction Risk | 3 | Friction is significant from containerizing currently flat derived output, preserving no-delete semantics, proving conformance bands, and avoiding retained-face rewrites, but CDT solver/topology/seam work is excluded. |
| Validation Burden Risk | 4 | Requires automated, contract, hosted visual, performance, undo, reload/readback, repeated-edit, no-delete, unsupported-child, anti-toy, and real-work-magnitude evidence; MTA-10 showed hosted validation can expose non-obvious performance and mutation failures. |
| Dependency / Coordination Risk | 2 | Depends on current adaptive output, MTA-10 lessons, MTA-22/MTA-23/MTA-24 fixture/probe patterns, MTA-35 planning, and SketchUp hosted access, but avoids CDT implementation dependencies and public client coordination. |
| Discovery / Ambiguity Risk | 3 | Major decisions are resolved, but exact default patch size, one-ring conformance sufficiency, reload/readback behavior, and whether global planning is fast enough remain evidence-gated. |
| Scope Volatility Risk | 3 | Scope can split or expand if hosted timing requires true patch-local planning, lookup needs a spatial index, conformance needs a wider band, or real-work-magnitude validation exposes output lifecycle gaps. |
| Rework Risk | 3 | Rework pressure is high around metadata schema, container traversal, conformance-band assumptions, hosted reload behavior, and performance gates if early implementation overfits toy/local cases. |
| Confidence | 3 | Planning evidence is strong, consensus-tested, and analog-backed, but confidence remains medium until hosted command-path timing, real SketchUp group/face cleanup, and reload/readback evidence exist. |

### Top Assumptions
- Hard patch-boundary splitting can preserve acceptable adaptive compactness for aligned
  power-of-two patch sizes.
- Hybrid patch containers plus minimal per-new-face metadata will reduce mutation/lookup cost
  without recreating the MTA-10 retained-face rewrite problem.
- One-neighbor-ring conformance is sufficient after hard boundary splitting, or can be expanded
  without collapsing locality.
- Owner-attribute registry metadata can either read back safely after reload or invalidate cleanly.
- Hosted full adaptive regeneration is cheap enough in some cases that the responsiveness floor
  avoids artificial blockers.

### Estimate Breakers
- Hosted timing shows global adaptive planning/conformance or lookup dominates above the
  responsiveness floor, requiring true patch-local planning or an index/store.
- Hard patch boundaries or candidate patch sizes inflate adaptive face counts enough to erase
  compactness benefits.
- One-neighbor-ring conformance fails on representative/hostile terrain and requires a materially
  wider replacement or conformance band.
- SketchUp patch group erase/reload behavior leaves stale hidden edges, duplicate output, or
  invalid registry state.
- Hosted validation cannot satisfy anti-toy requirements without adding new fixture/probe
  infrastructure beyond the planned MTA-22/MTA-23/MTA-24 reuse.

### Predicted Signals
- MTA-10 actuals showed local output mutation can be faster, but broad metadata rewrites and target
  resolution can dominate unless separately measured.
- MTA-21 adaptive conformance is already implemented but global; MTA-36 adds ownership and local
  lifecycle rather than a new adaptive mesh algorithm.
- MTA-35 planning provides a registry/lattice/no-delete lifecycle analog, but MTA-36 intentionally
  excludes CDT solver, topology, and per-patch feature intent.
- Current generator derived-output discovery is flat; patch groups require explicit traversal
  semantics and hosted proof.
- User explicitly rejected toy-only validation and clarified performance gate expectations:
  roughly `2x` speedup when full regeneration is user-visible, but not a blocker below about
  `100-200ms`.

### Predicted Estimate Notes
- Closest calibrated analog is MTA-10 for partial output mutation and hosted performance pitfalls.
  MTA-36 should be less CDT-dependent than MTA-35 but more technically invasive than MTA-10 because
  adaptive output needs stable patch containers, registry, conformance policy, reload/readback, and
  anti-toy hosted proof.
- MTA-35 predicted scores inform upper bounds: MTA-36 avoids CDT substrate and feature-selection
  dependencies, so implementation friction and dependency risk should stay lower, but validation
  burden remains very high.
- This prediction reflects the Step 10 draft plan as written. Patch-local planning, spatial index,
  or wider conformance bands are estimate breakers/gated follow-ups, not assumed implementation
  facts.
<!-- SIZE:PREDICTED:END -->

---

<!-- SIZE:CHALLENGE:START -->
## Challenge Review

> Filled when the estimate is pressure-tested through external review, premortem, or controlled consensus.

### Agreed Drivers
- Technical change surface remains `4`: the finalized plan touches adaptive patch policy,
  resolver/registry, hard-boundary splitting, conformance integration, patch containers, face
  metadata, generator mutation, command integration, no-leak contract tests, and hosted probes.
- Validation burden remains `4`: premortem accepted that hosted proof must cover real SketchUp
  group/face/edge lifecycle, performance, reload/readback, undo, no-delete, unsupported children,
  anti-toy rows, and real-work-magnitude timing, not just routine smoke breadth.
- Implementation friction remains `3`: CDT solver/topology is excluded, but containerizing flat
  derived output, preserving no-delete sequencing, proving one-ring conformance, and preventing
  retained-face rewrites are substantial implementation risks.
- Scope volatility remains `3`: the plan contains explicit split/escalation triggers for
  patch-local planning, spatial index/store, wider conformance bands, and validation fixture/probe
  expansion.

### Contested Drivers
- Validation burden could appear closer to `3` if hosted rows run cleanly and the command-path probe
  is straightforward. Keep `4` because the burden is not case count alone; it includes performance
  interpretation, persistence/readback, undo, no-delete, real-work-magnitude rows, and prior MTA-10
  evidence that hosted validation can expose non-obvious performance failures.
- Technical change surface could appear closer to `3` because public contracts and CDT are out of
  scope. Keep `4` because the internal terrain output architecture gains new stable ownership,
  registry, container traversal, conformance, and hosted-probe seams.
- Confidence could be argued as `2` because no hosted evidence exists yet. Keep `3` because the plan
  is strongly researched, consensus-tested, premortem-checked, and has explicit gates rather than
  hidden assumptions.

### Missing Evidence
- Hosted timing proving global adaptive planning plus local mutation either reaches the performance
  target above the responsiveness floor or is fast enough under the floor.
- Hosted proof that patch group erase/reload behavior does not leave stale hidden edges, duplicate
  output, or invalid registry state.
- Unit and hosted evidence that one-neighbor-ring conformance is sufficient after hard patch-boundary
  splitting for representative/hostile adaptive terrain.
- Evidence that fixed `16`/`32`-style aligned patch-size candidates remain compact and useful on
  real-work-magnitude terrain and repeated edits.
- Proof that affected-patch lookup/integrity traversal is bounded to target containers and does not
  hide all-output scans.

### Recommendation
- Keep the predicted scores unchanged.
- Proceed with the finalized plan boundaries: no public contract change, hybrid patch containers,
  minimal per-new-face metadata, purpose-specific traversal, no retained-face rewrites, and hosted
  command-path proof.
- Split or record follow-up/blocker only if the named gates fail: patch-local planning needed,
  spatial index/store needed, conformance band expansion materially widens replacement, or
  anti-toy hosted validation cannot be satisfied with planned fixture/probe reuse.

### Challenge Notes
- Challenge evidence came from Step 6 consensus on ownership/rebuild options, Step 6 consensus on
  remaining ambiguity gates, user performance-floor clarification, user anti-toy-validation
  clarification, live SketchUp terrain magnitude inspection, and Step 12 premortem.
- The final plan and challenged estimate agree: MTA-36 is lower dependency and lower solver
  friction than MTA-35, but still high technical surface and very high validation burden because it
  changes adaptive output lifecycle and must prove real hosted performance/safety.
<!-- SIZE:CHALLENGE:END -->

---

<!-- SIZE:DRIFT:START -->
## Drift Log

> Append only. Log only material changes that affect estimate shape, risk, confidence, or validation burden.

| Date | Phase / Checkpoint | Event Type | Severity (1-3) | Dimension Affected | Predictable Earlier? | Notes |
|---|---|---|---:|---|---|---|
| 2026-05-12 | Post-hosted lifecycle proof | Scope amendment | 3 | Technical Change Surface, Implementation Friction, Validation Burden, Scope Volatility | Partly | Hosted/user review rejected persistent one-group-per-patch output as final CDT-ready topology. MTA-36 now requires one derived mesh group with logical patch ownership and single-mesh cavity replacement. Prior challenge estimate is stale and must be rechallenged after the amended plan is implemented or before final acceptance. |

### Drift Notes
- Material drift recorded: the first implementation pass remains useful lifecycle evidence, but the
  accepted output model changed from patch containers to one single derived mesh group with
  face-level logical patch ownership.
<!-- SIZE:DRIFT:END -->

---

<!-- SIZE:ACTUAL:START -->
## Actual Profile

> Filled at the end of implementation. Do not overwrite predicted values.

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Shipped a behavior-visible local adaptive replacement lifecycle across create, repeated/intersecting edits, fallback, reload/readback, undo, performance proof, and MTA-35 handoff while preserving public workflows. |
| Technical Change Surface | 4 | Touched patch policy/resolver/registry/timing, adaptive planning, single-mesh output mutation, face metadata, command wiring, contract guardrails, hosted probes, performance instrumentation, and generic lifecycle extraction. |
| Actual Implementation Friction | 4 | Initial patch-container implementation had to be reclassified, replaced with single-mesh logical ownership, hardened with registry/ownership prevalidation, then tuned for planner and batch-construction bottlenecks. |
| Actual Validation Burden | 4 | Hosted validation required repeated live rows, topology/registry audits, visual save/reopen checks, performance A/B matrices, redeploy/restart verification, and interpretation of perf gates beyond routine smoke coverage. |
| Actual Dependency Drag | 2 | Work stayed inside the SketchUp extension runtime and did not need public client coordination, but depended on live SketchUp access, deployed plugin reload/restart behavior, and MTA-35/CDT handoff constraints. |
| Actual Discovery Encountered | 4 | Live validation and review surfaced material discoveries: separate patch groups were not acceptable CDT groundwork, global adaptive planning was too expensive, and generic lifecycle extraction was needed before closeout. |
| Actual Scope Volatility | 4 | The accepted shape changed substantially from patch containers to one mesh with logical patches, then expanded to patch-local planning, performance tuning, and generic lifecycle extraction. |
| Actual Rework | 4 | Significant completed work was revisited: patch-container output became lifecycle proof only, mutation was rebuilt around single-mesh cavities, and performance work required revert/reapply A/B plus multiple hosted passes. |
| Final Confidence in Completeness | 4 | Full local validation, final Grok review, restarted SketchUp live verification, save/reopen evidence, and extensive hosted correctness/performance rows support completion with only future CDT/tolerance product work left out of scope. |

### Actual Signals
- Patch-container lifecycle proved metadata and timing mechanics but failed as final CDT-ready
  topology, causing a material amended implementation.
- Single-mesh logical patch ownership preserved one mesh persistent ID through repeated overlapping
  edits with registry and topology audits clean.
- Performance evidence forced patch-local adaptive planning and code-level bottleneck work rather
  than leaving global adaptive planning as a validation baseline.
- Generic `PatchLifecycle` extraction was needed to avoid handing MTA-35 an adaptive-only base.
- Public contract tests and final hosted rows confirmed no patch IDs, registry internals, timing
  buckets, or fallback categories leaked.

### Actual Notes
- The predicted high validation and volatility risks were real. The early statement that stable
  ownership itself was simple remained true, but the output topology and performance proof around
  that ownership were materially harder than the initial seed implied.
<!-- SIZE:ACTUAL:END -->

---

<!-- SIZE:VALIDATION-EVIDENCE:START -->
## Validation Evidence Summary

> Fill only the sections that are relevant. Say `not applicable` where needed.

### Automated Validation
- Final Step 10 validation passed:
  - `bundle exec rake ruby:lint`: `343 files inspected, no offenses detected`
  - `bundle exec rake ruby:test`: `1343 runs, 15335 assertions, 0 failures, 0 errors, 37 skips`
  - `bundle exec rake package:verify`: produced `dist/su_mcp-1.7.0.rbz`
- Focused validation also covered generic lifecycle tests, adaptive wrapper tests, output-plan
  tests, mesh-generator tests, command wiring tests, contract no-leak tests, and hosted probe shape.

### Hosted / Manual Validation
- Hosted SketchUp validation covered patch-container lifecycle proof, the amended single-mesh
  implementation, repeated/intersecting edits across target height, local fairing, planar fit,
  survey correction, and corridor transition, fallback/no-delete cases, undo, reload/readback, true
  save/reopen, and visual inspection.
- Fresh reinstall/restart row `MTA36-RESTART-LIVE-1778598078` passed after generic lifecycle
  extraction: one `adaptive_patch_mesh`, 0 patch containers, valid JSON registry, complete face
  metadata, stable mesh persistent ID, revisions `1 -> 6`, and clean topology/registry audits after
  five overlapping command-path edits.

### Performance Validation
- Dense `50m x 70m @ 20cm` rows showed local replacement materially cheaper than forced full
  rebuild, including `251.13ms` local versus `683.8ms` full for a small edit and `594.85ms` local
  versus `996.01ms` full for a broader edit before later code-level tuning.
- Planner optimization A/B on `70m x 100m @ 20cm` improved create planning and edit totals
  substantially, for example `tol=0.01` small edit total `369.88ms -> 243.78ms` and broad edit
  total `1462.46ms -> 1100.48ms`.
- Planned-batch optimization reduced small `planned_patch_batch` median from `31.59ms` to `8.22ms`
  and broad median from `330.03ms` to `91.53ms` across varied dense terrains.

### Migration / Compatibility Validation
- Public terrain MCP schemas and response shapes did not change.
- Registry persistence moved to JSON string attributes and passed reload/readback and fresh
  restart verification.
- In-process Ruby superclass mismatch during wrapper extraction was understood as a reload-only
  artifact and cleared after a clean SketchUp restart/reinstall.

### Operational / Rollout Validation
- Package verification built the RBZ, and deployed plugin-tree files were exercised through
  `su-ruby`/`eval_ruby`.
- Final live verification selected the fresh terrain at `x=3200..3280m`, confirming the installed
  extension behavior rather than only local unit doubles.

### Validation Notes
- Validation burden is scored as `4` because validation caused material rework and required
  repeated fix/redeploy/restart/rerun and performance interpretation loops, not because of hosted
  case count alone.
<!-- SIZE:VALIDATION-EVIDENCE:END -->

---

<!-- SIZE:DELTA:START -->
## Estimation Delta Review

> Filled during final calibration. Compare prediction to actual behavior.

- **Most Underestimated Dimension**: Scope volatility and rework. The original prediction allowed
  for performance/index/conformance gates, but underestimated how strongly final CDT readiness would
  reject separate patch geometry and force single-mesh replacement plus generic lifecycle extraction.
- **Most Overestimated Dimension**: Dependency drag. The task depended on live SketchUp and MTA-35
  direction, but did not require external public contract coordination or CDT substrate completion.
- **Signal Present Early But Underweighted**: The task already warned that stable ownership domains
  must not require separate final groups. That signal should have been weighted as a hard topology
  acceptance constraint earlier.
- **Genuinely Unknowable Factor**: The exact performance bottleneck distribution was only knowable
  after hosted dense-terrain A/B rows. Planner and planned-batch costs were larger levers than some
  initially discussed lookup/index ideas.
- **Future Similar Tasks Should Assume**: Terrain output lifecycle work that is intended as CDT
  groundwork must prove final geometry topology, not just metadata lifecycle mechanics, and should
  budget for hosted performance matrices plus at least one structural rework loop.

### Calibration Notes
- Dominant actual failure mode: the first implementation proved the lifecycle on the wrong final
  geometry shape. Future estimates should treat "prepares CDT" as a topology constraint even when
  CDT solving itself is out of scope.
- The prediction correctly kept validation burden high and named performance as an estimate
  breaker, but it should have raised rework/scope-volatility suspicion once patch groups entered
  the implementation shape.
<!-- SIZE:DELTA:END -->

---

<!-- SIZE:TAGS:START -->
## Retrieval Tags

Use canonical values from the repo task-estimation taxonomy when present. Keep this as a compact analog-search index, not coverage. Target 8-14 tags.

- `archetype:integration`
- `scope:managed-terrain`
- `systems:terrain-output`
- `systems:terrain-mesh-generator`
- `systems:scene-mutation`
- `systems:managed-object-metadata`
- `contract:no-public-shape-change`
- `validation:hosted-matrix`
- `validation:performance`
- `validation:persistence`
- `host:repeated-fix-loop`
- `host:redeploy-restart`
- `host:save-reopen`
- `risk:performance-scaling`
- `risk:metadata-storage`
- `volatility:high`
- `rework:high`
- `confidence:high`
<!-- SIZE:TAGS:END -->
