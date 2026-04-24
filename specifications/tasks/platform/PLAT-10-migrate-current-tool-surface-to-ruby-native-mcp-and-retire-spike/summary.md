# PLAT-10 Implementation Summary

## What Shipped

- Added a Ruby-owned canonical native tool catalog in [mcp_runtime_loader.rb](./../../../src/su_mcp/mcp_runtime_loader.rb) for the migrated public surface:
  - `ping`
  - `get_scene_info`
  - `list_entities`
  - `find_entities`
  - `sample_surface_z`
  - `get_entity_info`
  - `create_site_element`
  - `set_entity_metadata`
  - `create_component`
  - `delete_component`
  - `transform_component`
  - `get_selection`
  - `set_material`
  - `export_scene`
  - `boolean_operation`
  - `chamfer_edges`
  - `fillet_edges`
  - `eval_ruby`
- Kept `bridge_configuration` out of the canonical native catalog so Python remains compatibility-only for that tool.
- Expanded [mcp_runtime_facade.rb](./../../../src/su_mcp/mcp_runtime_facade.rb) to dispatch migrated tool calls through [tool_dispatcher.rb](./../../../src/su_mcp/tool_dispatcher.rb) instead of remaining a narrow two-tool spike remnant.
- Added [runtime_command_factory.rb](./../../../src/su_mcp/runtime_command_factory.rb) so the native runtime and legacy socket path share Ruby command collaborator construction.
- Added [developer_commands.rb](./../../../src/su_mcp/developer_commands.rb) and moved shared `eval_ruby` behavior out of [socket_server.rb](./../../../src/su_mcp/socket_server.rb).
- Updated [mcp_runtime_server.rb](./../../../src/su_mcp/mcp_runtime_server.rb) so native handler wiring is catalog-driven rather than hardcoded to `ping` plus `get_scene_info`.
- Promoted SketchUp menu and status wording in [main.rb](./../../../src/su_mcp/main.rb) from `Experimental MCP Runtime` to `Native MCP Runtime`.
- Updated [python/src/sketchup_mcp_server/app.py](./../../../python/src/sketchup_mcp_server/app.py) and [README.md](./../../../README.md) to describe the Python FastMCP process as a compatibility surface.

## Validation

- Passed focused Ruby runtime and integration-adjacent tests:
  - `bundle exec ruby -Itest test/mcp_runtime_loader_test.rb`
  - `bundle exec ruby -Itest test/mcp_runtime_facade_test.rb`
  - `bundle exec ruby -Itest test/mcp_runtime_server_test.rb`
  - `bundle exec ruby -Itest test/socket_server_test.rb`
  - `bundle exec ruby -Itest test/socket_server_adapter_test.rb`
  - `bundle exec ruby -Itest test/mcp_runtime_main_integration_test.rb`
- Passed focused Python compatibility validation:
  - `uv run pytest python/tests/test_app.py`
- Passed broader repo validation for the changed surface:
  - `bundle exec rake ruby:lint`
  - `bundle exec rake ruby:test`
  - `bundle exec rake python:lint`
  - `bundle exec rake python:test`
  - `bundle exec rake package:verify:all`
- Live SketchUp-hosted validation confirmed the native runtime starts cleanly, the extension remains stable, and the scene remained recoverable after disposable geometry cleanup.
- Live SketchUp-hosted validation confirmed these tools working end to end on the native runtime:
  - `ping`
  - `get_scene_info`
  - `list_entities`
  - `find_entities`
  - `get_selection`
  - `get_entity_info`
  - `sample_surface_z`
  - `create_component`
  - `create_site_element`
  - `transform_component`
  - `set_material`
  - `set_entity_metadata`
  - `delete_component`
  - `eval_ruby`
  - `export_scene`
  - `boolean_operation`
- Live contract notes confirmed during native-host validation:
  - `get_entity_info` works with `id`
  - `sample_surface_z` works with `target` plus canonical `sampling`
  - `create_component` works with numeric vectors and `type: "cube"`
  - `create_site_element` works with the live semantic contract using fields such as `sourceElementId`, `status`, `footprint`, `thickness`, and `tag`
  - `transform_component` worked with `position`
  - `set_entity_metadata` worked with `target` plus `set`
- Live revalidation later confirmed `boolean_operation` working end to end on a real union call, including deletion of the source solids, creation of an `OuterShell` replacement solid, and the expected merged bounds/topology changes.
- Later live revalidation confirmed both `fillet_edges` and `chamfer_edges` now complete invocation and generate additional geometry without raising runtime errors.
- Live inspection after that revalidation also showed the generated edge-treatment output is still not functionally correct:
  - `fillet_edges` produces additional geometry, but the result is non-manifold
  - `chamfer_edges` produces additional geometry, but the result is non-manifold
- A follow-up local fix was then implemented in [modeling_support.rb](./../../../src/su_mcp/modeling_support.rb) and [solid_modeling_commands.rb](./../../../src/su_mcp/solid_modeling_commands.rb) to:
  - rebuild uncopiable edge and face geometry instead of assuming `copy`
  - perform boolean union on copied groups/components instead of `Sketchup::Entities`
  - tighten chamfer face-point construction around the two adjacent faces
  - snapshot chamfer face-point sets before any new chamfer faces are added so later edge processing does not pick up freshly-created geometry
- That follow-up fix passed focused and broader Ruby validation:
  - `bundle exec ruby -Itest test/modeling_support_test.rb`
  - `bundle exec ruby -Itest test/solid_modeling_commands_test.rb`
  - `bundle exec rake ruby:test`
  - `bundle exec rake ruby:lint`

## Docs And Metadata

- Updated [task.md](./task.md) status to `completed`
- Added implementation and validation notes to [task.md](./task.md)
- Added this `summary.md`
- Updated [README.md](./../../../README.md) for the canonical native-runtime posture and Python compatibility wording
- No bridge-contract artifact or contract-suite update was required because the public Python-to-Ruby socket bridge contract shape did not change

## Remaining Gaps

- Python remains present as a compatibility runtime in this repo; this task narrows its posture but does not remove it.
- The stronger Python catalog-derivation or parity-enforcement work described as one possible migration direction was not implemented here because Python is expected to be removed before new tool growth resumes.
- The inherited joinery tools `create_mortise_tenon`, `create_dovetail`, and `create_finger_joint` were removed from both the native Ruby catalog and the Python compatibility surface because they were never used and were not part of the validated tool surface.
- The remaining live defect cluster is no longer an MCP exposure problem. It is narrowed to shared Ruby geometry correctness in `fillet_edges` and `chamfer_edges`, which now execute but still produce non-manifold results in-host.

## Manual Verification

- Completed in a live SketchUp host for the validated tool set above.
- Still open only for functional follow-up on `fillet_edges` and `chamfer_edges`, whose current live outputs are non-manifold despite successful invocation.
