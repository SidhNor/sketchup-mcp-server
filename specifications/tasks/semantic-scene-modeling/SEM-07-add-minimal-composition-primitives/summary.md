# Summary: SEM-07 Add Limited Hierarchy Maintenance Primitives

## What Shipped

- Added two new public native MCP tools:
  - `create_group`
  - `reparent_entities`
- Implemented Ruby-owned hierarchy maintenance in:
  - [HierarchyMaintenanceCommands](../../../../src/su_mcp/semantic/hierarchy_maintenance_commands.rb)
  - [EntityRelocator](../../../../src/su_mcp/semantic/entity_relocator.rb)
  - [HierarchyEntitySerializer](../../../../src/su_mcp/semantic/hierarchy_entity_serializer.rb)
- Wired the new hierarchy command target through:
  - [McpRuntimeLoader](../../../../src/su_mcp/runtime/native/mcp_runtime_loader.rb)
  - [ToolDispatcher](../../../../src/su_mcp/runtime/tool_dispatcher.rb)
  - [RuntimeCommandFactory](../../../../src/su_mcp/runtime/runtime_command_factory.rb)
- Added representative native contract cases for successful `create_group` responses and refused `reparent_entities` responses.
- Kept the hierarchy-maintenance surface intentionally narrow:
  - compact target references only
  - supported child types limited to groups and component instances
  - no duplicate, replace, edit-context, or broad hierarchy-query behavior

## Validation

- `bundle exec ruby -Itest -e 'load "test/runtime/native/mcp_runtime_loader_test.rb"; load "test/runtime/tool_dispatcher_test.rb"; load "test/runtime/native/mcp_runtime_native_contract_test.rb"; load "test/runtime/native/mcp_runtime_facade_test.rb"; load "test/semantic/hierarchy_entity_serializer_test.rb"; load "test/semantic/entity_relocator_test.rb"; load "test/semantic/hierarchy_maintenance_commands_test.rb"'`

## Docs And Metadata

- Updated [README.md](../../../../README.md) to include the new hierarchy-maintenance tools in the live MCP surface.
- Updated [task.md](./task.md) status to `completed`.
- Refined [plan.md](./plan.md) to capture the runtime factory or facade integration coverage that landed.

## Manual Verification Still Needed

- Real SketchUp-hosted smoke validation is still recommended for:
  - grouping an existing managed child into a new container
  - reparenting a managed child under an existing target group
  - confirming returned identifiers and retained metadata after relocation in the hosted runtime

## Notes

- Current relocation support preserves managed metadata and wrapper presentation fields while returning fresh post-operation runtime identifiers from the recreated wrapper instances.
