# Summary: PLAT-17 Harmonize Residual Public MCP Contract Conventions

## What Shipped

- Removed the legacy public `boolean_operation` surface from the native tool catalog, dispatcher, facade expectations, command factory assembly, native contract fixtures, user-facing docs, and dedicated modeling implementation/tests.
- Updated [McpRuntimeLoader](../../../../src/su_mcp/runtime/native/mcp_runtime_loader.rb) so `get_entity_info`, `transform_entities`, and `set_material` now expose canonical `targetReference` request contracts instead of top-level direct-reference aliases such as `id`, `target_id`, or `tool_id`.
- Updated [SceneQueryCommands](../../../../src/su_mcp/scene_query/scene_query_commands.rb), [TargetReferenceResolver](../../../../src/su_mcp/scene_query/target_reference_resolver.rb), and [MutationTargetResolver](../../../../src/su_mcp/editing/mutation_target_resolver.rb) so caller-correctable selector failures return structured refusal payloads for missing targets, unsupported request fields, unresolved references, ambiguous references, and unsupported mutation target types.
- Added direct lookup helpers in [ModelAdapter](../../../../src/su_mcp/adapters/model_adapter.rb) and resolver tests so `entityId` and `persistentId` use native model lookup paths while metadata-backed `sourceElementId` remains traversal-backed.
- Normalized touched scene-query public response vocabulary in [SceneQuerySerializer](../../../../src/su_mcp/scene_query/scene_query_serializer.rb) and [SceneQueryCommands](../../../../src/su_mcp/scene_query/scene_query_commands.rb), including `persistentId`, `entityId`, `definitionName`, `childrenCount`, `activePathDepth`, `topLevelEntities`, `selectedEntities`, and `byType`.
- Converted scene-query public geometry outputs, including bounds and instance origins, to meters at the MCP boundary and updated [Semantic::Serializer](../../../../src/su_mcp/semantic/serializer.rb) to avoid double-converting bounds already emitted in public units.
- Added checked-in public contract sweep evidence in [public_mcp_contract_sweep.json](../../../../test/support/public_mcp_contract_sweep.json) and posture tests in [public_mcp_contract_posture_test.rb](../../../../test/runtime/public_mcp_contract_posture_test.rb).
- Updated [docs/mcp-tool-reference.md](../../../../docs/mcp-tool-reference.md) so the public tool inventory, direct-reference policy, mutation helper behavior, `get_entity_info` selector contract, and meter-unit guidance match the runtime surface.

## Validation

- Initial failing skeleton baseline was created and confirmed before implementation.
- Focused PLAT-17 subset passed before final review:
  - `bundle exec ruby -Itest -e 'ARGV.each { |path| load path }' test/scene_query/target_reference_resolver_test.rb test/scene_query/scene_query_commands_test.rb test/editing/editing_commands_test.rb test/runtime/native/mcp_runtime_loader_test.rb test/runtime/tool_dispatcher_test.rb test/runtime/native/mcp_runtime_facade_test.rb test/runtime/runtime_command_factory_test.rb test/runtime/public_mcp_contract_posture_test.rb test/semantic/semantic_serializer_test.rb test/runtime/native/mcp_runtime_native_contract_test.rb`
  - Result: 165 runs, 688 assertions, 0 failures, 31 skips.
- Full pre-review validation passed:
  - `bundle exec rake ruby:test`: 789 runs, 3963 assertions, 0 failures, 35 skips.
  - `bundle exec rake ruby:lint`: 202 files inspected, no offenses.
  - `bundle exec rake package:verify`: produced `dist/su_mcp-0.26.0.rbz`.
  - `bundle exec rake ci`: lint, tests, and package verification passed.
  - JSON fixture parse check passed for `native_runtime_contract_cases.json` and `public_mcp_contract_sweep.json`.
- Post-code-review follow-up validation passed:
  - `bundle exec ruby -Itest -e 'ARGV.each { |path| load path }' test/runtime/public_mcp_contract_posture_test.rb test/scene_query/target_reference_resolver_test.rb test/editing/editing_commands_test.rb`
  - Result: 31 runs, 140 assertions, 0 failures, 0 skips.
  - `bundle exec rubocop --cache false src/su_mcp/editing/mutation_target_resolver.rb src/su_mcp/scene_query/target_reference_resolver.rb test/runtime/public_mcp_contract_posture_test.rb`: 3 files inspected, no offenses.
- Final Step 10 integration validation passed:
  - `bundle exec rake ci`
  - Result after the response identity cleanup: 202 files inspected with no RuboCop offenses; 790 runs, 3990 assertions, 0 failures, 35 skips; package verification produced `dist/su_mcp-0.26.0.rbz`.

## Code Review

- Completed the required PAL code review with `mcp__pal__codereview` using `model: "grok-4.20"`.
- Confirmed no critical or high-severity findings.
- Addressed accepted findings:
  - Updated the stale `MutationTargetResolver` class comment so it no longer describes the removed additive `id` or `targetReference` contract.
  - Added an explicit source-tree absence assertion for removed `boolean_operation`, `SolidModelingCommands`, and `ModelingSupport` implementation symbols.
  - Added an inline resolver comment documenting why native SketchUp identifiers must stay on model-owned lookup paths instead of recursive traversal.
- Addressed the follow-up identity cleanup after external MCP validation:
  - Removed the parallel SketchUp entity `id` alias from scene-query entity summaries and mutation success payloads.
  - Mutation success payloads now return `entityId` and `persistentId` rather than top-level `id`.
- Dispositioned one broader serializer-sharing suggestion as follow-up scope:
  - `Semantic::Serializer` still owns its default `SceneQuerySerializer` instance. The PLAT-17 bug risk was covered by the no-double-conversion test; threading one shared serializer instance through command construction would be a broader dependency-injection cleanup rather than a required contract fix for this task.

## Contract Alignment

- Runtime schemas, dispatcher routing, command factory assembly, command validation, structured refusals, native fixtures, docs, and contract posture tests were re-checked for the changed public surfaces.
- `boolean_operation` is absent from first-class runtime inventory and public docs, and source-level assertions prevent the removed implementation seam from returning unnoticed.
- `get_entity_info`, `transform_entities`, and `set_material` now advertise and validate `targetReference` consistently.
- Unsupported legacy top-level selector fields return `unsupported_request_field` refusals when they reach runtime command validation.
- Missing direct references return `missing_target`; unresolved or ambiguous direct references are refused through structured payloads rather than raw runtime exceptions on the touched paths.
- Public geometry-bearing scene-query responses are documented and tested as meters.
- Public SketchUp entity identity responses now use `entityId` and, when available, `persistentId`; scene-query entity summaries and generic mutation success payloads no longer expose a parallel top-level `id` alias for SketchUp `entityID`.
- The finite option-set discoverability question is not materially expanded by this task after deleting `boolean_operation`; no new finite enum set was introduced.

## Hosted SketchUp Verification

- External MCP-client scenario validation was completed after code review.
- Passed scenarios confirmed:
  - `tools/list` no longer advertises `boolean_operation`, while `get_entity_info`, `transform_entities`, and `set_material` remain present.
  - Calling removed `boolean_operation` fails as tool-not-found.
  - `get_entity_info`, `transform_entities`, and `set_material` schemas require `targetReference` and do not advertise top-level `id`.
  - `get_entity_info` resolves by `sourceElementId`, `persistentId`, and compatibility `entityId`.
  - `targetReference.legacyId` returns structured `unsupported_request_field` with `field: "targetReference.legacyId"`.
  - `get_scene_info` uses `activePathDepth`, `topLevelEntities`, `selectedEntities`, and `byType`.
  - Component summaries use `entityId`, `persistentId`, `definitionName`, and `childrenCount`, with no snake_case equivalents observed.
  - Bounds and origins are emitted in public meters.
  - `transform_entities` moved a target by exactly `+1 m` for `position: [1.0, 0.0, 0.0]`.
  - `set_material` applied `Walnut` and follow-up inspection confirmed the material.
  - `delete_entities` still works with `targetReference.entityId`.
  - `find_entities` still uses predicate `targetSelector.identity.entityId`.
  - Raw JSON-RPC `structuredContent` matches the canonical/camelCase `get_entity_info` shape.
- External validation caveats:
  - Exact legacy-only or missing-target payloads such as `{ "id": "..." }` and `{}` are rejected by MCP schema/RPC validation before command-level structured refusals run. This is acceptable for PLAT-17 because schemas intentionally publish the canonical required shape and the plan allows legacy shapes to be rejected by wrapper/schema validation as long as they do not execute as compatibility behavior. Canonical malformed objects such as `{ "targetReference": {} }` still return structured `missing_target`.
- Follow-up code changes after this validation removed the reported response `id` caveat. Re-run the external matrix once more if live MCP confirmation of the cleaned identity payloads is required before handoff.

## Docs And Metadata

- Updated [docs/mcp-tool-reference.md](../../../../docs/mcp-tool-reference.md) for the changed public inventory, selector posture, and unit semantics.
- Updated [task.md](./task.md) status to `completed`.
- Added this `summary.md`.
- Completed Step 11 task-estimation calibration in [size.md](./size.md).

## Remaining Gaps

- Re-run the external MCP scenario matrix if live confirmation of the final no-`id` response payloads is required before release.
