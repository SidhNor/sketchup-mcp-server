# AGENTS.md

## Project Summary

This repository is a **Ruby SketchUp extension** under `src/` that owns MCP tool registration, SketchUp API usage, scene behavior, serialization, and the MCP server lifecycle

Release automation may still use `python-semantic-release` in CI, but that does not make Python a project runtime.

## Intended Architecture

Keep these boundaries stable as the codebase grows:

- SketchUp-facing behavior, MCP tool ownership, scene modeling, metadata handling, validation, and serialization belong in the extension runtime and should not be split into a second app layer
- transport, command orchestration, shared runtime support, and SketchUp adapters should stay distinct enough to evolve safely
- release tooling should stay isolated from product runtime code
- packaging should support a growing Ruby support tree rather than assuming a tiny fixed layout
- tests and linting are part of the platform, not optional cleanup

Current runtime entrypoints:

- `src/su_mcp.rb`: SketchUp extension loader
- `src/su_mcp/main.rb`: SketchUp runtime bootstrap
- `src/su_mcp/extension.rb` and `src/su_mcp/extension.json`: extension registration support and metadata
- `rakelib/package.rake`: canonical staged RBZ packaging tasks
- `releaserc.toml`: CI-owned semantic-release configuration

## Target Layering

The platform direction is a modular layered monolith running inside SketchUp.

Target Ruby layering:

- boot / extension registration
- runtime bootstrap
- MCP runtime and transport boundary
- command or use-case layer
- shared domain and support services
- SketchUp adapters

These are architectural boundaries, not a frozen directory layout. Move code toward those layers deliberately.

## Capability Folder Structure

Capability folders may start flat, but they should not become permanent catch-all
directories. Once a capability mixes commands, request contracts, domain
services, serializers/evidence, storage, output generation, probes, or
SketchUp-facing adapters, move it toward named internal ownership folders instead
of adding more files at the root. Keep structural moves mechanical and preserve
public constants, MCP contracts, response shapes, tests, and package behavior.

Use the platform HLD and Ruby coding guidelines for the fuller structure and
migration guidance.

## Source of Truth

- Keep MCP tool registration, SketchUp API usage, geometry work, entity traversal, and command behavior in the extension runtime rather than scattering them across helper scripts or release tooling.
- Do **not** expose raw SketchUp objects across public boundaries.
- Return only JSON-serializable data from runtime-facing commands and serializers.

## Runtime Boundary

- The supported MCP boundary runs inside SketchUp.
- Prefer one coherent command per tool call over chatty internal hops.
- Keep transport concerns separate from command behavior and SketchUp adapter code.
- In the Ruby-native runtime, keep public MCP tool entries and input schemas co-located in `src/su_mcp/runtime/native/native_tool_catalog.rb` so contract edits remain easy to inspect and update together.
- Keep `src/su_mcp/runtime/native/mcp_runtime_loader.rb` focused on vendored runtime loading and runtime assembly; do not grow it back into the tool catalog, schema catalog, or transport implementation.
- When a public MCP tool contract changes, update the tool registration, dispatcher, tests, and user-facing docs in the same change.

## Change Guidance

**IMPORTANT** If you are touching any part of the code, ensure you read `specifications/guidelines/ryby-coding-guidelines.md`

For task estimation identity fields and retrieval tags, use `specifications/guidelines/task-estimation-taxonomy.md`.

When making changes:

1. Keep SketchUp-specific and behavior-defining logic in the main runtime path rather than pushing it into build, packaging, or release helpers.
2. Prefer extracting commands, serializers, support objects, and adapters over growing one large runtime hotspot.
3. Centralize cross-cutting concerns such as result envelopes, errors, logging, configuration, and serialization helpers.
4. Update docs and examples when tool names, arguments, setup, or behavior change.
5. Avoid unrelated refactors, but do not preserve weak structure just because it is current.

## High-Risk Surfaces

Be conservative when changing these surfaces:

- `src/su_mcp/main.rb`: runtime bootstrap, menu wiring, and server lifecycle entrypoint
- public MCP tool contracts: tool names, arguments, response shapes, and refusal/error payloads
- `src/su_mcp/runtime/` and `src/su_mcp/runtime/native/`: dispatcher, runtime boot, transport wiring, and handler integration
- `rakelib/`, `Rakefile`, `releaserc.toml`, and `.github/workflows/`: packaging, release, and validation behavior
- `src/su_mcp.rb`, `src/su_mcp/extension.rb`, and `src/su_mcp/extension.json`: extension registration and packaged metadata
- docs that describe the current system shape: `README.md`, `AGENTS.md`, platform HLD, and current task indexes

For these surfaces:

- prefer minimal, explicit changes
- keep tests and docs in sync in the same change
- call out validation gaps clearly if full verification is not practical

## Ruby Guidance

- For Ruby extension implementation, RBZ packaging changes, or extension-level technical decisions, consult `specifications/guidelines/sketchup-extension-development-guidance.md`.
- Preserve the small loader pattern: `src/su_mcp.rb` should remain a registration entrypoint.
- Keep mutating operations explicit and be careful with destructive scene changes.
- Normalize outputs into simple hashes, arrays, strings, numbers, and booleans before returning them.
- Keep public tool names stable unless an intentional interface change is documented.
- When changing packaged extension behavior, check whether `src/su_mcp.rb`, `src/su_mcp/extension.rb`, or `src/su_mcp/extension.json` also need updates.
- Use the PRDs, capability HLDs, `specifications/domain-analysis.md`, and `specifications/guidelines/mcp-tool-authoring-sketchup.md` as product and contract guidance for the MCP surface.

## Testing Guidance

Prefer tests at the layer that owns the behavior:

- **Core behavior**: command behavior, metadata handling, serialization, geometry helpers, measurement, validation, and staged-asset workflows
- **Native runtime behavior**: MCP runtime boot, handler wiring, transport-shape behavior, status reporting, and package validation
- **Packaging and release support**: version sync, canonical package tasks, staged runtime assembly, and release-helper wiring
- **SketchUp-hosted behavior**: add in-SketchUp smoke or acceptance coverage where practical
- **Manual verification**: use SketchUp for end-to-end confirmation where automated coverage is not yet practical, but call that gap out explicitly

New platform abstractions should be designed so they can be verified by at least one of:

- isolated unit tests without SketchUp
- deterministic runtime integration tests
- SketchUp-hosted smoke or acceptance testing

## Linting Guidance

- Run language-appropriate linting for the code you change.
- Prefer RuboCop for Ruby quality checks.
- Treat missing lint coverage as a gap to call out, not as a reason to skip mentioning it.

## Commit Guidance

- Use Conventional Commits for commit messages.
- Format commit titles as `<type>(<scope>): <short summary>`.
- Use the correct semantic type for the actual change:
  - `feat` for user-facing or capability-expanding behavior
  - `fix` for bug fixes or behavior corrections
  - `refactor` for internal structural changes without intended behavior change
  - `docs` for documentation-only changes
  - `chore` for maintenance or repo upkeep that does not fit the categories above

## Docs and Contract Updates

When interface or setup behavior changes, review the relevant docs:

- `README.md` for installation, usage, and exposed tools
- `releaserc.toml`, `Rakefile`, and `rakelib/` when release or packaging behavior changes
- `specifications/hlds/hld-platform-architecture-and-repo-structure.md` for platform direction when architecture or repo structure changes materially
- capability HLDs, PRDs, `specifications/domain-analysis.md`, and `specifications/guidelines/mcp-tool-authoring-sketchup.md` when the tool surface changes materially

When architecture changes materially, update this file so it continues to describe the intended system rather than a stale snapshot.

## What To Avoid

- reintroducing a second runtime just to keep old structure alive
- duplicating business rules across multiple layers
- returning non-serializable objects from runtime-facing seams
- mixing transport, command orchestration, SketchUp API access, and shared runtime concerns in one growing module when a clearer split is justified
- letting `main.rb` become the permanent home for every new behavior
- mixing unrelated refactors into feature work

## Review Checklist

Before finishing, verify:

- core behavior still lives in the extension runtime
- MCP tool ownership still sits with the runtime command and registration layers
- outputs are explicit and serializable
- packaging/docs/examples were updated if the exposed contract changed
- relevant linting and the smallest practical test layer were run, or the gap was called out
- testing or manual verification covers the changed behavior, or the gap is called out
