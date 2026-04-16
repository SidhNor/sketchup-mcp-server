# Task: PLAT-10 Migrate Current Tool Surface To Ruby-Native MCP And Retire Spike
**Task ID**: `PLAT-10`
**Title**: `Migrate Current Tool Surface To Ruby-Native MCP And Retire Spike`
**Status**: `completed`
**Priority**: `P0`
**Date**: `2026-04-16`

## Linked HLD

- [Platform Architecture and Repo Structure](../../../hlds/hld-platform-architecture-and-repo-structure.md)
- [ADR: Prefer Ruby-Native MCP as the Target Runtime Architecture](../../../adrs/2026-04-16-ruby-native-mcp-target-runtime.md)
- [PLAT-07 Spike Ruby-Native MCP Runtime In SketchUp](../PLAT-07-spike-ruby-native-mcp-runtime-in-sketchup/task.md)

## Problem Statement

The accepted architecture direction now points to Ruby-native MCP inside SketchUp as the canonical runtime, but the current public MCP tool surface is still exposed from Python while the Ruby-native implementation remains confined to a narrow experimental spike slice. That leaves the repository in a mixed state where the architecture target is known, the host runtime path is proven, and the packaging foundation can be built, but the actual public tool surface still belongs to the old runtime ownership model. The next task must move the current exposed MCP tool surface toward Ruby-native ownership while collapsing the experimental spike posture so the repo does not carry a permanent parallel “real runtime plus spike runtime” shape.

## Goals

- move the current exposed MCP tool surface toward Ruby-native MCP ownership inside SketchUp
- reduce Python to an explicitly transitional compatibility role during the migration period
- retire or promote the current spike-only seams, labels, and menu affordances once the Ruby-native path becomes the canonical surface

## Acceptance Criteria

```gherkin
Scenario: Current public MCP tool exposure is owned by the Ruby-native runtime
  Given the repository currently exposes its public MCP surface primarily through Python-defined tool registration
  When the MCP tool surface is reviewed after this task is complete
  Then the current exposed tool catalog is served from the Ruby-native MCP runtime inside SketchUp
  And Ruby becomes the canonical owner of MCP tool registration for that migrated surface

Scenario: Public client-facing behavior remains stable through the migration
  Given MCP clients already depend on the current public tool names and expected behavior
  When representative tools are exercised after the migration
  Then public tool names remain behaviorally compatible unless an intentional interface change is scoped separately
  And the migrated Ruby-native path preserves the expected client-facing response behavior for the supported tool surface

Scenario: Python is constrained to compatibility duties during transition
  Given Python remains present during the migration period
  When the runtime ownership model is reviewed after this task is complete
  Then Python no longer acts as the canonical owner of the migrated tool surface
  And any remaining Python role is explicit, bounded, and transitional

Scenario: Spike-only feature-surface and UX seams are retired
  Given the current Ruby-native implementation still contains experimental spike naming and menu affordances
  When the runtime and SketchUp-facing controls are reviewed after this task is complete
  Then spike-only feature-surface seams are either promoted into supported runtime structure or removed
  And the repository no longer depends on a permanent parallel spike subtree to expose the migrated MCP surface

Scenario: Migration does not silently preserve transitional packaging behavior as a permanent commitment
  Given PLAT-09 establishes temporary coexistence between current packaging and the Ruby-native path
  When the migrated runtime is reviewed after this task is complete
  Then the transitional compatibility posture remains explicit
  And the task outcome does not harden temporary spike-era coexistence as the implied long-term end state
```

## Non-Goals

- inventing new product-capability behavior beyond migrating the current exposed tool surface
- removing Python entirely from the repo
- finalizing the permanent post-transition packaging shape after Python removal
- expanding scope into unrelated Ruby runtime cleanup outside the migrated MCP surface and spike-retirement boundary

## Business Constraints

- the task must deliver visible architectural progress, not only internal cleanup
- the migration must keep the current supported tool surface understandable to existing MCP clients during transition
- spike cleanup should reduce confusion and accidental parallel-runtime drift rather than hide unresolved ownership questions

## Technical Constraints

- the task depends on a repo-owned Ruby-native packaging and runtime foundation being in place first
- SketchUp-facing behavior and canonical MCP ownership must remain in Ruby
- cross-runtime compatibility behavior must stay explicit while Python still exists as a transition path
- the migrated surface must continue to fit the environment-aware host and bind posture proven during PLAT-07

## Dependencies

- `PLAT-09`
- `PLAT-07`
- `specifications/adrs/2026-04-16-ruby-native-mcp-target-runtime.md`

## Relationships

- follows `PLAT-09`
- informs the eventual removal or optional-only retention of Python as a compatibility shim
- retires the experimental spike posture created during `PLAT-07`

## Related Technical Plan

- [Technical Plan](./plan.md)

## Success Metrics

- the current public MCP tool surface is canonically exposed from the Ruby-native runtime rather than Python-defined ownership
- Python’s remaining role is clearly transitional and narrower than the pre-migration baseline
- spike-only files, labels, and menus are no longer left as a parallel permanent runtime posture

## Implementation Notes

- Added a Ruby-owned native tool catalog in [mcp_runtime_loader.rb](./../../../src/su_mcp/mcp_runtime_loader.rb) so the canonical native runtime exposes the migrated tool inventory from one Ruby definition source instead of a hardcoded two-tool loader path.
- Expanded [mcp_runtime_facade.rb](./../../../src/su_mcp/mcp_runtime_facade.rb) so the native runtime dispatches through [tool_dispatcher.rb](./../../../src/su_mcp/tool_dispatcher.rb) and the same Ruby command ownership model already used by the shrinking legacy socket path.
- Added [runtime_command_factory.rb](./../../../src/su_mcp/runtime_command_factory.rb) to share collaborator construction between the native runtime facade and the legacy socket server, preserving Ruby-side behavior ownership while reducing duplicate assembly logic.
- Extracted shared developer behavior into [developer_commands.rb](./../../../src/su_mcp/developer_commands.rb) so `eval_ruby` is no longer unique to [socket_server.rb](./../../../src/su_mcp/socket_server.rb) during the transition.
- Promoted the SketchUp-facing menu and status wording in [main.rb](./../../../src/su_mcp/main.rb) from `Experimental MCP Runtime` to `Native MCP Runtime`.
- Repositioned the Python FastMCP app wording in [python/src/sketchup_mcp_server/app.py](./../../../python/src/sketchup_mcp_server/app.py) as an explicit compatibility surface.

## Validation Notes

- Passed focused Ruby runtime tests for the migrated native catalog and shared command seams:
  - `bundle exec ruby -Itest test/mcp_runtime_loader_test.rb`
  - `bundle exec ruby -Itest test/mcp_runtime_facade_test.rb`
  - `bundle exec ruby -Itest test/mcp_runtime_server_test.rb`
  - `bundle exec ruby -Itest test/socket_server_test.rb`
  - `bundle exec ruby -Itest test/socket_server_adapter_test.rb`
  - `bundle exec ruby -Itest test/mcp_runtime_main_integration_test.rb`
- Passed focused Python compatibility validation:
  - `uv run pytest python/tests/test_app.py`
- Passed broader local validation:
  - `bundle exec rake ruby:lint`
  - `bundle exec rake ruby:test`
  - `bundle exec rake python:lint`
  - `bundle exec rake python:test`
  - `bundle exec rake package:verify:all`
- Bridge contract suites were not rerun because this task did not change the public Python-to-Ruby socket bridge contract shape.
- Manual SketchUp-hosted validation and real MCP-client validation still remain required to confirm the migrated native runtime in the live host process.
