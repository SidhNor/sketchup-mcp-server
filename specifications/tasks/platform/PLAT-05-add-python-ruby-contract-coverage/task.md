# Task: PLAT-05 Prepare Python/Ruby Contract Coverage Foundations
**Task ID**: `PLAT-05`
**Title**: `Prepare Python/Ruby Contract Coverage Foundations`
**Status**: `done`
**Priority**: `P1`
**Date**: `2026-04-14`

## Linked HLD

- [Platform Architecture and Repo Structure](../../../hlds/hld-platform-architecture-and-repo-structure.md)

## Problem Statement

Python and Ruby communicate through a structured bridge contract, but that boundary is still only lightly defended. The platform is about to replace most or all of the currently exposed tools through staged PRD delivery, so broad contract coverage for the legacy tool catalog would create churn without protecting the rollout that actually matters.

The platform instead needs preparatory contract work that survives tool replacement: shared bridge invariants, reusable contract-test seams, and a wave-friendly harness that lets new P0 and P1 tools add or update coverage as they land. Without that preparation, the replacement tool surface will rely too heavily on manual end-to-end testing during its highest-churn period.

## Goals

- establish automated protection for the durable Python/Ruby bridge contract invariants
- prepare reusable contract-test foundations that support wave-by-wave replacement of the tool surface
- let capability work add contract checks incrementally without freezing or over-investing in the legacy tool catalog

## Acceptance Criteria

```gherkin
Scenario: Shared bridge invariants are automatically checkable
  Given Python and Ruby communicate through a structured bridge boundary
  When the contract-preparation layer is reviewed
  Then durable request and response invariants such as envelopes, request identifiers, error semantics, and serializable result expectations can be verified automatically
  And regressions in those shared boundary rules can be detected without relying only on manual end-to-end testing

Scenario: Contract preparation supports incremental tool replacement
  Given the capability PRDs will replace the current tool surface in multiple P0 and P1 waves
  When the contract-preparation layer is reviewed
  Then it provides a reusable harness or test seam that new or revised tools can adopt incrementally
  And wave-specific contract cases can be added without requiring the full future tool catalog to be finalized first

Scenario: Contract preparation reflects the platform-owned boundary
  Given the revised HLD defines a clear Python/Ruby transport boundary
  When the contract-preparation layer is reviewed
  Then it validates platform-owned boundary behavior rather than duplicating Ruby business logic
  And it remains compatible with the shared runtime contracts from `PLAT-01`

Scenario: Contract checks are visible in normal CI without being confused with unit tests
  Given the prepared contract layer is fast and does not require SketchUp-hosted execution
  When the repository CI configuration is reviewed
  Then contract checks run as a required step inside the normal CI workflow
  And they remain separated from unit-test reporting rather than being hidden inside generic test steps
```

## Non-Goals

- adding broad contract coverage for the legacy tool catalog purely because it exists today
- replacing unit tests with cross-runtime contract tests
- making the full cross-runtime contract suite mandatory in CI by default
- moving product rules into Python for test convenience

## Business Constraints

- the task should strengthen confidence in the replacement rollout without turning every capability wave into heavy process overhead
- the task must protect the runtime boundary, not redefine ownership between runtimes
- the task must support staged delivery where different PRDs land replacement tools over time rather than in one cutover
- the task should keep contract-regression signal visible to contributors and reviewers instead of blending it into generic unit-test output

## Technical Constraints

- the contract-preparation layer must align with the revised platform HLD
- preparation work must remain compatible with shared Ruby runtime contracts and Python bridge invocation behavior
- the task should focus on durable boundary invariants and reusable test seams rather than assuming the current tool catalog survives
- the task should not assume SketchUp-hosted execution in the default CI path
- the resulting checks should run through native Ruby and Python test technology and fit into the existing CI workflow as a distinct contract step

## Dependencies

- `PLAT-01`
- `PLAT-03`

## Relationships

- preparatory platform task for the replacement tool rollout
- complements the unit coverage embedded in `PLAT-01`, `PLAT-02`, and `PLAT-03`
- prepares wave-owned contract cases for the capability PRD implementation slices

## Related Technical Plan

- [Technical Plan](./plan.md)

## Success Metrics

- durable Python/Ruby bridge invariants can be validated automatically
- new replacement tools can add or revise contract cases incrementally without large harness rewrites
- boundary regressions are easier to detect during staged tool-surface replacement before manual runtime testing
- CI makes contract regressions visible as boundary failures rather than burying them inside generic unit-test output
