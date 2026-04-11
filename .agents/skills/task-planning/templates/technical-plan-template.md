# Technical Implementation Plan Template

Store this document as:

- `specifications/tasks/<scope>/<TASK-ID>-<task-slug>/plan.md`

````md
# Technical Plan: <Task ID> <Task Title>
**Task ID**: `<TASK-ID>`
**Title**: `<Task Title>`
**Status**: `draft`
**Date**: `<YYYY-MM-DD>`

## Source Task

- [<Task Title>](./task.md)

## Problem Summary

<Condensed planning version of the task problem.>

## Goals

- <Goal>
- <Goal>

## Non-Goals

- <Non-goal>
- <Non-goal>

## Related Context

- <PRD / HLD / domain analysis / related task>

## Research Summary

- <What was learned from related work>

## Technical Decisions

### Data Model

<Define relevant structures or ownership rules.>

### API and Interface Design

<Define public and internal interfaces.>

### Error Handling

<Define failures, reporting, and recovery behavior.>

### State Management

<Define state ownership and transitions if relevant.>

### Integration Points

<Define runtime boundaries and integration behavior.>

### Configuration

<Define config sources, defaults, and override rules if relevant.>

## Architecture Context

```text
<Diagram or structured component view>
```

## Acceptance Criteria

- <Verifiable implementation-level outcome>
- <Verifiable implementation-level outcome>

## Test Strategy

### TDD Approach

<Describe how tests lead implementation.>

### Required Test Coverage

- <Unit tests>
- <Integration tests>
- <Scenario tests>

## Implementation Phases

1. <Small reversible phase>
2. <Small reversible phase>

## Risks and Mitigations

- <Risk>: <Mitigation>

## Dependencies

- <Dependency>
````

## Writing rules

- Prefer concrete technical decisions over vague implementation notes.
- Keep the design simple and understandable.
- Use repo-internal relative links only.
