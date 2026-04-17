# Summary: SEM-08 Adopt Builder-Native V2 Input for the Remaining First-Wave Families

## What Shipped

- `pad`, `retaining_edge`, `planting_mass`, and `tree_proxy` now consume section-native `definition` input directly in their builders.
- `SemanticCommands#create_site_element` no longer translates those four families into legacy builder payloads.
- `RequestValidator` now enforces the final remaining-family `definition.mode` vocabulary:
  - `pad`: `polygon`
  - `retaining_edge`: `polyline`
  - `planting_mass`: `mass_polygon`
  - `tree_proxy`: `generated_proxy`
- Transitional bridge modes from `SEM-06` are now refused with `unsupported_option` on `definition.mode`.
- `RequestValidator` now refuses non-finite `pad.definition.elevation` values with `invalid_numeric_value`.
- `RequestNormalizer` now defaults `tree_proxy.definition.canopyDiameterY` from `canopyDiameterX`, and the command metadata path keeps the same circular-canopy default.
- The migrated builders no longer keep the removed legacy payload fallbacks and now require section-native `definition` input.

## Validation

- `bundle exec ruby -Itest test/semantic/semantic_request_validator_test.rb`
- `bundle exec ruby -Itest test/semantic/semantic_request_normalizer_test.rb`
- `bundle exec ruby -Itest test/semantic/pad_builder_test.rb`
- `bundle exec ruby -Itest test/semantic/retaining_edge_builder_test.rb`
- `bundle exec ruby -Itest test/semantic/planting_mass_builder_test.rb`
- `bundle exec ruby -Itest test/semantic/tree_proxy_builder_test.rb`
- `bundle exec ruby -Itest test/semantic/semantic_commands_test.rb`
- `bundle exec rake ruby:test`
- `bundle exec rake ruby:lint`
- `bundle exec rake package:verify`

## Docs And Metadata

- Updated [sketchup_mcp_guide.md](../../../../sketchup_mcp_guide.md) to show the final `pad.definition.mode` example value.
- Updated [task.md](./task.md) status to `completed`.
- Updated [plan.md](./plan.md) with shipped implementation notes and final validation commands.

## Manual Verification Still Needed

- SketchUp-hosted smoke validation still remains for representative:
  - hosted `pad` creation with explicit `definition.elevation`
  - edge-clamped `retaining_edge` creation
  - `planting_mass` creation with wrapper fields
  - `tree_proxy` creation with omitted `canopyDiameterY`
