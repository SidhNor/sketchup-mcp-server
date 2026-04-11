# Step 03: Inspect Current System and Constraints

## Purpose

Ground the HLD in the current system, runtime boundaries, and existing constraints before choosing a design.

## Entry Criteria

- Step 02 exit criteria are met
- the user has confirmed or refined the HLD type and boundary

## Actions

1. Inspect the current repo and runtime context relevant to the HLD.
2. Identify current-system constraints, integration boundaries, and quality expectations.
3. Capture any existing architectural weaknesses or drift that the HLD must address.
4. Distinguish stable constraints from changeable implementation details.
5. Summarize the architectural starting point.

## Expected Outputs

- current-system summary
- runtime and boundary constraints
- architecture weakness list
- stable-vs-changeable context notes

## Exit Criteria

- the HLD is grounded in the current system reality
- relevant constraints are explicit
- the existing system weaknesses are visible

## Confirmation Gate

Present the current-system and constraint summary, then ask the user for confirmation before proceeding to Step 04.
