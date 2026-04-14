# HLD: Platform Architecture and Repo Structure

## System Overview

This document defines the product-agnostic platform architecture for the SketchUp MCP repository.

It should be read as an update over an already implemented platform, not as a greenfield design. The repository already contains:

- a Ruby SketchUp extension under `src/`
- a Python FastMCP server under `python/src/`
- a local socket bridge between the two runtimes
- RBZ packaging, Python packaging, version alignment, and local CI entrypoints

This HLD describes that current baseline and the intended refinement path introduced by the seeded HLD, PRD, and platform-task set. The seeded artifacts are an iteration on the existing design: they clarify boundaries, quality expectations, and growth direction for a system that already has substantial runtime behavior in place.

This is the platform HLD for the repository. It covers shared architecture concerns such as:

- runtime ownership boundaries
- repository structure direction
- transport shape
- packaging and release ownership
- testing and quality-gate structure
- shared runtime conventions

It does not define feature-specific behavior. Capability design belongs in:

- [`hld-scene-targeting-and-interrogation.md`](./hld-scene-targeting-and-interrogation.md)
- [`hld-semantic-scene-modeling.md`](./hld-semantic-scene-modeling.md)
- [`hld-asset-exemplar-reuse.md`](./hld-asset-exemplar-reuse.md)
- [`hld-scene-validation-and-review.md`](./hld-scene-validation-and-review.md)

The main source constraints for this HLD are:

- the current repository structure and runtime entrypoints
- [`../domain-analysis.md`](../domain-analysis.md)
- the seeded capability HLDs and PRDs
- the seeded platform task set under [`../tasks/platform/`](../tasks/platform/README.md)

## Architecture Approach

### Current Platform Shape

The repository already follows the correct macro-architecture:

- one Ruby runtime inside SketchUp
- one Python MCP adapter process
- one explicit transport boundary between them

Current entrypoints:

- Ruby extension registration: `src/su_mcp.rb`
- Ruby extension metadata and registration support: `src/su_mcp/extension.rb`, `src/su_mcp/extension.json`
- Ruby runtime bootstrap: `src/su_mcp/main.rb`
- Ruby bridge configuration and socket server: `src/su_mcp/bridge.rb`, `src/su_mcp/socket_server.rb`
- Python MCP server boot and tool registration: `python/src/sketchup_mcp_server/server.py`
- packaging and release wiring: `Rakefile`, `rakelib/`, `pyproject.toml`

This current shape already enforces the most important architectural rule: SketchUp-facing behavior lives in Ruby and Python acts as the MCP-facing adapter.

### Recommended Direction

The recommended platform style remains a modular layered monolith across the existing two runtimes.

The goal is not to replace the current architecture. The goal is to progressively decompose the current concentrated modules into clearer internal layers while preserving:

- the small SketchUp loader pattern
- the Ruby/Python runtime split
- the socket bridge contract
- packaged distribution for both runtimes

The main architectural issue in the current repository is concentration of responsibility rather than incorrect runtime ownership:

- `src/su_mcp/socket_server.rb` currently mixes transport ingress, request routing, result shaping, serialization helpers, and tool behavior
- `python/src/sketchup_mcp_server/server.py` currently mixes app boot, connection management, endpoint resolution, shared invocation behavior, and all MCP tool definitions

### Boundary Rules

- Ruby owns SketchUp API usage, entity traversal, mutation, geometry behavior, serialization of SketchUp-side results, and capability-defining logic.
- Python owns MCP tool registration, boundary validation, request construction, transport failure handling, and MCP-facing response or error mapping.
- The socket bridge owns message transport only. It must not become the home for capability policy.
- Cross-runtime payloads must remain JSON-serializable.
- One Ruby command should complete a coherent operation whenever possible; avoid chatty Python-to-Ruby round trips.

### Target Layering

Target Ruby layering:

- boot and extension registration
- runtime bootstrap
- transport ingress and request routing
- command or use-case execution
- shared runtime infrastructure
- SketchUp adapters

Target Python layering:

- MCP app boot
- tool modules by capability area
- shared invocation and connection modules
- boundary error mapping

These are architectural boundaries, not a required immediate directory rewrite. The seeded platform tasks should be understood as the implementation path for gradually extracting these layers from the current runtime hotspots.

## Component Breakdown

### 1. SketchUp Extension Registration

**Responsibilities**

- register the extension with SketchUp
- expose extension metadata
- preserve the standard SketchUp packaging shape of one root loader plus one support tree

**Must Not Own**

- transport logic
- feature or capability behavior
- broad runtime initialization beyond registration

### 2. Ruby Runtime Bootstrap

**Responsibilities**

- activate the extension runtime inside SketchUp
- install menu-level developer or operator affordances
- initialize and manage the bridge server lifecycle
- keep startup behavior understandable and minimal

**Current Baseline**

- implemented primarily in `src/su_mcp/main.rb`

**Must Not Own**

- low-level transport parsing
- command-level capability behavior
- reusable SketchUp adapter logic

### 3. Ruby Transport Boundary

**Responsibilities**

- accept socket requests from Python
- parse structured request envelopes
- route requests to the Ruby execution boundary
- return structured success or error responses

**Current Baseline**

- implemented inside `src/su_mcp/socket_server.rb`

**Must Not Own**

- long-term feature dispatch growth
- low-level SketchUp business logic
- duplicated cross-cutting result or error policy scattered per tool

### 4. Ruby Command or Use-Case Layer

**Responsibilities**

- expose stable execution entrypoints for capability behavior
- map tool calls to coherent Ruby-owned operations
- orchestrate shared services and SketchUp adapters

**Improvement Direction**

- extract command ownership from the current large transport file so execution is distinct from ingress

**Must Not Own**

- socket server lifecycle
- raw transport parsing
- duplicated low-level SketchUp API mechanics where reusable adapters should exist

### 5. Shared Ruby Runtime Infrastructure

**Responsibilities**

- result envelopes
- error categories
- logging and runtime messaging conventions
- configuration handling
- operation wrappers and serialization helpers used across commands

**Improvement Direction**

- move shared cross-cutting behavior out of individual transport or command implementations and into explicit platform-owned support modules

**Must Not Own**

- feature-specific behavior
- Python-facing MCP registration concerns

### 6. Ruby SketchUp Adapter Layer

**Responsibilities**

- isolate direct SketchUp API interaction
- provide reusable access to entities, bounds, materials, tags, components, export helpers, and model operations
- normalize SketchUp state into simple Ruby hashes, arrays, strings, numbers, and booleans before returning across the bridge

**Current Baseline**

- adapter-like behavior exists today, but much of it is embedded in `src/su_mcp/socket_server.rb`

**Must Not Own**

- MCP concerns
- Python transport semantics
- feature-policy decisions better expressed in higher-level commands

### 7. Python MCP App Boot

**Responsibilities**

- create the FastMCP server
- expose transport mode selection for stdio or HTTP
- manage process lifecycle behavior such as startup ping and shutdown cleanup

**Current Baseline**

- implemented in `python/src/sketchup_mcp_server/server.py`

**Must Not Own**

- SketchUp business logic
- detailed per-tool transport duplication

### 8. Python Invocation and Connection Layer

**Responsibilities**

- resolve the SketchUp bridge endpoint
- manage short-lived socket connections
- build structured bridge requests
- parse structured responses
- centralize transport failure handling for MCP-facing callers

**Current Baseline**

- already present in `SketchupConnection`, endpoint helpers, and `_call_bridge_tool`

**Must Not Own**

- Ruby business rules
- capability-specific validation duplicated from Ruby

### 9. Python Tool Modules

**Responsibilities**

- expose MCP tools with clear names and argument surfaces
- stay close to a 1:1 mapping with Ruby command names unless there is a strong adapter reason not to
- group tools by capability area as the surface expands

**Current Baseline**

- all tool definitions currently live in `python/src/sketchup_mcp_server/server.py`

**Improvement Direction**

- split tool definitions by capability area while preserving thin handlers and shared invocation

**Must Not Own**

- custom transport logic per tool
- domain-policy duplication from Ruby

### 10. Packaging and Release Layer

**Responsibilities**

- build the RBZ package
- build and expose the Python package
- keep version-bearing files aligned across both runtimes
- verify packaged RBZ layout

**Current Baseline**

- implemented through `Rakefile`, `rakelib/`, `pyproject.toml`, `VERSION`, and release-support helpers

**Must Not Own**

- capability behavior
- runtime-specific logic that should live in the product code

### 11. Quality and Verification Layer

**Responsibilities**

- Ruby linting and unit-test entrypoints
- Python linting and unit-test entrypoints
- contract-test direction for the Ruby/Python boundary
- SketchUp-hosted integration and fixture strategy direction
- documentation and specification quality expectations

**Current Baseline**

- local CI and package verification are already present
- current automated tests are still narrow compared with the intended layered quality model

**Must Not Own**

- feature behavior itself
- hidden architecture assumptions not reflected in the HLD and task set

## Integration & Data Flows

### Extension Startup Flow

```text
SketchUp
-> src/su_mcp.rb
-> src/su_mcp/extension.rb
-> src/su_mcp/main.rb
-> bridge configuration + socket server startup
-> extension menu/status controls
```

### MCP Tool Invocation Flow

```text
MCP client
-> Python FastMCP tool
-> shared Python invocation/connection logic
-> JSON request over local TCP socket
-> Ruby transport boundary
-> Ruby command or use-case execution
-> SketchUp adapter calls and model interaction
-> JSON-serializable Ruby result
-> Python response/error mapping
-> MCP response
```

### Packaging and Release Flow

```text
VERSION + runtime metadata
-> release support helpers
-> RBZ packaging verification
-> Python package metadata alignment
-> release artifact production
```

### Quality Flow

```text
Local change
-> Ruby lint/test if Ruby-owned concerns changed
-> Python lint/test if adapter concerns changed
-> contract tests for bridge-envelope changes
-> SketchUp-hosted tests for real runtime behavior
-> package verification
```

### Architecture Diagram

```text
                           +----------------------+
                           |  External MCP Client |
                           +----------+-----------+
                                      |
                                      v
                         +------------+-------------+
                         | Python MCP App Boot      |
                         | FastMCP server process   |
                         +------------+-------------+
                                      |
                     +----------------+----------------+
                     |                                 |
                     v                                 v
         +-----------+-----------+         +-----------+-----------+
         | Python Tool Modules   |         | Python Invocation /   |
         | thin MCP handlers     |-------->| Connection Layer      |
         +-----------------------+         +-----------+-----------+
                                                        |
                                     JSON over local TCP socket bridge
                                                        |
                                                        v
                             +--------------------------+----------------------+
                             | Ruby Transport Boundary / Request Routing       |
                             +--------------------------+----------------------+
                                                        |
                                                        v
                             +--------------------------+----------------------+
                             | Ruby Command / Use-Case Execution               |
                             +--------------------------+----------------------+
                                                        |
                               +------------------------+---------------------+
                               |                                              |
                               v                                              v
                    +----------+-----------+                      +-----------+----------+
                    | Shared Ruby Runtime  |                      | Ruby SketchUp        |
                    | Infrastructure       |                      | Adapters             |
                    +----------+-----------+                      +-----------+----------+
                               |                                              |
                               +------------------------+---------------------+
                                                        |
                                                        v
                                             +----------+----------+
                                             | SketchUp Runtime    |
                                             | Model + API         |
                                             +---------------------+

Test boundaries:
- Ruby unit tests: shared runtime logic
- Python unit tests: app boot, invocation, tool wiring
- contract tests: Python <-> Ruby request/response envelopes
- SketchUp-hosted tests: command -> adapter -> model behavior
```

## Key Architectural Decisions

### 1. Keep Ruby as the Source of Truth for SketchUp and Capability Behavior

**Decision**

SketchUp-facing behavior, geometry or model logic, entity traversal, mutation, and behavior-defining command execution remain Ruby-owned.

**Reason**

The SketchUp API lives in Ruby. Keeping execution semantics close to that runtime prevents drift, avoids duplicated business rules, and preserves a clean Python adapter boundary.

### 2. Keep Python Thin and Mechanical

**Decision**

Python remains responsible for MCP tool exposure, invocation, connection management, and boundary error mapping, not domain behavior.

**Reason**

This preserves a clear runtime split and keeps the MCP adapter maintainable as the tool surface grows.

### 3. Treat the Current Platform as the Baseline, Not a Temporary Placeholder

**Decision**

The HLD documents the existing dual-runtime implementation as the current platform baseline and frames seeded work as iterative refinement.

**Reason**

The repository already has working runtime, packaging, and quality structure. Describing the architecture as if it does not yet exist would be inaccurate and would weaken the HLD's usefulness.

### 4. Evolve by Extraction, Not Rewrite

**Decision**

Internal modularization should be achieved by extracting clearer layers from the current large files rather than by replacing the runtime shape wholesale.

**Reason**

The macro-architecture is already correct. The main risk is concentrated responsibility, so the design response should be evolutionary and low-churn.

### 5. Preserve the Small SketchUp Loader Pattern

**Decision**

`src/su_mcp.rb` stays a registration entrypoint, with runtime behavior living under the support tree.

**Reason**

This matches SketchUp extension conventions, keeps packaging predictable, and avoids turning boot files into implementation hotspots.

### 6. Keep the Socket Bridge as an Explicit Runtime Boundary

**Decision**

Python and Ruby continue to communicate through structured JSON messages over the local socket bridge.

**Reason**

The bridge already exists, fits the current runtime split, and provides a clean contract boundary for future contract testing and error mapping.

### 7. Centralize Shared Runtime Contracts

**Decision**

Results, errors, configuration, logging, operation wrappers, and similar cross-cutting runtime behavior should be owned by shared platform infrastructure rather than by individual commands or tool handlers.

**Reason**

Centralization reduces repeated reinvention and gives downstream tests and capabilities a stable platform contract to depend on.

### 8. Treat Testing, Packaging, and Documentation Quality as Architectural Concerns

**Decision**

Linting, tests, package verification, release metadata alignment, and specification quality are part of the platform architecture rather than optional maintenance work.

**Reason**

This repository spans two runtimes and a growing specification set. Without explicit quality and packaging ownership, drift will accumulate faster than feature work can safely expand.

## Technology Stack

| Concern | Technology / Approach | Purpose |
| --- | --- | --- |
| SketchUp extension runtime | Ruby inside SketchUp | Own SketchUp API access and behavior-defining execution |
| Extension registration | `sketchup.rb`, `extensions.rb`, root loader + support tree | Follow standard SketchUp extension packaging and load patterns |
| Ruby transport | `TCPServer` over local socket bridge | Accept Python bridge requests inside SketchUp |
| Ruby packaging | RBZ packaging via Rake and Zip | Produce distributable SketchUp extension artifacts |
| MCP adapter runtime | Python 3.10+ with FastMCP | Expose MCP tools and process lifecycle |
| Python bridge client | short-lived socket client per call | Forward MCP tool calls to the SketchUp runtime |
| MCP process transport | stdio by default, optional HTTP | Support MCP-client subprocess launch and optional HTTP serving |
| Release/version alignment | `VERSION`, `pyproject.toml`, Ruby/Python version files, extension metadata | Keep cross-runtime version metadata synchronized |
| Ruby quality | RuboCop, Minitest-based task entrypoint | Maintain Ruby code quality and unit-test execution |
| Python quality | Ruff, Pytest | Maintain Python adapter quality and test execution |
| Contract verification direction | Python/Ruby request-response fixture and contract testing | Protect bridge compatibility as the surface grows |
| SketchUp-hosted validation direction | SketchUp runtime integration tests and governed `.skp` fixtures | Validate behaviors that cannot be proven outside real SketchUp semantics |

## Opened Questions

1. What is the exact first extraction boundary inside `src/su_mcp/socket_server.rb`: transport router, command registry, or shared serialization and operation support?
2. What shared Ruby result and error envelope should be standardized first so Python contract tests can depend on it without locking in accidental current behavior?
3. How should Python tool modules be grouped as capability areas expand while still keeping cross-cutting app boot and invocation code centralized?
4. Which bridge behaviors should be mandatory contract-test coverage first: tool naming, request envelope shape, error payload shape, or success-envelope shape?
5. What is the practical first SketchUp-hosted test harness for this repository, and how should fixture `.skp` assets be versioned and governed?
6. Which documentation checks should become mandatory in the default quality workflow as the `specifications/` tree continues to grow?
