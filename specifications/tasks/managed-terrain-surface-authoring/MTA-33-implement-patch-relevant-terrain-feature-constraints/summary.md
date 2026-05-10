# Summary: MTA-33 Implement Patch-Relevant Terrain Feature Constraints

**Task ID**: `MTA-33`
**Status**: `implemented`
**Date**: `2026-05-10`

## Shipped Behavior

- Added `PatchRelevantFeatureSelector` to filter active effective terrain features by local patch
  relevance before CDT feature geometry is built.
- Preserved `EffectiveFeatureView` as the lifecycle and stale-index boundary.
- Added internal diagnostics for selection mode, active/included/excluded counts, strength counts,
  relevance exclusion reasons, and CDT fallback triggers.
- Preserved full-grid/create behavior: when no dirty/selection window is provided, all active
  effective features remain eligible.
- Added internal `cdtParticipation: skip` handling for unsupported, degenerate, feature-geometry,
  and selected-budget fallback cases.
- Updated `TerrainMeshGenerator` so CDT participation skips use the existing non-CDT output path
  without calling the CDT backend or leaking internal fallback vocabulary.
- Preserved public MCP contracts; no tool names, request schemas, public response shapes, public
  controls, or default CDT behavior changed.

## Validation

- Full Ruby suite: `bundle exec rake ruby:test`
  - `1280 runs`, `12844 assertions`, `0 failures`, `0 errors`, `37 skips`.
- Runtime lint: `RUBOCOP_CACHE_ROOT=tmp/.rubocop_cache bundle exec rake ruby:lint`
  - `315 files inspected`, `0 offenses`.
- Package verification: `bundle exec rake package:verify`
  - produced `dist/su_mcp-1.6.1.rbz`.
- Diff hygiene: `git diff --check`
  - clean after closeout metadata updates.

## Coverage Map

- Selector tests cover hash windows, `SampleWindow`, patch-domain windows, full-grid all-active
  mode, hard/protected inside/near/crossing/far behavior, touched unsupported hard skip, far
  unsupported hard exclusion, degenerate hard skip, firm/soft locality, survey-window-only
  relevance fallback, and the 40% cardinality threshold.
- Planner tests cover selector integration, active-only effective selection, stale-index refusal,
  large-history diagnostics, selected budget overflow, unsupported hard feature geometry skip, and
  full-grid preservation.
- Command tests cover changed-region forwarding into feature planning, selected feature geometry
  reaching CDT context, valid edit success when CDT participation is skipped, and repeated CDT
  skips not expanding dirty windows.
- Mesh generator tests cover accepted CDT generation for dirty-window feature geometry and
  `cdtParticipation: skip` falling back to current output without calling the CDT backend.
- Contract tests cover public no-leak behavior for patch-relevant diagnostics, raw feature IDs,
  patch windows, CDT participation, fallback triggers, and solver internals.

## Hosted SketchUp Verification

Hosted verification used `su-ruby` MCP tools only.

Six side fixtures were created at world `x = 50.0m`, with local terrain coordinates in meters and
without touching existing terrain:

| Fixture | Hosted Signal |
|---|---|
| `MTA-33-FX-01-hard-locality` | Far hard excluded, local hard selected, CDT eligible. |
| `MTA-33-FX-02-touched-protected` | Touched protected geometry selected, public edit succeeded. |
| `MTA-33-FX-03-firm-soft-locality` | Crossing/local firm-soft selected, far soft excluded. |
| `MTA-33-FX-04-cardinality` | Active hard `21`, selected hard `5`, about 76% reduction. |
| `MTA-33-FX-05-unsupported-hard` | Touched unsupported hard selected, far unsupported hard excluded, CDT skipped internally. |
| `MTA-33-FX-06-full-grid-control` | Full-grid mode selected all active hard/firm/soft features. |

MTA-32-style visual debug overlays were also rendered for inspection:

- Magenta accepted CDT proof meshes for FX-01 through FX-04.
- Orange skip marker for FX-05.
- Orange fallback proof mesh for FX-06 full-grid stress inspection.

## Code Review Disposition

Final implementation review findings were addressed or explicitly dispositioned after hosted
verification:

- Kept `EffectiveFeatureView` focused on lifecycle/stale-index semantics.
- Did not expand public `TerrainCdtResult` fallback enums for MTA-33 internal selector triggers.
- Covered unsupported touched versus unsupported far behavior in selector and hosted tests.
- Covered primitive/window normalization drift through selector, planner, and hosted diagnostics.
- Added the final review-requested survey-control regression for primitives that fall back to
  `relevanceWindow` instead of payload geometry.
- Renamed the private planner geometry helper to make the selected-feature boundary explicit.

Hosted verification was not rerun after those review follow-ups because they did not alter selector
runtime behavior, SketchUp scene mutation, feature geometry semantics, or CDT participation policy.
The final post-review validation was the Ruby test suite, lint, package verification, and diff
hygiene listed above.

## Remaining Gaps

- No public documentation update was required because no public MCP tool contract, schema, request,
  response, setup path, or user-facing workflow changed.
- No persistent feature spatial index was introduced; on-demand active feature scanning remains an
  accepted MTA-33 tradeoff. Split a future spatial-index task only if production-scale evidence
  shows selector scanning becomes dominant.
- Production SketchUp patch replacement remains MTA-34 scope. The visual debug meshes are
  inspection-only overlays and do not replace managed terrain output.
- MTA-34 can consume MTA-33 as a prepared dependency for patch-relevant feature constraints. MTA-33
  deliberately does not implement patch ownership, seam validation, local scene mutation, or undo
  semantics; those remain MTA-34 responsibilities.
