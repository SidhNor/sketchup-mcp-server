# Step 08: Validate Product Posture

## Purpose

Validate that the document is a PRD rather than a disguised architecture or implementation plan.

## Entry Criteria

- Step 07 exit criteria are met

## Actions

1. Validate the PRD against the source material, domain analysis, and related specs.
2. Confirm that metrics are measurable and not invented without support.
3. Confirm that functional requirements are testable and user-facing.
4. Confirm that domain-rule conflicts are flagged where applicable.
5. Confirm that non-functional scope sections are complete.
6. Confirm that the document does not contain architecture-only content such as component breakdowns, technology stacks, or runtime layering.
7. Confirm that front matter is present and `last_updated` reflects the current edit.
8. Confirm that `Revision History` includes an entry for the current create/update pass.
9. Check that links are repo-relative.

## Expected Outputs

- validation notes
- corrections required before finalization, if any

## Exit Criteria

- the PRD is consistent with its source material
- the required structure is complete
- the document reads as a product document rather than an architecture document
- front matter and revision history are up to date
- links are repo-relative
- any remaining uncertainty is captured in `Opened Questions`

## Proceed Condition

Proceed to Step 09 once the PRD passes validation or all required corrections are applied.
