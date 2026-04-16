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
  - `create_mortise_tenon`
  - `create_dovetail`
  - `create_finger_joint`
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

## Docs And Metadata

- Updated [task.md](./task.md) status to `completed`
- Added implementation and validation notes to [task.md](./task.md)
- Added this `summary.md`
- Updated [README.md](./../../../README.md) for the canonical native-runtime posture and Python compatibility wording
- No bridge-contract artifact or contract-suite update was required because the public Python-to-Ruby socket bridge contract shape did not change

## Remaining Gaps

- The canonical native tool catalog is now Ruby-owned, but the local validation in this environment does not prove end-to-end native MCP behavior inside a live SketchUp host.
- Python remains present as a compatibility runtime in this repo; this task narrows its posture but does not remove it.
- The stronger Python catalog-derivation or parity-enforcement work described as one possible migration direction was not implemented here because Python is expected to be removed before new tool growth resumes.

## Manual Verification

- Still required in a live SketchUp host:
  - extension startup
  - native runtime startup
  - native `tools/list`
  - one representative scene tool
  - one representative semantic or modeling mutation tool
  - `eval_ruby`
  - one real MCP client exercising representative migrated tools on the native runtime
