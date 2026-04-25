# Summary: MTA-02 Build Terrain State And Storage Foundation
**Task ID**: `MTA-02`
**Status**: `completed`
**Date**: `2026-04-25`

## Shipped

- Added `SU_MCP::Terrain::HeightmapState` as a SketchUp-free owner-local heightmap/grid state value with v1 schema fields, orthonormal basis validation, dimensions, spacing, nullable no-data elevations, revision, state identity, optional source and constraint references, and optional owner transform signature.
- Added `SU_MCP::Terrain::TerrainStateSerializer` for canonical JSON serialization, SHA-256 integrity digest generation, digest verification, current-version no-op migration, older-version migration refusal, unsupported newer-version refusal, corrupt JSON refusal, and malformed payload refusal.
- Added `SU_MCP::Terrain::AttributeTerrainStorage` for payload-oriented storage under `su_mcp_terrain/statePayload`, with an 8 MiB default serialized-size guardrail and JSON-safe write-failure/oversized refusals.
- Added `SU_MCP::Terrain::TerrainRepository` for domain-facing `save`, `load`, and `delete` outcomes, including saved/loaded summaries, recoverable missing-state absence, terminal refusals, and detectable owner-transform mismatch refusal.
- Added terrain tests for state invariants, canonical digest behavior, migration/refusal paths, namespace separation from `su_mcp`, repository round trips, representative 512x512 payload size, write failures, and owner transform mismatch.
- Added a skipped hosted smoke marker for the remaining live SketchUp persistence review.

## Contract And Runtime Notes

- No public MCP tool names, request schemas, response schemas, dispatcher entries, runtime registrations, native contract fixtures, or README tool examples changed.
- No finite user-facing runtime option set changed.
- Terrain payload data is stored outside `su_mcp`; `su_mcp` remains the lightweight Managed Scene Object metadata dictionary.
- Repository outcomes are JSON-safe domain hashes shaped for later adaptation to `ToolResponse`, but no public MCP boundary was added.

## Validation

- Failing baseline before implementation:
  - all four initial focused terrain tests failed with `LoadError` because the planned terrain runtime files did not exist.
- Focused terrain validation:
  - `bundle exec ruby -Itest -e 'Dir["test/terrain/*_test.rb"].sort.each { |path| load path }'`
  - result: 22 runs, 80 assertions, 0 failures, 1 skip.
- Broader Ruby validation:
  - `bundle exec rake ruby:test`
  - result: 561 runs, 2086 assertions, 0 failures, 29 skips.
- Lint:
  - `bundle exec rake ruby:lint`
  - result: 145 files inspected, no offenses.
- Package verification:
  - `bundle exec rake package:verify`
  - result: generated `dist/su_mcp-0.20.0.rbz`.

## PAL Codereview

- PAL codereview with `grok-4.20` completed after local file review.
- Findings addressed:
  - added default older-schema-version migration failure coverage.
  - removed redundant `JSON.parse` work from `TerrainRepository#save` by adding `TerrainStateSerializer#serialize_with_summary`.
  - froze normalized elevation arrays after validation to protect large-grid state from accidental mutation.
- Focused terrain tests, full Ruby tests, lint, and package verification were rerun after follow-up changes where relevant.

## Live Review Follow-Up

- Initial live SketchUp smoke saved the payload under `su_mcp_terrain/statePayload` and confirmed the payload did not leak into `su_mcp`.
- The same smoke exposed that `Geom::Transformation#to_s` is not a stable owner-transform signature in hosted SketchUp; two reads of the same owner transform produced different object-id-like strings and caused a false `owner_transform_unsupported` refusal.
- Fixed `AttributeTerrainStorage#owner_transform_signature` to use stable `Transformation#to_a` matrix values when available, with fallback to no detectable signature when a stable matrix is unavailable.
- Added regression coverage for stable matrix signatures and repository load without false transform mismatch.
- Post-fix validation:
  - focused terrain suite: 24 runs, 83 assertions, 0 failures, 1 hosted smoke skip.
  - full Ruby suite: 563 runs, 2089 assertions, 0 failures, 29 skips.
  - lint: 145 files inspected, no offenses.
- Follow-up live SketchUp smoke after the matrix-signature fix returned:
  - `saved_outcome: "saved"`
  - `loaded_outcome: "loaded"`
  - `terrain_payload_present: true`
  - `payload_leaked_to_su_mcp: false`
- Full save/reopen hosted persistence was then verified after reopening the model:
  - `owner_found: true`
  - `loaded_outcome: "loaded"`
  - `terrain_payload_present: true`
  - `terrain_payload_bytes: 620`
  - `payload_leaked_to_su_mcp: false`
  - loaded state retained the v1 heightmap schema, owner-local basis, 2x2 dimensions, nullable elevation value, revision, state id, source summary, digest summary, and stable matrix transform signature.

## Remaining Manual Verification

- Live SketchUp in-session repository save/load has been verified after the stable matrix-signature fix.
- Full save/reopen persistence across a SketchUp model restart has been verified.
- No remaining MTA-02 manual verification gap is known. `test/terrain/terrain_repository_hosted_smoke_test.rb` remains as the hosted-smoke record and reminder for future regression passes.
