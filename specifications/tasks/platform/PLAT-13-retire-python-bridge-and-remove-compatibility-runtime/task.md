# Task: PLAT-13 Retire Python Bridge And Remove Compatibility Runtime
**Task ID**: `PLAT-13`
**Title**: `Retire Python Bridge And Remove Compatibility Runtime`
**Status**: `planned`
**Priority**: `P0`
**Date**: `2026-04-16`

## Linked HLD

- [Platform Architecture and Repo Structure](../../../hlds/hld-platform-architecture-and-repo-structure.md)
- [ADR: Prefer Ruby-Native MCP as the Target Runtime Architecture](../../../adrs/2026-04-16-ruby-native-mcp-target-runtime.md)
- [PLAT-10 Migrate Current Tool Surface To Ruby-Native MCP And Retire Spike](../PLAT-10-migrate-current-tool-surface-to-ruby-native-mcp-and-retire-spike/task.md)

## Problem Statement

`PLAT-10` is intentionally scoped to make Ruby-native MCP the canonical public tool host while shrinking Python to a clearly transitional compatibility role. If that migration completes and the native runtime is validated against the real target client set, keeping the Python MCP adapter and local socket bridge in the repository no longer buys enough value to justify their architectural, packaging, documentation, CI, and maintenance overhead. Without a dedicated cleanup task, the repo could remain stuck in a “transition completed but compatibility runtime still present” posture where Ruby is canonical in practice but Python still lingers across docs, agents, build tooling, dependency manifests, release surfaces, tests, and architecture documents.

## Goals

- remove the Python MCP adapter and Python-to-Ruby bridge from the supported platform once Ruby-native MCP has been validated as sufficient for the target client set
- normalize repository documentation, agent guidance, specifications, CI, dependencies, packaging, and release posture around the single-runtime Ruby-native architecture
- remove the repo-owned Python project shape rather than preserving a dormant Python runtime package after the bridge is retired
- leave the repository in a coherent post-transition state where Python is no longer implied as a required platform runtime

## Acceptance Criteria

```gherkin
Scenario: Python compatibility runtime is removed after native validation
  Given `PLAT-10` has made Ruby-native MCP the canonical public tool host
  And representative native-runtime validation has confirmed that the supported client set does not require the Python compatibility runtime
  When the runtime implementation is reviewed after this task is complete
  Then the Python MCP adapter and the Python-to-Ruby socket bridge are no longer part of the supported runtime path
  And the repository no longer treats Python as a required MCP compatibility layer

Scenario: Repository metadata and automation reflect the single-runtime posture
  Given the current repository still contains Python-specific packaging, dependency, CI, and release surfaces from the migration era
  When platform automation and metadata are reviewed after this task is complete
  Then Python-only runtime packaging, dependency, and CI responsibilities that were kept solely for the compatibility runtime are removed or rewritten for the Ruby-native posture
  And the remaining automation, package metadata, and release expectations no longer imply a required dual-runtime platform

Scenario: Release automation does not preserve a dormant Python project
  Given the repo may still choose to use `python-semantic-release` for release automation after the runtime cleanup
  When the retained release-tooling posture is reviewed after this task is complete
  Then any surviving Python usage is limited to CI-owned release automation only
  And the repo no longer keeps a project-owned Python runtime package, runtime source tree, or Python app metadata solely to support release versioning

Scenario: Documentation and guidance no longer describe the bridge as current architecture
  Given repository-facing guidance currently documents a dual-runtime baseline and migration transition
  When the README, agent guidance, HLDs, ADR-linked follow-up docs, setup instructions, and related platform documents are reviewed after this task is complete
  Then they describe Ruby-native MCP inside SketchUp as the supported runtime architecture
  And obsolete Python-bridge setup, compatibility caveats, and maintenance guidance are removed or explicitly archived

Scenario: Live project-description documents reflect the supported post-transition system
  Given the repository contains project-description artifacts beyond the platform README, including product guidance, HLDs, PRDs, and task-set indexes
  When the live descriptive documents are reviewed after this task is complete
  Then current-state documents that describe the supported architecture, setup, workflows, or product-facing platform shape no longer present Python or the socket bridge as part of the supported system
  And historical planning artifacts are either left clearly historical or explicitly archived rather than silently treated as current architecture guidance

Scenario: Removal remains bounded to post-transition cleanup rather than new capability work
  Given this task exists to finish the runtime transition after `PLAT-10` validation succeeds
  When the completed change set is reviewed
  Then the work is traceable to retiring Python compatibility assets and normalizing the repo around the native runtime
  And unrelated product-capability expansion or Ruby-side redesign is left outside the task boundary unless explicitly required for the cleanup
```

## Non-Goals

- migrating the tool surface to Ruby-native MCP in the first place
- preserving Python as an optional long-term shim once the validated client set no longer needs it
- redesigning Ruby command behavior beyond what is required to remove bridge-era compatibility seams
- introducing new product capabilities unrelated to runtime retirement
- committing to a specific non-Python replacement for semantic-release if CI-owned `python-semantic-release` remains acceptable

## Business Constraints

- the task should only proceed once native-runtime validation demonstrates that the supported client set no longer needs the Python compatibility path
- the cleanup must leave contributors and users with a clearer repo story, not a silent breaking change hidden behind stale docs
- architecture, setup, and release guidance must converge on one supported runtime posture rather than imply that both remain first-class
- if any compatibility clients are intentionally dropped as part of the cleanup, that change must be made explicit in the resulting docs and release posture
- if Python is retained for release automation only, contributors should not need a repo-local Python runtime setup for normal development, testing, or package verification
- live project-description documents must be updated enough that new contributors do not learn an obsolete dual-runtime architecture from current-facing repo materials

## Technical Constraints

- Ruby remains the source of truth for SketchUp behavior, MCP tool ownership, and the supported runtime path
- the task must remove Python runtime ownership cleanly across code, tests, CI, package metadata, dependency manifests, release helpers, and repo guidance rather than leaving dead compatibility scaffolding behind
- shared bridge contract artifacts and bridge-specific tests should be removed, rewritten, or explicitly archived in line with the removal of the Python/Ruby socket boundary
- HLDs, ADR-adjacent task references, AGENTS guidance, README/setup docs, and packaging metadata must be updated so the repo no longer documents the bridge as the live supported architecture
- live project-description artifacts such as the root README, contributor guidance, product/runtime guide docs, current HLDs, current PRDs, and task indexes must be reviewed and updated where they describe the supported platform shape; historical task plans, summaries, and signals may remain historical records if they are not presented as current architecture guidance
- the resulting repo should still preserve a valid SketchUp extension package and a coherent native-runtime validation story after Python removal
- if `python-semantic-release` remains, it should be configured through CI-owned standalone release configuration rather than by keeping a repo Python package manifest, Python runtime source tree, or Python app version file
- Python-specific developer tasks, lockfiles, and environment bootstrap should be removed unless they are strictly required by the chosen release automation path

## Dependencies

- `PLAT-10`
- `specifications/adrs/2026-04-16-ruby-native-mcp-target-runtime.md`

## Relationships

- follows `PLAT-10`
- finalizes the post-transition packaging shape that `PLAT-10` explicitly leaves out of scope
- informs `PLAT-12` and any later structure cleanup by removing the legacy Python runtime footprint first

## Related Technical Plan

- [Technical Plan](./plan.md)

## Success Metrics

- the repository no longer contains a supported Python MCP runtime or Python-to-Ruby bridge path
- setup docs, AGENTS guidance, HLDs, and release-facing docs consistently describe a single supported Ruby-native runtime
- live project-description documents no longer teach the retired dual-runtime bridge architecture as the current supported system
- CI, package metadata, dependency manifests, and test ownership no longer carry Python compatibility-runtime obligations that are obsolete after native validation
- if Python remains anywhere in the repo, it is clearly limited to CI release automation and does not require preserving a repo-owned Python project
