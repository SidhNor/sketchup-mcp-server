# Tasks Index

## Purpose

This directory contains implementation task breakdowns derived from the HLDs.

Tasks are organized by scope area. Each task should:

- link back to its source HLD
- include a task metadata header with `Task ID`, `Title`, `Status`, and `Date`
- include Problem Statement, Goals, Acceptance Criteria, Non-Goals, Business Constraints, Technical Constraints, Dependencies, and Success Metrics
- stay requirements-focused
- define dependencies and relationships
- define testable acceptance criteria in Gherkin format
- avoid detailed implementation decisions unless explicitly moved into a lower-level design or execution artifact

## Current Task Sets

- [Platform Tasks](platform/README.md)
- [Scene Targeting and Interrogation Tasks](scene-targeting-and-interrogation/README.md)
- [Semantic Scene Modeling Tasks](semantic-scene-modeling/README.md)

## Relationship to Other Specifications

Recommended reading path before executing tasks:

1. [Domain Analysis](../domain-analysis.md)
2. Relevant PRD
3. Relevant HLD
4. Task breakdown

Tasks are downstream execution-planning artifacts. If a task conflicts with a PRD or HLD, the higher-level specification wins until the specs are explicitly updated.
