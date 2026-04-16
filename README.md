# SketchUp MCP

This repository is set up as a dual-runtime project:

- A SketchUp Ruby extension lives under `src/`.
- A FastMCP Python server lives under `python/src/`.
- The Python MCP server talks to the SketchUp extension over a local socket bridge on port `9876` by default.

The Ruby side follows the shape of SketchUp's VS Code extension template: editor config, RuboCop and Solargraph setup, VS Code tasks, and a `src/`-based extension layout.

## Layout

```text
.
├── .vscode/
├── Gemfile
├── pyproject.toml
├── python/
│   └── src/sketchup_mcp_server/
└── src/
    ├── su_mcp.rb
    └── su_mcp/
```

## Ruby extension

Install Ruby tooling:

```bash
bundle install
```

The extension entrypoint is `src/su_mcp.rb`, which registers `src/su_mcp/main.rb` with SketchUp. On load, the extension starts the local SketchUp socket bridge and exposes menu actions for both the bridge and the native Ruby MCP runtime inside SketchUp.

For local development, load the extension from this repository by symlinking or copying the `src/` contents into SketchUp's `Plugins` directory.

Build a local RBZ package:

```bash
bundle exec rake package:rbz
```

This writes `dist/su_mcp-<version>.rbz`, where the version comes from `VERSION`.

## Python FastMCP server

Install the Python environment with `uv`:

```bash
uv sync --dev
```

The Python server is currently a compatibility surface while the Ruby-native runtime inside SketchUp is the canonical MCP host for the migrated tool surface.

Run the server over stdio:

```bash
uv run fastmcp run python/src/sketchup_mcp_server/server.py:mcp
```

Run the packaged console script:

```bash
uv run sketchup-mcp-server
```

The packaged server uses stdio by default, which is the expected mode for MCP clients that launch the server as a subprocess. That Python process then forwards tool calls to the SketchUp extension over the local TCP bridge.

Run the server over HTTP:

```bash
SKETCHUP_MCP_TRANSPORT=http uv run sketchup-mcp-server
```

When HTTP transport is enabled, the server uses `127.0.0.1:8000` by default
and exposes the MCP endpoint at `/mcp`.

By default, the SketchUp extension listens on `0.0.0.0:9876`. Override the bridge endpoint with:

```bash
SKETCHUP_HOST=127.0.0.1
SKETCHUP_PORT=9876
```

When the Python server runs under WSL, it will try to auto-detect the Windows host if `SKETCHUP_HOST` is not set.

## Current tool surface

The current cross-runtime tool surface includes scene inspection and targeting helpers such as:

- `get_scene_info`
- `list_entities`
- `get_entity_info`
- `find_entities`
- `sample_surface_z`
- `create_site_element`
- `set_entity_metadata`

`find_entities` resolves explicit targets through the supported MVP identifier and exact-match query paths. `sample_surface_z` samples explicit target geometry at one or more world-space XY points in meters and returns compact per-point `hit`, `miss`, or `ambiguous` outcomes. `create_site_element` is the semantic creation path and currently delivers the SEM-02 first-wave slice for `structure`, `pad`, `path`, `retaining_edge`, `planting_mass`, and `tree_proxy`, including structured refusal outcomes for unsupported types, missing payloads, contradictory payloads, invalid geometry, and invalid numeric values. `set_entity_metadata` is the semantic mutation path for existing managed objects. Current support is limited to `status` updates for managed objects and `structureCategory` updates for managed `structure` objects, with structured refusals for empty mutation requests, protected fields, required-field clears, unmanaged targets, and ambiguous or missing target references. Public geometric dimensions for `create_site_element` are interpreted and returned in meters, independent of the active SketchUp model unit display settings.

## Bridge contract coverage

Shared bridge contract coverage lives in `contracts/bridge/bridge_contract.json`.
It captures durable Python/Ruby boundary invariants and wave-owned tool cases without moving behavior ownership out of Ruby.

Any change that introduces or modifies a public bridge or tool contract should update in the same change:

- the shared contract artifact
- the Python contract suite under `python/tests/contracts/`
- the Ruby contract suite under `test/contracts/`

Run the contract suites directly with:

```bash
bundle exec rake ruby:contract
bundle exec rake python:contract
```

These checks also run in CI as a separate `contract` job so boundary regressions stay visible rather than blending into generic unit-test output.

## Local CI and release tasks

Run the local CI task set:

```bash
bundle exec rake ci
```

This currently runs:

- `version:assert`
- `ruby:lint`
- `ruby:test`
- `ruby:contract`
- `python:lint`
- `python:test`
- `python:contract`
- `package:verify`

Prepare a local versioned release artifact without running the GitHub release flow:

```bash
NEW_VERSION=0.1.1 bundle exec rake release:prepare
```

This syncs version-bearing files, refreshes `uv.lock` for the releasing package version, and builds the RBZ.

The release workflow uses `python-semantic-release` from `pyproject.toml`. To preview the next computed version locally without creating a release:

```bash
uv run semantic-release --noop -v version --print
```

## VS Code tasks

The workspace includes tasks for:

- `bundle install`
- `uv sync`
- running the FastMCP server over stdio or HTTP
- launching SketchUp via the `SKETCHUP_EXECUTABLE` environment variable
