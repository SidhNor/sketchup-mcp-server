# SketchUp MCP

[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=SidhNor_sketchup-mcp-server&metric=alert_status)](https://sonarcloud.io/summary/new_code?id=SidhNor_sketchup-mcp-server)


This repository ships an MCP server inside a SketchUp extension.

- The extension code lives under `src/`.
- MCP tool registration and SketchUp behavior are both owned in Ruby.
- The packaged artifact is a single staged RBZ built from the vendored support tree.

## Repo Structure

```text
.
├── .github/
│   └── workflows/
├── config/
│   └── runtime_package_manifest.json
├── rakelib/
│   ├── package.rake
│   ├── release_support.rb
│   ├── ruby.rake
│   ├── version.rake
│   └── release_support/
├── specifications/
│   ├── adrs/
│   ├── guidelines/
│   ├── hlds/
│   ├── prds/
│   └── tasks/
├── src/
│   ├── su_mcp.rb
│   └── su_mcp/
│       ├── adapters/
│       ├── developer/
│       ├── editing/
│       ├── modeling/
│       ├── runtime/
│       │   └── native/
│       ├── scene_query/
│       └── semantic/
└── test/
    ├── adapters/
    ├── editing/
    ├── modeling/
    ├── release_support/
    ├── runtime/
    │   └── native/
    ├── scene_query/
    ├── semantic/
    └── support/
```

Key root files:

- `Rakefile`: canonical local validation and packaging entrypoints
- `releaserc.toml`: CI-owned semantic-release configuration
- `VERSION`: release version source of truth
- `AGENTS.md`: contributor/repo operating guidance

## Local Development

Install Ruby tooling:

```bash
bundle install
```

The extension entrypoint is `src/su_mcp.rb`, which registers `src/su_mcp/main.rb` with SketchUp. On load, the extension installs menu actions for the MCP server and attempts to start it automatically when the staged vendored support tree is present.

For local development, load the extension from this repository by symlinking or copying the `src/` contents into SketchUp's `Plugins` directory.

Build the canonical RBZ package:

```bash
bundle exec rake package:rbz
```

Verify the staged package layout:

```bash
bundle exec rake package:verify
```

The package output is `dist/su_mcp-<version>.rbz`, where the version comes from `VERSION`.

## Current Tool Surface

The current MCP surface includes scene inspection, semantic scene modeling, and editing helpers such as:

- `get_scene_info`
- `list_entities`
- `get_entity_info`
- `find_entities`
- `validate_scene_update`
- `measure_scene`
- `sample_surface_z`
- `create_terrain_surface`
- `create_site_element`
- `set_entity_metadata`
- `create_group`
- `reparent_entities`
- `delete_entities`
- `transform_entities`
- `set_material`
- `boolean_operation`
- `eval_ruby`

Public geometric dimensions for `create_site_element` are interpreted and returned in meters, independent of the active SketchUp model unit display settings.
The public `create_site_element` request is sectioned: `elementType`, `metadata`, `definition`, `hosting`, `placement`, `representation`, and `lifecycle`, with optional `sceneProperties` for wrapper `name` and `tag`.
The sectioned shape remains the only canonical public contract. The runtime now has bounded recovery-only handling for two common caller mistakes: wrapping the whole request under top-level `definition`, and lifting family-owned geometry leaf fields to top level instead of keeping them inside `definition`. Ambiguous or wrong-family requests still refuse with structured correction details instead of acting like a second supported create shape.
For `elementType: "path"` with `hosting.mode: "surface_drape"`, the runtime now creates a terrain-following top ribbon that stays level across each cross-section, smooths along the path length, keeps the top surface slightly above terrain to avoid visual overlap, and still applies any `thickness` downward for visual grounding.
The hierarchy-maintenance surface is intentionally narrow: `create_group` creates either a plain group container or, when `metadata.sourceElementId` and `metadata.status` are supplied, a managed `grouped_feature` container with optional `sceneProperties.name` and `sceneProperties.tag`. `reparent_entities` explicitly reparents supported groups or component instances using the same compact target-reference contract (`sourceElementId`, `persistentId`, `entityId`).
`list_entities` is an explicit inventory tool that now requires `scopeSelector` (`top_level`, `selection`, or `children_of_target`) plus optional `outputOptions`.
`find_entities` is an exact-match targeting tool that now requires `targetSelector` with nested `identity`, `attributes`, and `metadata` sections.
`sample_surface_z` is an explicit-host surface interrogation tool. It requires `target` plus a canonical `sampling` object: use `sampling.type: "points"` with `sampling.points` for XY point batches, or `sampling.type: "profile"` with `sampling.path` plus exactly one of `sampleCount` or `intervalMeters` for ordered profile evidence. It returns structured hit, miss, or ambiguous sample results; overlapping host surfaces with multiple surviving z-clusters are reported as `ambiguous`. It does not perform broad scene probing or terrain validation.
`create_terrain_surface` creates or adopts a repository-backed Managed Terrain Surface. Use it for managed terrain state and owned derived terrain mesh output, not for semantic hardscape or general site-element creation. Create mode requires `lifecycle.mode: "create"` plus `definition.kind: "heightmap_grid"` and a simple `definition.grid`; adopt mode requires `lifecycle.mode: "adopt"` plus `lifecycle.target` using the compact target-reference shape. Runtime refusals echo finite choices such as `lifecycle.mode` and `definition.kind` through `allowedValues`, and adoption refuses caller `definition` or `placement` in this slice.
All public terrain coordinates and elevations are meters. In create mode, `placement.origin` is a world-space meter point, while `definition.grid.origin`, `definition.grid.spacing`, and `definition.grid.baseElevation` are owner-local meter values used to build the persisted terrain state and derived mesh.

```json
{
  "metadata": { "sourceElementId": "terrain-main", "status": "existing" },
  "lifecycle": { "mode": "create" },
  "placement": { "origin": { "x": 120.0, "y": 80.0, "z": 0.0 } },
  "sceneProperties": { "name": "Managed Terrain", "tag": "Terrain" },
  "definition": {
    "kind": "heightmap_grid",
    "grid": {
      "origin": { "x": 0.0, "y": 0.0, "z": 0.0 },
      "spacing": { "x": 1.0, "y": 1.0 },
      "dimensions": { "columns": 10, "rows": 10 },
      "baseElevation": 0.0
    }
  }
}
```

```json
{
  "metadata": { "sourceElementId": "terrain-main", "status": "existing" },
  "lifecycle": {
    "mode": "adopt",
    "target": { "sourceElementId": "existing-terrain" }
  },
  "sceneProperties": { "name": "Managed Terrain", "tag": "Terrain" }
}
```

Successful terrain creation and adoption return `success: true`, `outcome`, `operation`, `managedTerrain`, `terrainState`, `output.derivedMesh`, and `evidence`. The response includes terrain-state digest and mesh-count evidence, and adoption includes source replacement and sampling summaries. It does not expose raw SketchUp objects or durable generated face or vertex identifiers.
If adoption cannot sample every derived grid point, the `source_sampling_incomplete` refusal includes public diagnostics such as sample count, hit/miss/ambiguous counts, extent, dimensions, spacing, and the first incomplete sample points.
`validate_scene_update` is the first public validation surface. It accepts a top-level `expectations` object and currently supports `mustExist`, `mustPreserve`, `metadataRequirements`, `tagRequirements`, `materialRequirements`, and `geometryRequirements`, with each expectation using exactly one of `targetReference` or `targetSelector`. `metadataRequirements` is currently a presence-style check for managed object metadata keys such as `sourceElementId`, `semanticType`, `status`, `state`, and `structureCategory`; it is not the public dimension-validation path for values like `width`, `height`, or `thickness`. `geometryRequirements` now also supports `kind: "surfaceOffset"` for approximate bounds-derived anchor checks against an explicit `surfaceReference`, using `anchorSelector.anchor`, `constraints.expectedOffset`, and `constraints.tolerance`. The MVP anchor selectors are intentionally approximate and suitable only for simple rectangular or slab-like forms.
`measure_scene` is the direct structured measurement surface. It supports `bounds/world_bounds`, `height/bounds_z`, `distance/bounds_center_to_bounds_center`, `area/surface`, `area/horizontal_bounds`, and `terrain_profile/elevation_summary`, using compact references (`sourceElementId`, `persistentId`, or compatibility `entityId`). Terrain profile measurements require `sampling.type: "profile"` with `sampling.path` plus exactly one of `sampleCount` or `intervalMeters`; `samplingPolicy.visibleOnly` and `samplingPolicy.ignoreTargets` mirror explicit surface sampling policy. It returns meter or square-meter quantities with `outcome: "measured"`, returns `outcome: "unavailable"` when measurable evidence is absent, and uses `no_unambiguous_profile_hits` when profile samples encountered only ambiguous surface stacks. It refuses unsupported modes, kinds, or sampling types with `allowedValues`. It is not a validation verdict tool and does not expose slope, grade, clearance-to-terrain, trench/hump, fairness, terrain editing, or raw dictionary inspection.
Managed objects may persist additional semantic properties such as path width or planting height in the `su_mcp` dictionary, but those stored values are not yet a first-class public inspection or validation contract.
`delete_entities` replaces `delete_component` and deletes one explicitly referenced supported group or component instance, returning structured `operation` and `affectedEntities.deleted` data.
`transform_entities` and `set_material` now accept either legacy `id` or compact `targetReference` (`sourceElementId`, `persistentId`, `entityId`), refuse requests that provide both or neither, and return additive mutation envelopes with `outcome`, `id`, and `managedObject`.
`set_entity_metadata` remains the semantic metadata path and now supports approved soft-field updates for `status`, `structureCategory`, `plantingCategory`, and `speciesHint` while continuing to refuse protected managed-object identity fields. `structureCategory` currently uses the approved values `main_building`, `outbuilding`, and `extension`, and invalid or non-clearable metadata requests now return `allowedValues` when the runtime owns the finite or contextual set.
`create_site_element` keeps `hosting.mode` contextual by `elementType` rather than flattening it into one misleading global enum. The currently shipped hosting pairs are `path -> surface_drape`, `pad -> surface_snap`, `retaining_edge -> edge_clamp`, `tree_proxy -> terrain_anchored`, and `structure -> terrain_anchored`, and unsupported requests return the narrowed `allowedValues` for the requested element type. Terrain-anchored `tree_proxy` creation samples the terrain host at `definition.position.x/y` and replaces caller `position.z`; terrain-anchored `structure` creation samples one arithmetic-mean footprint point and keeps the built form planar rather than draping individual vertices.
`boolean_operation` currently accepts only `union`, `difference`, or `intersection`, and unsupported requests return a structured refusal with the rejected value and `allowedValues`.

## Local Validation

Run the local CI task set:

```bash
bundle exec rake ci
```

This runs:

- `version:assert`
- `ruby:lint`
- `ruby:test`
- `package:verify`

## Release Automation

Release automation is CI-owned and uses `python-semantic-release` from the standalone [`releaserc.toml`](./releaserc.toml) configuration. Normal development, testing, and package verification do not require a repo-local Python environment.

Prepare a local versioned artifact:

```bash
NEW_VERSION=0.1.1 bundle exec rake release:prepare
```

This syncs the version files and verifies the canonical RBZ package.

## VS Code Tasks

The workspace includes tasks for:

- `bundle install`
- `bundle exec rake ci`
- `bundle exec rake package:verify`
- launching SketchUp via the `SKETCHUP_EXECUTABLE` environment variable
