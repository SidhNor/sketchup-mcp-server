# SEM-01 Implementation Summary

## Delivered

- Added the public `create_site_element` MCP tool in the Python adapter and registered it in deterministic tool order ahead of primitive creation helpers.
- Added the first Ruby semantic runtime slice under `src/su_mcp/semantic/` plus the `SemanticCommands` entrypoint.
- Implemented Ruby-owned builder selection for the delivered MVP semantic types:
  - `pad`
  - `structure`
- Implemented Managed Scene Object metadata persistence in the `su_mcp` attribute dictionary with the delivered SEM-01 fields:
  - `managedSceneObject`
  - `sourceElementId`
  - `semanticType`
  - `status`
  - `state`
  - `schemaVersion`
  - `structureCategory` for `structure`
- Implemented JSON-safe semantic serialization for created managed objects.
- Applied scene-facing wrapper properties for the delivered slice:
  - `name`
  - `tag`
  - `material`
- Implemented structured refusal outcomes for:
  - unsupported semantic types
  - contradictory `pad` versus `structure` payloads
  - degenerate footprints
  - self-intersecting or vertex-touching footprints
  - missing `structureCategory`
  - unapproved `structureCategory`
  - non-positive `structure.height`
  - non-positive `pad.thickness`
- Updated the shared bridge contract artifact and both native contract suites for created and refused `create_site_element` outcomes.

## Tests Added

- Python tool tests for registration order, schema exposure, passthrough request shaping, and request-id propagation.
- Python contract tests for the SEM-01 `create_site_element` cases.
- Ruby dispatcher and socket-server wiring tests for the new semantic command path.
- Ruby semantic command tests for creation envelope behavior and refusal outcomes.
- Ruby registry, metadata, serializer, `pad`, and `structure` builder tests.
- A test-owned semantic fixture overlay at `test/support/semantic_test_support.rb` for operation tracking, wrapper-group creation, attribute writes, and face `pushpull` behavior.

## Validation

- `bundle exec rake ruby:lint ruby:test ruby:contract`
- `uv run ruff check python/src python/tests`
- `uv run pytest python/tests --ignore=python/tests/contracts`
- `uv run pytest python/tests/contracts`
- `bundle exec rake package:verify`

## Review

- `mcp__pal__codereview` with model `grok-4.20`
  - Result: no concrete findings on the reviewed change set.
- `clink gemini` readonly codereview
  - Findings raised during review:
    - face-orientation hardening for semantic extrusion
    - collinear or vertex-touching self-intersection gaps in footprint validation
  - Resulting follow-up changes:
    - builders now normalize reversed horizontal faces via `reverse!` before `pushpull`
    - request validation now rejects additional touching or collinear self-intersection cases
- Residual review note:
  - manual SketchUp-hosted verification remains the main remaining confidence gap rather than a known code defect in the reviewed local implementation

## Remaining Gaps

- Manual SketchUp-hosted verification is still required for:
  - one-operation undo behavior in the live SketchUp runtime
  - representative live `pad` and `structure` geometry outcomes beyond the non-hosted fixture layer
  - refusal behavior for live invalid inputs in the actual SketchUp host

## Manual Verification

- No SketchUp-hosted manual verification was completed in this implementation session.
