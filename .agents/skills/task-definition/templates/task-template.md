# Task Template

Store this document as:

- `specifications/tasks/<scope>/<TASK-ID>-<task-slug>/task.md`

````md
# Task: <TASK-ID> <Task Title>
**Task ID**: `<TASK-ID>`
**Title**: `<Task Title>`
**Status**: `<workflow_status>`
**Date**: `<YYYY-MM-DD>`

## Linked HLD

- [<Source HLD Title>](<repo-internal-relative-path-to-source-hld.md>)

## Problem Statement

<Explain the problem this task solves and why it matters. Focus on what and why, not how.>

## Goals

- <Outcome 1>
- <Outcome 2>
- <Outcome 3>

## Acceptance Criteria

```gherkin
Scenario: <Primary scenario>
  Given <starting condition>
  When <review or validation condition>
  Then <testable outcome>
  And <additional testable outcome>
```

## Non-Goals

- <Explicit exclusion>
- <Explicit exclusion>

## Business Constraints

- <Business constraint>
- <Business constraint>

## Technical Constraints

- <Technical constraint>
- <Technical constraint>

## Dependencies

- `<Upstream task or source artifact>`

## Relationships

- blocks `<Task ID>` when applicable
- informs `<Task ID>` when applicable

## Related Technical Plan

- none yet

## Success Metrics

- <Specific measurable outcome>
- <Specific measurable outcome>
````

## Best practices

- Focus on requirements, not implementation details.
- Use repo-internal relative links only.
- Every acceptance criterion must be testable.
- Ask for missing or conflicting information instead of inventing it.
