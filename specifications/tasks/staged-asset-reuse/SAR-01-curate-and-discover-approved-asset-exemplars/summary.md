# SAR-01 Implementation Summary

**Status**: `completed`  
**Task**: `SAR-01 Curate And Discover Approved Asset Exemplars`  
**Captured**: `2026-04-26`

## Delivered

- Added `curate_staged_asset` for metadata-only curation of an existing group or component instance as an approved Asset Exemplar.
- Added `list_staged_assets` for approved-only discovery with category, tag, attribute, approval-state, limit, and bounds options.
- Added `SU_MCP::StagedAssets` runtime support:
  - `AssetExemplarMetadata` for the metadata contract, finite option validation, JSON-safe attribute normalization, and approved-exemplar predicate.
  - `AssetExemplarSerializer` for selection-friendly JSON-safe summaries.
  - `AssetExemplarQuery` for approved-first traversal, filtering, default limit, max cap, and component instance scoping.
  - `StagedAssetCommands` for target resolution, validation-before-write curation, and list delegation.
- Updated scene-query serialization so `assetExemplar: true` entities with `sourceElementId` are not reported as Managed Scene Objects.
- Wired the new tools through the Ruby runtime public surface:
  - native MCP loader catalog, schemas, annotations, and descriptions
  - runtime dispatcher
  - runtime command factory
  - native contract fixtures
  - README tool list and examples

## Contract Notes

- SAR-01 staging is intentionally metadata-only. Curation writes `stagingMode: "metadata_only"` and does not move, wrap, reparent, tag, layer, lock, duplicate, delete, or geometrically mutate the source entity.
- SAR-01 supports only `approval.state: "approved"`, `staging.mode: "metadata_only"`, and `filters.approvalState: "approved"`.
- Unsupported finite values refuse with structured detail containing `field`, `value`, and `allowedValues`.
- `list_staged_assets` returns only complete approved exemplars by default. Incomplete, unapproved, or malformed exemplar metadata is excluded from normal discovery.
- Component-instance curation is instance-scoped. Definition-level exemplar metadata remains deferred for SAR-02/SAR-03 decisions.

## Tests Added

- Metadata policy coverage for complete/incomplete approved-exemplar predicates, required curation metadata, managed-scene field exclusion, unsupported finite option refusals, and recursive JSON-safe attribute normalization.
- Serializer coverage for JSON-safe asset summaries and optional bounds.
- Query coverage for approved-only listing, category/tag/attribute filters, unsupported approval refusal, invalid filter shapes, default/capped limits, and component instance versus definition-child scoping.
- Command coverage for curate-to-list behavior, validation-before-write/no-partial-write refusals, unsupported staging, missing target, and unsupported target type.
- Scene-query regression coverage proving Asset Exemplars with `sourceElementId` are not Managed Scene Objects while remaining targetable by `sourceElementId`.
- Runtime wiring coverage for dispatcher routing, command factory composition, loader catalog/schema annotations, facade exposure, and representative native contract fixtures.

## Validation

- Focused SAR-01 skeleton/integration set passed before broad validation.
- `bundle exec rake ci`: passed.
  - RuboCop inspected 185 files with no offenses.
  - Ruby tests: 682 runs, 3095 assertions, 0 failures, 35 skips.
  - Package verification passed and produced `dist/su_mcp-0.22.0.rbz`.
- `mcp__pal__.codereview` with `grok-4.20`: completed on the final change set.
  - Final review found no required fixes.
  - Earlier sequence findings were addressed before final validation: command no-partial-write tests were pulled earlier, component-instance scoping tests were added, finite refusal detail keys were asserted, loader annotations were asserted, and README parity was kept in the closeout checklist.

## Live SketchUp Validation

- Live or hosted SketchUp smoke validation was not run in this terminal environment because no SketchUp host was available.
- Automated coverage uses SketchUp API doubles and package/load verification, so the remaining gap is an end-to-end host check that curates a real group/component instance through the public MCP runtime and lists it back with the expected summary.

## Remaining Follow-Up

- Run a live SketchUp public-client smoke when a host is available:
  - curate a representative group
  - curate a representative component instance
  - list approved exemplars through MCP
  - confirm no partial metadata after a refused curation
  - confirm scene inspection does not classify the exemplar as a Managed Scene Object
- SAR-02 can consume the approved exemplar metadata contract for editable instance placement.
- SAR-03 should reuse `AssetExemplarMetadata.approved_exemplar?` for mutation guardrails rather than duplicating the predicate.

## Task Metadata Updates

- This summary records the shipped SAR-01 implementation, public contract changes, validation evidence, Grok review disposition, and remaining hosted verification gap.
- `task.md`, `plan.md`, and `size.md` still need closeout/status calibration after this summary-first step.
