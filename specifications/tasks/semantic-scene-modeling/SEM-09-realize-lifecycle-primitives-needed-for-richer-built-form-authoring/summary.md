# Summary: SEM-09 Realize Lifecycle Primitives Needed for Richer Built-Form Authoring

## What Shipped

- Added [DestinationResolver](../../../../src/su_mcp/semantic/destination_resolver.rb) so semantic create and replace flows can resolve writable destination collections without bloating the builders.
- Updated all first-wave builders to accept an internal `destination:` collection and create into that collection instead of always using `model.active_entities`:
  - [structure_builder.rb](../../../../src/su_mcp/semantic/structure_builder.rb)
  - [path_builder.rb](../../../../src/su_mcp/semantic/path_builder.rb)
  - [pad_builder.rb](../../../../src/su_mcp/semantic/pad_builder.rb)
  - [retaining_edge_builder.rb](../../../../src/su_mcp/semantic/retaining_edge_builder.rb)
  - [planting_mass_builder.rb](../../../../src/su_mcp/semantic/planting_mass_builder.rb)
  - [tree_proxy_builder.rb](../../../../src/su_mcp/semantic/tree_proxy_builder.rb)
- Updated [semantic_commands.rb](../../../../src/su_mcp/semantic/semantic_commands.rb) to:
  - resolve writable create destinations for supported parent contexts
  - support replacement fallback when `replace_preserve_identity` omits `placement.parent`
  - perform real `structure` replacement by writing preserved metadata and erasing the old entity
  - clean up the replacement entity if erase fails before the operation aborts
  - enforce the bounded hosted matrix and refuse unsupported hosted combinations
- Updated [request_validator.rb](../../../../src/su_mcp/semantic/request_validator.rb) so `replace_preserve_identity` with `placement.mode: "parented"` no longer requires an explicit `placement.parent`.
- Extended semantic test support and coverage to assert parent collection insertion, entity erasure, non-writable destinations, replacement fallback, and hosted/refusal behavior.

## Validation

- `bundle exec ruby -Itest -e 'load "test/semantic/semantic_request_validator_test.rb"; load "test/semantic/structure_builder_test.rb"; load "test/semantic/path_builder_test.rb"; load "test/semantic/pad_builder_test.rb"; load "test/semantic/retaining_edge_builder_test.rb"; load "test/semantic/planting_mass_builder_test.rb"; load "test/semantic/tree_proxy_builder_test.rb"; load "test/semantic/semantic_commands_test.rb"'`
- `bundle exec ruby -Itest -e 'Dir["test/semantic/*_test.rb"].sort.each { |path| load path }'`
- `bundle exec rake ruby:test`
- `bundle exec rake ruby:lint`
- `bundle exec rake package:verify`

## External Review

- `grok-4.20` cross-check: no high-severity issues; implementation assessed as ready pending live SketchUp checks. Main caution was that hosted execution remains intentionally bounded rather than full geometry conformance.
- Final codereview status is recorded after the required `grok-code` pass.

## Docs And Metadata

- Updated [task.md](./task.md) status to `completed`.
- Updated [plan.md](./plan.md) with shipped implementation outcome notes.
- Updated [README.md](../README.md) so only `SEM-10` through `SEM-12` remain described as draft follow-on shells.
- No public MCP schema or user-facing setup/workflow docs changed in this task, so `README.md` and current source-of-truth docs did not require behavioral documentation updates.

## Remaining Manual Verification

- SketchUp-hosted smoke validation is still required for:
  - parented create under a real `Group`
  - parented create under a real `ComponentInstance`
  - `structure` replace-preserve-identity with and without explicit parent override
  - one success case for each delivered hosted mode:
    - `path` + `surface_drape`
    - `pad` + `surface_snap`
    - `retaining_edge` + `edge_clamp`
  - at least one larger-scene or host-stress hosted case to confirm no host-only drift
