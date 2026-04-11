---
name: "prd-creation"
description: "Use when the user wants to create or update one or more PRDs through progressive product discovery, domain alignment, measurable requirements, and structured validation."
---

# PRD Creation

Create or update one or more product requirement documents.

This skill is intentionally progressive. Start from the source material and execute one step at a time. Do not read later step files until the current step is complete and its exit criteria are met.

## Output model

- Store PRDs under `specifications/prds/`.
- Use one file per coherent product slice.
- File name format: `prd-<slug>.md`.
- Every PRD must include lightweight YAML front matter with `doc_type`, `title`, `status`, and `last_updated`.
- Every PRD must include a `Revision History` section with concise, dated entries.

Examples:

- `specifications/prds/prd-semantic-scene-modeling.md`
- `specifications/prds/prd-staged-asset-reuse.md`

## Operating principles

- One step at a time: load only the current step reference, not the whole step set up front.
- Product first: PRDs describe user problems, user value, workflows, outcomes, requirements, and business scope.
- Domain aligned: use the domain analysis where available and do not silently conflict with domain rules.
- Measurable by default: metrics, KPIs, and requirements must be reviewable and testable.
- Split by capability: if the source material covers multiple coherent product slices, create multiple PRDs rather than one overloaded document.
- Confirm before advancing at explicit checkpoints.
- Ask for clarity if key product intent, user scope, or domain rules are missing or conflicting.
- Use repo-relative links only. Never write local absolute workspace paths into PRDs.

## PRD posture

PRDs must answer:

- what problem exists
- for whom
- why it matters
- what outcomes define success
- what product behaviors are required
- what is explicitly out of scope

PRDs must not turn into architecture documents. Do not include:

- component breakdowns
- technology stacks
- runtime layering
- module/file structure
- implementation sequencing
- code-level API design

## Inputs

Start with:

- the source guide, brief, or user request
- `specifications/domain-analysis.md` when available
- related PRDs, HLDs, or notes when relevant

## Outputs

By the end of the skill, produce:

- a clear product problem and scope definition
- domain-aligned product boundaries
- measurable goals and KPI choices
- target users and user flows
- structured functional and non-functional requirements
- constraints, out-of-scope boundaries, risks, and dependencies
- one or more PRDs stored in `specifications/prds/` using `templates/prd-template.md`
- updated front matter and revision history for every PRD created or edited during the skill

## Step index

1. Define product slice
2. Capture user problem and target users
3. Align domain rules and terminology
4. Shape outcomes, KPIs, and flows
5. Define product requirements
6. Define scope boundaries and delivery risks
7. Draft PRD
8. Validate product posture
9. Finalize and persist PRD

## Progression rules

- Start with `steps/step-01-define-product-slice.md`.
- After completing a step, check its exit criteria before loading the next step.
- For steps 1, 2, 3, and 4, present a summary and ask the user for confirmation before proceeding.
- If the source material suggests more than one coherent product slice, split them before drafting.
- If domain rules are missing and materially affect requirements, ask the user or explicitly mark the gap instead of inventing rules.
- Functional requirements must be checked against domain rules and any conflicts must be flagged explicitly in the PRD.
- Keep implementation details out of the PRD unless the user explicitly asks for that level of specificity.
- When creating a PRD, initialize its front matter and add an initial revision-history entry.
- When updating an existing PRD, update `last_updated` and append a dated revision-history entry describing the change.
- Persist the final PRD as `prd-<slug>.md` under `specifications/prds/`.

## Step map

- `steps/step-01-define-product-slice.md`
- `steps/step-02-capture-user-problem-and-target-users.md`
- `steps/step-03-align-domain-rules-and-terminology.md`
- `steps/step-04-shape-outcomes-kpis-and-flows.md`
- `steps/step-05-define-product-requirements.md`
- `steps/step-06-define-scope-boundaries-and-delivery-risks.md`
- `steps/step-07-draft-prd.md`
- `steps/step-08-validate-product-posture.md`
- `steps/step-09-finalize-and-persist-prd.md`

## Template map

- `templates/prd-template.md`
