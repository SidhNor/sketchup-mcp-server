# Task: PLAT-09 Build Ruby-Native MCP Packaging And Runtime Foundations
**Task ID**: `PLAT-09`
**Title**: `Build Ruby-Native MCP Packaging And Runtime Foundations`
**Status**: `completed`
**Priority**: `P0`
**Date**: `2026-04-16`

## Linked HLD

- [Platform Architecture and Repo Structure](../../../hlds/hld-platform-architecture-and-repo-structure.md)
- [ADR: Prefer Ruby-Native MCP as the Target Runtime Architecture](../../../adrs/2026-04-16-ruby-native-mcp-target-runtime.md)
- [PLAT-07 Spike Ruby-Native MCP Runtime In SketchUp](../PLAT-07-spike-ruby-native-mcp-runtime-in-sketchup/task.md)

## Problem Statement

PLAT-07 proved that a Ruby-native MCP server can run inside SketchUp and serve a real narrow slice from the host process, but the repo still lacks the foundations required to treat that path as a supported platform capability. The current Ruby-native path depends on manual staged packaging, temporary vendoring posture, experimental runtime seams, and undocumented assumptions about load order and namespace exposure. That leaves the architecture decision validated in principle but not reproducible in the repo’s normal build and validation flow. The next step is to convert the spike’s packaging and runtime bootstrap into a deterministic, repo-owned foundation so later tool-surface migration does not have to keep rediscovering packaging, loader, and runtime contract details.

## Goals

- create a deterministic repo-owned staged packaging path for the Ruby-native MCP runtime
- promote the spike loader and runtime seams into a supported runtime foundation with explicit loading and facade boundaries
- make the Ruby-native packaging and runtime path executable in normal repository validation without treating the experimental spike procedure as the long-term workflow

## Acceptance Criteria

```gherkin
Scenario: Ruby-native MCP packaging is reproducible through a repo-owned build path
  Given the PLAT-07 spike required manual staged RBZ assembly
  When the Ruby-native packaging path is exercised after this task is complete
  Then the artifact is produced through a repo-owned packaging task rather than ad hoc shell staging
  And the staged runtime layout required for the Ruby-native path is reproduced deterministically

Scenario: Runtime foundations are promoted out of the spike posture
  Given the current Ruby-native path still uses spike-labeled runtime seams and temporary loading assumptions
  When the runtime structure is reviewed after this task is complete
  Then the loader, facade, and runtime bootstrap boundaries are explicit enough to support broader Ruby-native MCP work
  And production-facing runtime behavior no longer depends on undocumented spike-only bootstrap assumptions

Scenario: Vendoring and loading posture are explicit and bounded
  Given SketchUp cannot depend on runtime gem installation as a supported extension pattern
  When the Ruby-native runtime support tree is reviewed after this task is complete
  Then the vendoring or staging rules for required Ruby MCP dependencies are explicit and reproducible
  And the near-term namespace and loading posture is defined clearly enough that follow-on migration work does not need to reinvent it

Scenario: Temporary coexistence with the current packaging path is controlled
  Given the current shipped path still includes the Python-based MCP adapter
  When packaging and validation behavior are reviewed after this task is complete
  Then the normal RBZ packaging path and the Ruby-native staged packaging path can coexist without ambiguous ownership
  And that coexistence is documented as transitional rather than a permanent platform commitment

Scenario: Repository validation includes the Ruby-native foundation path
  Given the PLAT-07 spike proved host viability but not repo-owned automation
  When the normal repository validation flow is reviewed after this task is complete
  Then the Ruby-native packaging or runtime foundation path is exercised through repo-owned validation entrypoints
  And packaging regressions in that path are visible without relying on manual spike reconstruction
```

## Non-Goals

- migrating the current public MCP tool surface to Ruby-native ownership
- removing Python as the supported compatibility path
- finalizing the permanent post-Python packaging simplification
- broad SketchUp-hosted always-on CI execution beyond what is needed to validate the new packaging and runtime foundation

## Business Constraints

- the task must convert the PLAT-07 learning into a repeatable platform capability rather than another one-off spike procedure
- the resulting packaging path must stay clearly transitional where coexistence with the Python path remains necessary
- the task should reduce migration risk for the next Ruby-native task rather than broadening feature scope directly

## Technical Constraints

- SketchUp-facing behavior remains owned in Ruby
- the task must not depend on runtime gem installation inside SketchUp
- the Ruby-native runtime foundation must fit the repo’s RBZ packaging rules and extension support-tree expectations
- the task must preserve the current supported Python path while coexistence remains required
- the task must keep host and bind configuration explicit enough to preserve the environment-aware posture proven in PLAT-07

## Dependencies

- `PLAT-07`
- `specifications/adrs/2026-04-16-ruby-native-mcp-target-runtime.md`

## Relationships

- blocks `PLAT-10`
- informs the eventual removal of Python as a required runtime
- informs the long-term packaging decision for the Ruby-native runtime after the transitional coexistence period ends

## Related Technical Plan

- [Technical Plan](./plan.md)

## Success Metrics

- the repo can produce the Ruby-native MCP artifact through a deterministic repo-owned path rather than manual spike assembly
- the runtime loader and facade contract are explicit enough that follow-on Ruby-native migration work can build on them directly
- repository validation makes the Ruby-native foundation path visible without treating manual archive inspection as the normal control

## Implementation Notes

- Added a committed staged-runtime manifest at [config/runtime_package_manifest.json](./../../../config/runtime_package_manifest.json) with pinned gem versions, checksums, and runtime-asset retention rules for the Ruby-native package path.
- Added shared packaging support under [rakelib/release_support/](./../../../rakelib/release_support/) for manifest loading, vendored gem staging, staged package assembly, and staged runtime verification.
- Extended [package.rake](./../../../rakelib/package.rake), [version.rake](./../../../rakelib/version.rake), [Rakefile](./../../../Rakefile), and [ci.yml](./../../../.github/workflows/ci.yml) so the standard RBZ and the staged Ruby-native RBZ are both built and verified through repo-owned tasks and release preparation.
- Promoted the runtime seams out of the spike posture by replacing `mcp_spike_*` internals with [mcp_runtime_config.rb](./../../../src/su_mcp/mcp_runtime_config.rb), [mcp_runtime_loader.rb](./../../../src/su_mcp/mcp_runtime_loader.rb), [mcp_runtime_http_backend.rb](./../../../src/su_mcp/mcp_runtime_http_backend.rb), [mcp_runtime_server.rb](./../../../src/su_mcp/mcp_runtime_server.rb), and [mcp_runtime_facade.rb](./../../../src/su_mcp/mcp_runtime_facade.rb), then rewired [main.rb](./../../../src/su_mcp/main.rb) to those neutral seams.
- Kept the experimental SketchUp menu and status UX explicitly transitional while preserving the current Python MCP adapter as the supported compatibility path.

## Validation Notes

- Passed focused runtime and packaging seam tests for the new manifest, staging, verification, and promoted runtime files.
- Passed `bundle exec rake package:verify`
- Passed `bundle exec rake package:verify:ruby_native`
- Passed `bundle exec rake package:verify:all`
- The staged package verifier now runs an isolated staged-runtime load test so archive-shape validation also proves the pruned runtime can boot outside the repo development load path.
- Repo-wide `ruby:test` passed once unrelated untracked modeling and joinery files already present in the worktree were temporarily moved out of the tree and then restored.
- The PLAT-09 loader lint issue was resolved by updating [.rubocop.yml](./../../../.rubocop.yml) for the renamed runtime loader path. Remaining repo-wide lint noise comes from unrelated untracked modeling and joinery files outside PLAT-09 scope.
- Manual SketchUp-hosted validation of the staged Ruby-native RBZ was not run in this implementation session and remains the main remaining confidence gap.
