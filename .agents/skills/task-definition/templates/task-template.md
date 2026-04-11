# Task Template

Use this template when creating or normalizing a task document.

Store it as `task.md` inside a task folder:

- `specifications/tasks/<scope>/<TASK-ID>-<task-slug>/task.md`

````md
# Task: <TASK-ID> <Task Title>
**Task ID**: <TASK-ID>
**Title**: <Task Title>
**Status**: <workflow_status (defined, planned, done)>
**Date**: <YYYY-MM-DD>

## Linked HLD

- [<Source HLD Title>](/absolute/path/to/source-hld.md)

## Problem Statement

<Explain the problem this task solves and why it matters. Focus on the "what" and "why", not the "how">

## Goals
<Clear high level objectives this task aims to achieve>
- <Outcome 1>
- <Outcome 2>
- <Outcome 3>

## Acceptance Criteria

```gherkin
Scenario: <Primary scenario name>
  Given <relevant starting condition>
  When <review, validation, or execution condition>
  Then <testable outcome>
  And <additional testable outcome>

Scenario: <Secondary scenario name>
  Given <relevant starting condition>
  When <review, validation, or execution condition>
  Then <testable outcome>
```

## Non-Goals

- <Explicit exclusion 1>
- <Explicit exclusion 2>

## Business Constraints

- <Business rule, organizational need, ownership rule, or product-level limitation>
- <Another business constraint>

## Technical Constraints

- <Technical boundary, architecture rule, environment limitation, or contract requirement>
- <Another technical constraint>

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
- <Specific measurable outcome>
````

## Best practices

### Focus on requirements

- Capture what must be true when the task is complete.
- Avoid explaining how the code should be implemented unless the user explicitly asks for that level of detail.
- Prefer outcome statements over design prescriptions.

### Validate acceptance criteria

- Every scenario should be testable.
- Avoid vague outcomes like "works well" or "is improved."
- If a criterion cannot be reviewed or verified, rewrite it.

### Request clarity when needed

- Ask the user for missing source requirements.
- Flag conflicting requirements before writing the task.
- Do not silently invent goals, dependencies, or success metrics when the source material does not support them.

## Quick review questions

- Does the task explain why it exists?
- Is the task stored as `task.md` inside the correct task folder?
- Do the goals state outcomes rather than implementation steps?
- Are the acceptance criteria in valid Gherkin format?
- Could a reviewer verify each acceptance criterion?
- Are business constraints and technical constraints clearly separated?
- Do dependencies match the real upstream requirements?
- Do success metrics describe observable completion signals?
