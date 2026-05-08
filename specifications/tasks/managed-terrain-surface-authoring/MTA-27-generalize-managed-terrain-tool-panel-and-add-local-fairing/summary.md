# Summary: MTA-27 Generalize Managed Terrain Tool Panel And Add Local Fairing

**Task ID**: `MTA-27`
**Status**: `completed`
**Completed**: `2026-05-08`

## Shipped Behavior

- Converted the target-height-specific dialog into a shared Managed Terrain
  panel backed by Ruby-owned mode-aware brush state.
- Kept one `Managed Terrain` toolbar container and added two tool commands:
  `Target Height Brush` and `Local Fairing`.
- Added exact two-tool state ownership for `target_height` and `local_fairing`:
  shared `radius`, `blendDistance`, and `falloff` settings persist across tool
  switches, while target-height and local-fairing operation settings persist
  independently.
- Routed both round-brush tools through `BrushEditSession#apply_click` and the
  existing `TerrainSurfaceCommands#edit_terrain_surface` managed command path.
- Added local-fairing circular request construction with `strength`,
  `neighborhoodRadiusSamples`, and `iterations`.
- Preserved the existing target-height circular request shape.
- Added apply-blocking invalid panel state so invalid values refuse before
  command invocation and cannot silently apply stale prior values.
- Kept valid shared brush updates when another active operation field is invalid,
  so radius, blend, and falloff edits are not lost while the panel reports the
  unrelated apply-blocking field.
- Added slider plus adjacent numeric input pairs for bounded brush and fairing
  controls. Radius and blend sliders use a nonlinear mapping where the first
  half of the slider covers roughly `0..10m` and the second half covers
  `10..100m`; direct numeric entry remains authoritative and can exceed the
  slider range when otherwise valid.
- Reused the existing round-brush tool and overlay family for local fairing,
  including post-apply overlay dirtying and no clamping of numeric radius in
  preview/request construction.
- Added a Local Fairing toolbar SVG and package coverage for the shared panel
  and both icons.
- Updated README SketchUp UI documentation for the two-button toolbar, shared
  panel switching, and slider/numeric behavior.

## Files Added Or Changed

- `README.md`
- `src/su_mcp/terrain/ui/brush_settings.rb`
- `src/su_mcp/terrain/ui/brush_edit_session.rb`
- `src/su_mcp/terrain/ui/installer.rb`
- `src/su_mcp/terrain/ui/settings_dialog.rb`
- `src/su_mcp/terrain/ui/target_height_brush_tool.rb`
- `src/su_mcp/terrain/ui/assets/managed_terrain_panel.html`
- `src/su_mcp/terrain/ui/assets/local_fairing.svg`
- `src/su_mcp/terrain/ui/assets/target_height_brush.css`
- `src/su_mcp/terrain/ui/assets/target_height_brush.js`
- `test/terrain/ui/brush_settings_test.rb`
- `test/terrain/ui/brush_edit_session_test.rb`
- `test/terrain/ui/installer_test.rb`
- `test/terrain/ui/settings_dialog_test.rb`
- `test/terrain/ui/target_height_brush_tool_test.rb`
- `test/terrain/ui/brush_overlay_preview_test.rb`
- `test/terrain/ui/ui_assets_source_test.rb`
- `test/terrain/ui/target_height_brush_overlay_contract_guard_test.rb`
- `test/release_support/runtime_package_stage_builder_test.rb`
- `task.md`
- `plan.md`
- `size.md`

## Validation Evidence

- Focused MTA-27 terrain UI/package suite:
  - `96 runs, 473 assertions, 0 failures, 0 errors, 0 skips`
- Full Ruby test suite:
  - `1144 runs, 11424 assertions, 0 failures, 0 errors, 37 skips`
- Full Ruby lint:
  - `283 files inspected, no offenses detected`
- Package verification:
  - passed; produced `dist/su_mcp-1.5.0.rbz`
- Public contract guard coverage:
  - verifies `Target Height Brush`, `Local Fairing`, and shared panel UI names do
    not become native MCP catalog entries
  - verifies UI request-shape tests cover unchanged `target_height` and new
    `local_fairing` circular command requests
  - verifies `edit_terrain_surface` schema does not gain overlay or viewport
    fields

## Code Review

- Required Step 05 queue review ran with `mcp__pal__.codereview` using
  `grok-4.3` before skeleton creation.
- Required Step 10 implementation review ran with `mcp__pal__.codereview` using
  `grok-4.3`.
- No critical, high, or medium implementation defects were found.
- Code review low-severity follow-up items were addressed:
  - hosted SketchUp smoke was rerun against an isolated temporary managed terrain
    fixture instead of an existing terrain object
  - closeout metadata and `summary.md` were updated

## Hosted SketchUp Verification

Hosted SketchUp verification was performed after code review follow-up.

- SketchUp MCP runtime responded to `ping`.
- The first smoke run accidentally targeted the currently selected existing
  managed terrain. That edit was immediately undone with SketchUp undo after the
  user clarified not to use existing terrain.
- Replacement hosted smoke created a temporary managed terrain surface with
  sourceElementId `mta-27-hosted-smoke-1778262391`, selected only that fixture,
  ran the MTA-27 checks, and erased the fixture afterward.
- Manual visual verification after hosted smoke confirmed the shared panel and
  tool behavior looked good and worked. A small follow-up increased the dialog
  height to `520` so Local Fairing controls fit comfortably, and slider-origin
  radius/blend updates were snapped to `0.1m` while direct numeric entry remains
  more precise.
- Temporary-fixture hosted checks passed:
  - temporary managed terrain fixture created and resolved by sourceElementId
  - selected-terrain resolver targeted the temporary fixture only
  - one toolbar command set exposed target-height and local-fairing tools
  - target-height and local-fairing activation states reported the expected mode
  - shared radius persisted across a tool switch after numeric update
  - active-tool validation distinguished local fairing from target height
  - invalid fairing strength refused before apply
  - valid local fairing applied through the managed command path on the
    temporary fixture
  - shared panel opened, pushed state, and closed for the temporary fixture

## Contract And Architecture Notes

- No public MCP tool name, native schema, dispatcher, fixture, or response shape
  changed.
- Runtime ownership remains in the SketchUp extension Ruby support tree.
- JavaScript panel code owns presentation syncing and nonlinear slider mapping
  only; Ruby remains authoritative for settings state, validation, selected
  terrain resolution, request construction, and managed terrain mutation.
- Durable mutation remains owned by `TerrainSurfaceCommands#edit_terrain_surface`.
- UI-facing snapshots and test assertions stay JSON-safe; raw SketchUp objects do
  not cross public MCP boundaries.
- The mode definition is intentionally fixed to the two MTA-27 round-brush tools
  and does not introduce corridor, survey, planar, point-list, validation
  dashboard, or continuous-stroke behavior.

## Remaining Gaps

- Hosted verification was API-driven through SketchUp Ruby and supplemented by
  manual visual confirmation that the panel/tool behavior looked good and worked.
- Step 11 estimation calibration is complete in `size.md`.
