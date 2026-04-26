# Summary: MTA-12 Add Circular Terrain Regions And Preserve Zones

**Task ID**: `MTA-12`
**Status**: `completed`
**Date**: `2026-04-26`

## Shipped Automated Behavior

- Added `region.type: "circle"` for `edit_terrain_surface` `target_height` and `local_fairing`.
- Added `constraints.preserveZones[].type: "circle"` for `target_height` and `local_fairing`.
- Kept `corridor_transition` limited to `region.type: "corridor"` and rectangle preserve zones.
- Added structured validation for circle `center.x`, `center.y`, and positive `radius` fields.
- Added mode-specific finite `allowedValues` refusals for unsupported circle region and preserve-zone combinations.
- Added `SU_MCP::Terrain::RegionInfluence` as a SketchUp-free helper for rectangle/circle influence weights and preserve-zone masks.
- Migrated target-height and local-fairing kernels to shared region influence math.
- Updated native loader schema, native contract fixture cases, and README matrix/examples for circle regions and preserve zones.

## Validation Evidence

- `bundle exec rake ruby:test`
  - 756 runs, 3648 assertions, 0 failures, 0 errors, 36 skips.
- `bundle exec rake ruby:lint`
  - 193 files inspected, no offenses detected.
- `bundle exec rake package:verify`
  - built and verified `dist/su_mcp-0.23.0.rbz`.
- Focused terrain suite during implementation:
  - 173 runs, 1478 assertions, 0 failures, 0 errors, 3 skips.
- Focused schema/contract suite during implementation:
  - 118 runs, 705 assertions, 0 failures, 0 errors, 31 skips.
- `test/support/native_runtime_contract_cases.json` parses successfully.

## Code Review

- Final Step 10 PAL/Grok-4.20 code review completed.
- Findings addressed:
  - Added explicit circle-vs-rectangle positive blend default parity coverage.
  - Documented the exact outer-boundary rectangle zero-weight parity test.
- No critical, high, or medium code-review findings remain open.

## Live SketchUp Verification Status

Live public MCP client verification completed on deployed changes and passed.

Fixtures used:

- `mta12-main`: 25x25, spacing 0.5 m, placement `(4000, 3000, 0)`.
- `mta12-fair`: 31x31, spacing 0.4 m, placement `(4020, 3000, 0)`, deterministic noisy state.
- `mta12-preserve-th`: 25x25, spacing 0.5 m, placement `(4040, 3000, 0)`.
- `mta12-preserve-fair`: 31x31, spacing 0.4 m, placement `(4060, 3000, 0)`, deterministic noisy state.
- `mta12-undo`: 17x17 undo fixture.
- `mta12-edge-circle`: 17x17 edge-clamp fixture.

Public MCP smoke matrix:

| ID | Scenario | Result |
|---|---|---|
| MTA12-01 | Create non-zero-origin/fractional terrain | PASS |
| MTA12-02 | Target-height circle edit | PASS |
| MTA12-03 | Local-fairing circle edit | PASS |
| MTA12-04 | Circular preserve zone + target height | PASS |
| MTA12-05 | Circular preserve zone + local fairing | PASS |
| MTA12-06 | Circle region refused for corridor | PASS |
| MTA12-07 | Circular preserve zone refused for corridor | PASS |
| MTA12-08 | Invalid circle shapes | PASS |
| MTA12-09 | Undo circle target-height edit | PASS |
| MTA12-10 | Output coherence / no public ID leak | PASS |
| Extra | Edge-touching circle clamp | PASS |

Key live evidence:

- Target-height circle changed revision `1 -> 2`; output digest matched updated state digest; center and full-weight samples reached `3.0`, blend sample changed to `2.12`, outside sample stayed `1.25`.
- Local-fairing circle changed 305 samples; residual improved `0.2483 -> 0.1170`; revision `2 -> 3`; outside control sample stayed stable.
- Circular preserve + target height reported `protectedSampleCount: 13`; protected center samples stayed `1.0`; unprotected sample inside edit reached `4.0`.
- Circular preserve + local fairing reported `protectedSampleCount: 21`; protected center stayed `0.53`; neighboring samples changed; residual improved `0.2630 -> 0.1378`.
- Corridor circle region and corridor circular preserve-zone requests refused with mode-specific `allowedValues` before mutation.
- Missing/invalid circle fields returned structured refusals on `region.center`, `region.radius`, or `region.center.x`; refusals left revision/digest unchanged.
- Undo restored revision `2 -> 1`, digest, and samples after a target-height circle edit.
- Edited outputs retained derived face/edge markings; no down or flat faces were found; public responses did not expose raw face IDs or vertex IDs.

Circular boundary suite:

| Case | Result | Evidence |
|---|---|---|
| Max corner circle | PASS | Changed region clamped to columns/rows `14..16`; max corner hit `3.0`, outside stayed `1.0`. |
| Partial outside overlap | PASS | Edited only in-bounds overlap; changed region min column `0`; outside samples stayed unchanged. |
| Fully outside circle | PASS | Refused `edit_region_has_no_affected_samples`; revision/digest unchanged. |
| Sub-spacing circle on sample | PASS | Radius `0.1` centered on a sample changed exactly one sample to `2.2`; adjacent samples stayed `1.0`. |
| Sub-spacing circle between samples | PASS | Radius `0.1` between samples refused `edit_region_has_no_affected_samples`. |
| Circular preserve partly outside terrain | PASS | Preserve clipped to in-bounds samples; `protectedSampleCount: 8`; protected edge samples stayed `1.0`; unprotected edit samples changed. |
| Preserve fully covers edit | PASS | Refused `edit_region_has_no_affected_samples`; revision/digest unchanged. |
| Blend halo clips at terrain edge | PASS | Changed region clamped to column `0`; core hit `3.0`, blend sample `1.15`, outside `1.0`. |

Output sanity across edge fixtures:

- Face count stayed `512`.
- All faces and edges remained marked as derived output.
- `downFaces: 0` and `flatOrDownFaces: 0` on every edited fixture.
- Refusal cases did not mutate revision or digest.

## Remaining Gaps

- Native contract transport tests are present but skipped in this local environment behind the staged runtime guard.
- No live verification gaps remain from the MTA-12 plan.
