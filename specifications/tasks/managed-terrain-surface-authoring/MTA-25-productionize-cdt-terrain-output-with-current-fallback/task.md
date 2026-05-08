# Task: MTA-25 Productionize CDT Terrain Output With Current Backend Fallback
**Task ID**: `MTA-25`
**Title**: `Productionize CDT Terrain Output With Current Backend Fallback`
**Status**: `planned`
**Priority**: `P1`
**Date**: `2026-05-07`

## Linked HLD

- [Managed Terrain Surface Authoring](../../../hlds/hld-managed-terrain-surface-authoring.md)

## Problem Statement

MTA-24 showed that a residual-driven constrained Delaunay/CDT terrain output backend is the best
production-direction candidate, but it is not production-ready. The prototype produced materially
sparser terrain than the corrected MTA-23 adaptive-grid candidate on harder cases while preserving
the final edited heightmap within comparable tolerance, but it also exposed runtime pressure,
conservative hard-geometry diagnostics, and task-specific bakeoff harness code that should not
become long-lived production runtime ownership.

MTA-25 must turn the CDT direction into a production terrain output path with the current production
backend retained as the safety fallback. It must cleanly separate or remove MTA-24-specific
comparison/hosted-probe harnesses from production code, preserve public contracts unless a separate
contract task is defined, and prove the resulting backend through local and hosted SketchUp
acceptance gates.

## Goals

- Productionize a CDT-oriented terrain output backend that consumes production
  `TerrainFeatureGeometry` and final managed terrain heightmap state.
- Retain the current production terrain output backend as a fallback while CDT production behavior
  is gated and validated.
- Define measurable fallback predicates for CDT runtime, topology, hard-geometry, and residual
  failures.
- Harden the triangulation adapter boundary so the production path can swap the Ruby triangulator
  for a native/C++ triangulation implementation if runtime or robustness gates require it.
- Remove, relocate, or isolate MTA-24 task-specific comparison and hosted-probe harnesses so they do
  not become mixed into long-lived production runtime code.
- Preserve public MCP contracts and response shapes unless a separate contract-change task is
  explicitly created.
- Prove production behavior with automated tests, package validation, and hosted SketchUp
  acceptance over representative flat, crossfall, bumpy, high-relief, bounded, intersecting, hard
  preserve, fixed-anchor, and corridor/reference cases.

## Acceptance Criteria

```gherkin
Scenario: CDT output is production-wired behind explicit fallback gates
  Given a valid managed terrain state with feature geometry
  When production terrain output is generated
  Then the CDT-oriented backend is eligible to generate the production terrain mesh
  And the current production backend remains available as a fallback
  And fallback decisions are recorded with explicit machine-readable reasons

Scenario: Production CDT consumes the feature geometry substrate
  Given terrain edits that produce hard anchors, protected regions, pressure regions, reference segments, and affected windows
  When the production CDT backend builds output geometry
  Then it consumes production TerrainFeatureGeometry as its constraint and tolerance source
  And it does not read raw SketchUp objects or MTA-24 comparison rows as production input
  And it preserves mandatory hard anchors and required protected/reference geometry within documented tolerance

Scenario: Runtime and topology gates protect production output
  Given a terrain case that exceeds CDT runtime, point, face, topology, or constraint-recovery limits
  When production output is requested
  Then the system falls back to the current production backend or reports a production-safe residual state
  And the fallback does not corrupt terrain state or leave partial derived geometry
  And the fallback reason is visible in internal diagnostics without leaking prototype internals to public responses

Scenario: Task-specific bakeoff harnesses are not production runtime ownership
  Given the MTA-24 comparison backend and hosted bakeoff helpers exist in the codebase
  When MTA-25 production wiring is complete
  Then task-specific comparison and hosted-probe harnesses are removed, relocated to test/support ownership, or isolated behind validation-only namespaces
  And production runtime code does not depend on MTA-24 task harness classes for normal terrain output
  And public packaged behavior does not expose MTA-24 bakeoff identifiers or candidate-row internals

Scenario: Public terrain contracts remain stable
  Given existing public terrain MCP tools and response shapes
  When CDT production output is enabled internally
  Then public request schemas and response contracts remain backward compatible
  And raw CDT triangles, solver predicates, expanded constraints, comparison rows, and prototype diagnostics do not appear in public responses
  And contract tests fail if CDT implementation details leak across the public boundary

Scenario: Hosted SketchUp acceptance validates production behavior
  Given the production CDT path and fallback gates are implemented
  When hosted SketchUp validation runs on representative terrain/edit families
  Then generated production geometry has valid topology, acceptable residuals, and no visible hard-geometry defects on accepted cases
  And fallback cases produce current-backend geometry without corrupting scene state
  And validation records timing, topology, residual, fallback, undo, and save/reopen evidence where practical
```

## Non-Goals

- Re-running MTA-24 as another comparison-only bakeoff.
- Keeping MTA-24 task-specific harnesses as production runtime dependencies.
- Adding public backend selection controls or user-facing simplification knobs.
- Changing public MCP terrain contracts without a separate contract task.
- Productionizing the MTA-23 adaptive-grid prototype as the selected backend.
- Rewriting terrain edit kernels unrelated to derived output generation.
- Making native C++ packaging mandatory unless the technical plan proves it is required for the
  production runtime gate.

## Business Constraints

- Current production terrain output must remain available as a safety fallback until CDT production
  gates are satisfied.
- The work must improve production terrain output without exposing users to prototype backend
  selection complexity.
- The MTA-24 evidence selects CDT directionally, but does not by itself authorize an unconditional
  production swap.
- Production follow-up acceptance must be grounded in hosted SketchUp evidence, not local tests
  alone.

## Technical Constraints

- Terrain state remains authoritative; generated terrain output remains disposable derived geometry.
- Production CDT input must come from managed terrain state and production `TerrainFeatureGeometry`.
- Runtime outputs crossing command or public boundaries must remain JSON-serializable.
- Public MCP contracts, schemas, dispatcher behavior, and response shapes must remain stable unless
  separately planned.
- Fallback routing must be deterministic and diagnosable.
- Hosted validation must use the SketchUp runtime and MCP wrapper path, including `eval_ruby` where
  appropriate.
- Topology checks must include down faces, non-manifold edges, invalid faces, and visible gap
  risks.
- Performance gates must account for high-relief and repeated residual retriangulation cases found
  in MTA-24.
- The triangulation implementation must remain behind a production-owned adapter seam so native
  library evaluation does not leak through terrain commands, SketchUp mutation, diagnostics, or
  public response contracts.

## Dependencies

- `MTA-20`
- `MTA-22`
- `MTA-23`
- `MTA-24`

## Relationships

- follows `MTA-24` because MTA-24 selected CDT as the production-direction candidate while retaining
  current output as the fallback
- consumes MTA-24 residual-driven CDT prototype evidence and retained live H2H summaries
- supersedes MTA-23 as a production backend direction, while preserving MTA-23 as comparison and
  calibration history
- should be planned before committing to native C++ triangulation or public terrain-output controls

## Notes

- The technical plan should explicitly evaluate whether the Ruby triangulation path can meet the
  production runtime gates. If it cannot, MTA-25 may need to introduce or defer to a native/C++
  triangulation library adapter for the heavy CDT calculations, while preserving the Ruby production
  boundary for feature-geometry ingestion, fallback routing, diagnostics, and public contract
  stability.
- The technical plan should explicitly prepare the adapter shape for a possible `poly2tri`-style
  C++ implementation, including input prevalidation, simple-polygon/duplicate-point limitations,
  packaging impact, and fallback behavior if the native triangulator is unavailable.

## Related Technical Plan

- [Technical Implementation Plan](./plan.md)

## Success Metrics

- Production terrain output can use the CDT-oriented backend on accepted cases without public
  contract changes.
- Current production output is used as fallback when CDT exceeds runtime, topology, constraint, or
  residual gates.
- MTA-24 task-specific comparison and hosted-probe harnesses are removed from, relocated out of, or
  isolated from production runtime ownership.
- Automated tests cover fallback routing, contract no-leak behavior, topology/residual gates, and
  representative feature-geometry inputs.
- The triangulation adapter is hardened enough that Ruby and native/C++ implementations can be
  compared or swapped behind the same production result and fallback contract.
- Hosted SketchUp validation accepts production CDT output on representative flat, crossfall,
  bumpy, high-relief, bounded/intersecting, preserve, fixed-anchor, and corridor/reference cases.
- Summary evidence states the remaining production risks and whether current fallback can be
  retired, narrowed, or must remain.
