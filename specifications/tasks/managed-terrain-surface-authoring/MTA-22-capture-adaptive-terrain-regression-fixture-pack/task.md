# Task: MTA-22 Capture Adaptive Simplification Benchmark Fixtures And Replay Framework
**Task ID**: `MTA-22`
**Title**: `Capture Adaptive Simplification Benchmark Fixtures And Replay Framework`
**Status**: `implemented`
**Priority**: `P1`
**Date**: `2026-05-06`

## Linked HLD

- [Managed Terrain Surface Authoring](../../../hlds/hld-managed-terrain-surface-authoring.md)

## Problem Statement

MTA-21 repaired the current adaptive terrain output so mixed-resolution seams are conforming enough
to serve as the production baseline. Before MTA-23 prototypes intent-constrained simplification, the
baseline needs to be captured as a varied, replayable benchmark fixture set.

The fixture work must be strong enough that an MTA-23 candidate comparison is meaningful. Capturing
only a few corridor face counts would risk another MTA-19-style local-confidence failure. The task
therefore needs representative terrain shapes, edit families, quality metrics, known residuals, and
replay hooks that capture the current MTA-21 backend as a baseline result set. MTA-23 can then run a
future prototype backend against the same cases and compare the two result sets.

## Goals

- Capture varied adaptive-output benchmark fixtures against the current MTA-21 backend.
- Preserve current baseline metrics for face count, dense-equivalent ratio, profile behavior,
  topology sanity, known residuals, provenance, and timing where practical.
- Include enough terrain and edit variety to make MTA-23 prototype verification relevant.
- Provide reusable baseline capture and replay support that MTA-23 can use to produce candidate
  result sets against the same cases.
- Keep fixture and replay support production-neutral.

## Acceptance Criteria

```gherkin
Scenario: Benchmark fixtures cover representative terrain and edit families
  Given the adaptive simplification benchmark fixture pack
  When the fixture loader validates fixture coverage
  Then the pack includes flat, crossfall, steep, non-square, irregular ridge/valley, mound/hollow, aggressive-stack, and high-relief terrain cases
  And the pack includes corridor, off-grid corridor, target or flat stamp, planar or target region, preserve-zone-adjacent, fixed or survey control, fairing or smoothing, and combined-edit cases where practical

Scenario: Current adaptive backend metrics are captured as baseline evidence
  Given a benchmark fixture case
  When the current MTA-21 adaptive backend is replayed or represented from captured evidence
  Then the fixture records current backend face count or face-count range, dense-equivalent ratio, profile checks, topology checks, known residuals, and provenance
  And timing evidence is recorded when practical without making timing the only quality signal

Scenario: Replay framework supports later apples-to-apples prototype comparison
  Given the benchmark fixture pack and replay framework
  When MTA-22 captures the current adaptive backend baseline result set
  Then the captured results use a shape that MTA-23 can reuse for future candidate backend results
  And later comparison can report candidate metrics against the captured MTA-21 baseline

Scenario: Hosted-sensitive cases remain explicit
  Given a fixture fact cannot be fully reproduced in pure Ruby
  When the fixture is validated
  Then the fixture marks the case as hosted-sensitive or provenance-backed
  And it does not claim local replay proof for facts that require SketchUp-hosted verification

Scenario: Fixture framework remains production-neutral
  Given normal managed terrain tools are used
  When the fixture pack and replay framework exist in the repository
  Then public MCP contracts, runtime dispatcher behavior, production terrain output behavior, and persisted terrain state are unchanged
```

## Non-Goals

- Implementing or selecting a new adaptive simplification backend.
- Proving the future feature-aware simplifier is correct.
- Fixing the adopted off-grid corridor endpoint mismatch.
- Changing public MCP request or response fields.
- Requiring manual visual inspection as the primary replay mechanism.

## Business Constraints

- The benchmark set must make MTA-23 evidence meaningful rather than merely convenient.
- Fixture breadth should be driven by MTA-19 and MTA-21 failure and stress cases.
- Current MTA-21 behavior is the baseline being captured, not the desired final quality endpoint.
- Fixture work should not become a standalone validation story disconnected from prototype behavior.

## Technical Constraints

- Fixture data must be deterministic and JSON-serializable or repo-native.
- Fixtures must not persist raw SketchUp object handles, live entity IDs, or generated mesh as source truth.
- Expected outputs should use ranges or tolerances where future candidate backends may validly differ.
- Pure Ruby replay and SketchUp-hosted evidence must be distinguished explicitly.
- Production runtime code under `src/su_mcp` must not depend on test fixture artifacts.

## Dependencies

- `MTA-20`
- `MTA-21`

## Relationships

- blocks `MTA-23`
- provides the baseline replay framework for `MTA-23`
- preserves MTA-21 evidence before any future backend replacement

## Related Technical Plan

- [Technical implementation plan](./plan.md)

## Success Metrics

- Fixture coverage includes the terrain and edit families needed to stress MTA-23 prototype behavior.
- Current MTA-21 backend metrics are recorded in machine-checkable form.
- At least the locally replayable fixture subset can run through reusable baseline capture and
  replay support.
- Hosted-sensitive cases are labeled accurately rather than overstating local proof.
- Public contract and production behavior tests remain unaffected by fixture support.
