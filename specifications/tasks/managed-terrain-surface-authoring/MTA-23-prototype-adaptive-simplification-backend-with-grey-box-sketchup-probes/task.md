# Task: MTA-23 Prototype Intent-Constrained Adaptive Output Backend
**Task ID**: `MTA-23`
**Title**: `Prototype Intent-Constrained Adaptive Output Backend`
**Status**: `implemented`
**Priority**: `P1`
**Date**: `2026-05-06`

## Linked HLD

- [Managed Terrain Surface Authoring](../../../hlds/hld-managed-terrain-surface-authoring.md)

## Problem Statement

MTA-20 introduced durable terrain feature intent, but the current adaptive output backend still
mostly behaves like a heightmap-only simplifier. MTA-19 showed that heightfield correctness and local
sampling checks are not enough: generated topology can still fail around corridors, end caps,
protected areas, combined edits, and hosted SketchUp behavior.

This task prototypes an intent-constrained adaptive output backend. It must turn MTA-20 intent into
executable output constraints and use those constraints to drive a real validation-only
simplification kernel that emits candidate geometry. Validation-only means the backend is not
production-wired; it must not be mocked, simulated, or reduced to a planner. The task is not
successful if it only defines a planner, diagnostic layer, or current-backend ablation; it must
compare an actual candidate backend against the MTA-22 benchmark fixtures and end with evidence that
determines the next production direction.

## Goals

- Build the minimum backend-neutral feature-geometry layer needed by an output prototype.
- Implement one validation-only enhanced adaptive grid/quadtree-style candidate simplification
  backend that consumes those constraints and emits real candidate geometry.
- Use the MTA-22 benchmark fixture/replay framework to compare the candidate against the MTA-21
  baseline.
- Run SketchUp-hosted grey-box probes for candidate rows that are promising enough to inform
  production direction.
- Classify the result: productionize the candidate, use the constraint layer for a constrained
  Delaunay/CDT follow-up, repair constraint expansion first, or stop.

## Acceptance Criteria

```gherkin
Scenario: Feature intent becomes executable output constraints
  Given a terrain state with MTA-20 feature intent
  When the prototype prepares output constraints
  Then it derives JSON-safe internal planning data for protected-domain geometry, fixed output anchors, firm or soft influence regions, affected grid windows, and role-specific tolerances where present
  And the planning data can be consumed by more than one backend family without depending on SketchUp objects

Scenario: Prototype candidate emits real geometry through a simplification kernel
  Given prepared output constraints and a dense heightmap source of truth
  When the validation-only candidate simplification backend runs
  Then it emits candidate vertices, triangles, and compact metrics through a test-owned or prototype-owned path
  And the candidate geometry consumes the prepared constraints rather than ignoring feature context

Scenario: Candidate is compared against the MTA-21 baseline
  Given the MTA-22 benchmark fixture pack
  When the current backend and candidate backend are evaluated
  Then comparison rows record face count, dense ratio, height/profile error, topology validity, protected or feature crossing checks, residual behavior, and timing where practical
  And the candidate is evaluated against the same fixture cases and baseline metrics as the current backend

Scenario: Hosted probes gate production recommendation
  Given a candidate passes local comparison gates
  When SketchUp grey-box probes run through `eval_ruby`
  Then representative fixture cases create sidecar geometry without mutating existing scene geometry
  And hosted evidence records geometry creation, topology, profile or residual behavior, hidden-edge or metadata behavior, timing, undo, and save-copy or save/reopen status where practical

Scenario: Prototype result identifies the next backend direction
  Given local and hosted evidence has been collected
  When MTA-23 is completed
  Then the report recommends one of productionizing the candidate, using the constraint layer for a constrained Delaunay or CDT prototype, repairing constraint expansion first, or stopping
  And the recommendation names the evidence that supports the decision
```

## Non-Goals

- Shipping or enabling a production terrain output backend.
- Changing public MCP tool names, request schemas, response shapes, dispatcher routes, or user-facing docs.
- Treating current-kernel geometric ablations as the primary candidate.
- Mocking, simulating, or reporting hypothetical candidate output instead of implementing a real
  simplification kernel.
- Implementing full production constrained Delaunay/CDT unless explicitly selected by later evidence.
- Persisting generated mesh, raw triangles, raw vertices, expanded constraints, or solver internals as terrain source truth.
- Completing a planner-only or diagnostics-only task that does not implement a candidate
  simplification kernel and produce candidate geometry.

## Business Constraints

- The prototype must use MTA-20 feature intent as a real input to output generation.
- Hard output geometry is limited to protected-domain non-crossing and fixed-control output anchors;
  corridor, survey, and planar intent are represented as firm mesh-generation pressure and metrics.
- The enhanced adaptive grid/quadtree-style backend is the first proof vehicle, not an assumption
  about the final production architecture.
- The first candidate should be cheap enough to validate without recreating the MTA-19 failure pattern.
- A failed prototype must still produce actionable evidence about whether the constraint layer,
  candidate backend, or backend family is the limiting factor.
- Production implementation remains a later gated task.

## Technical Constraints

- Terrain state remains authoritative; generated mesh remains disposable derived output.
- Prototype code must stay validation-only and must not become the default production path in this task.
- The intent-constraint layer must be SketchUp-free and JSON-safe at its boundaries.
- Public terrain responses must not expose feature graphs, candidate internals, raw generated topology, or backend-specific vocabulary.
- Hosted probes must place diagnostic geometry to the side of existing scene geometry and avoid destructive scene edits.

## Dependencies

- `MTA-20`
- `MTA-21`
- `MTA-22`

## Relationships

- follows `MTA-22`
- blocks `MTA-24` only if a productionizable candidate is recommended

## Related Technical Plan

- [Technical Plan](./plan.md)

## Success Metrics

- Candidate output demonstrably consumes MTA-20-derived constraints.
- MTA-22 benchmark rows compare candidate metrics against the MTA-21 baseline.
- Hosted evidence exists for representative promising candidate cases before any production recommendation.
- The final report clearly distinguishes constraint-layer failure, candidate-backend failure, and production-ready evidence.
- The final report states whether a constrained Delaunay/CDT follow-up is justified by the evidence.
- Public contract stability tests remain green and no production backend is swapped by this task.
