# Task: MTA-34 Implement CDT Patch Replacement And Seam Validation
**Task ID**: `MTA-34`
**Title**: `Implement CDT Patch Replacement And Seam Validation`
**Status**: `closed-blocked`
**Priority**: `P1`
**Date**: `2026-05-09`

## Linked HLD

- [Managed Terrain Surface Authoring](../../../hlds/hld-managed-terrain-surface-authoring.md)

## Problem Statement

MTA-32 and MTA-33 are expected to prove that CDT terrain output can be solved locally and fed by
patch-relevant feature constraints. That still does not make CDT interactive unless the SketchUp
derived output can also be replaced locally. Rebuilding or replacing the whole terrain output for a
small edit would preserve a large part of the MTA-31 failure mode.

This task must turn a proven patch CDT result into safe local SketchUp output mutation by reusing
the partial-output ownership lessons from MTA-10, validating seams against preserved neighboring
output, and keeping fallback/undo behavior safe.

## Closure Disposition

MTA-34 is closed as blocked/incomplete, not accepted as product behavior. The implementation produced useful internal
replacement, seam-validation, ownership, fallback, and public no-leak infrastructure, but hosted
validation exposed a missing production precondition: normal terrain output does not create or
maintain stable CDT-owned patch output for MTA-34 to replace.

The task did not prove the full product loop required by the plan: a normal command-path edit using
real MTA-33 feature planning, real MTA-32 patch proof generation, and local CDT patch replacement
over stable production-owned patch output. The remaining lifecycle problem is defined in
[MTA-35 Productize Cached CDT Patch Output Lifecycle For Windowed Terrain Edits](../MTA-35-productize-cached-cdt-patch-output-lifecycle-for-windowed-terrain-edits/task.md).

## Goals

- Replace only affected CDT patch output while leaving unaffected terrain output intact.
- Reuse or extend existing partial derived-output ownership metadata instead of inventing a
  parallel mutation model.
- Validate seam compatibility between regenerated CDT patches and preserved neighboring output.
- Fall back or refuse deterministically when patch ownership, seam validation, topology, or
  unsupported children make local replacement unsafe.
- Prove SketchUp undo restores terrain state and derived output coherently.
- Keep CDT disabled by default and preserve public MCP response contracts.

## Acceptance Criteria

```gherkin
Scenario: Affected CDT patch output replaces locally
  Given a managed terrain owner with existing derived output and complete patch ownership metadata
  When a patch CDT result is accepted for a dirty edit
  Then only derived output owned by the affected patch region is replaced
  And neighboring unaffected derived output remains present and unchanged
  And the terrain owner, terrain state payload, and public response shape remain stable

Scenario: Seam validation protects preserved neighboring output
  Given a regenerated CDT patch shares a boundary with preserved neighboring output
  When local patch replacement is validated
  Then shared boundary XY positions are compatible
  And shared boundary Z values are within the configured seam tolerance
  And no open cracks, duplicate overlapping border faces, or protected-boundary crossings are accepted
  And seam validation failures produce deterministic internal fallback or refusal evidence

Scenario: Unsafe local replacement falls back without corrupting output
  Given derived output ownership is missing, duplicated, incomplete, or mixed with unsupported child entities
  When CDT patch replacement is requested
  Then the system refuses or falls back according to documented internal rules
  And old derived output is not erased before a safe replacement path is ready
  And public responses do not expose internal CDT patch or fallback vocabulary

Scenario: Undo restores state and patch output
  Given a CDT patch replacement has completed inside a SketchUp operation
  When SketchUp undo is invoked
  Then the prior terrain state and derived output are restored together
  And unaffected scene content remains untouched
  And a subsequent terrain edit reads the restored branch state

Scenario: Default production behavior remains unchanged
  Given the extension is loaded without an internal CDT patch enablement switch
  When managed terrain create or edit output is generated
  Then the existing current terrain output backend remains active
  And CDT patch replacement is not attempted
```

## Non-Goals

- Implementing patch-local incremental CDT refinement; that is owned by `MTA-32`.
- Implementing patch-relevant feature selection; that is owned by `MTA-33`.
- Default-enabling CDT terrain output.
- Adding public backend selectors, public CDT diagnostics, or public patch controls.
- Implementing native/C++ triangulation or incremental residual algorithms.
- Reworking unrelated terrain UI tools.

## Business Constraints

- Local CDT output must not risk corrupting user-visible terrain when patch ownership or seam
  validation is uncertain.
- Normal terrain workflows must continue to use the current supported backend unless CDT patch
  replacement is internally enabled for validation.
- The task must produce hosted evidence for local output mutation, not only SketchUp-free unit
  tests.

## Technical Constraints

- Generated terrain output remains disposable derived geometry; terrain state remains authoritative.
- Old derived output must not be erased until accepted replacement geometry is ready.
- Patch ownership and seam diagnostics must remain internal and JSON-serializable where exposed to
  tests or validation seams.
- The implementation should reuse MTA-10 partial replacement concepts where practical.
- Public MCP request schemas, dispatcher behavior, and response shapes must remain stable.
- Hosted validation must use the SketchUp runtime path for undo, scene mutation, and visible seam
  evidence.

## Dependencies

- `MTA-10`
- `MTA-31`
- `MTA-32`
- `MTA-33`
- [CDT Terrain Output External Review](../../../research/managed-terrain/cdt-terrain-output-external-review.md)

## Relationships

- follows `MTA-32` and `MTA-33` because local replacement needs a proven patch result shape and
  patch-relevant feature constraints
- reuses lessons from `MTA-10` partial terrain output regeneration
- hands off product-loop proof to `MTA-35`, which owns stable CDT patch output bootstrap,
  patch identity, dirty-window-to-patch mapping, repeated-edit lifecycle, and hosted visual proof

## Related Technical Plan

- [Technical Plan](./plan.md)

## Success Metrics

- Not met for accepted product behavior. Hosted validation did not prove a real command-path CDT
  patch lifecycle over stable production-owned patch output.
- Retained as partial infrastructure: replacement result adaptation, seam validator groundwork,
  ownership metadata conventions, no-delete-before-safe mutation ordering, fallback/refusal routing,
  and public no-leak coverage.
- Carried to MTA-35: stable patch output bootstrap, patch identity, dirty-window mapping, repeated
  replacement over newly emitted metadata, hosted visual proof, undo, and timing evidence.
