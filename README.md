# SketchUp MCP

This repository is set up as a dual-runtime project:

- A SketchUp Ruby extension lives under `src/`.
- A FastMCP Python server lives under `python/src/`.

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

The extension entrypoint is `src/su_mcp.rb`, which registers `src/su_mcp/main.rb` with SketchUp.

For local development, load the extension from this repository by symlinking or copying the `src/` contents into SketchUp's `Plugins` directory.

## Python FastMCP server

Install the Python environment with `uv`:

```bash
uv sync
```

Run the server over stdio:

```bash
uv run fastmcp run python/src/sketchup_mcp_server/server.py:mcp
```

Run the packaged console script:

```bash
uv run sketchup-mcp-server
```

The packaged server uses stdio by default, which is the expected mode for
MCP clients that launch the server as a subprocess.

Run the server over HTTP:

```bash
SKETCHUP_MCP_TRANSPORT=http uv run sketchup-mcp-server
```

When HTTP transport is enabled, the server uses `127.0.0.1:8000` by default
and exposes the MCP endpoint at `/mcp`.

## VS Code tasks

The workspace includes tasks for:

- `bundle install`
- `uv sync`
- running the FastMCP server over stdio or HTTP
- launching SketchUp via the `SKETCHUP_EXECUTABLE` environment variable
