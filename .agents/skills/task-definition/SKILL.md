---
name: "task-definition"
description: "Use this skill when you need a repeatable single task definition creation or update with comprehensive linking."
---

# Task Definition

Create or update structured task definitions from higher-level specifications.

Use this skill when the user wants task breakdowns, execution-planning artifacts, or normalized task definitions under a shared format.

## Task folder model

Use one folder per task.

- Store tasks under `specifications/tasks/<scope>/<TASK-ID>-<task-slug>/`.
- Store the product-readable task as `task.md` inside that folder.
- Reserve `plan.md` in the same folder for the technical implementation plan created later by the task-planning skill.
- If no task scope is available, use `specifications/tasks/general/`.

Example:

- `specifications/tasks/platform/PLAT-01-define-and-scaffold-platform-structure/task.md`
- `specifications/tasks/platform/PLAT-01-define-and-scaffold-platform-structure/plan.md`

## Core principles

- Focus on requirements: capture what needs to be true when the task is done, not how to implement it.
- Validate testability: every acceptance criterion must be testable and concrete.
- Request clarity when needed: if source requirements are missing, conflicting, or ambiguous enough to make the task unsafe, ask the user for clarification before writing.
- Respect the spec hierarchy: if a task conflicts with a PRD, HLD, domain analysis, or explicit user instruction, the higher-level source wins until the conflict is resolved.

## Workflow

1. Read the source specs that define the task.
2. Identify the task boundary:
   - problem the task solves
   - outcome the task must achieve
   - explicit non-goals
   - business constraints
   - technical constraints
   - dependencies and relationships
3. Derive the task folder path using the task scope, task ID, and task slug.
4. Create the task folder explicitly before writing task content.
5. Check for missing or conflicting information.
6. If the missing or conflicting information would materially weaken the task definition, ask the user a concise clarification question before writing.
7. Write `task.md` inside the task folder using the template in `templates/task-template.md`.
8. Validate the task before finishing.

Folder creation is mandatory. Do not leave a task definition as an unplaced standalone file.

## Required task structure

Every task definition should contain these sections in this order:

1. `Linked HLD` if available, otherwise `Source` with a link to the source material that defines the task.
2. `Problem Statement`
3. `Goals`
4. `Acceptance Criteria`
5. `Non-Goals`
6. `Business Constraints`
7. `Technical Constraints`
8. `Dependencies`
9. `Relationships` when applicable
10. `Related Technical Plan`
11. `Success Metrics`

Read `templates/task-template.md` before drafting the task.

## Naming and placement rules

- Folder name format: `<TASK-ID>-<task-slug>`
- Task file name: `task.md`
- The task folder is the primary identity for the task artifact.
- Do not create separate standalone task files outside the task folder.
- Keep the future technical plan co-located as `plan.md` in the same folder.

## Writing rules

- Keep the task requirements-focused.
- Do not prescribe implementation details unless the user explicitly asks for them.
- Keep `Goals` outcome-oriented and concise.
- Use `Acceptance Criteria` in Gherkin format.
- Make each scenario independently testable.
- Keep `Non-Goals` explicit so the task boundary is clear.
- Separate business constraints from technical constraints.
- Keep dependencies limited to real upstream needs, not nice-to-have sequencing.
- Keep success metrics outcome-oriented and specific enough to verify.
- Include a `## Related Technical Plan` section in `task.md`.
- If no plan exists yet, set that section to `- none yet`.

## Validation checklist

Before finishing, confirm:

- the task links back to its source HLD
- the task folder exists and matches the naming convention
- the task content is stored as `task.md` in that folder
- the problem statement explains why the task exists
- the goals describe required outcomes rather than implementation steps
- every acceptance criterion is written in Gherkin format
- every acceptance criterion is testable and unambiguous
- non-goals do not contradict goals
- business and technical constraints are both present and distinct
- dependencies are explicit and consistent with related tasks
- success metrics are measurable enough to review later
- the task does not conflict with higher-level specifications
- the task includes `## Related Technical Plan`

## When to stop and ask the user

Ask for clarification if any of these are true:

- the task source is unclear or missing
- two higher-level specs conflict
- the task boundary is too broad to produce one coherent task
- success metrics would be invented rather than derived
- dependencies are ambiguous enough to mis-sequence the work

## Template map

- `templates/task-template.md`: reusable task template and field guidance
