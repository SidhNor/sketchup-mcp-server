# AGENTS.md

## Project summary

This repository has two runtime layers:

- a **Ruby SketchUp extension** under `src/` that runs inside SketchUp, owns SketchUp API usage, and executes tool behavior
- a **Python FastMCP server** under `python/src/` that exposes those capabilities to MCP clients and forwards requests over a local TCP socket bridge

The Ruby layer is the source of truth for behavior. The Python layer should remain a thin adapter.

## Intended architecture

The current repo is still relatively small, but it is expected to grow substantially as the MCP surface expands.

Keep these architectural boundaries stable even if the internal file layout evolves:

- SketchUp-facing behavior, scene modeling, semantic construction, metadata handling, measurement, validation, and asset workflows belong in **Ruby**
- MCP tool definitions, transport, boundary validation, and response/error mapping belong in **Python**
- transport concerns should stay isolated from both product logic and SketchUp-specific adapter code
- the Ruby layer may and should be split into multiple maintainable files, modules, commands, or services as the tool surface grows
- packaging should support a growing Ruby support tree rather than assuming a small fixed set of files
- tests should grow with the codebase and should not be treated as optional scaffolding
- linting and static quality checks are part of the platform, not optional cleanup

Current entrypoints and packaging files still matter, but they are implementation details rather than the desired long-term structure:

- `src/su_mcp.rb`: SketchUp extension loader
- `src/su_mcp/main.rb`: current primary Ruby runtime entrypoint
- `src/su_mcp/extension.rb` and `src/su_mcp/extension.json`: extension registration support and metadata
- `python/src/sketchup_mcp_server/server.py`: current FastMCP server entrypoint
- `pyproject.toml`: Python packaging and console-script metadata

It is acceptable to introduce a more maintainable internal structure when the feature work justifies it. Do that deliberately, not as incidental churn.

## Target layering

The platform direction is a modular layered monolith with one Ruby runtime inside SketchUp, one Python MCP adapter, and one explicit transport boundary between them.

Target Ruby layering:

- boot / extension registration
- runtime bootstrap
- transport and request routing
- command or use-case layer
- shared domain and support services
- SketchUp adapters

Target Python layering:

- MCP app boot
- tool modules by capability area
- shared invocation and connection modules
- boundary error mapping

These are architectural boundaries, not a frozen directory layout. Keep code moving toward these layers without inventing unnecessary churn before the structure is justified.

## Source of truth

- Put domain logic, SketchUp API usage, geometry work, entity traversal, and command behavior in **Ruby**.
- Use **Python** for MCP tool definitions, boundary validation, request forwarding, and error/response mapping.
- Do **not** duplicate business logic in Python.
- Do **not** expose raw SketchUp objects across the Ruby/Python boundary.
- Return only JSON-serializable data from Ruby.

## Runtime boundary

- The Python server talks to SketchUp over a TCP socket using JSON-RPC-like messages.
- The Ruby extension accepts a request, responds, and closes the client socket; Python reconnects per call.
- Keep the MCP transport choice separate from the Python-to-Ruby socket bridge design.
- Prefer one Ruby command that completes a full operation over multiple cross-runtime round trips.
- Treat `contracts/bridge/bridge_contract.json` as the shared test artifact for durable Python/Ruby bridge invariants. It is test data for the runtime boundary, not runtime configuration.
- When adding or changing a tool, keep the contract explicit on both sides:
  - Python MCP tool name and arguments
  - Ruby `handle_tool_call` dispatch name
  - Ruby response shape returned across the socket
- When a public bridge or tool contract changes, update the shared contract artifact and the owning Python and Ruby contract suites in the same change.

## Change guidance

When making changes:

1. Decide whether the behavior belongs in Ruby, Python, or both.
2. Default to **Ruby** for anything SketchUp-specific or behavior-defining.
3. Keep Python changes limited to the MCP adapter, transport, validation, and error mapping.
4. For platform work, prefer refactoring toward transport, commands, shared support, and SketchUp adapter boundaries rather than adding more responsibility to one entrypoint.
5. Centralize cross-cutting runtime concerns such as result envelopes, errors, logging, configuration, operation wrappers, and serialization helpers rather than scattering them.
6. Update docs and examples when tool names, arguments, setup, or behavior change.
7. Avoid unrelated refactors, but do not preserve a weak structure just because it is current.

## Ruby guidance

- For Ruby extension implementation, RBZ packaging changes, or extension-level technical decisions, consult `specifications/sketchup-extension-development-guidance.md`. It is a targeted reference for SketchUp extension practices and should not be treated as always-on context for Python-only work.
- Keep SketchUp-facing behavior in Ruby, even if Python could technically do part of it.
- Preserve the current small loader pattern: `src/su_mcp.rb` should remain a registration entrypoint, not become the home for runtime or capability logic.
- As functionality expands, split Ruby code into focused command objects, modules, serializers, and helpers instead of growing one large dispatcher file indefinitely.
- Make mutating operations explicit and be careful with destructive scene changes.
- Normalize output into simple hashes, arrays, strings, numbers, and booleans before returning it.
- Keep command names stable once exposed through MCP unless the interface change is intentional and documented.
- When updating packaged extension behavior, check whether `src/su_mcp.rb`, `src/su_mcp/extension.rb`, or `src/su_mcp/extension.json` also need changes.
- Use the planned MCP direction in `sketchup_mcp_guide.md` as product guidance for expanding the Ruby surface, especially around semantic tools, staged assets, metadata, and validation.

## Python guidance

- Keep FastMCP handlers small and mechanical.
- Centralize socket communication and SketchUp invocation in the shared connection layer.
- Validate inputs at the MCP boundary, but avoid reimplementing Ruby-side rules.
- Return clear, structured errors where possible.
- Preserve a close 1:1 mapping between Python tools and Ruby commands unless there is a strong adapter reason not to.
- If Python code starts accumulating domain knowledge from the guide, that is a design smell; move that behavior back to Ruby.

## Testing guidance

Testing should become stricter as the server grows. Prefer tests at the layer that owns the behavior:

- **Ruby-side behavior**: cover command behavior, metadata handling, serialization, geometry helpers, measurement, validation, and staged-asset workflows
- **Python-side behavior**: test MCP schemas, handler wiring, socket request shaping, timeout/retry behavior, and error mapping
- **Contract behavior**: verify Python and Ruby continue to agree on tool names, request envelopes, response shapes, and structured error payloads
- **Integration behavior**: verify MCP request -> Python adapter -> Ruby command -> structured SketchUp response for important tools
- **SketchUp-hosted behavior**: add in-SketchUp integration or acceptance coverage for runtime-dependent behavior where practical
- **Manual verification**: use SketchUp for end-to-end confirmation where automated coverage is not yet practical, but do not let manual-only testing become the permanent default

If a change expands behavior without adding appropriate tests, call that out as a gap rather than silently accepting it.

When a change touches the Python/Ruby boundary:

- keep unit tests and contract tests separate so boundary failures stay visible
- run the dedicated contract suites for the affected surface:
  - `bundle exec rake ruby:contract`
  - `bundle exec rake python:contract`
- prefer updating the shared contract artifact and native contract suites over duplicating bridge rules in one runtime only

New platform abstractions should be designed so they can be verified by at least one of:

- isolated unit tests without SketchUp
- contract tests at the Python/Ruby boundary
- deterministic SketchUp-hosted integration testing

## Linting guidance

- Run language-appropriate linting for the code you change.
- Prefer RuboCop for Ruby quality checks.
- Prefer Ruff for Python linting and formatting checks.
- Treat missing lint coverage as a gap to call out, not as a reason to skip mentioning it.

## Docs and contract updates

When interface or setup behavior changes, review the relevant docs:

- `README.md` for installation, usage, and exposed tools
- `contracts/bridge/bridge_contract.json` and the contract suites under `python/tests/contracts/` and `test/contracts/` when the public Python/Ruby boundary changes
- packaging metadata files when extension or Python package behavior changes
- `specifications/hlds/hld-platform-architecture-and-repo-structure.md` for platform direction when architecture or repo structure changes materially
- `sketchup_mcp_guide.md` for higher-level MCP surface guidance when the tool surface changes materially

When architecture changes materially, update this file so it continues to describe the intended system rather than a stale snapshot.

## What to avoid

- moving core logic from Ruby to Python
- duplicating validation or business rules across both runtimes
- returning non-serializable objects across the boundary
- adding chatty Python-to-Ruby call patterns when one Ruby command would do
- treating the current flat structure as something that must be preserved
- mixing transport, command orchestration, SketchUp API access, and shared runtime concerns in one growing module when a clearer split is justified
- letting `main.rb` become the permanent home for every new behavior
- mixing unrelated refactors into feature work

## Review checklist

Before finishing, verify:

- core behavior still lives in Ruby
- the FastMCP layer is still thin
- Python and Ruby tool names/arguments still line up
- outputs are explicit and serializable
- errors are mapped clearly across the socket boundary
- shared contract artifacts and contract suites were updated if the public boundary changed
- transport, command, support, and SketchUp adapter responsibilities are still separated appropriately for the current size of the repo
- the structure remains maintainable as the Ruby surface grows
- packaging/docs/examples were updated if the exposed contract changed
- relevant linting and the smallest practical test layer were run, or the gap is called out
- testing or manual verification covers the changed behavior, or the gap is called out
