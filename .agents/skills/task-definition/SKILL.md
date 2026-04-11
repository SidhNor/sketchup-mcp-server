---
name: "task-definition"
description: "Use this skill when you need a repeatable single task definition creation or update with comprehensive linking."
---

# Task Definition

Create or update structured task definitions from higher-level specifications.

## Task folder model

Use one folder per task.

- Store tasks under `specifications/tasks/<scope>/<TASK-ID>-<task-slug>/`.
- Store the product-readable task as `task.md` inside that folder.
- Reserve `plan.md` in the same folder for the technical implementation plan created later by the task-planning skill.
- If no task scope is available, use `specifications/tasks/general/`.

## Core principles

- Focus on requirements: capture what needs to be true when the task is done, not how to implement it.
- Validate testability: every acceptance criterion must be testable and concrete.
- Request clarity when needed when source requirements are missing or conflicting.
- Respect the spec hierarchy: higher-level source documents win.
- Use repo-internal relative references only. Never include local user directories, machine-specific absolute paths, or workspace-specific filesystem roots.

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
6. Ask for clarification if those gaps would materially weaken the task definition.
7. Write `task.md` inside the task folder using `templates/task-template.md`.
8. Validate the task before finishing.

Folder creation is mandatory. Do not leave a task definition as an unplaced standalone file.

## Required task structure

1. `Linked HLD` if available, otherwise `Source`
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

## Naming and placement rules

- Folder name format: `<TASK-ID>-<task-slug>`
- Task file name: `task.md`
- The task folder is the primary identity for the task artifact.
- Keep the future technical plan co-located as `plan.md` in the same folder.

## Writing rules

- Keep the task requirements-focused.
- Do not prescribe implementation details unless explicitly asked.
- Keep `Goals` outcome-oriented and concise.
- Use Gherkin for `Acceptance Criteria`.
- Include `## Related Technical Plan` in `task.md`.
- If no plan exists yet, set that section to `- none yet`.

## Validation checklist

- the task links back to its source HLD or source material
- the task folder exists and matches the naming convention
- the task content is stored as `task.md`
- acceptance criteria are written in Gherkin and are testable
- business and technical constraints are both present
- the task does not conflict with higher-level specifications
- the task includes `## Related Technical Plan`

## Template map

- `templates/task-template.md`
