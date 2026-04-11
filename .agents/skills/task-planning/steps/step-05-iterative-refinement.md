# Step 05: Iterative Refinement

## Purpose

Resolve the technical decisions that would otherwise be deferred until implementation.

## Entry Criteria

- Step 04 exit criteria are met
- the task is accurate enough to support technical planning

## Actions

1. Gather technical details through discussion and repository context.
2. Make or document decisions for all material implementation concerns:
   - data model
   - API or interface design
   - error handling
   - state management
   - integration behavior
   - configuration
   - migration or rollout considerations when relevant
3. Surface tradeoffs clearly.
4. Keep the design simple and understandable.
5. Organize the work into small reversible implementation phases.
6. Define the TDD approach and test strategy at the same time as the technical decisions.

## Expected Outputs

- technical decision log
- unresolved question list, if any
- phased implementation outline
- initial test strategy

## Exit Criteria

- all implementation-critical decisions are either made or explicitly escalated
- the remaining unknowns are small enough not to block implementation
- the work can be broken into small reversible phases
- TDD and test strategy are defined at a meaningful planning level

## Confirmation Gate

Present the technical decisions and phased direction, then ask the user to confirm or refine before proceeding to Step 06.
