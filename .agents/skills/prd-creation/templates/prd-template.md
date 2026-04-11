# PRD Template

Use this template when creating or normalizing a PRD.

Store it as `specifications/prds/prd-<slug>.md`.

````md
---
doc_type: prd
title: <PRD Title>
status: draft
last_updated: YYYY-MM-DD
---

# PRD: <PRD Title>

## Problem statement

<Describe the user or workflow problem and why it matters.>

## Goals

1. <Goal>
2. <Goal>
3. <Goal>

## Success Metrics & KPI

| Metric | Baseline | Target | Measurement Method | Timeline |
| --- | --- | --- | --- | --- |
| <Metric> | <Baseline> | <Target> | <Measurement Method> | <Timeline> |

**Primary KPI**

- <Primary KPI>

**Secondary KPI**

- <Secondary KPI>
- <Secondary KPI>

## Target Users

- <User type>
- <User type>

## User Flows & Scenarios

### Flow 1: <Flow name>

1. <Step>
2. <Step>
3. <Step>

### Flow 2: <Flow name>

1. <Step>
2. <Step>
3. <Step>

## Functional Requirements

| Requirement | User Story | Acceptance Criteria | Priority |
| --- | --- | --- | --- |
| <Requirement> | As a <user>, I want <goal> so that <value> | <Testable product outcome> | <P0/P1/P2> |

Conflict flag: <state whether any functional requirements conflict with domain rules, and identify them if they do>.

## Non Functional Requirements

- <Requirement>
- <Requirement>

## Constraints

- <Constraint>
- <Constraint>

## Out of Scope

- <Explicit exclusion>
- <Explicit exclusion>

## Opened Questions

- <Open question>
- <Open question>

## Risks and Mitigation

| Risk | Likelihood | Impact | Mitigation Strategy |
| --- | --- | --- | --- |
| <Risk> | <Low/Medium/High> | <Low/Medium/High> | <Mitigation> |

## Dependencies

- <Dependency>
- <Dependency>

## Revision History

| Date | Change |
| --- | --- |
| YYYY-MM-DD | Initial draft created |
````

## Writing rules

- Keep the PRD focused on product behavior, value, constraints, and scope.
- Avoid implementation detail unless the user explicitly asks for it.
- Use repo-relative links only.
- Use lightweight YAML front matter with `doc_type`, `title`, `status`, and `last_updated`.
- Add a `Revision History` section with concise, dated entries.
- When updating an existing PRD, update `last_updated` and append a new revision-history entry for that change.
- Split broad source material into multiple PRDs when that produces cleaner product boundaries.
- Ensure metrics, requirements, and risks are concrete enough to review.
- Do not include component breakdowns, technology stacks, module/file layout, or runtime architecture.
