# MTA-07 Implementation Summary

**Status**: completed  
**Task**: `MTA-07 Define Scalable Terrain Representation Strategy`  
**Captured**: 2026-04-26

## Implemented

- Added `SU_MCP::Terrain::SampleWindow`, a SketchUp-free sample-index window primitive for full-grid windows, owner-local meter bounds mapping, clipping, empty windows, changed-region summaries, intersection, and union.
- Integrated `SampleWindow` into `BoundedGradeEdit` changed-region diagnostics.
- Added `SU_MCP::Terrain::TerrainOutputPlan`, a full-grid output descriptor that preserves the existing public `output.derivedMesh` shape.
- Refactored `TerrainMeshGenerator` so current per-face production generation reports through `TerrainOutputPlan` while preserving counts, digest linkage, derived marking, positive-Z normals, and regeneration refusal behavior.
- Added `TerrainMeshGenerator#generate_bulk_candidate` as a validation-only builder-based path for live SketchUp comparison. It is not wired into production `generate` or `regenerate`.
- Added contract stability coverage proving `heightmap_grid` remains schema version `1`, no window/chunk/tile state is persisted, and public edit evidence keeps `changedRegion`, `samples`, and `sampleSummary` without generated face or vertex identifiers.
- Added a hosted validation placeholder for the required live SketchUp comparison matrix.

## Representation Decision

The selected direction remains heightmap-derived managed terrain state with future localized-detail units, tiled/chunked storage, or patch overlays added through explicit follow-on work. Generated SketchUp TIN remains disposable derived output.

MTA-07 did not introduce persisted representation v2. Reliable regeneration remains based on the existing persisted v1 `heightmap_grid` state. The new primitives are deterministic internal views over that state and are intentionally not serialized.

## Validation

- `bundle exec ruby -Itest -e 'ARGV.each { |path| load path }' test/terrain/terrain_contract_stability_test.rb test/terrain/terrain_sample_window_test.rb test/terrain/terrain_output_plan_test.rb test/terrain/bounded_grade_edit_test.rb test/terrain/terrain_mesh_generator_test.rb test/terrain/terrain_output_live_validation_test.rb`: 26 runs, 83 assertions, 0 failures, 0 errors, 1 skip.
- `bundle exec rake ruby:test`: 633 runs, 2419 assertions, 0 failures, 0 errors, 32 skips.
- `bundle exec rake ruby:lint`: 170 files inspected, no offenses.
- `bundle exec rake package:verify`: passed and produced `dist/su_mcp-0.21.0.rbz`.
- `mcp__pal__.codereview` with `grok-4.20`: completed with no required fixes. One optional guardrail comment was added above the validation-only bulk candidate entrypoint, followed by rerunning focused mesh tests, lint, full Ruby tests, and package verification.

## Live SketchUp Validation

Production MCP path validation passed after scene reset:

| Case | Create | Edit/regenerate | Mesh | Revision | Undo |
|---|---:|---:|---:|---|---|
| Small 4x3 | 0.055s | 0.338s | 12 vertices / 12 faces | 1 -> 2 | PASS |
| Non-square 17x9 | 0.128s | 0.388s | 153 vertices / 256 faces | 1 -> 2 | PASS |
| Near-cap 100x100 | 21.629s | 23.039s | 10,000 vertices / 19,602 faces | 1 -> 2 | PASS |

MCP production checks passed:

- Public sampling confirmed the edited region changed and outside points remained unchanged.
- `Sketchup.undo` restored revision 1, original digest, and original sampled elevations.
- `ping` succeeded after each edit, including near-cap.
- An unmanaged top-level sentinel survived all operations, proving unrelated unmanaged scene content was not deleted.

Internal high-variation generator comparison passed:

| Case | Relief | Per-face generate | Bulk candidate | Mesh | Result |
|---|---:|---:|---:|---:|---|
| 9x7 | amplitude 8m | 0.2355s | 0.0020s | 63 vertices / 96 faces | PASS |
| 100x100 | amplitude 12m | 74.8048s | 0.4239s | 10,000 vertices / 19,602 faces | PASS |

Greybox checks passed:

- Matching digest between per-face and bulk candidate.
- Expected vertex and face counts.
- All generated faces and edges had derived-output markers.
- `downFacingFaces == 0`.
- `nonPositiveZFaces == 0`.
- Near-cap steep terrain normals stayed positive, with minimum normal Z about `0.0383`.

Public MCP high-variation edit validation also passed on a 17x9 terrain:

- Create passed with 153 vertices / 256 faces.
- Edit passed with revision `1 -> 2`.
- Smooth edit target was 9m; center sample after edit was 9.0, shoulder sample was 0.08, and outside sample was 0.0.
- Mesh normals after edit were 256 up / 0 down, with minimum normal Z about `0.2018`.
- MCP `ping` after the operation passed.

The main performance finding is strong: near-cap per-face generation remains tens of seconds, while the validation-only bulk candidate is sub-second in these greybox tests. Production output remains on the per-face path until a follow-on task explicitly adopts bulk output.

## Follow-On Work

- Durable localized-detail persistence and schema v2 design.
- Tiled/chunked storage and serializer/repository dispatch.
- Partial output regeneration.
- Production bulk-output adoption if live validation proves equivalence and host behavior is acceptable.
- Future evidence schema evolution if localized representation units need to become public evidence.

MTA-05 and MTA-06 may proceed on the existing uniform-grid substrate unless their representative cases require localized persistence, partial regeneration, or stronger hosted performance guarantees.
