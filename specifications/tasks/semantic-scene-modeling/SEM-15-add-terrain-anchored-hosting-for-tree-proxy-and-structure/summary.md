# Summary: SEM-15 Add Terrain-Anchored Hosting for Tree Proxy and Structure

## Status

Completed.

## Shipped

- Added `SU_MCP::Semantic::TerrainAnchorResolver` for single-point terrain height resolution using `SurfaceHeightSampler`.
- Expanded `create_site_element` contextual hosting support to:
  - `tree_proxy -> terrain_anchored`
  - `structure -> terrain_anchored`
- Wired `tree_proxy + terrain_anchored` so the sampled terrain height at `definition.position.x/y` replaces caller `position.z`.
- Wired `structure + terrain_anchored` so one arithmetic-mean footprint anchor determines the planar base elevation.
- Preserved no-partial-wrapper behavior by resolving terrain anchors before creating tree or structure wrapper groups.
- Made hosted `replace_preserve_identity` resolve and pass `hosting.resolved_target` consistently with `create_new`.
- Updated native loader guidance and README hosting guidance for the delivered contextual matrix.

## Validation

- `bundle exec ruby -Itest -e 'ARGV.each { |path| load path }' test/semantic/terrain_anchor_resolver_test.rb test/semantic/tree_proxy_builder_test.rb test/semantic/structure_builder_test.rb test/semantic/semantic_commands_test.rb test/runtime/native/mcp_runtime_loader_test.rb`
- `RUBOCOP_CACHE_ROOT=tmp/.rubocop_cache bundle exec rubocop src/su_mcp/semantic/terrain_anchor_resolver.rb src/su_mcp/semantic/tree_proxy_builder.rb src/su_mcp/semantic/structure_builder.rb src/su_mcp/semantic/semantic_commands.rb src/su_mcp/runtime/native/mcp_runtime_loader.rb test/semantic/terrain_anchor_resolver_test.rb test/semantic/tree_proxy_builder_test.rb test/semantic/structure_builder_test.rb test/semantic/semantic_commands_test.rb test/runtime/native/mcp_runtime_loader_test.rb`
- `bundle exec rake ruby:test`
- `bundle exec rake ruby:lint`
- `bundle exec rake package:verify`
- Post-implementation Grok-4.20 review completed. No critical, high, or medium issues remained; low clarity suggestions were addressed and focused/full validation was rerun.

## Live SketchUp Verification

| Case | Result | Evidence |
|---|---:|---|
| P1 tree anchored on sloped terrain | PASS | Tree lower Z 3.54m; host sample at (56,76) = 3.54m |
| P2 structure centroid anchored | PASS | Structure lower Z 3.94m; centroid sample (57.5,76.5) = 3.94m |
| N1 unsampleable host refusal | PASS | Refused with `invalid_hosting_target`; source lookup returned none |
| N2 sample-miss refusal | PASS | Refused with `terrain_sample_miss`; source lookup returned none |
| N3 unsupported-family refusal | PASS | Refused with `unsupported_hosting_mode`; source lookup returned none |
| E1 partial footprint, centroid inside | PASS | Structure lower Z 4.04m; centroid sample (58,76.5) = 4.04m |
| E2 explicit conflicting tree Z | PASS | Input z=50; final lower Z 4.14m, matching hosted sample |
| E3 host target by sourceElementId | PASS | Source-id host resolved; tree lower Z 3.74m, matching sample |

### Additional Live Matrix

| Area | Case | Result |
|---|---|---:|
| Target resolution | Host by persistentId | PASS |
| Target resolution | Missing `hosting.target` | PASS, refused `missing_required_field` |
| Target resolution | Stale/nonexistent host id | PASS, refused `target_not_found` |
| Target resolution | Duplicate `sourceElementId` host | PASS, refused `ambiguous_target` |
| Host state | Hidden host | PASS, explicit target still sampled/anchored |
| Host state | Locked host | PASS, sampled/anchored; host remained locked |
| Dimensions | Tree zero height | PASS, refused `invalid_numeric_value` |
| Dimensions | Tree zero canopy X | PASS, refused `invalid_numeric_value` |
| Dimensions | Tree negative trunk | PASS, refused `invalid_numeric_value` |
| Dimensions | Structure negative height | PASS, refused `invalid_numeric_value` |
| Geometry | Structure two-point footprint | PASS, refused `invalid_geometry` |
| Geometry | Structure self-crossing footprint | PASS, refused `invalid_geometry` |
| Geometry | Structure missing footprint | PASS, refused `invalid_geometry` |
| Geometry | Tree missing position | PASS, refused `invalid_numeric_value` |
| Atomicity | All refused source IDs unresolved afterward | PASS |

### Live Findings

- Hidden hosts are sampleable when explicitly targeted by `create_site_element`.
- Locked hosts are sampleable, and the host lock state stayed intact.
- Duplicate `sourceElementId` targets can exist, but hosted creation refuses them as ambiguous.
- Refusal atomicity looked good: every refused call left no managed object resolvable by its requested `sourceElementId`.
- Minor wording/API consistency note: missing `definition.position` for `tree_proxy` refused as `invalid_numeric_value`, not `missing_required_field`.
