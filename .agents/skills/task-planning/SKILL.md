---
name: "task-planning"
description: "Use when the user wants to turn an existing defined task into a comprehensive technical implementation plan through progressive step-by-step discovery, research, clarification, and confirmation."
---

# Task Planning

Turn an existing defined task into a technical implementation plan.

This skill is intentionally progressive. Start from the task document and execute one step at a time. Do not read later step files until the current step is complete and its exit criteria are met.

## Task folder model

This skill assumes the task already lives in a task folder:

- `specifications/tasks/<scope>/<TASK-ID>-<task-slug>/task.md`

Write the technical implementation plan as a sibling file:

- `specifications/tasks/<scope>/<TASK-ID>-<task-slug>/plan.md`

## Operating principles

- One step at a time: load only the current step reference, not the whole step set up front.
- Requirements first: keep the task product-readable; put technical detail in the implementation plan.
- TDD is required: test strategy must be designed before implementation planning is finalized.
- Small reversible steps: break complex delivery into small implementable phases with low rollback cost.
- Clarity over cleverness: choose simple, understandable approaches over overly abstract designs.
- Confirm before advancing at explicit checkpoints.
- Resolve ambiguity early: ask for missing or conflicting information before it pollutes the plan.

## Inputs

Start with:

- the defined task file
- linked HLD, PRD, and domain-analysis documents as needed
- any related tasks or prior planning artifacts

## Outputs

By the end of the skill, produce:

- a validated understanding of the task problem and scope
- refined goals, constraints, assumptions, and non-goals
- a research summary tied to related work
- an updated task document only if research proves the task is wrong or incomplete
- an architectural context diagram with integration and test boundaries
- refined acceptance criteria as testable bullet-point outcomes
- a documented risk and dependency assessment
- a comprehensive technical implementation plan stored as `plan.md` in the same task folder, using `templates/technical-plan-template.md`

## Step index

1. Capture problem
2. Define goals
3. Search related work
4. Update existing task with research findings
5. Iterative refinement
6. Architectural context
7. Acceptance criteria
8. Risk and dependencies
9. Create technical implementation plan

## Progression rules

- Start with `steps/step-01-capture-problem.md`.
- After completing a step, check its exit criteria before loading the next step.
- For steps 1, 2, 3, and 5, present a summary and ask the user for confirmation before proceeding.
- If a step reveals that the task, HLD, PRD, or domain analysis is materially wrong or conflicting, stop and resolve the conflict before moving on.
- If the implementation plan would require inventing important behavior without support from the task or research, ask the user instead of guessing.
- Persist the final plan as `plan.md` in the same folder as `task.md`.
- Update the task's `## Related Technical Plan` section to point to `./plan.md` when the plan is created.

## Step map

- `steps/step-01-capture-problem.md`
- `steps/step-02-define-goals.md`
- `steps/step-03-search-related-work.md`
- `steps/step-04-update-existing-task.md`
- `steps/step-05-iterative-refinement.md`
- `steps/step-06-architectural-context.md`
- `steps/step-07-acceptance-criteria.md`
- `steps/step-08-risk-and-dependencies.md`
- `steps/step-09-create-technical-plan.md`

## Template map

- `templates/technical-plan-template.md`
