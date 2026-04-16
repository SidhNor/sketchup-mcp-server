---
doc_type: adr
title: Prefer Ruby-Native MCP as the Target Runtime Architecture
status: proposed
category: platform_architecture
date: 2026-04-16
links:
  - ../hlds/hld-platform-architecture-and-repo-structure.md
  - ../sketchup-extension-development-guidance.md
  - ../ruby-platform-coding-guidelines.md
  - ../../rakelib/package.rake
  - ../../rakelib/release_support.rb
  - ../../README.md
  - ../../sketchup_mcp_guide.md
---

# Prefer Ruby-Native MCP as the Target Runtime Architecture

## Context

The current platform uses two runtimes:

- a Python MCP server that exposes the public MCP surface
- a Ruby SketchUp extension that owns SketchUp API usage and product behavior

The current request path is:

1. MCP client -> Python over `stdio` or Streamable HTTP
2. Python -> Ruby over a local TCP socket carrying newline-delimited JSON request and response payloads
3. Ruby -> SketchUp APIs inside the SketchUp host process

This design has worked as an adapter pattern, but it creates real architectural cost:

- every public tool change must stay aligned across Python tool definitions, the Ruby dispatcher, and the shared contract artifact
- the platform carries duplicate contract coverage and integration failure modes at the Python/Ruby boundary
- the Python layer owns little product behavior, so much of its value is protocol and transport convenience rather than domain ownership

Recent MCP ecosystem changes materially affect the decision space:

- the official MCP Ruby SDK now exists and is usable for server implementation
- the official MCP SDK registry currently lists Python as Tier 1 and Ruby as Tier 3, so Python remains the more mature MCP implementation surface
- MCP defines `stdio` and Streamable HTTP as first-class transports; `stdio` assumes the MCP client launches the server as a subprocess, while SketchUp extensions run inside an already-running GUI host process

SketchUp-specific constraints also matter:

- the extension runs inside SketchUp's embedded Ruby runtime, not a standalone Ruby process
- SketchUp extension guidance explicitly says gems do not work well in SketchUp, may freeze during installation, may require special build tools, and may conflict across extensions; the recommended approach is to copy gem code into the extension support folder and wrap it under the extension namespace
- the official Ruby MCP SDK exposes top-level `MCP::*` constants, which is convenient in normal Ruby applications but is a poor default fit for SketchUp's shared interpreter
- the current Ruby bridge is polled from SketchUp using a UI timer, which means transport overhead is not the only latency contributor
- MCP client support does not point uniformly in one direction:
  - Windsurf officially supports `stdio`, Streamable HTTP, and SSE for MCP servers
  - Codex officially documents remote MCP configuration through shared CLI and IDE configuration, and the public `openai/codex` configuration docs also show command-driven MCP server configuration in `~/.codex/config.toml`
  - neither source publishes transport benchmarks that would justify treating HTTP versus `stdio` overhead as the primary driver of this decision

This repository also has packaging facts that materially shape the decision:

- `package:rbz` currently packages a direct snapshot of `src/su_mcp.rb` plus files under `src/su_mcp/**`
- `package:verify` enforces the standard SketchUp layout of one root loader plus one `su_mcp/` support tree
- the current repo does not vendor runtime Ruby dependencies into the shipped extension

That means a Ruby-native MCP runtime cannot be adopted here as a normal runtime gem dependency. For this repo, it would need either:

- committed vendored source under the extension support tree, or
- build-time vendoring into a staging support tree before RBZ packaging

The key question is whether the platform should continue investing in the dual-runtime Python MCP plus Ruby bridge architecture, or move toward Ruby owning both MCP and SketchUp behavior directly.

## Decision

The platform should treat **Ruby-native MCP inside SketchUp, exposed over loopback Streamable HTTP, as the target runtime architecture**.

Python should no longer be treated as the long-term canonical MCP runtime. It may be retained temporarily or optionally as a **compatibility shim** only where `stdio` subprocess-based MCP client support is required.

This means:

- Ruby remains the source of truth for SketchUp behavior and becomes the source of truth for MCP tool registration and protocol handling
- the current Python-to-Ruby TCP bridge is a migration-stage compatibility mechanism, not the desired end-state architecture
- if Python is retained, it should be minimized to a thin adapter that proxies to the Ruby MCP server only for clients that require `stdio`
- new platform work should avoid deepening the Python/Ruby contract unless that work is explicitly part of a transition plan
- deprecating Python as a required runtime is conditional on proving that a vendored Ruby MCP stack can be packaged, loaded, and operated safely inside the real SketchUp host process
- for this repo, the preferred packaging posture is build-time vendoring into a staging tree rather than committing a large third-party runtime tree directly into `src/`
- for this repo, shipping a bare top-level `::MCP` namespace inside SketchUp is not treated as a safe production posture; the runtime should be isolated behind `SU_MCP`-owned loading and facade boundaries

## Repo-Specific Implementation Notes

The repo-specific packaging implications are concrete:

- [package.rake](../../rakelib/package.rake) builds the RBZ from files already present in the package tree; it does not install or resolve runtime gems during packaging
- [release_support.rb](../../rakelib/release_support.rb) currently enumerates package contents from `src/su_mcp.rb` and `src/su_mcp/**`, so any shipped Ruby MCP runtime would need to appear inside that packaged tree or a build staging tree that mirrors it
- the current `package:verify` rule should remain the integrity check for the shipped archive, even if the package source moves from `src/` to a staging directory during the build

The practical implication is that a Ruby-native MCP move is not just an architecture change. It is also a packaging-system change. At minimum it would require:

- a vendoring step before RBZ creation
- pruning of tests, docs, executables, and unused files from the vendored payload
- a namespace-isolation strategy so generic `MCP::*` constants are not exposed as a shared top-level dependency inside SketchUp
- a local `SU_MCP` facade so application code does not couple directly to third-party constants

## Options Considered

| Option | Description | Pros | Cons | Rationale for Selection |
| --- | --- | --- | --- | --- |
| Keep the current Python MCP plus Ruby bridge architecture | Keep Python as the canonical MCP server and continue using the existing raw TCP plus JSON bridge into Ruby. | Uses the most mature MCP runtime surface today; preserves current `stdio` and HTTP client compatibility; avoids near-term migration risk. | Preserves the Python/Ruby contract burden; keeps duplicate tool wiring and duplicate test surfaces; leaves Python owning protocol shape but not product behavior. | Not selected as the target architecture because it keeps the exact complexity under challenge and does not improve ownership alignment. |
| Replace Python with a Ruby sidecar process | Move MCP protocol handling from Python into a separate Ruby process while still keeping SketchUp communication as an inter-process bridge. | Reduces language diversity; may simplify release and contributor context if the team standardizes more heavily on Ruby. | Still keeps two processes and an IPC contract; does not solve the lifecycle mismatch between subprocess MCP and in-process SketchUp behavior; adds migration cost without enough architectural simplification. | Not selected because it changes the language but not the architecture that creates most of the current cost. |
| Move to Ruby-native MCP inside SketchUp over loopback Streamable HTTP | Run the MCP server directly from the SketchUp-hosted Ruby runtime and expose it over localhost HTTP, removing the separate Python MCP server from the canonical runtime path. | Removes the separate adapter runtime; aligns MCP ownership with SketchUp behavior ownership; eliminates the Python/Ruby bridge from the steady-state path; simplifies contract ownership. | Requires Ruby-side transport hardening and packaging work; does not provide a natural `stdio` subprocess story; depends on a less mature MCP SDK ecosystem than Python; requires vendoring and host-runtime validation before it is safe to ship; requires a safe answer for how vendored `MCP::*` code is isolated inside SketchUp. | Selected as the target end-state because it removes the unnecessary runtime boundary and best matches the product's real ownership model, but only after packaging and host-runtime validation succeed. |
| Hybrid target with Ruby-native MCP and optional Python `stdio` shim | Make Ruby-native MCP the canonical server, but keep a minimal Python adapter available for MCP clients that can only or primarily integrate through `stdio`. | Preserves a path for `stdio`-oriented clients during migration; allows Ruby to become canonical without forcing an all-at-once compatibility break; enables staged rollout and validation; better matches the current Codex and Windsurf client ecosystem than an immediate hard cutover. | Still carries some temporary dual-runtime complexity; risks the shim becoming permanent if not actively constrained; requires clear deprecation and ownership boundaries. | Selected as the preferred migration posture if `stdio` compatibility is still required during transition. It preserves client compatibility without keeping Python as the long-term canonical runtime. |

## Consequences

### Positives

- The architecture aligns with the existing ownership rule that SketchUp-facing behavior belongs in Ruby.
- The public MCP contract can be defined once in the Ruby runtime instead of being mirrored across Python and Ruby.
- Contract maintenance, duplicate tool wiring, and Python/Ruby integration drift are reduced.
- The end-state request path becomes simpler: MCP client -> Ruby MCP server -> SketchUp behavior.
- Direct Ruby ownership gives the platform a clearer path to packaging command behavior, metadata, and semantic tooling together.
- Streamable HTTP matches the lifecycle of an already-running SketchUp host process better than `stdio`.
- Client support realities do not invalidate the target architecture; they mainly justify a staged migration where Python remains optional for `stdio` compatibility.

### Negatives

- Ruby remains a less mature MCP ecosystem than Python at the current SDK tiering level.
- A Ruby-native server inside SketchUp must absorb more MCP transport, lifecycle, and security responsibility.
- Some MCP clients integrate most naturally through `stdio`, so removing Python entirely may reduce compatibility.
- SketchUp-hosted Ruby packaging is materially more constrained than a standalone Python environment and likely requires vendoring the Ruby MCP SDK and any usable dependencies into the extension support tree.
- Any migration will still require a temporary period where both architectures are supported.
- The repo's current RBZ pipeline will need to grow from simple source-tree zipping into a reproducible vendoring-and-staging flow if Ruby-native MCP is adopted.

### Risks

- The official Ruby SDK may lag Python on protocol completeness, bug fixes, or operational ergonomics.
- Embedded SketchUp Ruby compatibility may differ from standalone Ruby expectations and must be validated in the actual host.
- Vendoring the Ruby MCP stack into an RBZ-compatible support tree may prove significantly heavier than anticipated because SketchUp guidance discourages normal gem installation and extensions run in a shared interpreter.
- If vendored code exposes top-level `::MCP` constants in-process, it may create cross-extension collision risk in SketchUp's shared Ruby interpreter.
- A local HTTP server inside SketchUp must be locked down correctly, especially loopback binding and request-origin protections.
- If the migration keeps the current UI-timer polling model, some expected latency gains may not materialize immediately.
- Maintaining both a Ruby-native server and a Python shim for too long could preserve most of the current complexity instead of retiring it.
- Codex and Windsurf support both remote and local MCP patterns, but neither provides evidence that transport overhead should dominate this decision; choosing on raw transport intuition rather than host-runtime fit would be a category error.

### Gating Conditions

The following conditions must be satisfied before Python can stop being a required runtime:

- a vendored Ruby MCP implementation can be packaged into the SketchUp extension support tree without runtime gem installation
- a reproducible vendoring pipeline exists, preferably using a build staging tree rather than relying on ad hoc manual copying into `src/`
- the vendored payload is pruned and package-controlled so tests, docs, binaries, and unused files are not shipped accidentally
- namespace isolation is proven so the shipped extension does not expose new shared top-level constants such as bare `::MCP`
- the vendored Ruby MCP implementation loads and runs correctly inside the supported SketchUp host versions
- repeated extension reload and multi-extension sessions do not show namespace, load-order, or startup conflicts
- loopback HTTP binding, origin validation, and any required authentication posture are validated for the in-process server
- startup time, idle memory, and representative request latency are acceptable with the vendored runtime loaded
- at least the primary target MCP clients are verified against the Ruby-native server, with explicit confirmation of whether a Python `stdio` shim is still required

## Related Decisions

- The current platform architecture direction is documented in [`hld-platform-architecture-and-repo-structure.md`](../hlds/hld-platform-architecture-and-repo-structure.md), which describes the existing dual-runtime design and bridge boundary.
- SketchUp packaging and embedded Ruby constraints are documented in [`sketchup-extension-development-guidance.md`](../sketchup-extension-development-guidance.md).
- Ruby layering and behavior-ownership guidance remain in force from [`ruby-platform-coding-guidelines.md`](../ruby-platform-coding-guidelines.md).
- A follow-on implementation decision is still required to choose one of two migration postures:
  - retain Python only as an optional `stdio` compatibility shim
  - remove Python entirely once the client set is proven compatible with Ruby-native Streamable HTTP
- A follow-on packaging decision may be required if vendoring the Ruby MCP SDK and its dependencies materially affects RBZ packaging, extension startup, or support-version scope.
