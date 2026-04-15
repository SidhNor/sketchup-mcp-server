# SEM-02 Implementation Summary

## Status Correction

- The first-wave vocabulary expansion landed, but the task is reopened because the public unit contract is not yet enforced in code.
- `create_site_element` currently forwards raw numeric lengths into SketchUp semantic builders and serializes numeric semantic outputs back out without an explicit meters conversion.
- In practice, that means the public semantic create surface still behaves like SketchUp internal inches instead of the intended meter-based MCP contract.
- The remaining `SEM-02` work is a bounded Ruby-side remediation: make all supported `create_site_element` types accept meters and return meters consistently without moving unit logic into Python or changing the public tool shape.

## Delivered

- Extended the public `create_site_element` semantic surface across Ruby, Python, and the shared bridge contract for:
  - `path`
  - `retaining_edge`
  - `planting_mass`
  - `tree_proxy`
- Preserved one public semantic command and one Ruby-owned builder registry instead of adding new public creation tools.
- Added Ruby builders for the new semantic types plus a shared planar-geometry helper for line- and polygon-based site elements.
- Expanded semantic request validation with the shipped SEM-02 refusal taxonomy:
  - `unsupported_element_type`
  - `missing_element_payload`
  - `missing_required_field`
  - `invalid_geometry`
  - `invalid_numeric_value`
  - `contradictory_payload`
  - `unsupported_option`
- Kept Python as a thin MCP adapter by switching `create_site_element` to a typed discriminated request schema and direct passthrough payload shaping.
- Expanded managed-object metadata and serialization to include the shipped per-type fields for the new semantic objects.
- Updated the shared bridge contract artifact and both native contract suites for created and refused SEM-02 outcomes.
- Added a centralized Ruby meter-contract remediation for `create_site_element`:
  - public geometric inputs are normalized to SketchUp internal lengths once at the semantic command boundary
  - semantic builders remain geometry-only and do not own unit conversion policy
  - managed-object type-specific metadata stays in public meter units
  - managed-object bounds are converted back to meters in the semantic serializer
- Clarified the README so the public `create_site_element` dimensions contract now explicitly states meter semantics independent of active model display units.

## Tests Added

- Ruby validator tests for the SEM-02 discriminated payload contract and refusal taxonomy.
- Ruby builder tests for `path`, `retaining_edge`, `planting_mass`, and `tree_proxy`.
- Ruby registry, command, and serializer coverage for the expanded semantic slice.
- Ruby request-normalizer coverage for centralized public-meters-to-internal normalization.
- Ruby command coverage proving builder inputs are normalized while persisted metadata remains in public units.
- Ruby serializer coverage proving semantic managed-object bounds are returned in meters.
- Python tool-schema and passthrough tests for the expanded `create_site_element` boundary.
- Ruby and Python contract tests for the new SEM-02 `create_site_element` cases.

## Validation

- `bundle exec rake ruby:lint`
- `bundle exec rake ruby:test`
- `bundle exec rake ruby:contract`
- `bundle exec rake python:lint`
- `bundle exec rake python:test`
- `bundle exec rake python:contract`
- `bundle exec rake ci`

## Review

- `mcp__pal__codereview` with model `grok-code`
  - Result: no remaining findings on the final validated change set.
- `mcp__pal__codereview` with model `grok-4.20`
  - Result: no confirmed findings on the current validated change set.
- `mcp__pal__codereview` with model `grok-4.20` after the meter-contract remediation
  - Result: no confirmed findings on the current validated change set.
- Local review follow-up completed before the final codereview result:
  - fixed a terminal-offset bug in `src/su_mcp/semantic/planar_geometry_helper.rb` that could twist the generated corridor polygon for `path` and `retaining_edge`
  - added a regression assertion in `test/path_builder_test.rb`

## Remaining Gaps

- No SketchUp-hosted manual verification was completed in this session.
- Meter-accurate live geometry and undo behavior for the new semantic types still need confirmation inside SketchUp itself.

## Manual Verification

- Not run in a live SketchUp host during this implementation session.
