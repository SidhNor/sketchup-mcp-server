# Summary: MTA-34 Implement CDT Patch Replacement And Seam Validation

**Task ID**: `MTA-34`
**Status**: closed-blocked; partial infrastructure retained for MTA-35 planning
**Date**: `2026-05-10`

## Closure Disposition

MTA-34 is closed as blocked/incomplete, not accepted as product behavior. The retained work is useful replacement
infrastructure, but the task did not prove the planned product behavior because the production
runtime has no stable CDT-owned patch output lifecycle for MTA-34 to replace.

The next task definition is
[MTA-35 Productize Cached CDT Patch Output Lifecycle For Windowed Terrain Edits](../MTA-35-productize-cached-cdt-patch-output-lifecycle-for-windowed-terrain-edits/task.md).
MTA-35 owns patch output bootstrap, stable patch identity, dirty-window-to-patch mapping, repeated
edit lifecycle, full real command/planner/provider/mutation proof, hosted visual acceptance, and
timing evidence.

MTA-34 `size.md` has been calibrated for this blocked closeout outcome.

## Shipped Behavior So Far

- Added a private `PatchCdtReplacementResult` adapter that converts accepted MTA-32 patch proof
  evidence into a production-safe, JSON-safe replacement contract.
- Added a private `PatchCdtReplacementProvider` that invokes the MTA-32 proof runner internally,
  requests proof mesh evidence, and immediately strips validation-only `debugMesh` / `proofType`
  vocabulary from the replacement result.
- Added a pure `PatchCdtSeamValidator` for replacement-border versus preserved-neighbor seam
  checks, including reversed/asymmetric subdivision support, XY/Z tolerance failures, duplicate
  border vertices, protected-boundary crossing, stale neighbor evidence, and expected-neighbor
  digest mismatch.
- Added an internally gated dirty-window CDT patch replacement branch in `TerrainMeshGenerator`.
  The branch runs only with an injected `cdt_patch_replacement_provider`, eligible feature geometry,
  dirty-window output intent, and non-skipped `cdtParticipation`.
- Added CDT patch ownership metadata on emitted patch faces:
  `outputKind`, `cdtOwnershipSchemaVersion`, `cdtPatchDomainDigest`,
  `cdtReplacementBatchId`, `cdtPatchFaceIndex`, `cdtBorderSide`, and `cdtBorderSpanId`.
- Preserved the no-delete-before-safe gate sequence:
  replacement accepted, existing CDT ownership valid, neighbor seam snapshots converted, seam
  validation passed, then affected patch faces are erased and replacement faces emitted.
- Preserved fallback/refusal behavior:
  incomplete replacement and ordinary seam mismatch fall back to current output; duplicate or
  integrity-mismatched CDT ownership refuses with generic public ownership vocabulary and no erase.
- Kept CDT disabled by default and kept public MCP request schemas, tool names, dispatcher routing,
  response shapes, README examples, and public controls unchanged.

## Current Validation Evidence

- Focused MTA-34 group before the final border-side metadata tweak:
  `75 runs`, `5156 assertions`, `0 failures`, `0 errors`, `0 skips`.
- Post-review terrain suite before the final border-side metadata tweak:
  `694 runs`, `11107 assertions`, `0 failures`, `0 errors`, `3 skips`.
- Full Ruby suite before the final border-side metadata tweak:
  `1295 runs`, `13474 assertions`, `0 failures`, `0 errors`, `37 skips`.
- Full RuboCop before the final border-side metadata tweak:
  `321 files inspected`, `0 offenses`.
- Package verification before the final border-side metadata tweak:
  `bundle exec rake package:verify` produced `dist/su_mcp-1.6.1.rbz`.
- Diff hygiene before the final border-side metadata tweak:
  `git diff --check` passed.

### Validation Still Needed After Latest Local Tweak

- Rerun focused MTA-34 tests after the `cdtBorderSide` / `cdtBorderSpanId` stamping correction.
- Rerun focused lint for `TerrainMeshGenerator`.
- Rerun at least the terrain suite after that correction before final closeout.

## Code Review Disposition

Required Step 10 review ran with `mcp__pal__codereview` using `model: "grok-4.3"`.

Findings addressed:

- Added/kept explicit provider-result guards proving `debugMesh` and `proofType` do not survive
  into `PatchCdtReplacementResult#to_h`.
- Added timing-bucket coverage proving default timing keys exist and later stage timings can
  override individual buckets.
- Extended seam validation to reject stale neighbor evidence when an expected neighbor digest is
  present but mismatched.

Additional local correction after review:

- Updated replacement face ownership stamping so normal border-participating triangles receive a
  `cdtBorderSide` and `cdtBorderSpanId`, instead of only degenerate all-points-on-one-side faces.

## Hosted Verification Matrix

Hosted verification attempted after code review follow-up, but the attempted probe is not accepted
as MTA-34 completion evidence. It used tiny synthetic rectangles and an injected fake replacement
provider, so it only smoke-tested a narrow mutation seam. It did not prove the required end-to-end
chain across MTA-33 feature selection, MTA-32 patch proof generation, and MTA-34 local replacement
over realistic multi-feature terrain.

Hosted save/reopen has been removed from the required matrix per user direction.

### Retained Code Surface For MTA-35

Retain these MTA-34 implementation surfaces as inputs for MTA-35 planning and audit:

- `src/su_mcp/terrain/output/terrain_mesh_generator.rb`
- `src/su_mcp/terrain/output/cdt/patches/patch_cdt_replacement_result.rb`
- `src/su_mcp/terrain/output/cdt/patches/patch_cdt_replacement_provider.rb`
- `src/su_mcp/terrain/output/cdt/patches/patch_cdt_seam_validator.rb`

Relevant upstream dependency surfaces:

- `src/su_mcp/terrain/commands/terrain_surface_commands.rb`
- `src/su_mcp/terrain/features/terrain_feature_planner.rb`
- `src/su_mcp/terrain/features/patch_relevant_feature_selector.rb`
- `src/su_mcp/terrain/features/terrain_feature_geometry_builder.rb`
- `src/su_mcp/terrain/features/terrain_feature_geometry.rb`
- `src/su_mcp/terrain/output/cdt/patches/patch_local_cdt_proof.rb`
- `src/su_mcp/terrain/output/cdt/patches/patch_topology_quality_meter.rb`

MTA-35 must audit retained MTA-34 components against stable patch identity, patch output bootstrap,
dirty-window-to-patch mapping, and repeated-edit lifecycle requirements before reusing them.

### Proper Hosted Evidence Added After Reset

The earlier separated patch-only visual rows were removed from the SketchUp scene and should not be
counted. The current hosted scene contains one complete terrain fixture per use case. Each fixture
is a 25x25 terrain around `x=50m`, shifted as a whole by y offset, with the CDT patch in its real
dirty-window position inside that terrain.

Materials:

- base terrain: `MTA34 proper base terrain - light gray`
- accepted CDT replacement: `MTA34 accepted CDT replacement - cyan`
- preserved CDT neighbor: `MTA34 preserved CDT neighbor - magenta`
- fallback full grid: `MTA34 fallback full grid - gray`
- refusal-retained CDT: `MTA34 refusal retained CDT - red`

Current hosted rows:

- `UC01-positive-multifeature`, group
  `MTA34 PROPER UC01-positive-multifeature terrain y=90m 20260510215157`
  - full terrain bounds: `x=50..74m`, `y=90..114m`
  - real command path; MTA-33 included hard `1`, firm `1`, soft `1`; excluded far hard `1`
  - MTA-32 accepted; replacement mesh `166` faces / `104` vertices / `11` border vertices per side
  - old CDT patch faces `166`; old faces remaining `0`; final CDT faces `166`
  - public no-leak passed; total `0.2266s`, MTA-32 solve `0.1486s`
- `UC02-repeated-same-patch-two-edits`, group
  `MTA34 PROPER UC02-repeated-same-patch-two-edits terrain y=130m 20260510215134`
  - two sequential command-path edits on the same CDT patch domain
  - first and second MTA-32 proofs accepted; first replacement faces were replaced by the second
    edit (`firstReplacementRemainingAfterSecond=0`)
  - final CDT faces `166`; public no-leak passed for both edits
  - second edit selected hard `2`, firm `2`, soft `2` due retained prior feature state plus the
    second edit features
- `UC03-affected-only-neighbor`, group
  `MTA34 PROPER UC03-affected-only-neighbor terrain y=170m 20260510215051`
  - affected patch and separate preserved neighbor patch both sit inside the full terrain fixture
  - affected old faces `148`; affected old remaining `0`
  - preserved neighbor faces `166`; neighbor remaining `166`
  - final CDT faces `332`; public no-leak passed
- `UC04-broad-topology-blocker`, group
  `MTA34 PROPER UC04-broad-topology-blocker terrain y=210m 20260510215055`
  - broad/intersecting features selected hard `1`, firm `1`, soft `1`; excluded far hard `1`
  - real MTA-32 proof returned `topology_quality_failed`
  - MTA-34 fell back to full-grid output; final CDT faces `0`; public no-leak passed
- `UC05-duplicate-ownership-refusal`, group
  `MTA34 PROPER UC05-duplicate-ownership-refusal terrain y=250m 20260510215058`
  - duplicate CDT ownership was introduced by duplicate face index metadata
  - command refused with `terrain_output_ownership_invalid`
  - old CDT faces `166`; old CDT remaining `166`; public no-leak passed

Hosted blockers discovered:

- Broad/crossing feature-window variants with non-compact soft or corridor features selected
  `cdtParticipation=eligible`, but MTA-32 returned `topology_quality_failed`; MTA-34 correctly
  fell back instead of local replacement. Observed runs include `20260510212930`,
  `20260510213007`, `20260510213032`, and `20260510213115`.
- A realistic preserved seam neighbor with varied Z along the border cannot currently be modeled as
  one SketchUp face because SketchUp rejects the nonplanar face (`Points are not planar`), while the
  current seam validator rejects multiple neighbor spans/faces on the same side as
  `duplicate_overlapping_border_faces`. This blocks honest hosted coverage for complex asymmetric
  preserved seams until the snapshot/validator model supports multiple ordered spans per side or a
  separate seam evidence carrier.

Attempted hosted smoke result, rejected as insufficient:

- Run id: `20260510210841`
- Placement: fresh top-level validation groups around world `x = 50m`
- Result after a hosted unit-conversion fix: smoke rows reported passed for local replacement,
  seam fallback, duplicate-ownership refusal, skip control, and timing bucket presence.
- Disposition: insufficient. The scenario scale and provider model were too small and synthetic to
  validate huge multi-feature intersections, feature edits, proper CDT patch changes over global
  terrain, or public command behavior.

Planned hosted matrix:

| ID | Purpose | Expected Signal | Status |
|---|---|---|---|
| `MTA34-HOST-01-real-chain-multifeature` | Create a larger global managed terrain around `x = 50m` with multiple hard anchors, firm crossing corridors, soft pressure regions, and protected zones; perform a dirty edit that intersects several feature types. | MTA-33 selects patch-relevant features, MTA-32 produces an accepted proof, MTA-34 adapts it into a replacement result, seam validation passes, and mutation mode is local patch replacement. | pending |
| `MTA34-HOST-02-affected-only-global-terrain` | Use the same larger terrain and compare pre/post entity identities and metadata for affected versus neighboring CDT patch output. | Only affected patch-domain faces are replaced; unaffected neighboring CDT output remains present and unchanged; replacement faces have complete CDT ownership and border metadata. | pending |
| `MTA34-HOST-03-complex-seam-asymmetry` | Exercise an accepted patch whose regenerated border has different subdivision density from preserved neighbors. | Span validation accepts compatible asymmetric subdivision and rejects the same fixture when a protected-boundary crossing is introduced. | pending |
| `MTA34-HOST-04-seam-mismatch-no-delete` | Force an incompatible preserved-neighbor border over the larger terrain. | Seam validation fails before local erase; old CDT output remains until current-output fallback succeeds; public response hides seam/fallback vocabulary. | pending |
| `MTA34-HOST-05-ownership-integrity-refusal` | Corrupt CDT patch ownership on the larger terrain with duplicate/missing/mixed metadata. | Public generic ownership refusal; original derived output remains present; unsupported children also fail closed before erase. | pending |
| `MTA34-HOST-06-repeated-adjacent-edits` | Run two or more adjacent dirty edits after an accepted local replacement. | Newly emitted CDT metadata is sufficient for the next local replacement; seams remain closed across edit boundaries. | pending |
| `MTA34-HOST-07-undo-positive` | Invoke SketchUp undo after an accepted real-chain local replacement. | Prior terrain state payload and derived output are restored together; subsequent edit reads the restored branch state. | pending |
| `MTA34-HOST-08-timing-comparison` | Capture timing buckets for real-chain local replacement and current-output fallback on the same fixture. | Patch solve/adaptation/ownership/seam/mutation timings are recorded; if ownership/snapshot scanning erases locality benefit, record a default-enable blocker or follow-up index/cache task. | pending |

## Public Contract And Docs

- No public contract change was made.
- No README or public docs update is required for this implementation slice because no public tool,
  request schema, response shape, setup path, user-visible workflow, selector, or diagnostic field
  changed.
- Contract tests explicitly cover no-leak behavior for patch replacement, seam validation,
  ownership, fallback, raw triangle, and internal CDT terms.

## Remaining Gaps

- Hosted SketchUp validation did not complete as accepted MTA-34 evidence because production CDT
  patch output bootstrap and stable patch identity are missing.
- The attempted small-rectangle hosted smoke is explicitly not accepted as completion evidence.
- Real hosted acceptance must use larger global terrain with multiple intersecting feature types
  and actual CDT patch proof/replacement participation, not a fake provider-only path.
- Save/reopen validation is not required for this task per user direction.
- Timing evidence has not yet been captured in SketchUp. If ownership or seam snapshot scanning
  dominates local replacement cost, record a default-enable blocker or follow-up patch-index/cache
  task rather than broadening MTA-34.
- MTA-34 is formally closed as blocked/incomplete. MTA-35 owns the missing cached patch output
  lifecycle and the next accepted hosted proof.
