# HLD: Platform Architecture and Repo Structure

## System Overview

This document defines the product-agnostic platform architecture for the SketchUp MCP repository after retirement of the legacy Python runtime.

The repository now contains:

- a Ruby SketchUp extension under `src/`
- an MCP server hosted inside SketchUp
- staged RBZ packaging and vendored runtime support under the packaging helpers
- local validation and CI entrypoints
- CI-owned release automation through standalone semantic-release configuration
- capability-oriented Ruby support subtrees for scene query, scene validation, semantic modeling, editing, solid modeling, developer tools, adapters, and runtime support

This HLD covers:

- runtime ownership boundaries
- repository structure direction
- MCP runtime shape
- packaging and release ownership
- testing and quality-gate structure
- shared runtime conventions

It does not define feature-specific behavior. Capability design belongs in the capability HLDs.

## Architecture Approach

### Current Platform Shape

The supported platform is a layered monolith running inside SketchUp:

- one runtime inside SketchUp
- one in-process MCP boundary
- one packaged RBZ artifact that carries the staged runtime support tree

Current entrypoints:

- Ruby extension registration: `src/su_mcp.rb`
- Ruby extension metadata and registration support: `src/su_mcp/extension.rb`, `src/su_mcp/extension.json`
- runtime bootstrap: `src/su_mcp/main.rb`
- MCP runtime support: `src/su_mcp/runtime/*`, `src/su_mcp/runtime/native/*`
- packaging and release wiring: `Rakefile`, `rakelib/`, `releaserc.toml`

### Recommended Direction

The recommended platform style remains a modular layered monolith.

The main architectural goals are:

- keep MCP ownership aligned with SketchUp behavior ownership in Ruby
- preserve the small SketchUp loader pattern
- keep transport, command behavior, host interaction, and serialization distinct enough to evolve safely
- keep release automation separate from product runtime code
- preserve one canonical staged RBZ package path

### Boundary Rules

- Ruby owns MCP tool registration, SketchUp API usage, entity traversal, mutation, geometry behavior, serialization, and runtime lifecycle.
- Shared runtime helpers own result envelopes, logging, configuration, and command assembly.
- SketchUp adapter seams own direct host interaction and should return normalized Ruby data, not raw host objects.
- CI-owned release tooling may use Python, but no project runtime or contributor workflow should depend on a repo-local Python package.

## Component Breakdown

### 1. SketchUp Extension Registration

**Responsibilities**

- register the extension with SketchUp
- expose extension metadata
- preserve the standard SketchUp packaging shape of one root loader plus one support tree

**Must Not Own**

- runtime behavior
- transport logic
- feature or capability behavior

### 2. Ruby Runtime Bootstrap

**Responsibilities**

- activate the extension runtime inside SketchUp
- install menu-level developer or operator affordances
- initialize and manage the MCP server lifecycle
- keep startup behavior understandable and minimal

**Current Baseline**

- implemented primarily in `src/su_mcp/main.rb`

### 3. MCP Runtime Boundary

**Responsibilities**

- own MCP tool registration and protocol handling
- route tool requests to Ruby execution seams
- return structured success or error responses
- keep transport-specific concerns out of command behavior
- expose enough tool descriptions and input-schema metadata for a generic MCP client to call first-class tools safely without client-specific prompt stuffing
- provide a home for MCP prompts, and possibly later resources, when richer server-owned recipes, examples, or playbooks are too large for concise tool definitions

**Current Baseline**

- implemented primarily under `src/su_mcp/runtime/native/`
- `src/su_mcp/runtime/native/mcp_runtime_loader.rb` owns vendored runtime loading and assembly of the native MCP server surface
- `src/su_mcp/runtime/native/native_tool_catalog.rb` owns public native MCP tool entries and input schemas together, intentionally keeping contract edits co-located rather than spread across many small schema files
- focused support objects under `src/su_mcp/runtime/native/` own server object construction, prompt catalog integration, and stateless HTTP transport handling

### 4. Ruby Command or Use-Case Layer

**Responsibilities**

- expose stable execution entrypoints for capability behavior
- map tool calls to coherent operations
- orchestrate shared services and SketchUp adapters

**Current Baseline**

- shared assembly via `src/su_mcp/runtime/runtime_command_factory.rb`
- stable dispatch via `src/su_mcp/runtime/tool_dispatcher.rb`
- capability command ownership under `src/su_mcp/scene_query/`, `src/su_mcp/scene_validation/`, `src/su_mcp/semantic/`, `src/su_mcp/editing/`, `src/su_mcp/modeling/`, and `src/su_mcp/developer/`

### 5. Shared Ruby Runtime Infrastructure

**Responsibilities**

- result shaping
- error translation
- logging and runtime messaging conventions
- configuration handling
- operation wrappers and serialization helpers used across commands

**Current Baseline**

- implemented through support objects such as `src/su_mcp/runtime/tool_response.rb`, `src/su_mcp/runtime/runtime_logger.rb`, native runtime configuration, request normalizers, serializers, validators, and capability-local services

### 6. Ruby SketchUp Adapter Layer

**Responsibilities**

- isolate direct SketchUp API interaction
- provide reusable access to entities, bounds, materials, tags, components, export helpers, and model operations
- normalize SketchUp state into simple Ruby hashes, arrays, strings, numbers, and booleans before returning across the MCP boundary

**Current Baseline**

- shared model access begins in `src/su_mcp/adapters/model_adapter.rb`
- some capability-local SketchUp interaction still lives beside the owning commands and should be extracted only when reuse or boundary clarity justifies it

### 7. Packaging and Release Support

**Responsibilities**

- build the canonical staged RBZ artifact
- stage vendored runtime dependencies into the support tree
- verify package layout and runtime loadability
- keep version-bearing files aligned across the runtime metadata
- support CI-owned release automation without reintroducing a second project runtime

**Current Baseline**

- implemented through `Rakefile`, `rakelib/`, `VERSION`, `src/su_mcp/version.rb`, `src/su_mcp/extension.json`, and `releaserc.toml`

## Repository Structure Direction

The platform now has explicit support subtrees for the major runtime and capability layers. It should continue refining those boundaries incrementally rather than forcing broad directory churn.

Current source grouping:

- extension registration and boot
- runtime boundary and shared runtime support under `src/su_mcp/runtime/`
- native MCP transport and catalog support under `src/su_mcp/runtime/native/`
- scene query commands and support under `src/su_mcp/scene_query/`
- scene validation and measurement commands under `src/su_mcp/scene_validation/`
- semantic scene modeling under `src/su_mcp/semantic/`
- generic editing and mutation support under `src/su_mcp/editing/`
- solid modeling support under `src/su_mcp/modeling/`
- developer-only tool support under `src/su_mcp/developer/`
- shared SketchUp adapters under `src/su_mcp/adapters/`
- packaging and release support under `rakelib/`
- tests grouped by owning layer under `test/`

Further structure changes should be driven by concrete pressure such as large runtime hotspots, repeated SketchUp adapter logic, public tool contract changes, or packaging risk.

## Validation and Quality Gates

The canonical local validation surface is:

- `bundle exec rake version:assert`
- `bundle exec rake ruby:lint`
- `bundle exec rake ruby:test`
- `bundle exec rake package:verify`
- `bundle exec rake ci`

When runtime bootstrap, packaging, or MCP response-shape behavior changes, prefer focused runtime and packaging tests first, then rerun the broader validation surface.

Manual SketchUp-hosted smoke validation remains required when:

- package assembly changes
- runtime startup behavior changes
- vendored runtime dependencies change
- the MCP server behavior cannot be fully proven in plain Ruby tests

## Technology Stack

| Concern | Technology / Approach | Purpose |
| --- | --- | --- |
| extension runtime | SketchUp embedded Ruby | host process for MCP and SketchUp behavior |
| MCP server | vendored MCP runtime support | MCP tool exposure inside SketchUp |
| packaging | staged RBZ build via Rake | canonical distributable artifact |
| release automation | standalone `python-semantic-release` config in CI | versioning and GitHub release automation |
| quality checks | RuboCop, Minitest, package verification | maintain runtime and packaging quality |

## Open Questions

1. What additional SketchUp-hosted smoke coverage should become mandatory for packaged runtime startup, representative MCP requests, and high-risk mutating tools?
2. Should release automation stay on `python-semantic-release` long term, or should a repo-owned release flow eventually replace it?
3. How many initial MCP prompts should the native runtime expose for richer workflow guidance while keeping baseline usage semantics in tool descriptions and schemas?
