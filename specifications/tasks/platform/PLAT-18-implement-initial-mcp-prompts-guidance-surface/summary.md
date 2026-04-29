# Summary: PLAT-18 Implement Initial MCP Prompts Guidance Surface

**Task ID**: `PLAT-18`
**Status**: `completed`
**Date**: `2026-04-29`

## Shipped Contract Behavior

- Added a native runtime MCP prompt catalog with exactly two static no-argument prompts:
  - `managed_terrain_edit_workflow`
  - `terrain_profile_qa_workflow`
- Wired the prompt catalog into `McpRuntimeLoader` through the packaged Ruby MCP SDK prompt path.
- `prompts/list` now exposes both prompt definitions.
- `prompts/get` returns text-only `user` prompt messages with result descriptions.
- Existing tool catalog behavior remains unchanged; no public tool names, tool schemas, dispatcher routes, command behavior, terrain solvers, SketchUp adapters, or tool response shapes changed.
- Prompt text stays workflow guidance and does not move baseline-safe tool semantics out of `tools/list`.
- Prompt wording was updated after MTA-16 planning review to mention `planar_region_fit` as the explicit coherent-plane terrain intent while keeping `survey_point_constraint` distinct as bounded smooth adjustment.

## Implementation Boundary

- Runtime prompt content lives in `src/su_mcp/runtime/native/prompt_catalog.rb`.
- Runtime assembly remains in `src/su_mcp/runtime/native/mcp_runtime_loader.rb`.
- Prompt handling uses `MCP::Prompt.define`, `MCP::Prompt::Result`, `MCP::Prompt::Message`, and `MCP::Content::Text`.
- SDK-owned prompt errors remain SDK-owned; no custom prompt dispatcher, command guard, or refusal envelope was added.

## Documentation

- Updated `docs/mcp-tool-reference.md` to list the two prompts and explain that prompts are workflow guidance, not required hidden context.
- The docs intentionally do not duplicate full prompt bodies.
- README was not updated because the prompt surface is documented in the MCP tool reference and README does not currently enumerate MCP prompts.

## Validation Evidence

- `bundle exec ruby -Itest test/runtime/native/prompt_catalog_test.rb`
  - 4 runs, 39 assertions, 0 failures, 0 errors, 0 skips.
- `bundle exec ruby -Itest test/runtime/native/mcp_runtime_loader_test.rb`
  - 50 runs, 400 assertions, 0 failures, 0 errors, 8 skips.
- `bundle exec ruby -Itest test/runtime/public_mcp_contract_posture_test.rb`
  - 6 runs, 48 assertions, 0 failures, 0 errors, 0 skips.
- SDK-backed staged-runtime smoke using `tmp/package/ruby_native/vendor/ruby`
  - verified `prompts/list` returned `managed_terrain_edit_workflow` and `terrain_profile_qa_workflow`
  - verified `prompts/get` returned a text-only `user` message for `managed_terrain_edit_workflow`
- `bundle exec rake ruby:test`
  - 800 runs, 4055 assertions, 0 failures, 0 errors, 37 skips.
- `bundle exec rake ruby:lint`
  - 204 files inspected, no offenses detected.
- `bundle exec rake package:verify`
  - produced `dist/su_mcp-1.0.0.rbz`.
- `git diff --check`
  - clean.
- Post-closeout MTA-16-aware wording refresh:
  - `bundle exec ruby -Itest test/runtime/native/prompt_catalog_test.rb`
    - 4 runs, 39 assertions, 0 failures, 0 errors, 0 skips.
  - `bundle exec ruby -Itest test/runtime/native/mcp_runtime_loader_test.rb`
    - 50 runs, 400 assertions, 0 failures, 0 errors, 8 skips.
  - `bundle exec rubocop --cache false src/su_mcp/runtime/native/prompt_catalog.rb test/runtime/native/prompt_catalog_test.rb`
    - 2 files inspected, no offenses detected.
  - `git diff --check`
    - clean.

## Code Review

- Final Step 10 `mcp__pal__codereview` completed with `model: "grok-4.20"`.
- No critical, high, medium, or low findings were reported.
- The expert review confirmed the prompt surface is isolated, SDK-backed, test-covered, and aligned with the guidance-only contract boundary.
- A later wording consensus with `gpt-5.4`, `grok-4.20`, and `grok-4` reviewed the prompt text against MTA-16 planning context and recommended small wording updates. Those updates were applied.

## Live SketchUp Verification Status

Live or hosted SketchUp verification was not run and is not required for this task.

Reason: PLAT-18 adds static MCP prompt discovery/retrieval through the native runtime. It does not change SketchUp API usage, scene mutation behavior, terrain solvers, geometry output, persistence, undo behavior, or runtime menu/server lifecycle behavior.

## Contract Alignment Review

- Runtime prompt registration, prompt retrieval, focused tests, SDK-backed smoke, and docs are aligned.
- Tool schemas and provider-compatible input schema rules are unchanged.
- Tool refusal/error payload behavior is unchanged.
- Unknown prompt and malformed prompt protocol errors remain the SDK responsibility.
- The only new finite public set is the prompt name set; it is discoverable through `prompts/list` before use.
- The prompt text references `planar_region_fit` as workflow guidance only. The actual public tool schema and behavior remain owned by MTA-16.

## Remaining Gaps

- Normal test runs still skip SDK-backed transport tests when `test/runtime/vendor/ruby` is absent. The required protocol proof was run against the available staged package vendor runtime under `tmp/package/ruby_native/vendor/ruby`.
- No SketchUp-hosted smoke was run because the changed surface is static prompt protocol behavior, not host-sensitive scene behavior.
