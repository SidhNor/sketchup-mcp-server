# Summary: SEM-11 Align Managed-Object Maintenance Surface

## What Shipped

- Tightened [ManagedObjectMetadata](../../../../src/su_mcp/semantic/managed_object_metadata.rb) so soft metadata mutation is now governed by an explicit semantic-type-aware allowlist:
  - all managed objects: `status`
  - `structure`: `structureCategory`
  - `planting_mass`: `plantingCategory`
  - `tree_proxy`: `speciesHint`
- Kept [SemanticCommands](../../../../src/su_mcp/semantic/semantic_commands.rb) as the semantic metadata entrypoint and extended coverage so the widened managed metadata policy is exercised through the real command path.
- Extended [EditingCommands](../../../../src/su_mcp/editing/editing_commands.rb) so `transform_entities` and `set_material` now:
  - accept either legacy `id` or additive compact `targetReference`
  - refuse `missing_target` and `conflicting_target_selectors`
  - return normalized mutation envelopes with `success`, `outcome`, `id`, and `managedObject`
  - serialize updated managed targets while keeping unmanaged targets on the same additive shape with `managedObject: nil`
- Isolated the new editing-side semantic behavior behind dedicated collaborators:
  - [managed_mutation_helper.rb](../../../../src/su_mcp/editing/managed_mutation_helper.rb)
  - [mutation_target_resolver.rb](../../../../src/su_mcp/editing/mutation_target_resolver.rb)
- Extended [McpRuntimeLoader](../../../../src/su_mcp/runtime/native/mcp_runtime_loader.rb) so `transform_entities` and `set_material` schemas expose additive `targetReference` support without removing legacy `id`.
- Added or updated coverage for:
  - metadata policy widening and invariant refusals
  - semantic command serialization for widened metadata updates
  - managed-aware transform/material behavior
  - dispatcher passthrough and runtime schemas
  - native contract cases for managed success and selector refusals
- Finalized the hosted-correctness fixes discovered during live validation:
  - `transform_entities.position` now interprets public translation values in meters
  - `set_entity_metadata` loader schema now exposes `plantingCategory` and `speciesHint`
  - managed metadata reads used during hierarchy-aware relocation now avoid host-sensitive enumerator assumptions

## Validation

- `bundle exec ruby -Itest -e 'load "test/semantic/semantic_metadata_test.rb"; load "test/semantic/semantic_commands_test.rb"'`
- `bundle exec ruby -Itest -e 'load "test/editing/editing_commands_test.rb"; load "test/runtime/tool_dispatcher_test.rb"; load "test/runtime/native/mcp_runtime_loader_test.rb"; load "test/runtime/native/mcp_runtime_native_contract_test.rb"'`
- `bundle exec ruby -Itest -e 'load "test/runtime/native/mcp_runtime_loader_test.rb"; load "test/runtime/tool_dispatcher_test.rb"; load "test/runtime/native/mcp_runtime_native_contract_test.rb"'`
- `bundle exec rake ruby:test`
- `RUBOCOP_CACHE_ROOT=/tmp/rubocop-cache bundle exec rake ruby:lint`
- `bundle exec rake package:verify`
- Live SketchUp-hosted validation passed for:
  - managed `set_entity_metadata` widening, including `tree_proxy.speciesHint`
  - managed `transform_entities` by `targetReference`
  - managed `set_material` by `targetReference`
  - managed-container status mutation without implicit child propagation

## External Review

- `grok-4.20` codereview completed on the final post-host-feedback code state with no code-level blockers.
- Hosted validation superseded the earlier optimistic intermediate review and forced the final correctness fixes before closure.
- One schema regression was caught and fixed during the closeout:
  - `set_material` still requires `material` while supporting additive `id` or `targetReference`

## Docs And Metadata

- Updated [README.md](../../../../README.md) to describe the managed-aware mutation behavior accurately.
- Updated [sketchup_mcp_guide.md](../../../../sketchup_mcp_guide.md) for the current `transform_entities`, `set_material`, and `set_entity_metadata` contracts.
- Updated [task.md](./task.md) status to `completed`.
- Updated [plan.md](./plan.md) with the shipped implementation outcome and final validation record.

## Final Hosted Outcome

- The SEM-11 maintenance posture is now host-proven for the validated slice:
  - widened metadata mutation works on approved semantic types
  - protected metadata fields still refuse cleanly
  - managed transform and material mutation work through compact targeting
  - managed-container status changes remain targeted to the container and do not silently propagate to children
