# Task: MTA-33 Implement Patch-Relevant Terrain Feature Constraints
**Task ID**: `MTA-33`
**Title**: `Implement Patch-Relevant Terrain Feature Constraints`
**Status**: `defined`
**Priority**: `P1`
**Date**: `2026-05-09`

## Linked HLD

- [Managed Terrain Surface Authoring](../../../hlds/hld-managed-terrain-surface-authoring.md)

## Problem Statement

MTA-31 delivered materialized feature-intent lifecycle state, a validated effective feature view,
and edit-window relevance selection. That work removed full history replay from normal CDT
planning, but hosted evidence still showed that hard features can dominate local solves because
active hard constraints are treated too globally.

Patch-local CDT needs a stricter feature-selection rule: hard constraints remain globally durable,
but a local patch solve should include only hard, firm, and soft features that intersect, constrain,
protect, or meaningfully influence that patch. Far hard constraints must not participate in every
local solve merely because they are hard.

## Goals

- Extend the MTA-31 effective feature selection path with patch-aware CDT input relevance.
- Include hard constraints when they intersect, protect, constrain, or sit near the patch boundary.
- Exclude far hard constraints from local patch solves when existing cached output can preserve
  their durable semantics.
- Select firm and soft features by patch intersection or influence rather than broad history.
- Record internal diagnostics that explain included and excluded feature counts by strength and
  reason.
- Preserve public MCP contracts and existing feature-intent lifecycle semantics.

## Acceptance Criteria

```gherkin
Scenario: Patch-relevant selection excludes far hard constraints
  Given a managed terrain state with active hard constraints inside and far outside a CDT patch
  When patch-relevant feature selection prepares CDT input for that patch
  Then hard constraints intersecting, protecting, constraining, or near the patch are included
  And far hard constraints that do not affect the patch are excluded from the local solve
  And diagnostics report included and excluded hard counts with machine-readable reasons

Scenario: Touched protected geometry is not silently weakened
  Given a dirty patch or edit influence overlaps a protected region or hard boundary
  When patch-relevant feature selection evaluates the feature set
  Then the protected geometry is included, clipped, refused, or expands the patch according to a documented internal rule
  And the selection does not silently drop a touched hard constraint
  And the resulting internal evidence identifies the selected rule and affected feature strength

Scenario: Firm and soft features remain local pressure, not global point inflation
  Given active firm and soft feature intents inside and outside the patch influence area
  When patch-relevant selection prepares CDT feature geometry
  Then firm and soft features outside patch relevance are excluded from CDT input
  And firm and soft features inside patch relevance are included only as support, tolerance, or pressure according to their existing feature semantics
  And selected feature counts are bounded by patch relevance rather than total persisted feature history

Scenario: MTA-31 effective feature lifecycle semantics are preserved
  Given active, superseded, deprecated, and retired feature-intent records
  When patch-relevant selection is run
  Then only active effective records are eligible for patch relevance
  And stale effective-index behavior remains deterministic
  And the selection does not rebuild feature lifecycle state silently during normal output

Scenario: Public terrain contracts remain stable
  Given patch-relevant feature diagnostics are produced internally
  When public managed terrain command responses are returned
  Then raw feature IDs, internal selection reasons, patch indexes, CDT solver details, and fallback enums do not leak into public MCP responses
```

## Non-Goals

- Replacing the MTA-31 feature-intent lifecycle, merge, or effective-index model.
- Implementing patch-local CDT residual refinement; that is owned by `MTA-32`.
- Implementing SketchUp patch replacement; that is owned by `MTA-34`.
- Adding public feature-selection controls or public backend tuning fields.
- Default-enabling CDT output.

## Business Constraints

- Hard feature semantics must remain conservative: touched or protecting hard geometry must not be
  silently degraded for speed.
- Local edits should not pay for unrelated hard, firm, or soft feature history when existing output
  can preserve distant terrain behavior.
- Public terrain workflows must remain unchanged.

## Technical Constraints

- Patch-relevant selection must consume normalized MTA-31 effective feature state and must not
  replay full historical intent records on normal output.
- Selection outputs must be JSON-serializable and suitable for production CDT feature geometry.
- Far hard-feature exclusion must be based on patch relevance, not only strength class.
- Diagnostics must be internal and must not alter public request schemas or response shapes.
- Stale effective-index refusal or fallback behavior must remain deterministic.

## Dependencies

- `MTA-20`
- `MTA-31`
- `MTA-32`
- [CDT Terrain Output External Review](../../../research/managed-terrain/cdt-terrain-output-external-review.md)

## Relationships

- follows `MTA-32` because patch feature relevance depends on a concrete patch domain and result
  shape
- builds on `MTA-31` effective feature state rather than replacing it
- informs `MTA-34` by producing patch-bounded feature geometry that local SketchUp replacement can
  validate against

## Related Technical Plan

- none yet

## Success Metrics

- A feature-heavy MTA-31-style case shows materially lower hard-feature participation for a small
  patch than the prior global hard-feature selection.
- Touched hard/protected geometry is included, clipped, refused, or expanded by explicit internal
  rule.
- Firm and soft feature input cardinality is bounded by patch relevance.
- Existing feature lifecycle and stale-index tests remain valid.
- Public MCP response shape remains unchanged.
