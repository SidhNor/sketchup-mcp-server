# HLD Template

Use this template when creating or normalizing an HLD.

Store it as `specifications/hlds/hld-<slug>.md`.

````md
# HLD: <HLD Title>

## System Overview

<Describe the purpose, scope, and source context of the HLD. Make the platform-vs-capability boundary explicit when relevant.>

## Architecture Approach

<Describe the overall architecture direction, key boundaries, and why this shape was chosen.>

## Component Breakdown

### <Component 1>

**Responsibilities**

- <Responsibility>
- <Responsibility>

### <Component 2>

**Responsibilities**

- <Responsibility>
- <Responsibility>

## Integration & Data Flows

### <Flow name>

```text
<Component> -> <Boundary> -> <Component> -> <Result>
```

### Architecture Diagram

```text
<Diagram>
```

## Key Architectural Decisions

### 1. <Decision title>

**Decision**

<Decision statement>

**Reason**

<Why this decision was chosen>

## Technology Stack

| Concern | Technology / Approach | Purpose |
| --- | --- | --- |
| <Concern> | <Technology / Approach> | <Purpose> |

## Opened Questions

1. <Question>
2. <Question>
````

## Writing rules

- Keep the HLD architectural rather than product-spec or task-plan oriented.
- Keep platform HLDs product-agnostic.
- Keep capability HLDs focused on the relevant PRD and capability behavior.
- Use repo-relative links only.
- Include only technology choices that materially affect the architecture.
- Do not include KPI tables, target-user sections, or full product requirement tables beyond brief source references.
