# MCP Tool Reference

This document describes the public MCP tool surface for this extension, including request-shape expectations, supported options, and example payloads.

## Tool inventory

Current tools include:

- `get_scene_info`
- `list_entities`
- `get_entity_info`
- `find_entities`
- `validate_scene_update`
- `measure_scene`
- `sample_surface_z`
- `create_terrain_surface`
- `edit_terrain_surface`
- `curate_staged_asset`
- `list_staged_assets`
- `create_site_element`
- `set_entity_metadata`
- `create_group`
- `reparent_entities`
- `delete_entities`
- `transform_entities`
- `set_material`
- `eval_ruby`

## MCP prompts

The native runtime also exposes MCP prompts for reusable workflow guidance. Prompts are
workflow guidance, not required hidden context for calling ordinary tools correctly; generic
clients should still be able to call first-class tools safely from `tools/list` descriptions
and schemas.

Current prompts include:

- `managed_terrain_edit_workflow`: guidance for choosing bounded managed-terrain edit
  operations, protecting known-good terrain with preserve zones, and reviewing edit evidence.
- `terrain_profile_qa_workflow`: guidance for using point samples, profile samples, and
  terrain-profile measurement evidence to review terrain shape after edits.

Prompt bodies are available through `prompts/get`. This reference lists prompt availability
and placement rules only, so the runtime-owned guidance text stays in one place.

## Contract conventions

- Runtime-facing responses are JSON-serializable.
- Public geometry values are expressed in meters (or square meters for areas).
- Finite-option refusals use structured fields such as `field`, `value`, and `allowedValues`.
- Compact entity targeting uses `targetReference` (`sourceElementId`, `persistentId`, or compatibility `entityId`) unless a tool explicitly requires `targetSelector`.
- Public SketchUp entity identity is returned as `entityId` and, when available, `persistentId`; entity summaries do not expose a parallel `id` alias for SketchUp `entityID`.

## Core behavior notes by tool area

### Semantic creation and metadata

#### `create_site_element`

- Public dimensions are interpreted and returned in meters.
- The canonical request sections are:
  - `elementType`
  - `metadata`
  - `definition`
  - `hosting`
  - `placement`
  - `representation`
  - `lifecycle`
  - optional `sceneProperties` (`name`, `tag`)
- The runtime includes bounded recovery for two common malformed requests:
  - wrapping the entire request under top-level `definition`
  - lifting family-owned geometry leaf fields to top level
- Unsupported or ambiguous requests refuse with structured correction details.
- `hosting.mode` is contextual by `elementType`.

Currently shipped hosting pairs:

- `path -> surface_drape`
- `pad -> surface_snap`
- `retaining_edge -> edge_clamp`
- `tree_proxy -> terrain_anchored`
- `structure -> terrain_anchored`

Terrain-anchored behavior:

- `tree_proxy`: samples terrain at `definition.position.x/y` and replaces caller `position.z`
- `structure`: samples one arithmetic-mean footprint point and keeps the built form planar

#### `set_entity_metadata`

- Supports approved soft-field updates for:
  - `status`
  - `structureCategory`
  - `plantingCategory`
  - `speciesHint`
- Protected managed-object identity fields remain immutable.
- `structureCategory` allowed values: `main_building`, `outbuilding`, `extension`.

### Scene targeting and inspection

#### `list_entities`

Requires `scopeSelector`:

- `top_level`
- `selection`
- `children_of_target`

Optional: `outputOptions`.

#### `find_entities`

Requires `targetSelector` with nested sections:

- `identity`
- `attributes`
- `metadata`

#### `sample_surface_z`

- Explicit-host surface interrogation only (no broad scene probing).
- Requires `target` and a canonical `sampling` object.

Supported sampling shapes:

- `sampling.type: "points"` with `sampling.points`
- `sampling.type: "profile"` with `sampling.path` and exactly one of:
  - `sampleCount`
  - `intervalMeters`

Returns structured hit/miss/ambiguous samples; overlapping surfaces with multiple surviving z-clusters are reported as `ambiguous`.
Use point sampling to verify explicit controls or read back a known XY elevation. Use profile
sampling to review terrain shape between controls after regional edits, boundary edits,
fairing, or close point clusters.

### Terrain lifecycle

#### `create_terrain_surface`

Creates or adopts a managed terrain surface.

- Create mode:
  - `lifecycle.mode: "create"`
  - `definition.kind: "heightmap_grid"`
  - `definition.grid` required
- Adopt mode:
  - `lifecycle.mode: "adopt"`
  - `lifecycle.target` required
  - caller `definition` and `placement` are refused in this slice

#### `edit_terrain_surface`

Applies bounded intent-based edits to an existing managed terrain surface. A successful edit
means the command completed and solver guardrails accepted the result; it is not visual,
grading, or validation acceptance.

Required top-level fields:

- `targetReference`
- `operation.mode`
- `region.type`

Supported operation/region combinations:

| `operation.mode` | Supported `region.type` | Required operation fields | Required region fields |
| --- | --- | --- | --- |
| `target_height` | `rectangle`, `circle` | `targetElevation` | `bounds` for rectangle; `center`, `radius` for circle |
| `corridor_transition` | `corridor` | none beyond `mode` | `startControl`, `endControl`, `width` |
| `local_fairing` | `rectangle`, `circle` | `strength`, `neighborhoodRadiusSamples` | `bounds` for rectangle; `center`, `radius` for circle |
| `survey_point_constraint` | `rectangle`, `circle` | `correctionScope`, `constraints.surveyPoints` | `bounds` for rectangle; `center`, `radius` for circle |
| `planar_region_fit` | `rectangle`, `circle` | `constraints.planarControls` | `bounds` for rectangle; `center`, `radius` for circle |

Operation intent:

| `operation.mode` | Terrain intent |
| --- | --- |
| `target_height` | Impose a local area or pad-style target elevation. |
| `corridor_transition` | Express a linear corridor, ramp, or transition grade. |
| `local_fairing` | Smooth or finish existing terrain; do not use it to express grade intent. |
| `survey_point_constraint` | Correct measured points through local correction or a bounded smooth regional correction field. Regional scope is not implicit planar fitting, best-fit replacement, monotonic correction, or complete interior replacement. |
| `planar_region_fit` | Fit one coherent plane from three or more controls and replace mutable full-weight samples inside the bounded support region. Blend shoulders interpolate toward the plane. |

Additional terrain edit constraints:

- Local `region.blend.falloff`: `none`, `linear`, `smooth`
- Corridor `region.sideBlend.falloff`: `none`, `cosine`
- Positive corridor side-blend distance requires `cosine`
- `constraints.fixedControls` supported for `target_height`, `local_fairing`, `survey_point_constraint`, `planar_region_fit`
- `constraints.preserveZones`:
  - rectangle/circle support for `target_height`, `local_fairing`, `survey_point_constraint`, `planar_region_fit`
  - rectangle-only support for `corridor_transition`
  - primary protection mechanism for known-good terrain that should not drift
  - recommended near boundaries or known-good profiles outside the intended support area
- Regional `survey_point_constraint` safety is judged from resulting terrain shape and normalized
  correction scale. `evidence.survey.correction.regionalCoherence` reports
  `surveyResidualRange`, `supportFootprintLength`, `normalizedSurveyResidualRange`,
  `slopeMaxIncrease`, and `curvatureMaxIncrease`. Large absolute residual ranges can be valid
  when they span a large support footprint and produce acceptable grade/curvature.
- `planar_region_fit` uses `constraints.planarControls` in terrain-state public-meter
  coordinates. Controls require `point.x`, `point.y`, and `point.z`; `tolerance` is optional.
  Default control tolerance is `clamp(supportFootprintLength * 0.002, 0.03, 0.15)`,
  where rectangle support footprint length is the rectangle diagonal and circle support
  footprint length is the circle diameter, not the full terrain size.
- Planar controls must be representable by the edited discrete heightmap surface. Off-grid
  controls on hard edit boundaries can be refused with `planar_fit_unsafe` when unchanged
  neighboring samples would make exact public surface sampling disagree with the fitted plane.
  Move the controls inward, align the support to grid samples, widen the full-weight support,
  or add blend/support margin when exact sampled control satisfaction is required.

Safe terrain edit loop:

1. Choose the operation by terrain intent.
2. Bound the support region narrowly enough to match the intended edit.
3. Add `constraints.preserveZones` around terrain that should not drift.
4. Review edit evidence such as `changedRegion`, `maxSampleDelta`, planar residuals,
   survey residuals, preserve-zone drift, slope/curvature proxy changes, and regional
   coherence when present.
5. Verify non-trivial edits with `sample_surface_z` profiles or
   `measure_scene terrain_profile/elevation_summary`; point samples verify controls, while
   profiles verify shape between controls.

Grid-spacing limits:

- Terrain spacing limits the spatial detail that the heightmap can represent.
- Controls closer than a grid cell can share samples and interact strongly.
- Close points with sharp height differences may be refused or may move nearby samples.
- If close controls must both be honored, recreate or refine terrain with smaller spacing, or
  relax targets.

Terrain coordinate notes:

- All public terrain coordinates/elevations are meters.
- In create mode, `placement.origin` is world-space meters.
- `definition.grid.origin`, `spacing`, and `baseElevation` are terrain-state meters.
- In adopt mode, the terrain-state origin is derived from sampled source bounds.

### Staged asset workflows

#### `curate_staged_asset`

Marks an existing group/component instance as an approved asset exemplar.

Required fields:

- `targetReference`
- `metadata.sourceElementId`
- `metadata.category`
- `metadata.displayName`
- `approval.state: "approved"`
- `staging.mode: "metadata_only"`

Returns one JSON-safe `asset` summary.

SAR-01 curation is metadata-only: it does not import, move, reparent, tag, layer, lock, duplicate, or delete source geometry.

#### `list_staged_assets`

Supported filters/options:

- `filters.category`
- `filters.tags`
- `filters.attributes`
- `filters.approvalState: "approved"`
- `outputOptions.limit`
- `outputOptions.includeBounds`

Limits:

- default limit: 25
- maximum returned count: 100

### Validation, measurement, and editing helpers

#### `validate_scene_update`

- Accepts top-level `expectations`.
- Currently supports:
  - `mustExist`
  - `mustPreserve`
  - `metadataRequirements`
  - `tagRequirements`
  - `materialRequirements`
  - `geometryRequirements`
- Each expectation uses exactly one of `targetReference` or `targetSelector`.
- `metadataRequirements` is currently presence-style (not full public dimension-value validation).
- `geometryRequirements` supports `kind: "surfaceOffset"` with `surfaceReference`, `anchorSelector.anchor`, `constraints.expectedOffset`, and `constraints.tolerance`.

#### `measure_scene`

Supported measurement modes:

- `bounds/world_bounds`
- `height/bounds_z`
- `distance/bounds_center_to_bounds_center`
- `area/surface`
- `area/horizontal_bounds`
- `terrain_profile/elevation_summary`

Profile sampling requires `sampling.type: "profile"`, `sampling.path`, and exactly one of `sampleCount` or `intervalMeters`.

Returns `outcome: "measured"` when evidence exists, `outcome: "unavailable"` otherwise. Uses `no_unambiguous_profile_hits` when profile results are only ambiguous.
Use `terrain_profile/elevation_summary` as measurement evidence for terrain-shape review
between controls, not as a terrain validation verdict or pass/fail policy.

#### `get_entity_info`

- Returns one explicitly referenced entity summary.
- Requires canonical `targetReference` with `sourceElementId`, `persistentId`, or compatibility `entityId`.
- Public geometry-bearing response values, including bounds and instance origins, are meters.

#### `delete_entities`, `transform_entities`, `set_material`

- `delete_entities` deletes one explicitly referenced supported group/component instance.
- `transform_entities` transforms one explicitly referenced supported group/component instance; `position` values are meters.
- `set_material` applies a material to one explicitly referenced supported group/component instance.
- All three tools use canonical `targetReference` with `sourceElementId`, `persistentId`, or compatibility `entityId`.

## Example payloads

### `curate_staged_asset`

```json
{
  "targetReference": { "sourceElementId": "curatable-source-001" },
  "metadata": {
    "sourceElementId": "asset-tree-oak-001",
    "category": "tree",
    "displayName": "Oak Tree Exemplar",
    "tags": ["tree", "deciduous"],
    "attributes": {
      "species": "oak",
      "detailLevel": "high"
    }
  },
  "approval": { "state": "approved" },
  "staging": { "mode": "metadata_only" },
  "outputOptions": { "includeBounds": true }
}
```

### `list_staged_assets`

```json
{
  "filters": {
    "category": "tree",
    "tags": ["deciduous"],
    "attributes": { "species": "oak" },
    "approvalState": "approved"
  },
  "outputOptions": {
    "limit": 25,
    "includeBounds": true
  }
}
```

### `create_terrain_surface` (create mode)

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

### `create_terrain_surface` (adopt mode)

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

### `edit_terrain_surface` (`target_height`, rectangle)

```json
{
  "targetReference": { "sourceElementId": "terrain-main" },
  "operation": {
    "mode": "target_height",
    "targetElevation": 1.25
  },
  "region": {
    "type": "rectangle",
    "bounds": { "minX": 0.0, "minY": 0.0, "maxX": 10.0, "maxY": 8.0 },
    "blend": { "distance": 1.0, "falloff": "smooth" }
  },
  "constraints": {
    "fixedControls": [
      {
        "id": "threshold",
        "point": { "x": 2.0, "y": 3.0 },
        "tolerance": 0.01
      }
    ],
    "preserveZones": [
      {
        "id": "tree-root-zone",
        "type": "rectangle",
        "bounds": { "minX": 4.0, "minY": 4.0, "maxX": 5.0, "maxY": 5.0 }
      }
    ]
  },
  "outputOptions": { "includeSampleEvidence": false, "sampleEvidenceLimit": 20 }
}
```

### `edit_terrain_surface` (`target_height`, circle)

```json
{
  "targetReference": { "sourceElementId": "terrain-main" },
  "operation": {
    "mode": "target_height",
    "targetElevation": 1.1
  },
  "region": {
    "type": "circle",
    "center": { "x": 5.0, "y": 4.0 },
    "radius": 2.0,
    "blend": { "distance": 1.0, "falloff": "smooth" }
  },
  "constraints": {
    "fixedControls": [],
    "preserveZones": [
      {
        "id": "tree-root-zone",
        "type": "circle",
        "center": { "x": 5.0, "y": 4.0 },
        "radius": 0.75
      }
    ]
  },
  "outputOptions": { "includeSampleEvidence": true, "sampleEvidenceLimit": 8 }
}
```

### `edit_terrain_surface` (`local_fairing`)

```json
{
  "targetReference": { "sourceElementId": "terrain-main" },
  "operation": {
    "mode": "local_fairing",
    "strength": 0.35,
    "neighborhoodRadiusSamples": 2,
    "iterations": 2
  },
  "region": {
    "type": "rectangle",
    "bounds": { "minX": 2.0, "minY": 2.0, "maxX": 8.0, "maxY": 8.0 },
    "blend": { "distance": 1.0, "falloff": "smooth" }
  },
  "constraints": {
    "fixedControls": [],
    "preserveZones": [
      {
        "id": "tree-root-zone",
        "type": "rectangle",
        "bounds": { "minX": 4.0, "minY": 4.0, "maxX": 5.0, "maxY": 5.0 }
      }
    ]
  },
  "outputOptions": { "includeSampleEvidence": true, "sampleEvidenceLimit": 8 }
}
```

### `edit_terrain_surface` (`survey_point_constraint`)

```json
{
  "targetReference": { "sourceElementId": "terrain-main" },
  "operation": {
    "mode": "survey_point_constraint",
    "correctionScope": "regional"
  },
  "region": {
    "type": "rectangle",
    "bounds": { "minX": 0.0, "minY": 0.0, "maxX": 20.0, "maxY": 10.0 },
    "blend": { "distance": 2.0, "falloff": "smooth" }
  },
  "constraints": {
    "surveyPoints": [
      { "id": "left-1", "point": { "x": 0.0, "y": 0.0, "z": 1.1 }, "tolerance": 0.01 },
      { "id": "right-1", "point": { "x": 20.0, "y": 0.0, "z": 0.7 }, "tolerance": 0.01 }
    ],
    "fixedControls": [],
    "preserveZones": []
  },
  "outputOptions": { "includeSampleEvidence": false, "sampleEvidenceLimit": 20 }
}
```

### `edit_terrain_surface` (`planar_region_fit`)

```json
{
  "targetReference": { "sourceElementId": "terrain-main" },
  "operation": {
    "mode": "planar_region_fit"
  },
  "region": {
    "type": "rectangle",
    "bounds": { "minX": 0.0, "minY": 0.0, "maxX": 20.0, "maxY": 10.0 },
    "blend": { "distance": 2.0, "falloff": "smooth" }
  },
  "constraints": {
    "planarControls": [
      { "id": "sw", "point": { "x": 0.0, "y": 0.0, "z": 1.2 } },
      { "id": "se", "point": { "x": 20.0, "y": 0.0, "z": 1.2 } },
      { "id": "nw", "point": { "x": 0.0, "y": 10.0, "z": 1.7 } }
    ],
    "fixedControls": [],
    "preserveZones": []
  },
  "outputOptions": { "includeSampleEvidence": false, "sampleEvidenceLimit": 20 }
}
```

### `edit_terrain_surface` (`corridor_transition`)

```json
{
  "targetReference": { "sourceElementId": "terrain-main" },
  "operation": {
    "mode": "corridor_transition"
  },
  "region": {
    "type": "corridor",
    "startControl": {
      "point": { "x": 1.0, "y": 2.0 },
      "elevation": 0.5
    },
    "endControl": {
      "point": { "x": 8.0, "y": 2.0 },
      "elevation": 1.5
    },
    "width": 3.0,
    "sideBlend": { "distance": 1.0, "falloff": "cosine" }
  },
  "constraints": {
    "fixedControls": [],
    "preserveZones": []
  },
  "outputOptions": { "includeSampleEvidence": true, "sampleEvidenceLimit": 8 }
}
```

## Response-shape notes

### Terrain responses

Successful terrain creation/adoption returns `success: true` plus structured fields including:

- `outcome`
- `operation`
- `managedTerrain`
- `terrainState`
- `output.derivedMesh`
- `evidence`

Successful terrain edits return `success: true`, `outcome: "edited"`, and include:

- before/after `terrainState`
- derived-output evidence
- optional compact changed-sample evidence
- fixed-control and preserve-zone evidence
- always-present `warnings`

Review edit evidence before accepting non-trivial terrain edits. Important fields include
`changedRegion`, `maxSampleDelta`, planar residuals, survey residuals, preserve-zone drift,
slope/curvature proxy changes, and regional coherence when those fields are available.

Mode-specific compact evidence:

- `corridor_transition`: `evidence.transition`
- `local_fairing`: `evidence.fairing`
- `survey_point_constraint`: `evidence.survey`
- `planar_region_fit`: `evidence.planarFit`

Adoption refusal case:

- `source_sampling_incomplete` includes sample counts and first incomplete points.

No terrain response returns raw SketchUp objects, durable generated face/vertex IDs, solver matrices, output-plan internals, or survey/planar solver internals.

### Other response notes

- `measure_scene` is a measurement surface, not a validation verdict tool.
- Managed objects can store additional semantic values in `su_mcp`, but those stored values are not yet a first-class public inspection/validation contract.
