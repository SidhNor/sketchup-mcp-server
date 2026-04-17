# Summary: SEM-06 Cut Over Create Site Element To The Sectioned Contract And Adopt Builder-Native V2 Input For Path And Structure

## Shipped

- `create_site_element` now advertises a sectioned-only public schema in the native runtime.
- `PathBuilder` and `StructureBuilder` now consume sectioned `definition` input directly.
- `SceneProperties` now reads `sceneProperties.name`, `sceneProperties.tag`, and `representation.material` for migrated families.
- `SemanticCommands#create_site_element` now executes one sectioned create path for create, adopt, and replace flows.
- `pad`, `retaining_edge`, `planting_mass`, and `tree_proxy` remain available through the sectioned public contract via a narrow internal legacy-builder bridge.
- Metadata persistence now derives public-unit values from the original request rather than normalized inch-valued params.

## Validated

- `bundle exec ruby -Itest test/semantic/path_builder_test.rb`
- `bundle exec ruby -Itest test/semantic/structure_builder_test.rb`
- `bundle exec ruby -Itest test/semantic/semantic_request_validator_test.rb`
- `bundle exec ruby -Itest test/semantic/semantic_request_normalizer_test.rb`
- `bundle exec ruby -Itest test/semantic/semantic_commands_test.rb`
- `bundle exec ruby -Itest test/runtime/native/mcp_runtime_loader_test.rb`
- `bundle exec rake ruby:test`
- `bundle exec rake ruby:lint`
- `bundle exec rake package:verify`

## Docs Updated

- `README.md`
- `sketchup_mcp_guide.md`
- `task.md`
- `plan.md`

## Remaining Gap

- SketchUp-hosted manual verification was not run, so live host confirmation of terrain-hosted and replace-preserve-identity flows remains outstanding.
