# Technical Plan: SVR-04 Add Terrain-Aware Measurement Evidence
**Task ID**: `SVR-04`
**Title**: `Add Terrain-Aware Measurement Evidence`
**Status**: `drafted`
**Date**: `2026-04-24`

## Source Task

- [Add Terrain-Aware Measurement Evidence](./task.md)

## Problem Summary

Generic `measure_scene` modes are intentionally insufficient for terrain review questions such as profile elevation delta or cross-section comparison. `SVR-04` should add terrain-aware measurement evidence only after the generic measurement MVP and explicit profile sampling are stable, so the final contract reflects proven evidence shapes rather than speculative terrain diagnostics.

## Dependency Gate

This task should not enter implementation until both dependencies are complete enough to plan against:

- `SVR-03` has shipped the bounded `measure_scene` MVP and reusable measurement helper seams.
- `STI-03` has shipped or finalized the profile/section sampling output contract.

Exact public `mode` and `kind` names are intentionally deferred until those dependencies settle.

## Scope Direction

Likely measurement evidence categories include:

- profile elevation deltas across a sampled section or path
- min/max sampled terrain elevation summaries
- sampled cross-section comparison evidence
- sampled slope quantities only when expressed as direct measurement evidence rather than a verdict

The final task plan must choose a small finite mode/kind set and document what each quantity means and does not mean.

## Non-Goals

- terrain validation verdicts
- grade compliance decisions
- trench, hump, grade-break, drainage, or fairness diagnostics
- terrain editing, patch replacement, smoothing, fairing, or working-copy lifecycle behavior
- invoking the public `measure_scene` MCP tool internally from validation

## Integration Points

- Reuse `measure_scene` command/helper patterns from `SVR-03`.
- Reuse `STI-03` profile or section evidence for terrain-shaped measurement modes.
- Keep public results JSON-safe and unit-bearing.
- Keep validation consumers on internal helper seams rather than public tool calls.

## Acceptance Criteria

- The detailed implementation plan waits for `SVR-03` and `STI-03` contract stability before freezing public enum names.
- The delivered public contract uses explicit finite mode/kind combinations.
- Terrain-aware outputs are quantities and evidence, not pass/fail verdicts.
- Results include documented units and compact derivation evidence.
- Unsupported terrain diagnostic requests fail with structured refusals rather than heuristic partial answers.
- The implementation reuses upstream measurement and sampling seams and does not duplicate host-target terrain probing.
- Documentation clearly distinguishes generic `SVR-03` measurements, terrain-aware measurement evidence, and later validation diagnostics.

## Test Strategy

- Add loader/schema coverage for every shipped terrain-aware mode/kind branch.
- Add command tests for successful measurement evidence and structured refusals.
- Add helper tests for numeric derivations from representative profile evidence.
- Add regression tests proving validation code does not call the public `measure_scene` MCP tool.
- Add docs/guide checks showing terrain-aware measurement remains distinct from terrain diagnostics and terrain editing.

## Risks and Controls

- Premature enum design: keep exact names deferred until upstream evidence is stable.
- Boundary drift into validation: forbid pass/fail language and diagnostics in this task.
- Duplicate terrain sampling: require reuse of `STI-03` sampling evidence or internal helpers.
- Tool bloat: ship only a small finite set of terrain-aware measurement branches with explicit use/not-use descriptions.

## Quality Checks

- [x] Dependency gates documented
- [x] Measurement-versus-validation boundary documented
- [x] Exact mode/kind deferral documented
- [x] Test requirements specified
- [x] Terrain editing explicitly excluded
