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
- Component-instance curation is instance-scoped. Definition-level exemplar metadata remains deferred for explicit future policy decisions.

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

- Live smoke was run externally against `TestGround.skp`.
- Passing live areas:
  - runtime reachable and `ping` passed
  - `tools/list` exposed `curate_staged_asset` and `list_staged_assets`
  - a controlled group fixture resolved uniquely by name
  - group and component curation returned `outcome: "curated"`
  - unsupported approval state refused with `unsupported_approval_state`
  - unsupported staging mode refused with `unsupported_staging_mode`
  - missing required metadata refused with `missing_required_metadata`
  - curation did not visibly move, reparent, tag, layer, lock, delete, duplicate, or otherwise mutate source geometry
  - curated exemplars were findable with `metadata.managedSceneObject: false`
- Live blocker found: `list_staged_assets` returned `count: 0` after successful curation for both group and component cases.
- Root cause: `assetAttributes` was written as a Ruby hash, which live SketchUp entity attributes did not preserve as a hash. Because `assetAttributes` is part of the complete exemplar predicate, live curated assets were treated as incomplete and skipped by discovery.
- Fix applied: `assetAttributes` is now stored as JSON text in the SketchUp attribute dictionary, decoded back to a hash on read, and an empty attributes object is accepted as complete metadata.
- Post-fix live rerun passed against the same existing assets:
  - `SAR Tree Oak Group Fixture` group curated with `outcome: "curated"`, `stagingMode: "metadata_only"`, and preserved attributes
  - `SAR Bench Wood` component instance curated with `outcome: "curated"`, `stagingMode: "metadata_only"`, and preserved attributes
  - approved-only `list_staged_assets` returned `count: 2`
  - `category: vegetation` with tags `sar01` / `oak` returned only the group
  - `category: furniture` with tags `sar01` / `bench` returned only the component instance
  - attribute filter `species: oak`, `fixture: group` returned only the group
  - attribute filter `material: wood`, `fixture: component` returned only the component instance
  - uncurated tag filter returned `count: 0`
  - side-effect check stayed clean: same persistent IDs, same bounds, same `Layer0`, unlocked, visible, still parented at model root, with no move/reparent/tag/layer/lock/delete/duplicate effect observed
- Added [live-mcp-verification.md](./live-mcp-verification.md) with the live MCP client matrix, request examples, human SketchUp checklist, pass/fail rules, and evidence template for that remaining host check.

## Remaining Follow-Up

- SAR-02 can consume the approved exemplar metadata contract for editable instance placement.
- Later reuse workflows should reuse `AssetExemplarMetadata.approved_exemplar?` for source selection and source-stability checks rather than duplicating the predicate.

## Task Metadata Updates

- Updated [task.md](./task.md) status to `completed`.
- Updated [plan.md](./plan.md) status to `implemented` and recorded implementation closeout notes.
- Updated [size.md](./size.md) status to `calibrated` with actual profile, validation evidence, and estimation delta.
- This summary records the shipped SAR-01 implementation, public contract changes, validation evidence, Grok review disposition, live smoke defect/fix, and post-fix live pass.
