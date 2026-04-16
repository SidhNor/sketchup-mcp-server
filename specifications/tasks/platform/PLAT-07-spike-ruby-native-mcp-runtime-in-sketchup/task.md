# Task: PLAT-07 Spike Ruby-Native MCP Runtime In SketchUp
**Task ID**: `PLAT-07`
**Title**: `Spike Ruby-Native MCP Runtime In SketchUp`
**Status**: `planned`
**Priority**: `P0`
**Date**: `2026-04-16`

## Linked HLD

- [Platform Architecture and Repo Structure](specifications/hlds/hld-platform-architecture-and-repo-structure.md)
- [ADR: Prefer Ruby-Native MCP as the Target Runtime Architecture](specifications/adrs/2026-04-16-ruby-native-mcp-target-runtime.md)

## Problem Statement

The repo currently runs MCP in Python and forwards requests into SketchUp Ruby over a local TCP bridge. That shape is functional but expensive to evolve because tool wiring, contracts, and integration behavior must stay aligned across two runtimes.

Recent analysis shows that a Ruby-native MCP server inside SketchUp is technically plausible, but the practical risks are specific to this repo and host environment: SketchUp's embedded Ruby runtime, RBZ packaging constraints, vendoring requirements, top-level namespace safety, and direct client connectivity. In local developer mode, migration safety is not the main constraint. The immediate need is to replace debate with evidence by building a minimal end-to-end spike that proves or disproves the approach in the real host.

## Goals

- prove whether SketchUp can host a minimal Ruby-native MCP server over direct HTTP in the current repo
- validate a viable local dependency posture for the Ruby MCP SDK under SketchUp's embedded Ruby constraints
- expose `get_scene_info` as the representative existing Ruby-owned tool path for the spike
- produce direct evidence on client connectivity, runtime behavior, and repo-specific packaging friction before any broader migration work is approved

## Acceptance Criteria

```gherkin
Scenario: Ruby-native MCP can serve a minimal vertical slice from inside SketchUp
  Given the repo currently exposes MCP through Python and forwards requests into SketchUp Ruby
  When the spike is executed in local developer mode
  Then SketchUp hosts a Ruby-native MCP server over direct HTTP from the SketchUp host process
  And `ping` plus `get_scene_info` are exercised end to end

Scenario: Host access is validated for the active developer environment
  Given SketchUp may run on Windows or macOS and clients may run from the same host shell or from WSL
  When the spike is validated in the active environment
  Then the chosen bind host and client target are documented explicitly
  And the acceptance proof uses the correct access path for that environment rather than assuming localhost always works

Scenario: Dependency and namespace posture are tested rather than assumed
  Given SketchUp does not support normal runtime gem installation as a safe extension pattern
  When the spike evaluates the Ruby MCP SDK in the repo
  Then the spike uses a concrete vendoring approach suitable for local development
  And it records whether top-level MCP namespace exposure is acceptable, tolerable only for the spike, or must be isolated immediately

Scenario: The spike produces a go or no-go outcome for further platform work
  Given the long-term platform direction is under active review
  When the spike results are documented
  Then the outcome states whether Ruby-native MCP remains viable for this repo
  And it identifies the specific repo-level blockers, if any, that would keep Python required
```

## Non-Goals

- completing a production-ready migration away from the Python MCP adapter
- finalizing the long-term vendoring, packaging, or release architecture for a shipped RBZ
- replacing the full current tool catalog with Ruby-native MCP endpoints

## Business Constraints

- the task is a decision-support spike, so speed of learning matters more than migration polish
- local developer mode is the intended operating posture, so reinstall or restart friction is acceptable during the spike
- the output must create a credible basis for a later architectural decision instead of another purely theoretical comparison

## Technical Constraints

- SketchUp-facing behavior and any behavior-defining MCP tool implementation must remain in Ruby
- the spike must respect SketchUp embedded-runtime realities and cannot depend on runtime gem installation inside SketchUp
- the spike must test the repo's actual packaging and loading constraints closely enough to expose whether staged vendoring or direct local vendoring is required
- the spike must treat direct HTTP from the SketchUp host process as the transport under test, not a new Python-mediated bridge path
- the spike must validate the host and client access posture appropriate to the active environment:
  - same-host Windows shell -> Windows SketchUp: localhost is acceptable
  - same-host macOS shell -> macOS SketchUp: localhost is acceptable
  - WSL shell -> Windows SketchUp: Windows host IP may be required instead of localhost

## Dependencies

- `PLAT-01`
- `PLAT-02`
- `PLAT-03`
- `specifications/adrs/2026-04-16-ruby-native-mcp-target-runtime.md`

## Relationships

- informs a future packaging decision for vendored Ruby MCP runtime support
- informs any future decision to demote or remove the Python MCP adapter
- complements `PLAT-06` by testing real SketchUp-hosted runtime behavior, but with a narrower architecture-focused spike scope

## Related Technical Plan

- [Technical Plan](./plan.md)

## Success Metrics

- a local SketchUp-hosted Ruby MCP spike is runnable in the repo and proves or disproves at least one end-to-end MCP path without Python in the serving path
- `get_scene_info` is exposed through the Ruby-native MCP spike without inventing new SketchUp-side behavior for the proof
- the spike yields an explicit statement on dependency posture, including whether local vendoring is enough for a spike and what production packaging work would still remain
- the spike produces a concrete go, conditional-go, or no-go recommendation for continuing Ruby-native MCP work in this repo
