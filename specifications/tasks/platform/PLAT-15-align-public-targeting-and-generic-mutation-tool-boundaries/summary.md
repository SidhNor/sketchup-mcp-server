# Summary: PLAT-15 Align Public Targeting And Generic Mutation Tool Boundaries

## What Shipped

- Updated [McpRuntimeLoader](../../../../src/su_mcp/runtime/native/mcp_runtime_loader.rb) so the native catalog now teaches:
  - `list_entities` as scoped inventory with required `scopeSelector`
  - `find_entities` as predicate-first targeting with required `targetSelector`
  - `delete_entities` instead of `delete_component`
- Added [scope_resolver.rb](../../../../src/su_mcp/scene_query/scope_resolver.rb) so scoped inventory is resolved explicitly within the scene-query slice.
- Added [target_reference_resolver.rb](../../../../src/su_mcp/scene_query/target_reference_resolver.rb) and migrated semantic callers to it, so direct-reference lookup now lives under targeting ownership instead of the semantic slice.
- Updated [targeting_query.rb](../../../../src/su_mcp/scene_query/targeting_query.rb), [scene_query_commands.rb](../../../../src/su_mcp/scene_query/scene_query_commands.rb), and [scene_query_serializer.rb](../../../../src/su_mcp/scene_query/scene_query_serializer.rb) so `find_entities` now supports exact-match identity, attributes, and bounded metadata predicates while preserving compact resolution-state output.
- Replaced component-only deletion in [editing_commands.rb](../../../../src/su_mcp/editing/editing_commands.rb) with structured `delete_entities` behavior that returns `operation` plus `affectedEntities.deleted` and refuses unresolved, ambiguous, or unsupported targets explicitly.
- Updated runtime wiring and contract coverage in:
  - [tool_dispatcher.rb](../../../../src/su_mcp/runtime/tool_dispatcher.rb)
  - [mcp_runtime_facade_test.rb](../../../../test/runtime/native/mcp_runtime_facade_test.rb)
  - [mcp_runtime_loader_test.rb](../../../../test/runtime/native/mcp_runtime_loader_test.rb)
  - [mcp_runtime_native_contract_test.rb](../../../../test/runtime/native/mcp_runtime_native_contract_test.rb)
  - [native_runtime_contract_cases.json](../../../../test/support/native_runtime_contract_cases.json)

## Validation

- Passed focused TDD validation on the PLAT-15 surface, including loader, dispatcher, facade, scene-query, resolver, editing, semantic, and native contract tests.
- Passed final repo validation:
  - `bundle exec rake ruby:test`
  - `bundle exec rake ruby:lint`
  - `bundle exec rake package:verify`
- Native transport tests that depend on the staged vendor runtime still skip when the staged vendor tree is unavailable locally; that behavior is unchanged.
- Live SketchUp MCP verification completed for the selector surface:
  - `list_entities` `scopeSelector` verified for `top_level`, `selection`, `children_of_target`, `includeHidden`, `limit`, and the planned explicit request-error paths
  - `find_entities` `targetSelector` verified for identity, attributes, and metadata predicates including `semanticType`, plus cross-section narrowing, `none`, `ambiguous`, and selector-validation failures

## Docs And Metadata

- Updated [README.md](../../../../README.md) with the current scoped inventory, predicate targeting, and generic deletion boundaries.
- Updated current source-of-truth docs so they no longer teach `delete_component` or the old `find_entities.query` posture.
- Updated [task.md](./task.md) status and implementation notes.
- Updated [plan.md](./plan.md) with the shipped seams and validation results.
- Added this `summary.md`.

## Remaining Manual Verification

- Verify `delete_entities` succeeds for supported groups and component instances in live SketchUp and refuses unsupported targets with the documented refusal payloads.
