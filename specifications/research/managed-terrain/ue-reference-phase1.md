---
doc_type: research_reference
title: Managed Terrain Phase 1 UE Reference
status: research
last_updated: 2026-04-25
---

# Managed Terrain Phase 1 UE Reference

## Research Posture

This note is non-normative and research-only.

It preserves Unreal Engine Landscape documentation and source areas that may help later Managed Terrain Surface Authoring tasks reason about terrain-edit behavior, brush weighting, heightfield access, and fairing expectations. It does not define public MCP tool names, request schemas, response payloads, Ruby class names, repository layout, or architecture ownership for this repository.

Authoritative product, architecture, and domain direction remains in:

- [`../../prds/prd-managed-terrain-surface-authoring.md`](../../prds/prd-managed-terrain-surface-authoring.md)
- [`../../hlds/hld-managed-terrain-surface-authoring.md`](../../hlds/hld-managed-terrain-surface-authoring.md)
- [`../../domain-analysis.md`](../../domain-analysis.md)
- [`../../tasks/managed-terrain-surface-authoring/README.md`](../../tasks/managed-terrain-surface-authoring/README.md)

Use this note as a research map. Do not copy UE architecture into SketchUp MCP, and do not convert UE operation names into public tool commitments.

## Useful UE Documentation

The most relevant UE documentation areas for later terrain-kernel design are:

- Landscape Sculpt Mode: editing vocabulary, high-level sculpting model, and tool grouping.
- Landscape Smooth Tool: local smoothing expectations and neighborhood-style behavior.
- Landscape Flatten Tool: target-height and blend-toward-target behavior.
- Landscape Ramp Tool: controlled slope or corridor transition behavior.
- Landscape Brushes: brush size, strength, and falloff concepts.
- Landscape Edit Layers and Blueprint Brushes: ordered, replayable modifier concepts that may inform internal design, without becoming a Phase 1 requirement.

Reference links:

- [Editing Landscapes in Unreal Engine](https://dev.epicgames.com/documentation/unreal-engine/editing-landscapes-in-unreal-engine)
- [Landscape Sculpt Mode](https://dev.epicgames.com/documentation/unreal-engine/landscape-sculpt-mode-in-unreal-engine)
- [Landscape Smooth Tool](https://dev.epicgames.com/documentation/unreal-engine/landscape-smooth-tool-in-unreal-engine)
- [Landscape Flatten Tool](https://dev.epicgames.com/documentation/unreal-engine/landscape-flatten-tool-in-unreal-engine)
- [Landscape Ramp Tool](https://dev.epicgames.com/documentation/unreal-engine/landscape-ramp-tool-in-unreal-engine)
- [Landscape Brushes](https://dev.epicgames.com/documentation/unreal-engine/landscape-brushes-in-unreal-engine)
- [Landscape Edit Layers](https://dev.epicgames.com/documentation/unreal-engine/landscape-edit-layers-in-unreal-engine)
- [Landscape Blueprint Brushes](https://dev.epicgames.com/documentation/unreal-engine/landscape-blueprint-brushes-in-unreal-engine)
- [ULandscapeEditorObject API reference](https://dev.epicgames.com/documentation/en-us/unreal-engine/API/Editor/LandscapeEditor/ULandscapeEditorObject)

## Useful UE Source Areas

Later implementation tasks may inspect these UE source areas when a specific terrain-kernel question requires it:

- `Engine/Source/Editor/LandscapeEditor/Private/LandscapeEdMode.cpp`
- `Engine/Source/Editor/LandscapeEditor/Private/LandscapeEdModeTools.cpp`
- `Engine/Source/Editor/LandscapeEditor/Public/LandscapeEdModeTools.h`
- `Engine/Source/Editor/LandscapeEditor/Public/LandscapeEditorObject.h`
- `Engine/Source/Runtime/Landscape/Public/LandscapeEdit.h`

Expected research value:

- editor tool orchestration and parameter grouping
- brush size, strength, and falloff semantics
- heightmap access patterns and edit substrate assumptions
- local smoothing, target-height adjustment, and corridor transition behavior
- separation between editor interaction and terrain data mutation

## UE Inspection Cadence

| Task | UE inspection posture |
| --- | --- |
| `MTA-01` | Preserve research pointers and source posture only. Do not perform deep UE source inspection. |
| `MTA-02` | Inspect only if terrain-state storage or heightfield representation questions need a source sanity check. Keep exact storage and migration choices repository-owned. |
| `MTA-03` | Inspect only if adoption needs source-surface suitability or heightfield initialization comparisons. Do not import UE ownership or editor assumptions. |
| `MTA-04` | First substantial UE source inspection point. Use UE docs/source to compare bounded grade-edit semantics, target-height behavior, brush falloff, and deterministic sample updates. |
| `MTA-05` | Deepen UE source inspection for corridor transition behavior, ramp-like interpolation, lateral falloff, and dirty-region expectations. |
| `MTA-06` | Deepen UE source inspection for smoothing or fairing behavior, neighborhood influence, preserve controls, and defect-reduction expectations. |

## Responsible Use Rules

- Treat UE as behavioral and mathematical research input, not an architecture source of truth.
- Keep public MCP contract naming in the relevant implementation tasks, not in this research note.
- Keep repository architecture and Ruby layering in the HLD and implementation plans.
- Prefer targeted UE source inspection tied to the implementation question at hand.
- Record any adopted concept in the owning PRD, HLD, task plan, or runtime tests before relying on it as project direction.
