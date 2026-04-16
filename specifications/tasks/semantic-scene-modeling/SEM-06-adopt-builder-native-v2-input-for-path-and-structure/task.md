# Task: SEM-06 Adopt Builder-Native V2 Input for Path and Structure
**Task ID**: `SEM-06`
**Title**: `Adopt Builder-Native V2 Input for Path and Structure`
**Status**: `draft`
**Priority**: `P0`
**Date**: `2026-04-16`

## Linked HLD

- [Semantic Scene Modeling](../../../hlds/hld-semantic-scene-modeling.md)

## Problem Statement

`SEM-05` proved that the sectioned semantic `v2` direction can survive the live Ruby seam for `path` and `structure`, but the current implementation still relies on command-level translation from the sectioned `v2` request into older builder-facing payloads. That translation was acceptable for a bounded spike, but it should not become the long-term architecture for the first proven families.

This task exists to make the chosen `v2` direction real for `path` and `structure` by moving those families to builder-native `v2` input while preserving the working lifecycle and hosting behavior already validated in the spike. Completing this task turns the spike into real architecture and reduces the risk that the Ruby seam remains a permanent compatibility layer for the families already chosen as the direction-setting cases.

## Goals

- move `path` and `structure` from command-level `v2` translation to builder-native `v2` input
- preserve the proven `SEM-05` lifecycle and hosting behaviors for the two migrated families
- reduce family-specific translation logic in the semantic command seam for `path` and `structure`

## Acceptance Criteria

```gherkin
Scenario: path and structure builders accept the sectioned v2 contract natively
  Given the semantic capability has chosen the sectioned `v2` direction
  When a valid `path` or `structure` request is executed through `create_site_element`
  Then the selected builder consumes the sectioned `v2` family input without requiring family-specific command-level translation into the older builder payload shape

Scenario: proven v2 behaviors remain valid for path and structure after builder-native adoption
  Given `SEM-05` proved bounded `v2` support for `path` and `structure`
  When retained adoption, bounded replace-preserve-identity, and hosting-aware create flows are exercised for those families
  Then the migrated builders preserve the same managed-object identity, metadata, and structured-result behavior required by the current semantic contract

Scenario: migration does not thicken the Python or bridge boundary
  Given the semantic contract evolution is owned in Ruby
  When `path` and `structure` are migrated to builder-native `v2` input
  Then the Python MCP adapter remains thin
  And the task does not require public bridge-contract rollout solely to complete the Ruby-side builder adoption

Scenario: family-specific translation debt is reduced for the migrated families
  Given the command seam currently performs transitional `v2` translation for spike-proven families
  When this task is complete
  Then `path` and `structure` no longer depend on that family-specific translation path as their primary execution route
  And any remaining compatibility glue is narrow enough to be clearly transitional
```

## Non-Goals

- promoting the sectioned `v2` shape as a finalized public bridge contract in this task
- migrating every semantic family to builder-native `v2` input
- introducing composition primitives or multipart feature assembly behavior
- expanding next-wave semantic families such as `seat`, `water_feature_proxy`, or `terrain_patch`

## Business Constraints

- the task must make the `SEM-05` spike useful as real architecture rather than leaving it as stranded compatibility code
- the task must preserve the compact semantic creation surface rather than expanding into multiple overlapping creation tools
- the task must keep the chosen direction practical for a single-client repo without adding migration ceremony for its own sake

## Technical Constraints

- Ruby remains the owner of semantic interpretation, lifecycle handling, hosting handling, and builder routing
- Python and the bridge boundary should remain unchanged unless a concrete technical need emerges during implementation
- the task must keep `path` and `structure` aligned with the section boundaries established by the updated HLD
- command-level translation should be reduced for the migrated families rather than reintroduced under a different shape

## Dependencies

- `SEM-02`
- `SEM-03`
- `SEM-05`

## Relationships

- turns the bounded `SEM-05` proof into builder-native architecture for the first proven families
- establishes the adoption pattern that later `v2` family tasks should follow

## Related Technical Plan

- none yet

## Success Metrics

- `path` and `structure` are the first semantic families that accept sectioned `v2` input natively at the builder layer
- the semantic command seam carries less family-specific translation logic for those families than it did after `SEM-05`
- the repo retains the proven `SEM-05` lifecycle and hosting behavior for `path` and `structure` after the migration
