# Summary: SEM-05 Validate V2 Semantic Contract Via Ruby Normalizer Spike

## What Shipped

- Added a Ruby-only `contractVersion: 2` spike path inside the existing semantic seam:
  - [SemanticCommands](src/su_mcp/semantic_commands.rb)
  - [RequestValidator](src/su_mcp/semantic/request_validator.rb)
  - [RequestNormalizer](src/su_mcp/semantic/request_normalizer.rb)
- Proved three hard atomic scenarios through tests:
  - retained structure adoption
  - terrain-following path with hosting target resolution
  - `replace_preserve_identity` under hierarchy
- Added one hybrid high-risk proof test that uses the real command, validator, normalizer, and target-resolution path, while doubling only terminal builder mechanics.
- Kept Python and the shared bridge contract unchanged.

## Validation

- `bundle exec rake ruby:lint`
- `bundle exec rake ruby:test`
- `bundle exec rake ruby:contract`

All passed locally.

## Findings

- The candidate `v2` shape is viable enough to survive the Ruby seam for the spike scenarios.
- Section ownership held well enough for:
  `metadata`, `definition`, `hosting`, `placement`, and `lifecycle`
  to remain distinct in the implemented flows.
- The biggest remaining overlap is still the command-level translation from the sectioned `v2` envelope into the current builder-facing `v1` payload shape.
- `sceneProperties` were not needed for the proof.
- No new top-level escape fields were required.

## Docs And Metadata

- Updated the exploratory signal with spike findings:
  [Pressure-Test A Potential V2 Semantic Contract Before The PRD Surface Expands](specifications/signals/2026-04-15-semantic-contract-v2-pressure-test-signal.md)
- Updated [task.md](./task.md) status to `completed`
- Kept [plan.md](./plan.md) as the finalized technical plan

## Manual Verification Still Useful

- Real SketchUp-hosted manual validation would still be useful before treating the `v2` shape as production-ready, especially for:
  - actual terrain-conforming geometry behavior
  - fuller replacement semantics beyond the spike’s minimal proof

## Public Docs

- No user-facing doc update was required because no public MCP tool schema or bridge contract changed.
