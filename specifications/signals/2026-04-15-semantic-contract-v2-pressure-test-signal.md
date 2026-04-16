# Signal: Pressure-Test A Potential V2 Semantic Contract Before The PRD Surface Expands

**Date**: `2026-04-15`
**Source**: Exploratory architecture review of future semantic-contract durability
**Related Signals**:
- [Grok Proposal To Revisit The SEM-02 Request Contract](./2026-04-14-sem-02-grok-contract-change-signal.md)
- [Semantic Lifecycle Gaps Still Force Eval Ruby Fallbacks](./2026-04-15-semantic-lifecycle-and-eval-ruby-gap-signal.md)
- [Greenfield Semantic Authoring Is Viable But Lifecycle Gaps Remain](./2026-04-15-greenfield-semantic-authoring-is-viable-but-lifecycle-gaps-remain.md)
**Related Artifacts**:
- [Possible Direction Option](./possible-direction-option.md)
- [SketchUp Ruby MCP Surface Guide For Site, Garden, And Landscape Modeling](../../sketchup_mcp_guide.md)
- [PRD: Semantic Scene Modeling](../prds/prd-semantic-scene-modeling.md)
- [HLD: Semantic Scene Modeling](../hlds/hld-semantic-scene-modeling.md)
- [SEM-02 Technical Plan](../tasks/semantic-scene-modeling/SEM-02-complete-first-wave-semantic-creation-vocabulary/plan.md)
**Status**: `captured`
**Disposition**: `exploratory - validate before any contract decision`

## Summary

The current semantic surface has enough evidence to show that greenfield semantic object creation is viable for the first-wave object types. That evidence is valuable, but it is still narrow.

The current feedback has not yet pressure-tested the public contract against:

- terrain-aware authoring
- wrapping or draping behavior
- neat terrain-conforming modeling across a site with heavy Z variation, hills, and slopes
- edge clamping
- parented creation under accepted hierarchy
- adoption of existing geometry
- identity-preserving replacement or rebuild
- richer multipart or multilevel semantic forms
- richer vegetation visuals beyond one or two generic proxy variants

The central concern preserved by this signal is not immediate implementation pain in `SEM-02`. It is the risk that the platform could continue expanding the PRD surface with more type-specific public payloads until the contract becomes an ongoing source of limits and repeated redesign pressure.

This signal does **not** conclude that the current contract must be replaced now. It also does **not** conclude that a proposed `v2` envelope is already correct. It records a possible direction and a validation method for testing that direction before more of the semantic surface is implemented.

## Core Question Preserved By This Signal

Before more semantic authoring, terrain, hosting, and lifecycle behavior are implemented, should the platform validate whether a more durable public `create_site_element` contract is needed so future capability growth does not keep colliding with the limits of the current request shape?

## Why This Signal Matters

The repo is still early enough that public contract changes are possible without a large migration burden.

That makes this a useful review point:

- if the current public shape is durable enough, the repo should keep the simpler live contract and avoid premature abstraction
- if the current public shape will predictably keep hitting the same limits as terrain, hosting, adoption, and lifecycle work arrive, it is cheaper to learn that now than after more of the PRD surface depends on it

The risk is not just cosmetic inconsistency. The deeper risk is building a surface that keeps requiring one-off payload sections and special-case semantics as the product expands.

## Current Evidence, Inference, And Assumption Split

### What Current Evidence Supports

- first-wave greenfield semantic creation is viable for the currently exposed types
- current external feedback is still concentrated on creation, lookup, cleanup, and basic metadata presence
- the most important follow-on gaps are currently lifecycle, hierarchy, adoption, inspection depth, and terrain-aware behavior rather than basic object creation
- the site context under discussion is strongly Z-varied, so future semantic creation must be evaluated against sloped, hilly, and terrain-wrapping scenarios rather than mostly planar examples
- vegetation expectations are broader than a single generic tree proxy posture and should be treated as a real future pressure on both contract shape and representation modes

### What This Signal Infers

- the current request shape may not be the final durable contract once more of the PRD surface is implemented
- the platform may benefit from a more stable outer contract that models recurring semantic axes directly instead of accumulating more type-specific outer fields

### What Remains An Assumption

- that a new public envelope would actually reduce long-term contract pressure rather than only making the JSON look cleaner
- that the same outer shape can survive terrain hosting, edge clamping, adoption, replacement, and richer structure or water-feature behavior without quickly deforming
- that the same outer shape can survive terrain-wrapping requirements across varied slopes and elevation changes without collapsing back into ad hoc geometry flags
- that richer vegetation coverage can be expressed through disciplined semantic and representation modes rather than a growing set of special-case tree or planting payload variants
- that a more generic outer contract would still keep Python thin and Ruby as the source of truth for semantics

## Hypothesis Under Exploration

One possible direction is that a future `create_site_element` contract could become more durable if it models recurring semantic axes explicitly rather than continuing to grow by adding more type-specific public shape rules.

The candidate recurring axes under exploration are:

- semantic family
- definition mode
- placement mode
- hosting mode
- representation mode
- lifecycle mode

Under this hypothesis, a future contract would remain strict and semantic-first, but would carry variation through explicit modes rather than through continued root-level or per-type contract drift.

## Candidate Pressure-Test Matrix

This matrix set is intentionally unconfirmed. It is a validation tool, not a contract decision.

The scenario rows are the primary signal. The mode columns are provisional hypotheses only and should be challenged during validation rather than treated as already-correct contract design.

The matrix set should therefore be read as:

- authoritative about the kinds of future scenarios the contract must survive
- exploratory about the exact `elementType`, mode names, and fit assessment

### Generic Pressure-Test Scenarios

These are reusable pattern cases. They are meant to expose the abstraction axes cleanly, independent of one specific site plan.

| Scenario | `elementType` | `definition.mode` | `placement.mode` | `hosting.mode` | `representation.mode` | `lifecycle.mode` | Provisional Fit | Why It Matters |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Basic terrace pad | `pad` | `polygon` | `absolute` | `none` | `procedural` | `create_new` | Yes | Baseline current creation case |
| Multi-level terrace | `pad` | `stepped_pad` or `tiered_profile` | `absolute` | `none` | `procedural` | `create_new` | Maybe | Tests vertical form growth without root-level contract sprawl |
| Terrain-following path | `path` | `centerline` | `host_resolved` | `surface_drape` | `procedural` | `create_new` | Yes | Tests terrain-aware hosting instead of planar-only geometry |
| Edge-clamped retaining edge | `retaining_edge` | `polyline` | `host_resolved` | `edge_clamp` | `procedural` | `create_new` | Yes | Tests whether edge logic can stay separate from geometry definition |
| Pondless waterfall proxy | `water_feature_proxy` | `feature_proxy` or `cascade_path` | `host_resolved` | `terrain_anchored` | `proxy` | `create_new` | Maybe | Tests a likely future family with nontrivial hosting and proxy behavior |
| Roofed structure | `structure` | `footprint_mass` or `enclosed_form` | `absolute` | `none` | `procedural` | `create_new` | Yes | Tests richer built-form growth beyond simple footprint extrusion |
| Existing geometry adoption | varies | `adopt_reference` | `preserve_existing` | `none` or `existing_parent` | `adopted` | `adopt_existing` | Must fit | Tests whether adoption is first-class instead of fallback Ruby |
| Replace while preserving identity | varies | existing or new mode | `preserve_context` | varies | `procedural` or `asset_instance` | `replace_preserve_identity` | Must fit | Tests revision-safe lifecycle rather than create-only thinking |
| Parented creation under accepted hierarchy | varies | any | `parented` | `parent_entity` | any | `create_new` | Must fit | Tests hierarchy-aware creation without one-off parent fields |
| Asset-backed tree | `tree_instance` | `asset_reference` | `absolute` or `host_resolved` | `surface_snap` | `asset_instance` | `create_new` | Yes | Tests separation between semantic identity and representation source |
| Projected geometry with ambiguous host | `path` or `retaining_edge` | `centerline` or `polyline` | `host_resolved` | `surface_drape` | `procedural` | `create_new` | Yes, but refused | Tests whether refusal behavior can stay explicit and structured |
| Rebuild proxy into richer form | varies | new mode | `preserve_context` | varies | `procedural` or `asset_instance` | `rebuild_preserve_identity` | Must fit | Tests whether rebuild stays distinct from create or adopt |

### Site-Specific Scenario Extensions

These scenarios extend the generic pattern cases with the actual site pressures currently under discussion, especially retained baseline adoption, steep or varied terrain, and richer vegetation or furnishing needs.

| Scenario | `elementType` | `definition.mode` | `placement.mode` | `hosting.mode` | `representation.mode` | `lifecycle.mode` | Provisional Fit | Why It Matters |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Retained house / extension / sheds from shared baseline | `structure` | `adopt_reference` | `preserve_existing` | `none` | `coarse_mass` or `adopted` | `adopt_existing` | Must fit | Tests retained built-form adoption from shared retained geometry rather than local recreation |
| Retained service concrete apron | `pad` | `adopt_reference` | `preserve_existing` | `none` | `adopted` or `surface_proxy` | `adopt_existing` | Must fit | Tests whether retained hardscape can be adopted without inventing a new retained-surface family |
| Retained service path legs | `path` | `adopt_reference` | `preserve_existing` | `terrain_anchored` or `existing_parent` | `adopted` or `path_surface_proxy` | `adopt_existing` | Must fit | Tests retained path adoption across terrain-sensitive site context |
| Drive lane | `path` | `centerline` or `corridor` | `absolute` | `terrain_anchored` | `path_surface_proxy` | `create_new` | Yes | Tests whether vehicular circulation can remain a path-like family rather than forcing a special drive type |
| Parking terrace / forecourt / garden terrace / threshold terrace | `pad` | `polygon` | `absolute` | `none` or `terrain_cut_fill` | `surface_proxy` | `create_new` | Yes | Tests multiple terrace semantics under one geometry family |
| Formal lawn plane | `pad` | `leveled_plane` | `absolute` | `terrain_cut_fill` | `surface_proxy` | `create_new` | Yes | Tests whether grading-intent surfaces remain pad variants |
| Terraced island platform | `pad` | `polygon` | `host_resolved` | `terrain_anchored` | `surface_proxy` | `create_new` | Yes | Tests terrain-hosted pad behavior rather than creating a new island family |
| Main gravel walk | `path` | `centerline` | `host_resolved` | `surface_drape` | `path_surface_proxy` | `create_new` | Yes | Tests neat terrain-wrapping path behavior across varied slopes and hills |
| Stepping-stone island route | `path` | `stepping_centerline` | `host_resolved` | `terrain_anchored` | `path_surface_proxy` | `create_new` | Maybe | Tests whether patterned paths need a disciplined mode rather than ad hoc stepping fields |
| Parking retaining edge | `retaining_edge` | `polyline` | `host_resolved` | `edge_clamp` | `edge_proxy` | `create_new` | Yes | Tests edge-conforming support on sloped or cut conditions |
| Irregular island retaining rim | `retaining_edge` | `closed_polyline` | `host_resolved` | `edge_clamp` | `edge_proxy` | `create_new` | Yes | Tests whether open and closed edge variants stay within one family |
| Entry stair run | `stair` | `run_profile` | `anchored_relative` | `terrain_to_pad` | `procedural` | `create_new` | No in current MVP | Tests whether stairs need first-class semantics rather than being faked as paths or retaining edges |
| Vehicular / pedestrian gate | `gate` | `line_segment` or `opening_ref` | `parented` or `anchored_relative` | `boundary_parent` | `procedural` | `create_new` or `replace_preserve_identity` | No in current MVP | Tests boundary-hosted elements and retained-versus-relocated lifecycle pressure |
| Bench / stone seat | `seat` | `asset_reference` or `footprint_proxy` | `anchored_relative` | `terrain_snap` or `pad_snap` | `asset_instance` | `create_new` | No in current MVP | Tests asset-backed site furnishing on varied terrain |
| Pondless waterfall | `water_feature` | `cascade_path` | `host_resolved` | `terrain_anchored` | `proxy` | `create_new` | Maybe | Tests directional flow, width variation, and possible subpart pressure under one family |
| Hedge / clipped screen band | `planting_mass` | `band_profile` | `along_path` or `hosted_relative` | `terrain_anchored` | `planting_band_proxy` | `create_new` | Yes | Tests linear planting behavior distinct from mass polygons |
| Border / drift / slope planting / waterfall bank | `planting_mass` | `mass_polygon` | `within_region` or `host_resolved` | `terrain_anchored` | `planting_mass_proxy` | `create_new` | Yes | Tests terrain-responsive mass planting across slope-heavy conditions |
| Productive berry edge | `planting_mass` | `band_profile` | `along_boundary` | `boundary_offset` | `planting_band_proxy` | `adopt_existing` or `modify_existing` | Yes | Tests retained productive planting as a distinct lifecycle case inside one family |
| New accent tree | `tree` | `canopy_proxy` | `anchored_relative` | `terrain_snap` | `tree_proxy` or `asset_instance` | `create_new` | Yes | Tests tree creation with richer representation choices than one or two generic variants |
| Retained single tree | `tree` | `adopt_reference` | `preserve_existing` | `terrain_snap` | `tree_proxy` | `adopt_existing` | Must fit | Tests retained tree adoption as a first-class flow |
| Retained tree line / cluster | `tree_group` | `linear_group` or `cluster_group` | `anchored_relative` | `terrain_snap` | `grouped_tree_proxy` | `adopt_existing` | Yes | Tests whether grouped vegetation needs a family or mode distinct from single trees |
| Formal room / compositional zone | `zone` | `region_polygon` | `absolute` | `none` | `reference_only` | `create_new` | Should be separate semantic layer | Tests whether non-physical planning/reference regions should stay outside the physical site-element contract |

## Candidate V2 Contract Shape Under Exploration

This shape is illustrative only. It is preserved here so later analysis can test whether it holds up under the scenarios above.

```json
{
  "contractVersion": 2,
  "elementType": "path",
  "metadata": {
    "sourceElementId": "main-walk-001",
    "status": "proposed",
    "name": "Main Walk",
    "tag": "proposed_hardscape",
    "material": "gravel_light"
  },
  "definition": {
    "mode": "centerline",
    "centerline": [[0.0, 0.0], [4.0, 1.0], [8.0, 1.0]],
    "width": 1.6,
    "thickness": 0.1
  },
  "placement": {
    "mode": "absolute"
  },
  "hosting": {
    "mode": "none"
  },
  "representation": {
    "mode": "procedural"
  },
  "lifecycle": {
    "mode": "create_new"
  }
}
```

This first sketch is intentionally minimal and still reflects the earlier exploratory posture.

Later sections in this signal refine several boundary choices further, especially:

- adoption moving out of `definition` and into `lifecycle`
- material and realization concerns moving toward `representation`
- composition moving into a separate layer rather than widening `create_site_element`

## Corrected Sketches After Boundary Analysis

These sketches are still exploratory. They are not final contract proposals.

They exist to keep the signal internally consistent after the later boundary and composition analysis.

### A. Atomic Create Sketch

This sketch reflects the current best boundary posture for a straightforward atomic create request.

```json
{
  "contractVersion": 2,
  "elementType": "path",
  "metadata": {
    "sourceElementId": "main-walk-001",
    "status": "proposed"
  },
  "definition": {
    "mode": "centerline",
    "centerline": [[0.0, 0.0], [4.0, 1.0], [8.0, 1.0]],
    "width": 1.6,
    "thickness": 0.1
  },
  "hosting": {
    "mode": "surface_drape",
    "target": {
      "sourceElementId": "terrain-main"
    }
  },
  "placement": {
    "mode": "absolute"
  },
  "representation": {
    "mode": "path_surface_proxy",
    "material": "gravel_light"
  },
  "lifecycle": {
    "mode": "create_new"
  }
}
```

### B. Atomic Adopt Sketch

This sketch reflects the corrected boundary that adoption belongs in `lifecycle`, not `definition`.

```json
{
  "contractVersion": 2,
  "elementType": "structure",
  "metadata": {
    "sourceElementId": "retained-house-main",
    "status": "retained"
  },
  "definition": {
    "mode": "footprint_mass",
    "structureCategory": "main_building"
  },
  "hosting": {
    "mode": "none"
  },
  "placement": {
    "mode": "preserve_existing"
  },
  "representation": {
    "mode": "adopted"
  },
  "lifecycle": {
    "mode": "adopt_existing",
    "source": {
      "sourceElementId": "shared-retained-shell-house-main"
    }
  }
}
```

### C. Atomic Replace-Preserve-Identity Sketch

This sketch keeps the replacement target in `lifecycle` and the resulting scene location in `placement`.

```json
{
  "contractVersion": 2,
  "elementType": "pad",
  "metadata": {
    "sourceElementId": "threshold-terrace-main",
    "status": "proposed"
  },
  "definition": {
    "mode": "polygon",
    "boundary": [[8.0, 37.8], [13.4, 37.8], [13.4, 42.1], [8.0, 42.1]]
  },
  "hosting": {
    "mode": "terrain_cut_fill",
    "target": {
      "sourceElementId": "terrain-main"
    }
  },
  "placement": {
    "mode": "parented",
    "parent": {
      "sourceElementId": "accepted-pass-root"
    }
  },
  "representation": {
    "mode": "surface_proxy"
  },
  "lifecycle": {
    "mode": "replace_preserve_identity",
    "target": {
      "sourceElementId": "threshold-terrace-main"
    }
  }
}
```

### D. Composition Sketches

These sketches are not part of `create_site_element`.

They are preserved here so the signal has a concrete picture of how composite feature assembly might stay out of the atomic semantic creation contract.

#### D1. Create Empty Or Populated Group

```json
{
  "groupType": "feature_group",
  "children": [
    {"sourceElementId": "tree-west-01"},
    {"sourceElementId": "tree-west-02"},
    {"sourceElementId": "tree-west-03"}
  ],
  "parent": {
    "sourceElementId": "accepted-pass-root"
  },
  "metadata": {
    "sourceElementId": "retained-west-apple-line",
    "status": "retained"
  }
}
```

Exploratory intent:

- if `children` is omitted, the tool creates an empty group
- if `children` is present, it groups them atomically
- child identities remain intact

#### D2. Reparent Entities

```json
{
  "entityIds": [
    {"sourceElementId": "ret-edge-001"},
    {"sourceElementId": "seat-002"}
  ],
  "targetParent": {
    "sourceElementId": "island-feature-group-01"
  }
}
```

Exploratory intent:

- move existing managed objects into an existing parent
- preserve child identities
- avoid making feature composition depend on repeated manual hierarchy repair

## Hard-Case Payload Probes

These payloads are not proposed as final contract examples. They are pressure probes.

The purpose of this section is to test whether the candidate outer envelope can express hard future cases cleanly enough to justify further contract exploration.

If these probes immediately require root-level exceptions, overlapping semantics, or unclear ownership between sections, the candidate `v2` direction should be treated as weak.

### 1. Retained Structure Adoption

```json
{
  "contractVersion": 2,
  "elementType": "structure",
  "metadata": {
    "sourceElementId": "retained-house-main",
    "status": "retained"
  },
  "definition": {
    "mode": "adopt_reference",
    "target": {
      "sourceElementId": "shared-retained-shell-house-main"
    },
    "structureCategory": "main_building"
  },
  "placement": {
    "mode": "preserve_existing"
  },
  "hosting": {
    "mode": "none"
  },
  "representation": {
    "mode": "adopted"
  },
  "lifecycle": {
    "mode": "adopt_existing"
  }
}
```

Pressure being tested:

- adoption is first-class rather than fallback Ruby
- retained baseline geometry can enter managed semantics without recreate-from-scratch behavior
- built-form category stays inside the semantic request rather than hiding in post-adoption metadata mutation

Refusal probes:

- target resolves to no entity
- target resolves ambiguously
- target is not adoptable as a managed `structure`
- target violates required structure invariants such as missing closed footprint-like body or unsupported wrapper posture
- requested `structureCategory` conflicts with already-bound semantic type or protected metadata

### 2. Terrain-Following Main Walk

```json
{
  "contractVersion": 2,
  "elementType": "path",
  "metadata": {
    "sourceElementId": "main-gravel-walk",
    "status": "proposed",
    "material": "gravel_light"
  },
  "definition": {
    "mode": "centerline",
    "centerline": [[3.2, 18.0], [7.8, 22.4], [12.6, 26.1], [18.9, 30.3]],
    "width": 1.6,
    "thickness": 0.08
  },
  "placement": {
    "mode": "host_resolved"
  },
  "hosting": {
    "mode": "surface_drape",
    "target": {
      "sourceElementId": "terrain-main"
    }
  },
  "representation": {
    "mode": "path_surface_proxy"
  },
  "lifecycle": {
    "mode": "create_new"
  }
}
```

Pressure being tested:

- path creation on strongly varied terrain
- draping belongs in hosting rather than being smuggled into geometry fields
- visual path representation can vary without changing the outer contract

Refusal probes:

- hosting target missing or ambiguous
- centerline self-overlap or insufficient distinct points
- drape target exists but cannot support the full path continuously
- resulting path would self-intersect after host resolution
- requested width or thickness is invalid after normalization

### 3. Edge-Clamped Retaining Edge

```json
{
  "contractVersion": 2,
  "elementType": "retaining_edge",
  "metadata": {
    "sourceElementId": "parking-retaining-edge-south",
    "status": "proposed",
    "material": "stone_edge_dark"
  },
  "definition": {
    "mode": "polyline",
    "polyline": [[1.0, 11.2], [9.4, 11.2], [10.8, 14.9]],
    "height": 0.45,
    "thickness": 0.25
  },
  "placement": {
    "mode": "host_resolved"
  },
  "hosting": {
    "mode": "edge_clamp",
    "target": {
      "sourceElementId": "terrain-main"
    }
  },
  "representation": {
    "mode": "edge_proxy"
  },
  "lifecycle": {
    "mode": "create_new"
  }
}
```

Pressure being tested:

- edge behavior is distinct from path drape behavior
- geometry definition can stay simple while hosting determines terrain relation
- retaining-edge family can scale from open to closed variants without changing the outer shape

Refusal probes:

- clamp target missing or ambiguous
- polyline degenerates after normalization
- clamp cannot be resolved consistently along the requested run
- requested edge height or thickness is incompatible with resolved host geometry
- open polyline request is supplied with a closed-edge-only representation mode

### 4. Stepping-Stone Route

```json
{
  "contractVersion": 2,
  "elementType": "path",
  "metadata": {
    "sourceElementId": "island-stepping-route-01",
    "status": "proposed"
  },
  "definition": {
    "mode": "stepping_centerline",
    "centerline": [[14.2, 31.0], [15.7, 32.4], [17.1, 34.1]],
    "stepLength": 0.65,
    "stepWidth": 0.42,
    "gapLength": 0.28
  },
  "placement": {
    "mode": "host_resolved"
  },
  "hosting": {
    "mode": "terrain_anchored",
    "target": {
      "sourceElementId": "terrain-main"
    }
  },
  "representation": {
    "mode": "path_surface_proxy"
  },
  "lifecycle": {
    "mode": "create_new"
  }
}
```

Pressure being tested:

- patterned-path variation without inventing a separate tool
- whether `path` can support both continuous and discrete-surface semantics without becoming incoherent
- whether pattern parameters belong in `definition` instead of leaking into representation or hosting

Refusal probes:

- stepping parameters produce overlapping or impossible step layout
- resolved terrain slope or spacing makes the pattern invalid under current builder rules
- `stepping_centerline` conflicts with a continuous-surface-only representation mode
- route is too short to satisfy the requested stepping pattern deterministically

### 5. Pondless Waterfall

```json
{
  "contractVersion": 2,
  "elementType": "water_feature",
  "metadata": {
    "sourceElementId": "pondless-waterfall-west-bank",
    "status": "proposed"
  },
  "definition": {
    "mode": "cascade_path",
    "centerline": [[21.4, 8.6], [20.3, 10.1], [19.0, 12.4]],
    "startWidth": 1.4,
    "endWidth": 0.8,
    "dropMode": "follow_host_fall"
  },
  "placement": {
    "mode": "host_resolved"
  },
  "hosting": {
    "mode": "terrain_anchored",
    "target": {
      "sourceElementId": "terrain-main"
    }
  },
  "representation": {
    "mode": "proxy"
  },
  "lifecycle": {
    "mode": "create_new"
  }
}
```

Pressure being tested:

- directional water-feature behavior on irregular terrain
- width variation without introducing root-level special fields
- whether one semantic family can later absorb reservoir, rock, or bank subparts without outer-contract collapse

Refusal probes:

- host does not provide a coherent downhill or supported cascade direction
- width transition or path geometry is invalid
- requested drop behavior conflicts with the resolved terrain shape
- builder requires unsupported subparts for the requested mode

### 6. Retained Tree Cluster

```json
{
  "contractVersion": 2,
  "elementType": "tree_group",
  "metadata": {
    "sourceElementId": "retained-west-apple-line",
    "status": "retained"
  },
  "definition": {
    "mode": "linear_group",
    "members": [
      {"target": {"persistentId": "1001"}},
      {"target": {"persistentId": "1002"}},
      {"target": {"persistentId": "1003"}}
    ]
  },
  "placement": {
    "mode": "preserve_existing"
  },
  "hosting": {
    "mode": "terrain_snap",
    "target": {
      "sourceElementId": "terrain-main"
    }
  },
  "representation": {
    "mode": "grouped_tree_proxy"
  },
  "lifecycle": {
    "mode": "adopt_existing"
  }
}
```

Pressure being tested:

- whether grouped vegetation is a real family or just a tree mode
- richer vegetation visuals beyond one or two repeated proxies
- adoption and grouping pressure at the same time

Refusal probes:

- one or more member targets are missing or ambiguous
- members resolve to incompatible semantic families
- grouping request violates managed-object ownership or duplication rules
- resolved members cannot support the requested grouped representation mode

### 7. Replace While Preserving Identity Under Accepted Hierarchy

```json
{
  "contractVersion": 2,
  "elementType": "pad",
  "metadata": {
    "sourceElementId": "threshold-terrace-main",
    "status": "proposed"
  },
  "definition": {
    "mode": "polygon",
    "boundary": [[8.0, 37.8], [13.4, 37.8], [13.4, 42.1], [8.0, 42.1]]
  },
  "placement": {
    "mode": "parented",
    "parent": {
      "sourceElementId": "accepted-pass-root"
    }
  },
  "hosting": {
    "mode": "terrain_cut_fill",
    "target": {
      "sourceElementId": "terrain-main"
    }
  },
  "representation": {
    "mode": "surface_proxy"
  },
  "lifecycle": {
    "mode": "replace_preserve_identity",
    "target": {
      "sourceElementId": "threshold-terrace-main"
    }
  }
}
```

Pressure being tested:

- replacement and hierarchy preservation in one request
- target identity and target parent are distinct concerns
- lifecycle pressure is not forced into post-create repair flows

Refusal probes:

- lifecycle target missing or ambiguous
- requested parent missing or incompatible
- replacement would violate protected metadata invariants
- target semantic family conflicts with requested replacement family or mode
- replacement cannot complete atomically inside one operation boundary

## Formal Comparison: Current Contract Vs Candidate V2

This section compares the current live `create_site_element` contract against the candidate `v2` envelope using a fixed hard-scenario suite.

The goal is not to prove that `v2` is correct. The goal is to make the comparison explicit enough that the remaining uncertainty is concrete.

### Comparison Rules

- `Strong fit` means the contract can express the scenario cleanly without obvious top-level contract distortion.
- `Awkward fit` means the scenario can only be expressed by stretching fields beyond their current intended meaning or by offloading too much behavior into undocumented Ruby interpretation.
- `No fit` means the scenario is outside the current contract posture.
- `Conceptual fit` means the candidate `v2` envelope appears able to express the scenario coherently on paper, but this is still unproven by implementation or refusal behavior.
- `Composite feature` means the scenario likely should not be treated as one atomic `create_site_element` call at all.

### Fixed Hard-Scenario Suite

| Scenario | Current Contract | Candidate `v2` | Current Pressure | `v2` Pressure | Comparison Result |
| --- | --- | --- | --- | --- | --- |
| Retained structure adoption | No fit | Conceptual fit | Current contract is create-oriented and lacks a first-class adoption path | `definition` and `lifecycle` both touch adoption semantics and must stay non-overlapping | `v2` materially stronger |
| Terrain-following main walk | Awkward fit | Conceptual fit | Current path contract supports centerline plus scalar elevation, but not terrain-hosted drape semantics | `hosting` appears like the right seam, but terrain resolution and refusal behavior are unproven | `v2` materially stronger |
| Edge-clamped retaining edge | Awkward fit | Conceptual fit | Current retaining-edge contract expresses line geometry and dimensions, but not host-edge resolution | `hosting` looks plausible, but edge-clamp semantics still need builder rules and refusal taxonomy | `v2` materially stronger |
| Stepping-stone route | Awkward fit | Conceptual fit | Current path surface is continuous and would need ad hoc path-specific pattern fields | `definition.mode` likely helps, but patterned path rules must not turn `definition` into a junk drawer | `v2` stronger but still risky |
| Pondless waterfall | No fit as one atomic element today | Conceptually weak as one atomic element | Current contract has no meaningful water-feature family | The newer comparison suggests this is probably a composite feature rather than a direct atomic family | Neither wins; composition layer needed |
| Retained tree cluster / line | No fit as one atomic element today | Conceptually weak as one atomic element | Current contract supports only single tree proxies | The newer comparison suggests grouped trees should likely be created or adopted individually and then composed | Neither wins; composition layer needed |
| Replace while preserving identity under accepted hierarchy | No fit | Conceptual fit | Current contract has no first-class replace-preserve-identity or parent-targeting posture | `placement` and `lifecycle` both touch context preservation and need strict ownership boundaries | `v2` materially stronger |

### Comparison Summary

The formal comparison does **not** show that the candidate `v2` envelope is already correct.

It **does** show something narrower and more important:

- the current contract is strong for first-wave atomic greenfield creation
- the current contract is weak for adoption, terrain-hosted creation, edge-hosted creation, and identity-preserving replacement
- some future pressures are not actually evidence for a bigger atomic create contract
- instead, they are evidence for a missing composition and hierarchy-editing layer

The most important comparison outcome is therefore:

- `v2` appears stronger than the current contract for adoption, hosting, and lifecycle-heavy atomic scenarios
- neither the current contract nor the candidate `v2` should treat composite feature assembly as one giant atomic semantic create request by default

## Section Boundary Analysis

This section captures the current best attempt at separating the candidate `v2` sections so the pressure test stops failing for avoidable reasons.

The boundary goal is:

- each section owns one kind of concern
- hard scenarios do not require the same fact to be expressed in two sections
- Ruby can normalize the contract without Python learning semantic policy

This analysis is about **request-section ownership**, not about how fields are persisted on managed objects after creation. Some request fields may still be persisted into managed metadata after execution.

### Proposed Section Ownership

| Section | Owns | Must Not Own | Notes |
| --- | --- | --- | --- |
| `metadata` | Durable workflow identity, status, provenance, semantic role labels, business-facing identifiers | Geometry recipe, host targets, parent targets, replacement targets, visual representation choices | `sourceElementId` and workflow state belong here; request-time `structureCategory` does not, even if it is later persisted on the managed object |
| `definition` | Intrinsic semantic recipe for one atomic element family: shape inputs, family-specific dimensions, subtype/category qualifiers, internal pattern parameters | Host resolution, parent context, adoption target references, replacement targets, visual mode selection | For `structure`, subtype/category belongs here; for `path`, centerline and stepping parameters belong here |
| `hosting` | How the intrinsic definition should resolve against external geometry such as terrain, edges, pads, or boundaries; host target references; conforming modes like drape, snap, clamp, cut/fill | Parent container, identity preservation, create/adopt/replace intent, family-intrinsic geometry | Terrain and boundary dependence belongs here, not in `definition` |
| `placement` | Intended scene context of the resulting managed object or wrapper: parent container, absolute/relative transform, anchor frame | Host target resolution, source/target references for adopt or replace flows, semantic identity | Placement is about where the result lives in scene structure after execution, not about how terrain shapes it |
| `representation` | How the semantic result should be realized visually or structurally: procedural, proxy, asset-backed, adopted-surface, grouped feature proxy; style hints tied to realization | Business identity, host dependence, adopt/replace targets, scene hierarchy intent | Material or appearance policy belongs here more naturally than in `metadata` |
| `lifecycle` | Operation intent relative to existing scene state: create, adopt, replace, rebuild, modify; source and target references for those operations; identity-handoff intent | Intrinsic geometry recipe, host resolution, parent container, visual style selection | Adoption and replacement belong here, not in `definition` |

### Boundary Corrections Surfaced By The Hard Cases

The hard-case probes exposed several overlapping seams in the earlier illustrative payloads.

#### 1. Adoption must move out of `definition`

The earlier probe used:

- `definition.mode = adopt_reference`
- `lifecycle.mode = adopt_existing`

That is one fact expressed twice.

The cleaner boundary is:

- `definition` describes what semantic object is being established
- `lifecycle` describes that the operation uses existing scene geometry rather than new geometry creation

So retained structure adoption should move toward:

- `definition`: semantic subtype or other family-specific qualifiers only
- `lifecycle`: `mode = adopt_existing` plus source target reference

#### 2. Replace-preserve-identity must keep target ownership in `lifecycle`

The replacement target should not be split across:

- `placement` for parent context
- `lifecycle` for identity handoff

The cleaner split is:

- `lifecycle` owns which existing managed object is being replaced or rebuilt
- `placement` owns only where the resulting representation should live

That allows a request to say:

- replace this object
- place the resulting representation under this parent

without confusing identity handoff with hierarchy intent.

#### 3. Terrain behavior must stay in `hosting`, not `definition`

Several future scenarios are strongly terrain-dependent:

- draped paths
- clamped retaining edges
- cut/fill pads
- terrain-snapped vegetation

Those should not become definition-mode variants unless the family itself changes.

The pressure-test conclusion here is:

- `definition` says what the path, pad, or edge is in semantic terms
- `hosting` says how it conforms to the site

#### 4. Representation richness should not leak into family count

Richer vegetation and proxy fidelity are real pressures, but they should not automatically create more atomic semantic families.

The cleaner boundary is:

- family stays semantic
- representation handles realization richness

That means:

- a tree can remain a tree whether realized as a simple proxy, richer proxy, or asset instance
- a planting mass can remain a planting mass whether realized as a simple proxy or richer grouped mass

#### 5. `name`, `tag`, and `material` need an explicit posture

The illustrative `v2` payload still kept some convenience fields in places that are not fully clean.

The current analysis suggests:

- `material` belongs more naturally under `representation`
- `name` and `tag` are scene-facing organizational properties, not durable business identity

This signal does not yet finalize whether those should become:

- a dedicated `sceneProperties` section
- or carefully scoped compatibility fields

But it does conclude they should not be treated as core semantic identity fields by default.

### Boundary Verdict

The candidate section split is stronger after these corrections, but not fully proven.

Current posture:

- `metadata`: mostly clear
- `definition`: mostly clear once adopt/replace references are removed
- `hosting`: strong and increasingly justified by the terrain-heavy scenarios
- `placement`: clear for parent/transform intent, but still needs discipline in replace-and-parent cases
- `representation`: increasingly important, especially for vegetation richness
- `lifecycle`: essential, but must own all adoption/replacement source or target references consistently

So the boundary analysis improves the candidate `v2` direction, but it still remains a designed posture rather than a validated one.

## Proposed Composition Posture

The comparison and newer scenario analysis indicate that some future pressures should not be solved by widening `create_site_element`.

The main distinction that now appears necessary is:

- atomic site elements
- composite features
- reference-only planning layers

### 1. Atomic Site Elements

These are valid `create_site_element` candidates.

They should create or adopt one managed object at a time.

Examples:

- `structure`
- `pad`
- `path`
- `retaining_edge`
- `planting_mass`
- `tree`
- likely later `seat`, `gate`, and `stair`

Atomic site elements may still be:

- terrain-hosted
- adopted from existing geometry
- replaced while preserving identity
- represented procedurally, as proxies, or via assets

But they remain one semantic object per request.

### 2. Composite Features

These should not be treated as one giant atomic semantic create request by default.

A composite feature is an assembly of multiple managed objects whose combined arrangement forms the feature.

Examples:

- retained tree line or orchard cluster
- pondless waterfall assembly
- terrace package consisting of pad, retaining edge, seating, and planting accents
- larger feature groupings that are useful for review, move, duplicate, or validation

Under this posture:

- child elements keep their own managed identities
- the feature container may optionally have its own feature-level identity
- grouping must not erase or merge child `sourceElementId` values
- validation and targeting may need both child-level and feature-level references

### 3. Reference-Only Planning Layers

Some useful workflow constructs are not physical site elements at all.

Example:

- `zone`

These should remain outside the physical `create_site_element` contract unless the product later defines a separate non-physical semantic layer explicitly.

### Composition Tooling Posture

The current pressure test suggests the product needs a composition layer in addition to atomic semantic creation.

The leanest useful posture is:

1. `create_group`
   - creates an empty group when no children are supplied
   - groups existing entities atomically when children are supplied
2. `reparent_entities`
   - moves one or more existing entities into a target parent atomically
3. later: `duplicate_entities`
   - remains separate because duplication is not the same semantic operation as reparenting
4. later: `replace_preserve_identity`
   - explicit lifecycle helper or semantic command rather than hidden grouping behavior

This posture is intentionally leaner than a wide composition tool catalog, but it still recognizes that duplication and identity-preserving replacement are distinct operations that should not be collapsed into `reparent`.

### Composition Boundary Rules

The proposed rules are:

- `create_site_element` owns atomic semantic object creation or adoption
- composition tools own container creation, grouping, and hierarchy changes
- lifecycle tools own duplication and identity-preserving replacement
- feature grouping must preserve child identities
- composite feature assembly should not be the reason `create_site_element` absorbs every future site concept as a new atomic family

### Composition Verdict

This posture resolves two important ambiguities from the earlier matrix:

- `tree_group` is better treated as a composite feature built from individual trees plus grouping
- `water_feature` is better treated as a composite feature assembled from atomic parts unless the product later wants a bounded proxy-only convenience type

That means the pressure test should now classify future scenarios in three buckets:

1. atomic `create_site_element` candidates
2. composition-layer candidates
3. reference-only or separate-layer candidates

## Readiness Check For PRD/HLD Escalation

This checklist answers a narrower question than “is `v2` right?”

It answers:

`Is the current pressure test mature enough to promote a specific contract direction into PRD/HLD?`

### Current Status

| Criterion | Status | Notes |
| --- | --- | --- |
| Future contract pressure is real | `met` | The comparison and matrices consistently show pressure around hosting, adoption, lifecycle, and richer representation |
| The fixed hard scenarios are concrete enough to test against | `met` | The signal now includes generic cases, site-specific extensions, and hard payload plus refusal probes |
| The current contract is formally weaker than the candidate `v2` in the most important atomic future cases | `met` | Adoption, terrain-hosted pathing, edge-clamping, and replace-preserve-identity all compare poorly against the current surface |
| The candidate `v2` envelope has a captured non-overlapping ownership posture between `definition`, `placement`, `hosting`, `representation`, and `lifecycle` | `met` | The section-boundary analysis now captures the intended ownership split, even though implementation validation is still pending |
| The candidate `v2` envelope has proven that it can handle all agreed hard scenarios without new top-level exceptions | `partial` | Atomic hosting and adoption cases look promising, but composition cases show that some pressures belong in a separate layer rather than the atomic create contract |
| Composition and grouping pressures are accounted for explicitly rather than being forced into `create_site_element` | `met` | The proposed composition posture now classifies atomic elements, composite features, and reference-only layers separately |
| Ruby-owned implementation fit has been proven sufficiently to show Python can remain thin | `partial` | Architecturally plausible, but not yet validated by a branch prototype or request-normalizer design |
| Refusal behavior has been validated on representative hard cases | `not met` | Refusal probes exist on paper only |
| Migration or compatibility posture from the live contract to a future `v2` is explicit | `not met` | No accepted migration story yet |

### Readiness Verdict

Based on the formal comparison above, this signal is:

- strong enough to justify a future contract-design or contract-comparison planning step
- strong enough to justify a small PRD/HLD note that contract durability is now an explicit architectural risk
- **not yet strong enough** to promote the candidate `v2` envelope itself into accepted PRD/HLD direction

In other words:

- the pressure test is good
- the comparison is now explicit
- the signal is closer to decision-grade than before
- the section boundaries and composition posture are now materially clearer
- but it is still not fully PRD-ready as a contract commitment

## What Would Make This PRD-Ready

The smallest remaining confirmation set is now clearer:

1. Freeze the atomic hard-scenario suite and the explicit composite-feature exclusions.
2. Validate the captured ownership boundary between:
   - `definition`
   - `placement`
   - `hosting`
   - `representation`
   - `lifecycle`
3. Validate the proposed composition posture explicitly:
   - what stays atomic in `create_site_element`
   - what moves to a feature-composition layer
4. Prove at least a minimal Ruby normalization design for three hard cases:
   - retained structure adoption
   - terrain-following path
   - replace-preserve-identity under hierarchy
5. Validate representative refusal behavior for those cases without adding root-level escape fields.
6. Define the migration posture:
   - additive `v2`
   - cutover `v2`
   - or explicit deferral with stronger internal normalization only

Until those are done, the right artifact posture is still:

- `signal`: yes
- `contract decision`: not yet

## Stability Map

This section distinguishes what now looks stable enough to carry forward from what still remains exploratory inside this signal.

### Currently Stable Conclusions

These points now appear strong enough to preserve across later PRD, HLD, or task work unless new evidence directly contradicts them.

- future contract pressure is real and is not limited to cosmetic payload inconsistency
- the strongest future pressures are:
  - terrain-hosted behavior
  - adoption of existing geometry
  - identity-preserving replacement or rebuild
  - richer vegetation representation
  - composition and hierarchy-aware feature assembly
- the current live contract is materially weaker than a mode-based envelope for atomic adoption, terrain-hosted creation, edge-hosted creation, and replace-preserve-identity scenarios
- not every future pressure should become a new atomic `create_site_element` family
- composite feature assembly should be treated separately from atomic semantic creation
- `tree_group` is better treated as composition over individual trees than as a default atomic create family
- pondless waterfall or similar assemblies are better treated as composite features unless the product later defines a bounded proxy-only shortcut intentionally
- `zone`-like constructs should remain outside the physical site-element contract unless a separate reference-layer contract is introduced
- the candidate section split only becomes coherent if:
  - adoption and replacement targets live in `lifecycle`
  - terrain and boundary conformity live in `hosting`
  - parent and transform intent live in `placement`
  - intrinsic family recipe stays in `definition`

### Still Exploratory

These points are materially clearer than before, but they are still not validated enough to treat as settled direction.

- the exact final `v2` outer envelope
- exact mode names for each section
- whether `seat`, `gate`, and `stair` should all become atomic semantic families or whether some should stay lower priority or be handled partly through assets
- whether `tree` should be the single family with richer representation modes, or whether a later split such as `tree_instance` remains useful
- how much appearance or scene-facing organization belongs in:
  - `representation`
  - `metadata`
  - or a separate `sceneProperties` section
- the final minimal composition surface:
  - whether `create_group` should support optional children directly
  - whether separate `reparent_entities` remains necessary in v1 of composition
- the migration posture from the current live contract to any future `v2`
- the exact refusal taxonomy for hosting-heavy and lifecycle-heavy scenarios
- whether the boundary split remains clean once real Ruby normalization is attempted for the hard scenarios

### What Would Most Likely Change This Signal

The strongest kinds of new evidence would be:

- a branch prototype showing the candidate section split collapses in real normalization logic
- repeated hard scenarios that force new top-level escape fields even after the boundary corrections
- evidence that terrain-heavy or adoption-heavy workflows can be handled cleanly by evolving the current contract without meaningful public sprawl
- evidence that composition needs are better solved by a different product surface than the currently proposed grouping posture

## Seven-Item Pressure-Test Results

This section captures the current preferred posture after walking through the seven biggest remaining contract questions one by one and comparing the local analysis against a separate `grok-4.20-0309-reasoning` review.

The result is still signal-level and not yet an adopted PRD/HLD direction, but the shape is now materially clearer than earlier in this document.

### 1. `adopt_existing` vs `create_new`

Current preferred result:

- `adopt_existing` stays inside the same `create_site_element` command family
- it belongs in `lifecycle`, not as a separate tool and not inside `definition`

Why this is the current preferred posture:

- adoption is a lifecycle axis for establishing a semantic object from existing scene geometry
- it is not a new semantic family
- splitting it into a separate public tool would work against the compact-constructor goal

### 2. `hosting` vs `placement`

Current preferred result:

- `hosting` owns terrain, surface, edge, and boundary conformity
- `placement` owns scene-graph insertion, parent container, and transform or anchor intent

Why this is the current preferred posture:

- terrain-heavy scenarios depend on host resolution before the object can be placed
- parented or preserved scene context is a different concern from geometry resolution

### 3. `representation`

Current preferred result:

- `representation` remains a first-class top-level section

Why this is the current preferred posture:

- richer vegetation and proxy or asset-backed realization are real pressures
- without `representation`, those pressures would leak into family count or into `definition`

### 4. Family Boundaries

Current preferred result:

- keep atomic:
  - `structure`
  - `pad`
  - `path`
  - `retaining_edge`
  - `planting_mass`
  - `tree`
- defer:
  - `seat`
  - `gate`
  - `stair`
  - `terrain_patch`
- composition-by-default:
  - `tree_group`
  - `water_feature`
- separate layer:
  - `zone`

Why this is the current preferred posture:

- it keeps the atomic semantic surface compact
- it prevents grouped or multipart features from forcing every future feature into `create_site_element`

### 5. Terrain-Heavy `pad`

Current preferred result:

- `pad` remains a coherent atomic family
- terrain-heavy cases should stay inside `pad` through disciplined `definition.mode` and `hosting.mode`

Current working boundary for `pad`:

- still `pad`:
  - terraces
  - lawn planes
  - leveled or cut/fill surfaces
  - terraced island platforms
- not `pad`:
  - enclosed built forms
  - multipart feature assemblies
  - non-physical planning regions

### 6. Refusal Behavior

Current preferred result:

- refusals should be section-scoped and structured
- each section should own its own refusal family
- a generic semantic fallback should remain available for cross-section invariant failures

Current working refusal posture:

- `definition`: invalid mode, missing recipe, contradictory qualifiers
- `hosting`: missing or ambiguous host, unsupported conformity, resolution failure
- `placement`: invalid parent, hierarchy conflict, anchor failure
- `representation`: unknown mode, incompatible realization, material unavailable
- `lifecycle`: missing or invalid source or target, identity conflict, non-atomic replacement failure

### 7. Scene-Facing Convenience Fields

Current preferred result:

- use a hybrid posture
- add optional `sceneProperties` for:
  - `name`
  - `tag`
  - `collection`
  - similar scene-facing organizational fields
- keep `material` and visual style hints under `representation`
- keep `metadata` limited to durable workflow identity and state

## Current Preferred Shape

The current preferred shape after the seven-item pass is:

```json
{
  "contractVersion": 2,
  "elementType": "path",
  "metadata": {
    "sourceElementId": "main-walk-001",
    "status": "proposed"
  },
  "sceneProperties": {
    "name": "Main Gravel Walk",
    "tag": "proposed_hardscape",
    "collection": "circulation"
  },
  "definition": {
    "mode": "centerline",
    "centerline": [[0.0, 0.0], [4.0, 1.0], [8.0, 1.0]],
    "width": 1.6,
    "thickness": 0.1
  },
  "hosting": {
    "mode": "surface_drape",
    "target": {
      "sourceElementId": "terrain-main"
    }
  },
  "placement": {
    "mode": "absolute"
  },
  "representation": {
    "mode": "path_surface_proxy",
    "material": "gravel_light"
  },
  "lifecycle": {
    "mode": "create_new"
  }
}
```

### Section Meanings In The Current Preferred Shape

- `metadata`
  durable business identity and workflow state
- `sceneProperties`
  scene-facing organization and naming only
- `definition`
  intrinsic semantic recipe for one atomic family
- `hosting`
  terrain, boundary, or host conformity rules
- `placement`
  resulting scene context and parent or transform intent
- `representation`
  visual or structural realization mode and material policy
- `lifecycle`
  create, adopt, replace, rebuild, and related source or target references

## Current Preferred Composition Shape

The current preferred posture is that composite feature assembly should not be widened into `create_site_element`.

The lean composition surface under exploration is:

1. `create_group`
   - creates an empty group when no children are supplied
   - groups existing children atomically when children are supplied
2. `reparent_entities`
   - moves one or more existing entities into a target parent atomically
3. later `duplicate_entities`
4. later `replace_preserve_identity`

This keeps:

- atomic site elements in the semantic creation command
- grouped or multipart features in a composition layer
- child managed identities preserved inside composite features

## Possible Ruby Validation Scenario

This section sketches the leanest Ruby-side implementation shape currently considered sufficient to validate the preferred `v2` contract boundaries without prematurely turning the signal into a full HLD.

This is not an implementation commitment. It is a validation sketch.

### Why This Section Exists

One of the remaining readiness questions was whether the preferred `v2` shape is actually compatible with a Ruby-owned normalization path that keeps Python thin.

The goal of this sketch is to answer a narrower question:

`Can the candidate contract be normalized and executed in Ruby without exploding into a large cross-product of command classes or pushing semantic logic into Python?`

### Current Seam Reuse

The live Ruby semantic path is already centered on:

- `SemanticCommands#create_site_element`
- `RequestValidator#refusal_for`
- `RequestNormalizer#normalize_create_site_element_params`
- `BuilderRegistry#builder_for(elementType)`
- `builder.build(...)`
- `metadata_writer.write!`
- `serializer.serialize`

The validation sketch below deliberately reuses that posture rather than inventing a new runtime architecture.

### Candidate Lean Ruby Flow

Current preferred validation flow:

1. Keep one public `SemanticCommands#create_site_element` entrypoint.
2. Replace the current normalizer with a `v2` normalizer that:
   - validates outer-section presence and ownership rules
   - normalizes the public request into one canonical Ruby hash
   - resolves the minimal lifecycle and hosting contexts needed for the hard cases
   - preserves the original public request in `__public_request__`
3. Keep `BuilderRegistry` keyed by atomic `element_type` only.
4. Let the selected builder consume:
   - normalized `definition`
   - resolved `hosting`
   - resolved `lifecycle`
   - `representation`
   - `placement`
5. Extend the existing metadata-writing path to also persist scene-facing properties where needed.
6. Serialize the resulting managed object using the existing serializer posture.

### Candidate Canonical Ruby Hash

The working internal shape under exploration is:

```ruby
{
  element_type: "path",
  metadata: {
    "sourceElementId" => "main-walk-001",
    "status" => "proposed"
  },
  scene_properties: {
    "name" => "Main Gravel Walk",
    "tag" => "proposed_hardscape",
    "collection" => "circulation"
  },
  definition: {
    "mode" => "centerline",
    "centerline" => [[0.0, 0.0], [157.48, 39.37], [314.96, 39.37]],
    "width" => 62.992,
    "thickness" => 3.937
  },
  hosting: {
    "mode" => "surface_drape",
    "target" => {"sourceElementId" => "terrain-main"},
    "resolved_target" => :terrain_entity_placeholder
  },
  placement: {
    "mode" => "absolute"
  },
  representation: {
    "mode" => "path_surface_proxy",
    "material" => "gravel_light"
  },
  lifecycle: {
    "mode" => "create_new"
  },
  __public_request__: {
    "contractVersion" => 2,
    "elementType" => "path"
  }
}
```

The exact internal scalar values above are illustrative only. The important point is that:

- public meter-valued geometry is converted once
- section ownership remains explicit
- the original public request is preserved for metadata and serializer needs

### Collapsed Validation Shape

The current preferred Ruby validation shape is intentionally leaner than the earlier multi-collaborator sketch.

Instead of introducing many new top-level command collaborators at once, the preferred validation cut is:

- one `V2RequestNormalizer#normalize_and_resolve(params)`
- existing `BuilderRegistry`
- existing metadata writer, extended where needed
- existing serializer

This means the validator or normalizer owns the minimal proof work for:

- section ownership enforcement
- adoption and replacement target resolution
- host target resolution for the tested modes
- public-unit to internal-unit normalization
- structured refusals when any of the above fail

### Sketch Pseudocode

```ruby
def create_site_element(params)
  refusal = validator.refusal_for(params)
  return refusal if refusal

  normalized = v2_request_normalizer.normalize_and_resolve(params)

  model.start_operation(OPERATION_NAME, true)
  entity = registry.builder_for(normalized[:element_type]).build(
    model: model,
    params: normalized
  )
  metadata_writer.write!(entity, metadata_attributes(normalized))
  metadata_writer.write_scene_properties!(entity, normalized[:scene_properties])
  result = {
    success: true,
    outcome: "created",
    managedObject: serializer.serialize(entity)
  }
  model.commit_operation
  result
rescue StandardError
  model.abort_operation if model.respond_to?(:abort_operation)
  raise
end
```

### Why This Is Considered Plausible

Current reasons this sketch still looks viable:

- it preserves one public command
- it keeps Python as a thin adapter
- it avoids turning the builder registry into a cross-product of lifecycle or representation modes
- it reuses the current command seam instead of inventing a second semantic runtime
- it is small enough to test the hard scenarios without fully committing to a final architecture

### What This Sketch Still Does Not Prove

This sketch does not yet prove:

- that the normalizer will stay clean once all hard scenarios are added
- that the refusal taxonomy remains compact and deterministic
- that the section boundaries stay non-overlapping in real code rather than on paper
- that migration from the live contract to `v2` is worth the cost

### Grok Review Of This Sketch

A separate `grok-4.20-0309-reasoning` review of this Ruby validation scenario agreed that it is a plausible way to validate the contract shape, but pushed on one important point:

- the earlier multi-collaborator version was not truly minimal
- the leanest validation path should collapse most of the proof work into a single `v2` normalizer plus the existing builder and metadata seams

That challenge materially improved this section.

Current takeaway:

- a Ruby validation scenario now looks plausible enough to test
- the leanest proof path is one normalized canonical request plus the current builder registry, metadata writer, and serializer posture
- this still belongs in the signal for now rather than being treated as a committed HLD design

## Premortem

This section applies the `task-planning` Step 10 premortem lens to the signal itself.

Premortem question:

`Assume this preferred v2 direction was carried forward and still failed to achieve its intended goal. What faulty assumptions would have caused that failure, and what needs to be corrected now?`

The intended goal under test is:

- avoid future public-contract limits
- keep Ruby as the clear semantic source of truth
- keep Python thin
- preserve a compact and durable public surface

### Premortem Finding 1: Section overlap survives the paper design and reappears in Ruby normalization

**Mismatch**

The signal now presents clean section boundaries, but the real Ruby normalizer may still need to interpret cross-section interactions repeatedly for hard cases such as:

- terrain-following paths
- stepping routes
- replace-preserve-identity under hierarchy

If that happens, the design would still look clean in the contract while becoming messy in implementation.

**Root assumption**

The section split is clean enough that Ruby can normalize it without repeatedly collapsing `definition`, `hosting`, `placement`, and `lifecycle` back together.

**Why it threatens the goal**

If the normalizer becomes the real semantic policy hub, then:

- Ruby semantics become harder to reason about
- future modes will still feel like contract pressure
- Python may be tempted to absorb more validation or compatibility checks

**Likely cognitive bias**

- anchoring bias on the elegance of the section model

**Mitigation to apply now**

- explicitly treat the section split as a falsifiable implementation hypothesis
- test the split against a minimal Ruby normalizer spike for the hardest atomic cases before treating the shape as decision-grade

**Evidence needed**

- a spike that normalizes at least:
  - retained structure adoption
  - terrain-following path
  - replace-preserve-identity under hierarchy
- a review of whether the normalizer stays disciplined or devolves into repeated cross-section special cases

**Classification**

- `can be validated before implementation`

### Premortem Finding 2: Representation richness quietly turns back into family sprawl

**Mismatch**

The signal assumes that richer vegetation and proxy fidelity can stay inside `representation`, but real implementation pressure may still push toward:

- new semantic families
- element-type forks
- representation-specific builder behavior that behaves like hidden family splits

**Root assumption**

`representation` is strong enough to absorb richness without forcing more atomic families.

**Why it threatens the goal**

If representation richness leaks back into family count, the public surface still grows and the contract still drifts, just under a nicer envelope.

**Likely cognitive bias**

- optimism bias about how much richness one representation layer can contain

**Mitigation to apply now**

- stress-test tree and planting scenarios specifically against:
  - simple proxy
  - richer proxy
  - asset-backed realization
- refuse any new atomic family justification unless representation demonstrably cannot contain it

**Evidence needed**

- a vegetation-focused scenario suite showing whether richer representation modes stay inside one `tree` family and one `planting_mass` family without new top-level fields

**Classification**

- `can be validated before implementation`

### Premortem Finding 3: Lifecycle modes fail atomicity in hierarchy-heavy scenes

**Mismatch**

The signal assumes `lifecycle` can stay first-class for adopt and replace flows, but those operations may fail in actual SketchUp scene state because:

- hierarchy-sensitive replacement is not truly atomic
- parent preservation and identity handoff are harder to combine than expected
- retries or orchestration may leak into Python or workflow code

**Root assumption**

Identity-preserving lifecycle operations can remain one-command Ruby-owned behaviors inside a single operation boundary.

**Why it threatens the goal**

If lifecycle flows cannot stay atomic and Ruby-owned, then:

- Python or workflow logic becomes thicker
- the contract gains awkward exceptions
- replace/adopt behavior becomes unreliable for the exact scenarios driving this redesign

**Likely cognitive bias**

- planning fallacy about hierarchy-heavy scene maintenance

**Mitigation to apply now**

- treat hierarchy-aware replace and adopt flows as the real stress cases for the design
- do not treat the lifecycle section as validated until one replace-under-parent scenario has been proven feasible in Ruby

**Evidence needed**

- one replace-preserve-identity spike under a nontrivial parent context
- explicit observation that the operation can complete atomically or fail cleanly without partial state

**Classification**

- `requires implementation-time instrumentation or acceptance testing`

### Premortem Finding 4: Composition surface is too weak, so composite pressure leaks back into `create_site_element`

**Mismatch**

The signal now treats `tree_group` and `water_feature` as composition-by-default, but if the composition layer is too weak in practice, teams may push multipart feature creation back into `create_site_element`.

**Root assumption**

The lean composition posture is strong enough that composite feature pressure will stay out of the atomic semantic create contract.

**Why it threatens the goal**

If composition is underpowered:

- multipart requests will re-enter the atomic contract
- the contract will widen again
- the atomic/composite distinction will fail in practice

**Likely cognitive bias**

- confirmation bias from seeing that composition resolves conceptual ambiguity on paper

**Mitigation to apply now**

- explicitly test the composition posture against at least two composite feature scenarios
- keep composition classified as part of the contract-pressure solution, not as a side topic

**Evidence needed**

- one grouped vegetation feature assembly
- one waterfall-like or terrace-package composite assembly
- evidence that these do not require widening `create_site_element`

**Classification**

- `can be validated before implementation`

### Premortem Summary

The premortem does **not** invalidate the current preferred shape.

It does tighten the signal in an important way:

- the biggest remaining risks are no longer vague
- they are now concrete falsifiable failure paths
- all four risks are rooted in whether the cleaned-up contract survives real Ruby execution and composition pressure

### Premortem Corrections To Carry Forward

The signal should now be read with these extra guardrails:

1. Treat the section split as an implementation hypothesis until the Ruby normalizer spike proves it.
2. Treat representation richness as a likely sprawl vector unless vegetation scenarios prove otherwise.
3. Treat hierarchy-aware lifecycle atomicity as a required proof point, not a background assumption.
4. Treat composition adequacy as part of the contract decision, not as a separate later convenience topic.

## Validation Checklist From The Premortem

This checklist converts the premortem findings into concrete next validations.

The intent is:

- prove or falsify the current preferred shape quickly
- keep the remaining uncertainty explicit
- avoid carrying the signal forward on confidence alone

### A. Ruby Normalizer Validation

- [ ] Implement a minimal Ruby `v2` normalizer spike that handles:
  - retained structure adoption
  - terrain-following path
  - replace-preserve-identity under hierarchy
- [ ] Confirm the spike can normalize these cases without turning into repeated cross-section special-case logic.
- [ ] Confirm the canonical normalized hash preserves clear section ownership for:
  - `definition`
  - `hosting`
  - `placement`
  - `representation`
  - `lifecycle`
- [ ] Record where section overlap still appears in the spike, if anywhere.

Success threshold:

- no new top-level escape fields
- no need to move semantic logic into Python
- no obvious collapse back into one monolithic request interpreter

### B. Vegetation And Representation Validation

- [ ] Test one `tree` family across at least:
  - simple proxy
  - richer proxy
  - asset-backed realization
- [ ] Test one `planting_mass` family across at least:
  - simple mass proxy
  - band-style realization
  - richer representation variant if available
- [ ] Confirm these do not require:
  - new atomic families
  - new top-level contract fields
  - representation-specific semantic identity rules

Success threshold:

- richer visual variation stays inside `representation`
- family count does not grow just to support visual richness

### C. Hierarchy And Lifecycle Validation

- [ ] Prototype one `adopt_existing` flow against real retained geometry.
- [ ] Prototype one `replace_preserve_identity` flow inside a nontrivial parent context.
- [ ] Confirm the operation can:
  - complete atomically
  - fail cleanly with no partial scene state
  - preserve business identity as intended
- [ ] Confirm target resolution and parent placement do not force Python-side orchestration.

Success threshold:

- lifecycle-heavy operations remain Ruby-owned
- no partial replace or adopt state leaks into the model

### D. Composition Validation

- [ ] Test the lean composition posture against at least:
  - one grouped vegetation feature
  - one multipart feature assembly such as a terrace package or waterfall-like assembly
- [ ] Confirm these assemblies can be handled by:
  - `create_group`
  - `reparent_entities`
  - without widening `create_site_element`
- [ ] Confirm child managed identities remain intact after grouping.

Success threshold:

- composite feature pressure stays in the composition layer
- multipart assembly does not re-enter the atomic semantic create contract

### E. Refusal Validation

- [ ] Validate one representative refusal from each major section:
  - `definition`
  - `hosting`
  - `placement`
  - `representation`
  - `lifecycle`
- [ ] Confirm refusal payloads remain:
  - structured
  - deterministic
  - section-scoped
- [ ] Confirm at least one cross-section invariant failure still maps to a generic fallback without ambiguity.

Success threshold:

- refusal behavior remains toolable and does not depend on vague free-form error text

### F. Contract Viability Decision Check

Only move this signal toward contract direction if all of the following are true:

- [ ] the Ruby normalizer spike stays disciplined
- [ ] vegetation richness stays inside `representation`
- [ ] lifecycle-heavy flows remain atomic and Ruby-owned
- [ ] composition is strong enough to keep multipart pressure out of `create_site_element`
- [ ] refusal behavior is explicit and stable
- [ ] no new top-level escape fields were needed during validation

If any of these fail, the preferred shape should be revised before being treated as decision-grade.

## Why This Candidate Shape Is Being Considered

The candidate shape is being preserved because it could offer one stable outer envelope for future variation without forcing every new semantic family or lifecycle behavior to create a new public contract style.

The candidate shape is **not** being preserved because it is already proven simpler.

## Ruby Spike Findings (2026-04-16)

`SEM-05` has now validated the candidate `v2` shape through the live Ruby semantic seam rather than through chat-only reasoning.

Implemented proof posture:

- `contractVersion: 2` branching was added inside the existing Ruby semantic path:
  - `SemanticCommands#create_site_element`
  - `RequestValidator#refusal_for`
  - `RequestNormalizer#normalize_create_site_element_params`
- Python and the shared bridge contract were intentionally left unchanged.
- The spike proved:
  - retained structure adoption
  - terrain-following path with hosting-target resolution
  - `replace_preserve_identity` under hierarchy
- One hybrid high-risk proof test used the real command, validator, normalizer, and target-resolution path, with only terminal builder mechanics doubled.

Observed outcome:

- The candidate `v2` section split is strengthened by implementation evidence.
- `metadata`, `definition`, `hosting`, `placement`, and `lifecycle` remained distinct enough to survive the Ruby seam for the spike scenarios.
- No new top-level escape fields were needed.
- `sceneProperties` were not required for the proof.

Important remaining caveat:

- The strongest remaining overlap is still the command-level translation from the sectioned `v2` envelope into the current builder-facing `v1` payload shape.
- That means the signal is stronger than before, but not yet equivalent to saying the builders natively accept the `v2` shape.

Current interpretation:

- The candidate `v2` direction is no longer just a conceptual hypothesis.
- It is now implementation-backed for the spike scenarios.
- The direction should still be treated as stronger but not final, because terrain behavior and replacement semantics were proven only to the spike’s bounded depth, not to full production depth.

The likely benefits under exploration are:

- a more durable outer contract for future capability growth
- cleaner separation between geometry definition, hosting, representation, and lifecycle intent
- fewer future public root-field additions as terrain, vegetation, and lifecycle behaviors grow

The likely risks under exploration are:

- the outer envelope becomes abstract without actually reducing internal complexity
- `definition` becomes a disguised junk drawer rather than a disciplined schema seam
- Python could accidentally start carrying too much semantic shape knowledge
- the candidate shape may still fail once tested against real terrain-wrapping, hosting, vegetation, and adoption scenarios

## Validation Questions Preserved By This Signal

The next validation pass should test questions like:

- Can the same outer envelope handle all scenarios in the pressure-test matrix without adding new top-level fields?
- Do the hard-case payload probes above fit the same envelope without section overlap or ad hoc escape fields?
- Are `definition`, `placement`, `hosting`, `representation`, and `lifecycle` truly separate concerns, or do they collapse into overlapping semantics?
- Can Ruby remain the sole owner of per-family and per-mode schemas while Python stays shallow?
- Does the proposed shape reduce long-term contract pressure, or does it only relocate complexity behind a cleaner wrapper?
- Which future scenarios actually justify a public contract change, and which are better solved by stronger Ruby internals behind the current surface?
- Can the contract express terrain-conforming creation cleanly enough that sloped and hilly site conditions do not force repeated one-off exceptions?
- Can vegetation richness expand through representation and family rules without degenerating into a flat list of one-off visual variants?

## Suggested Follow-On Activities

This signal should remain exploratory until at least the following are done:

1. Validate the pressure-test matrix against representative future scenarios rather than greenfield creation only.
2. Test whether the candidate axes are sufficient for terrain wrapping, draping, edge clamping, adoption, replacement, hierarchy-aware creation, and richer vegetation coverage.
3. Draft hard-case payloads and refusal probes for the strongest scenarios, then identify where the candidate shape stays clean and where it immediately requires exceptions.
4. Compare the candidate shape against the current live contract in terms of:
   - long-term public contract durability
   - Ruby-owned implementation clarity
   - Python thin-adapter discipline
   - migration cost
5. Only after that validation, decide whether this becomes:
   - a future contract-change signal only
   - a dedicated `v2` contract-design task
   - or a rejected exploratory path

## Non-Decision Note

This signal is intentionally not framed as a decision.

The pressure-test matrix is not yet confirmed.

The candidate `v2` shape is not yet accepted.

No PRD, HLD, or task artifact should be treated as changed by this signal alone.
