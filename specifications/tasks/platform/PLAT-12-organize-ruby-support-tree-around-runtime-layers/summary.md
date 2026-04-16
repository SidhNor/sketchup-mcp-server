# Summary: PLAT-12 Organize Ruby Support Tree Around Runtime Layers
**Task ID**: `PLAT-12`
**Status**: `completed`
**Date**: `2026-04-16`

## Shipped

- Reorganized the Ruby support tree into explicit runtime and capability subtrees:
  - `src/su_mcp/transport/`
  - `src/su_mcp/runtime/`
  - `src/su_mcp/runtime/native/`
  - `src/su_mcp/scene_query/`
  - `src/su_mcp/editing/`
  - `src/su_mcp/modeling/`
  - `src/su_mcp/developer/`
  - `src/su_mcp/semantic/`
- Kept the root entrypoints stable:
  - `src/su_mcp.rb`
  - `src/su_mcp/main.rb`
  - `src/su_mcp/extension.rb`
  - `src/su_mcp/extension.json`
  - `src/su_mcp/version.rb`
- Moved app-owned tests to mirrored subtrees under `test/` where practical, while leaving `test/contracts/`, `test/support/`, and packaging-task tests in place.
- Updated staged native-package verification to load `runtime/native/mcp_runtime_loader.rb` from the packaged support tree.
- Updated `.rubocop.yml` so the staged native loader’s intentional vendored gem load-path handling remains excluded at its new path.

## Validation

- `bundle exec rake ruby:test`
- `bundle exec rake ruby:lint`
- `bundle exec rake ruby:contract`
- `uv run pytest python/tests/contracts`
- `bundle exec rake package:verify:all`

## Notes

- The implementation stayed structural: file moves, mirrored test moves, `require_relative` rewiring, and packaging-path alignment.
- No public tool names, Ruby constants, bridge payload shapes, or Python tool contracts changed.
- The plan’s `joinery_commands.rb` references were stale at implementation time; no joinery file existed in the repo, so the modeling move covered the existing `modeling_support.rb` and `solid_modeling_commands.rb` files only.
- No user-facing documentation updates were needed because the exposed MCP surface and setup workflow did not change.

## Remaining Gap

- SketchUp-hosted smoke verification of extension load, bridge status, and native-runtime status still needs to be run manually outside this environment.
