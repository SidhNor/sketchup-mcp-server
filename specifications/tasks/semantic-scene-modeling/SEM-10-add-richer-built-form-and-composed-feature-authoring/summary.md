# Summary: SEM-10 Add Richer Built-Form and Composed Feature Authoring

## What Shipped

- Extended [HierarchyMaintenanceCommands](../../../../src/su_mcp/semantic/hierarchy_maintenance_commands.rb) so `create_group` can now create a managed container when `metadata.sourceElementId` and `metadata.status` are supplied.
- Managed-container creation now writes fixed managed metadata through [ManagedObjectMetadata](../../../../src/su_mcp/semantic/managed_object_metadata.rb):
  - `semanticType: "grouped_feature"`
  - `status`
  - `state: "Created"`
  - `schemaVersion: 1`
- Managed-container creation now applies optional wrapper-facing `sceneProperties.name` and `sceneProperties.tag` through [SceneProperties](../../../../src/su_mcp/semantic/scene_properties.rb).
- Extended [McpRuntimeLoader](../../../../src/su_mcp/runtime/native/mcp_runtime_loader.rb) so the public `create_group` schema additively supports:
  - `metadata.sourceElementId`
  - `metadata.status`
  - `sceneProperties.name`
  - `sceneProperties.tag`
- Kept the composition boundary narrow:
  - `create_group` creates the wrapper
  - `create_site_element` remains the atomic child-creation tool
  - `reparent_entities` remains the path for adding existing supported children later
- Finalized the host-correctness details needed for live SketchUp behavior:
  - empty managed containers are preserved until real children exist
  - relocation avoids host-sensitive collection-iteration assumptions
  - public inventory and child counts hide the internal placeholder entity
- Added or updated coverage for:
  - managed `create_group` success and refusal behavior
  - runtime schema and dispatcher passthrough
  - native contract response shape
  - scene-query targeting by `semanticType: "grouped_feature"`
  - parented child creation under a managed container

## Validation

- `bundle exec ruby -Itest -e 'load "test/semantic/hierarchy_maintenance_commands_test.rb"'`
- `bundle exec ruby -Itest -e 'load "test/semantic/hierarchy_maintenance_commands_test.rb"; load "test/semantic/semantic_commands_test.rb"'`
- `bundle exec ruby -Itest -e 'load "test/runtime/native/mcp_runtime_loader_test.rb"; load "test/runtime/tool_dispatcher_test.rb"; load "test/scene_query/find_entities_scene_query_commands_test.rb"; load "test/runtime/native/mcp_runtime_native_contract_test.rb"; load "test/semantic/semantic_commands_test.rb"'`
- `bundle exec ruby -Itest -e 'load "test/semantic/hierarchy_maintenance_commands_test.rb"; load "test/runtime/native/mcp_runtime_loader_test.rb"; load "test/runtime/tool_dispatcher_test.rb"; load "test/scene_query/find_entities_scene_query_commands_test.rb"; load "test/runtime/native/mcp_runtime_native_contract_test.rb"; load "test/semantic/semantic_commands_test.rb"'`
- `bundle exec rake ruby:test`
- `RUBOCOP_CACHE_ROOT=/tmp/rubocop-cache bundle exec rake ruby:lint`
- `bundle exec rake package:verify`
- Live SketchUp-hosted validation passed for:
  - simple managed `create_group`
  - `create_group` with existing-child relocation
  - positive `reparent_entities`
  - parented child creation under a managed container

## External Review

- `grok-4.20` codereview completed with no medium-or-higher issues.
- Reviewed surfaces included:
  - [hierarchy_maintenance_commands.rb](../../../../src/su_mcp/semantic/hierarchy_maintenance_commands.rb)
  - [mcp_runtime_loader.rb](../../../../src/su_mcp/runtime/native/mcp_runtime_loader.rb)
  - the changed test and contract files
  - [README.md](../../../../README.md)
  - [sketchup_mcp_guide.md](../../../../sketchup_mcp_guide.md)
- Main confirmed outcome: the delivered workflow stays additive and keeps multipart composition outside `create_site_element`.

## Docs And Metadata

- Updated [README.md](../../../../README.md) to describe `create_group` managed-container mode accurately.
- Updated [sketchup_mcp_guide.md](../../../../sketchup_mcp_guide.md) with `create_group` and `reparent_entities` examples for the supported multi-call composed-feature workflow.
- Updated [task.md](./task.md) status to `completed`.
- Updated [plan.md](./plan.md) with the shipped implementation outcome and final validation record.

## Final Hosted Outcome

- The managed `grouped_feature` workflow is now host-proven in SketchUp:
  - managed containers persist and remain targetable
  - child creation under `placement.parent` works
  - existing supported children can be relocated into the container
  - post-relocation children receive new runtime ids while preserving business identity through `sourceElementId`
