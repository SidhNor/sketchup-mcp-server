# Summary: MTA-03 Create Or Adopt Managed Terrain Surface
**Task ID**: `MTA-03`
**Status**: `completed`
**Date**: `2026-04-26`

## Current State

- Implementation is complete and the focused live public-client retest passed after the boundary and performance fixes.
- Automated test, lint, package verification, live public-client checks, and final Grok 4.20 codereview are green.
- The only remaining verification gap is that save/reopen persistence was not rerun in the final live pass; this is recorded as a residual gap, not a known functional failure.

## Implemented So Far

- Added `create_terrain_surface` as a public terrain-owned MCP tool with `lifecycle.mode` values `create` and `adopt`.
- Added runtime routing through the native loader, dispatcher, facade, and command factory without routing terrain creation through `create_site_element`.
- Added request validation for required metadata, finite lifecycle and definition options, create/adopt section rules, grid caps, duplicate terrain identity, malformed targets, and supported adoption source refusals.
- Added create-mode support for flat `heightmap_grid` terrain state, optional `placement.origin`, lightweight `su_mcp` owner metadata, terrain repository persistence, and deterministic regular-grid derived mesh output.
- Added adopt-mode support for explicit target resolution, adaptive heightmap derivation through existing surface sampling support, source summary and sampling evidence, derived output generation, and source erase only after managed output succeeds.
- Added JSON-safe success evidence for operation, managed terrain owner, saved terrain state, derived output, request/source summaries, and adoption sampling details.
- Updated README public tool documentation, examples, refusal behavior, and native contract fixtures.
- After live testing found adoption failures, changed adoption sampling to convert source bounds to public meters before calling `sample_surface_z`, changed create placement and mesh generation to convert public meter inputs to SketchUp internal units, and added public diagnostics to incomplete-sampling refusals.
- After live retesting found exact max-edge sampling misses, changed shared `sample_surface_z` runtime-face handling to accept points within sampler tolerance of face edges.
- Added request-local XY indexing for prepared face entries so point-grid sampling narrows candidate faces before intersection/classification instead of scanning every prepared face for every sample.
- Final live retesting confirmed boundary sampling, flat source adoption, grouped terrain adoption, source replacement, evidence, undo, caps, and representative performance.

## Contract And Runtime Notes

- Finite user-facing options are aligned across loader schema, runtime validator constants, refusal payloads, tests, and README examples.
- `create_terrain_surface` remains a distinct terrain command because it owns terrain state, source replacement, repository persistence, and derived terrain output.
- Terrain payloads are stored only through `su_mcp_terrain/statePayload`; `su_mcp` remains lightweight identity metadata.
- Success and refusal responses follow the existing `ToolResponse.success` / `ToolResponse.refusal` vocabulary and avoid raw SketchUp objects or durable generated face/vertex identities.

## Validation

- Full Ruby suite:
  - `bundle exec rake ruby:test`
  - result: 591 runs, 2237 assertions, 0 failures, 0 errors, 30 skips.
- Lint:
  - `bundle exec rake ruby:lint`
  - result: 157 files inspected, no offenses detected.
- Package verification:
  - `bundle exec rake package:verify`
  - result: generated `dist/su_mcp-0.20.0.rbz`.
- Post-live-failure local validation:
  - `bundle exec rake ruby:test`
  - result: 594 runs, 2257 assertions, 0 failures, 0 errors, 30 skips.
  - `bundle exec rake ruby:lint`
  - result: 157 files inspected, no offenses detected.
  - `bundle exec rake package:verify`
  - result: generated `dist/su_mcp-0.20.0.rbz`.
  - `git diff --check`
  - result: clean.
- Post-boundary/performance-fix local validation:
  - `bundle exec rake ruby:test`
  - result: 596 runs, 2265 assertions, 0 failures, 0 errors, 30 skips.
  - `bundle exec rake ruby:lint`
  - result: 158 files inspected, no offenses detected.
  - `bundle exec rake package:verify`
  - result: generated `dist/su_mcp-0.20.0.rbz`.
- Focused post-fix validation:
  - `bundle exec ruby -Itest -e 'ARGV.each { |path| load path }' test/scene_query/sample_surface_z_scene_query_commands_test.rb test/terrain/terrain_surface_adoption_sampler_test.rb test/terrain/terrain_surface_commands_test.rb`
  - result: 47 runs, 187 assertions, 0 failures, 0 errors, 0 skips.
- Hosted smoke availability:
  - `bundle exec ruby -Itest -e 'ARGV.each { |path| load path }' test/terrain/terrain_repository_hosted_smoke_test.rb test/scene_query/sample_surface_profile_hosted_smoke_test.rb test/scene_validation/measure_scene_hosted_smoke_test.rb`
  - result: 3 runs, 0 assertions, 3 skips.

## PAL Codereview

- PAL codereview with `grok-4.20` completed for the implemented change set.
- Findings addressed:
  - moved adoption sampling before model mutation begins so adoption refusals do not start a SketchUp operation.
  - replaced an implicit `respond_to?` test seam in adoption sampling with an explicit constructor dependency.
  - removed a test-only source erase branch and used the production `source_entity&.erase!` path.
  - added descriptions to finite loader schema options for lifecycle mode and definition kind.
- Focused checks and the full validation set were rerun after follow-up changes.
- Final PAL codereview with `grok-4.20` found no critical, high, medium, or low issues after the final live retest and performance fixes.
- Grok's only residual concern was the same hosted verification gap recorded here: save/reopen persistence was not rerun in the final live pass.

## Live Public-Client Testing

- First live pass: create path, discovery, public lookup, public sampling of created terrain, scene properties, refusals, atomicity, and undo-create passed.
- First live pass failure: every adopt happy-path attempt refused with `source_sampling_incomplete`, including publicly sampleable flat and large terrain sources.
- Second live pass after the unit-contract fix: create meter placement passed, large grouped terrain adoption passed, adoption evidence passed, adoption undo passed, public lookup/sampling interoperability passed, and representative 10,000-sample adoption was functional but slow at about 80 seconds.
- Second live pass failure: exact max-edge samples still missed on simple flat faces and created terrain, blocking top-level flat-face adoption.
- Final live pass after the boundary/performance fix: create meter terrain, exact-boundary sampling, top-level flat-face adoption, simple flat-group adoption, large grouped wavy adoption, adoption evidence, source replacement, public lookup, undo-adopt, cap refusals, and representative performance all passed.
- Final performance results: create 64x64 about 3.01s MCP, create 100x100 about 18.17s MCP, create 128x78 about 16.95s MCP, and representative 80m by 80m wavy adoption about 31.25s MCP / 43.46s wall-clock.
- Save/reopen persistence was not rerun in the final live pass and remains the only explicit verification gap.
