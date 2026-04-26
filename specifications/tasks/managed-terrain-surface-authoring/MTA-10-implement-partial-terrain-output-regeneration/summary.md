# MTA-10 Implementation Summary

**Status**: completed  
**Task**: `MTA-10 Implement Partial Terrain Output Regeneration`  
**Captured**: 2026-04-26

## Implemented

- Added `SU_MCP::Terrain::TerrainOutputCellWindow` to convert dirty sample windows into affected output cell windows using overlap semantics.
- Extended internal `TerrainOutputPlan` with `cell_window` and previous-state digest/revision context while preserving the public `output.derivedMesh` summary shape.
- Added derived face ownership metadata under `su_mcp_terrain`:
  - `outputSchemaVersion`
  - `gridCellColumn`
  - `gridCellRow`
  - `gridTriangleIndex`
- Kept derived edges marker-only.
- Updated `TerrainMeshGenerator#regenerate` to:
  - refuse unsupported child entities before ownership lookup or deletion,
  - validate exact affected-cell ownership before partial erase,
  - replace only affected owned faces for safe dirty-window edits,
  - avoid rewriting retained unchanged faces for whole-state digest/revision linkage,
  - fall back to full-grid regeneration for legacy, duplicate, incomplete, whole-grid, or otherwise unsafe output states.
- Removed the per-face whole-terrain digest/revision ownership dependency after hosted performance showed retained-face relinking was the dominant residual cost. The public `output.derivedMesh.derivedFromStateDigest` remains the full output-to-state digest linkage.
- Added a terrain-command direct owner-resolution path for top-level managed terrain owners so `edit_terrain_surface` does not recursively scan every face and edge in large terrain outputs before each edit.
- Kept public MCP tool names, request schemas, dispatcher routing, and persisted `heightmap_grid` v1 state unchanged.
- Updated README wording so terrain edits no longer claim unconditional full regeneration.
- Added implementation guardrails to `plan.md` after Step 05 review.

## Public Contract

No public MCP request fields, response fields, schema entries, dispatcher routes, or user-facing strategy selectors were added.

Public terrain output remains centered on:

- `output.derivedMesh.meshType`
- `output.derivedMesh.vertexCount`
- `output.derivedMesh.faceCount`
- `output.derivedMesh.derivedFromStateDigest`

Contract tests assert the new internal metadata vocabulary does not appear in public output or persisted state.

## Local Validation

- Red baseline before implementation:
  - Focused skeleton suite: `50 runs, 284 assertions, 3 failures, 15 errors`.
- Focused MTA-10 suite after implementation:
  - `50 runs, 370 assertions, 0 failures, 0 errors, 0 skips`.
- Full terrain suite:
  - `132 runs, 1241 assertions, 0 failures, 0 errors, 2 skips`.
- Full Ruby suite:
  - `714 runs, 3391 assertions, 0 failures, 0 errors, 35 skips`.
- RuboCop:
  - `bundle exec rubocop --cache false Gemfile Rakefile rakelib test src/su_mcp`
  - `188 files inspected, no offenses detected`.
- Package verification:
  - `bundle exec rake package:verify`
  - produced `dist/su_mcp-0.22.0.rbz`.
- Diff hygiene:
  - `git diff --check` passed.

Post-performance correction validation after removing per-face whole-state digest/revision ownership:

- Focused generator suite:
  - `bundle exec ruby -Itest test/terrain/terrain_mesh_generator_test.rb`
  - `25 runs, 206 assertions, 0 failures, 0 errors, 0 skips`.
- Related contract/command suites:
  - `terrain_contract_stability_test.rb`: `3 runs, 61 assertions, 0 failures`.
  - `terrain_surface_commands_test.rb`: `15 runs, 67 assertions, 0 failures`.
  - `terrain_output_plan_test.rb`: `3 runs, 17 assertions, 0 failures`.
- Full terrain suite:
  - `135 runs, 1249 assertions, 0 failures, 0 errors, 2 skips`.
- Full Ruby suite:
  - `717 runs, 3399 assertions, 0 failures, 0 errors, 35 skips`.
- Full RuboCop:
  - `188 files inspected, no offenses detected`.
- Diff hygiene:
  - `git diff --check` passed.

Final local validation after the terrain owner resolver shortcut:

- Focused terrain command suite:
  - `bundle exec ruby -Itest test/terrain/terrain_surface_commands_test.rb`
  - `17 runs, 71 assertions, 0 failures, 0 errors, 0 skips`.
- Focused RuboCop:
  - `bundle exec rubocop --cache false src/su_mcp/terrain/terrain_surface_commands.rb test/terrain/terrain_surface_commands_test.rb`
  - `2 files inspected, no offenses detected`.
- Full terrain suite:
  - `137 runs, 1253 assertions, 0 failures, 0 errors, 2 skips`.
- Full Ruby suite:
  - `719 runs, 3403 assertions, 0 failures, 0 errors, 35 skips`.
- Full RuboCop:
  - `188 files inspected, no offenses detected`.
- Diff hygiene:
  - `git diff --check` passed.

## Code Review

`mcp__pal__.codereview` with `grok-4.20` completed after local validation, and a final post-performance Step 10 review completed after the per-face digest/revision removal and terrain owner resolver shortcut were patched into source.

Findings and dispositions:

- Critical: `TerrainOutputCellWindow#each_cell` yielded one array value instead of two scalar values.
  - Disposition: changed to `yield column, row`. Local tests still pass.
- Medium: `refresh_derived_face_state_linkage` rewrote digest/revision on newly emitted faces.
  - Disposition: first guarded already-current faces, then removed retained-face relinking entirely after hosted performance evidence showed the global per-face digest model was misaligned with partial regeneration.
- Medium: suggestion to ignore stale or legacy derived faces outside the dirty cell window.
  - Disposition: intentionally not changed. MTA-10 treats any untrusted derived terrain output ownership under the terrain owner as unsafe for partial regeneration; full-grid fallback is the conservative recovery.
- Low: `TerrainOutputPlan#execution_strategy` is currently not read by production logic.
  - Disposition: retained as internal MTA-09/MTA-10 planning vocabulary covered by tests and confirmed not to leak publicly.
- Low: README said affected output cells rather than faces.
  - Disposition: changed README wording to “affected output faces.”
- Final post-performance review: no additional source findings.
  - Disposition: no code changes required. The review noted clean packaged redeploy verification as an additional confidence check; this was accepted as non-blocking closeout evidence.

Focused tests, focused lint, full terrain tests, full Ruby tests, full lint, package verification, and `git diff --check` were rerun after review follow-up changes.

## Hosted SketchUp Validation Progress

Hosted validation started after redeploy using the MCP tool wrappers. All test terrain was placed to the side of existing site geometry at offsets beyond the observed site bounds.

### Iteration Count

- Fix-oriented hosted iterations completed so far: 5.
- Hosted matrix executions completed so far: 14, including exploratory fix runs and one expected coordinate-refusal retry during the near-cap case.
- Matrix scenarios with accepted evidence so far: 10 of 10 for correctness; `MTA10-MCP-09` was validated as a public save/reopen load-and-edit scenario without greybox partial-path proof.

Fix-oriented iterations:

1. Initial hosted partial attempts (`MTA10-MCP-01`, `01b`) fell back with `incomplete_ownership`.
2. Source/redeploy fix for real SketchUp face recognition allowed true partial replacement (`01c`), but edge count grew from 43 to 49.
3. Partial erase was expanded to delete affected faces plus edges owned only by affected faces (`01d`, `01e`), proving the remaining growth was orphan derived edges.
4. Orphan derived-edge cleanup was added; direct partial emission preserved edge count (`01f`).
5. Builder-based partial emission was restored with orphan cleanup, producing the accepted hosted result (`01g`).

### Fixes Captured From Hosted Validation

- Real SketchUp `Sketchup::Face` instances do not expose the fake-test `points` helper, so derived face detection now recognizes real face entities instead of rejecting valid hosted output as incomplete ownership.
- Partial erase now removes affected owned faces and any derived edges that are exclusively owned by those affected faces.
- Partial regeneration now performs derived orphan-edge cleanup after emitting replacement faces.
- Builder-based partial face emission remains in place; orphan cleanup is the correction that prevents edge-count drift.
- The local `emit_cell_window_via_builder` change was restored after hosted validation showed builder generation plus orphan cleanup preserves the intended topology.

### Scenario Evidence So Far

| ID | Result | Evidence |
| --- | --- | --- |
| `MTA10-MCP-01` | Passed pre-correction | Fresh 5x4 partial edit used `cellWindow [1,1,2,2]`, replaced 8 faces, retained 16, kept 24 faces/43 edges, and preserved upward normals. The original run also relinked all retained faces to revision 2; the post-performance correction removes that global relink. |
| `MTA10-MCP-02` | Passed | Non-square 7x4 last-row/column edit clipped to `cellWindow [5,2,5,2]`, replaced 2 faces, retained 34, kept 36 faces/63 edges, and preserved upward normals. |
| `MTA10-MCP-03` | Passed | Legacy marker-only metadata produced `legacy_output` fallback, fully rebuilt 24 faces/43 edges, removed stale marker-only output, and restored ownership metadata. |
| `MTA10-MCP-04` | Superseded | Stale digest/revision metadata produced `stale_metadata` fallback before the post-performance correction. After removing global per-face digest/revision ownership, this is no longer an MTA-10 fallback scenario; replacement validation should cover missing, duplicate, and incomplete affected-window ownership instead. |
| `MTA10-MCP-05` | Passed | Duplicate tuple ownership produced `duplicate_ownership` fallback, fully rebuilt 24 faces/43 edges, cleared tuple duplication, and restored ownership metadata. |
| `MTA10-MCP-06` | Passed | Incomplete derived face ownership produced `incomplete_ownership` fallback, restored the missing face, rebuilt 24 faces/43 edges, and restored ownership metadata. |
| `MTA10-MCP-07` | Passed | Unsupported child group caused refusal `terrain_output_contains_unsupported_entities`; regeneration trace stayed empty and all 24 prior derived faces were retained. |
| `MTA10-MCP-08` | Passed | Partial edit replaced 8 faces and retained 16; `Sketchup.undo` restored all 24 original face identities, revision 1, and the original digest. |
| `MTA10-MCP-09` | Passed public load/edit check | After saving, redeploying, and reopening `TestGround.skp`, `mta10-mcp-02-20260426` loaded from persisted state at revision 2 and edited successfully to revision 3 with the expected 7x4 derived mesh summary. This no-eval check proves save/reopen state load and edit correctness, but not internal partial-vs-full path selection. |
| `MTA10-MCP-10` | Passed | Near-cap 100x100 terrain created 19,602 faces/29,601 edges; bounded edit used `cellWindow [49,49,50,50]`, replaced 8 faces, retained 19,594, and preserved topology and normals. |

### Clean Redeploy No-Eval Sanity

After the user saved the scene, redeployed, and reopened it, the following MCP-wrapper-only checks passed without `eval_ruby`:

- Runtime health: `ping` returned ready and `get_scene_info` confirmed `C:\Users\Gleb\Documents\TestGround.skp` was reopened with the saved MTA-10 validation terrains present.
- Save/reopen load scenario: `edit_terrain_surface` on pre-save terrain `mta10-mcp-02-20260426` loaded revision 2 from persisted `heightmap_grid` state and edited to revision 3, preserving the full derived mesh summary of 28 vertices and 36 faces.
- Fresh clean-deploy create/edit: `mta10-clean-01-fresh-20260426` created as a 5x4 terrain and edited from revision 1 to revision 2 with a 20-vertex/24-face derived mesh summary.
- Persisted refusal behavior: `mta10-mcp-07-unsupported-20260426` still refused with `terrain_output_contains_unsupported_entities` after reopen.
- Persisted near-cap edit: `mta10-mcp-10-near-cap-20260426` loaded revision 2 and edited to revision 3 on a 100x100 terrain with 10,000 vertices and 19,602 faces.

These clean-deploy checks intentionally avoid greybox trace and metadata inspection. They prove public MCP behavior after save/reopen and redeploy; partial-vs-full path evidence remains covered by the earlier hosted greybox matrix.

### Hosted Performance Matrix

Performance validation used two side-by-side 100x100 managed terrains at the MTA-03 sample cap. Each terrain produced 10,000 vertices, 19,602 derived faces, and 29,601 derived edges. The normal terrain kept current ownership metadata so edits could use partial replacement. The comparison terrain had derived face digest/revision intentionally staled before each matching edit, forcing full-grid fallback in the pre-correction implementation. Timings below are MCP wrapper wall times for the edit calls only; the deliberate stale-metadata setup time is excluded.

| Scenario | Changed samples | Partial replacement | Forced full replacement | Partial time | Full fallback time | Result |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Single bounded point edit, no constraints | 1 | 8 faces | 19,602 faces | 3.22s | 3.70s | Partial was 13.0% faster and retained 19,594 faces. |
| Overlapping 3x3 bounded block edit, no constraints | 9 | 32 faces | 19,602 faces | 3.11s | 3.74s | Partial was 17.0% faster and retained 19,570 faces. |
| Horizontal corridor transition, no rectangle bounds | 567 | 1,312 faces | 19,602 faces | 3.24s | 3.67s | Partial was 11.8% faster and retained 18,290 faces. |
| Vertical corridor transition crossing the horizontal corridor | 567 | 1,312 faces | 19,602 faces | 3.39s | 4.10s | Partial was 17.4% faster and retained 18,290 faces. |
| Bounded rectangle with smooth blend and preserve-zone bounds | 504 edited, 25 protected | 1,152 faces | 19,602 faces | 3.97s | 4.81s | Partial was 17.5% faster and retained 18,450 faces. |

Additional observations:

- All performance scenarios preserved 19,602 total derived faces, 29,601 derived edges, complete tuple ownership, a single current digest, and upward normals after the edit.
- The cross-intersecting corridor scenario proved repeated edits on top of prior edits: point edit, block edit, horizontal corridor, vertical crossing corridor, then constrained bounded edit all ran against the same normal terrain.
- The first constrained attempt with a fixed control inside the edit region correctly refused with `fixed_control_conflict`; it was not included in the performance comparison.
- These pre-correction wall-clock gains were measurable but modest because retained faces were still relinked to the whole-state digest/revision after each edit. The implementation has since been corrected to remove retained-face relinking; hosted performance should be rerun after redeploy to measure the expected larger wall-clock gain.

### Patched Hosted Performance Recheck

After the per-face digest/revision correction was eval-patched into the live SketchUp runtime, repeated timings still showed little improvement. Command profiling then showed the dominant cost was not terrain output regeneration: `TerrainMeshGenerator#regenerate` took about 0.32s, while `prepare_edit_context` took about 4.4s because the generic `TargetReferenceResolver` recursively scanned the now-large scene to find the terrain owner by `sourceElementId`.

After eval-patching a terrain-command direct top-level owner resolver, `prepare_edit_context` dropped to about 70ms and the same point edit dropped from about 4.8s to 0.46s. The resolver shortcut was then patched into local source with tests.

Corrected hosted performance timings, with both eval patches active:

| Scenario | Changed samples | Partial replacement | Forced full replacement | Partial time | Full fallback time | Result |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Single bounded point edit, no constraints | 1 | 8 faces | 19,602 faces | 0.47s | 1.33s | Partial was 64.6% faster and retained 19,594 faces. |
| Overlapping 3x3 bounded block edit, no constraints | 9 | 32 faces | 19,602 faces | 0.55s | 1.29s | Partial was 57.4% faster and retained 19,570 faces. |
| Corridor transition after prior edits | 497 | 1,152 faces | 19,602 faces | 0.46s | 1.50s | Partial was 69.0% faster and retained 18,450 faces. |
| Bounded rectangle with smooth blend and preserve-zone bounds | 600 edited, 25 protected | 1,352 faces | 19,602 faces | 0.63s | 1.49s | Partial was 57.6% faster and retained 18,250 faces. |

Additional profiler evidence:

- With the resolver shortcut active, a point edit spent about 0.39s in `TerrainSurfaceCommands#edit_terrain_surface`, including about 0.32s in `TerrainMeshGenerator#regenerate`.
- The remaining generator cost is mostly conservative full-output scans: unsupported-child guard, affected-window ownership collection, and orphan-edge cleanup.
- The corrected hosted timings were produced with eval patches matching the source changes that were then committed locally; this was accepted as sufficient MTA-10 closeout evidence.

## MCP Client Test Scenario Matrix

| ID | MCP calls | Terrain case | Expected path | Assertions |
| --- | --- | --- | --- | --- |
| MTA10-MCP-01 | `create_terrain_surface`, `edit_terrain_surface` | Fresh 5x4 terrain, single interior sample edit | Partial | Public response remains `edited`; `output.derivedMesh` reports full mesh counts; only affected owned faces are replaced; adjacent face identities remain; no internal metadata terms leak. |
| MTA10-MCP-02 | `create_terrain_surface`, `edit_terrain_surface` | Fresh non-square terrain, dirty window touching last sample column/row | Partial | Affected cell window clips to the valid last cell; replacement face count is two per affected cell; normals stay upward; seam deltas remain within tolerance. |
| MTA10-MCP-03 | `create_terrain_surface`, manual legacy metadata downgrade, `edit_terrain_surface` | Marker-only derived output | Full fallback | Edit succeeds by full-grid regeneration; old marker-only faces are removed; regenerated faces carry ownership metadata; public output shape stays stable. |
| MTA10-MCP-04 | `create_terrain_surface`, edit or reopen older digest-stamped output, `edit_terrain_surface` | Old whole-state digest/revision on otherwise complete owned faces | Partial | Old digest/revision face attributes are ignored for affected-window ownership; complete cell/triangle ownership still permits partial replacement. |
| MTA10-MCP-05 | `create_terrain_surface`, manual duplicate ownership mutation, `edit_terrain_surface` | Duplicate affected triangle ownership | Full fallback | Duplicate ownership prevents partial erase; full-grid output is rebuilt; public response does not expose fallback internals. |
| MTA10-MCP-06 | `create_terrain_surface`, manual incomplete ownership mutation, `edit_terrain_surface` | Missing one affected triangle face | Full fallback | Incomplete ownership prevents partial erase; full-grid output is rebuilt; derived markers and upward normals are present. |
| MTA10-MCP-07 | `create_terrain_surface`, add unmanaged child group, `edit_terrain_surface` | Unsupported child under terrain owner | Refusal | Refuses with `terrain_output_contains_unsupported_entities` before deleting output; existing derived faces remain present. |
| MTA10-MCP-08 | `create_terrain_surface`, `edit_terrain_surface`, `Sketchup.undo` | Fresh partial edit | Partial then undo | One undo restores prior state revision/digest and output geometry; no unmanaged scene content is touched. |
| MTA10-MCP-09 | `create_terrain_surface`, save/reopen, `edit_terrain_surface` | Reopened metadata-bearing terrain | Partial | Face ownership attributes survive save/reopen; subsequent bounded edit uses partial replacement; seams, markers, normals, and digest linkage pass inspection. |
| MTA10-MCP-10 | `create_terrain_surface`, `edit_terrain_surface` | Near-cap terrain with small bounded edit | Partial or fallback if host safety fails | Runtime remains responsive; partial path replaces expected affected faces when ownership is complete; fallback remains correct if safety checks fail. |

## Closeout Notes

- No public strategy telemetry was added, by design. Hosted validation uses greybox inspection or temporary tracing to distinguish partial from fallback; the existing public operation recap remains shape-compatible and should not be treated as partial-path proof.
- Step 11 task-estimation calibration was completed in `size.md`.
