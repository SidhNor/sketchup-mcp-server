# Summary: PLAT-14 Establish Native MCP Tool Contract And Response Conventions

## What Shipped

- Added [NativeToolDefinition](../../../../src/su_mcp/runtime/native/tool_definition.rb) so the native catalog now uses one validated Ruby-owned declaration contract instead of permissive ad hoc hashes.
- Updated [McpRuntimeLoader](../../../../src/su_mcp/runtime/native/mcp_runtime_loader.rb) so every public native tool declares explicit `title`, `annotations`, and `classification`, with `eval_ruby` marked as the only `escape_hatch`.
- Added [ToolResponse](../../../../src/su_mcp/runtime/tool_response.rb) as the shared success/refusal envelope helper for first-class native tools.
- Migrated representative semantic and hierarchy flows onto the shared response helper posture in:
  - [semantic_commands.rb](../../../../src/su_mcp/semantic/semantic_commands.rb)
  - [hierarchy_maintenance_commands.rb](../../../../src/su_mcp/semantic/hierarchy_maintenance_commands.rb)
  - [request_validator.rb](../../../../src/su_mcp/semantic/request_validator.rb)
  - [managed_object_metadata.rb](../../../../src/su_mcp/semantic/managed_object_metadata.rb)
- Added a shared runtime failure-translation seam in the loader so raised handler failures are translated centrally at the native MCP boundary.

## Validation

- Passed focused TDD validation:
  - `bundle exec ruby -Itest test/runtime/tool_response_test.rb`
  - `bundle exec ruby -Itest test/runtime/native/mcp_runtime_loader_test.rb`
  - `bundle exec ruby -Itest test/semantic/semantic_commands_test.rb`
  - `bundle exec ruby -Itest test/semantic/hierarchy_maintenance_commands_test.rb`
- Passed broader validation:
  - `bundle exec rake ruby:test`
  - `bundle exec rake ruby:lint`
  - `bundle exec rake package:verify`
- Completed external codereview with `grok-code`; the only useful follow-up was preserving original backtraces when the loader translates raised handler failures.
- Existing vendored native transport contract tests under [test/runtime/native/mcp_runtime_native_contract_test.rb](../../../../test/runtime/native/mcp_runtime_native_contract_test.rb) still skip in this checkout because the staged native vendor runtime is not present locally.

## Docs And Metadata

- Updated [task.md](./task.md) status and implementation notes to reflect shipped work.
- Updated [plan.md](./plan.md) with implementation outcomes and the local validation posture.
- Added this `summary.md`.
- Updated current source-of-truth docs with the shared native response conventions and the `escape_hatch` posture for `eval_ruby`.

## Remaining Manual Verification

- Install the packaged RBZ in SketchUp and confirm representative first-class tools still return the expected structured result envelopes in-host.
- Confirm invalid known-option refusals still expose `refusal.details.allowedValues` in a live SketchUp session.
- Confirm raised runtime failures surface on the MCP error path in the live native runtime when the staged vendor runtime is present.
