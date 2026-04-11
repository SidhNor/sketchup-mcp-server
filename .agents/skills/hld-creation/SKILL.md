---
name: "hld-creation"
description: "Use when the user wants to create or update an HLD through progressive architecture discovery, source validation, boundary definition, and structured design drafting."
---

# HLD Creation

Create or update a high-level design document.

This skill is intentionally progressive. Start from the source specs and execute one step at a time. Do not read later step files until the current step is complete and its exit criteria are met.

## Output model

- Store HLDs under `specifications/hlds/`.
- Use one file per coherent architecture scope.
- File name format: `hld-<slug>.md`.

Examples:

- `specifications/hlds/hld-platform-architecture-and-repo-structure.md`
- `specifications/hlds/hld-semantic-scene-modeling.md`

## Operating principles

- One step at a time: load only the current step reference, not the whole step set up front.
- Architecture from source: derive the HLD from the PRD, domain analysis, guide, and current repo context.
- Separate platform from capability: classify the HLD early.
- Keep platform HLDs product-agnostic and focused on shared structure, runtime boundaries, quality gates, and cross-cutting concerns.
- Keep capability HLDs focused on implementing one PRD or capability slice without delving into generic repo-structure churn.
- Prefer clear boundaries and understandable structures over clever abstraction.
- Search related patterns when they materially improve the design; for SketchUp-specific work, favor official SketchUp guidance and established extension patterns.
- Confirm before advancing at explicit checkpoints.
- Use repo-relative links only. Never write local absolute workspace paths into HLDs.

## HLD posture

HLDs must answer:

- given the source PRD or platform need, what system shape should exist
- where boundaries sit
- how responsibilities split
- how components integrate
- what architectural decisions were made and why
- what technical questions remain open

HLDs must not turn into PRDs. Do not include:

- KPI tables
- target user sections
- full functional requirement tables
- product value framing beyond what is needed as source context
- implementation task sequencing beyond high-level architectural implications

## Inputs

Start with:

- one or more source PRDs
- `specifications/domain-analysis.md` when available
- the relevant current HLDs when updating or splitting documents
- current repo context and architecture constraints

## Outputs

By the end of the skill, produce:

- a scoped architecture statement
- a clear classification of platform vs capability HLD
- architectural obligations derived from source PRDs or platform needs
- a defined architecture approach and component model
- integration and data-flow views with diagrams
- key architectural decisions and technology choices
- opened questions that capture unresolved architecture work
- a final HLD stored in `specifications/hlds/` using `templates/hld-template.md`

## Step index

1. Capture architectural mandate
2. Classify HLD type and document boundaries
3. Inspect current system and constraints
4. Research patterns and choose architecture strategy
5. Define components and ownership boundaries
6. Define integration, data, and test boundaries
7. Document decisions and technology stack
8. Validate architecture posture and open questions
9. Finalize and persist HLD

## Progression rules

- Start with `steps/step-01-capture-architectural-mandate.md`.
- After completing a step, check its exit criteria before loading the next step.
- For steps 1, 2, 3, and 4, present a summary and ask the user for confirmation before proceeding.
- Classify the HLD as `platform` or `capability` before making structural decisions.
- If the HLD scope is mixed, split it rather than blending product-agnostic platform concerns with PRD-specific implementation concerns.
- Keep product requirements in the PRD and implementation tasks in task plans; the HLD should focus on system shape, boundaries, flows, integration, and major decisions.
- Persist the final HLD as `hld-<slug>.md` under `specifications/hlds/`.

## Step map

- `steps/step-01-capture-architectural-mandate.md`
- `steps/step-02-classify-hld-type-and-document-boundaries.md`
- `steps/step-03-inspect-current-system-and-constraints.md`
- `steps/step-04-research-patterns-and-choose-architecture-strategy.md`
- `steps/step-05-define-components-and-ownership-boundaries.md`
- `steps/step-06-define-integration-data-and-test-boundaries.md`
- `steps/step-07-document-decisions-and-technology-stack.md`
- `steps/step-08-validate-architecture-posture-and-open-questions.md`
- `steps/step-09-finalize-and-persist-hld.md`

## Template map

- `templates/hld-template.md`
