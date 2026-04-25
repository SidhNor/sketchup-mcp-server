# Staged Asset Reuse Tasks

## Source Specifications

These tasks are derived from:

- [Asset Exemplar Reuse HLD](../../hlds/hld-asset-exemplar-reuse.md)
- [PRD: Staged Asset Reuse](../../prds/prd-staged-asset-reuse.md)

## Task Set Intent

This task set covers the first staged asset reuse iteration. It starts from a zero-implementation baseline and establishes a user-curated in-scene Asset Exemplar workflow rather than integrating live public asset search.

The current task order proves the asset reuse capability through concrete, testable increments:

- curation and discovery of approved Asset Exemplars already present in the model
- instantiation of separate editable Asset Instances with source lineage
- exemplar-aware mutation guardrails for normal editing paths
- replacement of lower-fidelity proxies with staged assets while preserving workflow identity

## Current Task Order

1. [SAR-01 Curate And Discover Approved Asset Exemplars](SAR-01-curate-and-discover-approved-asset-exemplars/task.md)
2. [SAR-02 Instantiate Editable Asset Instances](SAR-02-instantiate-editable-asset-instances/task.md)
3. [SAR-03 Harden Exemplar Mutation Guardrails](SAR-03-harden-exemplar-mutation-guardrails/task.md)
4. [SAR-04 Replace Proxies With Staged Assets](SAR-04-replace-proxies-with-staged-assets/task.md)

## Deferred Follow-Ons

Deferred work is not promoted into active task folders in this iteration:

- deeper asset integrity and lineage validation after registration, instantiation, and replacement behavior exists
- live 3D Warehouse search, download, or marketplace integration
- ranking, recommendation, or advanced selection logic
- rich curation UI
- exemplar versioning, deprecation, and separate category-library management
- broad digital asset management behavior outside the in-scene Asset Exemplar workflow

## Notes

- User-curated 3D Warehouse assets are in scope only after they already exist in the SketchUp model.
- Asset Exemplars and Asset Instances must remain distinct domain objects.
- Existing platform, targeting, semantic, editing, and validation tasks remain dependency history and should not be rewritten by this task set.
