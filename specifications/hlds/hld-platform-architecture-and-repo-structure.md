# HLD: Platform Architecture and Repo Structure

## System Overview

This document defines the product-agnostic platform architecture for the SketchUp MCP repository.

It should be read as an update over an already implemented platform, not as a greenfield design. The repository already contains:

- a Ruby SketchUp extension under `src/`
- a Python FastMCP server under `python/src/`
- a local socket bridge between the two runtimes
- RBZ packaging, Python packaging, version alignment, and local CI entrypoints

This HLD describes that current baseline and the intended refinement path introduced by the seeded HLD, PRD, and platform-task set. The seeded artifacts are an iteration on the existing design: they clarify boundaries, quality expectations, and growth direction for a system that already has substantial runtime behavior in place.

Recent host-process validation proved a narrow Ruby-native MCP slice can run inside SketchUp. The platform direction is therefore a transition from the current supported dual-runtime baseline toward Ruby-native MCP as the canonical architecture.

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

The repository already follows the intended macro-architecture for the current supported path:

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

The recommended platform style remains a modular layered monolith, but the current dual-runtime shape is now the baseline rather than the architectural endpoint.

The accepted target direction is Ruby-native MCP inside SketchUp. Until that path is hardened, the repository should continue to preserve:

- the small SketchUp loader pattern
- Ruby as the source of truth for SketchUp behavior
- the current supported Python compatibility path
- explicit runtime boundaries during the transition
- packaged distribution for the currently supported path

The main architectural issues in the current repository are concentration of responsibility and the need to separate current compatibility architecture from the target Ruby-native MCP ownership model:

- `src/su_mcp/socket_server.rb` currently mixes transport ingress, request routing, result shaping, serialization helpers, and tool behavior
- `python/src/sketchup_mcp_server/server.py` currently mixes app boot, connection management, endpoint resolution, shared invocation behavior, and all MCP tool definitions

The remaining platform work is to harden a supported Ruby-native runtime and packaging foundation, then migrate the public MCP tool surface so Ruby becomes the canonical MCP host.

### Boundary Rules

- Ruby owns SketchUp API usage, entity traversal, mutation, geometry behavior, serialization of SketchUp-side results, and capability-defining logic. Ruby is also the target long-term owner of MCP tool exposure, capability negotiation, request dispatch, protocol handling, structured error mapping, and response shaping inside SketchUp.
- Python currently owns the supported MCP compatibility path: boundary validation, request construction, transport failure handling, and MCP-facing response or error mapping while Ruby-native MCP is being hardened.
- The socket bridge owns message transport for the current supported dual-runtime baseline only. It must not become the home for capability policy.
- Cross-runtime payloads must remain JSON-serializable.
- One Ruby-owned operation should complete a coherent client request whenever possible; avoid chatty cross-boundary round trips on the supported compatibility path.

### Target Layering

Target Ruby layering:

- boot and extension registration
- runtime bootstrap
- MCP transport, protocol handling, tool registration, and request routing
- command or use-case execution
- shared runtime infrastructure
- SketchUp adapters

Target Python layering during the transition:

- compatibility adapter boot
- compatibility invocation and connection modules
- boundary error mapping

These are architectural boundaries, not a required immediate directory rewrite. The implementation path should gradually extract these layers from the current runtime hotspots while the supported dual-runtime baseline transitions toward Ruby-native MCP.

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

### 3. Ruby MCP and Transport Boundary

**Responsibilities**

- own Ruby-side transport ingress for the active runtime path
- parse MCP or bridge request envelopes as appropriate to the runtime path
- own Ruby-side tool registration, protocol handling, request routing, and response shaping for the Ruby-native path
- route requests to the Ruby execution boundary
- return structured success or error responses

**Target Contract**

- use an in-process Ruby MCP boundary inside SketchUp for canonical tool registration and protocol ownership
- keep MCP protocol semantics in Ruby even if the externally exposed client transport varies between supported launch modes
- keep command execution and SketchUp adapter layers transport-agnostic

**Current Baseline**

- implemented primarily as the socket-facing boundary inside `src/su_mcp/socket_server.rb`
- the Ruby-native direction is an in-process MCP boundary inside SketchUp rather than a Python-mediated socket ingress

**Must Not Own**

- long-term feature dispatch growth
- low-level SketchUp business logic
- socket lifecycle concerns that belong only to the current compatibility path
- duplicated cross-cutting result or error policy scattered per tool

### 4. Ruby Command or Use-Case Layer

**Responsibilities**

- expose stable execution entrypoints for capability behavior
- map tool calls to coherent Ruby-owned operations
- orchestrate shared services and SketchUp adapters

**Architectural Direction**

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

**Architectural Direction**

- move shared cross-cutting behavior out of individual transport or command implementations and into explicit platform-owned support modules

**Must Not Own**

- feature-specific behavior
- Python-facing MCP registration concerns

### 6. Ruby SketchUp Adapter Layer

**Responsibilities**

- isolate direct SketchUp API interaction
- provide reusable access to entities, bounds, materials, tags, components, export helpers, and model operations
- normalize SketchUp state into simple Ruby hashes, arrays, strings, numbers, and booleans before returning across the active client boundary

**Current Baseline**

- adapter-like behavior exists today, but much of it is embedded in `src/su_mcp/socket_server.rb`

**Must Not Own**

- MCP concerns
- Python transport semantics
- feature-policy decisions better expressed in higher-level commands

### 7. Python Compatibility Adapter Boot

**Responsibilities**

- create the FastMCP compatibility server
- expose transport mode selection for stdio or HTTP
- manage process lifecycle behavior such as startup ping and shutdown cleanup

**Current Baseline**

- implemented in `python/src/sketchup_mcp_server/server.py`
- remains the supported MCP entrypoint while the Ruby-native path is not yet the supported default

**Must Not Own**

- SketchUp business logic
- detailed per-tool transport duplication

### 8. Python Compatibility Invocation and Connection Layer

**Responsibilities**

- resolve the SketchUp bridge endpoint
- manage short-lived socket connections
- build structured bridge requests
- parse structured responses
- centralize transport failure handling for MCP-facing callers

**Current Baseline**

- already present in `SketchupConnection`, endpoint helpers, and `_call_bridge_tool`
- remains the compatibility transport layer for the current supported dual-runtime path only

**Must Not Own**

- Ruby business rules
- capability-specific validation duplicated from Ruby

### 9. Python Compatibility Tool Surface

**Responsibilities**

- expose MCP tools with clear names and argument surfaces
- stay close to a 1:1 mapping with Ruby command names unless there is a strong adapter reason not to
- expose only the compatibility surface needed while Ruby-native MCP is not yet the supported default

**Current Baseline**

- all tool definitions currently live in `python/src/sketchup_mcp_server/server.py`
- current Python-owned tool registration is transitional rather than the intended long-term canonical ownership model

**Architectural Direction**

- keep handlers thin and shrink Python-owned MCP surface as Ruby-native ownership expands

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

The flows below show both the current supported dual-runtime baseline and the target Ruby-native MCP architecture.

### Extension Startup Flow

```text
SketchUp
-> src/su_mcp.rb
-> src/su_mcp/extension.rb
-> src/su_mcp/main.rb
-> bridge configuration + socket server startup
-> extension menu/status controls
```

### Target Ruby-native Extension Startup Flow

```text
SketchUp
-> src/su_mcp.rb
-> src/su_mcp/extension.rb
-> src/su_mcp/main.rb
-> Ruby-native MCP bootstrap inside SketchUp
-> extension menu/status controls
```

### Current Supported MCP Tool Invocation Flow

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

### Target Ruby-native MCP Tool Invocation Flow

```text
MCP client
-> Ruby-native MCP transport inside SketchUp
-> Ruby MCP protocol handling and tool registration
-> Ruby command or use-case execution
-> SketchUp adapter calls and model interaction
-> Ruby-owned response shaping
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
-> Ruby-native MCP startup and tool-call verification when native-boundary concerns changed
-> package verification
```

### Current Baseline Architecture Diagram

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
- Ruby-native MCP validation: SketchUp-hosted MCP startup and tool-call verification as the Ruby-native path expands beyond the currently validated slice
```

### Target Ruby-native Architecture Diagram

```text
                           +----------------------+
                           |  External MCP Client |
                           +----------+-----------+
                                      |
                                      v
                         +------------+-------------+
                         | Ruby-native MCP Boundary |
                         | in SketchUp              |
                         +------------+-------------+
                                      |
                                      v
                         +------------+-------------+
                         | Ruby Command / Use-Case  |
                         | Execution                |
                         +------------+-------------+
                                      |
                    +-----------------+------------------+
                    |                                    |
                    v                                    v
          +---------+----------+              +----------+---------+
          | Shared Ruby Runtime|              | Ruby SketchUp      |
          | Infrastructure     |              | Adapters           |
          +---------+----------+              +----------+---------+
                    |                                    |
                    +-----------------+------------------+
                                      |
                                      v
                           +----------+----------+
                           | SketchUp Runtime    |
                           | Model + API         |
                           +---------------------+
```

## Key Architectural Decisions

### 1. Keep Ruby as the Source of Truth for SketchUp and Capability Behavior

**Decision**

SketchUp-facing behavior, geometry or model logic, entity traversal, mutation, behavior-defining command execution, and the target Ruby-native MCP protocol surface remain Ruby-owned.

**Reason**

The SketchUp API lives in Ruby. Keeping execution semantics and the canonical MCP surface close to that runtime prevents drift, avoids duplicated business rules, and preserves a clean compatibility boundary for any remaining Python adapter.

### 2. Keep Python Thin, Mechanical, and Transitional

**Decision**

Python remains responsible for the current supported MCP compatibility path, invocation, connection management, and boundary error mapping, not domain behavior. Canonical MCP ownership should move toward Ruby as the Ruby-native path becomes supported.

**Reason**

This preserves a clear runtime split for the supported path while keeping the adapter small enough to shrink cleanly as Ruby-native MCP becomes the target architecture.

### 3. Treat the Current Platform as the Baseline, Not a Temporary Placeholder

**Decision**

The HLD documents the existing dual-runtime implementation as the current platform baseline and frames seeded work as iterative refinement.

**Reason**

The repository already has working runtime, packaging, and quality structure. Describing the architecture as if it does not yet exist would be inaccurate and would weaken the HLD's usefulness.

### 4. Evolve by Extraction and Controlled Transition, Not Rewrite

**Decision**

Internal modularization should be achieved by extracting clearer layers from the current large files and by promoting validated Ruby-native seams deliberately, rather than by speculative wholesale rewrites.

**Reason**

The current baseline is real and useful, and recent host-process validation already proved a narrow Ruby-native host path. The design response should therefore be evolutionary and low-churn while still allowing the accepted target architecture to replace the current canonical MCP ownership model over time.

### 5. Preserve the Small SketchUp Loader Pattern

**Decision**

`src/su_mcp.rb` stays a registration entrypoint, with runtime behavior living under the support tree.

**Reason**

This matches SketchUp extension conventions, keeps packaging predictable, and avoids turning boot files into implementation hotspots.

### 6. Keep the Socket Bridge as the Current Supported Runtime Boundary

**Decision**

Python and Ruby continue to communicate through structured JSON messages over the local socket bridge for the current supported dual-runtime baseline.

**Reason**

The bridge already exists, fits the current supported path, and provides a clean contract boundary for contract testing and compatibility while Ruby-native MCP packaging and runtime foundations are being formalized.

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
| Current supported Ruby transport | `TCPServer` over local socket bridge | Accept Python bridge requests inside SketchUp for the supported dual-runtime baseline |
| Ruby packaging | RBZ packaging via Rake and Zip | Produce distributable SketchUp extension artifacts |
| Target Ruby-native MCP boundary | In-process Ruby MCP boundary inside SketchUp with Ruby-owned tool registration, protocol handling, and response shaping | Canonical MCP architecture inside the SketchUp runtime |
| MCP adapter runtime | Python 3.10+ with FastMCP | Current supported compatibility path for MCP tool exposure and process lifecycle |
| Python bridge client | short-lived socket client per call | Forward MCP tool calls to the SketchUp runtime for the current dual-runtime baseline |
| MCP process transport | stdio by default, optional HTTP | Support MCP-client subprocess launch and optional HTTP serving |
| Release/version alignment | `VERSION`, `pyproject.toml`, Ruby/Python version files, extension metadata | Keep cross-runtime version metadata synchronized |
| Ruby quality | RuboCop, Minitest-based task entrypoint | Maintain Ruby code quality and unit-test execution |
| Python quality | Ruff, Pytest | Maintain Python adapter quality and test execution |
| Contract verification direction | Python/Ruby request-response fixture and contract testing | Protect bridge compatibility as the surface grows |
| SketchUp-hosted validation direction | SketchUp runtime integration tests and governed `.skp` fixtures | Validate behaviors that cannot be proven outside real SketchUp semantics |

## Opened Questions

1. Which externally exposed transport modes should the first supported Ruby-native MCP path provide: stdio only, HTTP only, or both?
2. What loading and namespace-isolation posture should govern Ruby-native MCP dependencies in the SketchUp support tree?
3. What temporary coexistence rules should govern the current supported dual-runtime package and the emerging Ruby-native package during the transition?
4. How should the public MCP tool surface migrate so Ruby-native ownership becomes canonical without breaking client-facing tool names or argument shapes?
5. Should any Python compatibility adapter remain once Ruby-native MCP becomes the canonical tool host, or should the platform converge fully to the SketchUp-hosted runtime?
6. What SketchUp-hosted validation path should become mandatory once Ruby-native MCP owns more than the currently validated slice?
