# Technical Plan: STI-03 Extend sample_surface_z With Profile and Section Sampling
**Task ID**: `STI-03`
**Title**: `Extend sample_surface_z With Profile and Section Sampling`
**Status**: `drafted`
**Date**: `2026-04-24`

## Source Task

- [Extend sample_surface_z With Profile and Section Sampling](./task.md)

## Problem Summary

Point-based `sample_surface_z` is valuable but still forces agents to manually build repeated probe grids when they need a section line or terrain profile. `STI-03` should add a bounded, explicit-host profile sampling contract that returns ordered evidence along a path while keeping terrain interpretation, validation, and editing out of scope.

## Scope

- Add profile or section sampling to the explicit surface-interrogation capability.
- Accept one explicit target host and one ordered sampling geometry.
- Support interval-based or count-based sample generation.
- Return ordered per-sample results plus compact summary fields.
- Preserve current point-sampling compatibility.

## Output Shape Direction

The public response should remain compact and JSON-safe. The implementation plan should settle exact names, but the evidence shape should include:

- ordered `samples`
- per-sample input XY, sampled distance or progress, and status
- sampled world-space XYZ only when a hit is resolved
- summary values such as `hitCount`, `missCount`, `sampledLength`, `minZ`, and `maxZ`

The response must not include slope verdicts, bump detection, trench detection, fairing advice, raw SketchUp objects, or verbose face/debug dumps.

## Contract Direction

Implementation planning should compare two contract options:

- extend `sample_surface_z` with a discriminator such as `samplingMode: "point" | "profile"` while preserving existing point defaults
- introduce a separate profile-sampling tool only if the `sample_surface_z` schema becomes hard for MCP clients to discover correctly

The default recommendation is to extend the existing command path first because profile sampling should reuse the same explicit host resolution and sampling internals as point sampling.

Whichever option is chosen, the tool-parameter root must remain provider-compatible: top-level `type: "object"` with no root `oneOf`, `anyOf`, `allOf`, `not`, or `enum`. Conditional legality belongs in runtime structured refusals and field descriptions, not root schema composition.

## Integration Points

- Reuse `TargetReferenceResolver` for the explicit host.
- Reuse the existing `sample_surface_z` surface-interrogation component for host-target disambiguation and visibility/ignore behavior.
- Keep profile-specific sampling orchestration in the targeting/interrogation slice, not inside validation or measurement commands.
- Ensure later `measure_scene` follow-ons can call internal sampling helpers directly without invoking the public MCP tool.

## Acceptance Criteria

- The public contract accepts an explicit target host and a profile or section sampling request.
- The sampling request supports ordered path input and either interval-based or count-based sampling.
- The output returns deterministic samples in path order.
- Each sample exposes `hit`, `miss`, or `ambiguous` without fabricating coordinates for non-hit outcomes.
- The output includes compact summary fields useful for downstream measurement evidence.
- Existing point-sampling callers remain compatible.
- Unsupported generic scene targets, missing explicit hosts, and unsupported path shapes fail with structured refusals.
- Hosted or manual SketchUp verification covers vegetation or overlapping-geometry occlusion against an explicit terrain host.
- The task does not add validation verdicts, slope compliance, fairness diagnostics, or terrain editing side effects.

## Test Strategy

- Add contract coverage for the new profile/section discriminator or new tool schema.
- Add Ruby behavior tests for path normalization, interval/count sample generation, ordered result shaping, miss handling, ambiguity handling, and compact summaries.
- Add regression coverage proving existing point-sampling request and response shapes remain stable.
- Add dispatcher/loader tests for public schema discoverability.
- Add hosted or documented manual SketchUp verification for an explicit terrain host with overlapping vegetation or other geometry.

## Risks and Controls

- Schema bloat: prefer a discriminator only if the rendered MCP tool remains clear and provider-compatible; otherwise split into a separate profile tool during implementation planning.
- Scope creep into diagnostics: keep slope, hump, trench, fairness, and grade-compliance outputs deferred to validation/review follow-ons.
- Duplicate sampling logic: reuse the existing explicit host-target surface-interrogation path rather than adding a second raytest implementation.
- Hidden coupling with `SVR-04`: keep output summary stable enough for reuse, but let `SVR-04` choose exact measurement mode/kind names after this contract settles.

## Quality Checks

- [x] Task dependency and ownership documented
- [x] Goals and non-goals documented
- [x] Output-shape direction documented
- [x] Contract split risk documented
- [x] Test requirements specified
- [x] Terrain editing explicitly excluded
