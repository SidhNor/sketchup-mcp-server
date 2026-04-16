# Task: SEM-05 Validate V2 Semantic Contract Via Ruby Normalizer Spike
**Task ID**: `SEM-05`
**Title**: `Validate V2 Semantic Contract Via Ruby Normalizer Spike`
**Status**: `completed`
**Priority**: `P0`
**Date**: `2026-04-16`

## Linked HLD

- [Semantic Scene Modeling](../../../hlds/hld-semantic-scene-modeling.md)

## Problem Statement

The semantic surface now has a much clearer exploratory `v2` direction captured in [the contract pressure-test signal](../../../signals/2026-04-15-semantic-contract-v2-pressure-test-signal.md), including a preferred section split, an atomic-versus-composite posture, and a lean composition surface. That signal is strong enough to show that future contract pressure is real, but it still leaves one important proof gap: the preferred `v2` shape has not yet been exercised through a plausible Ruby-owned normalization path.

That gap matters because the platform direction depends on Ruby remaining the clear owner of semantic interpretation while Python stays thin. If the `v2` shape only works on paper and collapses back into cross-section special cases when normalized in Ruby, then the current signal would still be carrying a faulty assumption forward. The strongest unresolved risk is not whether the current contract has pressure. It is whether the preferred `v2` section boundaries survive real normalization for the hardest future scenarios without widening the public surface or thickening the Python adapter.

This task exists to validate or falsify that assumption with the smallest practical Ruby-owned spike before any contract decision is promoted beyond signal level.

## Goals

- validate whether the preferred `v2` semantic contract can be normalized through one Ruby-owned canonical request path without collapsing its section boundaries
- prove or falsify the hardest atomic `v2` scenarios through a minimal Ruby spike rather than through chat-only reasoning
- make the remaining contract risk concrete by documenting where the preferred `v2` shape stays clean, where it overlaps, and whether refusal behavior remains deterministic

## Acceptance Criteria

```gherkin
Scenario: ruby spike normalizes the hardest atomic v2 scenarios through one canonical request shape
  Given the preferred `v2` contract direction is captured in the semantic contract pressure-test signal
  When the Ruby spike is exercised for retained structure adoption, terrain-following path creation, and replace-preserve-identity under hierarchy
  Then the spike normalizes all three scenarios through one canonical Ruby request shape
  And the spike does not require new public top-level contract fields to support those scenarios

Scenario: spike proves whether section ownership remains disciplined in Ruby
  Given the preferred `v2` shape separates `metadata`, `sceneProperties`, `definition`, `hosting`, `placement`, `representation`, and `lifecycle`
  When the spike is reviewed across the three validation scenarios
  Then the task records whether those sections remain non-overlapping in the Ruby normalization path
  And any section overlap that still appears is captured explicitly as evidence rather than left implicit

Scenario: spike validates that Ruby can stay the semantic owner without thickening Python
  Given the current architecture requires Python to remain a thin MCP adapter
  When the spike is completed
  Then the spike proves or falsifies the preferred `v2` shape without moving semantic interpretation into Python
  And the task captures whether the Ruby-side validation path is plausible without requiring a new Python-side semantic contract authority

Scenario: spike captures structured refusal behavior for representative hard cases
  Given the preferred `v2` shape relies on section-scoped refusal behavior
  When representative invalid or conflicting requests are exercised for the spike scenarios
  Then the task documents whether refusals remain structured and deterministic
  And the task identifies any refusal paths that still collapse into ambiguous or cross-section failure handling

Scenario: spike updates the signal with evidence rather than leaving the v2 direction at pure hypothesis
  Given the semantic contract pressure-test signal is the source exploratory artifact for this work
  When the spike is reviewed
  Then the signal is updated with the spike findings
  And the task leaves the repo with clearer evidence about whether the preferred `v2` direction is ready for future promotion or needs revision
```

## Non-Goals

- adopting the preferred `v2` contract as the live public MCP surface in this task
- delivering a full `v2` implementation across Python, Ruby, contract fixtures, and documentation
- implementing the full composition layer, including final grouping, duplication, or identity-preserving replacement tools
- introducing new production semantic families such as `seat`, `gate`, `stair`, `water_feature`, or `terrain_patch`

## Business Constraints

- the task must reduce decision risk around the future semantic contract rather than becoming an open-ended architecture exploration
- the spike must stay tied to the real workflow pressures already captured in the signal, especially adoption, terrain-hosted creation, and identity-preserving replacement
- the task must leave a reviewable evidence trail so later PRD or HLD updates do not depend on reconstructing conclusions from chat history

## Technical Constraints

- Ruby must remain the owner of semantic normalization, target resolution, invariant enforcement, and refusal behavior for the spike
- Python must remain a thin MCP adapter and must not become a second semantic schema authority during this validation task
- the spike should reuse the current Ruby semantic command posture where practical rather than inventing a separate long-lived semantic runtime
- the task must validate the preferred `v2` shape through the smallest practical Ruby slice rather than turning the spike into a full production migration
- the task must update the contract pressure-test signal with findings from the spike so the exploratory artifact reflects the new evidence

## Dependencies

- `SEM-02`
- `SEM-03`
- [Signal: Pressure-Test A Potential V2 Semantic Contract Before The PRD Surface Expands](../../../signals/2026-04-15-semantic-contract-v2-pressure-test-signal.md)

## Relationships

- informs any future task that would adopt or reject the preferred semantic `v2` contract direction
- informs future semantic lifecycle and composition work by proving or falsifying the current section-boundary posture

## Related Technical Plan

- [Draft technical plan](./plan.md)

## Success Metrics

- the repo has one task-owned spike result showing whether the preferred `v2` shape survives Ruby normalization for the three hardest atomic scenarios
- reviewers can point to explicit evidence for or against the current section-boundary posture instead of relying on chat-only reasoning
- the semantic contract pressure-test signal is materially stronger after this task because its remaining uncertainty is reduced by real spike findings
