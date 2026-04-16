# PLAT-07 Implementation Summary

## What Shipped

- Added a local-developer Ruby-native MCP spike path under `src/su_mcp/`:
  - [McpSpikeConfig](./../../../src/su_mcp/mcp_spike_config.rb)
  - [McpSpikeFacade](./../../../src/su_mcp/mcp_spike_facade.rb)
  - [McpSpikeRuntimeLoader](./../../../src/su_mcp/mcp_spike_runtime_loader.rb)
  - [McpSpikeHttpBackend](./../../../src/su_mcp/mcp_spike_http_backend.rb)
  - [McpSpikeServer](./../../../src/su_mcp/mcp_spike_server.rb)
- Wired explicit SketchUp menu actions into [Main](./../../../src/su_mcp/main.rb) for:
  - spike status
  - start
  - restart
  - stop
- Kept the existing Python bridge and TCP socket path intact.
- Exposed the planned spike slice only:
  - `ping`
  - `get_scene_info`
- Reused the existing Ruby-owned [SceneQueryCommands](./../../../src/su_mcp/scene_query_commands.rb) path for `get_scene_info` instead of inventing a new scene-query response shape.
- Kept MCP semantics in the vendored Ruby SDK server, but replaced the SDK's stateless HTTP transport edge with a thin stateless Rack app so the spike can safely accept both single and batched JSON-RPC POST bodies from editor clients.

## Validated Surface

- Exposed MCP surface validated in the real SketchUp-hosted environment:
  - `ping`
  - `get_scene_info`
- External Codex-connected MCP validation passed for both tools.
- `get_scene_info` returned real active-model data from SketchUp 2026, including:
  - model title and path
  - scene counts
  - serialized top-level entities
- Parameter behavior validated for `entity_limit`:
  - positive limits behaved correctly
  - `0` and negative values were coerced to `1`
  - this behavior is inherited from the existing Ruby-owned `SceneQueryCommands#limit_from` path, not introduced by the spike

## Vendoring Posture

- Used a local unpacked vendoring posture for the spike under `vendor/ruby/`.
- Validated the official Ruby MCP SDK with:
  - `mcp-0.13.0`
  - `json-schema-6.2.0`
  - `rack-3.2.6`
- The spike currently tolerates top-level `MCP::*` exposure inside the local developer runtime.
- The vendored runtime loader also has to shim `Gem.loaded_specs['json-schema']` for the unpacked spike layout.
- Result:
  - acceptable for a local spike
  - not yet the production-safe packaging or namespace-isolation answer

## Validation

- `bundle exec rake ruby:test`
- `bundle exec rake ruby:lint`
- `bundle exec rake package:verify`
- Local real-socket smoke:
  - started the new HTTP listener on a local TCP port
  - exercised `initialize`
  - exercised `ping`
  - confirmed a structured JSON response over the real HTTP path
- Added focused spike coverage for:
  - lowercase `content-length` headers
  - chunked POST bodies
  - batched `notifications/initialized` + `tools/list` requests
- SketchUp-hosted acceptance proof passed:
  - SketchUp 2026 loaded and started the spike successfully
  - the spike was reachable from WSL after aligning the bind host with the existing Ruby bridge posture
  - an external Codex-connected MCP client exercised `ping` and `get_scene_info` successfully against the live SketchUp host

All of the above passed locally.

## Installable Artifact

- Built a staged local RBZ for SketchUp installation:
  - `dist/su_mcp-0.8.2-spike.rbz`
- This artifact injects the local unpacked vendored gems under `su_mcp/vendor/ruby` at package-build time.
- The staged RBZ is for local spike validation only and does not change the normal repo packaging contract.

## Spike Packaging Procedure

- The spike RBZ was built manually from a temporary staging tree rather than from a repo-owned packaging task.
- Staging layout used for the working spike artifact:
  - copy `src/su_mcp.rb` to the stage root as `su_mcp.rb`
  - copy `src/su_mcp/.` into the stage as `su_mcp/`
  - copy the locally unpacked vendored runtime into `su_mcp/vendor/ruby/`
- Archive shape required for a valid installable spike:
  - `su_mcp.rb`
  - `su_mcp/extension.json`
  - `su_mcp/main.rb`
  - `su_mcp/vendor/ruby/...`
- The working manual assembly sequence was:
  - create a temporary stage directory
  - populate the stage with the layout above
  - zip `su_mcp` plus `su_mcp.rb` from the stage root into `dist/su_mcp-0.8.2-spike.rbz`
- Important failure learned during the spike:
  - copying `src/su_mcp` as a nested directory produced `su_mcp/su_mcp/...`, which broke extension loading because SketchUp expects `su_mcp/extension.json`
- This procedure is documented only to preserve the spike method.
  - follow-on work should replace it with a repo-owned packaging task and CI archive-shape verification

## Outcome

- Result: `conditional-go`
- Why:
  - the repo can host a real Ruby-native MCP transport path inside SketchUp without the Python adapter in the serving path
  - the tested local-developer surface is functionally healthy for the spike scope
  - the main remaining problems are packaging and automation, not basic runtime viability
  - the spike exposed concrete packaging friction instead of hiding it:
    - unpacked vendored gems require explicit load-path handling
    - the SDK assumes gem-spec metadata for `json-schema`
    - a direct stateless SDK transport edge was not sufficient for editor-client compatibility, so the spike needed a thin HTTP wrapper
    - manual RBZ staging is error-prone and regressed archive layout during the spike
    - production-safe namespace isolation is still unresolved
- Judgment:
  - `go` for follow-on platform work to formalize packaging and CI around the Ruby-native path
  - `no-go` for replacing the supported Python path yet
  - keep Python as the supported adapter until vendoring, packaging, and validation automation are made repo-native

## Docs And Metadata

- Updated [task.md](./task.md) status to `completed`
- Updated [plan.md](./plan.md) with the implemented seams, validations, and remaining gap
- Added this `summary.md`
- No `README.md` change was made because this spike is still a local-developer-only path rather than a supported public workflow
- The shared Python/Ruby bridge contract did not change, so no contract artifact or contract-suite update was required

## Remaining Gaps

- The current vendoring posture should not be treated as release-ready:
  - `vendor/ruby/` is suitable for the spike only
  - long-term staging and namespace isolation still need a follow-on packaging decision
- CI and packaging work are still required before this can become a supported repo path:
  - add a dedicated staged packaging task for the Ruby-native spike or successor runtime
  - add archive-shape verification so required files like `su_mcp/extension.json` and vendored runtime payloads are asserted automatically
  - make vendored runtime staging deterministic in build automation rather than manual shell assembly
  - decide how normal RBZ packaging and any Ruby-native staged packaging coexist in CI and release workflows
  - decide whether the Ruby MCP runtime remains spike-only vendored code, staged build output, or a namespaced repo-managed runtime tree

## CI And Packaging Requirements

- A follow-on implementation should add a repo-owned packaging task for the Ruby-native artifact instead of relying on manual staging.
- CI should validate both:
  - the normal package task output
  - the staged Ruby-native archive shape when that path is enabled
- CI archive checks should assert at minimum:
  - `su_mcp.rb`
  - `su_mcp/extension.json`
  - `su_mcp/main.rb`
  - required vendored runtime directories under `su_mcp/vendor/ruby/`
- CI does not need SketchUp-hosted execution for this spike outcome, but it does need deterministic package-shape checks and Ruby-side validation so packaging regressions are caught before manual install.
