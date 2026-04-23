# Summary: SEM-14 Harden `create_site_element` Request Recovery And Definition Boundaries
**Task ID**: `SEM-14`
**Status**: `completed`
**Date**: `2026-04-23`

## Shipped

- Added a dedicated semantic recovery seam at [request_shape_recovery.rb](../../../../src/su_mcp/semantic/request_shape_recovery.rb) to own malformed `create_site_element` request recovery or refusal before strict validation.
- Added a shared structural contract source at [request_shape_contract.rb](../../../../src/su_mcp/semantic/request_shape_contract.rb) for:
  - canonical top-level section ownership
  - family-specific `definition` field ownership
- Added bounded recovery for the two planned malformed classes:
  - whole canonical requests accidentally wrapped under top-level `definition`
  - unambiguous top-level family-owned geometry leaf fields that can be relocated into `definition`
- Added structured `malformed_request_shape` refusals with teaching details, including:
  - `expectedTopLevelSections`
  - `misnestedFields`
  - `elementType`
  - `allowedDefinitionFields`
  - `suggestedCorrection`
- Wired [semantic_commands.rb](../../../../src/su_mcp/semantic/semantic_commands.rb) so recovery now runs before `RequestValidator` and `RequestNormalizer`, while builders remain canonical-only consumers.
- Extended [request_validator.rb](../../../../src/su_mcp/semantic/request_validator.rb) to reject wrong-family `definition` fields with the same family-owned guidance.
- Updated [mcp_runtime_loader.rb](../../../../src/su_mcp/runtime/native/mcp_runtime_loader.rb) so `create_site_element` now exposes:
  - the canonical sectioned branch
  - a bounded wrapped-payload recovery branch
  - a bounded misnested-geometry recovery branch
  - tool text marking the compatibility path as recovery-only rather than a second supported contract
- Updated public docs in [README.md](../../../../README.md) and [sketchup_mcp_guide.md](../../../../sketchup_mcp_guide.md) to keep the sectioned shape canonical and explain the bounded recovery path.
- Added or updated tests for:
  - the new recovery seam
  - validator wrong-family ownership guidance
  - command recovery/refusal behavior before builder execution
  - loader schema branches and recovery-only description
  - native transport fixture coverage for the new malformed-shape refusal

## Validation

- `bundle exec ruby -Itest test/semantic/request_shape_recovery_test.rb`
- `bundle exec ruby -Itest test/semantic/semantic_request_validator_test.rb`
- `bundle exec ruby -Itest test/semantic/semantic_commands_test.rb`
- `bundle exec ruby -Itest test/runtime/native/mcp_runtime_loader_test.rb`
- `bundle exec rake ruby:test`
- `bundle exec rake ruby:lint`
- `bundle exec rake package:verify`

## Notes

- The implementation stayed inside the planned Ruby-owned seams:
  - loader schema
  - semantic recovery
  - semantic validation
  - semantic command orchestration
- The public contract is now aligned across:
  - runtime recovery/refusal behavior
  - validator ownership rules
  - loader schema discoverability
  - native contract fixtures
  - user-facing docs
- Discoverability now exists both before and after a bad call for the changed surface:
  - before a bad call: the loader schema exposes the canonical branch and bounded recovery branches, and the tool/docs now explain that the compatibility path is recovery-only
  - after a bad call: malformed and wrong-family requests return structured refusal details instead of opaque raw MCP param failures

## Remaining Gap

- `test/runtime/native/mcp_runtime_native_contract_test.rb` still skips locally without the staged native vendor runtime, so the new malformed-shape refusal transport case still needs confirmation in that environment.
- No additional SketchUp-hosted manual smoke pass was run in this session; downstream builder behavior is covered by the existing Ruby-side tests, but not by a fresh in-host create smoke check.
