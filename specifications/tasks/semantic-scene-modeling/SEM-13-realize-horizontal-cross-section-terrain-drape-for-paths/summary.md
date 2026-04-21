# Summary: SEM-13 Realize Horizontal Cross-Section Terrain Drape for Paths

## What Shipped

- Added a dedicated drape implementation in [path_drape_builder.rb](../../../../src/su_mcp/semantic/path_drape_builder.rb) that realizes `path + hosting.mode: "surface_drape"` as real terrain-following geometry instead of a planar corridor.
- Kept [path_builder.rb](../../../../src/su_mcp/semantic/path_builder.rb) as the family owner and routed hosted drape requests into the dedicated drape collaborator while preserving the existing planar path branch for non-drape requests.
- Added [surface_height_sampler.rb](../../../../src/su_mcp/semantic/surface_height_sampler.rb) so path drape sampling reuses the runtime's existing surface-traversal support through an internal semantic seam rather than the public `sample_surface_z` tool path.
- Added [builder_refusal.rb](../../../../src/su_mcp/semantic/builder_refusal.rb) and updated [semantic_commands.rb](../../../../src/su_mcp/semantic/semantic_commands.rb) so builder-owned drape feasibility failures surface as structured MCP refusals instead of falling back to planar path creation.
- Tightened [geometry_validator.rb](../../../../src/su_mcp/semantic/geometry_validator.rb) so consecutive duplicate centerline points are treated as invalid geometry before drape generation.
- Realized the planned drape behavior:
  - chord-length subdivision with preserved caller-provided vertices
  - `1.0 m` internal station spacing
  - 5-point cross-slope sampling
  - `0.02 m` top-surface clearance
  - 3-station moving-average smoothing with raw endpoints
  - post-smoothing re-clamp so `final_z` never falls below `raw_z`
  - `1000`-station tessellation cap with structured refusal
  - top ribbon stays above terrain while any `thickness` is applied downward for visual grounding
- Follow-up live fixes completed the final slice:
  - exact 1m spacing boundaries no longer duplicate the terminal station
  - the invalid centerline refusal message is now user-facing and specific
  - thickness now builds one coherent bottom ribbon plus side/end shell instead of per-triangle `pushpull`
  - draped face emission now prefers `entities.build { |builder| ... }` when available, with direct `add_face` retained as a compatibility fallback
  - host sampling now prepares and reuses a per-build sampling context instead of recollecting sampleable faces for every station sample
  - prepared host sampling caches reusable world-space face data so repeated elevation queries no longer refit the same terrain faces over and over
- Updated [README.md](../../../../README.md) so the public `create_site_element` guidance now describes the realized drape behavior rather than leaving `surface_drape` as an implied hosting intent only.

## Validation

- `bundle exec ruby -Itest -e 'load "test/semantic/path_drape_builder_test.rb"; load "test/semantic/path_builder_test.rb"; load "test/semantic/semantic_commands_test.rb"; load "test/semantic/semantic_request_validator_test.rb"'`
- `bundle exec rake ruby:test`
- `RUBOCOP_CACHE_ROOT=/tmp/rubocop-cache bundle exec rake ruby:lint`
- `bundle exec rake package:verify`
- Live SketchUp validation passed for:
  - flat control path
  - dense caller vertices preserved
  - longitudinal slope
  - cross-slope terrain
  - ridge smoothing / local peak preservation
  - thickness downward
  - unsampleable host refusal
  - terrain sample miss refusal
  - tessellation cap refusal
  - exact 1m station-boundary segment length
  - complex multi-hill / multi-valley terrain with coherent thick shell output
- Final live timing on the complex drape scenario improved from a `38.24s` average before the prepared-sampling-context optimization to a `2.40s` average after it, about `15.9x` faster.

## External Review

- Final code review was run through the required Grok-backed review step on the completed change set after the full local validation bar was green.
- No blocking architectural or correctness issues were identified in the final review state.
- Closure review with `grok-4.20` also found no blockers on the post-live-fix and `EntitiesBuilder`-optimized state.

## Docs And Metadata

- Updated [README.md](../../../../README.md) for the realized path drape behavior.
- Updated [task.md](./task.md) status to `completed`.
- Added this [summary.md](./summary.md) to capture the shipped slice, validations, and remaining gap.
- Updated [plan.md](./plan.md) with the final implemented outcome.

## Final State

- SEM-13 is fully closed and live-validated for the intended shipped slice.
- The final accepted implementation includes the prepared host-sampling optimization; no further optimization work is planned in this task.
- No code cleanup blockers remain from the implementation/fix/optimization rounds.
- Future work, if needed, is performance follow-up beyond the current slice rather than correctness repair.
