# Task: PLAT-05 Add Python/Ruby Contract Coverage
**Task ID**: `PLAT-05`
**Title**: `Add Python/Ruby Contract Coverage`
**Status**: `defined`
**Date**: `2026-04-13`

## Linked HLD

- [Platform Architecture and Repo Structure](../../../hlds/hld-platform-architecture-and-repo-structure.md)

## Problem Statement

Python and Ruby communicate through a structured bridge contract, but that boundary is still lightly defended. Contract coverage would improve confidence in request and response compatibility across the runtime boundary, but it is lower priority than the main decomposition and unit-test work because it is not currently expected to become a mandatory CI gate.

## Goals

- add automated protection for the structured Python/Ruby bridge contract
- verify request and response compatibility for the supported bridge model
- keep this coverage optional or low-priority relative to the main always-on unit-test path

## Acceptance Criteria

```gherkin
Scenario: Request and response compatibility is automatically checkable
  Given Python and Ruby communicate through a structured bridge boundary
  When contract coverage is reviewed
  Then request and response compatibility can be verified automatically
  And breaking changes in envelopes or boundary error behavior can be detected without relying only on manual end-to-end testing

Scenario: Contract coverage reflects the platform-owned boundary
  Given the revised HLD defines a clear Python/Ruby transport boundary
  When the contract layer is reviewed
  Then it validates the supported bridge contract rather than duplicating Ruby business logic
  And it remains compatible with the shared runtime contracts from `PLAT-01`

Scenario: Contract coverage remains lower priority than the main delivery path
  Given the platform does not currently require contract tests as a default CI gate
  When the task is reviewed in the platform backlog
  Then it is clearly treated as deferred or low-priority work
  And it does not block the core decomposition and unit-test slices
```

## Non-Goals

- replacing unit tests with cross-runtime contract tests
- making contract tests mandatory in CI by default
- moving product rules into Python for test convenience

## Business Constraints

- contract coverage should strengthen confidence without becoming required process overhead by default
- the task must protect the runtime boundary, not redefine ownership between runtimes
- backlog priority should reflect that this work is valuable but not urgent

## Technical Constraints

- the contract layer must align with the revised platform HLD
- coverage must remain compatible with shared Ruby runtime contracts and Python bridge invocation behavior
- the task should not assume SketchUp-hosted execution in the default CI path

## Dependencies

- `PLAT-01`
- `PLAT-03`

## Relationships

- deferred low-priority platform task
- complements the unit coverage embedded in `PLAT-01`, `PLAT-02`, and `PLAT-03`

## Related Technical Plan

- none yet

## Success Metrics

- the supported Python/Ruby bridge contract can be validated automatically
- boundary regressions are easier to detect before manual runtime testing
- the task remains clearly outside the main mandatory CI path unless priorities change later
